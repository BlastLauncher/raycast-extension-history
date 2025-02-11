#!/bin/bash
# generate_extensions.sh (Parallelized Version with Verbose Logging)
#
# This script generates a sorted list (by first commit timestamp) of all extension directories.
# It assumes the extensions are under "extensions/extensions" if that folder exists,
# otherwise under "extensions". It uses xargs to process directories concurrently.
#
# Usage: Run this script from the root of the repository.
# It will generate (or overwrite) the file "extensions.txt".

output_file="extensions.txt"
rm -f "$output_file"

# Determine where the extensions actually reside.
if [ -d "extensions/extensions" ]; then
  EXT_DIR="extensions/extensions"
else
  EXT_DIR="extensions"
fi

echo "Scanning extensions directory: $EXT_DIR" >&2

# Count the number of extension directories.
TOTAL=$(find "$EXT_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
echo "Found $TOTAL extensions to process." >&2

# Create a temporary file for collecting the output.
temp_file=$(mktemp)

# List each extension directory, add line numbers (for progress), and process them in parallel.
find "$EXT_DIR" -mindepth 1 -maxdepth 1 -type d | sort | nl -w1 -s' ' | \
xargs -L 1 -P 8 bash -c '
  # The first argument is the index and the second is the extension directory.
  index="$1"
  ext="$2"
  echo "[$index/'"$TOTAL"'] Processing extension: $ext" >&2
  # Get the first commit timestamp for this extension.
  commit=$(git log --diff-filter=A --reverse --format="%at" -- "$ext" | head -n 1)
  if [ -z "$commit" ]; then
    echo "[$index/'"$TOTAL"'] No commit found for $ext" >&2
  else
    echo "$commit $ext"
  fi
' _ >> "$temp_file"

# Sort the results numerically by timestamp and write to the output file.
sort -n "$temp_file" -o "$output_file"
rm "$temp_file"

echo "Finished processing. Generated $output_file." >&2
