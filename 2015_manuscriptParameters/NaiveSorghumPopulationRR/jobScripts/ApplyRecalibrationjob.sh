MEMORY=$1
GATKPATH=$2
NUMTHREADSGATK=$3
REFERENCE=$4
RECALTABLE=$5
INPUT=$6
OUTPUT=$7

module load java1.7.0

java -XX:+UseSerialGC -Xmx${MEMORY} -jar ${GATKPATH} \
	-T PrintReads \
	-R ${REFERENCE} \
	-I ${INPUT} \
	-BQSR ${RECALTABLE} \
	-o ${OUTPUT} \
					

