#!/bin/bash

update_background="./vendor/astuteo/astuteo-sh-scripts/tailwind/enhance/v3/background-opacity.sh"

# Get the project root directory (where the script is being run from)
project_root="$(pwd)"

# Create log directory if it doesn't exist
log_dir="./helpers/log"
mkdir -p "$log_dir"
log_file="$log_dir/enhance.log"

# Initialize log file with timestamp
echo "=== Tailwind Enhancement Log - $(date) ===" > "$log_file"
echo "Project root: $project_root" >> "$log_file"
echo "" >> "$log_file"

# Directories to scan
dirs="./src ./templates"

for dir in $dirs
do
    if [ -d "$dir" ]
    then
        echo "Processing $dir"
        echo "Processing $dir" >> "$log_file"
        # Find all css, sass, and pcss files in the directory
        files=$(find $dir -type f \( -iname \*.twig -o -iname \*.html -o -iname \*.css -o -iname \*.sass -o -iname \*.pcss \))
        for file in $files
        do
            echo "Enhancing $file" >> "$log_file"
            # Use perl to replace old_class with new_class using regex
            $update_background "$file"
            echo "  - Enhanced $file" >> "$log_file"
        done
    else
        echo "$dir doesn't exist"
        echo "$dir doesn't exist" >> "$log_file"
    fi
done

echo "Enhancement completed. Log saved to: $log_file"
echo "Enhancement completed at $(date)" >> "$log_file"
