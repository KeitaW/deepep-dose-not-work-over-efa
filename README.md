GDRCOPY_VERSION=v2.4.1
EFA_INSTALLER_VERSION=1.37.0
AWS_OFI_NCCL_VERSION=v1.13.2-aws
NCCL_VERSION=v2.23.4-1
NCCL_TESTS_VERSION=v2.13.10
docker build -f Dockerfile \
      --build-arg="EFA_INSTALLER_VERSION=${EFA_INSTALLER_VERSION}" \
      --build-arg="AWS_OFI_NCCL_VERSION=${AWS_OFI_NCCL_VERSION}" \
      --build-arg="NCCL_VERSION=${NCCL_VERSION}" \
      --build-arg="NCCL_TESTS_VERSION=${NCCL_TESTS_VERSION}" \
      -t deepep-on-aws:latest .

enroot import -o deepep-on-aws dockerd://deepep-on-aws:latest