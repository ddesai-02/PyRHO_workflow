# Convert to CM and window averages
WINDOW="50000" # Window Size
WINKB="50" # Window Size in kb
EDGE_THR="8.16"  # cM/Mb; 99th percentile of 1-Mb windows in the initial map

for rmap in $(ls *.rmap |  cut -f1-2 -d '.')
do
# Convert to CM
awk -f convert_Output_pyrho_cM_Mb.awk  ${rmap}.rmap > ${rmap}.rmapCM
# Mask recombination peaks (>100) and 50 surrounding SNPs
awk -v w=50 -f mask.awk ${rmap}.rmapCM > ${rmap}.rmapMasked
# Mask the first/last pyrho block of the scaffold if its rate > EDGE_THR.
# Blocks are identified on the unmasked cM map (rmapCM); rates are set to 0
# in the masked map, the same convention mask.awk uses.
awk -v thr=${EDGE_THR} -v s=${rmap} '
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
' ${rmap}.rmapCM ${rmap}.rmapMasked > ${rmap}.rmapEdge
# Add chrom name to column1 and DROP masked intervals (rate 0) so they are
# treated as missing data, not as zero recombination. pyrho never outputs an
# exact 0, so rate == 0 identifies masked sequence.
awk '($3+0) != 0 {print "'${rmap}'", $0}' ${rmap}.rmapEdge > ${rmap}.rmap2
# 1-Mb windows
python3 Rec_windows.py ${rmap}.rmap2 ${WINDOW} > ${rmap}.rmap${WINKB}kb
done 2> edge_mask.log

echo "Edge blocks masked: $(grep -c 'edge-masked' edge_mask.log)"
grep -v 'edge-masked' edge_mask.log

cat *.rmap${WINKB}kb > combined_scaffolds_${WINKB}kb.rmap
sed -e 's/^/Pyrho\t/' -e 's/HiC_scaffold_/chr/' -e 's/\.vcf//' combined_scaffolds_${WINKB}kb.rmap > pyrho_Urs_${WINKB}kb.txt

echo "Final file created: pyrho_Urs_${WINKB}kb.txt"

# Create raw intervals for genomic features (TEs)
for f in *.rmapEdge; do
    scaff=$(basename "$f" .rmapEdge)
    awk -v chrom="$scaff" '($3+0) != 0 {print chrom "\t" $1 "\t" $2 "\t" $3}' "$f"
done > pyrho_masked.bed

# Masked sequence, for the Methods
cat *.rmapEdge | awk '{L=$2-$1; t+=L} ($3+0)==0 {z+=L} END {printf "Masked (excluded): %.1f Mb of %.1f Mb (%.2f%%)\n", z/1e6, t/1e6, 100*z/t}'

# Genome-wide recombination rate over UNMASKED sequence (length-weighted)
awk '{len = $3 - $2; sum += $4 * len; total_len += len} END {if (total_len > 0) print sum / total_len}' pyrho_masked.bed

# Remove intermediate files
rm *.rmap2
rm *.rmapCM
rm *.rmapMasked *.rmapEdge
rm combined_scaffolds_${WINKB}kb.rmap
