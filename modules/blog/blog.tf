variable "blog_count" {
  type        = "string"
  description = "Number of blog servers"
  default     = "0"
}

variable "do_blog_size" {
  type        = "string"
  description = "DigitalOcean droplet size for the blog server"
  default     = "s-1vcpu-1gb"
}

variable "do_blog_image" {
  type        = "string"
  description = "DigitalOcean blog server image"
  default     = "centos-7-x64"
}

data "template_file" "blog_userdata" {
  count    = "${var.blog_count}"
  template = "${file("${path.module}/templates/cloud-init/centos_agent.tpl")}"

  vars = {
    hostname     = "${format("blog%02d", count.index + 1)}"
    role         = "blog"
    domain       = "${var.do_domain}"
    autosign_pwd = "${var.autosign_pwd}"
  }
}

resource "digitalocean_droplet" "blog" {
  count              = "${var.blog_count}"
  image              = "${var.do_blog_image}"
  name               = "${format("blog%02d", count.index + 1)}"
  region             = "${var.do_region}"
  size               = "${var.do_blog_size}"
  private_networking = true
  monitoring         = true
  resize_disk        = true
  ipv6               = true
  ssh_keys = [
    "${var.do_ssh_fingerprint}"
  ]
  tags      = ["all", "http", "https", "ssh4all", ]
  user_data = "${element(data.template_file.blog_userdata.*.rendered, count.index)}"

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

  depends_on = ["digitalocean_loadbalancer.puppet"]
}

resource "digitalocean_record" "blog" {
  count  = "${var.blog_count}"
  domain = "${var.do_domain}"
  type   = "A"
  name   = "${element(digitalocean_droplet.blog.*.name, count.index)}"
  value  = "${element(digitalocean_droplet.blog.*.ipv4_address, count.index)}"
  ttl    = 60
}

# cleanup node data/cert when destroying
resource "null_resource" "blog_cleanup" {
  count = "${var.blog_count}"

  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "/opt/puppetlabs/puppet/bin/puppet node purge ${element(digitalocean_droplet.blog.*.name, count.index)}.${var.do_domain}"
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
