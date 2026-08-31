#!/usr/bin/env python3
"""Merge Word's Manuscript style set into Pandoc's complete reference DOCX."""

from __future__ import annotations

import argparse
import copy
import io
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET
import zipfile


W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
W = f"{{{W_NS}}}"


def pandoc_reference(quarto: str) -> bytes:
    command = [quarto, "pandoc", "--print-default-data-file", "reference.docx"]
    result = subprocess.run(command, check=True, stdout=subprocess.PIPE)
    return result.stdout


def replace_special(default_root: ET.Element, manuscript_root: ET.Element, tag: str) -> None:
    replacement = manuscript_root.find(f"{W}{tag}")
    if replacement is None:
        return
    current = default_root.find(f"{W}{tag}")
    if current is None:
        default_root.insert(0, copy.deepcopy(replacement))
        return
    index = list(default_root).index(current)
    default_root.remove(current)
    default_root.insert(index, copy.deepcopy(replacement))


def merge_styles(default_xml: bytes, manuscript_xml: bytes) -> bytes:
    default_root = ET.fromstring(default_xml)
    manuscript_root = ET.fromstring(manuscript_xml)

    for tag in ("docDefaults", "latentStyles"):
        replace_special(default_root, manuscript_root, tag)

    default_styles = {
        style.get(f"{W}styleId"): style
        for style in default_root.findall(f"{W}style")
        if style.get(f"{W}styleId")
    }
    for manuscript_style in manuscript_root.findall(f"{W}style"):
        style_id = manuscript_style.get(f"{W}styleId")
        if not style_id:
            continue
        current = default_styles.get(style_id)
        if current is None:
            default_root.append(copy.deepcopy(manuscript_style))
            continue
        index = list(default_root).index(current)
        default_root.remove(current)
        replacement = copy.deepcopy(manuscript_style)
        default_root.insert(index, replacement)
        default_styles[style_id] = replacement

    ET.register_namespace("w", W_NS)
    return ET.tostring(default_root, encoding="utf-8", xml_declaration=True)


def build_reference(manuscript: Path, default_docx: bytes, output: Path) -> None:
    with (
        zipfile.ZipFile(manuscript, "r") as source,
        zipfile.ZipFile(io.BytesIO(default_docx), "r") as default,
    ):
        overrides = {
            "word/styles.xml": merge_styles(
                default.read("word/styles.xml"), source.read("word/styles.xml")
            )
        }
        for part in ("word/theme/theme1.xml", "word/fontTable.xml"):
            if part in source.namelist() and part in default.namelist():
                overrides[part] = source.read(part)

        output.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as result:
            for item in default.infolist():
                result.writestr(item, overrides.get(item.filename, default.read(item.filename)))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manuscript", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument(
        "--pandoc-reference",
        type=Path,
        help="Existing Pandoc reference.docx; otherwise obtain it through Quarto.",
    )
    parser.add_argument("--quarto", default=shutil.which("quarto") or "quarto")
    args = parser.parse_args()

    if not args.manuscript.is_file():
        parser.error(f"Manuscript style set not found: {args.manuscript}")
    if args.out.suffix.lower() != ".docx":
        parser.error("--out must end in .docx")

    default_docx = (
        args.pandoc_reference.read_bytes()
        if args.pandoc_reference
        else pandoc_reference(args.quarto)
    )
    build_reference(args.manuscript, default_docx, args.out)
    print(f"Wrote {args.out}")


if __name__ == "__main__":
    main()
