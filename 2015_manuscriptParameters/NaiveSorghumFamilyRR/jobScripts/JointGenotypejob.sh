
MEMORY=$1
GATKPATH=$2
GATKNUMTHREADS=$3
REFERENCE=$4
INTERVALFILE=$5
INPUTFILE=$6
OUTPUTFILE=$7

module load java1.7.0
java -Xmx${MEMORY} -jar ${GATKPATH} \
	-T GenotypeGVCFs \
        -R ${REFERENCE}  \
        -L ${INTERVALFILE} \
	-V ${INPUTFILE} \
        -o ${OUTPUTFILE} \
        -nt ${GATKNUMTHREADS} 

