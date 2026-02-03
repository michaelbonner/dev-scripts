#!/bin/bash

# Check if magick is installed
if ! command -v magick &> /dev/null; then
    echo "magick is not installed. Please install it and try again."
    exit 1
fi

# Find all .gif files in the current directory and subdirectories
find . -type f -name "*.gif" | while read -r file; do
    # Get the filename without extension
    filename="${file%.*}"
    
    # Convert .gif to .webp using magick
    magick "$file" "${filename}.gif.webp"
    
    # Check if conversion was successful
    if [ $? -eq 0 ]; then
        # Delete the original .gif file
        rm "$file"
        echo "Converted and deleted $file"
    else
        echo "Conversion failed for $file"
    fi
done

echo "Conversion and deletion complete!"
