#RIG Configuration file

NUMTHREADSBWA=7   #Number of threads used by BWA for alignment
GATKNUMTHREADS=7  #Number of threads used by some of the GATK's walkers
GATKNUMCPUTHREADS=7  #Number of cpu threads used by some of the GATK's walkers
JAVAMEMORY="32g"   #Amount of memory allocated to Java

GROUPID="BTx623xIS3620c_family"  #Group ID used to name output files

#File paths
#The parent directory of samples will be used as the read group, so place samples from the same read group in the same directory.
FASTQDIRS[0]=/data/ryanabashbash/GATK_pipeline/RAD_seq/Families/BTx623xIS3620c_01-02-14/data/004_lane3/
FASTQDIRS[1]=/data/ryanabashbash/GATK_pipeline/RAD_seq/Families/BTx623xIS3620c_01-02-14/data/004_lane4/
FASTQDIRS[2]=/data/ryanabashbash/GATK_pipeline/RAD_seq/Families/BTx623xIS3620c_01-02-14/data/004_lane5/
FASTQDIRS[3]=/data/ryanabashbash/GATK_pipeline/RAD_seq/Families/BTx623xIS3620c_01-02-14/data/004_lane6/
FASTQDIRS[4]=/data/ryanabashbash/GATK_pipeline/RAD_seq/Families/BTx623xIS3620c_01-02-14/data/005_lane1/
FASTQDIRS[5]=/data/ryanabashbash/GATK_pipeline/RAD_seq/Families/BTx623xIS3620c_01-02-14/data/005_lane2/

FAMILYREFERENCE=NULL #/data/ryanabashbash/GATK_pipeline/ReferenceCollections/FamilyReferences/FamilyReference_v002_pulledFromBTx623xIS3620c_01-02-14_family_NRRB1403_filtered.vcf
POPULATIONREFERENCE=NULL #/data/ryanabashbash/GATK_pipeline/ReferenceCollections/PopulationReferences/GermplasmCollection_v004_IRRB0002_recalibrated_975-975Tranche_sensitive.vcf
WGSREFERENCE=NULL #/data/ryanabashbash/GATK_pipeline/ReferenceCollections/WGSreferences/WGS-Collection_v002_IWGB0002_recalibrated_95-95Tranche_sensitive.vcf

INTERVALFILE=/data/ryanabashbash/GATK_pipeline/ReferenceCollections/intervals/sorghum/Sbi3/reducedRepresentation/NgoMIVintervals.intervals
OUTPUTPATH=/data/ryanabashbash/GATK_pipeline/RAD_seq/Families/BTx623xIS3620c_01-02-14/results/
LOGPATH=/data/ryanabashbash/GATK_pipeline/RAD_seq/Families/BTx623xIS3620c_01-02-14/log/

REFERENCEFASTA=/data/ryanabashbash/Sbi3_reference/reference/Sbi3.fasta #There also needs to be a fasta index file (.fai) in the same directory as this reference.
PICARDPATH=/data/ryanabashbash/Downloads/picard-tools-1.128/picard.jar  #This is the path of the directory containing the Picard tools
BWAPATH=/data/ryanabashbash/Downloads/bwa-0.7.12/bwa  #This is the path of the BWA executable
BWAINDEX=/data/ryanabashbash/Sbi3_reference/Sbi3_BWAindex/Sbi3  #This is the path of the reference index suffix
GATKPATH=/data/ryanabashbash/Downloads/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar #This is the path of the GATK .jar file

RIGPATH=/data/ryanabashbash/GATK_pipeline/src/RIG_src/

source ${RIGPATH}util/RIG_utilFunctions.sh
#Choice of pipeline. Comment out all others
#source ${RIGPATH}IWGB/TwoNonInterleavedPairedEndPhred33ToBam.sh
source ${RIGPATH}NRRB/SingleEndPhred33ToCalls.sh
#source ${RIGPATH}IRRB/SingleEndPhred33ToCalls.sh
#source ${RIGPATH}IWGB/TwoInterleavedPairedEndDifferentQualsToBam.sh
#source ${RIGPATH}IWGB/SingleInterleavedPairedEndPhred33ToBam.sh
#source ${RIGPATH}IWGB/MultiInterleavedPairedEndPhred64ToBam.sh
#source ${RIGPATH}IWGB/SingleInterleavedPairedEndPhred64ToBam.sh
