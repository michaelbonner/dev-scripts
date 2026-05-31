#!/bin/bash
#
# commit-timelog.sh — Build a chronological work log of your commits across
# every git repo nested under the current directory, spanning all branches
# (local and remote-tracking), not just the checked-out branch.
#
# Writes ./timelog.txt with one line per commit:
#   <YYYY-MM-DD HH:MM>  <repo folder>  <one-line commit subject>
#
# Lines are sorted oldest -> newest, with a blank line separating each
# calendar date.
#
# Run from the parent folder that holds your repos (they can be nested in
# subfolders). Tweak the config block below as needed.

set -euo pipefail

# --- Config -----------------------------------------------------------------
# Regex matched (case-insensitively) against each commit's AUTHOR NAME.
# Use \| to separate alternatives. Matches across all of your git emails.
AUTHORS='Michael Bonner\|KYF'

# How far back to include commits (any `git log --since` value).
SINCE='90 days ago'

# Output file, written into the current directory.
OUTPUT='timelog.txt'
# ----------------------------------------------------------------------------

TAB=$'\t'
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# Walk every git repo under the current directory (-prune stops find from
# descending into the .git directories themselves).
while IFS= read -r gitdir; do
  repo="$(dirname "$gitdir")"
  rel="${repo#./}"

  git -C "$repo" log \
    --all \
    --no-merges \
    --author="$AUTHORS" \
    --regexp-ignore-case \
    --since="$SINCE" \
    --date=format:'%Y-%m-%d %H:%M' \
    --pretty=tformat:"%ad${TAB}${rel}${TAB}%s" \
    2>/dev/null >> "$tmp" || true
done < <(find . -name .git -type d -prune)

# Sort by the leading timestamp (lexical == chronological for this format),
# then print, inserting a blank line whenever the calendar date changes.
sort "$tmp" | awk -F"$TAB" '
  NF < 3 { next }
  {
    date = substr($1, 1, 10)
    if (printed && date != prev) print ""
    printf "%s  %s  %s\n", $1, $2, $3
    prev = date
    printed = 1
  }
' > "$OUTPUT"

count="$(grep -c . "$OUTPUT" || true)"
echo "Wrote $count commit(s) to $OUTPUT"
