# Migrating a Mac from the old symlinked dotfiles

For a Mac that still runs the pre-chezmoi setup: zsh, `~/.zshrc` and friends
symlinked into the checkout, asdf for runtimes. After this, the Mac matches a
fresh `install.sh` machine: bash 5, chezmoi-managed files, and mise.

The checkout is `~/dev/src/github.com/gkuga/dotfiles` (the default `REPO_DIR`
of `install.sh`).

> [!IMPORTANT]
> The old dotfiles are symlinks into that checkout, and current `master`
> deletes or renames those files. Do **not** `git pull` until step 4: an early
> pull leaves the links dangling.
>
> Do steps 1–5 in **one terminal** and do not open new ones until step 5 is
> done. A running shell does not re-read its rc files, so this terminal keeps
> working. A new terminal after step 4 starts zsh without any rc file and may
> show zsh's first-run menu ("This is the Z Shell configuration function for
> new users"): press `q` so that it writes nothing.
>
> Interactive zsh does not treat `#` as a comment by default, so a trailing
> comment in the commands below would be passed on as arguments. Run this
> first in that terminal:
>
> ```sh
> setopt interactivecomments
> ```

Most of the time goes into `brew bundle` and `mise install`.

## 1. Back up and check

```sh
backup=~/dotfiles-backup        # used again in step 6 and in "Rolling back"
mkdir "$backup"                 # fails if an older backup is still there: move it away first
cp -p ~/.gitconfig ~/.tool-versions ~/.claude/CLAUDE.md "$backup"/
cp -p ~/.config/git/ignore "$backup"/git-ignore
cp -p ~/.gnupg/gpg-agent.conf "$backup"/

# The current symlinks as "LINK TARGET" lines (used by "Rolling back")
find ~ -maxdepth 1 -type l -lname '*gkuga/dotfiles*' | while read -r l; do
  printf '%s %s\n' "$l" "$(readlink "$l")"
done > "$backup"/symlinks.txt
cat "$backup"/symlinks.txt
```

Write down anything you still want from the old zsh setup: the untracked or
modified files are shown by `git -C ~/dev/src/github.com/gkuga/dotfiles status`.
They do not carry over. Step 7 lists the usual candidates.

## 2. Install the new packages

First clear what would make `brew bundle` fail:

```sh
# bash-completion (v1, for bash 3.2) conflicts with bash-completion@2.
brew list bash-completion >/dev/null 2>&1 && brew uninstall bash-completion
# Taps with nothing installed from them. go-task/tap also shadows the
# homebrew/core go-task formula and is refused as an untrusted tap.
# One at a time: brew untap stops at a tap that is missing or still in use.
for t in go-task/tap hashicorp/tap heroku/brew osx-cross/arm; do
  brew untap "$t" || echo "kept $t"
done
```

Then install from the new Brewfile without switching the checkout yet:

```sh
cd ~/dev/src/github.com/gkuga/dotfiles
git fetch origin
git show origin/master:packages/Brewfile > /tmp/Brewfile
brew bundle --no-upgrade --file=/tmp/Brewfile
```

This adds bash 5, bash-completion@2, tmux, chezmoi, mise and the rest. Nothing
in `$HOME` changes yet. `--no-upgrade` keeps already installed packages as they
are, so the migration does not also upgrade everything; run `brew upgrade`
afterwards.

Docker Desktop is not in the Brewfile because it updates itself; a cask on
top of that drifts out of sync. The existing app stays as it is.

If Homebrew still has a record of `docker-desktop` (`brew list --cask
docker-desktop` succeeds: an earlier cask install, or an `--adopt` that failed
halfway with `chmod ... Operation not permitted`), remove only that record.
Otherwise `brew bundle cleanup` in step 7 offers to uninstall it, and
`brew uninstall --cask docker-desktop` deletes `/Applications/Docker.app`.

```sh
# rm -rf removes the symlinks in there without following them into /Applications.
C="$(brew --prefix)/Caskroom/docker-desktop"
[ -d "$C" ] && rm -rf "$C"
brew list --cask docker-desktop     # now an error: Homebrew forgot it
ls -d /Applications/Docker.app      # the app is still there
```

Any other cask that fails with "It seems there is already an App at ..." was
installed without Homebrew and does not update itself, so let Homebrew take it
over: give the terminal "App Management" access (System Settings > Privacy &
Security), quit the app, then `brew install --cask --adopt <cask>`. Without
that access the adoption fails halfway, as above.

Hardware, build and project-specific tools are in `packages/Brewfile.extra`
(not installed by `install.sh`). This Mac already has them; to keep them
managed, run it as well. It declares its third-party taps as trusted; on the
first run, "Cannot check whether ... is outdated because its tap is not
trusted" warnings still appear and can be ignored.

```sh
git show origin/master:packages/Brewfile.extra > /tmp/Brewfile.extra
brew bundle --no-upgrade --file=/tmp/Brewfile.extra
```

## 3. Move the work-specific git settings out of `~/.gitconfig`

`~/.gitconfig` becomes a chezmoi template. Anything that is not in
[home/dot_gitconfig.tmpl](../home/dot_gitconfig.tmpl), most importantly the
work `url.*.insteadOf` entries, goes to `~/.gitconfig.local`. That file is
included at the end of `~/.gitconfig` and never committed.

```sh
# What is there now?
git config --global --get-regexp '^url\.'

# Copy each entry, e.g.
git config --file ~/.gitconfig.local \
  url.ssh://git@github.com/<org>/.insteadOf https://github.com/<org>/

git config --file ~/.gitconfig.local --list   # check
```

Copy credential helpers or other keys that only this Mac needs in the same way.
The diff in step 5 shows anything else that `~/.gitconfig` is about to lose.

## 4. Remove the old symlinks and update the checkout

```sh
cd ~/dev/src/github.com/gkuga/dotfiles

# Only symlinks into this checkout are removed; nothing else is touched.
find ~ -maxdepth 1 -type l -lname '*gkuga/dotfiles*' -print -delete

# Local changes to deleted files (e.g. zshrc) would block the pull.
git stash push --include-untracked -m "pre-chezmoi local changes"
git switch master
git pull --ff-only
```

Do not copy the old links' targets into place. `~/.profile.d` was a symlink, so
it is gone now, and step 5 creates it again with only the new files. A copy of
the old directory would keep `99-asdf.sh`, which puts asdf ahead of mise on
`PATH`.

## 5. Apply the dotfiles

```sh
./install.sh --dry-run          # optional: everything that would change
./install.sh --only dotfiles
```

`chezmoi init` asks for:

| Prompt | Answer on this Mac |
|---|---|
| Git user.name / user.email | as in your backup of `~/.gitconfig` |
| Sign git commits with GPG | yes (`commit.gpgsign` was on) |
| GPG signing key ID | empty, unless the backup had `user.signingkey` |

Read the diff before you confirm. Expected changes:

- new: `~/.profile`, `~/.profile.d/`, `~/.bashrc`, `~/.bash_profile`,
  `~/.bash.d/`, `~/.inputrc`, `~/.tmux.conf`, `~/.screenrc`, `~/.vimrc`,
  `~/.config/nvim/`, `~/.config/mise/config.toml`
- `~/.gitconfig`: the template, without your `insteadOf` (now in `.gitconfig.local`)
- `~/.config/git/ignore`: adds `.DS_Store` and `*.swp`
- `~/.claude/CLAUDE.md` and `~/.gnupg/gpg-agent.conf`: no change
- `~/.claude/settings.json` is only created when missing, so yours is kept

Then start bash in the same terminal (the login shell is still zsh):

```sh
/opt/homebrew/bin/bash -l
command -v bash git                  # /opt/homebrew/bin/...
git config --get-regexp '^url\.'     # comes from ~/.gitconfig.local
cd ~/dev/src/github.com/gkuga/dotfiles
```

The mise shims are not on `PATH` yet: that directory only exists after step 6.
Work in this bash from now on; the zsh around it still has the asdf `PATH`.

## 6. Move from asdf to mise

mise reads the existing `.tool-versions` files in the projects, so they do not
need changes. Only the global versions move to
`~/.config/mise/config.toml`.

```sh
mv ~/.tool-versions ~/dotfiles-backup/tool-versions.global
./install.sh --only mise      # mise install for the global tools, Claude Code CLI
exec bash -l                  # now with the mise shims on PATH
```

> [!NOTE]
> The global `python` is now `3.12.16`, not `3.12.5`. mise verifies the GitHub
> artifact attestations of the prebuilt Python builds, and older builds such as
> 3.12.5 or 3.10.6 have none, so mise refuses to install them.

Then install the tools of each project:

```sh
ghq list -p | while read -r dir; do
  # </dev/null: an installer that reads stdin must not eat the directory list
  [ -f "$dir/.tool-versions" ] && (cd "$dir" && echo "== $dir" && mise install </dev/null)
done
```

If a project pins an old Python (for example `python 3.10.6`):

1. Better: bump it to the latest patch of the same minor (`mise latest python@3.10`),
   and commit the change in that project.
2. Otherwise disable the check for that project only, with
   `MISE_PYTHON_GITHUB_ATTESTATIONS=false mise install`. Do not turn it off
   globally.

asdf plugins in use (`php`, `flutter`, `java`, `pnpm`, ...) are in the mise
registry. `php` builds from source and may need extra Homebrew packages; follow
mise's error message.

## 7. Switch the login shell, then clean up

```sh
./install.sh --only shell     # adds Homebrew bash to /etc/shells, chsh (asks for sudo)
```

Open a new terminal and check that `echo $BASH_VERSION` prints `5.x`. Then:

- Terminal app: turn on "Use Option as Meta key" for the Neovim `<M-...>` keys.
- Neovim: start `nvim` once (plugins install from `lazy-lock.json`), then
  `:Copilot auth`. Run `claude` once to log in.
- Completions the zsh setup had: put them where bash-completion loads them on
  first use, so that they cost nothing at shell start:

  ```sh
  dir=~/.local/share/bash-completion/completions
  mkdir -p "$dir"
  etc=/Applications/Docker.app/Contents/Resources/etc
  ln -sf "$etc/docker.bash-completion" "$dir/docker"
  ln -sf "$etc/docker-compose.bash-completion" "$dir/docker-compose"
  rustup completions bash cargo > "$dir/cargo"   # rust from mise comes with rustup
  ```

  Anything else that only this Mac needs goes to `~/.bashrc.local`.

- Once everything has worked for a few days:

  ```sh
  cd ~/dev/src/github.com/gkuga/dotfiles
  # Replaced by the new setup: mise (asdf, ghq, peco, bun) and bash (zsh-completions)
  brew uninstall asdf ghq peco zsh-completions oven-sh/bun/bun
  brew untap oven-sh/bun
  rm -rf ~/.asdf                      # about 14 GB here
  # Anything installed that neither Brewfile lists; it asks before removing
  # anything, so answer no to only see the list. Leave out Brewfile.extra if
  # you did not install it. If it lists docker-desktop, answer no and remove
  # Homebrew's record first (step 2): uninstalling it deletes Docker.app.
  cat packages/Brewfile packages/Brewfile.extra > /tmp/Brewfile.all
  brew bundle cleanup --file=/tmp/Brewfile.all
  git stash list                      # drop "pre-chezmoi local changes" when unneeded
  rm -rf ~/dotfiles-backup
  ```

## Rolling back

This restores the old dotfiles while `~/.asdf` and `~/dotfiles-backup` still
exist. The new Homebrew packages, mise tools and the Claude Code CLI can stay;
the old setup ignores them. Run it from bash, with the checkout still on
`master`: chezmoi needs the new source to list the files it manages.

```sh
cd ~/dev/src/github.com/gkuga/dotfiles
backup=~/dotfiles-backup

# 1. Remove every file chezmoi created (your ~/.claude/settings.json stays),
#    then the directories that are empty now.
chezmoi managed --path-style absolute --include files,symlinks |
  grep -vxF "$HOME/.claude/settings.json" |
  while read -r f; do rm -f "$f"; done
chezmoi managed --path-style absolute --include dirs | sort -r |
  while read -r d; do rmdir "$d" 2>/dev/null; done

# 2. The old checkout and its local changes (looked up by name, not the top stash)
git switch --detach 13645d5          # last commit of the symlink setup
stash=$(git stash list | grep -m1 'pre-chezmoi local changes' | cut -d: -f1)
git stash pop "$stash"

# 3. The old symlinks and files
while read -r link target; do ln -sfn "$target" "$link"; done < "$backup"/symlinks.txt
cp -p "$backup"/.gitconfig ~/.gitconfig
mkdir -p ~/.claude ~/.config/git
cp -p "$backup"/CLAUDE.md ~/.claude/CLAUDE.md
cp -p "$backup"/git-ignore ~/.config/git/ignore
cp -p "$backup"/gpg-agent.conf ~/.gnupg/gpg-agent.conf
mv "$backup"/tool-versions.global ~/.tool-versions 2>/dev/null || cp -p "$backup"/.tool-versions ~/.tool-versions
```

After step 7, also run `chsh -s /bin/zsh`.
