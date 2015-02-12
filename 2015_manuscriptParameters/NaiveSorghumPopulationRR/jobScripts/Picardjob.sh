
PICARDPATH=$1
INPUTFILE=$2
OUTPUTFILE=$3

java -jar ${PICARDPATH}/SortSam.jar \
        INPUT=${INPUTFILE} \
        OUTPUT=${OUTPUTFILE} \
        CREATE_INDEX=true \
        SORT_ORDER=coordinate
