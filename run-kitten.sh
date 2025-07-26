#!/bin/bash

# Run the kitten_deploy.jar file inside a Docker container
# Usage: ./run-kitten.sh <container_name> [additional-options]

if [ $# -lt 1 ]; then
    echo "Usage: $0 <container_name> [additional-options]"
    echo "Example: $0 kitten"
    exit 1
fi

CONTAINER_NAME="$1"
shift  # Remove the first argument (container name) from the argument list

# Create local directories for mounting if they don't exist
echo "Creating local directories for fuzzing output..."
mkdir -p kitten/default_finding_folder_JAVASCRIPT
mkdir -p kitten/default_interesting_folder_JAVASCRIPT
mkdir -p kitten/default_temp_folder_JAVASCRIPT

# Check if container exists
if ! docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '$CONTAINER_NAME' not found. Creating new container with volume mounts..."
    docker run -d --name "$CONTAINER_NAME" \
      -v "$(pwd)/kitten/default_finding_folder_JAVASCRIPT:/perses/kitten/default_finding_folder_JAVASCRIPT" \
      -v "$(pwd)/kitten/default_interesting_folder_JAVASCRIPT:/perses/kitten/default_interesting_folder_JAVASCRIPT" \
      -v "$(pwd)/kitten/default_temp_folder_JAVASCRIPT:/perses/kitten/default_temp_folder_JAVASCRIPT" \
      kitten tail -f /dev/null
fi

# Check if container is running
if ! docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Starting container '$CONTAINER_NAME'..."
    docker start "$CONTAINER_NAME"
fi

echo "Running kitten_deploy.jar in container '$CONTAINER_NAME' with mounted directories..."

# Run the JAR with the specified command and config path, mounting the directories
docker exec -it "$CONTAINER_NAME" java -jar kitten_deploy.jar \
  --testing-config all-compilers-config.yaml \
  --timeout 3600 \
  --max-recursions 5 \
  --enable-splicing true \
  --fuzzer-mode NORMAL_FUZZING \
  --verbosity "INFO" \
  "$@" 