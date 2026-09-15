#!/usr/bin/env python3
"""Preview or apply this repository's Zsh setup for an existing macOS user."""

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parent
CMUX_DOMAIN = "com.cmuxterm.app"


def file_plan(home: Path) -> dict[Path, bytes]:
    """Shared startup files are managed; machine overrides and identity are not."""
    config = home / ".config"
    plan = {
        home / ".zprofile": (
            "# Managed by ba/setup.py. Machine settings: ~/.config/ba/env.zsh\n"
            f"source {shlex.quote(str(ROOT / 'zsh/environment.zsh'))}\n"
        ).encode(),
        home / ".zshrc": (
            "# Managed by ba/setup.py. Local aliases: ~/.config/ba/local.zsh\n"
            f"source {shlex.quote(str(ROOT / 'zsh/interactive.zsh'))}\n"
        ).encode(),
        home / ".inputrc": (ROOT / ".inputrc").read_bytes(),
    }
    new_only = {
        config / "ba/env.zsh": (ROOT / "zsh/env.zsh.example").read_bytes(),
        config / "ba/local.zsh": b"# Machine-only aliases and functions. Loaded after shared Zsh settings.\n",
        config / "jj/config.toml": b'[ui]\neditor = "vim"\nmerge-editor = ":builtin"\n',
    }
    for path, content in new_only.items():
        if not os.path.lexists(path):
            plan[path] = content
    return {
        path: content for path, content in plan.items()
        if path.is_symlink() or not path.is_file() or path.read_bytes() != content
    }


def configured_email(path: Path) -> str:
    if not path.is_file():
        return ""
    result = subprocess.run(
        ["jj", "--ignore-working-copy", "config", "list", "--user",
         "--include-overridden", "user.email", "--template", "value.as_string()"],
        env=dict(os.environ, JJ_CONFIG=str(path)), cwd=path.parent,
        check=True, capture_output=True, text=True,
    )
    return result.stdout.strip()


def prompt_email_config(content: bytes) -> bytes:
    while True:
        try:
            email = input("JJ commit email: ").strip()
        except (EOFError, KeyboardInterrupt):
            raise ValueError("JJ email required; rerun --apply interactively. No configuration written.") from None
        local, separator, domain = email.partition("@")
        if local and separator and domain and "@" not in domain and not any(
            char.isspace() or ord(char) < 32 or ord(char) == 127 for char in email
        ):
            break
        print("Enter an email with a local part and domain, without spaces.")
    # Let JJ edit TOML, preserving other settings and comments. Stage it first so
    # the normal backup and atomic file replacement also cover the email change.
    with tempfile.TemporaryDirectory(prefix="ba-jj-config-") as directory:
        staged = Path(directory) / "config.toml"
        staged.write_bytes(content)
        staged.chmod(0o600)
        subprocess.run(
            ["jj", "--ignore-working-copy", "config", "set", "--file", str(staged),
             "user.email", json.dumps(email, ensure_ascii=False)],
            env=dict(os.environ, JJ_CONFIG=str(staged)), cwd=directory,
            check=True, capture_output=True, text=True,
        )
        return staged.read_bytes()


def cmux_write_args(key: str, value: object) -> list[str]:
    if type(value) is bool:
        flag, text = "-bool", "true" if value else "false"
    elif type(value) is int:
        flag, text = "-int", str(value)
    elif type(value) is float:
        flag, text = "-float", str(value)
    elif type(value) is str:
        flag, text = "-string", value
    else:
        raise ValueError(f"Unsupported cmux preference type: {key}")
    return ["/usr/bin/defaults", "write", CMUX_DOMAIN, key, flag, text]


def apply_files(plan: dict[Path, bytes], home: Path, backup: Path) -> None:
    for target, content in plan.items():
        if os.path.lexists(target):
            saved = backup / target.relative_to(home)
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, saved, follow_symlinks=False)
        target.parent.mkdir(parents=True, exist_ok=True)
        # Replace the link itself, never overwrite a symlink's external target.
        with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(content)
        try:
            temporary.replace(target)
        finally:
            temporary.unlink(missing_ok=True)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--home", type=Path, default=Path.home(), help="target home (default: current user)")
    parser.add_argument("--apply", action="store_true", help="write files, preserving originals in a backup")
    parser.add_argument("--cmux", action="store_true", help="also apply captured native cmux preferences")
    args = parser.parse_args(argv)
    home = args.home.expanduser().resolve()
    if not home.is_dir():
        parser.error("target home must already exist")
    if home == Path.home().resolve():
        for name, expected in [("ZDOTDIR", home), ("XDG_CONFIG_HOME", home / ".config")]:
            if os.environ.get(name) and Path(os.environ[name]).expanduser().resolve() != expected:
                parser.error(f"custom {name} is not supported by this installer; see SETUP.md")
    plan = file_plan(home)
    email_path = home / ".config/jj/config.toml"
    needs_email = not configured_email(email_path)
    if needs_email and email_path not in plan:
        plan[email_path] = email_path.read_bytes()
    # Validate every destination before writing any files.
    for path in plan:
        if path.is_dir() and not path.is_symlink():
            parser.error(f"destination is a directory: {path}")
        for parent in path.parents:
            if parent == home:
                break
            if parent.is_symlink():
                parser.error(f"destination parent is a symlink: {parent}")
            if parent.exists() and not parent.is_dir():
                parser.error(f"destination parent is not a directory: {parent}")

    cmux_commands = []
    if args.cmux:
        if sys.platform != "darwin" or home != Path.home().resolve():
            parser.error("--cmux applies only to the current macOS user's preference domain")
        preferences = json.loads((ROOT / "macos/cmux-preferences.json").read_text())
        cmux_commands = [cmux_write_args(key, value) for key, value in preferences.items()]
        if args.apply and subprocess.run(["/usr/bin/pgrep", "-x", "cmux"], capture_output=True).returncode == 0:
            parser.error("quit cmux before applying native preferences, then rerun")

    for path in plan:
        action = "replace (back up first)" if os.path.lexists(path) else "create"
        print(f"{action}: {path}")
    if cmux_commands:
        print(f"Apply {len(cmux_commands)} selected cmux preferences; preserve other keys.")
    if needs_email:
        print("JJ email missing; apply will prompt before writing configuration.")
    if not args.apply:
        print("Preview only. Run again with --apply to write this plan.")
        return 0
    if needs_email:
        plan[email_path] = prompt_email_config(plan[email_path])
    if not plan and not cmux_commands:
        print("Already up to date.")
        return 0

    backup_root = home / ".local/state/ba/backups"
    # A backup path must never redirect outside the requested home.
    for path in [backup_root, *backup_root.parents]:
        if path == home:
            break
        if path.is_symlink():
            parser.error(f"backup path is a symlink: {path}")
    backup_root.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ-")
    backup = Path(tempfile.mkdtemp(prefix=stamp, dir=backup_root))
    print(f"Backup: {backup}")
    (backup / "manifest.json").write_text(json.dumps({
        "created": [str(path.relative_to(home)) for path in plan if not os.path.lexists(path)],
        "replaced": [str(path.relative_to(home)) for path in plan if os.path.lexists(path)],
        "cmux": bool(cmux_commands),
    }, indent=2) + "\n")
    if cmux_commands:
        exported = subprocess.run(["/usr/bin/defaults", "export", CMUX_DOMAIN, "-"], capture_output=True)
        if exported.returncode:
            # A fresh user need not have launched cmux yet.
            if b"does not exist" not in exported.stderr:
                raise RuntimeError("Could not back up cmux preferences; nothing applied")
            (backup / "cmux-domain-absent").touch()
        else:
            (backup / "cmux-preferences.plist").write_bytes(exported.stdout)
    apply_files(plan, home, backup)
    for command in cmux_commands:
        subprocess.run(command, check=True)
    print("Applied. Open a new Zsh shell; relaunch cmux if its preferences were applied.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"Setup failed: {error}. See the printed backup path if files were written.", file=sys.stderr)
        raise SystemExit(1)
