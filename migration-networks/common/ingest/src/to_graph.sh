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

awk 'BEGIN{FS=OFS="|"}{print $1,$4,$2,$3}' $DATA/countries_gdp.csv > $NODEL/countries.csv
echo "Country:ID|Code|lat:float|lon:float" > $NODEH/countries.csv

# Years

awk 'BEGIN{FS=OFS="|"}{print $2}'  $DATA/gdp.csv | sort -u > $NODEL/years.csv
echo "Year:ID" > $NODEH/years.csv

# Wanna test if gdp and pop Countries are identical?
# cmp --silent <(printing '1,$2,$3' $DATA/countries_gdp.csv) <(printing '1,$2,$3' $DATA/countries_pop.csv) && echo 'identical'

# Location

cat <(printing 3 $DATA/demographics.csv) \
    <(echo "0") \
    | sed 's/||/|0|/g' | sed 's/||/|0|/g' | sed 's/*/0/g' \
    | sort -u > $NODEL/location.csv

echo "Location:ID" > $NODEH/location.csv

#### Edges

# Population

awk 'BEGIN{FS=OFS="|"}{print $1,$2,$3"|POPULATION"}' $DATA/population.csv > $EDGEL/population.csv
echo ":START_ID|:END_ID|population:int|:TYPE" > $EDGEH/population.csv

# GDP

awk 'BEGIN{FS=OFS="|"}{print $1,$2,$3"|GDP"}' $DATA/gdp.csv > $EDGEL/gdp.csv
echo ":START_ID|:END_ID|gdp:float|:TYPE" > $EDGEH/gdp.csv

# Asylum seekers

printing '3,$2,$1,$5,$7,$10,$11,$12,$13"|SEEKERS"' $DATA/asylum_seekers.csv \
    | sed 's/||/|0|/g' | sed 's/||/|0|/g' | sed 's/*/0/g' \
    | sed -e '/USA/c\United States of America' > $EDGEL/seekers.csv

echo ":START_ID|:END_ID|Year|StartPending:int|Applied:int|Rejected:int|Closed:int|TotalDecisions:int|EndPending:int|:TYPE" > $EDGEH/seekers.csv

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

echo ":START_ID|:END_ID|Year|Refugees:float|AsylumSeekers:float|Returned:float|IDP:float|ReturnedIDP:float|Stateless:float|Others:float|Total:float|:TYPE" > $EDGEH/concern.csv

# Resettlement

printing '2,$1,$3,$4"|RESETTLERS"' $DATA/resettlement.csv \
    | sed 's/||/|0|/g' | sed 's/||/|0|/g' | sed 's/*/0/g' > $EDGEL/resettlement.csv

echo ":START_ID|:END_ID|Year|Total:int|:TYPE" > $EDGEH/resettlement.csv

touch $EDGEL/ingest.done
