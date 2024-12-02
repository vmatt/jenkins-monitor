#!/bin/bash

# Path to the CSV data file (not the log file)
CSV_FILE="/var/lib/jenkins-monitor/processes.csv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ ! -f "$CSV_FILE" ]; then
    echo -e "${RED}Error: $CSV_FILE not found!${NC}"
    echo "Note: This script analyzes the data file, not the log file."
    exit 1
fi

echo -e "${BLUE}Processing $CSV_FILE...${NC}"
echo

# Function to print horizontal line
print_line() {
    printf '%.0s-' {1..65}
    echo
}

echo -e "${GREEN}Top 5 Jobs by Peak CPU Usage:${NC}"
print_line
awk -F',' '
    NR>1 { # Skip header
        # Clean timestamp format (remove Z and T)
        gsub("T|Z", " ", $1)

        if ($4 > cpu[$3] || !($3 in cpu)) {
            cpu[$3] = $4        # Keep track of max CPU
            timestamp[$3] = $1   # Store timestamp of max value
        }
    }
    END {
        # Output max values with timestamps
        for (path in cpu) {
            printf "%s\t%f\t%s\n", path, cpu[path], timestamp[path]
        }
    }
' "$CSV_FILE" | \
    sort -k2 -nr | \
    head -n 5 | \
    awk '{
        # Parse timestamp without T and Z
        printf "%-35s %8.2f%%  (at %s)\n",
        $1,
        $2,
        $3
    }'

echo
echo -e "${GREEN}Top 5 Jobs by Peak Memory Usage:${NC}"
print_line
awk -F',' '
    NR>1 { # Skip header
        # Clean timestamp format (remove Z and T)
        gsub("T|Z", " ", $1)

        if ($5 > mem[$3] || !($3 in mem)) {
            mem[$3] = $5        # Keep track of max memory
            timestamp[$3] = $1   # Store timestamp of max value
        }
    }
    END {
        # Output max values with timestamps
        for (path in mem) {
            printf "%s\t%f\t%s\n", path, mem[path], timestamp[path]
        }
    }
' "$CSV_FILE" | \
    sort -k2 -nr | \
    head -n 5 | \
    awk '{
        # Parse timestamp without T and Z
        printf "%-35s %8.2f%%  (at %s)\n",
        $1,
        $2,
        $3
    }'

echo
echo -e "${BLUE}Stats generated at: $(date)${NC}"
