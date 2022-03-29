#!/bin/bash
sudo yum -y update

# install docker
echo "VM ready"
echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
