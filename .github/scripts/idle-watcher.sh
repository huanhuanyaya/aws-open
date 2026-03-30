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
    # 1. Check traditional login sessions
    SESSION_WHO_RAW=$(who)
    SESSION_WHO=$(echo "$SESSION_WHO_RAW" | grep -q . && echo "yes" || echo "no")
    
    # 2. Check for active Tailscale SSH sessions via ss
    # Tailscale maintains some background connections; we look for specific SSH patterns if possible.
    # Note: Tailscale SSH might not always show up in 'ss' normally, so tailscale status is better.
    SESSION_SS_RAW=$(ss -tnp | grep "tailscaled" || true)
    SESSION_SS=$(echo "$SESSION_SS_RAW" | grep -q "ESTAB" && echo "yes" || echo "no")
    
    # 3. Check tailscale status for active sessions (most reliable for TS SSH)
    SESSION_TS_RAW=$(tailscale status --active || true)
    SESSION_TS=$(echo "$SESSION_TS_RAW" | grep -q . && echo "yes" || echo "no")

    if [ "$SESSION_WHO" = "yes" ] || [ "$SESSION_SS" = "yes" ] || [ "$SESSION_TS" = "yes" ]; then
        # Active sessions found
        if [ $IDLE_TIME -ne 0 ] || [ $(( $(date +%s) % 120 )) -lt $CHECK_INTERVAL ]; then
            echo "$(date): System active. Details:"
            [ "$SESSION_WHO" = "yes" ] && echo "  - who: $SESSION_WHO_RAW"
            [ "$SESSION_SS" = "yes" ] && echo "  - ss: $SESSION_SS_RAW"
            [ "$SESSION_TS" = "yes" ] && echo "  - ts: $SESSION_TS_RAW"
            echo "Resetting/keeping idle timer at 0."
        fi
        IDLE_TIME=0
    else
        # No sessions found
        IDLE_TIME=$((IDLE_TIME + CHECK_INTERVAL))
        if [ $((IDLE_TIME % 60)) -eq 0 ] || [ $IDLE_TIME -ge $TIMEOUT ]; then
            echo "$(date): No active sessions. Idle for ${IDLE_TIME}s (Timeout: ${TIMEOUT}s)."
        fi
        
        if [ $IDLE_TIME -ge $TIMEOUT ]; then
            echo "$(date): Idle timeout reached. Triggering shutdown."
            /usr/local/bin/action-shutdown
            break
        fi
    fi
    sleep $CHECK_INTERVAL
done
