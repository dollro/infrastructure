#!/usr/bin/env bash
echo "Waiting for team creation..."
while true; do
    inbox=$(find ~/.claude/teams -name "team-lead.json" -path "*/inboxes/*" 2>/dev/null | head -1)
    if [ -n "$inbox" ]; then
        echo "Team found! Tailing: $inbox"
        echo ""
        tail -f "$inbox" | while read -r line; do
            echo "$line" | jq '.' 2>/dev/null || echo "$line"
        done
        break
    fi
    sleep 2
done
