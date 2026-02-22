# Puppet Site Manifest
#
# Declares the desired state for the LLM deployment environment.
# Puppet ensures the system matches this manifest on every run (idempotent).
#
# Resources managed:
#   1. Required packages (curl, jq)
#   2. Application user
#   3. Deployment directories
#   4. Application config file
#   5. Health-check script

# 1. Required packages
package { 'curl':
  ensure => installed,
}

package { 'jq':
  ensure => installed,
}

# 2. Application user
user { 'llmapp':
  ensure     => present,
  home       => '/opt/llm-app',
  managehome => true,
  shell      => '/bin/bash',
  comment    => 'LLM Text Analysis Service user',
}

# 3. Deployment directory
file { '/opt/llm-app':
  ensure  => directory,
  owner   => 'llmapp',
  group   => 'llmapp',
  mode    => '0755',
  require => User['llmapp'],
}

file { '/opt/llm-app/config':
  ensure  => directory,
  owner   => 'llmapp',
  group   => 'llmapp',
  mode    => '0755',
  require => File['/opt/llm-app'],
}

file { '/opt/llm-app/logs':
  ensure  => directory,
  owner   => 'llmapp',
  group   => 'llmapp',
  mode    => '0755',
  require => File['/opt/llm-app'],
}

# 4. Application configuration file
file { '/opt/llm-app/config/app.json':
  ensure  => file,
  owner   => 'llmapp',
  group   => 'llmapp',
  mode    => '0644',
  content => '{
  "app_name": "LLM Text Analysis Service",
  "environment": "production",
  "port": 5000,
  "log_level": "INFO",
  "features": {
    "sentiment_analysis": true,
    "summarization": true,
    "prometheus_metrics": true
  },
  "model": {
    "type": "textblob",
    "version": "0.18"
  }
}
',
  require => File['/opt/llm-app/config'],
}

# 5. Health-check script
file { '/opt/llm-app/healthcheck.sh':
  ensure  => file,
  owner   => 'llmapp',
  group   => 'llmapp',
  mode    => '0755',
  content => '#!/bin/bash
# Health-check script (managed by Puppet)

APP_URL="${1:-http://localhost:5000}"

echo "Checking LLM App health at $APP_URL ..."

HEALTH=$(curl -sf "$APP_URL/health" | jq -r .status 2>/dev/null)

if [ "$HEALTH" = "healthy" ]; then
  echo "App is healthy"
  exit 0
else
  echo "App is NOT healthy"
  exit 1
fi
',
  require => [File['/opt/llm-app'], Package['curl'], Package['jq']],
}

# 6. Deployment log
exec { 'log_puppet_run':
  command => '/bin/bash -c "echo \"[$(date -Iseconds)] Puppet applied configuration successfully\" >> /opt/llm-app/logs/puppet.log"',
  require => File['/opt/llm-app/logs'],
}

notify { 'puppet_done':
  message => 'Puppet has configured the LLM deployment environment.',
}
