variable "ubuntu_agent_count" {
  type        = "string"
  description = "Number of Ubuntu Puppet Agents"
  default     = "0"
}

variable "do_ubuntu_agent_image" {
  type        = "string"
  description = "DigitalOcean Ubuntu Agent image"
  default     = "ubuntu-18-04-x64"
}

data "template_file" "ubuntu_agent_userdata" {
  count    = "${var.ubuntu_agent_count}"
  template = "${file("${path.module}/templates/cloud-init/ubuntu_agent.tpl")}"

  vars = {
    hostname     = "${format("ubuntu-agent%02d", count.index + 1)}"
    role         = "agent"
    domain       = "${var.do_domain}"
    autosign_pwd = "${var.autosign_pwd}"
  }
}

resource "digitalocean_droplet" "ubuntu_agent" {
  count              = "${var.ubuntu_agent_count}"
  image              = "${var.do_ubuntu_agent_image}"
  name               = "${format("ubuntu-agent%02d", count.index + 1)}"
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
  user_data = "${element(data.template_file.ubuntu_agent_userdata.*.rendered, count.index)}"

  connection {
    host    = self.ipv4_address
    user    = "root"
    type    = "ssh"
    agent   = true
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'waiting for boot-finished'; sleep 5; done;",
    ]
  }

  depends_on = ["digitalocean_record.puppet"]
}

resource "digitalocean_record" "ubuntu_agent" {
  count  = "${var.ubuntu_agent_count}"
  domain = "${var.do_domain}"
  type   = "A"
  name   = "${element(digitalocean_droplet.ubuntu_agent.*.name, count.index)}"
  value  = "${element(digitalocean_droplet.ubuntu_agent.*.ipv4_address, count.index)}"
  ttl    = 60
}

# cleanup node data/cert when destroying
resource "null_resource" "ubuntu_agent_cleanup" {
  count = "${var.ubuntu_agent_count}"

  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "/opt/puppetlabs/puppet/bin/puppet node purge ${element(digitalocean_droplet.ubuntu_agent.*.name, count.index)}.${var.do_domain}"
    ]

    connection {
      host    = "${digitalocean_droplet.master.ipv4_address}"
      user    = "root"
      type    = "ssh"
      agent   = true
      timeout = "2m"
    }
  }
}
