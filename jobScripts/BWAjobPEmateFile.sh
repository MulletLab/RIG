

BWAPATH=$1
NUMTHREADS=$2
RG=$3
BWAINDEX=$4
file=$5
fileMate=$6
outName=$7

printenv

${BWAPATH} mem -t ${NUMTHREADS} -R $RG ${BWAINDEX} ${file} ${fileMate} > ${outName}

