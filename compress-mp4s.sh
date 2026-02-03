#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

#–– Configuration ––
vcodec="libx264"
crf=23
preset="veryslow"

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

  # If output file exists, add a number suffix to make it unique
  if [[ -e "$outfile" ]]; then
    counter=2
    while [[ -e "$outdir/${base}-compressed-${counter}.mp4" ]]; do
      ((counter++))
    done
    outfile="$outdir/${base}-compressed-${counter}.mp4"
  fi

  echo "Compressing: $infile → $outfile"
  ffmpeg -i "$infile" \
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