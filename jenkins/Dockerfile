# ── Jenkins Dockerfile ────────────────────────────────────────────────────────
# Custom Jenkins image with Docker CLI + pre-installed plugins
FROM jenkins/jenkins:lts

USER root

# Install Docker CLI so Jenkins can build images
RUN apt-get update && \
    apt-get install -y docker.io curl && \
    rm -rf /var/lib/apt/lists/*

# Copy plugin list & install
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Copy Jenkins Configuration-as-Code
COPY casc.yaml /var/jenkins_home/casc.yaml
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc.yaml

# Skip setup wizard (demo only!)
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

USER jenkins
