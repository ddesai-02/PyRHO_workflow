#!/bin/sh
#SBATCH --account=def-shaferab
#SBATCH --job-name=pytabl
#SBATCH --cpus-per-task=12
#SBATCH --mem=4G
#SBATCH --time=2:59:00
module load python/3.11
source ~/ENV/bin/activate

SIZE="156" # Haploid so double the number of individuals (Haploid)
MU="5.25e-8" # Mutation rate per site per generation
MSMC="wtd_msmc" # MSMC File

pyrho make_table --mu ${MU} --samplesize ${SIZE} --msmc_file ${MSMC} --numthreads 12 --approx --outfile table78_MSMC_nohap --decimate_rel_tol 0.1 --logfile logMSMCtable
