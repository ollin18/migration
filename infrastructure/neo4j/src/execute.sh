#!/usr/bin/env bash

./create_db.sh

docker build --tag migration:0.1 --tag migration:latest .

docker run -v $(pwd)/nodes:/nodes -v $(pwd)/edges:/edges \
    --publish=7474:7474 --publish=7687:7687 \
    --volume=$HOME/data:/data \
    --volume=$HOME/neo4j/logs:/logs \
    --env=NEO4J_AUTH=none \
    --env=NEO4J_dbms_active_database="migration.db" \
    migration
