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
> Terminals that are already open keep working during the migration, because a
> running shell does not re-read its rc files. Do the whole migration in one
> terminal, and do not open new ones until step 5 is done.

Most of the time goes into `brew bundle` and `mise install`.

## 1. Back up and check

```sh
backup=~/dotfiles-backup-$(date +%Y%m%d)
mkdir -p "$backup"
cp -p ~/.gitconfig ~/.tool-versions "$backup"/
cp -p ~/.config/git/ignore "$backup"/git-ignore
cp -p ~/.gnupg/gpg-agent.conf "$backup"/

# Record the current symlinks (used by "Rolling back" below)
find ~ -maxdepth 1 -type l -lname '*gkuga/dotfiles*' -exec ls -l {} \; > "$backup"/symlinks.txt
cat "$backup"/symlinks.txt
```

Write down anything you still want from the old zsh setup: the untracked or
modified files are shown by `git -C ~/dev/src/github.com/gkuga/dotfiles status`.
They do not carry over. Step 7 lists the usual candidates.

## 2. Install the new packages

Install from the new Brewfile without switching the checkout yet:

```sh
cd ~/dev/src/github.com/gkuga/dotfiles
git fetch origin
git show origin/master:packages/Brewfile > /tmp/Brewfile
brew bundle --file=/tmp/Brewfile
```

This adds bash 5, bash-completion@2, tmux, chezmoi, mise and the rest. Nothing
in `$HOME` changes yet.

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

Do not delete the old links' targets by hand. `~/.profile.d` was a symlink, so
it is gone now, and step 5 creates it again with only the new files. Copying the
old directory would keep `99-asdf.sh`, which puts asdf ahead of mise on `PATH`.

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

Check it in a **new** terminal (the login shell is still zsh, so start bash):

```sh
/opt/homebrew/bin/bash -l
echo "$PATH" | tr : '\n' | head -5   # mise shims, ~/.local/bin, Homebrew first
git config --get-regexp '^url\.'     # comes from ~/.gitconfig.local
cd ~/dev/src/github.com/gkuga/dotfiles
```

Work in this bash for the rest of the migration: the old zsh terminal still has
the asdf `PATH`.

## 6. Move from asdf to mise

mise reads the existing `.tool-versions` files in the projects, so they do not
need changes. Only the global versions move to
`~/.config/mise/config.toml`.

```sh
mv ~/.tool-versions ~/dotfiles-backup-$(date +%Y%m%d)/tool-versions.global
./install.sh --only mise      # mise install for the global tools, Claude Code CLI
```

> [!NOTE]
> The global `python` is now `3.12.16`, not `3.12.5`. mise verifies the GitHub
> artifact attestations of the prebuilt Python builds, and older builds such as
> 3.12.5 or 3.10.6 have none, so mise refuses to install them.

Then install the tools of each project:

```sh
ghq list -p | while read -r dir; do
  [ -f "$dir/.tool-versions" ] && (cd "$dir" && echo "== $dir" && mise install)
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
- Port what you still need from the old zsh setup into `~/.bashrc.local`:

  ```sh
  # Docker CLI completion (Docker Desktop)
  for f in /Applications/Docker.app/Contents/Resources/etc/docker{,-compose}.bash-completion; do
    [ -r "$f" ] && . "$f"
  done
  # cargo completion (after mise installed rust)
  command -v rustup >/dev/null && . <(rustup completions bash cargo)
  ```

- Once everything has worked for a few days:

  ```sh
  brew uninstall asdf
  rm -rf ~/.asdf                      # about 14 GB here
  git -C ~/dev/src/github.com/gkuga/dotfiles stash list   # drop the stash when unneeded
  ```

## Rolling back

The new Homebrew packages, mise tools and the Claude Code CLI can stay; they
do not get in the way of the old setup. As long as `~/.asdf` still exists, this
restores the old dotfiles:

```sh
cd ~/dev/src/github.com/gkuga/dotfiles
git switch --detach 13645d5          # last commit of the symlink setup
git stash pop                        # the old local changes
# Recreate the links listed in the backup's symlinks.txt, e.g.
ln -sfn ~/dev/src/github.com/gkuga/dotfiles/zshrc ~/.zshrc
mv ~/dotfiles-backup-*/tool-versions.global ~/.tool-versions
cp ~/dotfiles-backup-*/.gitconfig ~/.gitconfig
```

After step 7, also run `chsh -s /bin/zsh`.
