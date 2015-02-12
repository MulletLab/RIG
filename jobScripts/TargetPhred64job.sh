
MEMORY=$1
GATKPATH=$2
NUMTHREADSGATK=$3
REFERENCE=$4
INTERVALS=$5
INPUTFILE=$6
OUTPUTFILE=$7

module load java1.7.0
java -XX:+UseSerialGC -Xmx${MEMORY} -jar ${GATKPATH} \
	-T RealignerTargetCreator \
	-R ${REFERENCE} \
	-L ${INTERVALS} \
	-I ${INPUTFILE} \
	-o ${OUTPUTFILE} \
	-nt ${NUMTHREADSGATK} \
        --fix_misencoded_quality_scores
