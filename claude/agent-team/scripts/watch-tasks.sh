#!/usr/bin/env bash
while true; do
    clear
    echo "=== AGENT TASKS ==="
    echo ""
    files=()
    for f in ~/.claude/tasks/*/?.json ~/.claude/tasks/*/??.json; do
        [ -f "$f" ] && files+=("$f")
    done
    if [ ${#files[@]} -gt 0 ]; then
        cat "${files[@]}" | jq -s '[.[] | {id,subject,status,owner}]' 2>/dev/null
    else
        echo "No tasks yet..."
    fi
    sleep 3
done
