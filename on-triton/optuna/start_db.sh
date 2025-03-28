#!/bin/bash
# Load Apptainer (Singularity)
module load apptainer-postgres/16

# Configuration
POSTGRES_PORT=5432  # Default PostgreSQL port
HPC_SUBNET="10.30.0.0/16"  # HPC network range
DATA_DIR=~/postgres_data
RUN_DIR=~/postgres_run

# Initialize database
initialize_db() {
    if [ ! -d "$DATA_DIR/PG_16_202307181" ]; then
        echo "Initializing database..."
        if [ "$(ls -A $DATA_DIR)" ]; then
            echo "Existing data found in $DATA_DIR"
            echo "Attempting to use existing database..."
            return 0
        fi
        if ! apptainer exec ${IMAGE_PATH} initdb -D $DATA_DIR; then
            echo "Database initialization failed" >&2
            exit 1
        fi
    fi
}

# Get network configuration
get_network_config() {
    NODE_IP=$(hostname -I | awk '{print $1}')
    if [ -z "$NODE_IP" ]; then
        echo "Failed to get node IP" >&2
        exit 1
    fi
    echo "Node IP: $NODE_IP"

    # Find available port starting from 5432
    while netstat -tuln | grep -q ":$POSTGRES_PORT "; do
        echo "Port $POSTGRES_PORT is in use, trying next port..."
        POSTGRES_PORT=$((POSTGRES_PORT + 1))
    done
    echo "Using port: $POSTGRES_PORT"
}

# Configure PostgreSQL
configure_postgres() {
    echo "Configuring PostgreSQL..."
    mkdir -p $DATA_DIR
    cat <<EOF > $DATA_DIR/postgresql.conf
listen_addresses = '*'
port = $POSTGRES_PORT
EOF

    cat <<EOF > $DATA_DIR/pg_hba.conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             $HPC_SUBNET            md5
EOF
}

# Start PostgreSQL server
start_postgres() {
    # Create run directory if it doesn't exist
    mkdir -p $RUN_DIR
    
    if ! apptainer instance start --bind $DATA_DIR:/var/lib/postgresql/data \
      --bind $RUN_DIR:/var/run/postgresql ${IMAGE_PATH} postgres_server; then
        echo "Failed to start PostgreSQL server" >&2
        exit 1
    fi

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
}

# Check if postgres user exists
check_postgres_user() {
    if ! apptainer exec instance://postgres_server psql -U postgres -c "\du" >/dev/null 2>&1; then
        echo "Creating postgres user..."
        apptainer exec instance://postgres_server createuser -s postgres || {
            echo "Failed to create postgres user" >&2
            exit 1
        }
    fi
}

# Configure PostgreSQL to allow connections from all compute nodes
configure_postgres_for_all_nodes() {
    apptainer exec instance://postgres_server bash -c "
      echo \"listen_addresses = '*'\" >> /var/lib/postgresql/data/postgresql.conf || exit 1
      echo \"host    all             all             $HPC_SUBNET            md5\" >> /var/lib/postgresql/data/pg_hba.conf || exit 1
    "
    if [ $? -ne 0 ]; then
        echo "Failed to configure PostgreSQL" >&2
        exit 1
    fi
}

# Restart PostgreSQL inside the container
restart_postgres() {
    apptainer exec instance://postgres_server pg_ctl -D /var/lib/postgresql/data restart
}

# Create and configure Optuna database
create_optuna_database() {
    # Check if user exists before creating
    if ! apptainer exec instance://postgres_server psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='optuna_user'" | grep -q 1; then
        apptainer exec instance://postgres_server psql -U postgres -c "CREATE USER optuna_user WITH PASSWORD 'optuna_password';"
    else
        echo "User optuna_user already exists"
    fi
    
    # Grant superuser privileges (in case they were lost)
    apptainer exec instance://postgres_server psql -U postgres -c "ALTER USER optuna_user WITH SUPERUSER;"
    
    # Check if database exists before creating
    if ! apptainer exec instance://postgres_server psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='optuna_db'" | grep -q 1; then
        apptainer exec instance://postgres_server psql -U postgres -c "CREATE DATABASE optuna_db OWNER optuna_user;"
    else
        echo "Database optuna_db already exists"
    fi
}

# Export connection details for Optuna
export_optuna_connection() {
    export PGUSER=optuna_user
    export PGPASSWORD=optuna_password
    export PGHOST=${NODE_IP}
    export PGPORT=${POSTGRES_PORT}
    export PGDATABASE=optuna_db
    export OPTUNA_STORAGE="postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
}

# Main execution
initialize_db
get_network_config
configure_postgres
start_postgres
check_postgres_user
configure_postgres_for_all_nodes
restart_postgres
create_optuna_database
export_optuna_connection

echo "PostgreSQL server ready at $NODE_IP:$POSTGRES_PORT"
