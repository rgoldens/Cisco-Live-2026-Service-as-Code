# Terminal Image Style Reference

This document defines the exact settings used to produce terminal/code screenshot PNGs
for the LTRATO-1001 lab guide. All future terminal images must follow these specs.

---

## General HTML Template Settings

| Setting | Value |
|---|---|
| Font family | `'JetBrains Mono', 'Courier New', monospace` |
| Font import | `https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&display=swap` |
| Font size | `13.5px` |
| Line height | `1.7` |
| Container width | `860px` |
| Padding | `22px 28px 22px 28px` |
| Background (body) | `#000000` |
| Background (terminal div) | `#000000` |
| Overflow | `hidden` (both `html` and `body`) |
| Box sizing | `border-box` on `*` |
| Margin/padding reset | `0` on `*` |
| Viewport meta | `width=1200` |

Screenshot method: measure `scrollHeight` of `.terminal`, resize page to that exact height × 860px wide, then capture viewport (not fullPage).

---

## HTML Boilerplate

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=1200" />
<title>image title</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&display=swap');

  * { box-sizing: border-box; margin: 0; padding: 0; }
  html, body { overflow: hidden; }

  body {
    background: #000000;
    font-family: 'JetBrains Mono', 'Courier New', monospace;
  }

  .terminal {
    background: #000000;
    width: 860px;
    padding: 22px 28px 22px 28px;
    font-size: 13.5px;
    line-height: 1.7;
  }

  /* — paste color token classes here — */
</style>
</head>
<body>
<div class="terminal">
<pre><!-- content here --></pre>
</div>
</body>
</html>
```

---

## Color Tokens — Ansible Terminal Output  
*(used in all `task1-step4`, `task1-verify`, `task1-ping`, `task1-recap`, `task1-adhoc-failed`, `task1-check-diff`, `task1-remediate`, `task1-remediate-ping` images)*

| Element | CSS class | Hex | Notes |
|---|---|---|---|
| `ok:` status lines + host names when ok | `.ok` | `#00e676` | Bright green |
| `changed:` status lines + host names when changed | `.chg` | `#e5c07b` | Yellow |
| `skipping:` status lines + host names | `.skp` | `#00b8c8` | Cyan (same hex as warning/comment) |
| `[ERROR]` block — entire failed output | `.err` | `#ff5555` | Red |
| `[WARNING]:` lines | `.warn` | `#00b8c8 italic` | Cyan italic (same as `.cm`) |
| All other text (PLAY headers, TASK headers, output body) | `.wh` | `#ffffff` | White |
| Comment / truncation note `# Output truncated...` | `.cm` | `#00b8c8 italic` | Cyan italic |

### CSS Classes (Ansible output)

```css
.ok   { color: #00e676; }                      /* ok status — bright green */
.chg  { color: #e5c07b; }                      /* changed status — yellow */
.skp  { color: #00b8c8; }                      /* skipping status — cyan */
.err  { color: #ff5555; }                      /* error/failed block — red */
.warn { color: #00b8c8; font-style: italic; }  /* warning lines — cyan italic */
.wh   { color: #ffffff; }                      /* default text — white */
.cm   { color: #00b8c8; font-style: italic; }  /* comments — cyan italic */
```

---

## Color Tokens — YAML Playbook  
*(confirmed against `task1-step2-playbook-clean.png` and `task1-vars-block.png`)*

| Element | CSS class | Hex | Notes |
|---|---|---|---|
| All YAML keys (`vars:`, `vlan_config:`, `n9k-ce01:`, `id:`, `name:`, `hosts:`, `gather_facts:`, `tasks:`, `config:`, `state:`, `mode:`, `access:`, `vlan:`, `save_when:`) | `.k` | `#00e676` | Bright green — every `key:` regardless of nesting level |
| Module names (`cisco.nxos.nxos_vlans:`, etc.) | `.k` | `#00e676` | Same bright green as keys |
| Unquoted values (`nxos`, `false`, `active`, `merged`, `layer2`, `modified`, `Ethernet1/3`) | `.wh` | `#ffffff` | White |
| Quoted string values after `name:` (task names, VLAN names) — entire string incl. quotes | `.ph` | `#c678dd` | Purple — quotes and content |
| `___` unquoted placeholder | `.wh` | `#ffffff` | White — no quotes |
| `"___"` quoted placeholder — entire string incl. quotes | `.ph` | `#c678dd` | Purple — quotes and content together |
| Jinja2 brackets `{{` and `}}` | `.jj` | `#e5c07b` | Yellow |
| Jinja2 variable inside brackets (`vlan_config[inventory_hostname].id`) | `.ph` | `#c678dd` | Purple |
| List item dashes (`-`) under `config:` | `.d` | `#e5c07b` | Yellow |
| `- name:` task dash | `.d` | `#e5c07b` | Yellow |
| Comments (`# TODO: ...`) | `.cm` | `#00b8c8` italic | Cyan italic |

### CSS Classes

```css
.k  { color: #00e676; }                      /* all YAML keys — bright green */
.wh { color: #ffffff; }                      /* unquoted values — white */
.ph { color: #c678dd; }                      /* quoted strings, placeholders, Jinja2 vars — purple */
.jj { color: #e5c07b; }                      /* Jinja2 {{ }} brackets — yellow */
.d  { color: #e5c07b; }                      /* list dashes — yellow */
.cm { color: #00b8c8; font-style: italic; }  /* comments — cyan italic */
```

---

## Color Tokens — `ls -la` Output  
*(used in `images/task5-ls-output.html`)*

| Element | CSS class | Color |
|---|---|---|
| Default text / permissions / owner / group / size / date | `.perms`, `.links`, `.owner`, `.group`, `.size`, `.date`, `.name-file` | `#c8d0d8` |
| Inode numbers | `.inode` | `#6a7a8a` |
| Directory names (`.`, `..`, named dirs) | `.name-dir` | `#00aaff` bold |
| Hidden dirs/files (`.terraform`) | `.name-hidden` | `#00aaff` bold |
| Regular `.tf` and config files | `.name-tf` | `#c8d0d8` |
| `total N` line | `.total` | `#6a7a8a` |

---

## Screenshot Workflow

1. Write content as HTML using the boilerplate above.
2. Open in Chrome DevTools MCP (`chrome-devtools_navigate_page`).
3. Measure height: `() => { const el = document.querySelector('.terminal'); return { w: el.scrollWidth, h: el.scrollHeight }; }`
4. Resize page to exact height × 860px wide (`chrome-devtools_resize_page`).
5. Take screenshot to the target PNG path (`chrome-devtools_take_screenshot` — viewport, not fullPage).
6. Preview in response to verify colors look correct before committing.
7. Commit both HTML source and PNG together.

---

## File Naming Convention

| Type | HTML source | PNG output |
|---|---|---|
| `ls -la` output | `images/<name>.html` | `images/<name>.png` |
| YAML/code block | `images/<name>.html` | `images/<name>.png` |

HTML sources are committed alongside PNGs so they can be edited and re-screenshotted.

---

## Confirmed Images

| PNG | HTML source | Notes |
|---|---|---|
| `images/task5-ls-output.png` | `images/task5-ls-output.html` | `ls -la` color scheme |
| `images/task1-vars-block.png` | `images/task1-vars-block.html` | YAML playbook color scheme |
| `images/task1-step2-playbook-clean.png` | *(no HTML source — original reference image)* | Full playbook — color reference |
| `images/task1-step4-output.png` | `images/task1-step4-output.html` | Ansible terminal — first run config tasks |
| `images/task1-verify-output.png` | `images/task1-verify-output.html` | Ansible terminal — verify VLAN brief output |
| `images/task1-ping-output.png` | `images/task1-ping-output.html` | Ansible terminal — ping test output |
| `images/task1-recap-output.png` | `images/task1-recap-output.html` | Ansible terminal — PLAY RECAP (955px wide) |
| `images/task1-adhoc-failed-output.png` | `images/task1-adhoc-failed-output.html` | Ansible terminal — ad-hoc failed red block |
| `images/task1-check-diff-output.png` | `images/task1-check-diff-output.html` | Ansible terminal — check/diff dry run |
| `images/task1-remediate-output.png` | `images/task1-remediate-output.html` | Ansible terminal — remediation run |
| `images/task1-remediate-ping-output.png` | `images/task1-remediate-ping-output.html` | Ansible terminal — remediation ping verify |
