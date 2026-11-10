#!/bin/bash
#SBATCH --account=def-shaferab
#SBATCH --job-name=split_vcf
#SBATCH --mem=4G
#SBATCH --time=2:59:00
#SBATCH --output=split_vcf_%j.out
 
# Strip the VCF down to genotypes only and split it into one VCF per scaffold.
# Input should already be filtered to biallelic SNPs.

source config.sh
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
