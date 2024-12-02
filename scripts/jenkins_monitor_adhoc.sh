#!/bin/bash

# ANSI color codes
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}Scanning processes for BUILD_URL...${NC}"
echo

# Print table header
printf "%-10s | %-20s | %-35s | %-8s | %-8s\n" "PID" "PROCESS" "BUILD_PATH" "CPU%" "MEM%"
printf '%.0s-' {1..100}; echo

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
            # Get process name, CPU usage, and memory usage
            process_name=$(ps -p "$pid" -o comm= 2>/dev/null)
            cpu=$(ps -p "$pid" -o %cpu= 2>/dev/null | tr -d ' ' || echo 0)
            mem=$(ps -p "$pid" -o %mem= 2>/dev/null | tr -d ' ' || echo 0)

            # Extract path from BUILD_URL
            build_path=$(echo "$build_url" | awk -F'/job/' '{for(i=2;i<=NF;i++) {split($i,a,"/"); printf a[1] (i==NF ? "" : "/")}} END {print ""}')

            # Truncate strings if they are too long
            [ ${#build_path} -gt 35 ] && build_path="${build_path:0:32}..."
            [ ${#process_name} -gt 20 ] && process_name="${process_name:0:17}..."

            # Store the formatted result in the array
            results+=("$(printf "%-10s | %-20s | %-35s | %8.1f | %8.1f\n" \
                "$pid" "$process_name" "$build_path" "$cpu" "$mem")")
        fi
    fi
done

# Sort results by CPU usage in descending order
IFS=$'\n' sorted_results=($(sort -t'|' -k4 -nr <<<"${results[*]}"))
unset IFS

# Print the results
for result in "${sorted_results[@]}"; do
    echo "$result"
done

# Print footer
if [ ${#results[@]} -gt 0 ]; then
    printf '%.0s-' {1..100}; echo
    echo "Total processes found: ${#results[@]}"
else
    echo "No processes with BUILD_URL found"
fi