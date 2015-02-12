

BWAPATH=$1
NUMTHREADS=$2
RG=$3
BWAINDEX=$4
file=$5
outName=$6

printenv

${BWAPATH} mem -t ${NUMTHREADS} -R $RG ${BWAINDEX} ${file} > ${outName}

