#!/bin/bash
VERSION_STRING="5:25.0.3-1~ubuntu.22.04~jammy"
ENABLE_ZSH=true

# --- Install Docker ---
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker vagrant
sudo echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

# --- Install ZSH ---
if [[ !(-z "$ENABLE_ZSH")  &&  ($ENABLE_ZSH == "true") ]]
then
    echo "Installing zsh"
    sudo apt -y install zsh git
    echo "vagrant" | chsh -s /bin/zsh vagrant
    su - vagrant  -c  'echo "Y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    su - vagrant  -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    sed -i 's/^plugins=/#&/' /home/vagrant/.zshrc
    echo "plugins=(git docker docker-compose colored-man-pages aliases copyfile copypath dotenv zsh-syntax-highlighting jsontools)" >> /home/vagrant/.zshrc
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME='agnoster'/g"  /home/vagrant/.zshrc
else
    echo "The zsh is not installed on this server"
fi

# --- Jenkins Multi-Node Docker Deployment ---

WORKDIR="/home/vagrant/jenkins-docker"
mkdir -p $WORKDIR/{jenkins-master/init.groovy.d,jenkins-agent}

# docker-compose.yml
cat > $WORKDIR/docker-compose.yml <<'EOF'
version: '3.8'

services:
  jenkins-master:
    build: ./jenkins-master
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
    networks:
      - jenkins

  agent1:
    build: ./jenkins-agent
    container_name: agent1
    networks:
      - jenkins

  agent2:
    build: ./jenkins-agent
    container_name: agent2
    networks:
      - jenkins

volumes:
  jenkins_home:

networks:
  jenkins:
EOF

# Jenkins Master Dockerfile
cat > $WORKDIR/jenkins-master/Dockerfile <<'EOF'
FROM jenkins/jenkins:lts
USER root
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d
COPY init.groovy.d /usr/share/jenkins/ref/init.groovy.d
USER jenkins
EOF

# Groovy script to auto-register agents
cat > $WORKDIR/jenkins-master/init.groovy.d/create-agents.groovy <<'EOF'
import jenkins.model.*
import hudson.slaves.*

def jenkins = Jenkins.getInstance()

['agent1', 'agent2'].each { name ->
    def launcher = new JNLPLauncher()
    def agent = new DumbSlave(name, "/home/jenkins/agent", launcher)
    agent.numExecutors = 1
    agent.mode = Node.Mode.NORMAL
    agent.retentionStrategy = new RetentionStrategy.Always()
    agent.nodeProperties.clear()
    jenkins.addNode(agent)
    println("Created agent: ${name}")
}

jenkins.save()
EOF

# Jenkins Agent Dockerfile
cat > $WORKDIR/jenkins-agent/Dockerfile <<'EOF'
FROM jenkins/inbound-agent:latest
EOF

# Change ownership to vagrant
chown -R vagrant:vagrant $WORKDIR

# Launch Jenkins Stack
echo "Starting Jenkins stack using Docker Compose..."
su - vagrant -c "cd $WORKDIR && docker compose up -d --build"

# Display IP
echo "Access Jenkins at: http://$(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p'):8080"
