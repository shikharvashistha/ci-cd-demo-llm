# ── Puppet Site Manifest ──────────────────────────────────────────────────────
#
# PURPOSE (for students):
#   Puppet is a "Configuration Management" tool.  Instead of SSH-ing into
#   servers and running commands by hand, you *declare* the desired state
#   in a manifest like this one, and Puppet makes the system match.
#
#   In a real deployment, a Puppet Server pushes these manifests to every
#   node (server) in your fleet.  For this demo we run `puppet apply`
#   locally inside a Docker container to illustrate the concept.
#
# WHAT THIS MANIFEST DOES:
#   1. Creates a dedicated application user
#   2. Creates the deployment directory with correct permissions
#   3. Writes a JSON config file consumed by the app
#   4. Writes a health-check script
#   5. Ensures required packages are present
# ─────────────────────────────────────────────────────────────────────────────

# ── 1. Ensure required packages ──────────────────────────────────────────────
package { 'curl':
  ensure => installed,
}

package { 'jq':
  ensure => installed,
}

# ── 2. Application user ─────────────────────────────────────────────────────
user { 'llmapp':
  ensure     => present,
  home       => '/opt/llm-app',
  managehome => true,
  shell      => '/bin/bash',
  comment    => 'LLM Text Analysis Service user',
}

# ── 3. Deployment directory ──────────────────────────────────────────────────
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

# ── 4. Application configuration file ───────────────────────────────────────
#    The Flask app could read this at startup to get environment-specific
#    settings (port, log level, feature flags, etc.)
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

# ── 5. Health-check script ──────────────────────────────────────────────────
file { '/opt/llm-app/healthcheck.sh':
  ensure  => file,
  owner   => 'llmapp',
  group   => 'llmapp',
  mode    => '0755',
  content => '#!/bin/bash
# Health-check script managed by Puppet
# Verifies the LLM app is running and responsive

APP_URL="${1:-http://localhost:5000}"

echo "Checking LLM App health at $APP_URL ..."

HEALTH=$(curl -sf "$APP_URL/health" | jq -r .status 2>/dev/null)

if [ "$HEALTH" = "healthy" ]; then
  echo "✅  App is healthy"
  exit 0
else
  echo "❌  App is NOT healthy"
  exit 1
fi
',
  require => [File['/opt/llm-app'], Package['curl'], Package['jq']],
}

# ── 6. Deployment log ───────────────────────────────────────────────────────
exec { 'log_puppet_run':
  command => '/bin/bash -c "echo \"[$(date -Iseconds)] Puppet applied configuration successfully\" >> /opt/llm-app/logs/puppet.log"',
  require => File['/opt/llm-app/logs'],
}

# ── Notify ───────────────────────────────────────────────────────────────────
notify { 'puppet_done':
  message => '🎉 Puppet has configured the LLM deployment environment!',
}
