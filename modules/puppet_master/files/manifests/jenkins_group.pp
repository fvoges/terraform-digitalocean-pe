Node_group {
  provider => 'https',
}

node_group { 'Jenkins Server':
  ensure               => 'present',
  classes              => { 'role::ci' => {}},
  environment          => 'production',
  override_environment => false,
  parent               => 'All Nodes',
  rule                 => ['=', ['trusted', 'extensions', 'pp_role'], 'ci'],
}
