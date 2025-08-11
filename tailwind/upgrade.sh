#!/bin/bash

# Check if class file was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: ./upgrade.sh v1-to-v2"
    exit 1
fi

class_file=$1

# Get the project root directory (where the script is being run from)
project_root="$(pwd)"

# Create log directory if it doesn't exist
log_dir="./helpers/log"
mkdir -p "$log_dir"
log_file="$log_dir/upgrade.log"

# Initialize log file with timestamp
echo "=== Tailwind Upgrade Log - $(date) ===" > "$log_file"
echo "Class mapping file: $class_file" >> "$log_file"
echo "Project root: $project_root" >> "$log_file"
echo "" >> "$log_file"

# List of directories to scan
dirs="./src ./templates"

# File types to scan in the src directory
types="css sass scss pcss"

while read -r line
do
    old_class=$(echo $line | cut -d ' ' -f 1)
    new_class=$(echo $line | cut -d ' ' -f 2)

    echo "Replacing $old_class with $new_class"
    echo "Replacing $old_class with $new_class" >> "$log_file"

    for dir in $dirs
    do
        if [ -d "$dir" ]
        then
            echo "Processing $dir"
            echo "Processing $dir" >> "$log_file"
            # Differentiate between ./src and ./templates
            if [ "$dir" == "./src" ]
            then
                for type in $types
                do
                    echo "Looking for $type files"
                    echo "Looking for $type files" >> "$log_file"
                    # Find all files of the specific type in the directory
                    files=$(find $dir -name "*.$type" -print0 | xargs -0 grep -l "$old_class")
                    for file in $files
                    do
                        echo "Updating $file"
                        echo "Updating $file" >> "$log_file"
                        # Use sed to replace old_class with new_class
                        sed -i '' "s/$old_class/$new_class/g" "$file"
                        echo "  - Replaced $old_class with $new_class in $file" >> "$log_file"
                    done
                done
            else
                files=$(grep -rl "$old_class" $dir)
                for file in $files
                do
                    echo "Updating $file"
                    echo "Updating $file" >> "$log_file"
                    # Use sed to replace old_class with new_class
                    sed -i '' "s/$old_class/$new_class/g" "$file"
                    echo "  - Replaced $old_class with $new_class in $file" >> "$log_file"
                done
            fi
        else
            echo "$dir doesn't exist"
            echo "$dir doesn't exist" >> "$log_file"
        fi
    done

done < "$class_file"

echo "Upgrade completed. Log saved to: $log_file"
echo "Upgrade completed at $(date)" >> "$log_file"
