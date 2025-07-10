#!/bin/bash

# Read path
search_dir="docs"
l1_folders=($(find "$search_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))

# echo "Write the title of the doc:"
# read title

echo "select the path to store the hackmd:"
filtered_folders=()
num=1
for dir in "${l1_folders[@]}"; do
    if [ "$dir" == "img" ]; then
        continue
    fi
    filtered_folders+=("$dir")
    echo "$num) $dir"
    num=$((num+1))
done
read l1
echo "You selected: ${filtered_folders[$l1-1]}"

search_dir="$search_dir/${filtered_folders[$l1-1]}"
l2_folders=($(find "$search_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))
num=1
for dir in "${l2_folders[@]}"; do
    echo "$num) $dir"
    num=$((num+1))
done
read l2
echo "You selected: ${l2_folders[$l2-1]}"

echo "Introduce hackmd Hash you want to add to mkdocs (example: https://hackmd.io/ -> U-g08FgHTLaY3SvSlmbIRQ <- ):"
read hash
# hash="${hackMDURL##*/}"
echo "HackMD hash: $hash"
curl "https://hackmd.io/$hash/download" > "$search_dir/${l2_folders[$l2-1]}/$hash.md"
echo "HackMD $hash added to mkdocs $search_dir/${l2_folders[$l2-1]}/$hash.md"