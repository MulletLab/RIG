
MEMORY=$1
GATKPATH=$2
NUMTHREADSGATK=$3
REFERENCE=$4
INTERVALS=$5
INPUTFILE=$6
INPUTINTERVALS=$7
OUTPUTFILE=$8

module load java1.7.0
java -XX:+UseSerialGC -Xmx${MEMORY} -jar ${GATKPATH} \
	-T IndelRealigner \
        -R ${REFERENCE} \
	-L ${INTERVALS} \
        -I ${INPUTFILE} \
        -targetIntervals ${INPUTINTERVALS} \
        -o ${OUTPUTFILE} \
	--fix_misencoded_quality_scores 

