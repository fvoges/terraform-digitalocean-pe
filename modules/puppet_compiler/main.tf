
resource "digitalocean_droplet" "compiler" {
  count              = "${var.compiler_count}"
  image              = "${var.do_image}"
  name               = "${format("puppet%02d", count.index + 1)}"
  region             = "${var.do_region}"
  size               = "${var.do_compiler_size}"
  private_networking = true
  monitoring         = true
  resize_disk        = true
  ipv6               = true
  ssh_keys  = var.do_ssh_fingerprints
  tags      = ["all", "puppet-compiler", "ssh4all"]
  user_data = "${element(data.template_file.compiler_userdata.*.rendered, count.index)}"

  connection {
    host    = self.ipv4_address
    user    = "root"
    type    = "ssh"
    agent   = true
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /tmp/provisioning_done ]; do echo 'waiting for boot-finished'; sleep 5; done;",
      "rm -f /tmp/provisioning_done",
    ]
  }
}

resource "digitalocean_record" "compiler" {
  count  = var.compiler_count
  domain = var.do_domain
  type   = "A"
  name   = "${element(digitalocean_droplet.compiler.*.name, count.index)}"
  value  = "${element(digitalocean_droplet.compiler.*.ipv4_address, count.index)}"
  ttl    = 60
}

# autosign doesn't allow dns alt names, so we have to go old school
resource "null_resource" "compiler_certs" {
  count = "${var.compiler_count}"

  connection {
    host    = var.master_ipv4
    user    = "root"
    type    = "ssh"
    agent   = true
    timeout = "2m"
  }

  provisioner "remote-exec" {
    when       = "create"
    on_failure = "continue"
    inline = [
      # "/opt/puppetlabs/puppet/bin/puppet cert sign --allow-dns-alt-names ${element(digitalocean_droplet.compiler.*.name, count.index)}.${var.do_domain}"
      "/opt/puppetlabs/bin/puppetserver ca sign --certname ${element(digitalocean_droplet.compiler.*.name, count.index)}.${var.do_domain}"
    ]
  }
  provisioner "remote-exec" {
    when       = "destroy"
    on_failure = "continue"
    inline = [
      "/opt/puppetlabs/puppet/bin/puppet node purge ${element(digitalocean_droplet.compiler.*.name, count.index)}.${var.do_domain}"
    ]
  }
}

resource "digitalocean_loadbalancer" "puppet" {
  count       = var.compiler_count > 0 ? 1 : 0
  name        = "puppet"
  region      = var.do_region
  algorithm   = "least_connections"
  droplet_ids = digitalocean_droplet.compiler.*.id

  forwarding_rule {
    entry_port     = 8140
    entry_protocol = "tcp"

    target_port     = 8140
    target_protocol = "tcp"
  }

  forwarding_rule {
    entry_port     = 8142
    entry_protocol = "tcp"

    target_port     = 8142
    target_protocol = "tcp"
  }

  healthcheck {
    port     = 8140
    protocol = "tcp"
  }
}

resource "digitalocean_record" "puppet" {
  domain = "${var.do_domain}"
  type   = "A"
  name   = var.compiler_count > 0 ? digitalocean_loadbalancer.puppet[0].name : var.master
  value  = var.compiler_count > 0 ? digitalocean_loadbalancer.puppet[0].ip : var.master_ipv4
  ttl    = 60
}

resource "digitalocean_firewall" "compiler" {
  name = "puppet-compiler"
  tags = ["puppet-compiler"]

  inbound_rule {
      protocol    = "tcp"
      port_range  = "8140"
      source_tags = ["puppet-compiler", "puppet-agent"]
  }

  inbound_rule {
      protocol    = "tcp"
      port_range  = "8142"
      source_tags = ["puppet-compiler", "puppet-agent"]
  }
}
