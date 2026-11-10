#!/bin/sh
#SBATCH --account=def-shaferab
#SBATCH --job-name=pytabl_red
#SBATCH --cpus-per-task=12
#SBATCH --mem=4G
#SBATCH --time=2:59:00
module load python/3.11
source ~/ENV/bin/activate

SIZE="" # Haploid so double the number of individuals (Haploid)
MU="" # Mutation rate per site per generation
MSMC="" # MSMC File

pyrho make_table --mu ${MU} --samplesize ${SIZE} --msmc_file ${MSMC} --numthreads 12 --approx --outfile table78_MSMC_nohap --decimate_rel_tol 0.1 --logfile logMSMCtable
