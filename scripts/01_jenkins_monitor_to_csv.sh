#!/bin/bash

# Output CSV file - now using full path
OUTPUT_DIR="/var/lib/jenkins-monitor"
OUTPUT_FILE="${OUTPUT_DIR}/processes.csv"

# Ensure directory exists (though install.sh should have created it)
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

# Create CSV header if file doesn't exist
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "timestamp,pid,build_path,cpu,mem" > "$OUTPUT_FILE"
fi

# Function to collect and write data
collect_data() {
    # Get current timestamp in ISO 8601 format
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Array to store results
    declare -a results

    # Iterate through all process IDs in /proc
    for pid_dir in /proc/[0-9]*; do
        pid="${pid_dir##*/}"

        # Check if the process directory exists
        if [ -d "/proc/$pid" ]; then
            # Read the environment variables and extract BUILD_URL
            build_url=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep '^BUILD_URL=' | cut -d'=' -f2)

            if [ -n "$build_url" ]; then
                # Get CPU usage and memory usage
                cpu=$(ps -p "$pid" -o %cpu= 2>/dev/null | tr -d ' ' || echo 0)
                mem=$(ps -p "$pid" -o %mem= 2>/dev/null | tr -d ' ' || echo 0)

                # Extract path from BUILD_URL
                build_path=$(echo "$build_url" | awk -F'/job/' '{for(i=2;i<=NF;i++) {split($i,a,"/"); printf a[1] (i==NF ? "" : "/")}} END {print ""}')

                # Escape any commas in build_path
                build_path=$(echo "$build_path" | sed 's/,/\\,/g')

                # Add to results array
                results+=("$timestamp,$pid,$build_path,$cpu,$mem")
            fi
        fi
    done

    # Write results to CSV file
    for result in "${results[@]}"; do
        echo "$result" >> "$OUTPUT_FILE"
    done

    # Log status message to stdout (will be captured by systemd logs)
    echo "$(date): Collected data for ${#results[@]} processes"
}

echo "Starting process monitoring. Writing to $OUTPUT_FILE"
echo "Press Ctrl+C to stop..."

# Run continuously until interrupted
while true; do
    collect_data
    sleep 30
done
