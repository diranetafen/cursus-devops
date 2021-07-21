# Step to use vagrant files

[![Déployez vos outils DevOps grâce à Vagrant](https://eazytraining.fr/wp-content/uploads/2021/07/vagrant-stack-eazytraining.png)](https://youtu.be/Z-Q62_OUqT4 "Déployez vos outils DevOps grâce à Vagrant")

## 1- Choose the tool you want to start and go to the corresponding folder
example : cd vagrant/jenkins
## 2- Install vagrant and virtualbox
Please refer to the official documentation based on your host OS and CPU
[Vagrant](https://www.vagrantup.com/docs/installation)
[Virtuabox](https://www.virtualbox.org/wiki/Downloads)
## 3- Install vagrant-hostsupdater plugin
```
vagrant plugin install vagrant-hostsupdater
```

## 4- Run your desire stack
```
vagrant up
```

## 5- Connect to the deployed VM
```
vagrant ssh <stack name>
```
## 6- Pick the ip that you must use for remote access from host (ssh, http ...)
Went until the stack end to deployment and pick the ip in the message bellow
```
For this Stack, you will use <IP Address> IP Address
```


## 7- Delete the stack
```
vagrant delete <stack name>
```
