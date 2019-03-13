#!/usr/bin/env bash

FILES=/home/ollin/Documentos/migration/data/clean/
cd $FILES
rm $FILES/delim*

for file in $(pwd)/*; do
    csvformat -D '|' "$(basename "$file")" > delim_"$(basename "$file" | cut -d. -f1)".csv
done
