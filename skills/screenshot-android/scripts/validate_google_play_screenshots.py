#!/usr/bin/env python3
"""Validate Google Play screenshot and preview-graphic inputs."""

from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:  # pragma: no cover - environment dependent
    raise SystemExit("Pillow is required: python3 -m pip install Pillow") from exc


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg"}
LARGE_SCREEN_DEVICES = {"seven-inch", "ten-inch", "tablet", "chromebook"}


def parse_requirements(values: list[str]) -> dict[str, int]:
    requirements: dict[str, int] = {}
    for value in values:
        try:
            device, count_text = value.split("=", 1)
            count = int(count_text)
        except ValueError as exc:
            raise argparse.ArgumentTypeError("Use DEVICE=COUNT, for example phone=2") from exc
        if not device or count < 0:
            raise argparse.ArgumentTypeError("Device must be non-empty and count must be non-negative")
        requirements[device] = count
    return requirements


def has_alpha(image: Image.Image) -> bool:
    if "transparency" in image.info:
        return True
    return image.mode in {"RGBA", "LA", "PA"} or (image.mode == "P" and "transparency" in image.info)


def checksum(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_graphic(path: Path, expected_size: tuple[int, int], label: str, allow_alpha: bool) -> list[str]:
    errors: list[str] = []
    if not path.is_file():
        return [f"{label}: missing file: {path}"]
    if path.suffix.lower() not in IMAGE_EXTENSIONS:
        return [f"{label}: unsupported extension: {path.suffix}"]

    try:
        with Image.open(path) as image:
            if image.size != expected_size:
                errors.append(f"{label}: expected {expected_size[0]}x{expected_size[1]}, found {image.width}x{image.height}")
            if not allow_alpha and has_alpha(image):
                errors.append(f"{label}: alpha channel/transparency is not allowed")
            if label == "app icon" and path.stat().st_size > 1024 * 1024:
                errors.append(f"{label}: file is larger than 1 MB")
    except Exception as exc:
        errors.append(f"{label}: unreadable image ({exc})")
    return errors


def validate_screenshot(path: Path, device: str) -> list[str]:
    errors: list[str] = []
    if path.suffix.lower() not in IMAGE_EXTENSIONS:
        return [f"{path}: unsupported extension; use PNG or JPEG"]

    try:
        with Image.open(path) as image:
            short_side = min(image.size)
            long_side = max(image.size)
            ratio = long_side / short_side
            if has_alpha(image):
                errors.append(f"{path}: screenshot has alpha/transparency")
            if short_side < 320:
                errors.append(f"{path}: minimum dimension is {short_side}px; must be at least 320px")

            if device in LARGE_SCREEN_DEVICES:
                if short_side < 1080 or long_side > 7680:
                    errors.append(f"{path}: large-screen dimensions are {image.width}x{image.height}; expected short side >=1080 and long side <=7680")
                expected_ratio = 16 / 9
                if abs(ratio - expected_ratio) > 0.02:
                    errors.append(f"{path}: large-screen aspect ratio {ratio:.4f} is not approximately 16:9 or 9:16")
            else:
                if long_side > 3840:
                    errors.append(f"{path}: maximum dimension is {long_side}px; must be at most 3840px")
                if ratio > 2:
                    errors.append(f"{path}: aspect ratio {ratio:.4f} exceeds the 2:1 limit")
    except Exception as exc:
        errors.append(f"{path}: unreadable image ({exc})")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True, help="Root containing <locale>/<device> screenshot folders")
    parser.add_argument("--require", action="append", default=[], metavar="DEVICE=COUNT", help="Minimum screenshots per device category; repeatable")
    parser.add_argument("--icon", type=Path, help="Optional 512x512 Play app icon")
    parser.add_argument("--feature-graphic", type=Path, help="Optional 1024x500 Play feature graphic")
    args = parser.parse_args()

    requirements = parse_requirements(args.require)
    errors: list[str] = []
    checked = 0

    if not args.root.is_dir():
        errors.append(f"Screenshot root does not exist: {args.root}")
    else:
        for locale_dir in sorted(path for path in args.root.iterdir() if path.is_dir()):
            for device_dir in sorted(path for path in locale_dir.iterdir() if path.is_dir()):
                files = sorted(path for path in device_dir.iterdir() if path.is_file())
                image_files = [path for path in files if path.suffix.lower() in IMAGE_EXTENSIONS]
                required = requirements.get(device_dir.name)
                if required is not None and len(image_files) < required:
                    errors.append(f"{locale_dir.name}/{device_dir.name}: found {len(image_files)} screenshots; need at least {required}")
                if len(image_files) > 8:
                    errors.append(f"{locale_dir.name}/{device_dir.name}: found {len(image_files)} screenshots; maximum is 8")

                seen: dict[str, Path] = {}
                for image_path in image_files:
                    checked += 1
                    errors.extend(validate_screenshot(image_path, device_dir.name))
                    digest = checksum(image_path)
                    if digest in seen:
                        errors.append(f"{image_path}: duplicate checksum with {seen[digest]}")
                    else:
                        seen[digest] = image_path

    if args.icon:
        errors.extend(validate_graphic(args.icon, (512, 512), "app icon", allow_alpha=True))
    if args.feature_graphic:
        errors.extend(validate_graphic(args.feature_graphic, (1024, 500), "feature graphic", allow_alpha=False))

    print(f"Checked {checked} screenshot files under {args.root}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        print(f"Validation failed with {len(errors)} error(s)", file=sys.stderr)
        return 1

    print("Google Play screenshot validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
