
PICARDPATH=$1
INPUTFILE=$2
OUTPUTFILE=$3


java -XX:+UseSerialGC -jar ${PICARDPATH} SortSam \
        INPUT=${INPUTFILE} \
        OUTPUT=${OUTPUTFILE} \
        CREATE_INDEX=true \
        SORT_ORDER=coordinate
