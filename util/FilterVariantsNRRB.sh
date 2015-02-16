
INPUTFILE=/data/ryanabashbash/GATK_pipeline/RAD_seq/Families/BTx623xIS3620c_01-02-14/results/BTx623xIS3620C_family_01-02-14_NRRB2001_unfiltered.vcf
OUTPUTFILE=/data/ryanabashbash/GATK_pipeline/RAD_seq/Families/BTx623xIS3620c_01-02-14/results/BTx623xIS3620C_family_01-02-14_NRRB2001.vcf
MEMORY="1g"
GATKPATH=/data/ryanabashbash/Downloads/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar
REFERENCE=/data/ryanabashbash/Sbi3_reference/reference/Sbi3.fasta
INTERVALS=/data/ryanabashbash/GATK_pipeline/ReferenceCollections/intervals/sorghum/Sbi3/reducedRepresentation/NgoMIVintervals.intervals

module load java1.7.0

java -Xmx${MEMORY} -jar ${GATKPATH} \
        -T SelectVariants \
	-R ${REFERENCE} \
	-L ${INTERVALS} \
        --variant ${INPUTFILE} \
        -o ${OUTPUTFILE%.*}_tmp.vcf \
        --restrictAllelesTo BIALLELIC \
        --selectTypeToInclude INDEL \
        --selectTypeToInclude SNP \
        --maxIndelSize 10

#Determine number of samples:
numSamples=`awk '{
if (substr($0, 1, 6) == "#CHROM") {
        numSamples = NF - 9
        print numSamples
        exit 0
}
}' ${OUTPUTFILE%.*}_tmp.vcf`

AFThresholdMin="0.05" #Minor allele frequency
AFThresholdMax="0.95" 
ANThreshold=$(echo "(0.6*${numSamples}*2)/1" | bc) # Number of alleles called; divide by one to round the float

java -Xmx${MEMORY} -jar ${GATKPATH} \
        -T VariantFiltration \
        -R ${REFERENCE}  \
	-L ${INTERVALS} \
        -V ${OUTPUTFILE%.*}_tmp.vcf \
        -o ${OUTPUTFILE%.*}_tmp2.vcf \
        --filterExpression "DP < 10" \
        --filterName "DPfailMin" \
        --filterExpression "QD < 5.0" \
        --filterName "QDfail" \
        --filterExpression "MQ < 30.0" \
        --filterName "MQfail" \
        --filterExpression "MQRankSum < -10.0" \
        --filterName "MQRankSumfail" \
        --filterExpression "BaseQRankSum < -10.0" \
        --filterName "BaseQRankSumfail" \
	--filterExpression "AN < ${ANThreshold}" \
	--filterName "ANfail" \
	--filterExpression "AF < ${AFThresholdMin}" \
	--filterName "AFfailMin" \
	--filterExpression "AF > ${AFThresholdMax}" \
	--filterName "AFfailMax"

java -Xmx${MEMORY} -jar ${GATKPATH} \
        -T SelectVariants \
        -R ${REFERENCE} \
	-L ${INTERVALS} \
        --variant ${OUTPUTFILE%.*}_tmp2.vcf \
        -o ${OUTPUTFILE%.*}_filtered_failedExcluded.vcf \
        --excludeFiltered

java -Xmx${MEMORY} -jar ${GATKPATH} \
        -T SelectVariants \
        -R ${REFERENCE} \
	-L ${INTERVALS} \
        --variant ${OUTPUTFILE%.*}_tmp2.vcf \
        -o ${OUTPUTFILE%.*}_filtered.vcf

rm ${OUTPUTFILE%.*}_tmp.vcf*
rm ${OUTPUTFILE%.*}_tmp2.vcf*

