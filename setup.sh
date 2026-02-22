#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  setup.sh — One-command setup for the CI/CD Demo
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   CI/CD Demo — LLM Text Analysis Service            ║"
echo "║   Setting up all services...                         ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Pre-flight checks ───────────────────────────────────────────────────────
echo -e "${YELLOW}[1/4] Checking prerequisites...${NC}"

if ! command -v docker &>/dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    echo "   → https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker compose version &>/dev/null; then
    echo -e "${RED}❌ Docker Compose is not available. Please install Docker Compose.${NC}"
    exit 1
fi

echo -e "   ✅ Docker $(docker --version | grep -oP '\d+\.\d+\.\d+')"
echo -e "   ✅ Docker Compose $(docker compose version --short)"

# ── Build ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[2/4] Building Docker images (this may take a few minutes)...${NC}"
docker compose build --parallel

# ── Start ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[3/4] Starting all services...${NC}"
docker compose up -d

# ── Wait for health checks ──────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[4/4] Waiting for services to become healthy...${NC}"

# Wait for LLM app
echo -n "   LLM App:     "
for i in $(seq 1 30); do
    if curl -sf http://localhost:5000/health &>/dev/null; then
        echo -e "${GREEN}✅ Ready${NC}"
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo -e "${RED}❌ Timeout${NC}"
    fi
    sleep 2
done

# Wait for Jenkins
echo -n "   Jenkins:     "
for i in $(seq 1 60); do
    if curl -sf http://localhost:8080/login &>/dev/null; then
        echo -e "${GREEN}✅ Ready${NC}"
        break
    fi
    if [ "$i" -eq 60 ]; then
        echo -e "${YELLOW}⏳ Still starting (Jenkins takes ~2 min)${NC}"
    fi
    sleep 2
done

# Wait for Prometheus
echo -n "   Prometheus:  "
for i in $(seq 1 20); do
    if curl -sf http://localhost:9090/-/ready &>/dev/null; then
        echo -e "${GREEN}✅ Ready${NC}"
        break
    fi
    if [ "$i" -eq 20 ]; then
        echo -e "${RED}❌ Timeout${NC}"
    fi
    sleep 2
done

# Wait for Selenium
echo -n "   Selenium:    "
for i in $(seq 1 20); do
    if curl -sf http://localhost:4444/wd/hub/status &>/dev/null; then
        echo -e "${GREEN}✅ Ready${NC}"
        break
    fi
    if [ "$i" -eq 20 ]; then
        echo -e "${RED}❌ Timeout${NC}"
    fi
    sleep 2
done

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   ✅  All services are running!                           ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║                                                           ║"
echo "║   🤖 LLM App:        http://localhost:5000               ║"
echo "║                                                           ║"
echo "║   🔧 Jenkins:        http://localhost:8080               ║"
echo "║      Username:       admin                               ║"
echo "║      Password:       admin                               ║"
echo "║                                                           ║"
echo "║   🌐 Selenium Grid:  http://localhost:4444               ║"
echo "║   🖥  Selenium VNC:   http://localhost:7900               ║"
echo "║      VNC Password:   secret                              ║"
echo "║                                                           ║"
echo "║   📊 Prometheus:     http://localhost:9090               ║"
echo "║      (no login required)                                  ║"
echo "║                                                           ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║   Run:  ./demo.sh   for interactive walkthrough           ║"
echo "║   Stop: docker compose down                               ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
