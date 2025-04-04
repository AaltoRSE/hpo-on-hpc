#!/bin/bash

LIBSQL_HOST=$(hostname -I | cut -f 1 -d ' ')
# Generate random port, user and password
LIBSQL_PORT=$(( $RANDOM + 10000))
LIBSQL_USER=$( openssl rand -hex 10 )
LIBSQL_PASSWORD=$( openssl rand -hex 10 )
LIBSQL_PASSWORD_HASH=$(echo ${LIBSQL_USER}:${LIBSQL_PASSWORD} | base64)

export SQLD_HTTP_LISTEN_ADDR=${LIBSQL_HOST}:${LIBSQL_PORT}

export SQLD_HTTP_AUTH=basic:$LIBSQL_PASSWORD_HASH

export OPTUNA_STORAGE="sqlite+libsql://${SQLD_HTTP_LISTEN_ADDR}?authToken=${LIBSQL_PASSWORD_HASH}"

module load libsql-server

sqld > logs/libsql_${SLURM_JOB_ID}.out 2>&1 &
LIBSQL_PID=$?

# Stop libsql when script ends
function shutdown_libsql() {
    echo "Shutting down libsql"
    kill -s TERM $LIBSQL_PID
}

trap shutdown_libsql EXIT

# Wait for database to fully initialize
sleep 5
