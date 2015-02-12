
MEMORY=$1
GATKPATH=$2
NUMTHREADSGATK=$3
REFERENCE=$4
INTERVALS=$5
INPUTFILE=$6
REFERENCE1=$7
OUTPUTFILE=$8

module load java1.7.0
java -XX:+UseSerialGC -Xmx${MEMORY} -jar ${GATKPATH} \
	-T BaseRecalibrator \
	-L ${INTERVALS} \
        -R ${REFERENCE} \
        -I ${INPUTFILE} \
        -knownSites ${REFERENCE1} \
	-nct ${NUMTHREADSGATK} \
        -o ${INPUTFILE}.recal.table

java -XX:+UseSerialGC -Xmx${MEMORY} -jar ${GATKPATH} \
	-T PrintReads \
	-R ${REFERENCE} \
	-L ${INTERVALS} \
	-I ${INPUTFILE} \
	-BQSR ${INPUTFILE}.recal.table \
	-o ${OUTPUTFILE}

java -XX:+UseSerialGC -Xmx${MEMORY} -jar ${GATKPATH} \
	-T BaseRecalibrator \
	-R ${REFERENCE} \
	-L ${INTERVALS} \
	-I ${OUTPUTFILE} \
	-knownSites ${REFERENCE1} \
	-nct ${NUMTHREADSGATK} \
	-o ${OUTPUTFILE}.recal.table


