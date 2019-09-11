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

  do_ssh_fingerprints = var.do_ssh_fingerprints
}
}

output "puppet_master_name" {
  value = "puppet_master.name"
}
