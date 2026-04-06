# do-diligence

`do-diligence` is a small desktop utility that watches `~/Downloads` for newly finished files, computes each file's SHA256 hash, and compares it against a SHA256 value stored in your clipboard. It logs the result and plays a success or failure sound so you can quickly verify downloads.

## How it works

1. Copy the expected SHA256 hash to your clipboard.
2. Download a file into `~/Downloads`.
3. The watcher waits for the file to finish writing, hashes it, and compares it to the clipboard value.
4. Results are written to `~/.local/share/do_diligence.log`.

## Requirements

- Linux desktop with a user `systemd` session
	- *Was written and tested on Kali, your mileage may vary with other distros.*
- `inotifywait`
- `sha256sum`
- `xclip` or `xsel` for clipboard access
- `paplay` for sound playback

## Installation

**Run:**

```bash
chmod +x install.sh
./install.sh
```

**The installer:**

- links `bin/do_diligence.sh` into `~/bin`
- links the user service into `~/.config/systemd/user`
- links the autostart entry into `~/.config/autostart`
- reloads the user `systemd` daemon
- starts `do_diligence.service`

## Usage

After installation, the service runs in the background. 

**To verify it is running:**

```bash
systemctl --user status do_diligence.service
```

**Then:**

1. Copy a SHA256 hash to your clipboard.
2. Download a file into `~/Downloads`.
3. Check the log if needed:

```bash
tail -f ~/.local/share/do_diligence.log
```
