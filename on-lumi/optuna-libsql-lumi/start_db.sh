#!/bin/bash

# Determine hostname
LIBSQL_HOST=$(hostname -I | cut -f 1 -d ' ')

# Generate random port, user and password
LIBSQL_PORT=$(( $RANDOM + 10000))
LIBSQL_USER=$( openssl rand -hex 10 )
LIBSQL_PASSWORD=$( openssl rand -hex 10 )

# Create hashed token that will be used for authentication
export LIBSQL_TOKEN=$(echo ${LIBSQL_USER}:${LIBSQL_PASSWORD} | base64)

# Set up libSQL-server's environment
export SQLD_HTTP_LISTEN_ADDR=${LIBSQL_HOST}:${LIBSQL_PORT}
export SQLD_HTTP_AUTH=basic:$LIBSQL_TOKEN

# Set Optuna connection string
export OPTUNA_STORAGE="sqlite+libsql://${SQLD_HTTP_LISTEN_ADDR}"

# Start up the server
libsql-server-x86_64-unknown-linux-gnu/sqld > logs/libsql_${SLURM_JOB_ID}.out 2>&1 &
export LIBSQL_PID=$?

# Wait for database to fully initialize
sleep 5
