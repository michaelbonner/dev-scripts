#!/usr/bin/env bash
# Filename: delete_videos_shallow.sh

set -euo pipefail

DRY_RUN=false
AUTO_YES=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --yes) AUTO_YES=true ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [--yes]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

# Collect matching files at depth 2
# We print them first for visibility; then delete using -delete to avoid long argv.
matches() {
  find . -maxdepth 2 -mindepth 2 -type f \( -iname '*.mp4' -o -iname '*.mov' -o -iname '*.m4v' \)
}

MAP_COUNT=0
while IFS= read -r path; do
  if [ "$MAP_COUNT" -eq 0 ]; then
    echo "Found video file(s) eligible for deletion (depth 2):"
  fi
  printf '  %s\n' "$path"
  MAP_COUNT=$((MAP_COUNT + 1))
done < <(matches)

if [ "$MAP_COUNT" -eq 0 ]; then
  echo "No matching video files found at depth 2."
  exit 0
fi

if [ "$DRY_RUN" = true ]; then
  echo "Dry run mode: no files will be deleted."
  # Continue to show compressed folder processing in dry-run mode
fi

if [ "$DRY_RUN" = false ] && [ "$AUTO_YES" = false ]; then
  read -r -p "Delete these $MAP_COUNT file(s)? [y/N]: " CONFIRM
  case "${CONFIRM:-N}" in
    y|Y) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
fi

# Delete using find -delete to avoid long argv
if [ "$DRY_RUN" = false ]; then
  find . -maxdepth 2 -mindepth 2 -type f \( -iname '*.mp4' -o -iname '*.mov' -o -iname '*.m4v' \) -print -delete
  echo "Deletion complete."
else
  echo "Dry run: would delete files listed above."
fi

# Move files from compressed folders up one directory level
echo ""
echo "Processing compressed folders..."

# Find all compressed directories and sort by depth (deepest first) to handle nested cases
# Count slashes to determine depth, then sort by depth descending
compressed_dirs=$(find . -type d -name "compressed" | while IFS= read -r dir; do
  depth=$(echo "$dir" | tr -cd '/' | wc -c | tr -d ' ')
  echo "$depth|$dir"
done | sort -t'|' -k1 -rn | cut -d'|' -f2-)

if [ -z "$compressed_dirs" ]; then
  echo "No compressed folders found."
else
  while IFS= read -r compressed_dir; do
    # Get the parent directory
    parent_dir=$(dirname "$compressed_dir")
    
    # Skip if compressed is at root (.)
    if [ "$parent_dir" = "." ]; then
      if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Skipping root-level compressed directory: $compressed_dir"
      else
        echo "  Skipping root-level compressed directory: $compressed_dir"
      fi
      continue
    fi
    
    # Count files in compressed directory (only direct files, not in subdirectories)
    file_count=$(find "$compressed_dir" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$file_count" -eq 0 ]; then
      if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] No files to move in: $compressed_dir"
      fi
    else
      if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would move $file_count file(s) from $compressed_dir to $parent_dir"
        find "$compressed_dir" -maxdepth 1 -type f -exec echo "    Would move: {} -> $parent_dir/" \;
      else
        echo "  Moving $file_count file(s) from $compressed_dir to $parent_dir"
        find "$compressed_dir" -maxdepth 1 -type f -exec mv {} "$parent_dir/" \;
      fi
    fi
    
    # Check if compressed directory is now empty and remove it
    if [ "$DRY_RUN" = false ]; then
      # Check if directory has any remaining items (files or subdirectories)
      if [ -z "$(find "$compressed_dir" -mindepth 1 -maxdepth 1 2>/dev/null)" ]; then
        echo "  Removing empty directory: $compressed_dir"
        rmdir "$compressed_dir" 2>/dev/null || true
      fi
    else
      # In dry-run, check if it would be empty after moving files
      # Count all items (files + directories) currently in the folder
      total_items=$(find "$compressed_dir" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
      # Would be empty if only files remain and we're moving all files
      if [ "$total_items" -eq "$file_count" ] && [ "$file_count" -gt 0 ]; then
        echo "  [DRY RUN] Would remove empty directory: $compressed_dir"
      elif [ "$total_items" -eq 0 ]; then
        echo "  [DRY RUN] Would remove empty directory: $compressed_dir"
      fi
    fi
  done <<< "$compressed_dirs"
fi

if [ "$DRY_RUN" = true ]; then
  echo "Dry run complete: no files were moved or directories removed."
else
  echo "Compressed folder processing complete."
fi

