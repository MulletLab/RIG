
PICARDPATH=$1
OUTPUTFILE=$2

INPUTARRAY=${@:3}

inputString=""
for element in ${INPUTARRAY[@]}
do
	inputString="$inputString INPUT=${element}"
done

java -XX:+UseSerialGC -jar ${PICARDPATH} MergeSamFiles \
	${inputString} \
	OUTPUT=${OUTPUTFILE} \
	CREATE_INDEX=true \
	SORT_ORDER=coordinate 

