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

variable "do_master_size" {
  type        = "string"
  description = "DigitalOcean droplet size for the Puppet Master"
  default     = "s-4vcpu-8gb"
}

variable "do_ssh_fingerprints" {
  type        = list(string)
  description = "DigitalOcean SSH key fingerprint"
}

variable "download_installer" {
  type        = "string"
  description = "Download PE installer (YES/no)"
  default     = "yes"
}

variable "console_pwd" {
  type        = "string"
  description = "PE admin password (also used for Grafana)"
  default     = "puppetlabs"
}

variable "r10k_remote" {
  type        = "string"
  description = "Cotrol repo URL"
  default     = "https://github.com/puppetlabs/control-repo.git"
}

variable "autosign_pwd" {
  type        = "string"
  description = "PE certificate auto-sign password"
  default     = "you.shall.not.sign"
}

data "template_file" "custom_pe_conf" {
  template = "${file("${path.module}/templates/custom_pe.conf.tpl")}"
  vars = {
    console_pwd = "${var.console_pwd}"
    r10k_remote = "${var.r10k_remote}"
    domain      = "${var.do_domain}"
  }
}

data "template_file" "master_userdata" {
  template = "${file("${path.module}/templates/cloud-init/master.tpl")}"
  vars = {
    domain = "${var.do_domain}"
    role   = "puppet::master::master"
  }
}

data "template_file" "provision_master_script" {
  template = "${file("${path.module}/templates/scripts/provision_master.sh.tpl")}"
  vars = {
    #url                = "https://pm.puppetlabs.com/cgi-bin/download.cgi?dist=el&rel=7&arch=x86_64&ver="
    url                = "https://pm.puppetlabs.com/cgi-bin/download.cgi?dist=ubuntu&rel=18.04&arch=amd64&ver="
    pe_ver             = "latest"
    domain             = "${var.do_domain}"
    download_installer = "${var.download_installer}"
    console_pwd        = "${var.console_pwd}"
  }
}

data "template_file" "master_classification" {
  template = "${file("${path.module}/templates/manifests/classification.pp.tpl")}"
  vars = {
    domain = "${var.do_domain}"
  }
}

data "template_file" "master_hiera_data" {
  template = "${file("${path.module}/templates/hiera/common.yaml.tpl")}"
  vars = {
    domain       = "${var.do_domain}"
    console_pwd  = "${var.console_pwd}"
    autosign_pwd = "${var.autosign_pwd}"
  }
}

