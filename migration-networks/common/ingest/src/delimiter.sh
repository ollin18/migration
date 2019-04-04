#!/usr/bin/env bash

# FILES=$(pwd)/migration/data/clean/
FILES=/data/clean/
rm $FILES/delim*
cd $FILES

for file in $(pwd)/*; do
    csvformat -D '|' "$(basename "$file")" > delim_"$(basename "$file" | cut -d. -f1)".csv
done
