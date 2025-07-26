#!/bin/bash

# Run the kitten_organizer_deploy.jar file
# Usage: ./run-organizer.sh [additional-options]

JAR_FILE="kitten_organizer_deploy.jar"

if [ ! -f "$JAR_FILE" ]; then
    echo "Error: $JAR_FILE not found in current directory"
    echo "Make sure you're in the /perses directory inside the Docker container"
    exit 1
fi

echo "Running $JAR_FILE..."
java -jar "$JAR_FILE" "$@" 