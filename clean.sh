#!/usr/bin/env bash
# clean.sh - Stop and remove all CI/CD demo resources
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}CI/CD Demo - Cleanup${NC}"
echo ""

# Stop and remove containers, networks
echo -e "${YELLOW}[1/3] Stopping containers...${NC}"
docker compose down 2>/dev/null || true
echo -e "${GREEN}  Containers stopped.${NC}"

# Remove volumes (Jenkins data, Prometheus data)
echo -e "${YELLOW}[2/3] Removing volumes...${NC}"
docker compose down -v 2>/dev/null || true
echo -e "${GREEN}  Volumes removed.${NC}"

# Remove built images
echo -e "${YELLOW}[3/3] Removing built images...${NC}"
for img in ci-cd-demo-llm-llm-app ci-cd-demo-llm-jenkins ci-cd-demo-llm-puppet ci-cd-demo-llm-selenium-tests; do
    if docker image inspect "$img" &>/dev/null; then
        docker rmi "$img" >/dev/null 2>&1 && echo -e "  Removed $img" || true
    fi
done
echo -e "${GREEN}  Images removed.${NC}"

echo ""
echo -e "${GREEN}Cleanup complete.${NC}"
echo "  To set up again: ./setup.sh"
