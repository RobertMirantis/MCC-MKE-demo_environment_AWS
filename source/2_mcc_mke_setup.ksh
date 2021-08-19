
DATE=`date "+%y%m%d"`
THUIS=`pwd`

if [ ! -f mirantis.lic ] 
then
  if [ -f ~/licenses/mirantis.lic ]
  then
	  cp ~/licenses/mirantis.lic .
  fi
fi

#################### SOURCE THE AWS variables
echo "SOURCE sourceme.ksh"
source sourceme.ksh

# Run the test
aws ec2 describe-instances > /dev/null
if [ $? -ne 0 ]
then
	echo "AWS CLI not working...."
	echo "--> Either have a valid sourceme.ksh with CLI KEY+Secret or give the EC2 host an Admin role"
	exit 1
fi


# Change AMI
FILE=kaas-bootstrap/templates/aws/machines.yaml.template
REPLACEAMI=`cat $FILE | grep "ami-" | cut -f 2 -d":" | awk '{print $1}' `
#echo "REPLACEAMI=$REPLACEAMI"

# Find needed AMI
# FILL IN YOUR AMI ID IN YOUR REGION (AMI number differs per region), and I will do the magic... ;-)!!
#TOAMI="ami-0e0102e3ff768559b"
TOAMI="ami-0b1deee75235aa4bb" # Right answer in Region=Frankfurt
TOAMI=`aws ec2 describe-images --filter "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20210415" --query 'Images[*].[ImageId]' --output text`
#echo "TOAMI=$TOAMI"

#echo "Before file ${FILE}"
#cat $FILE

# MAGIC
cat $FILE | sed "s/${REPLACEAMI}/${TOAMI}/g" > ${FILE}.1
mv ${FILE}.1 ${FILE}

#cat $FILE
#exit


########################################################################
# Start building MCC
########################################################################



LOGFILE=${THUIS}/kaas-bootstrap/todays_MCC_servers.logfile
rm -f $LOGFILE

sudo systemctl start docker

# Ensure nothing is running on the moment
while [ `docker ps | wc -l` -ne 1 ] 
do
  PS=`docker ps | tail -1 | awk '{print $1}'`
  docker stop $PS
  docker rm $PS
done
#docker system prune -a -f
#docker images prune -a 
#docker volume prune 

# Ok, lets kick things off
export KAAS_AWS_ENABLED=true
if [ -f ${THUIS}/mirantis.lic ]
then
	  cp ${THUIS}/mirantis.lic ${THUIS}/kaas-bootstrap/
else
	  echo "Geen license file gevonden in ${THUIS}"
	  exit 1
fi
cd ${THUIS}/kaas-bootstrap

rm -f nohup.out
nohup ./bootstrap.sh all & 
sleep 10
echo "********************************************************************************"
echo "**    Started building Mirantis Container Cloud - Happening in the background **"
echo "**     - Process can be followed by tailing kaas-bootstrap/nohop.out -        **"
echo "**                  This process will take about 40 minutes                   **"
echo "********************************************************************************"

typeset -i GREENLIGHT=0
typeset -i FIRSTHIT=0
echo "                                        |"
while [ $GREENLIGHT -eq 0 ]
do
     if [ -f ${THUIS}/kaas-bootstrap/kubeconfig ] 
     then
	  export KUBECONFIG=${THUIS}/kaas-bootstrap/kubeconfig
	  # Try to connect
	  if [ `kubectl get nodes | grep -i "Ready" | wc -l` -eq 3 ]
	  then
		  if [ $FIRSTHIT -eq 0 ]
		  then
			  # Give kaas-mgmt to be created please
		    echo -n "."
		    sleep 1m 
		    echo -n "."
		    sleep 1m 
		    echo -n "."
		    sleep 1m 
		    echo -n "."
		    sleep 1m 
		    echo -n "."
		    sleep 1m 
	          fi
		  # Ok nodes are ready
		  #if [ `kubectl get cluster kaas-mgmt | wc -l` -eq 2 ]
		  kubectl get cluster kaas-mgmt 2>&1 > /dev/null 
		  if [ $? -eq 0 ] 
		  then
	             # Ok, my cluster is there...
		     # Let the resources get uploaded (5m) or it will result in errormessages in our nice Layout....;-(
		     if [ $FIRSTHIT -eq 0 ]
		     then
		       sleep 1m
		       echo -n "."
		       sleep 1m
		       echo -n "."
		       sleep 1m
		       echo -n "."
		       sleep 1m
		       echo -n "."
		       sleep 1m
		       echo -n "."
                       typeset -i FIRSTHIT=1
	             fi
	             if [ `kubectl get cluster kaas-mgmt -o yaml  | grep -i "ready" | grep "false" | wc -l` -eq 0 ]
	             then
			  typeset -i GREENLIGHT=1
		     fi
	          fi
	  fi
     fi

     # DISPLAY & SLEEP
     echo -n "."
     sleep 1m
done
echo -n "| DONE"

echo "----------------------------" >> $LOGFILE
echo "----------------------------" 
cat passwords.yaml 
cat passwords.yaml >> $LOGFILE

# And back
cd ${THUIS}

##########################
# Create Child Cluster
##########################
if [ -f kaas-bootstrap/kubeconfig ] 
then
  cp ${THUIS}/kaas-bootstrap/kubeconfig ${THUIS}/MCC-kubeconfig
  export KUBECONFIG=${THUIS}/MCC-kubeconfig
fi


# Create first user on MCC
echo "password" | ${THUIS}/kaas-bootstrap/kaas bootstrap user add --password-stdin --kubeconfig ${THUIS}/kaas-bootstrap/kubeconfig --username demo --roles writer
echo "I have already created an user for you: " >> $LOGFILE
echo "Username: demo" >> $LOGFILE
echo "password: yes, that is IT (read: The password is 'password')" >> $LOGFILE
echo "--------------------------------------------------------------------------" >> $LOGFILE
echo "Connection DETAILS:" >> $LOGFILE
KAASUI=`cat kaas-bootstrap/nohup.out | grep "KAAS UI"` 
KEYCLOAK=`cat kaas-bootstrap/passwords.yaml| grep "Keycloak service"` 
KEYPWD=`cat kaas-bootstrap/passwords.yaml | grep "keyCloak:"`
${THUIS}/decode_urls.ksh  >> $LOGFILE
echo "Keycloak user + password = keyCloak + $KEYPWD" >> $LOGFILE
echo "connect to your kaas-mgmt cluster : export KUBECONFIG=${THUIS}/MCC-kubeconfig"
echo "connect to your demo cluster      : export KUBECONFIG=${THUIS}/demo-kubeconfig"
echo "GUI?:"
${THUIS}/decode_urls.ksh  


if [ -f CREATE_A_MKECHILD_PLEASE ]
then
  ####################################
  # Create our Demo2 cluster
  ####################################
  ${THUIS}/childMKE/create_demomke.ksh $KUBECONFIG
fi

echo "++++++++++++++++++++++++++ END GOOD - ALL GOOD +++++++++++++++++++++++++++++++++++++++++"
cat $LOGFILE
echo "-----------------------------------------------------------"
echo "This intel will be saved in `basename ${LOGFILE}`"
cp $LOGFILE ${THUIS}/
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
cd $THUIS

