pipeline {
  agent any
  stages {
    stage ('creation') {
      steps {
         sh 'az login --service-principal -u 78a645f8-8169-4c69-853b-22f8295daf19  -p 51e741f7-684b-4a02-97e1-5ab6c0c833b3  --tenant 06408ebc-5eb8-4b0d-827f-76dd3b58bc84'
	     sh 'az group create --name madhu09012020 --location eastus'
	     sh 'az vm create --resource-group madhu09012020  --name  task1  --image CentOS  --admin-username azureuser  --admin-password Azure.123456@e  --location eastus'
	     sh 'az vm open-port --port 22 --resource-group madhu09012020 --name task1'
      }
    }
     stage ('login') {
          steps{
              git credentialsId: 'github', url: 'https://github.com/kmadhukiran/Devops_new.git'
              sh '''
              sshpass -p 'Azure.123456@e' ssh -t -t -o StrictHostKeyChecking=no azureuser@168.61.45.159 << 'ENDSSH'
              sudo -S <<< "Azure.123456@e" yum update -y
              sudo -S <<< "Azure.123456@e" yum install git* -y
              sudo -S <<< "Azure.123456@e" git clone https://github.com/kmadhukiran/Devops_new.git
              sudo -S <<< "Azure.123456@e" git init
              sudo -S <<< "Azure.123456@e" git remote add origin https://github.com/kmadhukiran/Devops_new.git
              sudo -S <<< "Azure.123456@e" git remote -v
              sudo -S <<< "Azure.123456@e" git pull origin master
              exit
              ENDSSH
              '''
          } 
    }
    
 }
}
