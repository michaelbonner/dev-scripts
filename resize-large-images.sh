#!/usr/bin/env bash

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null; then
    echo "ImageMagick is not installed. Please install it and try again."
    exit 1
fi

MAX_SIZE="${1:-2000}"

# Find all images and resize them if they are larger than MAX_SIZExMAX_SIZE
find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -exec sh -c '
    max_size="$2"
    width=$(identify -format "%w" "$1")
    height=$(identify -format "%h" "$1")
    if [ "$width" -gt "$max_size" ] || [ "$height" -gt "$max_size" ]; then
        magick "$1" -background white -alpha remove -resize "${max_size}x${max_size}>" "$1"
        echo "Resized $1"
    fi
' sh {} "$MAX_SIZE" \;
