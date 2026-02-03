#!/bin/bash

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null
then
    echo "ImageMagick is not installed. Please install it and try again."
    exit 1
fi

# Find all PNG files recursively in the current directory
find . -type f -iname "*.png" | while read -r file
do
    # Get the filename without extension
    filename="${file%.*}"
    
    # Convert PNG to JPG
    magick convert "$file" "${filename}.png.jpg"
    
    # Check if conversion was successful
    if [ $? -eq 0 ]; then
        echo "Converted $file to ${filename}.jpg"
        
        # Delete the original PNG file
        rm "$file"
        echo "Deleted original file: $file"
    else
        echo "Failed to convert $file"
    fi
done

echo "Conversion process completed."
