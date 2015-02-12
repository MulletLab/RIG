#!/bin/bash
#$ -pe mpi 8
#$ -q normal.q
#$ -l mem_free=32g
#$ -N JointGenotype

module load java1.7.0
rm -f $HOME/*.*[oe]*

NUMTHREADSBWA=8 # Probably good to set this to maximum number of processors available?
GATKNUMSCATTER=4 #On a single machine with SGE, probably won't be much benefit in terms of speed to have num scatter * num cpu threads  be greater than num processing units. However, this reduces the amount of memory each job needs so cranking it up can make jobs that are too large on their own require less memory
GATKNUMTHREADS=8
GATKNUMCPUTHREADS=8  #On a single machine with SGE, this will dictate the number of jobs that can run (NumProcessors/NumCPUThreads = NumJobs). 64 GB of memory struggles with 7 jobs of Haplotype Caller when NumScatter is 7. 
MEMORY="64g"
GATKPATH=/data/ryanabashbash/Downloads/GenomeAnalysisTK-3.1-1/GenomeAnalysisTK.jar
OUTPUTFILE=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/results_JointGenotyping/Germplasm_collection_v003_IRRB0002.vcf
REFERENCE=/data/ryanabashbash/Sbi1_reference/reference/sbi1.fasta #There also needs to be a fasta index file (.fai) in the same directory as this reference.
INTERVALFILE=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/intervals/NgoMIVintervals.intervals

module load java1.7.0

java -Xmx${MEMORY} -jar ${GATKPATH} \
        -T GenotypeGVCFs \
        -R ${REFERENCE}  \
        -L ${INTERVALFILE} \
        -V /data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/results_G-SAP/GermplasmCollection_G-SAP_IRRB0002.popGVCF.vcf \
	-V /data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/results_E-SAP/GermplasmCollection_E-SAP_IRRB0002.popGVCF.vcf \
	-V /data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/results_miscPanels/GermplasmCollection_miscPanels_IRRB0002.popGVCF.vcf \
	-V /data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/results_crossParents/GermplasmCollection_crossParents_IRRB0002.popGVCF.vcf \
        -o ${OUTPUTFILE%.*}_unfiltered.vcf \
        -nt ${GATKNUMTHREADS}

java -Xmx${MEMORY} -jar ${GATKPATH} \
        -T SelectVariants \
        -R ${REFERENCE} \
        --variant ${OUTPUTFILE%.*}_unfiltered.vcf \
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
        -L ${INTERVALFILE} \
        -V ${OUTPUTFILE%.*}_tmp.vcf \
        -o ${OUTPUTFILE%.*}_tmp2.vcf \
        --filterExpression "DP < 10" \
        --filterName "DPfail" \
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
        --variant ${OUTPUTFILE%.*}_tmp2.vcf \
        -o ${OUTPUTFILE%.*}_filtered.vcf \
        --excludeFiltered

rm ${OUTPUTFILE%.*}_tmp.vcf*
rm ${OUTPUTFILE%.*}_tmp2.vcf*
