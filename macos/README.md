# Mac shell customisation

Exported from this Mac on 2026-09-15. For portable installation, use
[SETUP.md](../SETUP.md). Paths under `home/` map directly to
the same paths under `$HOME`. This is a configuration snapshot, not a full
machine backup. The existing Linux files and `install.sh` remain separate.

## Included

- `.zshrc`: prompt, history, completion, environment, Git/JJ aliases and utilities.
- `.zprofile`, `.zshenv`, `.bashrc`, `.profile`: shell startup configuration.
- `.inputrc`: Readline settings (identical to the existing root `.inputrc`).
- `.config/jj/config.toml`: user identity, editor and operation metadata.
- `.config/fish/conf.d/atuin.env.fish`: existing Fish startup snippet.
- `cmux-preferences.json`: selected cmux 0.62.2 appearance and behavior
  preferences, exported from `com.cmuxterm.app`. No session or browser state.

The `HF_TOKEN` assignment was replaced by a comment before creating the commit.
Supply its value through a private environment. Credentials, shell history,
SSH material, generated completions, installed tools and per-repository JJ state
are not included.

Exported settings match the source files except for that secret omission.

Live files in `$HOME` were not changed. Existing live aliases can therefore still
refer to `main`; use explicit JJ commands to work with this repository's `prod`.

## Restore deliberately

Compare each exported file with its destination and back up existing files before
copying selected files into `$HOME`. Do not run the Linux `install.sh` on macOS.
Review the JJ identity and hostname before restoring them on another machine.

This snapshot preserves machine-specific paths, including `/Users/mt`, Apple
Silicon Homebrew under `/opt/homebrew`, and Android storage under `/Volumes/LaCie`.
Shell startup references Homebrew, Cargo, Atuin, Git Town, AWS tools, Terraform,
Bun, NVM, pnpm, LM Studio and Java 26. Those tools and generated environment files
must exist separately; syntax validation does not verify those installations.

## JJ history and `prod`

The repository is colocated: both `.git` and `.jj` are in `/Users/mt/src/ba`.

- `github-start`: unchanged GitHub starting commit `0fffe67a`.
- `mac-snapshot`: export commit directly on top of that starting commit.
- `mac-customisation`: portable setup commit on top of the snapshot.
- `zsh-cmux-setup`: feature branch containing the snapshot, portable setup and
  this workflow documentation. Publish it for a pull request into `prod`.
- `prod`: matches the last fetched `prod@origin`; it is not the feature branch.
- The working copy is an empty change on top of `zsh-cmux-setup`.

Repository-local JJ configuration sets `trunk()` to `prod`. JJ configuration is
not tracked by Git. To reproduce that local setting in another clone:

```sh
jj config set --repo 'revset-aliases."trunk()"' prod
```

Review before publishing:

```sh
jj log -r 'ancestors(@, 6)'
jj diff --from prod@origin --to zsh-cmux-setup
jj status
```

Publish the feature bookmark and open a pull request targeting `prod`:

```sh
jj git fetch --remote origin
jj git push --remote origin --bookmark zsh-cmux-setup
gh pr create --repo michft/ba --base prod --head zsh-cmux-setup
```

Merge the pull request after review. Do not advance or push local `prod` to
publish feature work. After merging, fetch and move local `prod` to `prod@origin`.

The owner changed GitHub's default to `prod` during preparation. The refreshed
`prod@origin` points to the original `0fffe67a` starting commit. `github-start`
preserves that initial upstream point. Fetch again before publishing if the
remote has changed since this preparation.
