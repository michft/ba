# Standard Zsh setup for an existing Mac user

Use this repository to share the same prompt, CLI aliases/functions and cmux
preferences across Macs. The original Linux setup remains in `install.sh` and
`user.ba`; the captured Mac configuration is documented in [macos/README.md](macos/README.md).

## Preview and install

Requires Zsh and Python 3.10 or newer. Install the CLI applications you use
separately; this installer does not download packages or create macOS accounts.

Keep the checkout in a permanent location, such as `~/src/ba`, because startup
files source the shared files directly from that checkout:

```sh
cd ~/src/ba
python3 setup.py
python3 setup.py --apply
```

Preview makes no changes. Apply backs up existing `.zshrc`, `.zprofile` and
`.inputrc` before replacing them. Move any settings you still need from the
backup into the local override files described below. Existing `.zshenv` and
other startup files are not replaced; review those separately if they depend on
tools or paths that no longer exist. For a user whose login shell is not Zsh,
switch it separately with `chsh -s /bin/zsh`.

The installer prints its backup directory under `~/.local/state/ba/backups/`.
Each backup includes originals and a manifest distinguishing created from
replaced files. To undo, restore the backed-up originals and remove only files
listed as newly created in that manifest. Do not put backups in this repository:
original startup files may contain private credentials.

Reapplying leaves identical files, existing local overrides and existing JJ user
identity untouched. New JJ configurations contain editor settings only; set your
own identity with `jj config set --user user.name ...` and
`jj config set --user user.email ...`.

`--home /path/to/existing/home` supports isolated setup previews/tests. Apply as
the intended user, without `sudo`. Automated installation targets standard home
paths; it refuses a custom `ZDOTDIR` or `XDG_CONFIG_HOME` for the current user.
With custom directories, add the two source lines from the generated startup
files manually to your chosen Zsh startup files instead.

## Shared and machine-local settings

| Location | Purpose |
| --- | --- |
| `zsh/environment.zsh` | Portable paths, Homebrew discovery and environment defaults |
| `zsh/interactive.zsh` | Prompt, history, key bindings and optional completions |
| `zsh/aliases.zsh` | Shared Git/JJ shortcuts and utility functions |
| `~/.config/ba/env.zsh` | Private/machine environment, loaded before tool setup |
| `~/.config/ba/local.zsh` | Machine-only aliases/functions, loaded last |
| `macos/home/` | Historical source snapshot; not installed by `setup.py` |
| `macos/cmux-preferences.json` | Shared native cmux preference values |

Homebrew works under Apple Silicon or Intel prefixes. User paths use `$HOME`.
Optional commands/completions are enabled only when present. External Android
storage, Java selection and the legacy AWS config override are examples in
`zsh/env.zsh.example`; enable only the values appropriate to each machine.
Shared startup preserves the terminal-provided `TERM`, including cmux's
`xterm-ghostty`. macOS manages its SSH agent; shared startup does not evaluate the
snapshot's cached agent file.

Git, JJ, GitHub CLI, Git Town and LazyGit shortcuts remain available; invoking a
shortcut requires its corresponding application. `ls` uses `eza` only when
installed. `genpasswd` accepts a positive length; `ds` converts Unix timestamps.

Differences from the historical snapshot:

- Git default-branch shortcuts prefer `prod`, retaining legacy fallback branches.
- `gtp` opens a PR against `prod`; branch/title are resolved when invoked.
- `gu` resolves its branch at invocation and stops if pull fails.
- `gr` uses valid `git rebase -i` argument order.
- `ji` creates a colocated Git/JJ repository.
- `jn` fetches, then starts from the supplied revision or repository `trunk()`;
  failed fetch stops the operation.
- `jz <bookmark>` requires an explicit bookmark and stops if push fails.
- Shared shell startup itself does not fetch, push or open a PR.

## cmux preferences

Preview native preference changes:

```sh
python3 setup.py --cmux
```

Quit cmux, then apply from another terminal:

```sh
python3 setup.py --apply --cmux
```

The installer backs up the existing `com.cmuxterm.app` preference domain and
writes only the 18 captured keys. Other preferences remain intact. The profile
includes dark appearance/icon, Google browser search, system browser theme,
new-workspace placement, sidebar appearance, disabled telemetry and disabled
automatic update checks. Relaunch cmux afterward. Session layouts, browser
history, sockets and authentication are deliberately excluded.

This export comes from cmux **0.62.2**, which stores these values in native macOS
preferences. Current cmux also supports `~/.config/cmux/cmux.json`, whose settings
can override native preferences. If using that file on another Mac, reconcile its
overlapping settings before applying this native profile. Terminal rendering is
configured separately through Ghostty; this Mac's Ghostty file was empty, so no
font or theme settings were invented. See [official cmux configuration](https://cmux.com/docs/configuration).

To recover cmux settings after an apply, quit cmux and import the printed backup's
`cmux-preferences.plist` with `defaults import com.cmuxterm.app /path/to/backup/cmux-preferences.plist`.
A `cmux-domain-absent` marker means no prior preference domain existed.

## Share changes between machines

The default branch is `prod`. GitHub's default was changed by the owner during
this setup. Local JJ `trunk()` is set to `prod`.

New clone (choose a destination that does not already contain a checkout):

```sh
jj git clone --colocate https://github.com/michft/ba.git ~/src/ba
cd ~/src/ba
jj config set --repo 'revset-aliases."trunk()"' 'prod@origin'
python3 setup.py
```

After reviewing changes from another machine:

```sh
jj git fetch --remote origin
jj new prod@origin
python3 setup.py
```

Keep shared changes in this repository, commit them with JJ, then publish the
specific reviewed bookmark. Keep private or machine-only changes in the local
override files. Because startup sources the checkout, **the checked-out revision
determines what new shells load**; review incoming shell code before opening a
new shell. Rerun `setup.py --apply` only when generated startup files change or
the checkout moves. cmux preferences require their separate apply step.

## Validate

```sh
python3 -B -m unittest discover -s tests -v
zsh -n zsh/environment.zsh
zsh -n zsh/interactive.zsh
zsh -n zsh/aliases.zsh
```

Tests use temporary directories and stub CLI commands. They cover preview-only
behavior, backups, repeated apply, symlink handling, identity preservation,
portable environment loading and fetch/push failure handling. No live home
configuration, applications or remote repositories are modified by the tests.
