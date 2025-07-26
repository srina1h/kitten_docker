#!/bin/bash

# Startup script for kitten docker container
set -e

echo "Starting kitten docker container..."

# Check if seeds directory exists and has files
if [ ! -d "/perses/seeds" ] || [ -z "$(ls -A /perses/seeds 2>/dev/null)" ]; then
    echo "Seeds directory is empty or doesn't exist. Running prepare_seeds.sh..."
    cd /perses
    
    # Run prepare_seeds with timeout and error handling
    if timeout 900 ./prepare_seeds.sh; then
        echo "Successfully prepared seeds!"
        echo "Number of seed files: $(find /perses/seeds -name "*.js" | wc -l)"
    else
        echo "Warning: prepare_seeds.sh failed or timed out. Container will continue without seeds."
        echo "You can manually run './prepare_seeds.sh' inside the container if needed."
    fi
else
    echo "Seeds directory already exists with $(find /perses/seeds -name "*.js" | wc -l) files."
fi

echo "Container startup complete. Starting bash..."
exec /bin/bash 