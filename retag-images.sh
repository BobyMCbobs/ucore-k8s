#!/usr/bin/env bash

DEST_REGISTRY_PREFIX="ghcr.io/bobymcbobs/ucore-k8s"
NEW_TAG=1.17.0

function retag {
    REF="$1"
    NEW_TAG="$2"
    NAME="$(echo "${REF}" | sed 's,.*/\(.*\),\1,g')"
    NAME_WITHOUT_TAG="$(echo "${REF}" | sed 's,.*/\(.*\):.*,\1,g' | sed 's,\(.*\)@.*,\1,g')"
    NEW_REF_WITHOUT_TAG="$DEST_REGISTRY_PREFIX/$NAME_WITHOUT_TAG"
    NEW_REF="$DEST_REGISTRY_PREFIX/$NAME"
    crane digest "$NEW_REF_WITHOUT_TAG:$NEW_TAG" || crane tag "$NEW_REF" "$NEW_TAG"
}

IMAGES=(
    $(curl -sSL https://github.com/knative/operator/raw/refs/heads/main/cmd/operator/kodata/knative-serving/1.17.0/2-serving-core.yaml | grep 'image: .*' | sed 's,.*image: \(.*\),\1,g' | sort | uniq)
)

for IMAGE in "${IMAGES[@]}"; do
    echo "> $IMAGE"
    retag "$IMAGE" "$NEW_TAG"
done
