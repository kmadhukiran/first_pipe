pipeline {
  agent any
  stages {
    stage ('creation') {
      steps {
       sh 'az login --service-principal -u  9793ee19-4016-47ca-b68f-c0aa1d44b3c0 -p 70ea2e3c-bb92-4329-b794-72cfca970456 --tenant fa8261cb-9a47-424a-8328-011cf9c6482d'
	     sh 'az group create --name AtmecsGroup_storage --location "centralus"'
	     sh 'az vm create --resource-group AtmecsGroup_storage --name AtmecsVm1 --image CentOs --admin-username atmecs --admin-password atmecs@123456'
	     sh 'az vm open-port --resource-group AtmecsGroup_storage --name AtmecsVm1 --port 22'
       sh 'ip=$(az vm show --resource-group AtmecsGroup_storage --name AtmecsVm1 -d --query [publicIps] --output tsv)'
      }
          }
     stage ('login') {
          steps{
              sh '''
              sshpass -p 'atmecs@123456' ssh -t -t -o StrictHostKeyChecking=no atmecs@$ip << 'ENDSSH'

sudo -S <<< "atmecs@123456" sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo -S <<< "atmecs@123456" sudo sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo -S <<< "atmecs@123456"sudo yum install azure-cli -y

az storage account create --name madhustorageacc --resource-group AtmecsGroup_storage --location centralus --sku Standard_ZRS --encryption-services blob

az storage account keys list --account-name madhustorageacc --resource-group AtmecsGroup_storage --output table > keys.txt

export AZURE_STORAGE_KEY=`head -n 3 keys.txt | tail -n 1 | awk '{print $3}'`
export AZURE_STORAGE_ACCOUNT=madhustorageacc

echo $AZURE_STORAGE_KEY
echo $AZURE_STORAGE_ACCOUNT
az storage container create --name sample-container1

 az storage blob upload-batch -d sample-container1 --account-name madhustorageacc -s /var/lib/jenkins/jobs/Azure_storage/builds  --if-modified-since 2020-05-12

exit;
EOF'''
          } 
    }
    
 }
}
