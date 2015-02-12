
MEMORY=$1
GATKPATH=$2
GATKNUMTHREADS=$3
REFERENCE=$4
INTERVALFILE=$5
INPUTFILE=$6
OUTPUTFILE=$7

module load java1.7.0
java -Xmx${MEMORY} -jar ${GATKPATH} \
	-T HaplotypeCaller \
        -R ${REFERENCE}  \
	-I ${INPUTFILE} \
	-L ${INTERVALFILE} \
        -o ${OUTPUTFILE} \
	--genotyping_mode DISCOVERY \
	-stand_emit_conf 30 \
	-stand_call_conf 30 \
	-nct ${GATKNUMTHREADS} \
	--emitRefConfidence GVCF \
	--variant_index_type LINEAR \
	--variant_index_parameter 128000

