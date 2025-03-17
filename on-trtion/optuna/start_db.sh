#!/bin/bash
# Load Apptainer (Singularity)
module load apptainer-postgres/16

# Configuration
POSTGRES_PORT=5432  # Default PostgreSQL port
HPC_SUBNET="10.30.0.0/16"  # HPC network range

# Create required directories
mkdir -p ~/postgres_data ~/postgres_run

# Initialize database if not exists
if [ ! -d ~/postgres_data/PG_16_202307181 ]; then
    echo "Initializing database..."
    if [ "$(ls -A ~/postgres_data)" ]; then
        echo "postgres_data directory is not empty. Cleaning up..."
        rm -rf ~/postgres_data/*
    fi
    if ! apptainer exec ${IMAGE_PATH} initdb -D ~/postgres_data; then
        echo "Database initialization failed" >&2
        exit 1
    fi
fi

# Get node IP
NODE_IP=$(hostname -I | awk '{print $1}')
if [ -z "$NODE_IP" ]; then
    echo "Failed to get node IP" >&2
    exit 1
fi
echo "Node IP: $NODE_IP"

# Ensure port is free
if netstat -tuln | grep -q "$POSTGRES_PORT"; then
    echo "Port $POSTGRES_PORT is already in use" >&2
    exit 1
fi

# Configure PostgreSQL network settings
echo "Configuring PostgreSQL..."
mkdir -p ~/postgres_data
cat <<EOF > ~/postgres_data/postgresql.conf
listen_addresses = '*'
port = $POSTGRES_PORT
EOF

cat <<EOF > ~/postgres_data/pg_hba.conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             $HPC_SUBNET            md5
EOF

# Start PostgreSQL server inside Apptainer
if ! apptainer instance start --bind ~/postgres_data:/var/lib/postgresql/data \
  --bind ~/postgres_run:/var/run/postgresql ${IMAGE_PATH} postgres_server; then
    echo "Failed to start PostgreSQL server" >&2
    exit 1
fi

# Check server logs for errors
echo "Checking PostgreSQL logs for errors..."
apptainer exec instance://postgres_server cat /var/lib/postgresql/data/log/*.log 2>/dev/null

# Wait for server to be ready (up to 60 seconds)
MAX_WAIT=60
WAITED=0
while ! apptainer exec instance://postgres_server pg_isready -q; do
    sleep 1
    WAITED=$((WAITED + 1))
    if [ $WAITED -ge $MAX_WAIT ]; then
        echo "PostgreSQL server failed to start within $MAX_WAIT seconds" >&2
        echo "Last status:"
        apptainer exec instance://postgres_server pg_ctl status -D /var/lib/postgresql/data
        exit 1
    fi
    if [ $((WAITED % 5)) -eq 0 ]; then
        echo "Waiting for PostgreSQL to start... ($WAITED seconds)"
    fi
done
echo "PostgreSQL server is ready after $WAITED seconds"

# Check if postgres user exists
if ! apptainer exec instance://postgres_server psql -U postgres -c "\du" >/dev/null 2>&1; then
    echo "Creating postgres user..."
    apptainer exec instance://postgres_server createuser -s postgres || {
        echo "Failed to create postgres user" >&2
        exit 1
    }
fi

# Configure PostgreSQL to allow connections from all compute nodes
apptainer exec instance://postgres_server bash -c "
  echo \"listen_addresses = '*'\" >> /var/lib/postgresql/data/postgresql.conf || exit 1
  echo \"host    all             all             $HPC_SUBNET            md5\" >> /var/lib/postgresql/data/pg_hba.conf || exit 1
"
if [ $? -ne 0 ]; then
    echo "Failed to configure PostgreSQL" >&2
    exit 1
fi

# Restart PostgreSQL inside the container
apptainer exec instance://postgres_server pg_ctl -D /var/lib/postgresql/data restart

# Create and configure Optuna database
apptainer exec instance://postgres_server psql -U postgres -c "CREATE USER optuna_user WITH PASSWORD 'optuna_password';"
apptainer exec instance://postgres_server psql -U postgres -c "ALTER USER optuna_user WITH SUPERUSER;"
apptainer exec instance://postgres_server psql -U postgres -c "CREATE DATABASE optuna_db OWNER optuna_user;"

echo "PostgreSQL server ready at $NODE_IP:$POSTGRES_PORT"

# Export connection details for Optuna
export PGUSER=optuna_user
export PGPASSWORD=optuna_password
export PGHOST=${NODE_IP}
export PGPORT=${POSTGRES_PORT}
export PGDATABASE=optuna_db
export OPTUNA_STORAGE="postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
