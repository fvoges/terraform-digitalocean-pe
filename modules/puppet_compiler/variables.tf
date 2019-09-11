variable "do_ssh_fingerprints" {
  type        = list(string)
  description = "DigitalOcean SSH key fingerprint"
}

variable "do_domain" {
  type        = "string"
  description = "DigitalOcean managed DNS domain"
}

variable "do_region" {
  type        = "string"
  description = "DigitalOcean region"
  default     = "lon1"
}

variable "do_image" {
  type        = "string"
  description = "DigitalOcean Puppet infrastructure image"
  default     = "ubuntu-18-04-x64"
}

variable "do_compiler_size" {
  type        = "string"
  description = "DigitalOcean droplet size for the Puppet Compilers"
  default     = "s-2vcpu-4gb"
}

variable "autosign_pwd" {
  type        = "string"
  description = "PE certificate auto-sign password"
  default     = "you.shall.not.sign"
}

variable "compiler_count" {
  type        = "string"
  description = "Number of Compile Masters"
  default     = "2"
}

data "template_file" "compiler_userdata" {
  count    = "${var.compiler_count}"
  template = "${file("${path.module}/templates/cloud-init/compiler.tpl")}"

  vars = {
    hostname     = "${format("puppet%02d", count.index + 1)}"
    role         = "puppet::master::compiler"
    domain       = "${var.do_domain}"
    autosign_pwd = "${var.autosign_pwd}"
  }
}
