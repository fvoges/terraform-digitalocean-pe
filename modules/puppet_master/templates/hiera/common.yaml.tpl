
---
# The Hiera Data in this file is designed to allow Puppet Masters running PE
# 3.7.2 and above to run on VMs with 1 GB of RAM. These settings will likely not
# be sufficient for production loads.

# PE3.7 / 3.8
puppet_enterprise::profile::amq::broker::heap_mb: '96'
# JRuby tuning is only available for PE 3.7.2 and newer. Masters running 3.7.0
# or 3.7.1 should be given a full 4 GB of RAM to meet JRuby demands.
puppet_enterprise::master::puppetserver::jruby_max_active_instances: 1
puppet_enterprise::master::puppetserver::reserved_code_cache: '96m'
puppet_enterprise::profile::master::java_args:
  Xmx: '384m'
  Xms: '128m'
  'XX:MaxPermSize': '=96m'
  'XX:PermSize': '=64m'
  'XX:+UseG1GC': ''

puppet_enterprise::profile::puppetdb::java_args:
  Xmx: '128m'
  Xms: '64m'
  'XX:MaxPermSize': '=96m'
  'XX:PermSize': '=64m'
  'XX:+UseG1GC': ''
puppet_enterprise::puppetdb::read_maximum_pool_size: 4
puppet_enterprise::puppetdb::write_maximum_pool_size: 2

puppet_enterprise::profile::console::java_args:
  Xmx: '128m'
  Xms: '64m'
  'XX:MaxPermSize': '=96m'
  'XX:PermSize': '=64m'
  'XX:+UseG1GC': ''
puppet_enterprise::trapperkeeper::database_settings::activity::maximum_pool_size: 2
puppet_enterprise::trapperkeeper::database_settings::classifier::maximum_pool_size: 2
puppet_enterprise::trapperkeeper::database_settings::rbac::maximum_pool_size: 2
puppet_enterprise::profile::console::delayed_job_workers: 1

#shared_buffers takes affect during install but is not managed after
puppet_enterprise::profile::database::shared_buffers: '4MB'
#2015.3.2 and above
puppet_enterprise::profile::orchestrator::java_args:
  Xmx: '128m'
  Xms: '128m'
  'XX:+UseG1GC': ''
profile::puppet::master::autosign::shared_secret: '${autosign_pwd}'
puppet_enterprise::profile::master::metrics_graphite_enabled: true
puppet_enterprise::profile::master::metrics_graphite_host: 'master.${domain}'
