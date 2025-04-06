#!/bin/bash
# shellcheck disable=SC2206
#SBATCH --job-name=test-ray
#SBATCH --cpus-per-task=56
#SBATCH --mem-per-gpu=30GB
#SBATCH --gpus-per-task=8
#SBATCH --tasks-per-node=1
#SBATCH --time=00:30:00
#SBATCH --nodes=4
#SBATCH --exclusive
#SBATCH --partition=standard-g
#SBATCH --account=project_462000365
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err    

module purge
module load LUMI 
module load PyTorch/20240801-rocm-6.2.0-python-3.12-singularity-20241007
# Optional: Inject the environment variables for NCCL debugging into the container.   
# This will produce a lot of debug output!     
export NCCL_DEBUG=INFO
export NCCL_DEBUG_SUBSYS=INIT,COLL

c=fe
MYMASKS="0x${c}000000000000,0x${c}00000000000000,0x${c}0000,0x${c}000000,0x${c},0x${c}00,0x${c}00000000,0x${c}0000000000"
echo "Running ray"

# Getting the node names
nodes=$(scontrol show hostnames "$SLURM_JOB_NODELIST")
nodes_array=($nodes)

head_node=${nodes_array[0]}
head_node_hostname=$head_node  # Use hostname directly

port=6399
ip_head=$head_node_hostname:$port  # Use hostname instead of IP
export ip_head
echo "IP Head: $ip_head"

echo "Starting HEAD at $head_node"

# Start head node
srun --nodes=1 --ntasks=1 -w "$head_node" \
    singularity exec $SIFPYTORCH \
    ray start --head --node-ip-address="$head_node_hostname" --port=$port \
    --num-cpus "${SLURM_CPUS_PER_TASK}" --num-gpus "${SLURM_GPUS_PER_TASK}" --block &

sleep 30
# number of nodes other than the head node
worker_num=$((SLURM_JOB_NUM_NODES - 1))

for ((i = 1; i <= worker_num; i++)); do
    node_i=${nodes_array[$i]}
    echo "Starting WORKER $i at $node_i"
    srun --nodes=1 --ntasks=1 -w "$node_i" \
        singularity exec $SIFPYTORCH \
        ray start --address "$ip_head" \
        --num-cpus "${SLURM_CPUS_PER_TASK}" --num-gpus "${SLURM_GPUS_PER_TASK}" --block &
    sleep 5 
done

echo "Running Python script inside container"

singularity exec $SIFPYTORCH \
  python -u mnist_pytorch_trainable.py --cuda


if [ $? -ne 0 ]; then
    echo "Training failed"
    exit 1
fi
echo "Training complete!"