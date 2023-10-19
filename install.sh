# install the project onto a local minikube cluster
echo "before running this:"
echo "- install istioctl and helm"
echo "- run the genKeys.sh script from in the keys directory"
echo "- create a hashicorp vault instance on hashicorp cloud platform; fill out the vault_source file with env vars (see below in this script for more info)"
echo "- run 'minikube start', then 'kubectl proxy --disable-filter=true' in one tab and 'ngrok http 127.0.0.1:8001' in another"

set -e

source ./vault_source
# vault_source should set VAULT_ADDR, VAULT_TOKEN, and VAULT_NAMESPACE
# VAULT_NAMESPACE is typically 'admin'

echo "should be runnning 'kubectl proxy --disable-filter=true' and 'ngrok http 127.0.0.1:8001'; enter ngrok address:"
read K8S_URL
export K8S_CA_CERT="$(true | openssl s_client -connect ngrok.io:443 2>/dev/null | openssl x509)"
# usually you can get this cert from your kubernetes config file, instead we're using ngrok's cert since they're doing https

kubectl apply -f etc.yaml
kubectl create namespace vault-secrets-operator-system
kubectl create namespace istio-system

vault auth enable -path kubernetes-proj kubernetes
vault write auth/kubernetes-proj/config \
   "kubernetes_host=$K8S_URL" \
   "kubernetes_ca_cert=$K8S_CA_CERT"
vault secrets enable -path=proj-kv kv-v2
echo 'path "proj-kv/data/abc" { capabilities = ["read"] }' | vault policy write proj-kv-abc-read -
echo 'path "proj-kv/data/cred-c" { capabilities = ["read"] }' | vault policy write proj-kv-cred-c-read -
vault write auth/kubernetes-proj/role/sa-c-role \
   bound_service_account_names=sa-c \
   bound_service_account_namespaces=app \
   policies=proj-kv-abc-read \
   audience=vault \
   ttl=24h
vault write auth/kubernetes-proj/role/istio-ingress-role \
   bound_service_account_names=istio-ingressgateway-service-account \
   bound_service_account_namespaces=istio-system \
   policies=proj-kv-cred-c-read \
   audience=vault \
   ttl=24h
vault kv put proj-kv/abc "x=abc" "y=def"
vault kv put proj-kv/cred-c "tls.crt=$(cat keys/c.abc.com.crt)" "tls.key=$(cat keys/c.abc.com.key)"

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
istioctl install -y
helm install vault-secrets-operator hashicorp/vault-secrets-operator -n vault-secrets-operator-system --values /dev/stdin <<EOF
defaultVaultConnection:
  enabled: true
  address: "$VAULT_ADDR"
EOF

sleep 1

kubectl apply -f istiosecret.yaml

sleep 1

helm package test-proj -d test-proj
helm install -n app test-proj test-proj/test-proj*.tgz

echo "DONE INSTALLING"
echo "you can run 'minikube tunnel' in one tab and './curlScript.sh index.html' in another to test out website"
echo "you can run 'kubectl get -n app pod' and 'kubectl exec -n app dep-a-[...] -- /bin/sh -c 'curl svc-b; curl svc-c'' to test out istio authz; the first curl should succeed and the second should fail"
echo "you can run 'kubectl describe -n app vaultstaticsecret static-sec-kv-c' and 'kubectl describe -n app secret sec-kv-c' to test out secret"

echo "press enter to cleanup, ctrl c to exit:"
read
./cleanup.sh
