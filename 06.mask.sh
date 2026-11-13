#!/bin/bash
#SBATCH --account=def-shaferab
#SBATCH --job-name=pymask
#SBATCH --mem=4G
#SBATCH --time=0:59:00
#SBATCH --output=pymask_%j.out

# Mask spikes and high-rate scaffold edges, then average into windows.
# Needs the *.rmapCM files and edge_threshold.txt from 05.convert.sh.

module load python/3.11
set -euo pipefail

source config.sh

EDGE_THR=$(cat edge_threshold.txt)   # cM/Mb, from 05.convert.sh

for f in *.rmapCM; do
    rmap=${f%.rmapCM}
    # Mask recombination peaks (>100 cM/Mb) and 50 surrounding SNPs
    awk -v w=50 -f mask.awk "${rmap}.rmapCM" > "${rmap}.rmapMasked"
    # Mask the first/last pyrho block of the scaffold if its rate > EDGE_THR.
    # Blocks are identified on the unmasked cM map (rmapCM); rates are set to 0
    # in the masked map, the same convention mask.awk uses.
    awk -v thr="${EDGE_THR}" -v s="${rmap}" '
      NR==FNR { r[FNR]=$3; n=FNR; next }
      FNR==1 {
        OFS = (index($0, "\t") ? "\t" : " ")
        fe=1; while (fe<n && r[fe+1]==r[1]) fe++      # last line of first block
        ls=n; while (ls>1 && r[ls-1]==r[n]) ls--      # first line of last block
        mf = (r[1]+0 > thr); ml = (r[n]+0 > thr)
        if (mf) printf "%s edge-masked FIRST block, rate %s\n", s, r[1] > "/dev/stderr"
        if (ml) printf "%s edge-masked LAST block, rate %s\n",  s, r[n] > "/dev/stderr"
      }
      { if ((mf && FNR<=fe) || (ml && FNR>=ls)) $3=0; print }
    ' "${rmap}.rmapCM" "${rmap}.rmapMasked" > "${rmap}.rmapEdge"
    # Add chrom name to column 1 and DROP masked intervals (rate 0) so they are
    # treated as missing data, not as zero recombination. pyrho never outputs an
    # exact 0, so rate == 0 identifies masked sequence.
    awk -v c="${rmap}" '($3+0) != 0 {print c, $0}' "${rmap}.rmapEdge" > "${rmap}.rmap2"
    # Window averages
    python3 Rec_windows.py "${rmap}.rmap2" "${WIN_BP}" > "${rmap}.rmap${WIN_KB}kb"
done 2> edge_mask.log

echo "Edge threshold: ${EDGE_THR} cM/Mb"
echo "Edge blocks masked: $(grep -c 'edge-masked' edge_mask.log || true)"
grep -v 'edge-masked' edge_mask.log || true   # any other errors/warnings

cat *.rmap${WIN_KB}kb > combined_scaffolds_${WIN_KB}kb.rmap
sed -e 's/^/Pyrho\t/' -e 's/HiC_scaffold_/chr/' -e 's/\.vcf//' combined_scaffolds_${WIN_KB}kb.rmap > pyrho_Urs_${WIN_KB}kb.txt

echo "Final file created: pyrho_Urs_${WIN_KB}kb.txt"

# Unmasked raw intervals for genomic-feature analyses (TEs)
for f in *.rmapEdge; do
    scaff=${f%.rmapEdge}
    awk -v chrom="${scaff}" '($3+0) != 0 {print chrom "\t" $1 "\t" $2 "\t" $3}' "${f}"
done > pyrho_masked.bed

# Masked sequence, for the Methods
cat *.rmapEdge | awk '{L=$2-$1; t+=L} ($3+0)==0 {z+=L} END {printf "Masked (excluded): %.1f Mb of %.1f Mb (%.2f%%)\n", z/1e6, t/1e6, 100*z/t}'

# Genome-wide recombination rate over UNMASKED sequence (length-weighted)
awk '{len = $3 - $2; sum += $4 * len; total_len += len} END {if (total_len > 0) printf "Genome-wide mean (unmasked): %s cM/Mb\n", sum / total_len}' pyrho_masked.bed

# Remove intermediate files (rmapCM is kept so 06 can be rerun without 05)
rm -f *.rmapMasked *.rmapEdge *.rmap2 *.rmap${WIN_KB}kb combined_scaffolds_${WIN_KB}kb.rmap
