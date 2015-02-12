
MEMORY=$1
GATKPATH=$2
NUMTHREADSGATK=$3
REFERENCE=$4
INPUTFILE=$5
OUTPUTFILE=$6

module load java1.7.0
java -Xmx${MEMORY} -jar ${GATKPATH} \
	-T PrintReads \
        -R ${REFERENCE} \
        -I ${INPUTFILE} \
        -o ${OUTPUTFILE} \
	--fix_misencoded_quality_scores 

