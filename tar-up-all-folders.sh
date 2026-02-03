#!/bin/bash

# Loop through all directories in the current directory
for dir in */; do
  # Remove the trailing slash from the directory name
  dir_name="${dir%/}"

  # Check if it's actually a directory
  if [ -d "$dir_name" ]; then
    # Create the tar file
    tar -czvf "${dir_name}.tar.gz" "$dir_name"

    # Check if the tar command was successful
    if [ $? -eq 0 ]; then
      echo "Successfully created ${dir_name}.tar.gz"
    else
      echo "Failed to create ${dir_name}.tar.gz"
    fi
  fi
done

echo "Tar process completed."
