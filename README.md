# Terraform PE environment

This [Terraform](https://terraform.io/) files will setup [Puppet Enterprise](https://puppet.com/) in a multi-master environment on [DigitalOcean](https://digitalocean.com/).

The architrecture used is Monolithic Master plus Compile Masters running on Ubuntu 16.04 LTS. The Compile Masters are load balanced using DigitalOcena's load balancer service.

Requiremets:
  - DigitalOcean Account
  - DigitalOcean API token ([Personal access token](https://cloud.digitalocean.com/settings/api/tokens))
  - A DNS domain managed by your DigitalOcean account
  - A Puppet control repo with the following classes
    + `role::puppet::master::mom` - Used for the Master of Masters
    + `role::puppet::master::cm` -  Used for the Compile Masters
  - The fingerprint for your SSH key configured in DigitalOcean
