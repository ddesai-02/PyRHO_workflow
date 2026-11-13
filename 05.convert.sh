#!/bin/bash
#SBATCH --account=def-shaferab
#SBATCH --job-name=pyconvert
#SBATCH --mem=4G
#SBATCH --time=0:59:00
#SBATCH --output=pyconvert_%j.out

# Convert pyrho maps to cM/Mb, mask recombination spikes, and derive the
# edge-masking threshold used by 06: the 99th percentile of 1-Mb window
# rates across the spike-masked map.

module load python/3.11
set -euo pipefail

THR_WIN=1000000   # Window size (bp) for the threshold
THR_PCT=0.99      # Percentile

for f in *.rmap; do
    scaff=${f%.rmap}
    # Columns out: start, end, rate (cM/Mb), cumulative map (cM), interval width (bp)
    awk -f convert_Output_pyrho_cM_Mb.awk "${f}" > "${scaff}.rmapCM"
    # Mask recombination peaks (>100 cM/Mb) and 50 surrounding SNPs (rate set to 0)
    awk -v w=50 -f mask.awk "${scaff}.rmapCM" > "${scaff}.rmapMasked"
    # 1-Mb windows of the spike-masked map; masked intervals dropped as missing data
    awk -v c="${scaff}" '($3+0) != 0 {print c, $0}' "${scaff}.rmapMasked" | python3 Rec_windows.py - "${THR_WIN}"
done > pyrho_spikemasked_1Mb.txt

# Percentile with linear interpolation between order statistics (as numpy/R default)
cut -f4 pyrho_spikemasked_1Mb.txt | sort -g | awk -v p="${THR_PCT}" '
  { x[NR] = $1 }
  END {
    h = (NR - 1) * p + 1; lo = int(h)
    v = (lo < NR) ? x[lo] + (h - lo) * (x[lo + 1] - x[lo]) : x[NR]
    printf "%.2f\n", v
  }' > edge_threshold.txt

echo "Converted and spike-masked $(ls *.rmapMasked | wc -l) maps"
echo "Edge threshold (${THR_PCT} quantile of $(wc -l < pyrho_spikemasked_1Mb.txt) spike-masked 1-Mb windows): $(cat edge_threshold.txt) cM/Mb"
