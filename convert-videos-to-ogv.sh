#! /bin/bash

for file in *.mp4; do
    if [[ -f "$file" && "$file" != *.ogv ]]; then
        ffmpeg -i "$file" "${file%.*}.ogv"
    fi
done
