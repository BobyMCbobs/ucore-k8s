#!/usr/bin/env bash

DEST_REGISTRY_PREFIX="ghcr.io/bobymcbobs/ucore-k8s"

function kustomize-images {
    REF="$1"
    NAME="$(echo "${REF}" | sed 's,\(.*\):.*,\1,g' | sed 's,\(.*\)@.*,\1,g')"
    NAME_WITHOUT_TAG="$(echo "${REF}" | sed 's,.*/\(.*\):.*,\1,g' | sed 's,\(.*\)@.*,\1,g')"
    NEW_REF="$DEST_REGISTRY_PREFIX/$NAME_WITHOUT_TAG"
    echo "- name: $NAME"
    echo "  newName: $NEW_REF"
}

function copy-and-sign {
    REF="$1"
    NAME="$(echo "${REF}" | sed 's,.*/\(.*\),\1,g')"
    NEW_REF="$DEST_REGISTRY_PREFIX/$NAME"
    crane digest "$NEW_REF" || crane copy "$REF" "$NEW_REF"
    DIGEST="$(crane digest "$NEW_REF")"
    export COSIGN_YES=true
    cosign verify --key cosign.pub "$NEW_REF" || cosign sign -y -r --key cosign.key "$NEW_REF@$DIGEST"
}

IMAGES=(
    registry.k8s.io/kube-apiserver:v1.32.2
    registry.k8s.io/kube-controller-manager:v1.32.2
    registry.k8s.io/kube-scheduler:v1.32.2
    registry.k8s.io/kube-proxy:v1.32.2
    registry.k8s.io/coredns/coredns:v1.11.3
    registry.k8s.io/pause:3.10
    registry.k8s.io/etcd:3.5.16-0
    $(curl -sSL https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.yaml | grep 'image:' | sed 's,.*image: "\(.*\)",\1,g')
    $(curl -sSL https://github.com/knative/operator/releases/download/knative-v1.17.3/operator.yaml | grep 'image:' | sed 's,.*image: \(.*\),\1,g')
    $(curl -sSL https://github.com/knative/operator/raw/refs/heads/main/cmd/operator/kodata/knative-serving/1.17.0/2-serving-core.yaml | grep 'image: .*' | sed 's,.*image: \(.*\),\1,g')
    $(curl -sSL https://github.com/knative/operator/raw/refs/heads/main/cmd/operator/kodata/ingress/1.17/kourier/kourier.yaml | grep 'image: .*' | sed 's,.*image: \(.*\),\1,g')
)

for IMAGE in "${IMAGES[@]}"; do
    echo "> $IMAGE"
    copy-and-sign "$IMAGE"
    # kustomize-images "$IMAGE"
done
