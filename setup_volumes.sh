#!/bin/bash
# Setup script to initialize host storage directories for the 'mycloud' stack
# Usage: ./setup_volumes.sh [/path/to/base_data_dir]

set -e

# Load environment variables if .env exists
if [ -f .env ]; then
  # Load DATA_DIR from .env file
  DATA_DIR_FROM_ENV=$(grep '^DATA_DIR=' .env | cut -d '=' -f2- | tr -d '"' | tr -d "'")
fi

BASE_DIR="${1:-${DATA_DIR_FROM_ENV:-/srv/data/mycloud}}"

echo "Setting up volume directories for mycloud under: $BASE_DIR"

# Seafile directories
sudo mkdir -p "$BASE_DIR/seafile/data"
sudo mkdir -p "$BASE_DIR/seafile/mariadb"

# Immich directories
sudo mkdir -p "$BASE_DIR/immich/upload"
sudo mkdir -p "$BASE_DIR/immich/postgres"
sudo mkdir -p "$BASE_DIR/immich/models"

echo "Setting volume permissions..."
# Allow read/write access for container services
sudo chmod -R 775 "$BASE_DIR"

echo "Directories created successfully at $BASE_DIR!"
