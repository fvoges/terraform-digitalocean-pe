output "ipv4_address" {
  value = digitalocean_droplet.master.ipv4_address
}

output "name" {
  value = "${digitalocean_droplet.master.name}.${var.do_domain}"
}
