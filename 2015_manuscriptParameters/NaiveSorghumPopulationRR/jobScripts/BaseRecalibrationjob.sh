
MEMORY=$1
GATKPATH=$2
NUMTHREADSGATK=$3
REFERENCE=$4
REFERENCE1=$5
OUTPUT=$6
LANEFILEARRAY=${@:7}

for file in ${LANEFILEARRAY[@]}
do
	inputString="${inputString} -I ${file}"
done


module load java1.7.0

java -Xmx${MEMORY} -jar ${GATKPATH} \
	-T BaseRecalibrator \
        -R ${REFERENCE} \
        ${inputString} \
        -knownSites ${REFERENCE1} \
	-nct ${NUMTHREADSGATK} \
        -o ${OUTPUT}



