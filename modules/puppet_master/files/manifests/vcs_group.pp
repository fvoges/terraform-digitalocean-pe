Node_group {
  provider => 'https',
}

node_group { 'Version Control Server':
  ensure               => 'present',
  classes              => { 'role::vcs' => {}},
  environment          => 'production',
  override_environment => false,
  parent               => 'All Nodes',
  rule                 => ['=', ['trusted', 'extensions', 'pp_role'], 'vcs'],
}
