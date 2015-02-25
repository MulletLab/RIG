#Energy sorghum panel
NUMTHREADS=$1
PARENTDIR=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/NRRB/data
COHORTID="ESAP"
rm -f ${PARENTDIR}/001_lane1/*.fastq*
rm -f ${PARENTDIR}/001_lane2/*.fastq*
rm -f ${PARENTDIR}/001_lane3/*.fastq*

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

currentLane="001_lane1"
COHORTID="ESAP_001-1"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/ESP-HegX80MF2-StdBCXSC170F2_05-13-13/DLVR2Mullet_Lane1/*R1.fastq.zip | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
unzip {} -d ${PARENTDIR}/$currentLane;
IFS='_' read -r id id2 id3 id4 id5 string <<< {/.};
fileName=${COHORTID}_\$id3.fastq;
mv ${PARENTDIR}/$currentLane/{/.} ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;"

currentLane="001_lane2"
COHORTID="ESAP_001-2"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/ESP-HegX80MF2-StdBCXSC170F2_05-13-13/DLVR2Mullet_Lane2/*R1.fastq.zip | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
unzip {} -d ${PARENTDIR}/$currentLane;
IFS='_' read -r id id2 id3 id4 id5 string <<< {/.};
fileName=${COHORTID}_\$id3.fastq;
mv ${PARENTDIR}/$currentLane/{/.} ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;"

currentLane="001_lane3"
COHORTID="ESAP_001-3"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/ESP-HegX80MF2-StdBCXSC170F2_05-13-13/DLVR2Mullet_Lane3/*R1.fastq.zip | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
unzip {} -d ${PARENTDIR}/$currentLane;
IFS='_' read -r id id2 id3 id4 id5 string <<< {/.};
fileName=${COHORTID}_\$id3.fastq;
mv ${PARENTDIR}/$currentLane/{/.} ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;"
