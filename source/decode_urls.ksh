
THUIS=`pwd`
export KUBECONFIG=${THUIS}/kaas-bootstrap/kubeconfig
TMPFILE=/tmp/getclusterintel$$.out

kubectl get cluster kaas-mgmt -o yaml > $TMPFILE

typeset -i GETKEYCLOAK=0
typeset -i GETMCCUI=0

while read REGEL
do
	if [ $GETMCCUI -eq 2 ]
	then
		continue
	fi
	#echo "REGEL=$REGEL"
	# FIND KEYCLOAK URL
	if [ `echo "$REGEL" | grep "keycloak:" | wc -l` -eq 1 ]
	then
		if [ $GETKEYCLOAK -eq 0 ]
		then
		   #echo "GETKEYCLOAK gets 1"
		   typeset -i GETKEYCLOAK=1
	        fi
	fi
	if [ `echo "$REGEL" | grep "url:" | wc -l` -eq 1 ]
	then
		if [ $GETKEYCLOAK -eq 1 ]
		then
			#echo "REGEL=$REGEL"
			KEYCLOAKURL=`echo "$REGEL" | cut -f 2,3 -d":" | awk '{print $1}'`
		        typeset -i GETKEYCLOAK=2
		fi
	fi
	# FIND MCC URL
	if [ `echo "$REGEL" | grep "ui:" | wc -l` -eq 1 ]
	then
		if [ $GETMCCUI -eq 0 ]
		then
		   #echo "GETMCCUI gets 1"
		   typeset -i GETMCCUI=1
	        fi
	fi
	if [ `echo "$REGEL" | grep "url:" | wc -l` -eq 1 ]
	then
		if [ $GETMCCUI -eq 1 ]
		then
			MCCURL=`echo "$REGEL" | cut -f 2,3 -d":" | awk '{print $1}'`
		        typeset -i GETMCCUI=2
		fi
	fi

done < $TMPFILE
rm -f $TMPFILE


echo "MCCURL=$MCCURL"
echo "KEYLOAKURL=$KEYCLOAKURL"
