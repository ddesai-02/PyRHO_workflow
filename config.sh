# Shared settings for the pyrho pipeline.

VCF=""    # Population VCF file
SIZE=""   # Haploid sample size = 2 x number of diploid individuals in the VCF
MU=""     # Mutation rate per site per generation
MSMC=""   # MSMC output file giving the demographic history
 
TABLE="table${SIZE}_MSMC_nohap"   # Lookup table written by 02, read by 03 and 04

# Chosen from the 03_hyperparam.sh output
WINDOW=100
BPEN=10

# Window size for the final averaged map made by 06 (default 50 kb)
WIN_BP=50000
WIN_KB=$((WIN_BP / 1000))
