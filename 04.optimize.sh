#!/bin/bash
#SBATCH --account=def-shaferab
#SBATCH --job-name=pyoptimize
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --time=11:59:00
#SBATCH --array=1-36   # Must equal the line count of scaff_names (wc -l < scaff_names)
#SBATCH --output=pyOpt_%A_%a.out
 
# Infer the recombination map for one scaffold per array task. Output is per-bp, per-generation r.
 
module load python/3.11
source ~/ENV/bin/activate
set -euo pipefail
 
source config.sh
 
scaff=$(sed -n "${SLURM_ARRAY_TASK_ID}p" scaff_names)
 
pyrho optimize --vcffile "${scaff}.vcf" --windowsize "${WINDOW}" --blockpenalty "${BPEN}" \
  --tablefile "${TABLE}" --ploidy 2 \
  --numthreads "${SLURM_CPUS_PER_TASK}" \
  --outfile "${scaff}.rmap" --logfile "${scaff}.pyOptlog"
