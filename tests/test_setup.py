import importlib.util
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("ba_setup", ROOT / "setup.py")
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


class SetupTests(unittest.TestCase):
    def test_preview_backup_repeat_and_local_overrides(self):
        with tempfile.TemporaryDirectory(prefix="ba test ") as directory:
            home = Path(directory)
            startup = home / ".zshrc"
            startup.write_text("# user startup\n")
            local = home / ".config/ba/local.zsh"
            local.parent.mkdir(parents=True)
            local.write_text("alias mine='true'\n")
            jj = home / ".config/jj/config.toml"
            jj.parent.mkdir()
            jj.write_text('[user]\nname = "Another User"\n')
            self.assertEqual(setup.main(["--home", directory]), 0)
            self.assertEqual(startup.read_text(), "# user startup\n")
            self.assertFalse((home / ".local").exists())
            self.assertEqual(setup.main(["--home", directory, "--apply"]), 0)
            backups = list((home / ".local/state/ba/backups").iterdir())
            self.assertEqual(len(backups), 1)
            self.assertEqual((backups[0] / ".zshrc").read_text(), "# user startup\n")
            self.assertEqual(local.read_text(), "alias mine='true'\n")
            self.assertIn("Another User", jj.read_text())
            self.assertEqual(setup.file_plan(home), {})
            self.assertEqual(setup.main(["--home", directory, "--apply"]), 0)
            self.assertEqual(len(list(backups[0].parent.iterdir())), 1)
            subprocess.run(["zsh", "-n", str(startup)], check=True)

    def test_symlink_replaced_without_touching_original(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            home = root / "user"
            home.mkdir()
            original = root / "original"
            original.write_text("original\n")
            (home / ".zshrc").symlink_to(original)
            setup.main(["--home", str(home), "--apply"])
            self.assertEqual(original.read_text(), "original\n")
            self.assertFalse((home / ".zshrc").is_symlink())
            backup = next((home / ".local/state/ba/backups").iterdir())
            self.assertEqual((backup / ".zshrc").readlink(), original)

    def test_invalid_destination_prevents_all_writes(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            (home / ".inputrc").mkdir()
            with self.assertRaises(SystemExit):
                setup.main(["--home", directory, "--apply"])
            self.assertFalse((home / ".zshrc").exists())
            self.assertFalse((home / ".local").exists())

    def test_symlinked_config_parent_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            home, elsewhere = root / "user", root / "elsewhere"
            home.mkdir()
            elsewhere.mkdir()
            (home / ".config").symlink_to(elsewhere)
            with self.assertRaises(SystemExit):
                setup.main(["--home", str(home), "--apply"])
            self.assertEqual(list(elsewhere.iterdir()), [])
            self.assertFalse((home / ".zshrc").exists())

    def test_cmux_native_types(self):
        for value, expected in [(False, ["-bool", "false"]), (0.18, ["-float", "0.18"]), (1, ["-int", "1"]), ("dark", ["-string", "dark"])]:
            self.assertEqual(setup.cmux_write_args("test", value)[-2:], expected)
        with self.assertRaises(ValueError):
            setup.cmux_write_args("bad", [])

    def test_cmux_apply_backs_up_domain_and_writes_selected_keys(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory).resolve()
            calls = []

            def run(command, **kwargs):
                calls.append(command)
                if command[0].endswith("pgrep"):
                    return subprocess.CompletedProcess(command, 1)
                if command[1] == "export":
                    return subprocess.CompletedProcess(command, 0, b"original domain", b"")
                return subprocess.CompletedProcess(command, 0)

            with patch.object(setup.Path, "home", return_value=home), patch.object(setup.sys, "platform", "darwin"), patch.object(setup.subprocess, "run", side_effect=run):
                setup.main(["--home", str(home), "--apply", "--cmux"])
            backup = next((home / ".local/state/ba/backups").iterdir())
            self.assertEqual((backup / "cmux-preferences.plist").read_bytes(), b"original domain")
            writes = [command for command in calls if command[1] == "write"]
            self.assertEqual(len(writes), 18)
            self.assertTrue(all(command[2] == "com.cmuxterm.app" for command in writes))
            self.assertFalse(any("import" in command or "delete" in command for command in calls))

    def test_running_cmux_prevents_all_writes(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory).resolve()
            with patch.object(setup.Path, "home", return_value=home), patch.object(setup.sys, "platform", "darwin"), patch.object(setup.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)):
                with self.assertRaises(SystemExit):
                    setup.main(["--home", str(home), "--apply", "--cmux"])
            self.assertEqual(list(home.iterdir()), [])


class ShellTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="ba shell ")
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.log = self.directory / "commands"
        self.env = dict(os.environ, PATH=f"{self.directory}:/usr/bin:/bin", BA_COMMAND_LOG=str(self.log), XDG_CONFIG_HOME=str(self.directory / "config"), ZDOTDIR=str(self.directory))

    def stub(self, name, body):
        script = self.directory / name
        script.write_text('#!/bin/sh\nprintf "%s\\n" "$0" "$@" >> "$BA_COMMAND_LOG"\n' + body + "\n")
        script.chmod(0o755)

    def shell(self, code, interactive=False):
        return subprocess.run(["/bin/zsh", "-df" + ("i" if interactive else "") + "c", code], env=self.env, text=True, capture_output=True)

    def test_no_fetch_push_or_git_call_during_alias_loading(self):
        for name in ["jj", "git", "gh"]:
            self.stub(name, "exit 0")
        result = self.shell(f"source {shlex.quote(str(ROOT / 'zsh/aliases.zsh'))}")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.log.exists())

    def test_jn_uses_trunk_and_stops_when_fetch_fails(self):
        self.stub("jj", 'if [ "$1" = git ] && [ "${BA_FAIL_FETCH:-0}" = 1 ]; then exit 7; fi')
        source = f"source {shlex.quote(str(ROOT / 'zsh/aliases.zsh'))}; jn"
        result = self.shell(source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("new\ntrunk()\n", self.log.read_text())
        self.log.unlink()
        self.env["BA_FAIL_FETCH"] = "1"
        result = self.shell(source)
        self.assertEqual(result.returncode, 7)
        self.assertNotIn("new", self.log.read_text())

    def test_jz_requires_explicit_bookmark(self):
        self.stub("jj", "exit 0")
        result = self.shell(f"source {shlex.quote(str(ROOT / 'zsh/aliases.zsh'))}; jz")
        self.assertEqual(result.returncode, 2)
        self.assertFalse(self.log.exists())

    def test_gu_stops_when_not_in_repository(self):
        self.stub("git", "exit 9")
        result = self.shell(f"source {shlex.quote(str(ROOT / 'zsh/aliases.zsh'))}; gu")
        self.assertEqual(result.returncode, 9)
        self.assertNotIn("push", self.log.read_text())

    def test_interactive_startup_without_optional_tools(self):
        # Environment discovery is tested separately; isolate optional integrations.
        code = f'''typeset -g _BA_ENV_LOADED=1
export BA_ROOT={shlex.quote(str(ROOT))}
export BUN_INSTALL={shlex.quote(str(self.directory))}
unset HOMEBREW_PREFIX
source "$BA_ROOT/zsh/interactive.zsh"
(( $+functions[jn] && $+functions[genpasswd] ))
'''
        result = self.shell(code, interactive=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")

    def test_portable_environment_preserves_terminal_and_local_override(self):
        config = self.directory / "config/ba"
        config.mkdir(parents=True)
        (config / "env.zsh").write_text("export BA_TEST_MACHINE=local\n")
        self.stub("brew", 'printf "%s\\n" /nonexistent/ba-brew')
        code = f'''export TERM=xterm-ghostty
source {shlex.quote(str(ROOT / 'zsh/environment.zsh'))}
source {shlex.quote(str(ROOT / 'zsh/environment.zsh'))}
[[ $TERM == xterm-ghostty && $BA_TEST_MACHINE == local && $BA_ROOT == {shlex.quote(str(ROOT))} ]]
'''
        result = self.shell(code)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.log.read_text().count("--prefix"), 1)


if __name__ == "__main__":
    unittest.main()
