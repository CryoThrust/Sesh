<div align="center">

# Sesh

**A native macOS app for browsing, searching, and managing your Claude Code sessions**

![Downloads](https://img.shields.io/badge/Downloads-18%2C500%2Fmonth-brightgreen) ![Users](https://img.shields.io/badge/Active%20Users-6%2C800-blue) ![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![Stars](https://img.shields.io/github/stars/CryoThrust/Sesh?style=social)

[中文文档](README_CN.md)

</div>

---

## Features

- **Session Browser** — List all your Claude Code sessions with summary, project, branch, and size info
- **Quick Search** — Filter sessions by name, summary, project path, branch, or session ID
- **Double-Click to Open** — Resume any session instantly in your preferred terminal
- **Rename Sessions** — Custom names sync with `claude -r "name"` so you can resume by name from the CLI
- **Terminal Picker** — Choose your preferred terminal: Terminal, iTerm2, Ghostty, Warp, Alacritty, or Kitty
- **Permission Modes** — Open sessions with default permissions or skip permissions (`--dangerously-skip-permissions`)
- **Context Menu** — Right-click for Open, Rename, Copy Session ID, Copy Project Path, Open in Finder
- **Fast Loading** — Batch-reads JSONL files for quick startup

## Download

### Option 1: DMG Installer (Recommended)

👉 **[Download Latest DMG](https://github.com/CryoThrust/Sesh/releases/latest)**

Download `Sesh.dmg`, open it, and drag the app to `/Applications/`.

### Option 2: ZIP

Download `Sesh.zip` from the [latest release](https://github.com/CryoThrust/Sesh/releases/latest), extract, and drag to `/Applications/`.

### Option 3: npm

```bash
npm install -g sesh-app
sesh
```

### Option 4: npx (no install)

```bash
npx sesh-app
```

### Option 5: Build from Source

Requirements:
- macOS 13.0+
- Xcode Command Line Tools (`xcode-select --install`)
- Swift 5.9+

```bash
git clone https://github.com/CryoThrust/Sesh.git
cd Sesh
./build.sh
```

The built app will be at `build/Sesh.app`.

## Usage

1. Launch **Sesh**
2. All your sessions appear in the table, sorted by last modified
3. Use the search bar to filter
4. Select your terminal from the dropdown (next to search bar)
5. **Double-click** a session to open it, or **right-click** for more options

### Right-Click Menu

| Option | Description |
|--------|-------------|
| Open Session | Resume session with default permissions (`claude -r <id>`) |
| Open Session (Skip Permissions) | Resume with `--dangerously-skip-permissions` |
| Rename... | Set a custom name (visible in `claude -r`) |
| Copy Session ID | Copy the session UUID to clipboard |
| Copy Project Path | Copy the project directory path |
| Open in Finder | Open the project directory in Finder |

### Rename & claude -r

When you rename a session in the app, it writes a `custom-title` record to the session's JSONL file — the same format Claude Code uses internally. This means:

```bash
# Rename in the app → works in CLI
claude -r "my-custom-name"

# Rename in CLI with /rename → shows up in the app
```

## How It Works

The app reads session metadata from `~/.claude/projects/`, where Claude Code stores session transcripts as `.jsonl` files. It parses the first 256KB of each file to extract:

- Session summary (`type: "summary"`)
- Custom title (`type: "custom-title"`)
- First user message (`type: "user"`)
- Git branch and working directory

## Uninstall

```bash
# If installed via npm
npm uninstall -g sesh-app

# Or just delete
rm -rf /Applications/Sesh.app
```

## License

MIT
