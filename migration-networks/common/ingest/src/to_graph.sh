#!/usr/bin/env bash

export DATA=/data/clean
export NODEH=/data/nodes/headers
export NODEL=/data/nodes/list
export EDGEH=/data/edges/headers
export EDGEL=/data/edges/list

function printing {
    awk 'BEGIN{FS=OFS="|"}NR>1{print $'$1'}' $2
}

#### Nodes

# Countries

# cat <(printing 2 $DATA/asylum_seekers.csv) \
#     <(printing 3 $DATA/asylum_seekers.csv) \
#     <(printing 1 $DATA/asylum_seekers_monthly.csv) \
#     <(printing 2 $DATA/asylum_seekers_monthly.csv) \
#     <(printing 2 $DATA/demographics.csv) \
#     <(printing 2 $DATA/persons_of_concern.csv) \
#     <(printing 3 $DATA/persons_of_concern.csv) \
#     <(printing 1 $DATA/resettlement.csv) \
#     <(printing 2 $DATA/resettlement.csv) \
#     | sed -e '/USA/c\United States of America' \
#     | sort -u > $NODEL/countries.csv
cp $DATA/countries.csv $NODEL/countries.csv

echo "code|Country:ID|lat|lon" > $NODEH/countries.csv

# Location

cat <(printing 3 $DATA/demographics.csv) \
    <(echo "0") \
    | sed 's/||/|0|/g' | sed 's/||/|0|/g' | sed 's/*/0/g' \
    | sort -u > $NODEL/location.csv

echo "Location:ID" > $NODEH/location.csv

#### Edges

# Asylum seekers

printing '3,$2,$1,$5,$7,$10,$11,$12,$13"|SEEKERS"' $DATA/asylum_seekers.csv \
    | sed 's/||/|0|/g' | sed 's/||/|0|/g' | sed 's/*/0/g' \
    | sed -e '/USA/c\United States of America' > $EDGEL/seekers.csv

echo ":START_ID|:END_ID|Year|StartPending|Applied|Rejected|Closed|TotalDecisions|EndPending|:TYPE" > $EDGEH/seekers.csv

# Monthly seekers

printing '2,$1,$3,$4,$5"|MONTHLY"' $DATA/asylum_seekers_monthly.csv \
    | sed 's/USA (EOIR)/United States of America/g' \
    | sed 's/USA (INS\/DHS)/United States of America/g' \
    | sed 's/||/|0|/g' | sed 's/||/|0|/g' | sed 's/*/0/g' > $EDGEL/monthly.csv

echo ":START_ID|:END_ID|Year|Month|Seekers|:TYPE" > $EDGEH/monthly.csv

# Demographics

printing '2,$3,$1,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19"|DEMOGRAPHICS"' $DATA/demographics.csv \
    | sed 's/||/|0|/g' | sed 's/||/|0|/g' | sed 's/*/0/g' > $EDGEL/demo.csv

echo ":START_ID|:END_ID|Year|F(0-4)|F(5-11)|F(5-17)|F(12-17)|F(18-59)|F(60+)|F(Unknown)|F(Total)|M(0-4)|M(5-11)|M(5-17)|M(12-17)|M(18-59)|M(60+)|M(Unknown)|M(Total)|:TYPE" > $EDGEH/demo.csv

# Persons of concern

printing '3,$2,$1,$4,$5,$6,$7,$8,$9,$10,$11"|CONCERN"' $DATA/persons_of_concern.csv \
    | sed 's/||/|0|/g' | sed 's/||/|0|/g' | sed 's/*/0/g' > $EDGEL/concern.csv

echo ":START_ID|:END_ID|Year|Refugees|AsylumSeekers|Returned|IDP|ReturnedIDP|Stateless|Others|Total|:TYPE" > $EDGEH/concern.csv

# Resettlement

printing '2,$1,$3,$4"|RESETTLERS"' $DATA/resettlement.csv \
    | sed 's/||/|0|/g' | sed 's/||/|0|/g' | sed 's/*/0/g' > $EDGEL/resettlement.csv

echo ":START_ID|:END_ID|Year|Total|:TYPE" > $EDGEH/resettlement.csv

touch $EDGEL/ingest.done
