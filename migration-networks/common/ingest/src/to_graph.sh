#!/usr/bin/env zsh

export DATA=/home/ollin/Documentos/migration/data/clean
export NODEH=/home/ollin/Documentos/migration/data/nodes/headers
export NODEL=/home/ollin/Documentos/migration/data/nodes/list
export EDGEN=/home/ollin/Documentos/migration/data/edges/headers
export EDGEL=/home/ollin/Documentos/migration/data/edges/list

function printing {
    awk 'BEGIN{FS="|"}{OFS="|"}NR>1{print $'$1'}' $2
}

#### Nodes

# Countries

cat <(printing 2 $DATA/delim_asylum_seekers.csv) \
    <(printing 3 $DATA/delim_asylum_seekers.csv) \
    <(printing 1 $DATA/delim_asylum_seekers_monthly.csv) \
    <(printing 2 $DATA/delim_asylum_seekers_monthly.csv) \
    <(printing 2 $DATA/delim_demographics.csv) \
    <(printing 2 $DATA/delim_persons_of_concern.csv) \
    <(printing 3 $DATA/delim_persons_of_concern.csv) \
    <(printing 1 $DATA/delim_resettlement.csv) \
    <(printing 2 $DATA/delim_resettlement.csv) \
    | sed -e '/USA/c\United States of America' \
    | sort -u > $NODEL/countries.csv

echo "Country:ID" > $NODEH/countries.csv

# Location

cat <(printing 3 $DATA/delim_demographics.csv) \
    | sort -u > $NODEL/location.csv

echo "Location:ID" > $NODEH/location.csv

#### Edges

# Asylum seekers

printing '3,$2,$1,$5,$7,$10,$11,$12,$13"|SEEKERS"' $DATA/delim_asylum_seekers.csv \
    | sed 's/||/|0|/g' | sed 's/||/|0|/g' | sed 's/*/0/g'
    | sed -e '/USA/c\United States of America' > $EDGEL/seekers.csv

echo ":START_ID|:END_ID|Year|StartPending|Applied|Rejected|Closed|TotalDecisions|EndPending|SEEKERS:TYPE" > $EDGEH/seekers.csv

# Monthly seekers

printing '2,$1,$3,$4,$5"|MONTHLY"' $DATA/delim_asylum_seekers_monthly.csv \
    | sed 's/USA (EOIR)/United States of America/g' \
    | sed 's/USA (INS\/DHS)/United States of America/g' \
    | sed 's/||/|0|/g' | sed 's/||/|0|/g' | sed 's/*/0/g' > $EDGEL/monthly.csv

echo ":START_ID|:END_ID|Year|Month|MONTHLY:TYPE" > $EDGEH/monthly.csv







# Gender

printf "Female\nMale\n" > $NODEL/gender.csv

echo "Gender:ID" > $NODEH/gender.csv

# Age

printf "0-4\n5-11\n5-17\n12-17\n18-59\n60+\nUnknown\nTotal\n" > $NODEL/age.csv

echo "Age:ID" > $NODEH/age.csv


cat <(printing 1 $DATA/delim_asylum_seekers.csv) \
    <(printing 3 $DATA/delim_asylum_seekers_monthly.csv) \
    <(printing 1 $DATA/delim_demographics.csv) \
    <(printing 1 $DATA/delim_persons_of_concern.csv) \
    <(printing 3 $DATA/delim_resettlement.csv) \
    | sort -u > $NODEL/years.csv

echo "Year:ID" > $NODEH/years.csv

cat <(printing 4 $DATA/delim_asylum_seekers_monthly.csv) \
    | sort -u > $NODEL/months.csv

echo "Month:ID" > $NODEH/months.csv


