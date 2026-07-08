# .shellcustomization

Personal shell and tooling dotfiles, kept in one repo and shared across
multiple hosts. Cloned to `~/.shellcustomization`; `init.sh` symlinks the files
into `$HOME` so edits in the repo take effect live.

## Requirements

These dotfiles assume a Linux host with **bash** and GNU **coreutils** (used
for `dircolors`), plus:

| Tool | Used by |
|------|---------|
| `git` | `update.sh`, `.gitconfig` |
| `screen` | `.bash_profile` auto-attach, `.screenrc` |
| `vim` | `.vimrc`, `$EDITOR` |
| `gzip` | `compress-screenlogs.sh` |
| `lsof` | `compress-screenlogs.sh` (detecting logs still open) |

Optional: **bash-completion** (sourced by `.bashrc` if present).

`init.sh` checks for these on startup. If any are missing it prints the
appropriate install command for the detected package manager (`emerge`, `apt`,
`dnf`, `yum`, `pacman`, `zypper`, or `apk`) and offers to run it — it never
installs anything without asking.

## Installation

```sh
git clone git@github.com:tomribbens/.shellcustomization.git ~/.shellcustomization
~/.shellcustomization/init.sh
```

`init.sh` is idempotent — re-running it is safe and silent (it skips symlinks
that already point at the right place and only prompts before overwriting
something unexpected).

## Updating

```sh
~/.shellcustomization/update.sh   # cd ~/.shellcustomization && git pull
```

On hosts running the auto-screen login (see below), a dedicated screen window
(number 9) runs `update.sh` at session start.

> **Note:** the git remote uses SSH (`git@github.com:...`). `.gitconfig` also
> rewrites `https://github.com/` URLs to SSH automatically, so pushes don't
> prompt for HTTPS credentials.

## Files

### Dotfiles (symlinked into `$HOME` by `init.sh`)

| File | Purpose |
|------|---------|
| `.bashrc` | Interactive bash config: prompt, aliases, history, completion, PATH, `shopt` options, dircolors. |
| `.bash_profile` | Login shell: stabilises the forwarded SSH agent socket, sources `.bashrc`, compresses screen logs, and starts/attaches screen. |
| `.inputrc` | Readline: prefix history search on ↑/↓, case-insensitive and coloured completion. |
| `.screenrc` | GNU screen: session logging, status caption, and startup windows. |
| `.vimrc` | Vim config with persistent undo and swap/backup dirs under `~/.vim`. |
| `.gitconfig` | Git identity, aliases, and quality-of-life defaults (see below). |
| `.dircolors` | `LS_COLORS` palette applied by `.bashrc`. |
| `.gitignore_global` | Ignore patterns applied to every repo via `core.excludesfile`. |
| `authorized_keys` | Shared SSH public keys → `~/.ssh/authorized_keys`. |
| `ssh_config` | Shared SSH **client** defaults, pulled into `~/.ssh/config` via an `Include` line (not symlinked — see below). |

### Scripts

| Script | Runs as | Purpose |
|--------|---------|---------|
| `init.sh` | user | Bootstrap: create the symlinks, wire up SSH keys, and make required directories. |
| `update.sh` | user | `git pull` the repo. |
| `compress-screenlogs.sh` | user | Gzip finished screen logs and prune old archives. |
| `setup_sudo_ssh_auth.sh` | **root** | Configure sudo to authenticate via SSH agent forwarding (Debian/Ubuntu or Gentoo). |

### Per-host files

These let one shared repo behave differently per machine without branching:

| Pattern | Effect |
|---------|--------|
| `.bashrc_<fqdn>` | Sourced by `.bashrc` at the end if it matches `hostname -f`. Host-specific env/aliases. Examples in-repo: `db.aginti.eu`, `phoebe.lan.multi-air.com`. |
| `authorized_keys_<fqdn>` | Symlinked to `~/.ssh/authorized_keys2` by `init.sh` when it matches this host. Host-specific SSH keys, kept out of the shared `authorized_keys`. Example in-repo: `jessica.lan.tomribbens.be`. |

## Notable behaviours

### SSH agent forwarding that survives screen reattach

Every new SSH connection creates a fresh `$SSH_AUTH_SOCK`, so shells inside a
long-lived screen session end up pointing at a dead socket after you reattach
over a new connection. `.bash_profile` re-points a stable symlink
(`~/.ssh/ssh_auth_sock`) at the current live socket on each login, and `.bashrc`
makes every shell use that stable path — so agent forwarding keeps working
across reattaches.

### Auto screen login (opt-out per host)

`.bash_profile` runs `screen -xRR` on login (attach if a session exists, else
create one). To disable this on a given host — e.g. a local workstation where
you want the dotfiles but not the auto-attach — create the marker file:

```sh
touch ~/.no_auto_screen
```

### Per-host SSH keys via `authorized_keys2`

sshd reads both `~/.ssh/authorized_keys` and `~/.ssh/authorized_keys2` by
default. Shared keys live in `authorized_keys`; host-specific keys go in
`authorized_keys_<fqdn>`, which `init.sh` links to `authorized_keys2`. If a
host's sshd is configured *not* to read `authorized_keys2`, `init.sh` prints a
warning (the host keys would otherwise be silently ignored).

### Screen log compression

Screen logs each window to `~/.screenlogs`. `compress-screenlogs.sh` gzips
finished logs — skipping any a live window still holds open, so it's always
safe to run — and deletes archives older than `RETENTION_DAYS` (365) to bound
growth. It runs backgrounded from `.bash_profile` on every login (no cron
dependency).

### SSH client defaults (connection reuse, keepalives)

`ssh_config` holds shared client defaults (a `Host *` block: `ControlMaster`
connection multiplexing, `ServerAliveInterval` keepalives, `AddKeysToAgent`).
`init.sh` prepends an `Include ~/.shellcustomization/ssh_config` line to
`~/.ssh/config` rather than symlinking it, so your host-specific `Host` entries
stay put and are never overwritten. It also creates `~/.ssh/control` (mode
0700) for the multiplexing sockets. ssh uses the first value it sees per option,
and host-specific blocks (earlier in the file) still win over the `Host *`
defaults.

### Local `.bashrc` drop-ins

`.bashrc` also sources any regular file in `~/.bashrc.d/`, for machine-local
tweaks you don't want committed to the repo.

## `.gitconfig` highlights

- Rewrites `https://github.com/` remotes to SSH automatically.
- `pull.ff = only` — refuses to silently create a merge on divergence.
- `rebase.autostash` — auto-stashes/reapplies local changes around a rebase.
- `rerere.enabled` — remembers conflict resolutions.
- `fetch.prune`, `merge.conflictstyle = zdiff3`, `core.editor = vim`.
- `diff.algorithm = histogram`, `diff.colorMoved = zebra`, `commit.verbose`.
- `core.excludesfile = ~/.gitignore_global`.
- Aliases: `git st` (`status -sb`), `git lg` (graph log).
- `[safe]` entries are host-local CI runner paths (added by a self-hosted
  GitHub Actions runner).

## Continuous integration

`.github/workflows/shellcheck.yml` runs `shellcheck` over the shell scripts on
every push and pull request, using a GitHub-hosted `ubuntu-latest` runner.
