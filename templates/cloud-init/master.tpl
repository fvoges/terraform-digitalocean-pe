#cloud-config
hostname: master
fqdn: master.${domain}
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
