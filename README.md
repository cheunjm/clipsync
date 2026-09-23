# clipsync

Auto-sync clipboard images over SSH between two Macs — paste a screenshot
locally, `Ctrl+V`/`Cmd+V` it natively on a remote machine a couple seconds
later. Built for pasting screenshots into a remote [Claude
Code](https://claude.com/claude-code) session (or any other remote terminal
app) when you're SSH'd from a laptop into a home server/workstation.

## How it works

A small LaunchAgent polls your local clipboard every few seconds
(`pngpaste`). When it finds a new image, it `scp`s it to the remote host and
runs `osascript` there to write it straight into the remote machine's native
macOS clipboard. No daemon pairing, no auth tokens — it just rides your
existing SSH key trust.

**Requires macOS on both ends** (uses `pngpaste` locally and `osascript`
remotely — this is not cross-platform).

## Install

```bash
git clone https://github.com/cheunjm/clipsync.git
cd clipsync
./install.sh <remote-host>
```

`<remote-host>` is anything `ssh <remote-host>` already works for (an
`~/.ssh/config` alias, a Tailscale MagicDNS name, a raw hostname/IP) —
passwordless key auth to it is required, since this runs unattended on a
timer.

Optional: `./install.sh <remote-host> --interval 5` to poll less often
(default: 2 seconds).

## Uninstall

```bash
./uninstall.sh
```

## Why not just use clipboard passthrough / tmux?

Terminal multiplexers (tmux) generally strip binary/image data from paste
operations, forwarding only text — and even outside tmux, a program running
in a remote SSH session has no path to your local OS clipboard by default.
clipsync sidesteps both problems by treating the sync as a file transfer +
a direct write to the remote OS clipboard, rather than relying on any
paste-passthrough mechanism.

## Config

All configuration is env vars, set automatically by `install.sh` in the
LaunchAgent's plist:

| Var | Default | Meaning |
|-----|---------|---------|
| `CLIPSYNC_REMOTE_HOST` | *(required)* | SSH host/alias to push images to |
| `CLIPSYNC_REMOTE_TMP_DIR` | `/tmp` | Remote scratch directory for transferred images |
| `CLIPSYNC_CACHE_DIR` | `~/.cache/clipsync` | Local state (last-synced hash, to avoid re-sending) |
| `CLIPSYNC_SSH_OPTS` | *(empty)* | Extra space-separated ssh/scp options |

## License

MIT
