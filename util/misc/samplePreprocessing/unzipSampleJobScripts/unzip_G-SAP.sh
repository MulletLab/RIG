#Energy sorghum panel
NUMTHREADS=$1
PARENTDIR=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/NRRB/data
COHORTID="GSAP"
rm -f ${PARENTDIR}/002_lane1/*.fastq*
rm -f ${PARENTDIR}/002_lane2/*.fastq*
rm -f ${PARENTDIR}/002_lane3/*.fastq*
rm -f ${PARENTDIR}/002_lane4/*.fastq*
rm -f ${PARENTDIR}/002_lane5/*.fastq*
rm -f ${PARENTDIR}/002_lane6/*.fastq*

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


currentLane="002_lane1"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/SAP-Hegarix80MF2F3-StayGreen-StBCxSC710_07-18-13/DLVR2Mullet_lane1/SAP*R1.fastq.zip | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
unzip {} -d ${PARENTDIR}/$currentLane;
IFS='_-' read -r id id2 id3 id4 id5 string <<< {/.};
fileName=${COHORTID}_\$id2.fastq;
mv ${PARENTDIR}/$currentLane/{/.} ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;"

currentLane="002_lane2"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/SAP-Hegarix80MF2F3-StayGreen-StBCxSC710_07-18-13/DLVR2Mullet_lane2/SAP*R1.fastq.zip | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
unzip {} -d ${PARENTDIR}/$currentLane;
IFS='_-' read -r id id2 id3 id4 id5 string <<< {/.};
fileName=${COHORTID}_\$id2.fastq;
mv ${PARENTDIR}/$currentLane/{/.} ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;"

currentLane="002_lane3"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/SAP-Hegarix80MF2F3-StayGreen-StBCxSC710_07-18-13/DLVR2Mullet_lane3/SAP*R1.fastq.zip | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
unzip {} -d ${PARENTDIR}/$currentLane;
IFS='_-' read -r id id2 id3 id4 id5 string <<< {/.};
fileName=${COHORTID}_\$id2.fastq;
mv ${PARENTDIR}/$currentLane/{/.} ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;"

currentLane="002_lane4"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/SAP-Hegarix80MF2F3-StayGreen-StBCxSC710_07-18-13/DLVR2Mullet_lane4/SAP*R1.fastq.zip | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
unzip {} -d ${PARENTDIR}/$currentLane;
IFS='_-' read -r id id2 id3 id4 id5 string <<< {/.};
fileName=${COHORTID}_\$id2.fastq;
mv ${PARENTDIR}/$currentLane/{/.} ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;"

currentLane="002_lane5"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/SAP-Hegarix80MF2F3-StayGreen-StBCxSC710_07-18-13/DLVR2Mullet_lane5/SAP*R1.fastq.zip | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
unzip {} -d ${PARENTDIR}/$currentLane;
IFS='_-' read -r id id2 id3 id4 id5 string <<< {/.};
fileName=${COHORTID}_\$id2.fastq;
mv ${PARENTDIR}/$currentLane/{/.} ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;"

currentLane="002_lane6"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/SAP-Hegarix80MF2F3-StayGreen-StBCxSC710_07-18-13/DLVR2Mullet_lane6/SAP*R1.fastq.zip | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
unzip {} -d ${PARENTDIR}/$currentLane;
IFS='_-' read -r id id2 id3 id4 id5 string <<< {/.};
fileName=${COHORTID}_\$id2.fastq;
mv ${PARENTDIR}/$currentLane/{/.} ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;"
















