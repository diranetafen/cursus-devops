#!/bin/bash
# Create log file
LOGS_FILE="/tmp/install_jenkins.log"
echo -e "You will find Vagrant provisioning logs below" > ${LOGS_FILE}
sudo apt-get update -y

# Install Jenkins repository and upgrade system
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update -y
sudo apt-get upgrade -y

# Add required dependencies for the Jenkins package
sudo apt-get install -y openjdk-11-jdk sshpass vim

# Create provisioning script on remote server and launch it
cat > /root/install_jenkins.sh <<EOF
#!/bin/bash
# Set variables for script
JENKINS_HOME="/var/lib/jenkins"
NOMBRE_WORKER=\$2
echo worker number : \$NOMBRE_WORKER
# Enable local DNS on each server
echo -e "192.168.99.10 jenkins" >> /etc/hosts
i=1
while [ \$i -le \$NOMBRE_WORKER ]
do
  echo -e "192.168.99.1\${i} worker\${i}" >> /etc/hosts
  let i=i+1
done
# Declare function
function waitforssh {
    sshpass -p vagrant ssh -o StrictHostKeyChecking=no vagrant@\$1 echo ssh is up on \$1
    while test \$? -gt 0
    do
        sleep 5 
        echo -e "SSH server not started on \$1 host. Trying again later in 5 seconds..."
        sshpass -p vagrant ssh -o StrictHostKeyChecking=no vagrant@\$1 echo ssh is up on \$1
    done
}

i=1 
if [ "\$1" == "master" ]
then 
    # Install and start Jenkins server
    sudo apt-get install -y jenkins
    sudo systemctl daemon-reload
    sudo systemctl enable jenkins
    sudo systemctl start jenkins

    ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y >/dev/null 2>&1
    mkdir -p \${JENKINS_HOME}/.ssh
    sudo mv /root/.ssh/id_rsa* \${JENKINS_HOME}/.ssh/
    sudo chown -R jenkins:jenkins \${JENKINS_HOME}/.ssh

    while [ \$i -le \${NOMBRE_WORKER} ]
    do
        waitforssh worker\${i}
        sshpass -p vagrant ssh -o StrictHostKeyChecking=no vagrant@worker\${i}  "sudo su -c \" useradd -d \${JENKINS_HOME} jenkins && mkdir -p \${JENKINS_HOME}/.ssh && touch \${JENKINS_HOME}/.ssh/authorized_keys && chown -R jenkins:jenkins \${JENKINS_HOME}/.ssh/ \"" 
        cat \${JENKINS_HOME}/.ssh/id_rsa.pub | sshpass -p vagrant ssh -o StrictHostKeyChecking=no vagrant@worker\${i} "sudo su -c \"cat >> ~jenkins/.ssh/authorized_keys\""
        let i=i+1
    done

    echo -e "For this Stack, you will use \$(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address\n"
    echo "To finish Jenkins installation, please go to your preferred browser; launch this URL: http://\$(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p'):8080 and paste this secret: \$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"    
fi

if [ "\$1" == "worker" ]
then 
    echo -e "Nothing to do, it is a worker node"
fi
EOF

chmod +x /root/install_jenkins.sh
/root/install_jenkins.sh $1 $2 1>>${LOGS_FILE} 2>&1 &
