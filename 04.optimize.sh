#!/bin/sh
#SBATCH --account=def-shaferab
#SBATCH --job-name=pyOpt
#SBATCH --cpus-per-task=24
#SBATCH --mem=96G
#SBATCH --time=23:59:00
for vcf in $(ls *vcf |  cut -f1-2 -d '.')
do
pyrho optimize --vcffile ${vcf} --windowsize 50 --blockpenalty 20 --tablefile table78_MSMC_nohap --ploidy 2 --outfile ${vcf}.rmap --numthreads 24 --logfile ${vcf}.pyOptlog
done
