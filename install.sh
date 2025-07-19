#!/bin/bash

set -e

DOMAIN="example.com"
EMAIL="your@email.com"

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

curl -sfL https://get.k3s.io | sh -

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

kubectl wait --namespace cert-manager --for=condition=Ready pods --all --timeout=120s
kubectl wait --namespace default --for=condition=Ready pods --selector=app.kubernetes.io/component=controller --timeout=120s

sed "s/DOMAIN_PLACEHOLDER/${DOMAIN}/g; s/EMAIL_PLACEHOLDER/${EMAIL}/g" manifests/issuer.yaml | kubectl apply -f -
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/deployment.yaml
sed "s/DOMAIN_PLACEHOLDER/${DOMAIN}/g" manifests/ingress.yaml | kubectl apply -f -

echo "✅ Setup complete. Point *.${DOMAIN} to your server IP: $(curl -s ifconfig.me)"
