#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <process_name>"
    exit 1
fi

PROCESS_NAME="$1"
LOG_FILE="/var/log/monitoring.log"

MONITOR_URL="https://test.com/monitoring/test/api"
# MONITOR_URL="localhost:8081/health" # test URL

PID_FILE="/tmp/test_monitor_${PROCESS_NAME}.pid"

current_pid=$(pgrep -x "$PROCESS_NAME")

if [ -z "$current_pid" ]; then
    echo "$(date): Process '$PROCESS_NAME' is not running"
    exit 0
fi

if [ -f "$PID_FILE" ]; then
    stored_pid=$(cat "$PID_FILE")
    if [ "$stored_pid" != "$current_pid" ]; then
        echo "$(date): Process '$PROCESS_NAME' restarted. New PID: $current_pid" >> "$LOG_FILE"
    fi
fi
echo "$current_pid" > "$PID_FILE"

curl --max-time 5 --silent --fail "$MONITOR_URL" > /dev/null
if [ $? -ne 0 ]; then
    echo "$(date): Monitoring server $MONITOR_URL is not available" >> "$LOG_FILE"
else
    echo "$(date): Success sending request to $MONITOR_URL"
fi

echo "Exiting..."

exit 0
