#RIG Configuration file

NUMTHREADSBWA=7   #Number of threads used by BWA for alignment
GATKNUMTHREADS=7  #Number of threads used by some of the GATK's walkers
GATKNUMCPUTHREADS=7  #Number of cpu threads used by some of the GATK's walkers
JAVAMEMORY="32g"   #Amount of memory allocated to Java

GROUPID="BTx623_Sbi1_009_12-18-14"  #Group ID used to name output files

#File paths
#The parent directory of samples will be used as the read group, so place samples from the same read group in the same directory.
BAMDIRS[0]=/data/ryanabashbash/GATK_pipeline/WGS/data/results_009_12-18-14/

FAMILYREFERENCE=NULL #/data/ryanabashbash/GATK_pipeline/ReferenceCollections/FamilyReferences/FamilyReference_v002_pulledFromBTx623xIS3620c_01-02-14_family_NRRB1403_filtered.vcf
POPULATIONREFERENCE=NULL #/data/ryanabashbash/GATK_pipeline/ReferenceCollections/PopulationReferences/GermplasmCollection_v004_IRRB0002_recalibrated_975-975Tranche_sensitive.vcf
WGSREFERENCE=NULL #/data/ryanabashbash/GATK_pipeline/ReferenceCollections/WGSreferences/WGS-Collection_v002_IWGB0002_recalibrated_95-95Tranche_sensitive.vcf

#INTERVALLISTDIR contains .intervals files based on how the user wants HaplotypeCaller jobs to be scattered. The easiest case is to make a .intervals file that contains each chromosome.
INTERVALLISTDIR=/data/ryanabashbash/GATK_pipeline/ReferenceCollections/intervals/sorghum/Sbi1/wholeGenome/individualChromosomes/
#INTERVALFILE is one .intervals file that has all intervals of interest. Generally, this will be all of the intervals contained in the files of INTERVALLISTDIR put into one file.
INTERVALFILE=/data/ryanabashbash/GATK_pipeline/ReferenceCollections/intervals/sorghum/Sbi1/wholeGenome/Sbi1WholeGenome.intervals

OUTPUTPATH=/data/ryanabashbash/GATK_pipeline/WGS/results_009_12-18-14/
LOGPATH=/data/ryanabashbash/GATK_pipeline/WGS/log_009_12-18-14/
TMPPATH=/data/ryanabashbash/tmp/

REFERENCEFASTA=/data/ryanabashbash/Sbi1_reference/reference/sbi1.fasta #There also needs to be a fasta index file (.fai) in the same directory as this reference.
PICARDPATH=/data/ryanabashbash/Downloads/picard-tools-1.128/picard.jar  #This is the path of the directory containing the Picard tools
BWAPATH=/data/ryanabashbash/Downloads/bwa-0.7.12/bwa  #This is the path of the BWA executable
BWAINDEX=/data/ryanabashbash/Sbi3_reference/Sbi3_BWAindex/Sbi3  #This is the path of the reference index suffix
GATKPATH=/data/ryanabashbash/Downloads/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar #This is the path of the GATK .jar file

RIGPATH=/data/ryanabashbash/GATK_pipeline/src/RIG_src/

source ${RIGPATH}util/RIG_utilFunctions.sh
#Choice of pipeline. Comment out all others
source ${RIGPATH}IWGB/BamsToVcf.sh
