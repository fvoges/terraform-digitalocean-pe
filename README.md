# Terraform Puppet Enterprise environment

This [Terraform](https://terraform.io/) files will setup [Puppet Enterprise](https://puppet.com/) in a multi-master environment on [DigitalOcean](https://digitalocean.com/).

The architecture used is Puppet Master plus Puppet Compilers running on Ubuntu 18.04 LTS. The Puppet Compilers are load balanced using DigitalOcean's load balancer service.

Requirements:

- DigitalOcean Account
- DigitalOcean API token ([Personal access token](https://cloud.digitalocean.com/settings/api/tokens))
- A DNS domain managed by your DigitalOcean account
- A Puppet control repo with the following classes
  - `role::puppet::master::mom` - Used for the Master of Masters
  - `role::puppet::master::cm` -  Used for the Compile Masters
- The fingerprint for your SSH key configured in DigitalOcean
