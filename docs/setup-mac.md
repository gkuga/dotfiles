# Setting up a new Mac

From a fresh macOS install to the same environment as the other machines:
Homebrew bash 5 as the login shell, chezmoi-managed dotfiles, mise, the same
git identity and signing key. For a Mac that still runs the old symlinked zsh
setup, see [migrate-mac.md](migrate-mac.md) instead.

Placeholders: `<keyid>` is the GPG signing key ID, `<email>` the git email,
`<old>` an already set-up machine reachable over SSH.

> [!NOTE]
> Until step 5 the login shell is zsh. Interactive zsh does not treat `#` as a
> comment by default, so run `setopt interactivecomments` first in that
> terminal, or a trailing comment is passed on as arguments.

## 1. Xcode

Install Xcode from the App Store if you build iOS apps (Flutter, CocoaPods);
otherwise the Command Line Tools are enough, and `install.sh` asks for them.

After installing or updating Xcode, accept its license and finish its first
launch, or every C compiler call fails (treesitter parsers, telescope-fzf-native,
native gems and npm modules, source builds by mise):

```sh
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch
```

Keep Xcode's major version in step with macOS. An older Xcode next to a newer
Command Line Tools SDK fails at link time with
`ld: tapi error: malformed file ... unknown architecture`.

## 2. Install

```sh
curl -fsSL https://raw.githubusercontent.com/gkuga/dotfiles/main/install.sh | bash
```

This clones the repository to `~/dev/src/github.com/gkuga/dotfiles` and runs
every step. Without the Command Line Tools it opens their installer and stops:
run the same command again when that finishes. The Homebrew installer asks for
your password.

Answers for `chezmoi init`:

| Prompt | Answer |
|---|---|
| Git user.name | Enter (the default) |
| Git user.email | `<email>`; do not leave it empty |
| Sign git commits with GPG | Enter (`true`); import the key in step 3 |
| GPG signing key ID | `<keyid>` |

Notes on the packages step:

- Docker Desktop is not in the Brewfile because it updates itself. Install it
  from docker.com; the `platform` step warns while it is missing.
- A cask fails with "It seems there is already an App at ..." when the app was
  installed without Homebrew. Give the terminal "App Management" access (System
  Settings > Privacy & Security), quit the app, then
  `brew install --cask --adopt <cask>`. Never `brew uninstall --cask` an app you
  want to keep: it deletes the app.
- Optional extras (hardware, build and project-specific tools, the Android SDK
  for Flutter): `brew bundle --file=packages/Brewfile.extra`. It declares its
  third-party taps as trusted; "tap is not trusted" warnings on the first run
  can be ignored.

## 3. Keys and machine-specific settings

From `<old>` (run on the new Mac):

```sh
install -d -m 700 ~/.ssh
scp <old>:.ssh/id_ed25519 <old>:.ssh/id_ed25519.pub <old>:.ssh/config ~/.ssh/
scp '<old>:.ssh/*.pem' ~/.ssh/          # keys that ~/.ssh/config refers to
chmod 600 ~/.ssh/id_ed25519 ~/.ssh/config ~/.ssh/*.pem
scp <old>:.gitconfig.local ~/
ssh <old> 'gpg --export-secret-keys --armor <keyid>' | gpg --import
ssh <old> 'gpg --export-ownertrust' | gpg --import-ownertrust
```

Exporting the GPG key asks for its passphrase on `<old>`; when that prompt
cannot reach you over SSH, export to a file on `<old>` instead and copy it.

Without an old machine: create a key with `ssh-keygen -t ed25519` and
`gpg --quick-generate-key "<name> <<email>>" ed25519 sign never`, and add both
public keys to GitHub.

## 4. Projects

Projects keep their `.tool-versions` or `mise.toml`; mise reads both. After
cloning them with `ghq get`:

```sh
ghq list -p | while read -r dir; do
  [ -f "$dir/.tool-versions" ] && (cd "$dir" && echo "== $dir" && mise install </dev/null)
done
```

mise verifies GitHub artifact attestations for prebuilt Python and refuses
older builds without them (for example 3.12.5, 3.10.6). Bump the project to the
latest patch of the same minor (`mise latest python@3.10`); only if that is not
possible, use `MISE_PYTHON_GITHUB_ATTESTATIONS=false mise install` in that
project.

## 5. Check and finish

Open a new terminal tab:

```sh
echo $SHELL $BASH_VERSION                       # /opt/homebrew/bin/bash 5.x
chezmoi status && chezmoi verify
ssh -T git@github.com
echo test | gpg --clearsign >/dev/null && echo "gpg signing OK"
command -v peco nvim claude                     # mise shims or ~/.local/bin
```

Once, by hand:

- iTerm2: Settings > Profiles > Keys > General, set Left Option key to `Esc+`
  (the Neovim `<M-...>` keys need it).
- `nvim`: plugins, treesitter parsers and LSP servers install on the first
  start; then `:Copilot auth`. `claude`: log in to Claude Code.
- Completions that bash-completion loads on first use:

  ```sh
  dir=~/.local/share/bash-completion/completions
  mkdir -p "$dir"
  etc=/Applications/Docker.app/Contents/Resources/etc
  ln -sf "$etc/docker.bash-completion" "$dir/docker"
  ln -sf "$etc/docker-compose.bash-completion" "$dir/docker-compose"
  rustup completions bash cargo > "$dir/cargo"
  pnpm completion bash > "$dir/pnpm"
  ```

- Anything only this Mac needs goes to `~/.bashrc.local` or `~/.gitconfig.local`.
