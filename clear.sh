#!/usr/bin/env bash
# ==============================================================================
# 🛑 ZERO-COST TEARDOWN SCRIPT FOR KOOMAI EXPRESS SERVICE
# Cleanly terminates processes, frees ports, and cleans temporary caches
# ==============================================================================

set -eo pipefail

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${PORT:-5001}"

echo -e "${YELLOW}${BOLD}[*] Teardown: Stopping KoomAI Express Backend...${NC}"

# Kill process listening on port 5001
if command -v lsof &>/dev/null; then
    PIDS=$(lsof -ti ":${PORT}" 2>/dev/null || true)
    if [ -n "$PIDS" ]; then
        echo -e "  ${RED}✖${NC} Terminating process on port ${PORT} (PID: ${PIDS})..."
        kill -9 $PIDS 2>/dev/null || true
    fi
fi

# Kill any lingering node server.js
pkill -f "node.*server.js" 2>/dev/null || true
pkill -f "nodemon.*server.js" 2>/dev/null || true
pkill -f "bun.*server.js" 2>/dev/null || true

# Clean temporary video chunks
if [ -d "${SCRIPT_DIR}/temp_upload" ]; then
    rm -rf "${SCRIPT_DIR}/temp_upload"/* 2>/dev/null || true
    echo -e "${GREEN}[✓] Cleaned temporary video upload buffer.${NC}"
fi

echo -e "\n${GREEN}${BOLD}🎉 KoomAI Express Service cleared. Port ${PORT} is free! ($0.00 footprint)${NC}\n"
