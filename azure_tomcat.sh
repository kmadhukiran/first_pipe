pipeline {
  agent any
  stages {
    stage ('Login') {
      steps {
        sh 'az login --service-principal -u  6f2347da-e00b-41d0-8738-61db97dec0eb -p    e31d59f9-6c43-4c96-8586-e5f8e524fb0c --tenant   6b94bb78-d3ab-45ee-a0d0-468e38a6057d'
      }
    }
    
    stage ('Resourcegroup creation') {
      steps {
	     sh 'az group create --name Atmecs_devops --location eastus'
      }
    }
    stage ('Virtualmachine creation') {
      steps {
	     sh 'az vm create --resource-group  Atmecs_devops --name  Atmecs_devops_vm  --image CentOS  --admin-username atmecs  --admin-password Atmecs@123456  --location eastus'
      }
    }
    stage ('Creation NSG') {
      steps {
	     sh 'az network nsg create --resource-group Atmecs_devops --location eastus --name Atmecs_devops_NSG'
      }
    }
    stage ('Creation NSG Rule') {
      steps {
	     sh 'az network nsg rule create --resource-group Atmecs_devops --nsg-name Atmecs_devops_NSG --name Atmecs_devops_NSG_rule --protocol Tcp --priority 1000 --destination-port-range 22'
	     sh 'az network nsg rule create --resource-group Atmecs_devops --nsg-name Atmecs_devops_NSG --name Atmecs_devops_NSG_rule --priority 1000 --source-address-prefixes VirtualNetwork --destination-port-ranges 80 8080 --direction Inbound --access Allow --protocol Tcp --description "Allow VirtualNetwork to Storage".'
	     sh 'az network nsg rule create --resource-group Atmecs_devops --nsg-name Atmecs_devops_NSG --name Atmecs_devops_NSG_rule --protocol Tcp --priority 1000 --destination-port-range 8081'
      }
    }
    stage ('IP enabling and login') {
      steps {
	     git credentialsId: 'jenkins', url: 'https://github.com/kmadhukiran/Devops_new.git'
              sh '''
              ip=$(az vm show --resource-group Atmecs_devops --name Atmecs_devops_vm -d --query [publicIps] --o tsv)
              sshpass -p 'Atmecs@123456' ssh -t -t -o StrictHostKeyChecking=no atmecs@$ip << 'ENDSSH'
              sudo -S <<< "Atmecs@123456" yum update -y
              sudo -S <<< "Atmecs@123456" yum install java 1.8* -y
              sudo -S <<< "Atmecs@123456" wget http://apachemirror.wuchna.com/tomcat/tomcat-9/v9.0.31/bin/apache-tomcat-9.0.31.tar.gz
              sudo -S <<< "Atmecs@123456" tar -xzvf apache-tomcat-9.0.31.tar.gz
              sudo -S <<< "Atmecs@123456" /home/atmecs/apache-tomcat-9.0.31/bin/startup.sh
              sudo -S <<< "Atmecs@123456" ps -ef|grep tomcat
              exit
              ENDSSH
              '''
      }
    }
 }
}
