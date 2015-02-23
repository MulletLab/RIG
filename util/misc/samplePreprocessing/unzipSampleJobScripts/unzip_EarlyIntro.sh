#Energy sorghum panel
NUMTHREADS=$1
PARENTDIR=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/NRRB/data
COHORTID="EarlyIntro"
rm -f ${PARENTDIR}/005_lane8/*.fastq*

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


currentLane="005_lane8"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/01-02-14_BTx623xIS3620c-R07018xR07020-etal/DLVR2130119Mul-8/*R1.fastq.zip | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ${PARENTDIR}/$currentLane/{/.};
IFS='_' read -r id1 id2 id3 id4 id5 string <<< {/.};
fileName=${COHORTID}_\${id1}_\${id2}.fastq;
awk '$AWK_BODY' ${PARENTDIR}/$currentLane/{/.} > ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;
rm ${PARENTDIR}/$currentLane/{/.}"







