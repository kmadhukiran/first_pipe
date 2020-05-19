
#Create a public  IP address for vm1
az network public-ip create --resource-group Azure \
--name myPublicIP1

#Create a public  IP address for vm2
az network public-ip create --resource-group Azure \
--name myPublicIP2

# Create Azure load balancer
az network lb create \
    --resource-group Azure \
    --name myLoadBalancer \
    --public-ip-address myPublicIP \
    --frontend-ip-name myFrontEndPool \
    --backend-pool-name myBackEndPool

# Create the health probe (to check waether virtual machine instances running or not )
az network lb probe create \
    --resource-group Azure \
    --lb-name myLoadBalancer \
    --name myHealthProbe \
    --protocol tcp \
    --port 80       

# Create the load balancer rule
az network lb rule create \
    --resource-group Azure \
    --lb-name myLoadBalancer \
    --name myHTTPRule \
    --protocol tcp \
    --frontend-port 80 \
    --backend-port 80 \
    --frontend-ip-name myFrontEndPool \
    --backend-pool-name myBackEndPool \
    --probe-name myHealthProbe

# Configure virtual network
az network vnet create \
    --resource-group Azure \
    --location eastus \
    --name myVnet \
    --subnet-name mySubnet

# Create a network security group (Create network security group to define inbound connections to your virtual network.)
az network nsg create \
    --resource-group Azure \
    --name myNetworkSecurityGroup

# Create a network security group rule(create a network security group rule to allow inbound connections through port 80)
az network nsg rule create \
    --resource-group Azure \
    --nsg-name myNetworkSecurityGroup \
    --name myNetworkSecurityGroupRuleHTTP \
    --protocol tcp \
    --direction inbound \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range 80 \
    --access allow \
    --priority 200

# Create NICs
for i in `seq 1 2`; do
  az network nic create \
    --resource-group Azure \
    --name myNic$i \
    --vnet-name myVnet \
    --subnet mySubnet \
    --public-ip-address myPublicIP$i \
    --network-security-group myNetworkSecurityGroup \
    --lb-name myLoadBalancer \
    --lb-address-pools myBackEndPool
done

# Create an Availability set
az vm availability-set create \
   --resource-group Azure \
   --name myAvailabilitySet

# Create the virtual machines
for i in `seq 1 2`; do
 az vm create \
   --resource-group Azure \
   --name myVM$i \
   --availability-set myAvailabilitySet \
   --nics myNic$i \
   --image CentOs \
   --admin-username nisum \
   --admin-password nisum@123456789 \
   --generate-ssh-keys \
 az vm open-port --port 22 --resource-group Azure --name myVM$i
done


pipeline {
  agent any
  stages {
    stage ('Login') {
      steps {
        sh 'az login --service-principal -u  9793ee19-4016-47ca-b68f-c0aa1d44b3c0 -p 70ea2e3c-bb92-4329-b794-72cfca970456 --tenant fa8261cb-9a47-424a-8328-011cf9c6482d'
      }
    }
    stage ('Resourcegroup creation') {
      steps {
	     sh 'az group create --name Azure \
             --location eastus'
      }
    }
    stage ('PIP generation') {
      steps {
	     sh 'az network public-ip create --resource-group Azure \
            --name myPublicIP'
         sh 'az network public-ip create --resource-group Azure \
            --name myPublicIP1'
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
              sh '''
              ip=$(az vm show --resource-group Atmecs_devops --name Atmecs_devops_vm -d --query [publicIps] --output tsv)
              sshpass -p 'Atmecs@123456' ssh -t -t -o StrictHostKeyChecking=no atmecs@$ip << 'ENDSSH'
              sudo -S <<< "Atmecs@123456" yum update -y
              sudo -S <<< "Atmecs@123456" yum install java 1.8* -y
              sudo -S <<< "Atmecs@123456" wget http://apachemirror.wuchna.com/tomcat/tomcat-9/v9.0.31/bin/apache-tomcat-9.0.31.tar.gz
              sudo -S <<< "Atmecs@123456" tar -xzvf apache-tomcat-9.0.31.tar.gz
              sudo -S <<< "Atmecs@123456" systemctl start tomcat
              sudo -S <<< "Atmecs@123456" ps -ef|grep tomcat
              exit
              ENDSSH
              '''
      }
    }
 }
}
