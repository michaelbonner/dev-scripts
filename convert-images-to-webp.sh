#!/bin/bash

# Set the quality level for WebP conversion (0-100)
QUALITY=80

# Check if cwebp is installed and accessible
if ! command -v cwebp &> /dev/null; then
    echo "cwebp command not found. Please install WebP tools and add them to your PATH."
    exit 1
fi

# Loop through all JPEG and PNG files in the current directory
for file in *.jpg *.jpeg *.png; do
    # Skip if no files are found
    if [ -z "$file" ]; then
        echo "No images found in the current directory."
        break
    fi

    # Convert the image to WebP
    output_file="${file}.webp"
    cwebp -q $QUALITY "$file" -o "$output_file"
    echo "Converted $file to $output_file"
done
