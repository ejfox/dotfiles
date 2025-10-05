#!/bin/bash
# Quick Docker status for tmux

RUNNING=$(docker ps -q | wc -l)
STOPPED=$(docker ps -a -q --filter "status=exited" | wc -l)

if [ $RUNNING -gt 0 ]; then
    echo "🐳$RUNNING"
    if [ $STOPPED -gt 0 ]; then
        echo " ⛔$STOPPED"
    fi
else
    echo "🐳💤"
fi