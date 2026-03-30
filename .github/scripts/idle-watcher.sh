#!/bin/bash

# Default timeout 600s
TIMEOUT=${IDLE_TIMEOUT:-600}

if [ "$TIMEOUT" -le 0 ]; then
    echo "Idle timeout is set to $TIMEOUT. Idle watcher is disabled."
    exit 0
fi

CHECK_INTERVAL=30
IDLE_TIME=0

echo "Starting idle watcher with timeout: ${TIMEOUT}s"

while true; do
    # Check if any user is logged in
    if who | grep -q .; then
        # Active sessions found
        if [ $IDLE_TIME -ne 0 ]; then
            echo "Session active. Resetting idle timer."
            IDLE_TIME=0
        fi
    else
        # No sessions found
        IDLE_TIME=$((IDLE_TIME + CHECK_INTERVAL))
        if [ $((IDLE_TIME % 60)) -eq 0 ] || [ $IDLE_TIME -ge $TIMEOUT ]; then
            echo "Idle for ${IDLE_TIME}s..."
        fi
        
        if [ $IDLE_TIME -ge $TIMEOUT ]; then
            echo "Idle timeout reached (${TIMEOUT}s). Triggering shutdown."
            /usr/local/bin/action-shutdown
            break
        fi
    fi
    sleep $CHECK_INTERVAL
done
