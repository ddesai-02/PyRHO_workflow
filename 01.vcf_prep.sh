VCF="/home/devan/projects/def-shaferab/devan/Odocoileus_virginianus/fasteprr/pyrho_WTD/WTD_sex_filt_nokey.vcf.gz"
module load bcftools

bcftools annotate -x INFO,^FORMAT/GT ${VCF} -Oz -o VCF_GT.vcf.gz
bcftools index VCF_GT.vcf.gz

zgrep -v '^#' VCF_GT.vcf.gz | cut -f1 | sort -u > scaff_names
for scaff in $(cat scaff_names)
do
echo ${scaff}
bcftools view VCF_GT.vcf.gz ${scaff} > ${scaff}.vcf
done

rm VCF_GT.vcf.gz
