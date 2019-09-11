variable "pe_ver" {
  type        = "string"
  default     = "2019.1"
  description = "Puppet Enterprise version"
}

variable "do_master_size" {
  type        = "string"
  description = "DigitalOcean droplet size for the Puppet Master"
  default     = "s-4vcpu-8gb"
}

variable "do_token" {
  type        = "string"
  description = "DigitalOcean API Token"
}

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

variable "do_agent_size" {
  type        = "string"
  description = "DigitalOcean droplet size for the Puppet Agents"
  default     = "s-1vcpu-1gb"
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

variable "compiler_count" {
  type        = "string"
  description = "Number of Compile Masters"
  default     = "2"
}
