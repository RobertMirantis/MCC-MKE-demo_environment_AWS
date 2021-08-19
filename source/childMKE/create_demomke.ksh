KUBECONFIG=${1:-"kubeconfig"}

echo "export KUBECONFIG=$KUBECONFIG"


echo "********************************************************************"
echo "Test Connection"
echo "********************************************************************"
kubectl get node
if [ $? -ne 0 ]
then
       echo "Failed to Connect to MCC cluster"
       echo "FIX KUBECONFIG variable and run script childMKE/create_demomke.ksh"
       exit 1
else
       echo "Great ;-) Works like a charm"
       echo ""
fi       

echo "********************************************************************"
echo "Now we are now going to create your first child cluster called demo"
echo "********************************************************************"

if [ -f releases.lst ]
then
	TAKERELEASE=`cat releases.lst | cut -f 6 -d'"' | sed 's/./-/g'`
	cat childMKE/cluster_demo.yaml " | sed 's/release: mke-7-0-0-3-4-0/release: mke-$TAKERELEASE/g'"  > childMKE/cluster_demo.yaml1
fi


if [ -f childMKE/cluster_demo.yaml1 ]
then
  # Latests and greatest
  kubectl create -f childMKE/cluster_demo.yaml1
else
  # Fixed in version
  kubectl create -f childMKE/cluster_demo.yaml
fi
kubectl create -f childMKE/machine1.yaml
kubectl create -f childMKE/machine2.yaml
kubectl create -f childMKE/machine3.yaml
kubectl create -f childMKE/machine4.yaml
kubectl create -f childMKE/machine5.yaml
kubectl create -f childMKE/machine6.yaml

############################
# WAIT FOR IT
############################
echo "WAIT FOR IT: MKE cluster gets created (estimated 30 minutes):"
echo "                                   |"
echo -n "."
sleep 1m

typeset -i GREENLIGHT=0
while [ $GREENLIGHT -eq 0 ]
do
  if [ `kubectl get cluster demo -o yaml | grep -i "ready: 6" | wc -l` -eq 1 ]
  then
    if  [ `kubectl get cluster demo -o yaml | grep -i "ready: false" | wc -l` -eq 0 ]
    then
      typeset -i GREENLIGHT=1
    fi
  fi

  # MEANWHILE 
  sleep 1m
  echo -n "."
done

echo -n " | done"
echo ""

## ADD kubeconfig intel to kubeconfig
childMKE/vul_kubeconfig.ksh demo

export KUBECONFIG=demo-kubeconfig

## Create demo namespace
kubectl create ns demo

##### ADD DEMO RESOURCE script




