#!/bin/bash
# generate_extensions.sh (Parallelized Version)
# This script generates a sorted list of extensions with their first commit timestamps,
# running multiple git log commands concurrently.
#
# It assumes the extensions are in "extensions/extensions" if that folder exists,
# otherwise in "extensions".

output_file="extensions.txt"
rm -f "$output_file"

if [ -d "extensions/extensions" ]; then
  EXT_DIR="extensions/extensions"
else
  EXT_DIR="extensions"
fi

# Create a temporary file to hold intermediate results.
temp_file=$(mktemp)

# Find each extension directory (one level deep) and process them in parallel.
find "$EXT_DIR" -mindepth 1 -maxdepth 1 -type d | sort | \
  xargs -I {} -P 8 bash -c '
    ext="{}"
    first_commit=$(git log --diff-filter=A --reverse --format="%at" -- "$ext" | head -n 1)
    # Print the result; if no commit is found, first_commit will be empty.
    echo "$first_commit $ext"
  ' >> "$temp_file"

# Sort the results numerically by timestamp and output to the final file.
sort -n "$temp_file" -o "$output_file"
rm "$temp_file"
