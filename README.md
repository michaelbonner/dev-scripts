# Scripts

A collection of standalone bash utility scripts for media processing and development workflow automation. Each script is self-contained and designed to be run from the directory containing the files to process.

## Media Compression & Conversion

| Script                        | Description                                                                                 |
| ----------------------------- | ------------------------------------------------------------------------------------------- |
| `compress-mp4s.sh`            | Compress videos (mp4/mkv/mov/avi/webm) using libx264, outputs to `compressed/` subdirectory |
| `compress-pdfs.sh`            | Compress PDFs using Ghostscript                                                             |
| `convert-images-to-webp.sh`   | Convert JPG/PNG to WebP using cwebp                                                         |
| `convert-jpegs-to-avif.sh`    | Convert JPG/JPEG to AVIF using ImageMagick                                                  |
| `convert-all-pngs-to-jpgs.sh` | Convert PNGs to JPGs recursively, deletes originals                                         |
| `convert-all-gif-to-webp.sh`  | Convert GIFs to WebP recursively, deletes originals                                         |
| `resize-large-images.sh`      | Resize images larger than 2000x2000 using ImageMagick                                       |

## Video Processing

| Script                             | Description                                              |
| ---------------------------------- | -------------------------------------------------------- |
| `convert-mk4-to-h265.sh`           | Convert MKV to MP4 with H.265/HEVC encoding              |
| `convert-videos-to-ogv.sh`         | Convert MP4 to OGV format                                |
| `create-posters.sh`                | Extract thumbnail frame from MP4 videos at 1 second mark |
| `trim-worthless-frames.sh`         | Remove stale video time from screen recordings           |
| `remove-video-files-in-folders.sh` | Delete videos at depth 2 and move compressed files up    |

## Development Workflow

| Script                  | Description                                                                              |
| ----------------------- | ---------------------------------------------------------------------------------------- |
| `clean-install.sh`      | Clean reinstall for Next.js/Bun projects (removes node_modules, .next, clears bun cache) |
| `bun-out-pr.sh`         | Check outdated deps, update with Bun, create PR via GitHub CLI                           |
| `npm-out-pr.sh`         | Check outdated deps, update with npm, create PR via GitHub CLI                           |
| `tar-up-all-folders.sh` | Create .tar.gz archives for all directories                                              |

## Requirements

Scripts depend on various CLI tools. Install as needed:

```bash
# Video processing
brew install ffmpeg

# Image processing
brew install imagemagick cwebp

# PDF compression
brew install ghostscript

# Development workflow
brew install bun gh
```

## Usage

Most scripts are designed to be run from the directory containing the files you want to process:

```bash
cd /path/to/your/files
/path/to/scripts/compress-mp4s.sh
```

Some scripts support flags:

```bash
# Dry run mode
remove-video-files-in-folders.sh --dry-run

# Skip confirmation
remove-video-files-in-folders.sh --yes
```

Environment variables for `convert-jpegs-to-avif.sh`:

```bash
QUALITY=80 SPEED=6 ./convert-jpegs-to-avif.sh
```
