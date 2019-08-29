#----------------------------------------------------------------------------
# Puppet Enterprise installer configuration file
# https://docs.puppet.com/pe/latest/install_pe_conf_param.html
#
# Format: Hocon
# https://docs.puppet.com/pe/latest/config_hocon.html
#----------------------------------------------------------------------------
{
  #--------------------------------------------------------------------------
  # Required. The password to log into the Puppet Enterprise console.
  #--------------------------------------------------------------------------
  "console_admin_password": "${console_pwd}"

  # Puppet Enterprise Master
  "puppet_enterprise::puppet_master_host": "%%{::trusted.certname}"

  # DNS altnames to be added to the SSL certificate generated for the Puppet
  # master node. Only used at install time.
  "pe_install::puppet_master_dnsaltnames": ["puppet","master","lb","puppet.${domain},"master.${domain},"lb.${domain}"]

  # R10K options
  "puppet_enterprise::profile::master::code_manager_auto_configure": true
  "puppet_enterprise::profile::master::r10k_remote": "${r10k_remote}"
}
