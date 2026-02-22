#!/usr/bin/env bash
# demo.sh - Interactive walkthrough for class presentation
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

pause() {
    echo ""
    echo -e "${YELLOW}   Press ENTER to continue...${NC}"
    read -r
}

clear
echo -e "${CYAN}${BOLD}"
echo "CI/CD Demo - LLM Text Analysis Service"
echo "Interactive Walkthrough"
echo -e "${NC}"
echo ""
echo "This demo walks through 5 live demos:"
echo ""
echo "  1. The LLM Application"
echo "  2. Jenkins CI/CD Pipeline"
echo "  3. Selenium Automated Testing"
echo "  4. Puppet Configuration Management"
echo "  5. Prometheus Monitoring"
echo ""
pause

# Demo 1
clear
echo -e "${CYAN}${BOLD}Demo 1: The LLM Application${NC}"
echo ""
echo "Open in your browser:  ${GREEN}http://localhost:5000${NC}"
echo ""
echo "What to show:"
echo "  - Paste some text (a product review, article, etc.)"
echo "  - Click Analyze"
echo "  - Point out: Sentiment (positive/negative/neutral)"
echo "  -            Summary (shortened version)"
echo "  -            Stats (character reduction %)"
echo ""
echo -e "${YELLOW}Key message:${NC}"
echo "  'This is our product - an LLM-powered text analysis tool."
echo "   Now let's see how we automate building, testing, and deploying it.'"
echo ""
echo "Also show the API directly:"
echo -e "  ${GREEN}curl -s http://localhost:5000/health | python3 -m json.tool${NC}"
echo ""

# Actually call the health endpoint
echo "Health check result:"
curl -s http://localhost:5000/health 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "(App not running — start with: docker compose up -d)"
pause

# Demo 2
clear
echo -e "${CYAN}${BOLD}Demo 2: Jenkins CI/CD Pipeline${NC}"
echo ""
echo "Open in your browser:  ${GREEN}http://localhost:8080${NC}"
echo "  Login:  admin / admin"
echo ""
echo "What to show:"
echo "  1. Click 'llm-text-analysis' pipeline"
echo "  2. Click 'Build Now' (left sidebar)"
echo "  3. Click 'Open Blue Ocean' for visual pipeline view"
echo "  4. Walk through each stage:"
echo ""
echo "     ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐"
echo "     │ Checkout  │→ │  Build   │→ │  Unit    │→ │   UI     │→ │ Puppet   │→ │ Deploy   │"
echo "     │  (Git)    │  │ (Docker) │  │  Tests   │  │  Tests   │  │  Config  │  │  (Prod)  │"
echo "     └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘"
echo ""
echo -e "${YELLOW}Key message:${NC}"
echo "  'Every time a developer pushes code to GitHub, this entire process"
echo "   runs automatically. If ANY step fails, the code NEVER reaches production.'"
pause

# Demo 3
clear
echo -e "${CYAN}${BOLD}Demo 3: Selenium UI Testing${NC}"
echo ""
echo "Watch live in browser:  ${GREEN}http://localhost:7900${NC}  (password: secret)"
echo "Selenium Grid:          ${GREEN}http://localhost:4444${NC}"
echo ""
echo "Now running Selenium tests..."
echo ""
docker compose run --rm selenium-tests 2>&1 || echo -e "${YELLOW}(Tests completed or app not running)${NC}"
echo ""
echo -e "${YELLOW}Key message:${NC}"
echo "  'Selenium is like a robot QA tester. It opens a real browser, types text,"
echo "   clicks buttons, and verifies everything works — 24/7, no human needed.'"
pause

# Demo 4
clear
echo -e "${CYAN}${BOLD}Demo 4: Puppet Configuration${NC}"
echo ""
echo "Running Puppet to configure the deployment environment..."
echo ""
docker compose run --rm puppet 2>&1 || echo -e "${YELLOW}(Puppet completed)${NC}"
echo ""
echo "Now running Puppet AGAIN (idempotency demo)..."
echo ""
docker compose run --rm puppet 2>&1 || echo -e "${YELLOW}(Puppet completed)${NC}"
echo ""
echo -e "${YELLOW}Key message:${NC}"
echo "  'Puppet declares the DESIRED STATE, not the steps."
echo "   Run it once or 100 times — the result is always the same."
echo "   This prevents the \"works on my machine\" problem.'"
pause

# Demo 5
clear
echo -e "${CYAN}${BOLD}Demo 5: Prometheus Monitoring${NC}"
echo ""
echo "Open in your browser:  ${GREEN}http://localhost:9090${NC}"
echo ""
echo "What to show:"
echo "  1. Query box → type: llm_requests_total  → Execute → Graph"
echo "  2. Go to the app, submit a few analyses"
echo "  3. Refresh Prometheus — the counter increases"
echo "  4. Try: llm_request_latency_seconds_bucket"
echo "  5. Go to Status → Targets → Show all monitored services"
echo ""

# Generate some traffic for the demo
echo "Generating sample requests to create metrics..."
for i in $(seq 1 5); do
    curl -sf -X POST http://localhost:5000/analyze \
        -H "Content-Type: application/json" \
        -d '{"text": "This is test request number '"$i"'. CI/CD is amazing!"}' \
        >/dev/null 2>&1 || true
    echo "  Request $i sent"
done
echo ""

echo -e "${YELLOW}Key message:${NC}"
echo "  'Prometheus watches your app in real-time. If latency spikes or the app"
echo "   goes down, it fires alerts — often before users even notice a problem.'"
pause

# Summary
clear
echo -e "${GREEN}${BOLD}"
echo "Demo Complete"
echo -e "${NC}"
echo ""
echo "  What we demonstrated:"
echo ""
echo "  - GitHub     : Source code management"
echo "  - Jenkins    : Automated CI/CD pipeline"
echo "  - Selenium   : Automated UI testing"
echo "  - Puppet     : Configuration management"
echo "  - Prometheus : Monitoring and alerting"
echo "  - Docker     : Containerization (runs everything)"
echo ""
echo "  The big picture:"
echo ""
echo "    Developer pushes code -> GitHub -> Jenkins pipeline runs -> "
echo "    Tests pass -> Puppet configures servers -> App deployed -> "
echo "    Prometheus monitors health"
echo ""
echo "  All of this happens AUTOMATICALLY on every code change."
echo ""
echo -e "  ${CYAN}Services still running at:${NC}"
echo "    App:        http://localhost:5000"
echo "    Jenkins:    http://localhost:8080"
echo "    Prometheus: http://localhost:9090"
echo ""
echo "  To stop:  docker compose down"
echo ""
