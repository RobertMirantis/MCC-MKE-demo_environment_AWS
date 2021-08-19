

CLUSTER=${1:-kaas-mgmt}

SERVER=`kubectl get secrets ${CLUSTER}-kubeconfig -o yaml | grep "ucp_url" | cut -f 2 -d":" | awk '{print $1}' | base64 -d | cut -f 3 -d"/" | sed 's/6443/443/g'`
HSERVER="${SERVER}"
USERVER="ucp_${SERVER}_admin"
# DEBUG
#echo "SERVER=$SERVER"
#echo "HSERVER=$HSERVER"
#echo "USERVER=$USERVER"

UCP_CA=`kubectl get secrets ${CLUSTER}-kubeconfig -o yaml | grep "ucp_ca.pem" | cut -f 2 -d":" | awk '{print $1}' `
UCP_CERT=`kubectl get secrets ${CLUSTER}-kubeconfig -o yaml | grep "ucp_cert.pem" | cut -f 2 -d":" | awk '{print $1}' `
UCP_KEY=`kubectl get secrets ${CLUSTER}-kubeconfig -o yaml | grep "ucp_key.pem" | cut -f 2 -d":" | awk '{print $1}' `


#echo "*********************************************************************************************************"
#echo "UCP_CA.PEM=$UCP_CA"
#echo "*********************************************************************************************************"
#echo "UCP_CERT.PEM=$UCP_CERT"
#echo "*********************************************************************************************************"
#echo "UCP_KEY.PEM=$UCP_KEY"
#echo "*********************************************************************************************************"


RESULT=${CLUSTER}-kubeconfig
rm -f $RESULT.*
cat childMKE/kube_templ | sed "s/UCP_CA.PEM/$UCP_CA/g" > ${RESULT}.1
cat ${RESULT}.1 | sed "s/UCP_CERT.PEM/$UCP_CERT/g" > ${RESULT}.2
cat ${RESULT}.2 | sed "s/UCP_KEY.PEM/$UCP_KEY/g" > ${RESULT}.3
cat ${RESULT}.3 | sed "s/USERVER/$USERVER/g" > ${RESULT}.4
cat ${RESULT}.4 | sed "s/HSERVER/$HSERVER/g" > ${RESULT}.5

mv ${RESULT}.5 ${RESULT}
rm ${RESULT}.1
rm ${RESULT}.2
rm ${RESULT}.3
rm ${RESULT}.4

echo "Your kubeconfig file & MKE cluster is ready for you!"
echo "Kubeconfig = ${RESULT}"
echo "Set context : export KUBECONFIG=$RESULT"

echo "*** First Test:****"
export KUBECONFIG=${RESULT}
kubectl get nodes

