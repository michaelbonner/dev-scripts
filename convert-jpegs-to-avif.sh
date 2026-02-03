#!/usr/bin/env bash
# convert-jpgs-to-avif.sh
# Converts all .jpg/.jpeg in the current folder to .avif using ImageMagick + libheif.

set -euo pipefail

QUALITY="${QUALITY:-60}"   # 0-100, higher = better quality, larger file
SPEED="${SPEED:-4}"        # 0-8 for libaom via libheif; lower = slower/better

shopt -s nullglob nocaseglob
jpgs=( *.jpg *.jpeg )
shopt -u nocaseglob

if [ ${#jpgs[@]} -eq 0 ]; then
  echo "No JPG/JPEG files found."
  exit 0
fi

for input in "${jpgs[@]}"; do
  base="${input%.*}"
  output="${base}.avif"

  if [ -e "$output" ]; then
    echo "Skipping '$input' → '$output' (already exists)"
    continue
  fi

  echo "Converting '$input' → '$output' (quality=${QUALITY}, speed=${SPEED})"
  # -strip removes metadata. Remove it if you want to keep EXIF.
  magick "$input" -strip -quality "${QUALITY}" -define heic:speed="${SPEED}" "$output"
done

echo "Done."

