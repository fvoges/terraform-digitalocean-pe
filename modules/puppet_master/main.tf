resource "digitalocean_tag" "master" {
  name = "puppet-master"
}

resource "digitalocean_tag" "compiler" {
  name = "puppet-compiler"
}

resource "digitalocean_tag" "agent" {
  name = "puppet-agent"
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
  ssh_keys           = var.do_ssh_fingerprints
  ]
  tags      = ["all", "puppet-master", "ssh4all"]
  user_data = "${data.template_file.master_userdata.rendered}"

  depends_on = [
    digitalocean_tag.master,
    digitalocean_tag.compiler,
    digitalocean_tag.agent
  ]

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
    source      = "${path.module}/files/data/master_csr_attributes.yaml"
    destination = "/opt/terraform/data/csr_attributes.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/files/scripts"
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

resource "digitalocean_firewall" "master" {
  name = "puppet-master"
  tags = ["puppet-master"]


  inbound_rule {
      protocol         = "tcp"
      port_range       = "443"
      source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
      protocol         = "tcp"
      port_range       = "8170"
      source_addresses = ["0.0.0.0/0", "::/0"]
  }

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

  inbound_rule {
      protocol    = "tcp"
      port_range  = "4433"
      source_tags = ["puppet-compiler"]
  }

  inbound_rule {
      protocol    = "tcp"
      port_range  = "5432"
      source_tags = ["puppet-compiler"]
  }

  inbound_rule {
      protocol    = "tcp"
      port_range  = "8081"
      source_tags = ["puppet-compiler"]
  }

  inbound_rule {
      protocol    = "tcp"
      port_range  = "8143"
      source_tags = ["puppet-compiler"]
  }
}
