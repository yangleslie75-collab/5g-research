
#!/usr/bin/env python3

# -*- coding: utf-8 -*-



import argparse

import csv

import hashlib

import shutil

import subprocess

from pathlib import Path



from PIL import Image, ImageOps





TEXT_EXTS = {".txt"}

AUDIO_EXTS = {".wav", ".mp3", ".flac", ".m4a", ".ogg"}

IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}

VIDEO_EXTS = {".mp4", ".avi", ".mov", ".mkv", ".gif", ".webm"}





def sha256_file(path: Path) -> str:

    h = hashlib.sha256()

    with path.open("rb") as f:

        for chunk in iter(lambda: f.read(1024 * 1024), b""):

            h.update(chunk)

    return h.hexdigest()





def safe_name(index: int, src: Path, suffix: str) -> str:

    stem = src.stem.replace(" ", "_").replace("/", "_")

    return f"{index:06d}_{stem}{suffix}"





def run_cmd(cmd, timeout_sec: int = 120):

    subprocess.run(

        cmd,

        check=True,

        stdout=subprocess.DEVNULL,

        stderr=subprocess.DEVNULL,

        timeout=timeout_sec,

    )





def normalize_text_file(src: Path, dst: Path, target_bytes: int):

    raw = src.read_bytes()



    try:

        text = raw.decode("utf-8", errors="ignore")

    except Exception:

        text = raw.decode("latin1", errors="ignore")



    text = text.replace("\r\n", "\n").replace("\r", "\n")

    text = "\n".join(line.strip() for line in text.splitlines())

    text = " ".join(text.split())



    if not text:

        text = "empty text sample"



    while len(text.encode("utf-8")) > target_bytes:

        text = text[:-1]



    data = text.encode("utf-8")



    if len(data) < target_bytes:

        data += b" " * (target_bytes - len(data))



    dst.write_bytes(data)





def normalize_audio_file(src: Path, dst: Path, duration_sec: float, sample_rate: int):

    cmd = [

        "ffmpeg", "-nostdin", "-y",

        "-stream_loop", "-1",

        "-i", str(src),

        "-t", str(duration_sec),

        "-ac", "1",

        "-ar", str(sample_rate),

        "-sample_fmt", "s16",

        "-vn",

        str(dst),

    ]

    run_cmd(cmd, timeout_sec=120)





def normalize_image_file(src: Path, dst: Path, image_size: int, quality: int):

    img = Image.open(src).convert("RGB")

    img = ImageOps.exif_transpose(img)

    try:

        resample_filter = Image.Resampling.LANCZOS

    except AttributeError:

        if hasattr(Image, "LANCZOS"):

            resample_filter = Image.LANCZOS

        else:

            resample_filter = Image.ANTIALIAS



    img = ImageOps.fit(img, (image_size, image_size), method=resample_filter)


    img.save(dst, format="JPEG", quality=quality, optimize=True)





def normalize_video_file(src: Path, dst: Path, duration_sec: float, size: int, fps: int):

    vf = (

        f"scale={size}:{size}:force_original_aspect_ratio=decrease,"

        f"pad={size}:{size}:(ow-iw)/2:(oh-ih)/2,"

        f"fps={fps},format=yuv420p"

    )



    cmd = [

        "ffmpeg", "-nostdin", "-y",

        "-stream_loop", "-1",

        "-i", str(src),

        "-t", str(duration_sec),

        "-vf", vf,

        "-an",

        "-c:v", "libx264",

        "-preset", "veryfast",

        "-crf", "23",

        "-pix_fmt", "yuv420p",

        str(dst),

    ]

    run_cmd(cmd, timeout_sec=180)





def collect_files(folder: Path, exts):

    if not folder.exists():

        return []

    return sorted([p for p in folder.rglob("*") if p.is_file() and p.suffix.lower() in exts])





def process_class(label, files, out_dir, args, rows):

    out_dir.mkdir(parents=True, exist_ok=True)



    for i, src in enumerate(files, start=1):

        try:

            if label == "text":

                dst = out_dir / safe_name(i, src, ".txt")

                normalize_text_file(src, dst, args.text_bytes)



            elif label == "audio":

                dst = out_dir / safe_name(i, src, ".wav")

                normalize_audio_file(src, dst, args.audio_sec, args.audio_sr)



            elif label == "image":

                dst = out_dir / safe_name(i, src, ".jpg")

                normalize_image_file(src, dst, args.image_size, args.image_quality)



            elif label == "video":

                dst = out_dir / safe_name(i, src, ".mp4")

                normalize_video_file(src, dst, args.video_sec, args.video_size, args.video_fps)



            else:

                raise ValueError(label)



            rows.append({

                "status": "ok",

                "modality": label,

                "source_path": str(src),

                "standardized_path": str(dst),

                "source_bytes": src.stat().st_size,

                "standardized_bytes": dst.stat().st_size,

                "sha256_source": sha256_file(src),

                "sha256_standardized": sha256_file(dst),

                "error": "",

            })



            print(f"[ok] {label}: {src.name} -> {dst.name}", flush=True)



        except Exception as exc:

            rows.append({

                "status": "error",

                "modality": label,

                "source_path": str(src),

                "standardized_path": "",

                "source_bytes": src.stat().st_size if src.exists() else "",

                "standardized_bytes": "",

                "sha256_source": sha256_file(src) if src.exists() else "",

                "sha256_standardized": "",

                "error": str(exc),

            })

            print(f"[error] {label}: {src} | {exc}", flush=True)





def main():

    parser = argparse.ArgumentParser()

    parser.add_argument("--source-root", default="/home/ps/PycharmProjects/researchtopic/pusch_plus/datasets/source_payloads")

    parser.add_argument("--out-root", default="/home/ps/PycharmProjects/researchtopic/pusch_plus/datasets/source_payloads_std")

    parser.add_argument("--clean", action="store_true")



    parser.add_argument("--text-bytes", type=int, default=4096)



    parser.add_argument("--audio-sec", type=float, default=3.0)

    parser.add_argument("--audio-sr", type=int, default=16000)



    parser.add_argument("--image-size", type=int, default=256)

    parser.add_argument("--image-quality", type=int, default=90)



    parser.add_argument("--video-sec", type=float, default=3.0)

    parser.add_argument("--video-size", type=int, default=256)

    parser.add_argument("--video-fps", type=int, default=15)



    args = parser.parse_args()



    source_root = Path(args.source_root).expanduser().resolve()

    out_root = Path(args.out_root).expanduser().resolve()



    if args.clean and out_root.exists():

        shutil.rmtree(out_root)



    out_root.mkdir(parents=True, exist_ok=True)



    rows = []



    text_files = collect_files(source_root / "text", TEXT_EXTS)

    audio_files = collect_files(source_root / "audio", AUDIO_EXTS)

    image_files = collect_files(source_root / "image", IMAGE_EXTS)

    video_files = collect_files(source_root / "video", VIDEO_EXTS)



    print(f"text : {len(text_files)}")

    print(f"audio: {len(audio_files)}")

    print(f"image: {len(image_files)}")

    print(f"video: {len(video_files)}")



    process_class("text", text_files, out_root / "text", args, rows)

    process_class("audio", audio_files, out_root / "audio", args, rows)

    process_class("image", image_files, out_root / "image", args, rows)

    process_class("video", video_files, out_root / "video", args, rows)



    manifest_path = out_root / "standardization_manifest.csv"

    with manifest_path.open("w", newline="", encoding="utf-8") as f:

        fieldnames = [

            "status",

            "modality",

            "source_path",

            "standardized_path",

            "source_bytes",

            "standardized_bytes",

            "sha256_source",

            "sha256_standardized",

            "error",

        ]

        writer = csv.DictWriter(f, fieldnames=fieldnames)

        writer.writeheader()

        writer.writerows(rows)



    print(f"\nSaved standardized dataset to: {out_root}")

    print(f"Manifest: {manifest_path}")





if __name__ == "__main__":

    main()

