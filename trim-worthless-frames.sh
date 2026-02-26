#!/bin/bash

# Usage: ./trim_dupes.sh input.webm [output.webm] [hold_seconds]

INPUT="$1"
OUTPUT="${2:-${INPUT%.*}_trimmed.${INPUT##*.}}"
HOLD="${3:-3}"

if [[ -z "$INPUT" ]]; then
  echo "Usage: $0 input [output] [hold_seconds]"
  exit 1
fi

if [[ ! -f "$INPUT" ]]; then
  echo "Error: File '$INPUT' not found."
  exit 1
fi

echo "Processing: $INPUT"
echo "Output:     $OUTPUT"
echo "Hold per scene: ${HOLD}s"

FPS=$(ffprobe -v error -select_streams v:0 \
  -show_entries stream=r_frame_rate \
  -of default=noprint_wrappers=1:nokey=1 "$INPUT" \
  | bc -l)

echo "Detected FPS: $FPS"

# Step 1: Detect scene change timestamps (in seconds)
echo "Detecting scene changes..."
SCENES=$(ffprobe -v quiet \
  -select_streams v \
  -show_frames \
  -show_entries frame=pts_time,pkt_pts_time \
  -of default=noprint_wrappers=1 \
  -f lavfi "movie=${INPUT},select=gt(scene\,0.1)" \
  | grep "pts_time" | head -1 | cut -d= -f2)

# Better approach: use scene filter directly
SCENES=$(ffprobe -v quiet \
  -select_streams v \
  -show_entries frame=best_effort_timestamp_time \
  -of csv=p=0 \
  -f lavfi "movie=${INPUT},select=gt(scene\,0.1)" 2>/dev/null)

if [[ -z "$SCENES" ]]; then
  echo "No scene changes detected. Try lowering the scene threshold."
  exit 1
fi

SCENE_COUNT=$(echo "$SCENES" | wc -l | tr -d ' ')
echo "Found $SCENE_COUNT scene changes"
echo "First few timestamps: $(echo "$SCENES" | head -5)"

# Step 2: Build segments — for each scene change, keep [ts-0.5, ts+HOLD]
SEGMENTS_FILE=$(mktemp)
echo "0 $HOLD" >> "$SEGMENTS_FILE"

while IFS= read -r ts; do
  [[ -z "$ts" ]] && continue
  START=$(echo "$ts - 0.5" | bc)
  if (( $(echo "$START < 0" | bc -l) )); then START=0; fi
  END=$(echo "$ts + $HOLD" | bc)
  echo "$START $END" >> "$SEGMENTS_FILE"
done <<< "$SCENES"

# Step 3: Merge overlapping segments
MERGED=$(sort -n "$SEGMENTS_FILE" | awk '
{
  start = $1 + 0
  end = $2 + 0
  if (NR == 1) { s = start; e = end }
  else if (start <= e) { if (end > e) e = end }
  else { print s, e; s = start; e = end }
}
END { print s, e }
')

echo "Merged segments:"
echo "$MERGED"

SEGMENT_COUNT=$(echo "$MERGED" | wc -l | tr -d ' ')
echo "Total segments to keep: $SEGMENT_COUNT"

# Step 4: Build ffmpeg select expression
SELECT_EXPR=$(echo "$MERGED" | awk '
{
  s = $1; e = $2
  if (NR > 1) printf "+";
  printf "between(t," s "," e ")"
}')

echo "Encoding..."

EXT=$(echo "${OUTPUT##*.}" | tr '[:upper:]' '[:lower:]')
case "$EXT" in
  webm)
    VCODEC="-c:v libvpx-vp9 -crf 33 -b:v 0"
    ACODEC="-c:a libopus -b:a 128k"
    ;;
  mp4|mov|mkv)
    VCODEC="-c:v libx264 -crf 18 -preset fast"
    ACODEC="-c:a aac -b:a 128k"
    ;;
  *)
    VCODEC="-c:v libx264 -crf 18 -preset fast"
    ACODEC="-c:a aac -b:a 128k"
    ;;
esac

ffmpeg -i "$INPUT" \
  -vf "select='${SELECT_EXPR}',setpts=N/FRAME_RATE/TB" \
  -af "aselect='${SELECT_EXPR}',asetpts=N/SR/TB" \
  $VCODEC \
  $ACODEC \
  "$OUTPUT"

rm "$SEGMENTS_FILE"
echo "Done! Output saved to: $OUTPUT"