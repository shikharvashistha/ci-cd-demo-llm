# Puppet container - runs "puppet apply" locally to demonstrate config management.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Puppet agent from the official repo
RUN apt-get update && \
    apt-get install -y wget lsb-release ca-certificates curl jq && \
    wget https://apt.puppet.com/puppet7-release-jammy.deb && \
    dpkg -i puppet7-release-jammy.deb && \
    apt-get update && \
    apt-get install -y puppet-agent && \
    rm -rf /var/lib/apt/lists/* puppet7-release-jammy.deb

# Add Puppet binaries to PATH
ENV PATH="/opt/puppetlabs/bin:${PATH}"

WORKDIR /puppet
COPY manifests/ /puppet/manifests/

# Apply the manifest and keep the container running for demo visibility
CMD ["sh", "-c", "puppet apply /puppet/manifests/site.pp --verbose && echo 'Puppet configuration applied.' && tail -f /dev/null"]
