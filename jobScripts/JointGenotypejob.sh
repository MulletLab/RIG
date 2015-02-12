
TMPDIR=$1
MEMORY=$2
GATKPATH=$3
GATKNUMTHREADS=$4
REFERENCE=$5
INTERVALS=$6
INPUTFILE=$7
OUTPUTFILE=$8

module load java1.7.0
java -Djava.io.tmpdir=${TMPDIR} -Xmx${MEMORY} -jar ${GATKPATH} \
	-T GenotypeGVCFs \
        -R ${REFERENCE}  \
	-L ${INTERVALS} \
	-V ${INPUTFILE} \
        -o ${OUTPUTFILE} \
        -nt ${GATKNUMTHREADS} 

