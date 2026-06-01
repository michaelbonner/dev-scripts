#!/bin/bash
#
# timelog-to-dropbox.sh — Build the commit timelog, group it by project, and
# stash both output files in Dropbox.
#
# Runs (in order):
#   1. commit-timelog.sh      -> timelog.txt
#   2. timelog-by-project.sh  -> timelog-by-project.txt
# then moves both outputs to ~/Dropbox/Bootpack/.
#
# Safe to run from anywhere (including cron): it cd's into REPOS_ROOT first, so
# the inner scripts find the repos, the timelog-projects-key.txt, and write the
# outputs in the right place regardless of the caller's working directory.

set -euo pipefail

# cron runs with a bare PATH (/usr/bin:/bin); make sure git & friends are found.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

# The folder that holds your repos AND timelog-projects-key.txt. Override by
# exporting REPOS_ROOT before invoking.
REPOS_ROOT="${REPOS_ROOT:-$HOME/Development}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/Dropbox/Bootpack"

cd "$REPOS_ROOT"

"$SCRIPT_DIR/commit-timelog.sh"
"$SCRIPT_DIR/timelog-by-project.sh"

mkdir -p "$DEST"
mv -f timelog.txt timelog-by-project.txt "$DEST/"

echo "Moved timelog.txt and timelog-by-project.txt to $DEST"
