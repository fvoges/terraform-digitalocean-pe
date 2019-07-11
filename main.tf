provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_droplet" "master" {
  image              = "${var.do_image}"
  name               = "master"
  region             = "${var.do_region}"
  size               = "${var.do_master_size}"
  private_networking = true
  monitoring         = true
  resize_disk        = true
  ipv6               = true
  ssh_keys = [
    "${var.do_ssh_fingerprint}"
  ]
  tags      = ["all", "puppet-master", "ssh4all"]
  user_data = "${data.template_file.master_userdata.rendered}"

  lifecycle {
    # prevent_destroy = true
    ignore_changes = all
  }

  connection {
    host    = self.ipv4_address
    user    = "root"
    type    = "ssh"
    agent   = true
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /opt/terraform/data /opt/terraform/manifests /opt/terraform/scripts /etc/puppetlabs/code/environments/production/data",
    ]
  }

  provisioner "file" {
    content     = "${data.template_file.custom_pe_conf.rendered}"
    destination = "/opt/terraform/data/custom-pe.conf"
  }

  provisioner "file" {
    source      = "files/data/master_csr_attributes.yaml"
    destination = "/opt/terraform/data/csr_attributes.yaml"
  }

  provisioner "file" {
    source      = "files/scripts"
    destination = "/opt/terraform"
  }

  provisioner "file" {
    content     = "${data.template_file.provision_master_script.rendered}"
    destination = "/opt/terraform/scripts/provision_master.sh"
  }

  provisioner "file" {
    content     = "${data.template_file.master_classification.rendered}"
    destination = "/opt/terraform/manifests/classification.pp"
  }

  provisioner "file" {
    content     = "${data.template_file.master_hiera_data.rendered}"
    destination = "/opt/terraform/data/common.yaml"
  }

  provisioner "file" {
    content     = "${data.template_file.master_hiera_data.rendered}"
    destination = "/etc/puppetlabs/code/environments/production/data/common.yaml"
  }

  # provisioner "file" {
  #   source      = "~/.vagrant.d/pe_builds/puppet-enterprise-2018.1.2-ubuntu-16.04-amd64.tar.gz"
  #   destination = "/root/puppet-enterprise-2018.1.2-ubuntu-16.04-amd64.tar.gz"
  # }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'waiting for boot-finished'; sleep 5; done;",
    ]
  }

  # Move master provisioning to remote-exec to allow master to
  # be fully provisioned before creating nodes
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /opt/terraform/scripts/*.sh",
      "sudo /opt/terraform/scripts/provision_master.sh",
    ]
  }
}

resource "digitalocean_record" "master" {
  domain = "${var.do_domain}"
  type   = "A"
  name   = "${digitalocean_droplet.master.name}"
  value  = "${digitalocean_droplet.master.ipv4_address}"
  ttl    = 60
}

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
  ssh_keys = [
    "${var.do_ssh_fingerprint}"
  ]
  tags      = ["all", "puppet-compile", "ssh4all"]
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

  depends_on = ["digitalocean_droplet.master"]
}

resource "digitalocean_record" "compiler" {
  count  = "${var.compiler_count}"
  domain = "${var.do_domain}"
  type   = "A"
  name   = "${element(digitalocean_droplet.compiler.*.name, count.index)}"
  value  = "${element(digitalocean_droplet.compiler.*.ipv4_address, count.index)}"
  ttl    = 60
}

# autosign doesn't allow dns alt names, so we have to go old school
resource "null_resource" "compiler_certs" {
  count = "${var.compiler_count}"

  connection {
    host    = "${digitalocean_droplet.master.ipv4_address}"
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
  name   = var.compiler_count > 0 ? digitalocean_loadbalancer.puppet[0].name : digitalocean_droplet.master.name
  value  = var.compiler_count > 0 ? digitalocean_loadbalancer.puppet[0].ip : digitalocean_droplet.master.ipv4_address
  ttl    = 60
}

