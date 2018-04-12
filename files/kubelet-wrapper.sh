#!/bin/bash
# Wrapper for launching kubelet via rkt-fly stage1. 
#
# Make sure to set KUBELET_IMAGE_TAG to an image tag published here:
# https://quay.io/repository/coreos/hyperkube?tab=tags Alternatively,
# override $KUBELET_IMAGE_URL to a custom location.

set -e

if [ -z "${KUBELET_IMAGE_TAG}" ]; then
    echo "ERROR: must set KUBELET_IMAGE_TAG"
    exit 1
fi

KUBELET_IMAGE_URL="${KUBELET_IMAGE_URL:-quay.io/coreos/hyperkube}"

mkdir --parents /etc/kubernetes
mkdir --parents /var/lib/docker
mkdir --parents /var/lib/kubelet
mkdir --parents /run/kubelet
mkdir --parents /var/log/containers

exec /usr/bin/rkt run \
  --volume etc-kubernetes,kind=host,source=/etc/kubernetes \
  --volume etc-ssl-certs,kind=host,source=/usr/share/ca-certificates \
  --volume var-lib-docker,kind=host,source=/var/lib/docker \
  --volume var-lib-kubelet,kind=host,source=/var/lib/kubelet,readOnly=false,recursive=true \
  --volume var-log,kind=host,source=/var/log,readOnly=false \
  --volume run,kind=host,source=/run \
  --mount volume=etc-kubernetes,target=/etc/kubernetes \
  --mount volume=etc-ssl-certs,target=/etc/ssl/certs \
  --mount volume=var-lib-docker,target=/var/lib/docker \
  --mount volume=var-lib-kubelet,target=/var/lib/kubelet \
  --mount volume=var-log,target=/var/log \
  --mount volume=run,target=/run \
  --hosts-entry=127.0.0.1=localhost \
  --trust-keys-from-https \
  $RKT_RUN_ARGS \
  --stage1-from-dir=stage1-fly.aci \
  ${KUBELET_IMAGE_URL}:${KUBELET_IMAGE_TAG} --exec=/kubelet -- "$@"
