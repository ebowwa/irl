#!/usr/bin/env bash

set -euo pipefail

OUTPUT_FILE="file_relationships.mmd"
TEMP_REL=$(mktemp)

echo "graph TD" > "$OUTPUT_FILE"

extract_relationships() {
    local file="$1"
    local filename
    filename=$(basename "$file" .swift)

    # Expanded patterns to capture:
    # - Imports: import.*$filename
    # - Class inheritance: class.*:.*$filename
    # - Struct inheritance: struct.*:.*$filename
    # - Enum inheritance: enum.*:.*$filename
    # - Protocol inheritance: protocol.*:.*$filename
    # - Direct usage references: $filename\. for property/method calls
    # - Instantiation: $filename\( to detect direct object creation
    # - Spaces following filename: $filename\s to catch references in type annotations, function params
    # Combined into one grep command to reduce overhead.

    find . -name "*.swift" -type f | while read -r other_file; do
        if [[ "$other_file" != "$file" ]]; then
            if grep -Eq "import.*$filename|class.*:.*$filename|struct.*:.*$filename|enum.*:.*$filename|protocol.*:.*$filename|$filename\.|$filename\(|$filename " "$other_file"; then
                local other_filename
                other_filename=$(basename "$other_file" .swift)
                echo "    $other_filename --> $filename" >> "$TEMP_REL"
            fi
        fi
    done
}

find . -name "*.swift" -type f | while read -r swift_file; do
    extract_relationships "$swift_file"
done

sort -u "$TEMP_REL" >> "$OUTPUT_FILE"
rm "$TEMP_REL"

echo "Mermaid chart generated in $OUTPUT_FILE"
