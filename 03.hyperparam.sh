#!/bin/bash
#SBATCH --account=def-shaferab
#SBATCH --job-name=pyhyperparam
#SBATCH --cpus-per-task=12
#SBATCH --mem=48G
#SBATCH --time=19:59:00
#SBATCH --output=pyhyperparam_%j.out
 
# Simulate under the MSMC demography to choose window size and block penalty. --ploidy 2 because the data are unphased genotypes.
 
module load python/3.11
source ~/ENV/bin/activate
set -euo pipefail
 
source config.sh
 
pyrho hyperparam --samplesize "${SIZE}" --mu "${MU}" --msmc_file "${MSMC}" \
  --tablefile "${TABLE}" --ploidy 2 \
  --blockpenalty 10,20,50,100 --windowsize 20,25,50,100 --num_sims 5 \
  --numthreads "${SLURM_CPUS_PER_TASK}" \
  --outfile "hyperparam${SIZE}_MSMC_nohap" --logfile logMSMChyp
