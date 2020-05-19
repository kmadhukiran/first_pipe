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
	    
	  sh 'az network public-ip create --resource-group Azure \
           --name myPublicIP2'
	   
      }
    }
    stage ('Creating LB') {
      steps {
	     sh 'az network lb create \
               --resource-group Azure \
               --name myLoadBalancer \
               --public-ip-address myPublicIP \
               --frontend-ip-name myFrontEndPool \
               --backend-pool-name myBackEndPool'
      }
    }
    stage ('LB port') {
      steps {
	     sh 'az network lb probe create \
               --resource-group Azure \
               --lb-name myLoadBalancer \
               --name myHealthProbe \
               --protocol tcp \
               --port 80 '
      }
    }
    stage ('LB rule') {
      steps {
	     sh 'az network lb rule create \
              --resource-group Azure \
             --lb-name myLoadBalancer \
            --name myHTTPRule \
             --protocol tcp \
             --frontend-port 80 \
             --backend-port 80 \
               --frontend-ip-name myFrontEndPool \
             --backend-pool-name myBackEndPool \
            --probe-name myHealthProbe'
     }
    }    
   stage ('azure Vnet') {
      steps {
	     sh ' az network vnet create \
    --resource-group Azure \
    --location eastus \
    --name myVnet \
    --subnet-name mySubnet'
    }
   }
   stage ('Azure NSG') {
      steps {
	     sh 'az network nsg create \
    --resource-group Azure \
    --name myNetworkSecurityGroup'
    }
    }
    stage ('Azure NSG rule'){
    steps {
          sh 'az network nsg rule create \
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
    --priority 200'

}
}
    stage ('IP enabling and login') {
      steps {
      sh '
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
done'
}
}
    stage('Availability zone'){
    steps{
    sh 'az vm availability-set create \
   --resource-group Azure \
   --name myAvailabilitySet'
   }
}
for i in `seq 1 2`; do
stage ('Creating VM'){
steps{
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
done '
      }
    }
 }
}
