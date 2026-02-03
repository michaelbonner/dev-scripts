#!/bin/bash

# Check if Ghostscript is installed
if ! command -v gs &> /dev/null; then
    echo "Ghostscript is not installed. Please install it using 'brew install ghostscript'"
    exit 1
fi

# Loop through all PDF files in the current directory
for file in *.pdf; do
    if [ -f "$file" ]; then
        output_file="${file%.pdf}_compressed.pdf"
        /opt/homebrew/bin/gs -q -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite \
           -dCompatibilityLevel=1.5 -dPDFSETTINGS=/screen \
           -dEmbedAllFonts=true -dSubsetFonts=true \
           -dColorImageDownsampleType=/Bicubic -dColorImageResolution=150 \
           -dGrayImageDownsampleType=/Bicubic -dGrayImageResolution=150 \
           -dMonoImageDownsampleType=/Bicubic -dMonoImageResolution=150 \
           -sOutputFile="$output_file" "$file"
        echo "Compressed $file to $output_file"
    fi
done
