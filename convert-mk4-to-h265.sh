#!/bin/bash

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "ffmpeg could not be found. Please install it first."
    exit 1
fi

# Loop through all .mkv files in the current directory
for file in *.mkv; do
    # Check if there are any .mkv files
    if [[ ! -e "$file" ]]; then
        echo "No .mkv files found in the current directory."
        exit 1
    fi

    # Define output file name
    output="${file%.mkv}.mp4"

    # Check if the output file already exists
    if [[ -e "$output" ]]; then
        echo "File '$output' already exists. Skipping conversion for '$file'."
        continue
    fi

    # Convert the video using ffmpeg
    ffmpeg -i "$file" -c:v libx265 -preset medium -crf 23 -c:a aac -b:a 192k -movflags +faststart "$output"

    echo "Converted '$file' to '$output'."
done

echo "Conversion completed."
