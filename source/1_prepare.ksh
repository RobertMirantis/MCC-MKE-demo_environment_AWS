DATE=`date "+%y%m%d"`
THUIS=`pwd`

if [ ! -f mirantis.lic ]
then
  if [ -f ~/licenses/mirantis.lic ]
  then
          cp ~/licenses/mirantis.lic .
  fi
fi


#######################################################
# Before doing anything - update system
#######################################################
sudo apt update
#######################################################
# Install kubectl
#######################################################
if [ ! -f /usr/local/bin/kubectl ]
then
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   rm kubectl
fi

if [ $? -ne 0 ]
then
        echo "Installation of awscli exit with return status 1"
        exit 1
fi
#######################################################
# Install AWS CLI
#######################################################
sudo apt install awscli -y

if [ $? -ne 0 ]
then
        echo "Installation of awscli exit with return status 1"
        exit 1
fi

if [ ! -d ~/.aws ] 
then
  mkdir ~/.aws
fi

if [ ! -f ~/.aws/config ] 
then
  echo "Going to create a aws configure file"
  echo "[default]" > ~/.aws/config
  echo "region = eu-west-1 " >> ~/.aws/config
  echo "output = json" >> ~/.aws/config
fi



#######################################################
# Install docker first
#######################################################
if [ -f /usr/bin/docker ]
then
  if [ `docker images | grep "REPOSITORY" |wc -l` -eq 1 ]
  then
          echo "Docker is install correctly"
  else
          sudo apt-get update -y
          sudo apt install docker.io
          sudo usermod -aG docker $USER
          echo "Run : aws configure  first"
          echo "Docker is now installed - please logoff, login again and start me for a second time!"
  fi
else
          sudo apt-get update -y
          sudo apt install docker.io -y
          sudo usermod -aG docker $USER
          echo "Docker is now installed - please logoff, login back in again!"
fi

#############################
# Get MCC bootstrap software
#############################
if [ -d ${THUIS}/kaas-bootstrap ]
then
  rm -r ${THUIS}/kaas-bootstrap
fi
${THUIS}/get_container_cloud210.sh

#############################
# Changes to machine.yaml
#############################
# IS WORKAROUND FOR 2.10 MCC kubectl edit statefulset.apps/prometheus-server -n stacklight
YAMLFILE=${THUIS}/kaas-bootstrap/templates/aws/machines.yaml.template
cat ${YAMLFILE} | sed 's/120/200/g' > ${YAMLFILE}.1
cat ${YAMLFILE}.1 | sed 's/2x/4x/g' > ${YAMLFILE}

#############################
# Install bootstrapper user
#############################
if [ `cat ${THUIS}/sourceme.ksh | grep "FILL IN" | wc -l` -ge 1 ]
then
  echo "Going to create the bootstrap-user for you"
  cd ${THUIS}/kaas-bootstrap
  ./kaas bootstrap aws policy
  cd ${THUIS}
fi


echo "*********************************************************************"
echo "** Now IMPORTANT STUFF!!!:                                         **"
echo "** - fill in the correct KEYS + SECRET in sourceme.ksh             **"
echo "** - Remove the admin IAM role from the EC2 instance               **"
echo "** - Logout!                                                       **"
echo "** - Log back in - continue running the second script              **"
echo "*********************************************************************"
exit
