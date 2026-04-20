#!/usr/bin/env bash

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null; then
    echo "ImageMagick is not installed. Please install it and try again."
    exit 1
fi

# Find all images and resize them if they are larger than 2000x2000
find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -exec sh -c '
    width=$(identify -format "%w" "$1")
    height=$(identify -format "%h" "$1")
    if [ $width -gt 2000 ] || [ $height -gt 2000 ]; then
        magick "$1" -background white -alpha remove -resize "2000x2000>" "$1"
        echo "Resized $1"
    fi
' sh {} \;
