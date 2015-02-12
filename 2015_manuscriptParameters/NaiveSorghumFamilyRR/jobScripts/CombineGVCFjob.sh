MEMORY=$1
GATKPATH=$2
GATKNUMTHREADS=$3
REFERENCE=$4
OUTPUTPATH=$5
OUTPUTFILE=$6
GVCFARRAY=${@:7}

module load java1.7.0

for file in ${GVCFARRAY[@]}
do
#	dirName=$(dirname $file)
#        parentDir=${dirName##*/}
#        stripPath=${file##*/}
#        sampleID=${stripPath%.GVCF.vcf}
	inputString="${inputString} -V ${file}"
done

java -Xmx${MEMORY} -jar ${GATKPATH} \
        -T CombineGVCFs \
        -R ${REFERENCE}  \
        ${inputString} \
        -o ${OUTPUTFILE}


