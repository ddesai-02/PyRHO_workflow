#!/bin/sh
#SBATCH --account=def-shaferab
#SBATCH --job-name=pyhyperparam
#SBATCH --cpus-per-task=12
#SBATCH --mem=48G
#SBATCH --time=19:59:00
SIZE="" # Haploid so double the number of individuals (Haploid)
MU="" # Mutation rate per site per generation
MSMC="" # MSMC File

pyrho hyperparam -n ${SIZE} --mu ${MU} --numthreads 12 --ploidy 2 --blockpenalty 10,20,50,100 --windowsize 20,25,50,100 --logfile logMSMChyp --tablefile table78_MSMC_nohap --num_sims 5 --msmc_file ${MSMC}  --outfile hyperparam78_MSMC_nohap
