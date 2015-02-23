#Diversity panel from 008_11-18-14
NUMTHREADS=$1
PARENTDIR=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/NRRB/data
COHORTID="Div-008"
rm -f ${PARENTDIR}/008_lane8/*.fastq*

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

currentLane="008_lane8"

mv /data/ryanabashbash/raw_data/restriction_site_sequencing/008_11-18-14/DLVR214197Mul-8/141_308439_CTGAGCTTCTCA_R1.fastq.gz /data/ryanabashbash/raw_data/restriction_site_sequencing/008_11-18-14/DLVR214197Mul-8/141_308439-1_CTGAGCTTCTCA_R1.fastq.gz

mv /data/ryanabashbash/raw_data/restriction_site_sequencing/008_11-18-14/DLVR214197Mul-8/149_308439_ATGATCCACGGC_R1.fastq.gz /data/ryanabashbash/raw_data/restriction_site_sequencing/008_11-18-14/DLVR214197Mul-8/149_308439-2_ATGATCCACGGC_R1.fastq.gz

ls /data/ryanabashbash/raw_data/restriction_site_sequencing/008_11-18-14/DLVR214197Mul-8/*_[0-9,G]*R1.fastq.gz | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ${PARENTDIR}/$currentLane/{/.};
IFS='_' read -r id1 id2 id3 id4 string <<< {/.};
fileName=${COHORTID}_\${id2}.fastq;
awk '$AWK_BODY' ${PARENTDIR}/$currentLane/{/.} > ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;
rm ${PARENTDIR}/$currentLane/{/.}"

ls /data/ryanabashbash/raw_data/restriction_site_sequencing/008_11-18-14/DLVR214197Mul-8/Unknown*R1.fastq.gz | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ${PARENTDIR}/$currentLane/{/.};
IFS='_' read -r id1 id2 id3 id4 string <<< {/.};
fileName=${COHORTID}_\${id1}.fastq;
awk '$AWK_BODY' ${PARENTDIR}/$currentLane/{/.} > ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;
rm ${PARENTDIR}/$currentLane/{/.}"


