provider "digitalocean" {
  token = "${var.do_token}"
}

terraform {
  backend "remote" {
    organization = "shadowsun"

    workspaces {
      name = "learning"
    }
  }
}

module "puppet_master" {
  source = "./modules/puppet_master"

  do_region           = var.do_region
  do_domain           = var.do_domain
  do_ssh_fingerprints = var.do_ssh_fingerprints
}

module "puppet_compiler" {
  source = "./modules/puppet_compiler"

  compiler_count      = "1"
  master              = module.puppet_master.name
  master_ipv4         = module.puppet_master.ipv4_address
  do_region           = var.do_region
  do_domain           = var.do_domain
  do_ssh_fingerprints = var.do_ssh_fingerprints
}

output "puppet_master_name" {
  value = module.puppet_master.name
}
output "puppet_master_ipv4_address" {
  value = module.puppet_master.ipv4_address
}
