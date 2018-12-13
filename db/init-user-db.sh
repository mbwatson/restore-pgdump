#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER root;
    GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO root;
EOSQL

psql $POSTGRES_DB < /data/dump.sql
