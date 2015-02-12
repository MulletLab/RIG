MEMORY=$1
GATKPATH=$2
GATKNUMTHREADS=$3
REFERENCE=$4
INTERVALS=$5
OUTPUTPATH=$6
OUTPUTFILE=$7
GVCFARRAY=${@:8}

module load java1.7.0

for file in ${GVCFARRAY[@]}
do
	inputString="${inputString} -V ${file}"
done

java -XX:+UseSerialGC -Xmx${MEMORY} -jar ${GATKPATH} \
        -T CombineGVCFs \
        -R ${REFERENCE}  \
	-L ${INTERVALS} \
        ${inputString} \
        -o ${OUTPUTFILE}


