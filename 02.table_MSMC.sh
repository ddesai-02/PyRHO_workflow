#!/bin/bash
#SBATCH --account=def-shaferab
#SBATCH --job-name=pytabl_red
#SBATCH --cpus-per-task=12
#SBATCH --mem=4G
#SBATCH --time=2:59:00
#SBATCH --output=pytable_%j.out
 
# Build the two-locus likelihood lookup table under the MSMC demography.
 
module load python/3.11
source ~/ENV/bin/activate
set -euo pipefail
 
source config.sh

pyrho make_table --samplesize "${SIZE}" --approx --moran_pop_size "${SIZE}" \
  --mu "${MU}" --msmc_file "${MSMC}" --decimate_rel_tol 0.1 \
  --numthreads "${SLURM_CPUS_PER_TASK}" \
  --outfile "${TABLE}" --logfile logMSMCtable
