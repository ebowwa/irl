#!/usr/bin/env bash

# Another segment sets variables for target directory and output file
TARGET_DIR="."
OUTPUT_FILE="output.md"

# Another segment parses command-line arguments if any
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Another segment starts writing to the markdown file
{
    echo "# Local Repository to Text Conversion"
    echo
    echo "This markdown file contains a structured representation of the local directory:"
    echo "\`$TARGET_DIR\`"
    echo
    echo "Below is a formatted listing of all Swift files and their contents:"
    echo
} > "$OUTPUT_FILE"

# Another segment finds all swift files
SWIFT_FILES=$(find "$TARGET_DIR" -type f -name "*.swift")

# Another segment loops through swift files, printing a heading and their contents
for file in $SWIFT_FILES; do
    echo "## $(basename "$file")" >> "$OUTPUT_FILE"
    echo '```swift' >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo >> "$OUTPUT_FILE"
done

# Another segment prints statistics about number of swift files
COUNT=$(echo "$SWIFT_FILES" | wc -l | awk '{print $1}')
{
    echo "## Statistics"
    echo
    echo "* Total Swift files listed: $COUNT"
} >> "$OUTPUT_FILE"

# Another segment ends here without summary or reflection
exit 0
