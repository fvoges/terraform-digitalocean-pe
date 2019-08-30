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

  do_region          = var.do_region
  do_domain          = var.do_domain
  do_ssh_fingerprint = var.do_ssh_fingerprint
}

output "puppet_master_name" {
  value = "puppet_master.name"
}
