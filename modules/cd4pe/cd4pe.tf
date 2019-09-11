variable "cd4pe_count" {
  type        = "string"
  description = "Number of CD4PE servers"
  default     = "0"
}

variable "do_cd4pe_size" {
  type        = "string"
  description = "DigitalOcean droplet size for the CD4PE server"
  default     = "s-1vcpu-3gb"
}

variable "do_cd4pe_image" {
  type        = "string"
  description = "DigitalOcean CD4PE server image"
  default     = "ubuntu-18-04-x64"
}

data "template_file" "cd4pe_userdata" {
  count    = "${var.cd4pe_count}"
  template = "${file("${path.module}/templates/cloud-init/cd4pe.tpl")}"

  vars = {
    hostname     = "${format("cd4pe%02d", count.index + 1)}"
    role         = "agent"
    domain       = "${var.do_domain}"
    autosign_pwd = "${var.autosign_pwd}"
  }
}

resource "digitalocean_droplet" "cd4pe" {
  count              = "${var.cd4pe_count}"
  image              = "${var.do_cd4pe_image}"
  name               = "${format("cd4pe%02d", count.index + 1)}"
  region             = "${var.do_region}"
  size               = "${var.do_cd4pe_size}"
  private_networking = true
  monitoring         = true
  resize_disk        = true
  ipv6               = true
  ssh_keys = [
    "${var.do_ssh_fingerprint}"
  ]
  tags      = ["all", "https", "http"]
  user_data = "${element(data.template_file.cd4pe_userdata.*.rendered, count.index)}"

  lifecycle {
    # prevent_destroy = true
    ignore_changes = all
  }

  connection {
    host    = self.ipv4_address
    user    = "root"
    type    = "ssh"
#    agent   = true
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'waiting for boot-finished'; sleep 5; done;",
    ]
  }

  depends_on = ["digitalocean_loadbalancer.puppet"]
}

resource "digitalocean_record" "cd4pe" {
  count  = "${var.cd4pe_count}"
  domain = "${var.do_domain}"
  type   = "A"
  name   = "${element(digitalocean_droplet.cd4pe.*.name, count.index)}"
  value  = "${element(digitalocean_droplet.cd4pe.*.ipv4_address, count.index)}"
  ttl    = 60
}

# cleanup node data/cert when destroying
resource "null_resource" "cd4pe_cleanup" {
  count = "${var.cd4pe_count}"

  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "/opt/puppetlabs/puppet/bin/puppet node purge ${element(digitalocean_droplet.cd4pe.*.name, count.index)}.${var.do_domain}"
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
