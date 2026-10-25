#!/bin/bash

# Usage: ./raspored.sh [prilog.txt]
# prilog.txt: one file name per line

LIST="${1:-prilog.txt}"
PATTERN='^k[0-9a-fA-F]{8}\.kod$'

if [[ ! -f "$LIST" ]]; then
    echo "List file '$LIST' not found." >&2
    exit 1
fi

# Create empty files with names from the list
while IFS= read -r name || [[ -n "$name" ]]; do
    name="${name%$'\r'}"          # strip Windows CR if present
    [[ -z "$name" ]] && continue
    touch -- "$name" 2>/dev/null || echo "Could not create: $name" >&2
done < "$LIST"

# Validate names and report invalid ones
echo "Invalid file names:"
invalid=0
valid_files=()
while IFS= read -r name || [[ -n "$name" ]]; do
    name="${name%$'\r'}"
    [[ -z "$name" ]] && continue
    if [[ "$name" =~ $PATTERN ]]; then
        valid_files+=("$name")
    else
        echo "  $name"
        invalid=$((invalid + 1))
    fi
done < "$LIST"
[[ $invalid -eq 0 ]] && echo "  (none)"

# Create subdirectories and move valid files (invalid ones are ignored)
for f in "${valid_files[@]}"; do
    hex="${f:1:8}"                # ABCDEFGH
    E="${hex:4:1}"                # 5th digit
    G="${hex:6:1}"                # 7th digit
    g=$((16#$G))

    if (( g % 2 == 0 )); then
        X="$G"
    else
        X=$(printf '%x' $((g - 1)))
    fi

    dir="${X}0/${E}0"
    mkdir -p -- "$dir"
    mv -- "$f" "$dir/"
done

echo "Done. Valid files moved: ${#valid_files[@]}, invalid ignored: $invalid"