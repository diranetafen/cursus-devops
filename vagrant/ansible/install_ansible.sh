
#!/bin/bash
yum -y update
yum -y install epel-release
yum install -y python3
if [ $1 == "master" ]
then

  # install ansible
  curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3
  /usr/local/bin/pip3 install ansible
  yum install -y sshpass
fi
echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
