# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a collection of standalone bash utility scripts, primarily for media processing (images, videos, PDFs) and development workflow automation. Each script is self-contained and designed to be run from the directory containing the files to process.

## Script Categories

### Media Compression & Conversion
- **compress-mp4s.sh** - Compress videos (mp4/mkv/mov/avi/webm) using libx264, outputs to `compressed/` subdirectory
- **compress-pdfs.sh** - Compress PDFs using Ghostscript (requires `brew install ghostscript`)
- **convert-images-to-webp.sh** - Convert JPG/PNG to WebP using cwebp
- **convert-jpegs-to-avif.sh** - Convert JPG/JPEG to AVIF using ImageMagick (env vars: `QUALITY`, `SPEED`)
- **convert-all-pngs-to-jpgs.sh** - Convert PNGs to JPGs recursively, deletes originals
- **convert-all-gif-to-webp.sh** - Convert GIFs to WebP recursively, deletes originals
- **resize-large-images.sh** - Resize images larger than 2000x2000 using ImageMagick

### Video Processing
- **convert-mk4-to-h265.sh** - Convert MKV to MP4 with H.265/HEVC encoding
- **convert-videos-to-ogv.sh** - Convert MP4 to OGV format
- **create-posters.sh** - Extract thumbnail frame from MP4 videos at 1 second mark
- **remove-video-files-in-folders.sh** - Delete videos at depth 2 and move compressed files up (supports `--dry-run`, `--yes`)

### Development Workflow
- **clean-install.sh** - Clean reinstall for Next.js/Bun projects (removes node_modules, .next, clears bun cache)
- **bun-out-pr.sh** - Check outdated deps, update with Bun, create PR via GitHub CLI
- **npm-out-pr.sh** - Check outdated deps, update with npm, create PR via GitHub CLI
- **tar-up-all-folders.sh** - Create .tar.gz archives for all directories

## Required Tools

Scripts depend on various CLI tools (check before running):
- **ffmpeg** - Video compression/conversion
- **ImageMagick** (`magick`) - Image conversion/resizing
- **cwebp** - WebP conversion
- **Ghostscript** (`gs`) - PDF compression
- **bun/npm** - Package management scripts
- **gh** - GitHub CLI for PR creation
