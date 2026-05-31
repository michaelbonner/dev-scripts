#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

#–– Configuration ––
vcodec="libx264"
crf=23
preset="veryslow"

# Skip re-encoding when a compressed output already exists and is at least
# this many bytes (guards against leftover empty/partial files from a crash).
min_size_bytes=$((100 * 1024)) # 100 KB

# Root directory (first arg) or current dir
root="${1:-.}"

echo "Compressing videos under: $root"
echo "Codec: $vcodec  CRF: $crf  Preset: $preset"
echo

# Find all video files, exclude any whose name contains "compressed"
find "$root" -type f \
  \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" \
  -o -iname "*.avi" -o -iname "*.webm" \) \
  ! -iname "*compressed*" -print0 |
while IFS= read -r -d '' infile; do
  dir=$(dirname "$infile")
  base=$(basename "${infile%.*}")
  outdir="$dir/compressed"
  mkdir -p "$outdir"
  outfile="$outdir/${base}-compressed.mp4"

  # Skip if a compressed output already exists with a realistic file size
  if [[ -f "$outfile" ]]; then
    size=$(stat -f%z "$outfile" 2>/dev/null || stat -c%s "$outfile" 2>/dev/null || echo 0)
    if (( size >= min_size_bytes )); then
      echo "Skipping (already compressed): $outfile"
      echo
      continue
    fi
    echo "Re-encoding (existing output too small): $outfile"
  fi

  echo "Compressing: $infile → $outfile"
  ffmpeg -y -i "$infile" \
    -c:v "$vcodec" \
    -preset "$preset" \
    -crf "$crf" \
    -c:a copy \
    -movflags +faststart \
    "$outfile" </dev/null
  echo "  ✔ Done."
  echo
done

echo "All done."