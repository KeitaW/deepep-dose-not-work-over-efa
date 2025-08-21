#!/bin/bash
#SBATCH -J deepep-internode
#SBATCH -N 2
#SBATCH --ntasks-per-node=8
#SBATCH --gpus-per-node=8
#SBATCH --gpus-per-task=1
#SBATCH --gpu-bind=single:1
#SBATCH --cpus-per-task=8
#SBATCH --exclusive

#SBATCH -t 00:20:00

# #SBATCH -p gpu
# #SBATCH --constraint=p5en

set -euo pipefail
IMAGE=./deepep-on-aws.sqsh

# EFA + NVSHMEM over libfabric
export FI_PROVIDER=efa
export FI_EFA_USE_DEVICE_RDMA=1
export NVSHMEM_REMOTE_TRANSPORT=libfabric
export NVSHMEM_LIBFABRIC_PROVIDER=efa
export NVSHMEM_BOOTSTRAP=PMI
export NVSHMEM_SYMMETRIC_SIZE=1G

# Map Slurm -> torch.distributed (env://)
MASTER_ADDR=$(scontrol show hostnames "$SLURM_NODELIST" | head -n1)
export MASTER_ADDR MASTER_PORT=29500

srun --mpi=pmix \
  --container-image="$IMAGE" \
  bash -lc '
  set -euo pipefail
  export RANK=$SLURM_PROCID
  export WORLD_SIZE=$SLURM_NTASKS
  export LOCAL_RANK=$SLURM_LOCALID

  # Minimal DeepEP smoke test: initialize DDP, create a DeepEP Buffer with RDMA bytes,
  # do a couple of barriers. If any NVSHMEM/EFA step fails, this will error out.
  python3 - <<PY
import os, torch, torch.distributed as dist
from deep_ep import Buffer

backend="nccl"
dist.init_process_group(backend=backend, init_method="env://",
                        rank=int(os.environ["RANK"]), world_size=int(os.environ["WORLD_SIZE"]))

# Small RDMA region to force symmetric allocation / NVSHMEM setup
group = dist.group.WORLD
Buffer.set_num_sms(4)
buf = Buffer(group, num_nvl_bytes=0, num_rdma_bytes=32*1024*1024)  # 32MB RDMA region

dist.barrier()
if dist.get_rank()==0:
    print("DeepEP Buffer created (RDMA bytes allocated). NVSHMEM/EFA path appears functional.")
dist.barrier()
dist.destroy_process_group()
PY
'
