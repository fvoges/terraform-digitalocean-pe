$pe_agent_classes = node_groups()['PE Agent']['classes']

$pe_master_classes = node_groups()['PE Master']['classes']

$pe_agent_new_classes = {
  'puppet_enterprise::profile::agent' => {
    'package_inventory_enabled' => true
  }
}

$pe_master_new_classes = {
  'pe_repo::platform::el_7_x86_64' => {},
}

node_group { 'Production one-time run exception':
  ensure               => 'present',
  description          => 'Allow production nodes to request a different puppet environment for a one-time run. May request and use any Puppet environment except for \'development\'.',
  environment          => 'agent-specified',
  override_environment => true,
  parent               => 'Production environment',
  rule                 => ['and',
  ['~',
    ['fact', 'agent_specified_environment'],
    '.+'],
  ['not',
    ['=',
      ['fact', 'agent_specified_environment'],
      'development']]],
}

node_group { 'PE Agent':
  ensure      => 'present',
  classes     => $pe_agent_classes + $pe_agent_new_classes,
  environment => 'production',
}

node_group { 'PE Master':
  ensure => 'present',
  classes     => $pe_master_classes + $pe_master_new_classes,
  rule   => ['or',
    ['=', ['trusted', 'extensions', 'pp_role'], 'puppet::master::mom'],
    ['=', ['trusted', 'extensions', 'pp_role'], 'puppet::master::cm'],
  ],
}

node_group { 'PE Master of Masters':
  ensure               => 'present',
  classes              => {'role::puppet::master::mom' => {}, },
  environment          => 'production',
  override_environment => false,
  parent               => 'PE Master',
  rule                 =>  ['=', ['trusted', 'extensions', 'pp_role'], 'puppet::master::mom'],
}

node_group { 'PE Compile Master':
  ensure               => 'present',
  classes              => {
    'pe_repo'                  => {
      compile_master_pool_address => 'puppet.${domain}',
    },
    'role::puppet::master::cm' => {},
  },
  environment          => 'production',
  override_environment => false,
  parent               => 'PE Master',
  rule                 => ['=', ['trusted', 'extensions', 'pp_role'], 'puppet::master::cm']
}
