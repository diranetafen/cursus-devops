#!/bin/bash
echo "###################################################"
echo "Install Puppet requirements"
echo "###################################################"
yum -y update
yum -y install epel-release
yum install -y https://yum.puppet.com/puppet-release-el-8.noarch.rpm
if [ $1 == "master" ]
then
        echo "###################################################"
        echo "Start Master Puppet Installation"
        echo "###################################################"
        yum install -y puppetserver-7.2.1-1.el8.noarch
        echo "127.0.2.1 puppet puppetdb puppet.home" >> /etc/hosts
        systemctl enable --now puppetserver puppet
        systemctl enable --now firewalld
        firewall-cmd --zone=public --permanent --add-service=http --add-service=https --add-service=ssh
        firewall-cmd --zone=public --permanent --add-port 8140/tcp
        firewall-cmd --reload
        echo "###################################################"
        echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
        echo "###################################################"
else
        echo "###################################################"
        echo "Start Agent Puppet Installation"
        echo "###################################################"
        yum install -y puppet-agent-7.9.0-1.el8.x86_64 puppet-bolt-3.16.0-1.el8.x86_64
        echo "$2 puppet" >> /etc/hosts
        connection="ko"
        while [ $connection == "ko"  ]
        do
          systemctl enable --now puppet
          /opt/puppetlabs/bin/bolt command run '/opt/puppetlabs/bin/puppetserver ca sign --all' -t 192.168.99.10 -u vagrant -p vagrant --no-host-key-check --run-as root
          puppet agent --test > /tmp/test-connection.log
          if grep -q "Caching catalog" /tmp/test-connection.log ;
          then
            echo "Connection to master succeded"
            connection="ok"
          fi
          rm /tmp/test-connection.log
        done
        echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
fi
