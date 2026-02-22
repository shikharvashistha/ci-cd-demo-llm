# Puppet container — runs "puppet apply" locally to demonstrate configuration management.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y wget lsb-release ca-certificates curl jq && \
    wget https://apt.puppet.com/puppet7-release-jammy.deb && \
    dpkg -i puppet7-release-jammy.deb && \
    apt-get update && \
    apt-get install -y puppet-agent && \
    rm -rf /var/lib/apt/lists/* puppet7-release-jammy.deb

ENV PATH="/opt/puppetlabs/bin:${PATH}"

WORKDIR /puppet
COPY manifests/ /puppet/manifests/

CMD ["sh", "-c", "puppet apply /puppet/manifests/site.pp --verbose && echo 'Puppet configuration applied.' && tail -f /dev/null"]
