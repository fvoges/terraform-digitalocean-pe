variable "centos_agent_count" {
  type        = "string"
  description = "Number of CentOS Puppet Agents"
  default     = "0"
}

variable "do_centos_agent_image" {
  type        = "string"
  description = "DigitalOcean CentOS agent image"
  default     = "centos-7-x64"
}

data "template_file" "centos_agent_userdata" {
  count    = "${var.centos_agent_count}"
  template = "${file("${path.module}/templates/cloud-init/centos_agent.tpl")}"

  vars = {
    hostname     = "${format("centos-agent%02d", count.index + 1)}"
    role         = "agent"
    domain       = "${var.do_domain}"
    autosign_pwd = "${var.autosign_pwd}"
  }
}

resource "digitalocean_droplet" "centos_agent" {
  count              = "${var.centos_agent_count}"
  image              = "${var.do_centos_agent_image}"
  name               = "${format("centos-agent%02d", count.index + 1)}"
  region             = "${var.do_region}"
  size               = "${var.do_agent_size}"
  private_networking = true
  monitoring         = true
  resize_disk        = true
  ipv6               = true
  ssh_keys = [
    "${var.do_ssh_fingerprint}"
  ]
  tags      = ["all", "agent", "ssh4all"]
  user_data = "${element(data.template_file.centos_agent_userdata.*.rendered, count.index)}"

  connection {
    host    = self.ipv4_address
    user    = "root"
    type    = "ssh"
#    agent   = true
    timeout = "2m"
  }

  provisioner "puppet" {
    server             = aws_instance.puppetmaster.public_dns
    server_user        = "ubuntu"
    extension_requests = {
      pp_application = var.pp_application
      pp_datacenter  = var.pp_datacenter
      pp_environment = var.pp_environment
      pp_role        = var.pp_role
    }
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'waiting for boot-finished'; sleep 5; done;",
    ]
  }

  depends_on = ["digitalocean_record.puppet"]
}

resource "digitalocean_record" "centos_agent" {
  count      = "${var.centos_agent_count}"
  domain     = "${var.do_domain}"
  type       = "A"
  depends_on = ["digitalocean_record.puppet"]
  name       = "${element(digitalocean_droplet.centos_agent.*.name, count.index)}"
  value      = "${element(digitalocean_droplet.centos_agent.*.ipv4_address, count.index)}"
  ttl        = 60
}

# cleanup node data/cert when destroying
resource "null_resource" "centos_agent_cleanup" {
  count = "${var.centos_agent_count}"

  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "/opt/puppetlabs/puppet/bin/puppet node purge ${element(digitalocean_droplet.centos_agent.*.name, count.index)}.${var.do_domain}"
    ]

    connection {
      host    = "${digitalocean_droplet.master.ipv4_address}"
      user    = "root"
      type    = "ssh"
#      agent   = true
      timeout = "2m"
    }
  }
}
