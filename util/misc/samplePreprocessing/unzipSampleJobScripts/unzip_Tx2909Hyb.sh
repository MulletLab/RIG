#Energy sorghum panel
NUMTHREADS=$1
PARENTDIR=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/NRRB/data
COHORTID="Tx2909Hyb"
rm -f ${PARENTDIR}/008_lane6/*.fastq*

AWK_BODY='{
readName=$0
getline
readSequence=$0
getline
plusSign=$0
getline
qualScore=$0
if (substr(readSequence, 1, 5) == "CCGGC") {
	print readName
	print readSequence
	print plusSign
	print qualScore
}
}'

currentLane="008_lane6"
COHORTID="Tx2909Hyb_008-6"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/008_11-18-14/DLVR214197Mul-6/*87*-*[0-9]*R1.fastq.gz | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ${PARENTDIR}/$currentLane/{/.};
IFS='_' read -r id1 id2 id3 id4 string <<< {/.};
fileName=${COHORTID}_\${id2}.fastq;
awk '$AWK_BODY' ${PARENTDIR}/$currentLane/{/.} > ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;
rm ${PARENTDIR}/$currentLane/{/.}"


