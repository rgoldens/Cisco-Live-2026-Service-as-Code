#!/usr/bin/env python3
"""
Generate 4 Cisco DevNet dark-themed slides for the Terraform lab guide.
Output: slides/slide-01-what-is-terraform.png  through  slide-04-what-we-build.png
"""

from PIL import Image, ImageDraw, ImageFont
import os

FONT_DIR = "/System/Library/Fonts/Supplemental"
OUT_DIR = os.path.dirname(os.path.abspath(__file__))

W, H = 1200, 675

BG = "#0d1117"
PANEL = "#161b22"
BORDER = "#21262d"
TEAL = "#00bceb"
TEAL_DK = "#007fa3"
WHITE = "#ffffff"
GREY_LT = "#c9d1d9"
GREY_MD = "#8b949e"
ORANGE = "#f0883e"
GREEN = "#3fb950"


def font(size, bold=False):
    p = os.path.join(FONT_DIR, "Arial Bold.ttf" if bold else "Arial.ttf")
    return ImageFont.truetype(p, size)


def new_slide():
    img = Image.new("RGB", (W, H), BG)
    return img, ImageDraw.Draw(img)


def teal_bar(d):
    d.rectangle([(0, 0), (W, 6)], fill=TEAL)


def badge(d):
    d.text((28, 18), "LTRATO-1001  |  Terraform Lab", font=font(17), fill=TEAL)


def slide_num(d, n):
    d.text((W - 36, H - 28), f"{n}/6", font=font(16), fill=GREY_MD, anchor="rm")


def pill(d, x, y, w, h, fill, r=10):
    d.rounded_rectangle([x, y, x + w, y + h], radius=r, fill=fill)


def cx_text(d, cx, y, text, fnt, color):
    bb = d.textbbox((0, 0), text, font=fnt)
    d.text((cx - (bb[2] - bb[0]) // 2, y), text, font=fnt, fill=color)


def header_with_subtitle(d, title, subtitle):
    """Returns y just below divider (always 152)."""
    d.text((60, 46), title, font=font(52, bold=True), fill=WHITE)
    d.text((62, 114), subtitle, font=font(21), fill=GREY_LT)
    d.rectangle([(60, 150), (W - 60, 152)], fill=BORDER)
    return 152


def header_no_subtitle(d, title):
    """Returns y just below divider (always 118)."""
    d.text((60, 46), title, font=font(52, bold=True), fill=WHITE)
    d.rectangle([(60, 116), (W - 60, 118)], fill=BORDER)
    return 118


# ══════════════════════════════════════════════════════════════════════════════
# SLIDE 1 — What Is Terraform?
# 2×2 card grid.  div_y=152 → cards start at y=164, height=230 each, gap=16
# Row 1: y=164..394   Row 2: y=410..640   → bottom edge 640, fine within H=675
# ══════════════════════════════════════════════════════════════════════════════
def slide1():
    img, d = new_slide()
    teal_bar(d)
    badge(d)
    slide_num(d, 1)
    header_with_subtitle(
        d,
        "What Is Terraform?",
        "Open-source Infrastructure as Code (IaC) tool by HashiCorp",
    )

    cards = [
        (
            GREEN,
            "Reproducible",
            [
                "Same config = same environment, every time.",
                "No more hand-crafted 'snowflake' servers.",
                "Run it again — get the exact same result.",
            ],
        ),
        (
            TEAL,
            "Version-Controlled",
            [
                "Infrastructure lives in git alongside your code.",
                "Every change is tracked, reviewable, reversible.",
                "Roll back the same way you roll back app code.",
            ],
        ),
        (
            ORANGE,
            "Safe to Change",
            [
                "terraform plan shows the exact diff first.",
                "Add / change / destroy counts are explicit.",
                "Nothing touches real infra until you say yes.",
            ],
        ),
        (
            GREEN,
            "Easy to Clean Up",
            [
                "terraform destroy removes everything it made,",
                "in the correct dependency order.",
                "No orphaned resources. No manual teardown.",
            ],
        ),
    ]

    CW, CH = 558, 228
    GAP_X, GAP_Y = 24, 16
    START_X = (W - (2 * CW + GAP_X)) // 2  # = 19
    START_Y = 164

    for i, (color, title, lines) in enumerate(cards):
        col, row = i % 2, i // 2
        cx = START_X + col * (CW + GAP_X)
        cy = START_Y + row * (CH + GAP_Y)

        pill(d, cx, cy, CW, CH, PANEL, r=12)
        d.rounded_rectangle([cx, cy, cx + CW, cy + 5], radius=3, fill=color)
        d.text((cx + 20, cy + 16), title, font=font(20, bold=True), fill=WHITE)
        d.rectangle([(cx + 20, cy + 50), (cx + CW - 20, cy + 52)], fill=BORDER)
        for j, line in enumerate(lines):
            d.text((cx + 20, cy + 62 + j * 30), line, font=font(17), fill=GREY_LT)

    img.save(os.path.join(OUT_DIR, "slide-01-what-is-terraform.png"))
    print("  slide-01-what-is-terraform.png")


# ══════════════════════════════════════════════════════════════════════════════
# SLIDE 2 — The Terraform Workflow
# 5 boxes.  div_y=118 → boxes start at y=130, height=480 → bottom 610
# ══════════════════════════════════════════════════════════════════════════════
def slide2():
    img, d = new_slide()
    teal_bar(d)
    badge(d)
    slide_num(d, 2)
    header_no_subtitle(d, "The Terraform Workflow")

    steps = [
        (
            "Write",
            GREY_MD,
            [
                "Define resources",
                "in .tf config files.",
                "HCL is readable by",
                "humans & machines.",
            ],
            "main.tf\nvariables.tf\noutputs.tf",
        ),
        (
            "init",
            TEAL,
            [
                "Download provider",
                "plugins.",
                "Run once per project",
                "or new provider.",
            ],
            "$ terraform init",
        ),
        (
            "plan",
            TEAL,
            [
                "Preview every change",
                "before it happens.",
                "Shows +add /~change",
                "/−destroy counts.",
            ],
            "$ terraform plan",
        ),
        (
            "apply",
            GREEN,
            [
                "Create or update",
                "real infrastructure.",
                "Confirm with 'yes'",
                "after reviewing plan.",
            ],
            "$ terraform apply",
        ),
        (
            "destroy",
            ORANGE,
            [
                "Remove everything",
                "Terraform created.",
                "Correct order,",
                "nothing left behind.",
            ],
            "$ terraform destroy",
        ),
    ]

    N = len(steps)
    BW = 196
    GAP = 14
    sy = 130
    BH = (H - 50) - sy  # 495px — fills slide to footer
    total_w = N * BW + (N - 1) * GAP
    sx = (W - total_w) // 2

    for i, (cmd, color, lines, example) in enumerate(steps):
        bx = sx + i * (BW + GAP)

        pill(d, bx, sy, BW, BH, PANEL, r=12)
        d.rounded_rectangle([bx, sy, bx + BW, sy + 5], radius=3, fill=color)

        # Step label pill near top
        lbl = f"terraform {cmd}" if cmd != "Write" else "Write"
        pill(d, bx + 14, sy + 14, BW - 28, 40, BG, r=6)
        cx_text(d, bx + BW // 2, sy + 22, lbl, font(15, bold=True), color)

        d.rectangle([(bx + 14, sy + 62), (bx + BW - 14, sy + 64)], fill=BORDER)

        # Description lines
        for j, line in enumerate(lines):
            cx_text(d, bx + BW // 2, sy + 76 + j * 30, line, font(15), GREY_LT)

        # Step number as large faint background accent in middle
        num_str = str(i + 1)
        num_fnt = font(96, bold=True)
        bb = d.textbbox((0, 0), num_str, font=num_fnt)
        nw = bb[2] - bb[0]
        mid_y = sy + 200
        # Blend color toward panel bg for a subtle watermark effect (15% color, 85% panel)
        r0, g0, b0 = tuple(int(color.lstrip("#")[k : k + 2], 16) for k in (0, 2, 4))
        pr, pg, pb = tuple(int(PANEL.lstrip("#")[k : k + 2], 16) for k in (0, 2, 4))
        faint = "#{:02x}{:02x}{:02x}".format(
            (r0 * 15 + pr * 85) // 100,
            (g0 * 15 + pg * 85) // 100,
            (b0 * 15 + pb * 85) // 100,
        )
        d.text((bx + (BW - nw) // 2, mid_y), num_str, font=num_fnt, fill=faint)

        # Example code pill pinned to bottom
        ex_lines = example.split("\n")
        ex_h = len(ex_lines) * 26 + 20
        ex_y = sy + BH - ex_h - 16
        pill(d, bx + 10, ex_y, BW - 20, ex_h, BG, r=8)
        for j, eline in enumerate(ex_lines):
            cx_text(
                d, bx + BW // 2, ex_y + 10 + j * 26, eline, font(14, bold=True), color
            )

        if i < N - 1:
            ax = bx + BW + 2
            ay = sy + BH // 2
            d.polygon([(ax, ay - 7), (ax + GAP, ay), (ax, ay + 7)], fill=GREY_MD)

    d.text(
        (60, H - 52),
        "The write \u2192 plan \u2192 apply cycle repeats with every change.",
        font=font(16),
        fill=GREY_MD,
    )
    d.text(
        (60, H - 30),
        "terraform destroy is a separate teardown operation, not a routine next step.",
        font=font(16),
        fill=GREY_MD,
    )

    img.save(os.path.join(OUT_DIR, "slide-02-workflow.png"))
    print("  slide-02-workflow.png")


# ══════════════════════════════════════════════════════════════════════════════
# SLIDE 3 — Key Concepts
# 4 cards.  div_y=118 → cards start at y=130, height=500 → bottom 630
# ══════════════════════════════════════════════════════════════════════════════
def slide3():
    img, d = new_slide()
    teal_bar(d)
    badge(d)
    slide_num(d, 3)
    header_no_subtitle(d, "Key Concepts")

    concepts = [
        (
            TEAL,
            "Provider",
            ["A plugin that knows how to", "talk to a specific platform."],
            ["This lab uses:", "  kreuzwerker/docker", "  CiscoDevNet/iosxe"],
            "terraform {",
            "  required_providers {",
            "    iosxe = {",
            '      source = "CiscoDevNet/iosxe"',
            "    }",
            "  }",
            "}",
        ),
        (
            GREEN,
            "Resource",
            ["A single piece of infra", "managed by Terraform."],
            ["Examples:", "  docker_container", "  iosxe_interface_loopback"],
            'resource "iosxe_interface_loopback"',
            '         "lo0" {',
            "  name        = 0",
            '  description = "Managed by TF"',
            "}",
        ),
        (
            ORANGE,
            "State File",
            ["Terraform's memory —", "records what it deployed."],
            ["Stored in:", "  terraform.tfstate", "  Never edit by hand"],
            "# After apply:",
            "$ cat terraform.tfstate",
            '  "hostname": "csr-terraform"',
            '  "address":  "10.99.99.1"',
        ),
        (
            TEAL,
            "Module",
            ["A reusable group of", "resources packaged together."],
            ["This lab uses:", "  docker-infra", "  iosxe-config"],
            'module "iosxe_config" {',
            '  source   = "./modules/iosxe-config"',
            "  hostname = var.hostname",
            "}",
        ),
    ]

    CW, CH = 248, 495
    GAP = 26
    total_w = 4 * CW + 3 * GAP
    sx = (W - total_w) // 2
    sy = 130

    for i, (color, title, body, detail, *code_lines) in enumerate(concepts):
        cx = sx + i * (CW + GAP)

        pill(d, cx, sy, CW, CH, PANEL, r=12)
        d.rounded_rectangle([cx, sy, cx + CW, sy + 5], radius=3, fill=color)

        cx_text(d, cx + CW // 2, sy + 16, title, font(22, bold=True), color)
        d.rectangle([(cx + 16, sy + 52), (cx + CW - 16, sy + 54)], fill=BORDER)

        for j, line in enumerate(body):
            cx_text(d, cx + CW // 2, sy + 64 + j * 30, line, font(17), GREY_LT)

        # Detail pill (label + examples)
        detail_y = sy + 148
        detail_h = 120
        pill(d, cx + 12, detail_y, CW - 24, detail_h, BG, r=8)
        for j, line in enumerate(detail):
            d.text((cx + 24, detail_y + 10 + j * 26), line, font=font(15), fill=GREY_MD)

        # Code example pill pinned to bottom
        ex_h = len(code_lines) * 20 + 20
        ex_y = sy + CH - ex_h - 14
        pill(d, cx + 12, ex_y, CW - 24, ex_h, BG, r=8)
        for j, line in enumerate(code_lines):
            d.text(
                (cx + 20, ex_y + 10 + j * 20),
                line,
                font=font(11, bold=True),
                fill=color,
            )

    img.save(os.path.join(OUT_DIR, "slide-03-key-concepts.png"))
    print("  slide-03-key-concepts.png")


# ══════════════════════════════════════════════════════════════════════════════
# SLIDE 4 — What This Lab Builds
# ══════════════════════════════════════════════════════════════════════════════
def slide4():
    img, d = new_slide()
    teal_bar(d)
    badge(d)
    slide_num(d, 4)
    header_no_subtitle(d, "What This Lab Builds")

    # ── Left: file list ────────────────────────────────────────────────────
    lx, ly = 52, 132
    d.text((lx, ly), "Terraform Config", font=font(20, bold=True), fill=TEAL)

    tf_files = [
        ("main.tf", "Root — wires modules together"),
        ("variables.tf", "Input values with defaults"),
        ("outputs.tf", "Printed after apply"),
        ("modules/", "docker-infra  +  iosxe-config"),
    ]
    ROW_H = 68
    for i, (fname, desc) in enumerate(tf_files):
        fy = ly + 42 + i * ROW_H
        pill(d, lx, fy, 350, 58, PANEL, r=8)
        d.text((lx + 14, fy + 10), fname, font=font(17, bold=True), fill=WHITE)
        d.text((lx + 14, fy + 32), desc, font=font(14), fill=GREY_MD)

    # ── Arrow ──────────────────────────────────────────────────────────────
    ftop = ly + 42
    fbot = ly + 42 + 4 * ROW_H
    ay = (ftop + fbot) // 2
    ax1, ax2 = 418, 570
    d.rectangle([(ax1, ay - 3), (ax2 - 14, ay + 3)], fill=TEAL)
    d.polygon([(ax2 - 16, ay - 12), (ax2, ay), (ax2 - 16, ay + 12)], fill=TEAL)
    cx_text(d, (ax1 + ax2) // 2, ay - 36, "terraform apply", font(16, bold=True), TEAL)
    cx_text(d, (ax1 + ax2) // 2, ay + 12, "RESTCONF", font(14), GREY_MD)

    # ── Right: Docker topology ─────────────────────────────────────────────
    rx, ry = 585, 120
    NW, NH = W - rx - 20, H - ry - 18
    pill(d, rx, ry, NW, NH, PANEL, r=14)
    d.rounded_rectangle([rx, ry, rx + NW, ry + 5], radius=3, fill=TEAL_DK)
    d.text(
        (rx + 18, ry + 16),
        "Docker bridge: terraform-net  (172.20.21.0/24)",
        font=font(16, bold=True),
        fill=TEAL,
    )

    containers = [
        (TEAL, "csr-terraform", "IOS XE 16.12", "172.20.21.10", "Terraform\ntarget"),
        (
            GREEN,
            "linux-terraform1",
            "network-multitool",
            "172.20.21.20",
            "Linux\nclient",
        ),
        (
            GREEN,
            "linux-terraform2",
            "network-multitool",
            "172.20.21.21",
            "Linux\nclient",
        ),
    ]
    CW, CH, CGAP = 166, 170, 16
    ctx = rx + (NW - (3 * CW + 2 * CGAP)) // 2
    cty = ry + 52

    bus_y = cty + CH + 20
    bus_x1 = ctx + CW // 2
    bus_x2 = ctx + 2 * (CW + CGAP) + CW // 2
    d.rectangle([(bus_x1, bus_y - 2), (bus_x2, bus_y + 2)], fill=BORDER)

    for i, (color, name, image, ip, role) in enumerate(containers):
        bx = ctx + i * (CW + CGAP)
        mid = bx + CW // 2
        pill(d, bx, cty, CW, CH, BG, r=10)
        d.rounded_rectangle([bx, cty, bx + CW, cty + 5], radius=3, fill=color)
        d.rectangle([(mid - 1, cty + CH), (mid + 1, bus_y)], fill=BORDER)
        cx_text(d, mid, cty + 14, name, font(13, bold=True), WHITE)
        cx_text(d, mid, cty + 36, image, font(12), GREY_MD)
        cx_text(d, mid, cty + 62, ip, font(13, bold=True), color)
        for j, rl in enumerate(role.split("\n")):
            cx_text(d, mid, cty + 96 + j * 22, rl, font(12), GREY_MD)

    for j, item in enumerate(["hostname → csr-terraform", "Loopback0 → 10.99.99.1/32"]):
        cx_text(d, ctx + CW // 2, bus_y + 16 + j * 26, item, font(14), TEAL)

    img.save(os.path.join(OUT_DIR, "slide-04-what-we-build.png"))
    print("  slide-04-what-we-build.png")


# ══════════════════════════════════════════════════════════════════════════════
# Icon helpers  — classic Cisco network diagram style
# ══════════════════════════════════════════════════════════════════════════════
def draw_router_icon(d, cx, cy, size, color):
    """Classic Cisco router: filled cylinder (ellipse cap + body + base ellipse)
    with 4 white directional arrows on the top face."""
    rw = size  # half-width of ellipse
    rh = size // 4  # half-height of ellipse (flat disc)
    body_h = size // 2  # height of the cylindrical body

    top_y = cy - body_h // 2  # vertical centre of top ellipse
    bot_y = cy + body_h // 2  # vertical centre of bottom ellipse

    # ── cylinder body (left/right sides + fill) ──────────────────────────────
    # filled rectangle for the body sides
    d.rectangle([(cx - rw, top_y), (cx + rw, bot_y)], fill=color)

    # bottom ellipse (drawn first so top overlaps it)
    d.ellipse([(cx - rw, bot_y - rh), (cx + rw, bot_y + rh)], fill=color)
    # slight darker rim on bottom edge for depth
    d.arc([(cx - rw, bot_y - rh), (cx + rw, bot_y + rh)], 0, 180, fill=PANEL, width=2)

    # top ellipse — slightly lighter tint blended toward white for 3-D look
    # blend color 70 % + white 30 %
    r0, g0, b0 = tuple(int(color.lstrip("#")[k : k + 2], 16) for k in (0, 2, 4))
    lighter = "#{:02x}{:02x}{:02x}".format(
        min(255, (r0 * 70 + 255 * 30) // 100),
        min(255, (g0 * 70 + 255 * 30) // 100),
        min(255, (b0 * 70 + 255 * 30) // 100),
    )
    d.ellipse([(cx - rw, top_y - rh), (cx + rw, top_y + rh)], fill=lighter)
    # rim outline on top face
    d.ellipse([(cx - rw, top_y - rh), (cx + rw, top_y + rh)], outline=color, width=2)

    # ── 4 directional arrows on top face (N/S/E/W) ───────────────────────────
    al = size // 5  # arrow arm length
    aw = max(2, size // 14)  # arm width
    tip = size // 8  # arrowhead size

    def arrow(dx, dy):
        """Draw one arrow from centre outward in direction (dx,dy)."""
        ax1, ay1 = cx, top_y
        ax2 = cx + dx * al
        ay2 = top_y + dy * (rh * al // (rw if dx == 0 else al))  # project onto ellipse
        # use flat coords on the ellipse face
        ax2 = cx + dx * (al - tip)
        ay2 = top_y + dy * int((rh / rw) * (al - tip))
        # shaft
        d.line([(ax1, ay1), (ax2, ay2)], fill=PANEL, width=aw)
        # arrowhead triangle
        # perpendicular offset for triangle base
        px = int(dy * tip * 0.6)
        py = int(-dx * tip * 0.6 * (rh / rw))
        tip_x = cx + dx * al
        tip_y = top_y + dy * int((rh / rw) * al)
        d.polygon(
            [
                (tip_x, tip_y),
                (ax2 + px, ay2 + py),
                (ax2 - px, ay2 - py),
            ],
            fill=PANEL,
        )

    arrow(1, 0)  # E
    arrow(-1, 0)  # W
    arrow(0, 1)  # S (down on ellipse face)
    arrow(0, -1)  # N (up on ellipse face)


def draw_server_icon(d, cx, cy, w, h, color):
    """Classic Cisco workstation / server icon:
    monitor (rounded rect with screen bezel) + base + keyboard tray."""
    # ── monitor body ──────────────────────────────────────────────────────────
    mon_w = w
    mon_h = int(h * 0.58)
    mx, my = cx - mon_w // 2, cy - h // 2

    # outer bezel
    d.rounded_rectangle([mx, my, mx + mon_w, my + mon_h], radius=5, fill=color)
    # screen inset
    pad = max(4, mon_w // 10)
    d.rounded_rectangle(
        [mx + pad, my + pad, mx + mon_w - pad, my + mon_h - pad], radius=3, fill=PANEL
    )

    # ── neck / stand ─────────────────────────────────────────────────────────
    neck_w = max(6, mon_w // 6)
    neck_h = int(h * 0.12)
    neck_x = cx - neck_w // 2
    neck_y = my + mon_h
    d.rectangle([(neck_x, neck_y), (neck_x + neck_w, neck_y + neck_h)], fill=color)

    # ── base platform ─────────────────────────────────────────────────────────
    base_w = int(mon_w * 0.75)
    base_h = int(h * 0.10)
    base_x = cx - base_w // 2
    base_y = neck_y + neck_h
    d.rounded_rectangle(
        [base_x, base_y, base_x + base_w, base_y + base_h], radius=3, fill=color
    )

    # ── keyboard tray ─────────────────────────────────────────────────────────
    kb_w = int(mon_w * 0.85)
    kb_h = int(h * 0.10)
    kb_x = cx - kb_w // 2
    kb_y = base_y + base_h + 2
    d.rounded_rectangle([kb_x, kb_y, kb_x + kb_w, kb_y + kb_h], radius=2, fill=color)
    # key row lines
    for col in range(1, 5):
        lx = kb_x + col * kb_w // 5
        d.rectangle([(lx, kb_y + 2), (lx + 1, kb_y + kb_h - 2)], fill=PANEL)


# ══════════════════════════════════════════════════════════════════════════════
# SLIDE 5 — Lab Topology
# Full-slide network diagram: Docker bridge + 3 containers + RESTCONF callout
# Icons: router (CSR) and server (Linux containers) drawn above each box
# ══════════════════════════════════════════════════════════════════════════════
def slide5():
    img, d = new_slide()
    teal_bar(d)
    badge(d)
    slide_num(d, 5)
    header_no_subtitle(d, "Lab Topology")

    # ── Outer border panel ───────────────────────────────────────────────────
    PX, PY = 40, 128
    PW, PH = W - 80, H - 160
    d.rounded_rectangle([PX, PY, PX + PW, PY + PH], radius=14, outline=BORDER, width=2)

    # ── Docker bridge label bar at top of panel ──────────────────────────────
    BRX, BRY = PX + 16, PY + 14
    BRW, BRH = PW - 32, 44
    pill(d, BRX, BRY, BRW, BRH, TEAL_DK, r=8)
    cx_text(
        d,
        W // 2,
        BRY + 10,
        "Docker bridge network:  terraform-net  (172.20.21.0/24)",
        font(17, bold=True),
        WHITE,
    )

    # ── Horizontal bus line ───────────────────────────────────────────────────
    bus_y = BRY + BRH + 30
    bus_x1 = PX + 80
    bus_x2 = PX + PW - 80
    d.rectangle([(bus_x1, bus_y - 3), (bus_x2, bus_y + 3)], fill=TEAL_DK)
    # gateway dot on bus
    gw_x = W // 2
    d.ellipse([(gw_x - 7, bus_y - 7), (gw_x + 7, bus_y + 7)], fill=TEAL)
    cx_text(d, gw_x, bus_y - 22, "gateway  172.20.21.1", font(12), GREY_MD)

    # ── Layout constants ──────────────────────────────────────────────────────
    ICON_H = 72  # vertical space reserved for icon above each box
    ICON_GAP = 8  # gap between bottom of icon and top of box
    CW, CH = 230, 148
    CGAP = 40
    total_cw = 3 * CW + 2 * CGAP
    ctx = (W - total_cw) // 2
    icon_top = bus_y + 14  # icons start here
    cty = icon_top + ICON_H + ICON_GAP  # boxes start here

    containers = [
        (
            TEAL,
            "router",
            "csr-terraform",
            "vrnetlab/vr-csr:16.12.05",
            "172.20.21.10",
            "Cisco IOS XE 16.12",
        ),
        (
            GREEN,
            "server",
            "linux-terraform1",
            "hellt/network-multitool",
            "172.20.21.20",
            "Linux client 1",
        ),
        (
            GREEN,
            "server",
            "linux-terraform2",
            "hellt/network-multitool",
            "172.20.21.21",
            "Linux client 2",
        ),
    ]

    for i, (color, icon_type, name, image, ip, role) in enumerate(containers):
        bx = ctx + i * (CW + CGAP)
        mid = bx + CW // 2

        # vertical drop-line: bus → icon area → box
        d.rectangle([(mid - 2, bus_y + 3), (mid + 2, cty)], fill=TEAL_DK)

        # ── Icon ──────────────────────────────────────────────────────────────
        icon_cy = icon_top + ICON_H // 2
        if icon_type == "router":
            draw_router_icon(d, mid, icon_cy, 58, color)
        else:
            draw_server_icon(d, mid, icon_cy, 58, 64, color)

        # ── Container info box ────────────────────────────────────────────────
        pill(d, bx, cty, CW, CH, PANEL, r=10)
        d.rounded_rectangle([bx, cty, bx + CW, cty + 5], radius=4, fill=color)

        cx_text(d, mid, cty + 12, name, font(14, bold=True), WHITE)
        d.rectangle([(bx + 16, cty + 36), (bx + CW - 16, cty + 38)], fill=BORDER)
        cx_text(d, mid, cty + 46, ip, font(17, bold=True), color)
        cx_text(d, mid, cty + 76, role, font(13), GREY_LT)

        # image pill at bottom
        img_pill_y = cty + CH - 30
        pill(d, bx + 14, img_pill_y, CW - 28, 22, BG, r=5)
        cx_text(d, mid, img_pill_y + 4, image, font(11), GREY_MD)

    # ── "managed by Terraform" badge on CSR box ───────────────────────────────
    csr_mid = ctx + CW // 2
    pill(d, ctx + 10, cty + CH - 58, CW - 20, 22, TEAL_DK, r=5)
    cx_text(
        d, csr_mid, cty + CH - 53, "managed by Terraform", font(11, bold=True), WHITE
    )

    # ── RESTCONF callout ──────────────────────────────────────────────────────
    csr_bot = cty + CH
    cx_b, cy_b = PX + 24, PY + PH - 68
    cw_b, ch_b = 340, 56
    pill(d, cx_b, cy_b, cw_b, ch_b, BG, r=8)
    d.rounded_rectangle([cx_b, cy_b, cx_b + cw_b, cy_b + 4], radius=3, fill=TEAL)
    d.text(
        (cx_b + 14, cy_b + 10),
        "Terraform configures via RESTCONF:",
        font=font(13, bold=True),
        fill=TEAL,
    )
    d.text(
        (cx_b + 14, cy_b + 32),
        "hostname → csr-terraform  |  Loopback0 → 10.99.99.1/32",
        font=font(12),
        fill=GREY_LT,
    )

    # dashed arrow from CSR box bottom → callout
    ax, ay1, ay2 = csr_mid, csr_bot + 4, cy_b
    for seg_y in range(ay1, ay2, 10):
        d.rectangle([(ax - 1, seg_y), (ax + 1, min(seg_y + 6, ay2))], fill=TEAL)
    d.polygon([(ax - 8, ay2 + 2), (ax + 8, ay2 + 2), (ax, ay2 - 10)], fill=TEAL)

    img.save(os.path.join(OUT_DIR, "slide-05-topology.png"))
    print("  slide-05-topology.png")


# ══════════════════════════════════════════════════════════════════════════════
# SLIDE 6 — Infrastructure Drift
# Same topology layout as slide 5, but linux-terraform2 box has a red X drawn
# over it to show it was manually deleted — illustrating configuration drift.
# ══════════════════════════════════════════════════════════════════════════════
def slide6():
    img, d = new_slide()
    teal_bar(d)
    badge(d)
    slide_num(d, 6)
    header_no_subtitle(d, "Infrastructure Drift")

    # ── Outer border panel ───────────────────────────────────────────────────
    PX, PY = 40, 128
    PW, PH = W - 80, H - 160
    d.rounded_rectangle([PX, PY, PX + PW, PY + PH], radius=14, outline=BORDER, width=2)

    # ── Docker bridge label bar at top of panel ──────────────────────────────
    BRX, BRY = PX + 16, PY + 14
    BRW, BRH = PW - 32, 44
    pill(d, BRX, BRY, BRW, BRH, TEAL_DK, r=8)
    cx_text(
        d,
        W // 2,
        BRY + 10,
        "Docker bridge network:  terraform-net  (172.20.21.0/24)",
        font(17, bold=True),
        WHITE,
    )

    # ── Horizontal bus line ───────────────────────────────────────────────────
    bus_y = BRY + BRH + 30
    bus_x1 = PX + 80
    bus_x2 = PX + PW - 80
    d.rectangle([(bus_x1, bus_y - 3), (bus_x2, bus_y + 3)], fill=TEAL_DK)
    # gateway dot on bus
    gw_x = W // 2
    d.ellipse([(gw_x - 7, bus_y - 7), (gw_x + 7, bus_y + 7)], fill=TEAL)
    cx_text(d, gw_x, bus_y - 22, "gateway  172.20.21.1", font(12), GREY_MD)

    # ── Layout constants ──────────────────────────────────────────────────────
    ICON_H = 72
    ICON_GAP = 8
    CW, CH = 230, 148
    CGAP = 40
    total_cw = 3 * CW + 2 * CGAP
    ctx = (W - total_cw) // 2
    icon_top = bus_y + 14
    cty = icon_top + ICON_H + ICON_GAP

    containers = [
        (
            TEAL,
            "router",
            "csr-terraform",
            "vrnetlab/vr-csr:16.12.05",
            "172.20.21.10",
            "Cisco IOS XE 16.12",
            False,
        ),
        (
            GREEN,
            "server",
            "linux-terraform1",
            "hellt/network-multitool",
            "172.20.21.20",
            "Linux client 1",
            False,
        ),
        (
            GREEN,
            "server",
            "linux-terraform2",
            "hellt/network-multitool",
            "172.20.21.21",
            "Linux client 2",
            True,  # <-- manually deleted → draw red X
        ),
    ]

    RED = "#e85151"

    for i, (color, icon_type, name, image, ip, role, deleted) in enumerate(containers):
        bx = ctx + i * (CW + CGAP)
        mid = bx + CW // 2

        # vertical drop-line: bus → icon area → box
        drop_color = RED if deleted else TEAL_DK
        d.rectangle([(mid - 2, bus_y + 3), (mid + 2, cty)], fill=drop_color)

        # ── Icon ──────────────────────────────────────────────────────────────
        icon_cy = icon_top + ICON_H // 2
        icon_color = RED if deleted else color
        if icon_type == "router":
            draw_router_icon(d, mid, icon_cy, 58, icon_color)
        else:
            draw_server_icon(d, mid, icon_cy, 58, 64, icon_color)

        # ── Container info box ────────────────────────────────────────────────
        box_fill = "#1a0505" if deleted else PANEL
        box_accent = RED if deleted else color
        pill(d, bx, cty, CW, CH, box_fill, r=10)
        d.rounded_rectangle([bx, cty, bx + CW, cty + 5], radius=4, fill=box_accent)

        cx_text(d, mid, cty + 12, name, font(14, bold=True), WHITE)
        d.rectangle([(bx + 16, cty + 36), (bx + CW - 16, cty + 38)], fill=BORDER)
        cx_text(d, mid, cty + 46, ip, font(17, bold=True), box_accent)
        cx_text(d, mid, cty + 76, role, font(13), GREY_LT)

        # image pill at bottom
        img_pill_y = cty + CH - 30
        pill(d, bx + 14, img_pill_y, CW - 28, 22, BG, r=5)
        cx_text(d, mid, img_pill_y + 4, image, font(11), GREY_MD)

        # ── Big red X over deleted container ─────────────────────────────────
        if deleted:
            # Extend X slightly above box to include icon area
            x0 = bx + 10
            y0 = icon_top + 4
            x1 = bx + CW - 10
            y1 = cty + CH - 4
            lw = 9  # line width (simulate with thick rects via polygon)
            # Draw two diagonal lines using thick lines (series of filled rects)
            import math

            def thick_line(d, ax, ay, bx2, by2, width, fill):
                dx, dy = bx2 - ax, by2 - ay
                length = math.hypot(dx, dy)
                if length == 0:
                    return
                ux, uy = dy / length, -dx / length  # perpendicular unit vector
                hw = width / 2
                pts = [
                    (ax + ux * hw, ay + uy * hw),
                    (ax - ux * hw, ay - uy * hw),
                    (bx2 - ux * hw, by2 - uy * hw),
                    (bx2 + ux * hw, by2 + uy * hw),
                ]
                d.polygon(pts, fill=fill)

            thick_line(d, x0, y0, x1, y1, lw, RED)
            thick_line(d, x1, y0, x0, y1, lw, RED)

            # "DELETED" label below the X lines, inside the box
            cx_text(d, mid, cty + CH - 50, "DELETED", font(14, bold=True), RED)

    # ── Drift explanation callout ──────────────────────────────────────────────
    cx_b, cy_b = PX + 24, PY + PH - 68
    cw_b, ch_b = 460, 56
    pill(d, cx_b, cy_b, cw_b, ch_b, BG, r=8)
    d.rounded_rectangle([cx_b, cy_b, cx_b + cw_b, cy_b + 4], radius=3, fill=RED)
    d.text(
        (cx_b + 14, cy_b + 10),
        "Drift detected:",
        font=font(13, bold=True),
        fill=RED,
    )
    d.text(
        (cx_b + 14, cy_b + 32),
        "linux-terraform2 was manually removed outside Terraform",
        font=font(12),
        fill=GREY_LT,
    )

    img.save(os.path.join(OUT_DIR, "slide-06-drift.png"))
    print("  slide-06-drift.png")


if __name__ == "__main__":
    print("Generating slides...")
    slide1()
    slide2()
    slide3()
    slide4()
    slide5()
    slide6()
    print("Done.")
