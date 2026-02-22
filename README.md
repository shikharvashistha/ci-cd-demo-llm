# CI/CD Demo — LLM Text Analysis Service

> **Audience:** Professionals from non-CSE backgrounds  
> **Goal:** Understand end-to-end CI/CD by seeing it work on a real LLM application

---

## 🗺️ What This Demo Shows

```
  Developer          GitHub           Jenkins            Production
  ────────          ──────           ───────            ──────────
  Writes code  ──▶  Push to   ──▶  Automated   ──▶   App is live
  & commits         repo           pipeline           & monitored
                                      │
                        ┌─────────────┼─────────────┐
                        ▼             ▼             ▼
                     Build         Test          Deploy
                   (Docker)    (Selenium)     (Puppet +
                                              Prometheus)
```

### Tools & Their Roles

| Tool | Role | Think of it as… |
|------|------|-----------------|
| **GitHub** | Source code repository | A shared Google Drive for code |
| **Jenkins** | CI/CD automation server | A robot that builds & deploys your code every time you push changes |
| **Selenium** | Browser-based UI testing | A robot that opens your website and clicks buttons to verify it works |
| **Puppet** | Configuration management | A checklist that ensures every server is set up identically |
| **Prometheus** | Monitoring & alerting | A dashboard that watches your app's health 24/7 |
| **Docker** | Containerization | A shipping container — your app runs the same everywhere |

---

## 📁 Project Structure

```
ci-cd-demo-llm/
├── app/                        ← The LLM application
│   ├── Dockerfile              ← How to package the app
│   ├── app.py                  ← Flask server (sentiment + summarization)
│   ├── requirements.txt        ← Python dependencies
│   ├── templates/
│   │   └── index.html          ← Web user interface
│   └── tests/
│       └── test_app.py         ← Unit tests
│
├── jenkins/                    ← Jenkins CI/CD server config
│   ├── Dockerfile              ← Custom Jenkins with Docker & plugins
│   ├── plugins.txt             ← Jenkins plugins to install
│   └── casc.yaml               ← Jenkins Configuration-as-Code
│
├── selenium-tests/             ← Automated UI tests
│   ├── Dockerfile
│   ├── requirements.txt
│   └── test_ui.py              ← Selenium WebDriver tests
│
├── puppet/                     ← Configuration management
│   ├── Dockerfile
│   └── manifests/
│       └── site.pp             ← Puppet manifest (desired system state)
│
├── prometheus/                 ← Monitoring
│   ├── prometheus.yml          ← What to monitor
│   └── alert_rules.yml         ← When to raise alarms
│
├── docker-compose.yml          ← Orchestrates ALL services
├── Jenkinsfile                 ← The CI/CD pipeline definition
├── setup.sh                    ← One-command setup script
├── demo.sh                     ← Interactive demo walkthrough
└── README.md                   ← This file
```

---

## 🚀 Quick Start (5 minutes)

### Prerequisites
- **Docker** & **Docker Compose** installed ([Install Docker](https://docs.docker.com/get-docker/))
- **Git** installed
- 4 GB+ free RAM

### 1. Clone & Enter

```bash
git clone https://github.com/YOUR_USERNAME/ci-cd-demo-llm.git
cd ci-cd-demo-llm
```

### 2. Start Everything

```bash
# Build and start all services
docker compose up -d --build
```

### 3. Open the Dashboards

| Service | URL | Credentials |
|---------|-----|-------------|
| **LLM App** | [http://localhost:5000](http://localhost:5000) | — |
| **Jenkins** | [http://localhost:8080](http://localhost:8080) | admin / admin |
| **Selenium Grid** | [http://localhost:4444](http://localhost:4444) | — |
| **Selenium VNC** | [http://localhost:7900](http://localhost:7900) | secret |
| **Prometheus** | [http://localhost:9090](http://localhost:9090) | — |

### 4. Stop Everything

```bash
docker compose down
```

---

## 🎓 Step-by-Step Demo Walkthrough

### Demo 1: The Application (2 min)

1. Open [http://localhost:5000](http://localhost:5000)
2. Paste any text (an article, review, etc.)
3. Click **⚡ Analyze**
4. Show the **Sentiment** (positive/negative/neutral) and **Summary**
5. Explain: *"This is the product we're building — an LLM-powered text analysis tool"*

### Demo 2: The Pipeline — Jenkins (5 min)

1. Open [http://localhost:8080](http://localhost:8080) → login `admin` / `admin`
2. Click **"llm-text-analysis"** pipeline
3. Click **"Build Now"**
4. Click **"Open Blue Ocean"** (left sidebar) for the visual pipeline view
5. Walk through each stage:
   - **Checkout** → Pulls code from GitHub
   - **Build** → Creates Docker image
   - **Unit Tests** → Runs pytest
   - **UI Tests** → Selenium clicks through the app
   - **Puppet Config** → Sets up the server
   - **Deploy** → Pushes to production

> **Key message:** *"Every time a developer pushes code, this entire process runs automatically. If any step fails, the code does NOT reach production."*

### Demo 3: Automated UI Testing — Selenium (3 min)

1. Open [http://localhost:7900](http://localhost:7900) (password: `secret`) — this shows a live browser
2. Run tests manually:
   ```bash
   docker compose run --rm selenium-tests
   ```
3. Watch the browser automatically:
   - Open the app
   - Type text
   - Click Analyze
   - Verify results appear

> **Key message:** *"Selenium is like a robot QA tester that checks the UI 24/7 — no human needed."*

### Demo 4: Configuration Management — Puppet (3 min)

1. Run Puppet:
   ```bash
   docker compose run --rm puppet
   ```
2. Show the output — Puppet creates users, directories, config files
3. Run it **again** — Puppet reports nothing changed (idempotency!)

> **Key message:** *"Puppet ensures every server looks identical. Run it once or a hundred times — same result. This prevents 'works on my machine' problems."*

### Demo 5: Monitoring — Prometheus (3 min)

1. Open [http://localhost:9090](http://localhost:9090)
2. In the query box, type: `llm_requests_total` → click **Execute** → **Graph**
3. Go back to the app, submit a few analyses
4. Refresh Prometheus — the counter goes up
5. Try: `llm_request_latency_seconds_bucket`
6. Go to **Status → Targets** — show that Prometheus is watching both the app and Jenkins

> **Key message:** *"Prometheus watches your application in real-time. If something breaks, it fires alerts before users even notice."*

---

## 🔄 The CI/CD Pipeline Explained

```
┌─────────────────────────────────────────────────────────────────────┐
│                        JENKINS PIPELINE                             │
│                                                                     │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐     │
│  │ CHECKOUT │───▶│  BUILD   │───▶│  TEST    │───▶│  DEPLOY  │     │
│  │          │    │          │    │          │    │          │     │
│  │ Pull     │    │ Docker   │    │ pytest + │    │ Puppet + │     │
│  │ from     │    │ image    │    │ Selenium │    │ restart  │     │
│  │ GitHub   │    │ create   │    │ verify   │    │ app      │     │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘     │
│                                                                     │
│  If ANY stage fails ──▶ Pipeline STOPS ──▶ Developer is notified   │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   PROMETHEUS     │
                    │   Monitors the   │
                    │   deployed app   │
                    └──────────────────┘
```

---

## 📝 Key Concepts for Non-CSE Professionals

### CI/CD = Continuous Integration / Continuous Deployment

| Term | Meaning | Analogy |
|------|---------|---------|
| **Continuous Integration** | Every code change is automatically tested | Like auto-spell-check while you type |
| **Continuous Deployment** | Tested code is automatically released | Like auto-publishing a document after review |
| **Pipeline** | The series of automated steps | Like an assembly line in a factory |
| **Container (Docker)** | A packaged, portable application | Like a shipping container — same contents everywhere |
| **Configuration Management** | Automated server setup | Like a checklist that a robot follows |
| **Monitoring** | Real-time health tracking | Like a heart monitor in a hospital |

### Why Does This Matter?

1. **Speed** — Changes go live in minutes, not weeks
2. **Quality** — Bugs are caught automatically before reaching users
3. **Consistency** — Every server is configured identically
4. **Visibility** — Everyone can see what's deployed and its health
5. **Reliability** — If a deployment fails, it rolls back automatically

---

## 🛠️ Customization

### Change Jenkins GitHub repo
Edit `jenkins/casc.yaml` → update the `url` field with your actual GitHub repo URL.

### Add more tests
Add test functions in `app/tests/test_app.py` (unit) or `selenium-tests/test_ui.py` (UI).

### Change monitoring targets
Edit `prometheus/prometheus.yml` to scrape additional services.

---

## 🧹 Cleanup

```bash
# Stop all services
docker compose down

# Stop + remove all data (volumes)
docker compose down -v

# Remove built images
docker rmi llm-text-analysis:latest
```

---

## 📚 Further Reading

- [Docker Getting Started](https://docs.docker.com/get-started/)
- [Jenkins Pipeline Tutorial](https://www.jenkins.io/doc/book/pipeline/)
- [Selenium Documentation](https://www.selenium.dev/documentation/)
- [Puppet Overview](https://puppet.com/docs/puppet/latest/puppet_overview.html)
- [Prometheus First Steps](https://prometheus.io/docs/introduction/first_steps/)

---

*Built for educational purposes — not for production use.*
