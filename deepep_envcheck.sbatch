#!/bin/bash
#SBATCH -J deepep-envcheck
#SBATCH -N 2
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-node=1
#SBATCH --exclusive
#SBATCH -t 00:10:00
set -euo pipefail

# ECR or local image tag you built from DeepEP-efa.Dockerfile
IMAGE=./deepep-on-aws.sqsh

# Common EFA/NVSHMEM runtime envs
export FI_PROVIDER=efa
export FI_EFA_USE_DEVICE_RDMA=1
export NVSHMEM_REMOTE_TRANSPORT=libfabric
export NVSHMEM_LIBFABRIC_PROVIDER=efa
export NVSHMEM_BOOTSTRAP=PMI
export NVSHMEM_SYMMETRIC_SIZE=1G

# With Pyxis/Enroot: mount devices and shm; pass host network namespace by default
srun --mpi=pmi2 \
  --container-image="$IMAGE" \
  bash -lc '
    echo "===== Node: $(hostname) ====="
    nvidia-smi | head -n 20 || true
    which fi_info && fi_info -p efa | head -n 25 || true
    python3 - <<PY
import sys, torch
print("Torch:", torch.__version__, "CUDA:", torch.version.cuda, "Is CUDA available?", torch.cuda.is_available())
import importlib, importlib.util
import nvidia.nvshmem as nv
print("NVSHMEM wheel OK; module path:", nv.__file__)
import deep_ep
print("DeepEP import OK; version attribute?", getattr(deep_ep, "__version__", "n/a"))
PY
  '
