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
| **YAML module FQCNs** | `#c792ea` | Purple — used for Ansible module names (e.g. `cisco.nxos.nxos_vlans`) |

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
| `failed` | Red | `#e06c75` — when entire output is failure/stderr, use this color for ALL lines |
| `skipping` | Cyan | `#00aaaa` |
| Headers / plain text | Bright white | `#e8e8e8` |
| Informational text | Light grey | `#cccccc` |
| YAML module FQCNs | Purple | `#c792ea` |

---

## Standard Image Width

All terminal output images **must be 980px wide**. This ensures consistent rendering
across the lab guide. Always use `--window-size=980,<height>` when exporting.

---

## Export Process

1. Write content to an HTML file using `<span>` tags with the colors above
2. Export with headless Chrome at **980px width**:
   ```bash
   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
     --headless=new --disable-gpu \
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
| `task1-ping-output.png` | Task 1 — ping test play output (client1→client2, client3→client4) |
| `task1-recap-output.png` | Task 1 — PLAY RECAP summary (all 6 hosts, first run) |
| `task1-adhoc-failed-output.png` | Task 1 — ad-hoc raw ping showing expected FAILED/rc=1 output |
| `task1-check-diff-output.png` | Task 1 — `--check --diff` dry-run output showing drift detected on n9k-ce01 |
| `task1-remediate-output.png` | Task 1 — actual remediation run output (Steps 1–4 + pause, changed on n9k-ce01 Step 3) |
| `task1-remediate-ping-output.png` | Task 1 — ping verification after remediation (0% packet loss on both client pairs) |
| `task2-nxos-output.png` | Task 2 — Play 1 NX-OS IS-IS config (Steps 1–6) |
| `task2-csr-output.png` | Task 2 — Play 2 CSR PE IS-IS config (Steps 1–4 + wait) |
| `task2-linux-routes-output.png` | Task 2 — Play 3 Linux client route additions |
| `task2-verify-output.png` | Task 2 — NX-OS IS-IS neighbors and routes verification |
| `task2-csr-verify-output.png` | Task 2 — CSR PE IS-IS neighbor verification |
| `task2-ping-output.png` | Task 2 — Ping test results + PLAY RECAP |
| `task3-xrd-output.png` | Task 3 — Play 1 XRd VRF and BGP config (Steps 1–5b, all ok) |
| `task3-bgp-config-output.png` | Task 3 — XRd show run router bgp display |
| `task3-csr-output.png` | Task 3 — Play 2 CSR PE BGP config (Steps 1–4, changed) |
| `task3-linux-routes-output.png` | Task 3 — Play 3 Linux cross-site route additions |
| `task3-pause-output.png` | Task 3 — 90-second BGP convergence pause |
| `task3-bgp-summary-output.png` | Task 3 — XRd BGP VPNv4 summary (3 prefixes received) |
| `task3-vrf-routes-output.png` | Task 3 — XRd VRF route table (6 prefixes, 6 paths) |
| `task3-csr-bgp-summary-output.png` | Task 3 — CSR PE BGP summary (4 prefixes received) |
| `task3-ping-output.png` | Task 3 — Cross-site ping results (4 clients) + PLAY RECAP |
| `task1-step2-read-playbook.png` | Task 1 Step 2 — nano editor screenshot showing full playbook with comments |
| `task1-step2-playbook-clean.png` | Task 1 Step 2 — syntax-highlighted clean playbook view (no block comments, TODO inline comments kept) |
