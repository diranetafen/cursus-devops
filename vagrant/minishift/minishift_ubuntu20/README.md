## This stack is used for OpenShift Training
To use this stack you must install virtualbox and vagrant and then use `vagrant up`

[![Déployez OpenShift sur votre PC](https://user-images.githubusercontent.com/18481009/173793559-a4619640-4e9a-4047-b51d-11ca4b3834d6.PNG)](https://youtu.be/25UaRP72hAk "Déployez OpenShift sur votre PC")

[minishift](https://github.com/minishift/minishift) is a lite version of openshift 3.x that enable deployment of single node deployment (all-in-one)
After the stack end execution (the deployment may takes more than 10 minutes, so be patient), you will get the URL for OpenShift console and credentials

<img width="700" alt="stack output" src="https://user-images.githubusercontent.com/18481009/173579587-7d32d00a-f0aa-4209-90c5-eebfdfafc76c.PNG">

To use OpenShift Cli (aka ***oc***), you must 

 - login on minishift VM (not openshift VM) : `vagrant ssh minishift`
 - switch to root user : `sudo su -`
 - use oc cli : `oc login -u system:admin`
<img width="700" alt="sudo" src="https://user-images.githubusercontent.com/18481009/173580756-120df34a-10ed-48a2-983f-c3e1a5d5f85f.PNG">
