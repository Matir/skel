#!/usr/bin/env python3

import argparse
import plistlib
import shutil
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageEnhance


DEFAULT_CHROME_APP = Path("/Applications/Google Chrome.app")
DEFAULT_APPS_DIR = Path.home() / "Applications" / "Chrome Containers"

# Edit this list for your containers.
CONTAINERS = [
#    {
#        "name": "Chrome Work",
#        "bundle_id": "com.example.chrome.work",
#        "mode": "persistent",
#        "profile_dir": str(Path.home() / ".chrome-work"),
#        "badge_path": str(Path.home() / ".chrome-container-badges" / "briefcase.svg"),
#    },
    {
        "name": "Chrome Family",
        "bundle_id": "com.example.chrome.family",
        "mode": "persistent",
        "profile_dir": str(Path.home() / ".chrome-family"),
        "badge_path": str(Path.home() / ".chrome-container-badges" / "family.svg"),
    },
    {
        "name": "Chrome Research",
        "bundle_id": "com.example.chrome.research",
        "mode": "persistent",
        "profile_dir": str(Path.home() / ".chrome-research"),
        "badge_path": str(Path.home() / ".chrome-container-badges" / "research.svg"),
    },
    {
        "name": "Chrome Ephemeral",
        "bundle_id": "com.example.chrome.ephemeral",
        "mode": "ephemeral",
        "profile_dir": None,
        "badge_path": str(Path.home() / ".chrome-container-badges" / "fire.svg"),
    },
]

DEFAULT_COLOR_FACTOR = 0.55
DEFAULT_BRIGHTNESS_FACTOR = 0.94
DEFAULT_CONTRAST_FACTOR = 0.97
DEFAULT_BADGE_FRACTION = 0.50
DEFAULT_PADDING_FRACTION = 0.03
DEFAULT_BADGE_OPACITY = 0.96


def run(cmd, check=True, capture_output=False, text=True):
    return subprocess.run(cmd, check=check, capture_output=capture_output, text=text)


def require_tool(name: str):
    if shutil.which(name) is None:
        print(f"Missing required tool: {name}", file=sys.stderr)
        sys.exit(1)


def parse_icon_size(path: Path):
    name = path.name
    if not name.endswith(".png") or not name.startswith("icon_"):
        return (0, 0)

    stem = name[:-4]
    rest = stem[len("icon_"):]
    scale = 1
    if rest.endswith("@2x"):
        rest = rest[:-3]
        scale = 2

    try:
        left, right = rest.split("x", 1)
        return (int(left) * scale, int(right) * scale)
    except Exception:
        return (0, 0)


def find_source_icns(app_path: Path) -> Path:
    info_plist = app_path / "Contents" / "Info.plist"
    resources_dir = app_path / "Contents" / "Resources"

    if not info_plist.exists():
        raise FileNotFoundError(f"Missing Info.plist: {info_plist}")
    if not resources_dir.exists():
        raise FileNotFoundError(f"Missing Resources directory: {resources_dir}")

    with info_plist.open("rb") as f:
        plist = plistlib.load(f)

    icon_name = plist.get("CFBundleIconFile")
    if icon_name:
        if not icon_name.endswith(".icns"):
            icon_name += ".icns"
        candidate = resources_dir / icon_name
        if candidate.exists():
            return candidate

    chrome_named = sorted(resources_dir.glob("*[Cc]hrome*.icns"))
    if chrome_named:
        return chrome_named[0]

    any_icns = sorted(resources_dir.glob("*.icns"))
    if any_icns:
        return any_icns[0]

    raise FileNotFoundError(f"No .icns file found in {resources_dir}")


def extract_iconset(icns_path: Path, out_iconset: Path):
    run(["iconutil", "-c", "iconset", str(icns_path), "-o", str(out_iconset)])


def largest_png(iconset_dir: Path) -> Path:
    pngs = list(iconset_dir.glob("*.png"))
    if not pngs:
        raise FileNotFoundError(f"No PNGs found in {iconset_dir}")
    pngs.sort(key=lambda p: parse_icon_size(p)[0] * parse_icon_size(p)[1], reverse=True)
    return pngs[0]


def rasterize_svg(svg_path: Path, out_png: Path, size: int = 1024):
    # Prefer librsvg if installed.
    if shutil.which("rsvg-convert"):
        run([
            "rsvg-convert",
            "-w", str(size),
            "-h", str(size),
            "-o", str(out_png),
            str(svg_path),
        ])
        return

    # Fallback to Inkscape CLI if available.
    if shutil.which("inkscape"):
        run([
            "inkscape",
            str(svg_path),
            "--export-type=png",
            f"--export-filename={out_png}",
            "-w", str(size),
            "-h", str(size),
        ])
        return

    raise RuntimeError(
        f"SVG badge provided but no SVG rasterizer found for {svg_path}. "
        "Install librsvg (rsvg-convert) or Inkscape."
    )


def load_badge_image(badge_path: Path, temp_dir: Path) -> Image.Image | None:
    if not badge_path.exists():
        print(f"Warning: badge file not found, skipping overlay: {badge_path}")
        return None

    suffix = badge_path.suffix.lower()

    if suffix == ".png":
        return Image.open(badge_path).convert("RGBA")

    if suffix == ".svg":
        rasterized = temp_dir / f"{badge_path.stem}.png"
        rasterize_svg(badge_path, rasterized, size=1024)
        return Image.open(rasterized).convert("RGBA")

    raise RuntimeError(
        f"Unsupported badge format for {badge_path}. "
        "Supported formats: .png, .svg"
    )


def compose_icon(
    base_png: Path,
    badge_path: str | None,
    out_master: Path,
    color_factor: float,
    brightness_factor: float,
    contrast_factor: float,
    badge_fraction: float,
    padding_fraction: float,
    badge_opacity: float,
    temp_dir: Path,
):
    base = Image.open(base_png).convert("RGBA")

    muted = ImageEnhance.Color(base).enhance(color_factor)
    muted = ImageEnhance.Brightness(muted).enhance(brightness_factor)
    muted = ImageEnhance.Contrast(muted).enhance(contrast_factor)

    result = muted.copy()

    if badge_path:
        badge = load_badge_image(Path(badge_path).expanduser(), temp_dir)
        if badge is not None:
            w, h = result.size

            max_badge_w = int(w * badge_fraction)
            max_badge_h = int(h * badge_fraction)
            pad = max(4, int(w * padding_fraction))

            bw, bh = badge.size
            scale = min(max_badge_w / bw, max_badge_h / bh)
            new_size = (max(1, int(bw * scale)), max(1, int(bh * scale)))
            badge = badge.resize(new_size, Image.LANCZOS)

            if badge_opacity < 1.0:
                alpha = badge.getchannel("A")
                alpha = ImageEnhance.Brightness(alpha).enhance(badge_opacity)
                badge.putalpha(alpha)

            x = w - badge.width - pad
            y = h - badge.height - pad
            result.alpha_composite(badge, (x, y))

    result.save(out_master)


def build_iconset_from_master(master_png: Path, out_iconset: Path):
    out_iconset.mkdir(parents=True, exist_ok=True)
    img = Image.open(master_png).convert("RGBA")

    sizes = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]

    for filename, size in sizes:
        resized = img.resize((size, size), Image.LANCZOS)
        resized.save(out_iconset / filename)


def iconset_to_icns(iconset_dir: Path, out_icns: Path):
    run(["iconutil", "-c", "icns", str(iconset_dir), "-o", str(out_icns)])


def make_launch_script(chrome_bin: Path, mode: str, profile_dir: str | None) -> str:
    chrome_bin_escaped = str(chrome_bin).replace("\\", "\\\\").replace('"', '\\"')

    if mode == "persistent":
        if not profile_dir:
            raise ValueError("Persistent container requires profile_dir")
        profile_dir_escaped = profile_dir.replace("\\", "\\\\").replace('"', '\\"')
        return f"""#!/bin/bash
set -euo pipefail

CHROME_BIN="{chrome_bin_escaped}"
PROFILE_DIR="{profile_dir_escaped}"

mkdir -p "$PROFILE_DIR"

exec "$CHROME_BIN" \\
  --user-data-dir="$PROFILE_DIR" \\
  --no-first-run \\
  --no-default-browser-check \\
  --new-window
"""
    elif mode == "ephemeral":
        return f"""#!/bin/bash
set -euo pipefail

CHROME_BIN="{chrome_bin_escaped}"
PROFILE_DIR="$(mktemp -d /tmp/chrome-ephemeral-XXXXXX)"

cleanup() {{
  rm -rf "$PROFILE_DIR"
}}
trap cleanup EXIT INT TERM

exec "$CHROME_BIN" \\
  --user-data-dir="$PROFILE_DIR" \\
  --no-first-run \\
  --no-default-browser-check \\
  --new-window
"""
    else:
        raise ValueError(f"Unknown mode: {mode}")


def write_plist(app_name: str, bundle_id: str, plist_path: Path):
    plist = {
        "CFBundleDisplayName": app_name,
        "CFBundleExecutable": "launch",
        "CFBundleIdentifier": bundle_id,
        "CFBundleName": app_name,
        "CFBundlePackageType": "APPL",
        "CFBundleShortVersionString": "1.0",
        "CFBundleVersion": "1",
        "LSMinimumSystemVersion": "12.0",
        "NSHighResolutionCapable": True,
        "CFBundleIconFile": "applet",
    }
    with plist_path.open("wb") as f:
        plistlib.dump(plist, f)


def codesign_app(app_dir: Path):
    try:
        run(["/usr/bin/codesign", "--force", "--deep", "--sign", "-", str(app_dir)])
    except subprocess.CalledProcessError as e:
        print(f"Warning: codesign failed for {app_dir}: {e}")


def sanitize_container(container: dict) -> dict:
    required = ["name", "bundle_id", "mode"]
    for key in required:
        if key not in container or not container[key]:
            raise ValueError(f"Container missing required key: {key}")

    mode = container["mode"]
    if mode not in {"persistent", "ephemeral"}:
        raise ValueError(f"Invalid mode for {container['name']}: {mode}")

    if mode == "persistent" and not container.get("profile_dir"):
        raise ValueError(f"Persistent container missing profile_dir: {container['name']}")

    return container


def container_matches_filter(name: str, only_names: set[str]) -> bool:
    if not only_names:
        return True
    return name in only_names


def build_icon_for_app(
    source_icns: Path,
    badge_path: str | None,
    out_icns: Path,
    color_factor: float,
    brightness_factor: float,
    contrast_factor: float,
    badge_fraction: float,
    padding_fraction: float,
    badge_opacity: float,
):
    with tempfile.TemporaryDirectory() as tmp:
        tmpdir = Path(tmp)
        base_iconset = tmpdir / "base.iconset"
        new_iconset = tmpdir / "new.iconset"
        master_png = tmpdir / "master.png"

        extract_iconset(source_icns, base_iconset)
        base_png = largest_png(base_iconset)
        size = parse_icon_size(base_png)
        print(f"  Base icon source: {base_png.name} ({size[0]}x{size[1]})")

        compose_icon(
            base_png=base_png,
            badge_path=badge_path,
            out_master=master_png,
            color_factor=color_factor,
            brightness_factor=brightness_factor,
            contrast_factor=contrast_factor,
            badge_fraction=badge_fraction,
            padding_fraction=padding_fraction,
            badge_opacity=badge_opacity,
            temp_dir=tmpdir,
        )
        build_iconset_from_master(master_png, new_iconset)
        iconset_to_icns(new_iconset, out_icns)


def create_or_update_container(
    container: dict,
    apps_dir: Path,
    chrome_bin: Path,
    source_icns: Path,
    force: bool,
    update_icons_only: bool,
    codesign: bool,
    color_factor: float,
    brightness_factor: float,
    contrast_factor: float,
    badge_fraction: float,
    padding_fraction: float,
    badge_opacity: float,
):
    app_name = container["name"]
    bundle_id = container["bundle_id"]
    mode = container["mode"]
    profile_dir = container.get("profile_dir")
    badge_path = container.get("badge_path")

    app_dir = apps_dir / f"{app_name}.app"
    contents_dir = app_dir / "Contents"
    macos_dir = contents_dir / "MacOS"
    resources_dir = contents_dir / "Resources"
    out_icns = resources_dir / "applet.icns"

    exists = app_dir.exists()

    if update_icons_only:
        if not exists:
            print(f"Skipping missing app for icon update: {app_dir}")
            return
        print(f"Updating icon only for {app_name}...")
        resources_dir.mkdir(parents=True, exist_ok=True)
        build_icon_for_app(
            source_icns,
            badge_path,
            out_icns,
            color_factor,
            brightness_factor,
            contrast_factor,
            badge_fraction,
            padding_fraction,
            badge_opacity,
        )
        if codesign:
            codesign_app(app_dir)
        print(f"  Updated icon: {out_icns}")
        return

    if exists and not force:
        print(f"Skipping existing app: {app_dir}")
        return

    if exists and force:
        print(f"Recreating existing app: {app_dir}")
        shutil.rmtree(app_dir)
    else:
        print(f"Creating {app_name}...")

    macos_dir.mkdir(parents=True, exist_ok=True)
    resources_dir.mkdir(parents=True, exist_ok=True)

    write_plist(app_name, bundle_id, contents_dir / "Info.plist")

    launch_script = make_launch_script(chrome_bin, mode, profile_dir)
    launch_path = macos_dir / "launch"
    launch_path.write_text(launch_script, encoding="utf-8")
    launch_path.chmod(launch_path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    if mode == "persistent":
        Path(profile_dir).expanduser().mkdir(parents=True, exist_ok=True)

    build_icon_for_app(
        source_icns,
        badge_path,
        out_icns,
        color_factor,
        brightness_factor,
        contrast_factor,
        badge_fraction,
        padding_fraction,
        badge_opacity,
    )

    if codesign:
        codesign_app(app_dir)

    print(f"  Created: {app_dir}")


def main():
    parser = argparse.ArgumentParser(description="Create and manage Chrome container wrapper apps on macOS.")
    parser.add_argument("--chrome-app", default=str(DEFAULT_CHROME_APP), help="Path to Chrome app bundle")
    parser.add_argument("--apps-dir", default=str(DEFAULT_APPS_DIR), help="Directory for generated wrapper apps")
    parser.add_argument("--force", action="store_true", help="Recreate containers even if they already exist")
    parser.add_argument("--update-icons-only", action="store_true", help="Only rebuild icons for existing containers")
    parser.add_argument("--no-codesign", action="store_true", help="Skip ad-hoc codesigning")
    parser.add_argument(
        "--only",
        action="append",
        default=[],
        help="Limit to specific container name; can be passed multiple times",
    )
    parser.add_argument("--color-factor", type=float, default=DEFAULT_COLOR_FACTOR)
    parser.add_argument("--brightness-factor", type=float, default=DEFAULT_BRIGHTNESS_FACTOR)
    parser.add_argument("--contrast-factor", type=float, default=DEFAULT_CONTRAST_FACTOR)
    parser.add_argument("--badge-fraction", type=float, default=DEFAULT_BADGE_FRACTION)
    parser.add_argument("--padding-fraction", type=float, default=DEFAULT_PADDING_FRACTION)
    parser.add_argument("--badge-opacity", type=float, default=DEFAULT_BADGE_OPACITY)
    args = parser.parse_args()

    require_tool("iconutil")

    chrome_app = Path(args.chrome_app).expanduser().resolve()
    apps_dir = Path(args.apps_dir).expanduser().resolve()
    chrome_bin = chrome_app / "Contents" / "MacOS" / "Google Chrome"

    if not chrome_bin.exists():
        print(f"Chrome binary not found: {chrome_bin}", file=sys.stderr)
        sys.exit(1)

    try:
        import PIL  # noqa: F401
    except ImportError:
        print("Pillow is required. Install it with:", file=sys.stderr)
        print("  python3 -m pip install --user pillow", file=sys.stderr)
        sys.exit(1)

    source_icns = find_source_icns(chrome_app)
    apps_dir.mkdir(parents=True, exist_ok=True)
    only_names = set(args.only)

    print(f"Using Python:      {sys.executable}")
    print(f"Using Chrome app:  {chrome_app}")
    print(f"Using source icon: {source_icns}")
    print(f"Apps directory:    {apps_dir}")
    print()

    for raw_container in CONTAINERS:
        container = sanitize_container(raw_container)
        if not container_matches_filter(container["name"], only_names):
            continue

        create_or_update_container(
            container=container,
            apps_dir=apps_dir,
            chrome_bin=chrome_bin,
            source_icns=source_icns,
            force=args.force,
            update_icons_only=args.update_icons_only,
            codesign=not args.no_codesign,
            color_factor=args.color_factor,
            brightness_factor=args.brightness_factor,
            contrast_factor=args.contrast_factor,
            badge_fraction=args.badge_fraction,
            padding_fraction=args.padding_fraction,
            badge_opacity=args.badge_opacity,
        )
        print()

    print("Done.")


if __name__ == "__main__":
    main()
