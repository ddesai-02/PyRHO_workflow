VCF=".vcf.gz"
module load bcftools

bcftools annotate -x INFO,^FORMAT/GT ${VCF} -Oz -o VCF_GT.vcf.gz
bcftools index -t VCF_GT.vcf.gz

zgrep -v '^#' VCF_GT.vcf.gz | cut -f1 | sort -u > scaff_names
for scaff in $(cat scaff_names)
do
echo ${scaff}
bcftools view VCF_GT.vcf.gz ${scaff} > ${scaff}.vcf
done

rm VCF_GT.vcf.gz
rm VCF_GT.vcf.gz.tbi
