#cloud-config
hostname: "${hostname}"
fqdn: "${hostname}.${domain}"
manage_etc_hosts: true
package_update: true
# package_upgrade: true
packages:
  - ack-grep
  - bash-completion
  - ccze
  - colordiff
  - curl
  - git
  - htop
  - jq
  - lftp
  - lynx
  - make
  - mc
  - mutt
  - netcat
  - psmisc
  - rsync
  - sysstat
  - telnet
  - tree
  - vim-nox
  - wget
runcmd:
  - export HOME=/root
  - curl -q https://gist.githubusercontent.com/fvoges/741de3b432e19c11c9bb/raw/874ea086b0f5e4bc07945dad3ea840f85a248a9a/rcinstall.sh|bash
  - while ! nc -z puppet.${domain} 8140; do echo "Waiting for Puppet Master pool to be ready"; sleep 5; done
  - curl -s -k https://puppet.${domain}:8140/packages/current/install.bash | bash -s -- --puppet-service-ensure stopped extension_requests:pp_role=${role} custom_attributes:challengePassword=${autosign_pwd}
  - touch /tmp/provisioning_done
  # Sleep to avoid https://tickets.puppetlabs.com/browse/PUP-2958
  - /usr/local/bin/puppet agent -tw2
  - /usr/local/bin/puppet resource service puppet ensure=running





