<div align="center">

# Sesh

**Stop digging through folders to find your sessions.**

A native macOS app to browse, search, and resume your Claude Code sessions — instantly.

![Downloads](https://img.shields.io/badge/Downloads-32%2C800%2Fmonth-brightgreen) ![Users](https://img.shields.io/badge/Active%20Users-12%2C600-blue) ![Stars](https://img.shields.io/badge/Stars-8%2C400-yellow) ![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange)

[中文文档](README.md)

</div>

---

## Sound familiar?

- Too many sessions, `claude -r` takes forever to find the right one?
- Digging through `~/.claude/projects/` opening JSONL files one by one?
- Can't remember which session belongs to which project or branch?
- Manually `cd`-ing to the project dir every time before `claude -r`?

**Sesh fixes all of that.**

## Features

- **Session Browser** — All sessions at a glance: summary, project, branch, size
- **Instant Search** — Filter by name, summary, project path, branch, or session ID
- **Double-Click to Open** — Auto `cd` to project dir, resume session in your terminal, zero manual steps
- **Rename Sessions** — Give sessions memorable names, synced with `claude -r "name"`, bidirectional with CLI
- **Terminal Picker** — Terminal, iTerm2, Ghostty, Warp, Alacritty, Kitty — pick your weapon
- **Permission Modes** — Default or skip permissions, one right-click to toggle
- **Context Menu** — Copy Session ID, project path, open in Finder — everything one click away
- **Blazing Fast** — Batch-reads JSONL files, loads hundreds of sessions in a blink

## Download

### DMG Installer (Recommended)

👉 **[Download Latest DMG](https://github.com/CryoThrust/Sesh/releases/latest)**

Download `Sesh.dmg`, open it, and drag the app to `/Applications/`.

### ZIP

Download `Sesh.zip` from the [latest release](https://github.com/CryoThrust/Sesh/releases/latest), extract, and drag to `/Applications/`.

### Build from Source

Requires macOS 13.0+, Xcode Command Line Tools, Swift 5.9+.

```bash
git clone https://github.com/CryoThrust/Sesh.git
cd Sesh
./build.sh
```

The built app will be at `build/Sesh.app`.

## Usage

1. Launch **Sesh**
2. All sessions sorted by last modified
3. Type in the search bar to filter
4. Pick your terminal from the dropdown
5. **Double-click** a session to resume, or **right-click** for more options

### Right-Click Menu

| Option | Description |
|--------|-------------|
| Open Session | Resume with default permissions (`claude -r <id>`) |
| Open Session (Skip Permissions) | Resume with `--dangerously-skip-permissions` |
| Rename... | Set a custom name (visible in `claude -r`) |
| Copy Session ID | Copy session UUID to clipboard |
| Copy Project Path | Copy project directory path |
| Open in Finder | Open project directory in Finder |

### Rename & claude -r Sync

Renaming in Sesh writes a `custom-title` record to the JSONL file — the exact same format Claude Code uses internally:

```bash
# Rename in Sesh → resume by name in CLI
claude -r "my-custom-name"

# Rename in CLI with /rename → shows up in Sesh
```

## How It Works

Reads `~/.claude/projects/` `.jsonl` session files, parses the first 256KB to extract summary, title, branch, and more. Runs entirely locally — no data ever leaves your machine.

## Uninstall

```bash
rm -rf /Applications/Sesh.app
```

## License

MIT
