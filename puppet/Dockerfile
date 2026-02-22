# ── Puppet Dockerfile ─────────────────────────────────────────────────────────
# Lightweight Puppet agent image that applies manifests locally.
# In production, you'd use a Puppet Server + agents; for this demo
# we run "puppet apply" directly to show configuration management.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y wget lsb-release ca-certificates && \
    wget https://apt.puppet.com/puppet7-release-jammy.deb && \
    dpkg -i puppet7-release-jammy.deb && \
    apt-get update && \
    apt-get install -y puppet-agent && \
    rm -rf /var/lib/apt/lists/* puppet7-release-jammy.deb

ENV PATH="/opt/puppetlabs/bin:${PATH}"

WORKDIR /puppet
COPY manifests/ /puppet/manifests/

# Apply the manifest on container start, then sleep to keep container alive
CMD ["sh", "-c", "puppet apply /puppet/manifests/site.pp --verbose && echo '✅ Puppet configuration applied' && tail -f /dev/null"]
