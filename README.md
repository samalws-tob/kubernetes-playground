This repo creates a kubernetes cluster which:
- Has an istio service mesh, and tests out its authorization system
- Pulls secrets automatically from hashicorp vault
- Serves an nginx example page from an ingress gateway using certs pulled from vault

Run install.sh to try it out. It assumes you have a local minikube cluster running.

DO NOT use this as a model for production code, especially since it doesn't encrypt secrets at rest (yet).

Features that I didn't get around to adding but would like to eventually try out:
- Encrypting secrets at rest using trousseau (which enables KMS using vault)
- Gitops using argo or flux
- Logging
