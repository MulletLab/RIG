#RIG Configuration file

NUMTHREADSBWA=12   #Number of threads used by BWA for alignment
GATKNUMTHREADS=7  #Number of threads used by some of the GATK's walkers
GATKNUMCPUTHREADS=7  #Number of cpu threads used by some of the GATK's walkers
JAVAMEMORY="32g"   #Amount of memory allocated to Java
GLOBALQSUBOPTIONS="-q normal.q"  #String that gets passed to every qsub call

GROUPID="WGS-Phase1A"  #Group ID used to name output files

#File paths
#The parent directory of samples will be used as the read group, so place samples from the same read group in the same directory.
FASTQDIRS[0]=/data/ryanabashbash/raw_data/009_12-18-14/BTx623_TAMU/
FASTQDIRS[1]=/data/ryanabashbash/raw_data/009_12-18-14/IS3620C_TAMU/
FASTQDIRS[2]=/data/ryanabashbash/raw_data/009_12-18-14/Tx7000_TAMU/
FASTQDIRS[3]=/data/ryanabashbash/raw_data/009_12-18-14/BTx642_TAMU/
FASTQDIRS[4]=/data/ryanabashbash/raw_data/009_12-18-14/Hegari_TAMU/

FAMILYREFERENCE=/data/ryanabashbash/GATK_pipeline/ReferenceCollections/FamilyReferences/FamilyReferenceCollection_Sbi3_v0001.vcf
POPULATIONREFERENCE=/data/ryanabashbash/GATK_pipeline/ReferenceCollections/PopulationReferences/GermplasmCollection_NgoMIV_v001_NRRB2002_filtered_failedExcluded.vcf
WGSREFERENCE=/data/ryanabashbash/GATK_pipeline/ReferenceCollections/WGSreferences/WGS-Phase1_IIWGB1002_recalibrated_990-990Tranche_sensitive.vcf

INTERVALFILE=/data/ryanabashbash/GATK_pipeline/ReferenceCollections/intervals/sorghum/Sbi3/wholeGenome/Sbi3WholeGenome.intervals
OUTPUTPATH=/data/ryanabashbash/GATK_pipeline/WGS/IWGB/data/results_WGS-Phase1A/
LOGPATH=/data/ryanabashbash/GATK_pipeline/WGS/IWGB/data/log_WGS-Phase1A/
TMPPATH=/data/ryanabashbash/tmp/

REFERENCEFASTA=/data/ryanabashbash/Sbi3_reference/reference/Sbi3.fasta #There also needs to be a fasta index file (.fai) in the same directory as this reference.
PICARDPATH=/data/ryanabashbash/Downloads/picard-tools-1.128/picard.jar  #This is the path of the directory containing the Picard tools
BWAPATH=/data/ryanabashbash/Downloads/bwa-0.7.12/bwa  #This is the path of the BWA executable
BWAINDEX=/data/ryanabashbash/Sbi3_reference/Sbi3_BWAindex/Sbi3  #This is the path of the reference index suffix
GATKPATH=/data/ryanabashbash/Downloads/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar #This is the path of the GATK .jar file

RIGPATH=/data/ryanabashbash/GATK_pipeline/src/RIG_src/

source ${RIGPATH}util/RIG_utilFunctions.sh
#Choice of pipeline. Comment out all others
#source ${RIGPATH}IWGB/TwoNonInterleavedPairedEndPhred33ToBam.sh
#source ${RIGPATH}NRRB/SingleEndPhred33ToCalls.sh
#source ${RIGPATH}IRRB/SingleEndPhred33ToCalls.sh
#source ${RIGPATH}IWGB/TwoInterleavedPairedEndDifferentQualsToBam.sh
#source ${RIGPATH}IWGB/SingleInterleavedPairedEndPhred33ToBam.sh
#source ${RIGPATH}IWGB/MultiInterleavedPairedEndPhred64ToBam.sh
#source ${RIGPATH}IWGB/SingleInterleavedPairedEndPhred64ToBam.sh
source ${RIGPATH}IWGB/TwoNonInterleavedPairedEndPhred33ToBam.sh
