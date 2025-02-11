#!/bin/bash
# view_extensions.sh - Interactively view and filter an extensions list with fzf.
#
# This script reads an extensions list where each line is in the format:
#   <timestamp> <extension_path>
#
# If a filename is given as the first argument, that file is used.
# Otherwise, the script downloads the latest list from:
# https://github.com/BlastLauncher/raycast-extension-history/raw/refs/heads/extensions-list/extensions.txt
#
# The script uses a Perl one-liner (via POSIX::strftime) to convert the Unix
# timestamp to a human-readable date in a single pass, then pipes the results
# into fzf for interactive filtering.
#
# Usage:
#   ./view_extensions.sh [list_file]
#
# If [list_file] is not provided, the latest list is downloaded.

# Ensure fzf is installed.
if ! command -v fzf >/dev/null 2>&1; then
  echo "Error: fzf is not installed. Please install fzf to use this script." >&2
  exit 1
fi

# If a file is provided as an argument, use it. Otherwise, download from URL.
if [ -z "$1" ]; then
  echo "No filename provided. Downloading the latest extension list..." >&2
  list_file=$(mktemp)
  curl -sSL "https://rawcdn.githack.com/BlastLauncher/raycast-extension-history/refs/heads/extensions-list/extensions.txt" -o "$list_file"
  if [ ! -s "$list_file" ]; then
    echo "Error: Failed to download extension list." >&2
    exit 1
  fi
  downloaded=1
else
  list_file="$1"
  if [ ! -f "$list_file" ]; then
    echo "Error: File '$list_file' not found." >&2
    exit 1
  fi
  downloaded=0
fi

# Create a temporary file to store the formatted output.
formatted_list=$(mktemp)

# Use a Perl one-liner to convert the timestamp to a human-readable date.
# Each line is expected to be "<timestamp> <extension_path>".
perl -MPOSIX=strftime -e '
  while (<>) {
    chomp;
    my ($ts, $rest) = split(/\s+/, $_, 2);
    print "[" . strftime("%Y-%m-%d %H:%M:%S", localtime($ts)) . "] $rest\n";
  }
' "$list_file" > "$formatted_list"

# Launch fzf for interactive filtering.
selected=$(fzf --prompt="Select an extension: " < "$formatted_list")

if [ -n "$selected" ]; then
  echo "You selected: $selected"
else
  echo "No extension selected."
fi

# Clean up temporary files.
rm "$formatted_list"
[ "$downloaded" -eq 1 ] && rm "$list_file"
