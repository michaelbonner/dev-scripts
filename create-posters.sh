#!/bin/bash

for file in *.mp4; do
    ffmpeg -i "$file" -ss 00:00:01.000 -vframes 1 "${file%.mp4}-thumbnail.jpg"
done