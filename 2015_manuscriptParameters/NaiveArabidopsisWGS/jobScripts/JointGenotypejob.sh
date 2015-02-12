
MEMORY=$1
GATKPATH=$2
GATKNUMTHREADS=$3
REFERENCE=$4
INPUTFILE=$5
OUTPUTFILE=$6

module load java1.7.0
java -Djava.io.tmpdir=/data/ryanabashbash/GATK_pipeline/WGS/tmp -Xmx${MEMORY} -jar ${GATKPATH} \
	-T GenotypeGVCFs \
        -R ${REFERENCE}  \
	-V ${INPUTFILE} \
        -o ${OUTPUTFILE} \
        -nt ${GATKNUMTHREADS} 

