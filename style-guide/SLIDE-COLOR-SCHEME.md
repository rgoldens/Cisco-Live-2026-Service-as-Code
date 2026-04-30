# Slide Color Scheme — LTRATO-1001 Cisco Live 2026

Reference for recreating or extending slides consistently.

---

## Backgrounds

| Element | Hex | Description |
|---|---|---|
| **Outer background** | `#0a0a0a` | Near black — surrounds the slide |
| **Slide background** | `#0e1621` | Dark navy — main slide area |
| **Card background** | `#141e2b` | Slightly lighter navy — content cards |
| **Code block background** | `#0e1621` | Same as slide background |

---

## Text

| Element | Hex | Description |
|---|---|---|
| **Main title** | `#ffffff` | White, bold |
| **Body text** | `#c8d0d8` | Light grey-white |
| **Breadcrumb "LTRATO-1001"** | `#00aaff` | Cyan-blue |
| **Breadcrumb separator & section label** | `#00d4ff` | Bright cyan |
| **Dimmed / secondary text** | `#5a6a7a` | Muted grey |

---

## Accent Colors (card top borders & highlights)

| Name | Hex | Used For |
|---|---|---|
| **Cyan** | `#00aaff` | Provider, Write step, general highlight |
| **Green** | `#00cc66` | Resource, `terraform apply` |
| **Orange** | `#ff8800` | State File, `terraform destroy` |
| **Purple/Blue** | `#7b68ee` | Module |
| **Grey** | `#6b7280` | Write step (neutral / first step) |

---

## UI Elements

| Element | Color |
|---|---|
| **Top horizontal divider line** | Dual-line: `#00aaff` `strokeWidth=3` (top) + `#00d4ff` `strokeWidth=1` (bottom, offset 6px below) |
| **Card top border accent** | Matches accent color per card (see above) |
| **Command bar / terminal pill** | `#1e2d3d` background, accent-colored text |
| **Arrow connectors** | `#4a5568` grey |

---

## Typography

| Element | Style |
|---|---|
| **Slide title** | Large, bold, `#ffffff` |
| **Subtitle** | Medium, regular, `#c8d0d8` |
| **Breadcrumb** | Small — `#00aaff` label + `#00d4ff` separator/section |
| **Card heading** | Medium, bold, `#ffffff` |
| **Card body** | Small, regular, `#c8d0d8` |
| **Dimmed text** | Small, `#5a6a7a` |
| **Slide counter** | Small, `#5a6a7a`, bottom-right aligned, format `n/N` |
| **Font family** | Sans-serif (Inter or similar clean sans) |

---

## Layout

- **Header area:** Left-aligned breadcrumb (`LTRATO-1001 | Section Label`) above title — **mandatory on every diagram and slide**
- **Divider:** Dual-line — thick `#00aaff` (`strokeWidth=3`) on top, thin `#00d4ff` (`strokeWidth=1`) 6px below it
- **Content area:** 2×2 grid of cards (or single/variable layout depending on slide)
- **Cards:** Dark navy background (`#141e2b`), single-color top border accent, bold heading + body text
- **Slide counter:** Bottom-right corner

---

## Breadcrumb — Mandatory Element

Every diagram and slide **must** include the breadcrumb in the upper-left corner:

```
LTRATO-1001  |  Service Insertion as Code: From Concept to Commit
```

| Part | Color | Style |
|---|---|---|
| `LTRATO-1001` | `#00aaff` | Small, regular |
| ` \| ` separator | `#5a6a7a` | Small, regular |
| Section label (e.g. `Ansible Lab`, `Task 1`) | `#00aaff` | Small, regular |

**draw.io HTML value:**
```html
<font color="#00aaff">LTRATO-1001</font><font color="#5a6a7a"> | </font><font color="#00aaff">Service Insertion as Code: From Concept to Commit</font>
```

**Position:** top-left, x=25, y=12, above the slide title.  
The dual-line divider sits below the title: thick `#00aaff` line (`strokeWidth=3`) with a thin `#00d4ff` line (`strokeWidth=1`) 6px below it.

> **Note:** Always use both lines — thick cyan on top, thin teal 6px below. This matches the reference template exactly.

---

## CSS / HTML Quick Reference

```css
/* Backgrounds */
--bg-outer:      #0a0a0a;
--bg-slide:      #0e1621;
--bg-card:       #141e2b;
--bg-code:       #0e1621;
--bg-terminal:   #1e2d3d;

/* Accents */
--accent-cyan:   #00aaff;
--accent-teal:   #00d4ff;
--accent-green:  #00cc66;
--accent-orange: #ff8800;
--accent-purple: #7b68ee;
--accent-grey:   #6b7280;

/* Text */
--text-primary:   #ffffff;
--text-body:      #c8d0d8;
--text-dim:       #5a6a7a;
--text-breadcrumb:#00aaff;
--text-section:   #00d4ff;

/* UI */
--border-card:    matches accent color per card;
--arrow:          #4a5568;
```
