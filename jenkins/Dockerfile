# Jenkins with Docker CLI and pre-installed plugins
FROM jenkins/jenkins:lts

USER root

# Install Docker CLI so Jenkins can build/run images
RUN apt-get update && \
    apt-get install -y docker.io curl && \
    rm -rf /var/lib/apt/lists/*

# Pre-install plugins listed in plugins.txt
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Load Jenkins Configuration as Code on startup
COPY casc.yaml /var/jenkins_home/casc.yaml
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc.yaml

# Skip the setup wizard for repeatable demos
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Drop back to the Jenkins user for runtime
USER jenkins
