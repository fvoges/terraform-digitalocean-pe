Node_group {
  provider => 'https',
}

node_group { 'vRA Integration':
  ensure               => 'present',
  classes              => {'profile::vra_config' => {}},
  environment          => 'production',
  override_environment => false,
  parent               => 'All Nodes',
  rule                 => ['=', 'name', $facts['fqdn']],
}
