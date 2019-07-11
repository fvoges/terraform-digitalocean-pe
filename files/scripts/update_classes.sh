#!/bin/bash
CERT=$(/opt/puppetlabs/puppet/bin/puppet config print hostcert)
KEY=$(/opt/puppetlabs/puppet/bin/puppet config print hostprivkey)
CACERT=$(/opt/puppetlabs/puppet/bin/puppet config print localcacert)
MASTER=$(/opt/puppetlabs/puppet/bin/puppet config print certname)

curl -s -X POST --cert $CERT --key $KEY --cacert $CACERT https://${MASTER}:4433/classifier-api/v1/update-classes
