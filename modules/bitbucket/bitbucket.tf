variable "bitbucket_count" {
  type        = "string"
  description = "Number of BitBucket servers"
  default     = "0"
}

variable "do_bitbucket_size" {
  type        = "string"
  description = "DigitalOcean droplet size for the BitBucket server"
  default     = "s-1vcpu-3gb"
}

variable "do_bitbucket_image" {
  type        = "string"
  description = "DigitalOcean BitBucket server image"
  default     = "ubuntu-18-04-x64"
}

data "template_file" "bitbucket_userdata" {
  count    = "${var.bitbucket_count}"
  template = "${file("${path.module}/templates/cloud-init/bitbucket.tpl")}"

  vars = {
    hostname     = "${format("bitbucket%02d", count.index + 1)}"
    role         = "agent"
    domain       = "${var.do_domain}"
    autosign_pwd = "${var.autosign_pwd}"
  }
}

resource "digitalocean_droplet" "bitbucket" {
  count              = "${var.bitbucket_count}"
  image              = "${var.do_bitbucket_image}"
  name               = "${format("bitbucket%02d", count.index + 1)}"
  region             = "${var.do_region}"
  size               = "${var.do_bitbucket_size}"
  private_networking = true
  monitoring         = true
  resize_disk        = true
  ipv6               = true
  ssh_keys = [
    "${var.do_ssh_fingerprint}"
  ]
  tags      = ["all", "https", "http"]
  user_data = "${element(data.template_file.bitbucket_userdata.*.rendered, count.index)}"

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

resource "digitalocean_record" "bitbucket" {
  count  = "${var.bitbucket_count}"
  domain = "${var.do_domain}"
  type   = "A"
  name   = "${element(digitalocean_droplet.bitbucket.*.name, count.index)}"
  value  = "${element(digitalocean_droplet.bitbucket.*.ipv4_address, count.index)}"
  ttl    = 60
}

# cleanup node data/cert when destroying
resource "null_resource" "bitbucket_cleanup" {
  count = "${var.bitbucket_count}"

  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "/opt/puppetlabs/puppet/bin/puppet node purge ${element(digitalocean_droplet.bitbucket.*.name, count.index)}.${var.do_domain}"
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
