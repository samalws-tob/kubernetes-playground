INGRESS_NAME=istio-ingressgateway
INGRESS_NS=istio-system
INGRESS_HOST=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
SECURE_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
TCP_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
DOMAIN=c.abc.com
curl -v -HHost:$DOMAIN --resolve "$DOMAIN:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
  --cacert keys/$DOMAIN.crt "https://$DOMAIN:$SECURE_INGRESS_PORT/$1"
