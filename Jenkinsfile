// Jenkinsfile - CI/CD Pipeline for LLM Text Analysis Service
//
// Pipeline stages:
//   Checkout -> Build -> Unit Tests -> UI Tests -> Puppet Config -> Deploy
//
// Each stage runs sequentially. If any stage fails, the pipeline stops.

pipeline {
    agent any

    environment {
        APP_IMAGE   = 'llm-text-analysis'
        APP_VERSION = "${env.BUILD_NUMBER ?: 'dev'}"
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        stage('1. Checkout') {
            steps {
                echo 'Pulling latest code from GitHub...'
                checkout scm
                sh 'echo "Commit: $(git rev-parse --short HEAD)"'
            }
        }

        stage('2. Build Docker Image') {
            steps {
                echo 'Building the LLM app Docker image...'
                dir('app') {
                    sh "docker build -t ${APP_IMAGE}:${APP_VERSION} ."
                    sh "docker build -t ${APP_IMAGE}:latest ."
                }
                echo "Image built: ${APP_IMAGE}:${APP_VERSION}"
            }
        }

        stage('3. Unit Tests') {
            steps {
                echo 'Running unit tests inside the container...'
                sh """
                    docker run --rm \
                      ${APP_IMAGE}:${APP_VERSION} \
                      python -m pytest tests/ -v --tb=short
                """
            }
            post {
                failure {
                    echo 'Unit tests FAILED - pipeline will stop here.'
                }
                success {
                    echo 'All unit tests passed.'
                }
            }
        }

        stage('4. Selenium UI Tests') {
            steps {
                echo 'Starting the app + Selenium Chrome...'
                sh 'docker compose up -d llm-app selenium-chrome'
                sh 'sleep 10'

                echo 'Running Selenium UI tests...'
                sh 'docker compose run --rm selenium-tests'
            }
            post {
                always {
                    echo 'Cleaning up test containers...'
                    sh 'docker compose down llm-app selenium-chrome || true'
                }
            }
        }

        stage('5. Puppet Configuration') {
            steps {
                echo 'Applying Puppet configuration...'
                sh 'docker compose run --rm puppet'
                echo 'Environment configured by Puppet.'
            }
        }

        stage('6. Deploy to Production') {
            steps {
                echo 'Deploying the LLM app to production...'
                sh 'docker compose up -d llm-app prometheus'
                sh 'sleep 5'
                sh 'curl -sf http://localhost:5000/health | python3 -m json.tool'
                echo 'Deployment successful. App is live at http://localhost:5000'
            }
        }
    }

    post {
        success {
            echo 'PIPELINE SUCCEEDED - App: http://localhost:5000 | Prometheus: http://localhost:9090 | Jenkins: http://localhost:8080'
        }
        failure {
            echo 'Pipeline FAILED - check the logs above for details.'
        }
    }
}
