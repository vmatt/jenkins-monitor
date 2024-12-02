#!/bin/bash

CSV_FILE="/var/log/jenkins-monitor/collector.log

if [ ! -f "$CSV_FILE" ]; then
    echo "Error: $CSV_FILE not found!"
    exit 1
fi

echo "Processing $CSV_FILE..."
echo

# Function to print horizontal line
print_line() {
    printf '%.0s-' {1..65}
    echo
}

echo "Top 5 Jobs by Peak CPU Usage:"
print_line
awk -F',' '
    NR>1 { # Skip header
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
        printf "%-35s %8.2f%%  (at %s)\n",
        $1,
        $2,
        strftime("%Y-%m-%d %H:%M:%S", mktime(substr($3,1,4) " " substr($3,6,2) " " substr($3,9,2) " " substr($3,12,2) " " substr($3,15,2) " " substr($3,18,2)))
    }'

echo
echo "Top 5 Jobs by Peak Memory Usage:"
print_line
awk -F',' '
    NR>1 { # Skip header
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
        printf "%-35s %8.2f%%  (at %s)\n",
        $1,
        $2,
        strftime("%Y-%m-%d %H:%M:%S", mktime(substr($3,1,4) " " substr($3,6,2) " " substr($3,9,2) " " substr($3,12,2) " " substr($3,15,2) " " substr($3,18,2)))
    }'

echo
echo "Stats generated at: $(date)"
