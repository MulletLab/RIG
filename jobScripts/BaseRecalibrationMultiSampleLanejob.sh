
MEMORY=$1
GATKPATH=$2
NUMTHREADSGATK=$3
REFERENCE=$4
INTERVALS=$5
KNOWNSITES=$6
OUTPUT=$7
LANEFILEARRAY=${@:8}

for file in ${LANEFILEARRAY[@]}
do
	inputString="${inputString} -I ${file}"
done


module load java1.7.0

java -Xmx${MEMORY} -jar ${GATKPATH} \
	-T BaseRecalibrator \
        -R ${REFERENCE} \
	-L ${INTERVALS} \
        ${inputString} \
        -knownSites ${KNOWNSITES} \
	-nct ${NUMTHREADSGATK} \
        -o ${OUTPUT}



