# Ansible Terminal Output — Image Color Reference

Reference for recreating or extending Ansible terminal output images consistently.

## Source HTML

The HTML template used to generate these images is stored at `/tmp/ansible-output.html`
(not git-tracked). Recreate from scratch using the colors and structure below.

---

## Colors

| Element | Hex | Description |
|---|---|---|
| **Background** | `#0c0c0c` | Near-black terminal background |
| **TASK / PLAY headers** | `#e8e8e8` | Bright white — task names and asterisk lines |
| **`changed:` lines** | `#e5c000` | Golden yellow — matches Ansible terminal output |
| **`ok:` lines** | `#00cc44` | Bright green — matches Ansible terminal output |
| **Pause / informational text** | `#cccccc` | Light grey — non-status output lines |

---

## Font

| Property | Value |
|---|---|
| **Font family** | `SF Mono`, `Menlo`, `monospace` (system fallback chain) |
| **Font size** | `13px` |
| **Line height** | `1.6` |

---

## Status Color Key

| Ansible Status | Color | Hex |
|---|---|---|
| `changed` | Golden yellow | `#e5c000` |
| `ok` | Bright green | `#00cc44` |
| `failed` | Red (not yet used) | `#e06c75` |
| `skipping` | Cyan (not yet used) | `#56b6c2` |
| Headers / plain text | Bright white | `#e8e8e8` |
| Informational text | Light grey | `#cccccc` |

---

## Export Process

1. Write content to an HTML file using `<span>` tags with the colors above
2. Export with headless Chrome:
   ```bash
   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
     --headless=new --disable-gpu \
     --run-all-compositor-stages-before-draw \
     --screenshot="images/<filename>.png" \
     --window-size=980,<height> --hide-scrollbars \
     "file:///tmp/ansible-output.html"
   ```
3. Auto-crop bottom empty space with Python Pillow if needed

---

## Images in This Folder Using This Scheme

| File | Description |
|---|---|
| `task1-step4-output.png` | Task 1 — first run playbook output (Steps 1–4 + pause) |
| `task1-verify-output.png` | Task 1 — verify play output (Show VLAN brief + Display VLAN status) |
