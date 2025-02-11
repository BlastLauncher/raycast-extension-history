#!/bin/bash
# view_extensions.sh - Interactively view and filter an extensions list with fzf.
#
# This script reads a list file (default: extensions.txt) where each line is in the format:
#   <timestamp> <extension_path>
#
# It uses a Perl one-liner to convert the Unix timestamp to a human-readable date in a single pass,
# and then pipes the results into fzf for interactive filtering.
#
# Usage:
#   ./view_extensions.sh [list_file]
#
# If [list_file] is not provided, "extensions.txt" is used.

# Check if fzf is installed.
if ! command -v fzf >/dev/null 2>&1; then
  echo "Error: fzf is not installed. Please install fzf to use this script." >&2
  exit 1
fi

# Use the first argument as the list file, default to "extensions.txt" if not provided.
list_file="${1:-extensions.txt}"

# Check that the specified list file exists.
if [ ! -f "$list_file" ]; then
  echo "Error: '$list_file' not found. Please generate the file first." >&2
  exit 1
fi

# Create a temporary file to store the formatted output.
formatted_list=$(mktemp)

# Use a Perl one-liner to process the list file.
# It reads each line (format: "<timestamp> <extension_path>"), converts the timestamp using localtime,
# and prints a formatted line "[YYYY-MM-DD HH:MM:SS] <extension_path>".
perl -MPOSIX=strftime -e '
  while (<>) {
    chomp;
    my ($ts, $rest) = split(/\s+/, $_, 2);
    print "[" . strftime("%Y-%m-%d %H:%M:%S", localtime($ts)) . "] $rest\n";
  }
' "$list_file" > "$formatted_list"

# Pipe the formatted output into fzf for interactive filtering.
selected=$(fzf --prompt="Select an extension: " < "$formatted_list")

if [ -n "$selected" ]; then
  echo "You selected: $selected"
else
  echo "No extension selected."
fi

# Clean up the temporary file.
rm "$formatted_list"