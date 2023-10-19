source ./vault_source

helm delete -n app test-proj
kubectl delete -n istio-system vaultauth auth-kv-istio-ingress
kubectl delete -n istio-system vaultstaticsecret static-sec-cred-c

helm delete -n vault-secrets-operator-system vault-secrets-operator
istioctl uninstall --purge -y

vault auth disable kubernetes-proj
vault secrets disable proj-kv

sleep 1

kubectl delete namespace app 
kubectl delete namespace vault-secrets-operator-system
kubectl delete namespace istio-system
