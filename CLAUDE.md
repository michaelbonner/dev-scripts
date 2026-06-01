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
- **commit-timelog.sh** - Walk every git repo nested under the current directory and write `timelog.txt`: one line per commit (`timestamp  repo-path  subject`), sorted oldest→newest with a blank line between each calendar date. Scans all branches (`git log --all`, local and remote-tracking), not just the checked-out branch. Config block at top sets `AUTHORS` (regex matched case-insensitively against commit author name) and `SINCE` (default `90 days ago`)
- **timelog-by-project.sh** - Chunk `timelog.txt` into billable projects using a `timelog-projects-key.txt` mapping (`folder : Project Name`, or `folder : ignore` to drop). Keeps the same commit-line format but groups commits by day (newest first) under `===== date =====` headers, and within each day by project (alphabetically). Each project header shows that day's commit count plus an estimated work-hours figure (e.g. `Willow Creek App (20 commits): Est 6.75 work hours`), and the date header shows the day's total. Hours are estimated by allocating the day's working span across projects weighted by commit share. The span is session-based: a day's commits are clustered into sessions (a gap longer than `SESSION_GAP_MINUTES`, default 120, starts a new one), and each session contributes its first→last duration plus a `LEAD_IN_MINUTES` (default 45) ramp-up credit — so idle gaps between bursts aren't billed and a lone commit is worth the lead-in alone. The total is rounded to `ROUND_MINUTES` with largest-remainder distribution so per-project estimates sum to the day total. `ignore`-marked repos are non-billable (no estimate, excluded from the span). Keys match a repo's leaf folder name case- and hyphen-insensitively (longest match wins); each day, unlisted repos group under `Unmatched` and `ignore`-marked repos under `Ignored` (both last). Config block sets `INPUT`, `KEY`, `OUTPUT`, `SESSION_GAP_MINUTES`, `LEAD_IN_MINUTES`, `ROUND_MINUTES`

## Required Tools

Scripts depend on various CLI tools (check before running):
- **ffmpeg** - Video compression/conversion
- **ImageMagick** (`magick`) - Image conversion/resizing
- **cwebp** - WebP conversion
- **Ghostscript** (`gs`) - PDF compression
- **bun/npm** - Package management scripts
- **gh** - GitHub CLI for PR creation
