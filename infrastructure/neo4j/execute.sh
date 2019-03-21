#!/usr/bin/env bash
docker build --tag empty_neo:0.1 --tag empty_neo:latest .

docker run \
    --publish=7474:7474 --publish=7687:7687 \
    --volume=$HOME/data:/data \
    --volume=$HOME/neo4j/logs:/logs \
    --env=NEO4J_AUTH=none \
empty_neo
