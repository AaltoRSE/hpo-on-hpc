# Ray tune on LUMI

This example is based on the following documentation and adapted to the LUMI environment:
https://docs.ray.io/en/latest/cluster/vms/user-guides/community/slurm.html



## Files

- `submit.slurm`: Main SLURM script that orchestrates the optimization process
- `mnist_pytorch_trainable.py`: The script to run the training

## Usage

1. Setup the example environment on LUMI, refer to:
  https://github.com/AaltoRSE/llm-on-lumi/blob/main/USE_LUMI.md

2. Modify the SLURM parameters in `submit.slurm` as needed (e.g., time limit, cpus, gpus)
3. Submit the job to SLURM:
   ```bash
   sbatch submit.slurm
   ```
4. Monitor progress:
   - Check job status: `slurm q`
   - By default, ray tune will save the results in `~/ray_results/`
