"""Package deterministic Godot captures without changing game/source artwork."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil

from PIL import Image, ImageDraw, ImageOps


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", type=Path, default=Path("output/qa/rc-017/motion"))
    parser.add_argument("--keep-frames", action="store_true")
    args = parser.parse_args()
    destination = args.directory.resolve()
    project = Path(__file__).resolve().parents[1]
    report = json.loads((destination / "results.json").read_text(encoding="utf-8"))
    packaged = []
    for sequence in report["sequences"]:
        folder = destination / sequence["name"]
        frames = [project / frame["path"].removeprefix("res://") for frame in sequence["frames"]]
        if not frames:
            continue
        source_paths = [folder / "before.png", *frames, folder / "after.png"]
        images = []
        for path in source_paths:
            with Image.open(path) as image:
                width = min(360, image.width)
                images.append(image.convert("RGB").resize((width, round(image.height * width / image.width)), Image.Resampling.LANCZOS))
        # One palette preserves unchanged pixels between frames, preventing
        # independent adaptive palettes from producing a full-image flicker/diff.
        palette_source = Image.new("RGB", (90 * len(images), 220))
        for index, image in enumerate(images):
            palette_source.paste(ImageOps.contain(image, (90, 220)), (90 * index, 0))
        palette = palette_source.quantize(colors=256)
        encoded = [image.quantize(palette=palette, dither=Image.Dither.NONE) for image in images]
        gif = folder / "motion.gif"
        encoded[0].save(gif, save_all=True, append_images=encoded[1:], loop=0,
                       duration=[350] + [round(report["frame_seconds"] * 1000)] * len(frames) + [700],
                       optimize=False, disposal=1)
        representatives = []
        phase_order = list(dict.fromkeys(frame["phase"] for frame in sequence["frames"]))
        for phase in phase_order:
            sample = sequence["representative"][phase]
            source = project / sample["path"].removeprefix("res://")
            target = folder / f"key-{phase}.png"
            shutil.copyfile(source, target)
            representatives.append(target)
        columns = min(4, len(representatives) + 2)
        selections = [folder / "before.png", *representatives, folder / "after.png"]
        cell_width, cell_height = 225, 530
        sheet = Image.new("RGB", (columns * cell_width, ((len(selections) + columns - 1) // columns) * cell_height), "#111725")
        draw = ImageDraw.Draw(sheet)
        for index, path in enumerate(selections):
            x, y = index % columns * cell_width, index // columns * cell_height
            with Image.open(path) as image:
                thumb = ImageOps.contain(image.convert("RGB"), (cell_width, cell_height - 30), Image.Resampling.LANCZOS)
                sheet.paste(thumb, (x + (cell_width - thumb.width) // 2, y + 30))
            draw.text((x + 6, y + 7), path.stem.removeprefix("key-"), fill="#f4dfaf")
        contact = folder / "contact.png"
        sheet.save(contact, optimize=True)
        item = {"name": sequence["name"], "gif": gif.relative_to(project).as_posix(),
                "gif_bytes": gif.stat().st_size, "gif_sha256": digest(gif),
                "contact": contact.relative_to(project).as_posix(),
                "key_stills": [{"path": path.relative_to(project).as_posix(), "sha256": digest(path)} for path in selections],
                "frame_count": len(frames), "raw_frames_retained": args.keep_frames,
                "source_frame_hashes": [{"path": path.name, "sha256": digest(path)} for path in frames]}
        packaged.append(item)
        if not args.keep_frames:
            for path in frames:
                if path.parent.resolve() != folder or not path.name.startswith("frame-"):
                    raise RuntimeError(f"Refusing to remove unexpected temporary capture {path}")
                path.unlink()
    receipt = {"source": "results.json", "note": "GIFs are reduced-size convenience sequences; native key stills retain actual render dimensions. Temporary per-frame PNGs are reproducible with capture_combat_animation.gd and hashed here before removal.", "sequences": packaged}
    (destination / "media.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"sequences": len(packaged), "gif_bytes": sum(item["gif_bytes"] for item in packaged), "output": str(destination / "media.json")}))


if __name__ == "__main__":
    main()
