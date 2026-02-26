#!/usr/bin/env bash
while true; do
    clear
    echo "=== TEAM MEMBERS ==="
    echo ""
    config=$(find ~/.claude/teams -name "config.json" 2>/dev/null | head -1)
    if [ -n "$config" ]; then
        jq '.members[] | {name,agentType,backendType}' "$config" 2>/dev/null
    else
        echo "No team yet..."
    fi
    sleep 5
done
