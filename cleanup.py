#!/usr/bin/env python3
"""
o11Pro HLS temizlik scripti — Sakli Karak

.ts  : Playlist son segmentleri korunur, süresi dolan eskiler silinir.
.m4s : DASH ara cache — ffmpeg tükettikten sonra silinir.
.m3u8: Asla silinmez.
"""

import time
from pathlib import Path

TARGET_DIR = Path("/home/o11Pro/hls/live")

# .ts segmentleri bu kadar saniye tutulur (~20 dk)
TS_RETENTION = 1200

# Canlı oynatma — playlist sonundaki segmentler her zaman korunur (~2 dk)
MIN_LIVE_KEEP = 30

# Playlist'te olmayan yetim .ts dosyaları
ORPHAN_AGE = 180

# DASH ara cache (.m4s)
M4S_AGE = 300


def parse_playlist_segments(m3u8_path: Path) -> list[str]:
    if not m3u8_path.is_file() or m3u8_path.stat().st_size == 0:
        return []
    try:
        lines = m3u8_path.read_text(errors="ignore").splitlines()
    except OSError:
        return []
    return [line.strip() for line in lines if line.strip().endswith(".ts")]


def cleanup_channel(channel_dir: Path, now: float) -> tuple[int, int]:
    m3u8 = channel_dir / "stream_0.m3u8"
    playlist_segments = parse_playlist_segments(m3u8)
    playlist_set = set(playlist_segments)
    protected = set(playlist_segments[-MIN_LIVE_KEEP:]) if playlist_segments else set()

    ts_deleted = m4s_deleted = 0

    for file_path in channel_dir.iterdir():
        if not file_path.is_file():
            continue

        suffix = file_path.suffix
        name = file_path.name

        try:
            age = now - file_path.stat().st_mtime
        except OSError:
            continue

        if suffix == ".m3u8":
            continue

        if suffix == ".m4s":
            if age > M4S_AGE:
                file_path.unlink(missing_ok=True)
                m4s_deleted += 1
            continue

        if suffix != ".ts":
            continue

        if name in protected:
            continue

        if name not in playlist_set:
            if age > ORPHAN_AGE:
                file_path.unlink(missing_ok=True)
                ts_deleted += 1
            continue

        if age > TS_RETENTION:
            file_path.unlink(missing_ok=True)
            ts_deleted += 1

    return ts_deleted, m4s_deleted


def main() -> None:
    if not TARGET_DIR.is_dir():
        return

    now = time.time()
    total_ts = total_m4s = 0

    for channel_dir in TARGET_DIR.iterdir():
        if not channel_dir.is_dir():
            continue
        ts, m4s = cleanup_channel(channel_dir, now)
        total_ts += ts
        total_m4s += m4s

    if total_ts or total_m4s:
        print(f"cleanup: {total_ts} ts, {total_m4s} m4s silindi")


if __name__ == "__main__":
    main()
