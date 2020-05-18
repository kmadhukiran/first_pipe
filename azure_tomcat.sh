pipeline {
  agent any
  stages {
    stage ('Login') {
      steps {
        sh 'az login --service-principal -u  9793ee19-4016-47ca-b68f-c0aa1d44b3c0 -p 36c253a4-e406-49b5-8a91-b638920517bf --tenant fa8261cb-9a47-424a-8328-011cf9c6482d'
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
	     sh 'az network nsg rule create --resource-group Atmecs_devops --nsg-name Atmecs_devops_NSG --name Atmecs_devops_NSG_rule --priority 300 --source-address-prefixes VirtualNetwork --destination-port-ranges 8080 --direction Inbound --access Allow --protocol Tcp --description "Allow VirtualNetwork to Storage".'
	     sh 'az network nsg rule create --resource-group Atmecs_devops --nsg-name Atmecs_devops_NSG --name Atmecs_devops_NSG_rule --protocol Tcp --priority 320 --destination-port-range 8081'
      }
    }
    stage ('IP enabling and login') {
      steps {
	     git credentialsId: 'jenkins', url: 'https://github.com/kmadhukiran/Devops_new.git'
              sh '''
              ip=$(az vm show --resource-group Atmecs_devops --name Atmecs_devops_vm -d --query [publicIps] --output tsv)
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
