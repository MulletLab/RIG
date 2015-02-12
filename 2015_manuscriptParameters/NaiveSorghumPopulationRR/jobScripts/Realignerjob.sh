
MEMORY=$1
GATKPATH=$2
NUMTHREADSGATK=$3
REFERENCE=$4
INPUTFILE=$5
INPUTINTERVALS=$6
OUTPUTFILE=$7

module load java1.7.0
java -Xmx${MEMORY} -jar ${GATKPATH} \
	-T IndelRealigner \
        -R ${REFERENCE} \
        -I ${INPUTFILE} \
        -targetIntervals ${INPUTINTERVALS} \
        -o ${OUTPUTFILE}

