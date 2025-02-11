#!/bin/bash
# generate_extensions.sh
# This script generates an extensions.txt file that lists each extension’s
# first appearance time (using the commit timestamp) in ascending order.
#
# It is intended to be run from the root of the cloned repository.
# If the repository structure has an "extensions/extensions" folder, that folder is used;
# otherwise it falls back to "extensions".

output_file="extensions.txt"
# Clear any previous output
> "$output_file"

# Determine which folder contains the extension directories.
if [ -d "extensions/extensions" ]; then
  EXT_DIR="extensions/extensions"
else
  EXT_DIR="extensions"
fi

# Loop over each subdirectory (each extension) and get the timestamp
for ext in "$EXT_DIR"/*; do
  if [ -d "$ext" ]; then
    # Look for the first commit that added a file in this extension.
    first_commit_date=$(git log --diff-filter=A --reverse --format="%at" -- "$ext" | head -n 1)
    echo "$first_commit_date $ext" >> "$output_file"
  fi
done

# Sort the file numerically (by Unix timestamp) in place.
sort -n "$output_file" -o "$output_file"