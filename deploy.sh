#!/usr/bin/env bash
# ==============================================================================
# 🚀 KOOMAI REAL-TIME MEDIA INGESTION & WEBRTC API DEPLOYMENT SCRIPT
# One-click autonomous startup for local development and cloud VMs
# ==============================================================================

set -eo pipefail

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PORT="${PORT:-5001}"

echo -e "${CYAN}${BOLD}"
cat << "EOF"
================================================================================
  🎬 KOOMAI HIGH-THROUGHPUT MEDIA INGESTION & WEBRTC API
  Automated Deployment Runner
================================================================================
EOF
echo -e "${NC}"

# 1. Kill any existing process on port
if command -v lsof &>/dev/null; then
    OCCUPIED_PID=$(lsof -ti ":${PORT}" 2>/dev/null || true)
    if [ -n "$OCCUPIED_PID" ]; then
        echo -e "${YELLOW}[i] Port ${PORT} occupied by PID ${OCCUPIED_PID}. Terminating...${NC}"
        kill -9 $OCCUPIED_PID 2>/dev/null || true
        sleep 1
    fi
fi

# 2. Check Package Manager (bun preferred, npm fallback)
if command -v bun &>/dev/null; then
    PKG_MGR="bun"
    RUN_CMD="bun run start"
elif command -v npm &>/dev/null; then
    PKG_MGR="npm"
    RUN_CMD="npm start"
else
    PKG_MGR="node"
    RUN_CMD="node server.js"
fi

echo -e "${GREEN}[✓] Using runtime manager: ${PKG_MGR}${NC}"

# 3. Ensure dependencies installed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}[+] Installing dependencies...${NC}"
    if [ "$PKG_MGR" = "bun" ]; then
        bun install
    else
        npm install
    fi
fi

# 4. Ensure upload directory exists
mkdir -p temp_upload

# 5. Start Service
echo -e "${CYAN}[*] Starting KoomAI Express Backend on port ${PORT}...${NC}"

if [ "$1" = "--daemon" ] || [ "$1" = "-d" ]; then
    mkdir -p logs
    nohup $RUN_CMD > logs/server.log 2>&1 &
    APP_PID=$!
    echo -e "${GREEN}[✓] Server launched in background (PID: ${APP_PID})${NC}"
    echo -e "  • Tail logs: ${YELLOW}tail -f logs/server.log${NC}"
    echo -e "  • Health:    ${CYAN}http://localhost:${PORT}/health${NC}"
    echo -e "  • Metrics:   ${CYAN}http://localhost:${PORT}/metrics${NC}"
else
    exec $RUN_CMD
fi
