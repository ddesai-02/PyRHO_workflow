#!/bin/bash
#SBATCH --account=def-shaferab
#SBATCH --job-name=pyoptimize
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --time=11:59:00
#SBATCH --array=1-36
#SBATCH --output=pyOpt_%A_%a.out

vcf=$(ls *.vcf | sed -n "${SLURM_ARRAY_TASK_ID}p")
base=${vcf%.vcf}

pyrho optimize --vcffile ${vcf} --windowsize 100 --blockpenalty 10 \
  --tablefile table78_MSMC_nohap --ploidy 2 \
  --outfile ${base}.rmap --numthreads 8 --logfile ${base}.pyOptlog
