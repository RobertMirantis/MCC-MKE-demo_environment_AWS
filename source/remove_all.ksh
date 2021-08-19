THUIS=`pwd`

export KUBECONFIG=${THUIS}/kaas-bootstrap/kubeconfig
if [ ! -f ${KUBECONFIG} ] 
then
	if [ -f ${KUBECONFIG}.saved ]
	then
		cp ${KUBECONFIG}.saved ${KUBECONFIG}
	fi
fi


echo ""
echo "################### TEST CONNECTION ######################"
kubectl get nodes 
if [ $? -ne 0 ]
then
	echo "Test FAILED! Fix the KUBECONFIG variable to point to the MCC cluster"
	exit 1
else
	echo "Great - First test has succeed!"
fi

echo ""
echo "****************** DELETE CHILD CLUSTERS ******************"
for CLUSTER in `kubectl get cluster  | grep -vE "kaas-mgmt|NAME|AGE" | awk '{print $1}'`
do
	kubectl delete cluster $CLUSTER
done

echo ""
echo "****************** DELETE MCC CLUSTER *********************"
cd ${THUIS}/kaas-bootstrap
./bootstrap.sh cleanup
cd ${THUIS}

echo "****************** CLEAN UP DOCKER ENV ********************"
docker volume prune -f

echo "************YOU MAY NEED TO MANUALLY DELETE THE CREATED EBS VOLUMES!!"
echo "I known... It is made by design that some EBS volumes stay (forever)"


cp $KUBECONFIG ${KUBECONFIG}.saved
rm $KUBECONFIG
rm -f demo-kubeconfig
rm -f MCC-kubeconfig
rm -f todays_MCC_servers.logfile 
rm -f kaas-bootstrap/mirantis.lic
rm -f mirantis.lic

