#!/bin/bash
#
# timelog-by-project.sh — Chunk a timelog.txt (see commit-timelog.sh) into
# billable projects using a folder→project key file.
#
# Output (default ./timelog-by-project.txt) keeps the exact same commit line
# format as the input, but groups commits by day (newest first), and within
# each day by project (alphabetically):
#
#   ===== 2026-05-30 =====
#
#   Willow Creek App
#   2026-05-30 13:33  blackthorn-software/crewview-rn  Update i18n count
#   2026-05-30 13:25  blackthorn-software/crewview-rn  fix: PR feedback
#
#   WWC Manager
#   2026-05-30 12:31  wasatch/wwc-manager  ...
#
# Within each day, repos in no key are grouped under "Unmatched" and repos
# listed as "ignore" in the key under "Ignored" — both sorted last so nothing
# billable slips through unnoticed.
#
# Key file format (see timelog-projects-key.txt):
#   # comments and blank lines are ignored
#   folder-name : Project Name
#   other-folder : ignore
# A key matches a repo when the key's folder string appears (case-insensitively,
# ignoring hyphens) anywhere in the repo's leaf folder name — so
# `denverwindowwellcovers` matches `wasatch/denverwindowwellcovers-astro` and
# `crew-view` matches `crewview-rn`. When several keys match, the longest (most
# specific) wins.

set -euo pipefail

# --- Config -----------------------------------------------------------------
INPUT='timelog.txt'                  # produced by commit-timelog.sh
KEY='timelog-projects-key.txt'       # folder → project mapping
OUTPUT='timelog-by-project.txt'
# ----------------------------------------------------------------------------

if [[ ! -f "$INPUT" ]]; then
  echo "Input not found: $INPUT (run commit-timelog.sh first)" >&2
  exit 1
fi
if [[ ! -f "$KEY" ]]; then
  echo "Key file not found: $KEY" >&2
  exit 1
fi

TAB=$'\t'

# Stage 1: tag every commit line with its project (and a sort key), dropping
# ignored repos. Emits:  <sortkey>\t<project>\t<original line>
awk '
  # --- key file (read first) ---
  FNR == NR {
    line = $0
    sub(/\r$/, "", line)
    if (line ~ /^[[:space:]]*#/ || line ~ /^[[:space:]]*$/) next
    ci = index(line, ":")            # split on the FIRST colon only
    if (ci == 0) next
    folder = substr(line, 1, ci - 1)
    proj   = substr(line, ci + 1)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", folder)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", proj)
    if (folder == "") next
    nkeys++
    kfolder = tolower(folder); gsub(/-/, "", kfolder)   # hyphen-insensitive
    kf[nkeys] = kfolder
    kp[nkeys] = (tolower(proj) == "ignore") ? "@IGNORE" : proj
    next
  }

  # --- timelog file ---
  length($0) < 19 { next }           # skips blank date-separator lines too
  {
    date = substr($0, 1, 10)         # commit line is fixed-width: 16-char
    rest = substr($0, 19)            # timestamp + 2 spaces, then repo path
    di = index(rest, "  ")
    repo = (di > 0) ? substr(rest, 1, di - 1) : rest
    n = split(repo, parts, "/")
    leaf = tolower(parts[n]); gsub(/-/, "", leaf)       # hyphen-insensitive

    bestlen = 0; bestproj = ""
    for (i = 1; i <= nkeys; i++) {
      if (index(leaf, kf[i]) > 0 && length(kf[i]) > bestlen) {
        bestlen = length(kf[i]); bestproj = kp[i]
      }
    }
    # fields: date \t project-sort-key \t commit line \t display project
    if (bestlen > 0 && bestproj == "@IGNORE")
         { print date "\t~~~~ Ignored\t"  $0 "\tIgnored" }   # Ignored sorts last
    else if (bestlen == 0)
         { print date "\t~~~ Unmatched\t" $0 "\tUnmatched" }
    else { print date "\t" bestproj "\t"  $0 "\t" bestproj }
  }
' "$KEY" "$INPUT" \
| LC_ALL=C sort -t"$TAB" -k1,1r -k2,2 -k3,3r \
| awk -F"$TAB" '
    BEGIN { print "Timelog grouped by day, then project"; print "" }
    {
      date = $1; line = $3; proj = $4
      if (date != curdate) {
        if (printed) print ""
        print "===== " date " ====="
        print ""
        print proj
        curdate = date; curproj = proj; printed = 1
      } else if (proj != curproj) {
        print ""
        print proj
        curproj = proj
      }
      print line
    }
  ' > "$OUTPUT"

days="$(grep -c '^===== ' "$OUTPUT" || true)"
commits="$(grep -c '^[0-9]\{4\}-' "$OUTPUT" || true)"
echo "Wrote $commits commit(s) across $days day(s) to $OUTPUT"
