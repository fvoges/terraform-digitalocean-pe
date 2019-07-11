#!/bin/bash
#setenforce 0
DOWNLOAD_INSTALLER=${download_installer}
mkdir -p /etc/puppetlabs/puppet
cp /opt/terraform/data/csr_attributes.yaml /etc/puppetlabs/puppet/csr_attributes.yaml
/usr/local/bin/puppet --version 2&> /dev/null
if [ $? -ne 0 ]; then
  if [ "$DOWNLOAD_INSTALLER" == "yes" ]
  then
    echo "Puppet download url is ${url}${pe_ver}"
    wget --quiet --progress=bar:force --content-disposition --continue "${url}${pe_ver}"
    if [ $? -ne 0 ]; then
      echo "Puppet failed to download"
      exit 2
    fi
  fi
  tar xzvf puppet-enterprise-*.tar* -C /root
  /root/puppet-enterprise-*/puppet-enterprise-installer -c /opt/terraform/data/custom-pe.conf -y
  rm -fr /root/puppet-enterprise-*
fi
/opt/puppetlabs/puppet/bin/puppet agent -t
echo "${console_pwd}" | /opt/puppetlabs/bin/puppet-access login admin --lifetime 90d && \
echo "Deploying puppet code from version control server" && \
/opt/puppetlabs/bin/puppet-code deploy --all --wait && \
echo "Clearing environments cache" && \
/opt/terraform/scripts/update_environments.sh && \
echo "Clearing classifier cache" && \
/opt/terraform/scripts/update_classes.sh && \
# /opt/puppetlabs/puppet/bin/puppet apply /opt/terraform/manifests/classification.pp && \
echo "Clearing environments cache" && \
/opt/terraform/scripts/update_environments.sh && \
echo "Clearing classifier cache" && \
/opt/terraform/scripts/update_classes.sh
/usr/local/bin/puppet agent -t
exit 0
