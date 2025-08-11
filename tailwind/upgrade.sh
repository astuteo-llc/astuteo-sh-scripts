#!/bin/bash

# Check if class file was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: ./upgrade.sh v1-to-v2"
    exit 1
fi

class_file=$1
project_root="$(pwd)"

log_dir="./helpers/log"
mkdir -p "$log_dir"
log_file="$log_dir/upgrade.log"

echo "=== Tailwind Upgrade Log - $(date) ===" > "$log_file"
echo "Class mapping file: $class_file" >> "$log_file"
echo "Project root: $project_root" >> "$log_file"
echo "" >> "$log_file"

dirs="./src ./templates"
types="css sass scss pcss"

while IFS= read -r line; do
    # Skip empty lines or comments (allow leading whitespace)
    if [[ -z "${line//[[:space:]]/}" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi

    # old is first token; new is the REST (supports multi-word replacements)
    old_class=$(echo "$line" | awk '{print $1}')
    new_class=$(echo "$line" | cut -d' ' -f2-)

    if [ -z "$old_class" ]; then
        echo "Skipping malformed mapping line: '$line'" >> "$log_file"
        continue
    fi

    # Trim trailing spaces from new_class (just in case)
    new_class=$(echo "$new_class" | sed 's/[[:space:]]*$//')

    if [ -z "$new_class" ]; then
        echo "Deleting occurrences of: $old_class"
        echo "Deleting occurrences of: $old_class" >> "$log_file"
    else
        echo "Replacing $old_class with $new_class"
        echo "Replacing $old_class with $new_class" >> "$log_file"
    fi

    for dir in $dirs; do
        if [ -d "$dir" ]; then
            echo "Processing $dir"
            echo "Processing $dir" >> "$log_file"

            if [ "$dir" == "./src" ]; then
                for type in $types; do
                    echo "Looking for *.$type files"
                    echo "Looking for *.$type files" >> "$log_file"

                    # Find files of given type that contain the pattern (extended regex)
                    files=$(find "$dir" -name "*.$type" -print0 | xargs -0 grep -El -E "$old_class")
                    for file in $files; do
                        echo "Updating $file"
                        echo "Updating $file" >> "$log_file"

                        if [ "$old_class" = "rounded" ]; then
                            # Only replace standalone "rounded" tokens (not "rounded-*")
                            if [ -z "$new_class" ]; then
                                sed -E -i '' "s/(^|[^A-Za-z0-9-])rounded([^A-Za-z0-9-]|$)/\1\2/g" "$file"
                                echo "  - Deleted '$old_class' in $file" >> "$log_file"
                            else
                                sed -E -i '' "s/(^|[^A-Za-z0-9-])rounded([^A-Za-z0-9-]|$)/\1${new_class}\2/g" "$file"
                                echo "  - Replaced $old_class with $new_class in $file" >> "$log_file"
                            fi
                        else
                            if [ -z "$new_class" ]; then
                                sed -E -i '' "s/$old_class//g" "$file"
                                echo "  - Deleted '$old_class' in $file" >> "$log_file"
                            else
                                sed -E -i '' "s/$old_class/$new_class/g" "$file"
                                echo "  - Replaced $old_class with $new_class in $file" >> "$log_file"
                            fi
                        fi
                    done
                done
            else
                # ./templates — check all files (extended regex)
                files=$(grep -rEl -E "$old_class" "$dir")
                for file in $files; do
                    echo "Updating $file"
                    echo "Updating $file" >> "$log_file"

                    if [ "$old_class" = "rounded" ]; then
                        if [ -z "$new_class" ]; then
                            sed -E -i '' "s/(^|[^A-Za-z0-9-])rounded([^A-Za-z0-9-]|$)/\1\2/g" "$file"
                            echo "  - Deleted '$old_class' in $file" >> "$log_file"
                        else
                            sed -E -i '' "s/(^|[^A-Za-z0-9-])rounded([^A-Za-z0-9-]|$)/\1${new_class}\2/g" "$file"
                            echo "  - Replaced $old_class with $new_class in $file" >> "$log_file"
                        fi
                    else
                        if [ -z "$new_class" ]; then
                            sed -E -i '' "s/$old_class//g" "$file"
                            echo "  - Deleted '$old_class' in $file" >> "$log_file"
                        else
                            sed -E -i '' "s/$old_class/$new_class/g" "$file"
                            echo "  - Replaced $old_class with $new_class in $file" >> "$log_file"
                        fi
                    fi
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
