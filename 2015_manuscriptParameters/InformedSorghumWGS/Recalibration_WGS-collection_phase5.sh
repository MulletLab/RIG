
MEMORY="32g"

GROUPID="WGS-Collection_Phase5"
PIPELINEVERSION="IWGB0002"

OUTPUTPATH=/data/ryanabashbash/GATK_pipeline/WGS/Recalibration_WGS-collection_phase5/results_Recalibration_WGS-collection_phase5/

VARIANTSTORECALIBRATE=/data/ryanabashbash/GATK_pipeline/WGS/results_WGS-collection_JointGenotyped/WGS-initialCollection_phase5_jointGenotyped_unfiltered.vcf

FAMILYREFERENCE=/data/ryanabashbash/GATK_pipeline/ReferenceCollections/FamilyReferences/FamilyReference_v002_pulledFromBTx623xIS3620c_01-02-14_family_NRRB1403_filtered.vcf
POPULATIONREFERENCE=/data/ryanabashbash/GATK_pipeline/ReferenceCollections/PopulationReferences/Germplasm_collection_v002_NRRB1402_filtered.vcf
#FAMILYREFERENCE=/data/ryanabashbash/GATK_pipeline/ReferenceCollections/FamilyReferences/FamilyReference_v002_pulledFromPopulationv002.vcf
#WGSREFERENCE=/data/ryanabashbash/GATK_pipeline/ReferenceCollections/WGSreferences/WGS-initialCollection_NWGB0004_recalibrated.vcf


REFERENCEFASTA=/data/ryanabashbash/Sbi1_reference/reference/sbi1.fasta #There also needs to be a fasta index file (.fai) in the same directory as this reference.
GATKPATH=/data/ryanabashbash/Downloads/GenomeAnalysisTK-3.2-2/GenomeAnalysisTK.jar #This is the path of the GATK .jar file

SNPRECALFILESTEM="SNPrecal"
INDELRECALFILESTEM="INDELrecal"

module load java1.7.0

#Priors are phred scaled.
#Q=-10 log_10 P
#P = 10 ^(-Q/10)
#e.g. Q15 = .968377 accuracy
# .99 accuracy = Q20

#Strangely, the family reference needs to be pulled as a subset of the population reference, otherwise it causes a crash.
#I also don't think this can be parallelized on the current file system due to a limit of 1024 files open.

java -Djava.io.tmpdir=/data/ryanabashbash/GATK_pipeline/WGS/WGS-initialCollection_recalibration/tmp -Xmx${MEMORY} -jar ${GATKPATH} \
	-T VariantRecalibrator \
	-R ${REFERENCEFASTA} \
	-input ${VARIANTSTORECALIBRATE} \
        -resource:FamilyReference,known=true,training=true,truth=true,prior=15.0 ${FAMILYREFERENCE} \
	-resource:PopulationReference,known=true,training=true,truth=true,prior=7.0 ${POPULATIONREFERENCE} \
	-an DP \
	-an QD \
	-an FS \
	-an MQ \
	-an MQRankSum \
	-an ReadPosRankSum \
	-mode SNP \
	-tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 97.5 -tranche 95.0 -tranche 90.0 \
	-tranche 85.0 -tranche 80.0 -tranche 75.0 -tranche 70.0 -tranche 65.0 -tranche 60.0 \
	-tranche 55.0 -tranche 50.0 -tranche 25.0 \
	--maxGaussians 4 \
	-recalFile ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${SNPRECALFILESTEM}.recal \
	-tranchesFile ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${SNPRECALFILESTEM}.tranches \
	-rscriptFile ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${SNPRECALFILESTEM}_plots.R 

java -Xmx${MEMORY} -jar ${GATKPATH} \
        -T VariantRecalibrator \
        -R ${REFERENCEFASTA} \
        -input ${VARIANTSTORECALIBRATE} \
        -resource:FamilyReference,known=true,training=true,truth=true,prior=15.0 ${FAMILYREFERENCE} \
        -resource:PopulationReference,known=true,training=true,truth=true,prior=7.0 ${POPULATIONREFERENCE} \
        -an DP \
	-an QD \
        -an FS \
        -an MQRankSum \
        -an ReadPosRankSum \
        -mode INDEL \
        -tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 97.5 -tranche 95.0 -tranche 90.0 \
        -tranche 85.0 -tranche 80.0 -tranche 75.0 -tranche 70.0 -tranche 65.0 -tranche 60.0 \
        -tranche 55.0 -tranche 50.0 -tranche 25.0 \
        --maxGaussians 4 \
        -recalFile ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${INDELRECALFILESTEM}.recal \
        -tranchesFile ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${INDELRECALFILESTEM}.tranches \
        -rscriptFile ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${INDELRECALFILESTEM}_plots.R

java -Xmx${MEMORY} -jar ${GATKPATH} \
	-T ApplyRecalibration \
	-R ${REFERENCEFASTA} \
	-input ${VARIANTSTORECALIBRATE} \
	-mode SNP \
	--ts_filter_level 95.0 \
	-recalFile ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${SNPRECALFILESTEM}.recal \
	-tranchesFile ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${SNPRECALFILESTEM}.tranches \
	-o ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_SNPrecal_95Tranche_sensitive.vcf

java -Xmx${MEMORY} -jar ${GATKPATH} \
	-T ApplyRecalibration \
	-R ${REFERENCEFASTA} \
        -input ${VARIANTSTORECALIBRATE} \
        -mode SNP \
        --ts_filter_level 90.0 \
        -recalFile ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${SNPRECALFILESTEM}.recal \
        -tranchesFile ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${SNPRECALFILESTEM}.tranches \
        -o ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_SNPrecal_90Tranche_specific.vcf

#Apply indel recalibration
java -Xmx${MEMORY} -jar ${GATKPATH} \
	-T ApplyRecalibration \
	-R ${REFERENCEFASTA} \
	-input ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_SNPrecal_95Tranche_sensitive.vcf \
	-mode INDEL \
	--ts_filter_level 95.0 \
	-recalFile ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${INDELRECALFILESTEM}.recal \
	-tranchesFile ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${INDELRECALFILESTEM}.tranches \
	-o ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_recalibrated_95-95Tranche_sensitive.vcf

java -Xmx${MEMORY} -jar ${GATKPATH} \
        -T ApplyRecalibration \
        -R ${REFERENCEFASTA} \
        -input ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_SNPrecal_90Tranche_specific.vcf \
        -mode INDEL \
        --ts_filter_level 90.0 \
        -recalFile ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${INDELRECALFILESTEM}.recal \
        -tranchesFile ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${INDELRECALFILESTEM}.tranches \
	-o ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_recalibrated_90-90Tranche_specific.vcf

rm -f ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_SNPrecal_95Tranche_sensitive.vcf
rm -f ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_SNPrecal_95Tranche_sensitive.vcf.idx
rm -f ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_SNPrecal_90Tranche_specific.vcf
rm -f ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_SNPrecal_90Tranche_specific.vcf.idx
