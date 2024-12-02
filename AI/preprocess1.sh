#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

BASE_DIR=$1
SOURCE_PATH="./data/$BASE_DIR/sourcecode/"
BYTECODE_PATH="./data/$BASE_DIR/bytecode/"
BINARYCODE_PATH="./data/$BASE_DIR/binarycode/"

if [ ! -d "$SOURCE_PATH" ]; then
    echo "Error: Source directory $SOURCE_PATH does not exist."
    exit 1
fi

mkdir -p "$BYTECODE_PATH"
mkdir -p "$BINARYCODE_PATH"

files=$(ls $SOURCE_PATH)
for file in $files; do
    version=$(grep -oP 'pragma solidity \^\K[0-9]+\.[0-9]+\.[0-9]+' "$SOURCE_PATH$file")

    if [ -z "$version" ]; then
        echo "No pragma version found in $file. Skipping..."
        continue
    fi

    echo "Compiling $file with solc version $version..."

    solc-select use "$version" || {
        echo "Version $version not installed. Installing..."
        solc-select install "$version" && solc-select use "$version"
    }

    cp "$SOURCE_PATH$file" "$BINARYCODE_PATH$file"

    solc --bin "$SOURCE_PATH$file" | tee -a "$BYTECODE_PATH$file"

    slither "$BINARYCODE_PATH$file" --print cfg
    rm -f "$BINARYCODE_PATH$file"

    base_name=$(basename "$file" .sol)

    echo "digraph G {" > "$BINARYCODE_PATH$base_name".dot
    for dot_file in "$BINARYCODE_PATH$file"*.dot; do
        function_name=$(basename "$dot_file" .dot)
        echo "// Function: $function_name" >> "$BINARYCODE_PATH$base_name".dot
        cat "$dot_file" >> "$BINARYCODE_PATH$base_name".dot
        rm -f "$dot_file"
    done
    echo "}" >> "$BINARYCODE_PATH$base_name".dot

done