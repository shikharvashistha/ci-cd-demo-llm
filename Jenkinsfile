// ═══════════════════════════════════════════════════════════════════════════
//  Jenkinsfile — CI/CD Pipeline for LLM Text Analysis Service
// ═══════════════════════════════════════════════════════════════════════════
//
//  PIPELINE STAGES (shown visually in Jenkins Blue Ocean):
//
//   ┌──────────┐  ┌───────────┐  ┌────────────┐  ┌────────────┐  ┌──────────┐  ┌──────────┐
//   │ Checkout  │→ │   Build   │→ │ Unit Tests │→ │  UI Tests  │→ │  Config  │→ │  Deploy  │
//   │  (Git)    │  │ (Docker)  │  │  (pytest)  │  │ (Selenium) │  │ (Puppet) │  │  (Prod)  │
//   └──────────┘  └───────────┘  └────────────┘  └────────────┘  └──────────┘  └──────────┘
//
//  HOW TO READ THIS FILE (for non-CSE audience):
//    • A "pipeline" is an automated sequence of steps.
//    • Each "stage" is one step — if any stage fails, the pipeline stops.
//    • "agent any" means Jenkins picks any available worker to run this.
//    • "sh" runs a shell command (like typing in a terminal).
// ═══════════════════════════════════════════════════════════════════════════

pipeline {
    agent any

    // ── Environment variables available to all stages ───────────────────
    environment {
        APP_IMAGE   = 'llm-text-analysis'
        APP_VERSION = "${env.BUILD_NUMBER ?: 'dev'}"
    }

    // ── Pipeline options ────────────────────────────────────────────────
    options {
        timestamps()                    // Show timestamps in logs
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        // ────────────────────────────────────────────────────────────────
        // STAGE 1: Checkout — Pull the latest code from GitHub
        // ────────────────────────────────────────────────────────────────
        stage('1. Checkout') {
            steps {
                echo '📥 Pulling latest code from GitHub...'
                checkout scm
                sh 'echo "Commit: $(git rev-parse --short HEAD)"'
            }
        }

        // ────────────────────────────────────────────────────────────────
        // STAGE 2: Build — Create the Docker image for our LLM app
        // ────────────────────────────────────────────────────────────────
        stage('2. Build Docker Image') {
            steps {
                echo '🔨 Building the LLM app Docker image...'
                dir('app') {
                    sh "docker build -t ${APP_IMAGE}:${APP_VERSION} ."
                    sh "docker build -t ${APP_IMAGE}:latest ."
                }
                echo "✅ Image built: ${APP_IMAGE}:${APP_VERSION}"
            }
        }

        // ────────────────────────────────────────────────────────────────
        // STAGE 3: Unit Tests — Run automated tests on the code
        // ────────────────────────────────────────────────────────────────
        stage('3. Unit Tests') {
            steps {
                echo '🧪 Running unit tests inside the container...'
                sh """
                    docker run --rm \
                      ${APP_IMAGE}:${APP_VERSION} \
                      python -m pytest tests/ -v --tb=short
                """
            }
            post {
                failure {
                    echo '❌ Unit tests FAILED — pipeline will stop here.'
                }
                success {
                    echo '✅ All unit tests passed!'
                }
            }
        }

        // ────────────────────────────────────────────────────────────────
        // STAGE 4: UI Tests — Selenium verifies the web interface
        // ────────────────────────────────────────────────────────────────
        stage('4. Selenium UI Tests') {
            steps {
                echo '🌐 Starting the app + Selenium Chrome...'
                sh 'docker compose up -d llm-app selenium-chrome'
                sh 'sleep 10'  // Wait for services to be ready

                echo '🧪 Running Selenium UI tests...'
                sh 'docker compose run --rm selenium-tests'
            }
            post {
                always {
                    echo '🧹 Cleaning up test containers...'
                    sh 'docker compose down llm-app selenium-chrome || true'
                }
            }
        }

        // ────────────────────────────────────────────────────────────────
        // STAGE 5: Configuration — Puppet sets up the target environment
        // ────────────────────────────────────────────────────────────────
        stage('5. Puppet Configuration') {
            steps {
                echo '🔧 Applying Puppet configuration...'
                sh 'docker compose run --rm puppet'
                echo '✅ Environment configured by Puppet.'
            }
        }

        // ────────────────────────────────────────────────────────────────
        // STAGE 6: Deploy — Push to production
        // ────────────────────────────────────────────────────────────────
        stage('6. Deploy to Production') {
            steps {
                echo '🚀 Deploying the LLM app to production...'
                sh 'docker compose up -d llm-app prometheus'
                sh 'sleep 5'

                // Verify deployment
                sh 'curl -sf http://localhost:5000/health | python3 -m json.tool'
                echo '✅ Deployment successful! App is live at http://localhost:5000'
            }
        }
    }

    // ── Post-pipeline actions ───────────────────────────────────────────
    post {
        success {
            echo '''
            ╔══════════════════════════════════════════════╗
            ║  ✅  PIPELINE SUCCEEDED                      ║
            ║                                              ║
            ║  🌐 App:        http://localhost:5000        ║
            ║  📊 Prometheus: http://localhost:9090        ║
            ║  🔧 Jenkins:    http://localhost:8080        ║
            ╚══════════════════════════════════════════════╝
            '''
        }
        failure {
            echo '❌ Pipeline FAILED — check the logs above for details.'
        }
    }
}
