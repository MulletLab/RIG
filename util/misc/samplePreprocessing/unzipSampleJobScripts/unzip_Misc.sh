#Energy sorghum panel
NUMTHREADS=$1
PARENTDIR=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/NRRB/data
COHORTID="Misc"
rm -f ${PARENTDIR}/005_lane2/*.fastq*
rm -f ${PARENTDIR}/007_lane7/*.fastq*
rm -f ${PARENTDIR}/008_lane5/*.fastq*

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

currentLane="005_lane2"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/01-02-14_BTx623xIS3620c-R07018xR07020-etal/DLVR2130119Mul-2/21_BTx623_RIL_Parent_GGTCTATGTCAC_R1.fastq.zip | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
unzip {} -d ${PARENTDIR}/$currentLane;
fileName=${COHORTID}_BTx623.fastq;
awk '$AWK_BODY' ${PARENTDIR}/$currentLane/{/.} > ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;
rm ${PARENTDIR}/$currentLane/{/.}"

currentLane="005_lane2"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/01-02-14_BTx623xIS3620c-R07018xR07020-etal/DLVR2130119Mul-2/20_IS3620c_RIL_Parent_GTGCTTGCTATA_R1.fastq.zip | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
unzip {} -d ${PARENTDIR}/$currentLane;
fileName=${COHORTID}_IS3620C.fastq;
awk '$AWK_BODY' ${PARENTDIR}/$currentLane/{/.} > ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;
rm ${PARENTDIR}/$currentLane/{/.}"

currentLane="007_lane7"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/007_10-02-14/DLVR214140Mul-7/92_BTx642_Parent_CCATGGACGCAT_R1.fastq.gz | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ${PARENTDIR}/$currentLane/{/.};
fileName=${COHORTID}_BTx642.fastq;
awk '$AWK_BODY' ${PARENTDIR}/$currentLane/{/.} > ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;
rm ${PARENTDIR}/$currentLane/{/.};"

currentLane="007_lane7"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/007_10-02-14/DLVR214140Mul-7/93_Tx7000_Parent_TCTTGGATCGGA_R1.fastq.gz | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ${PARENTDIR}/$currentLane/{/.};
fileName=${COHORTID}_Tx7000.fastq;
awk '$AWK_BODY' ${PARENTDIR}/$currentLane/{/.} > ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;
rm ${PARENTDIR}/$currentLane/{/.};"

currentLane="008_lane5"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/008_11-18-14/DLVR214197Mul-5/202_B3_JB_ATGCCAAGCGCT_R1.fastq.gz | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ${PARENTDIR}/$currentLane/{/.};
IFS='_' read -r id1 id2 id3 id4 string <<< {/.};
fileName=${COHORTID}_B3-JB.fastq;
awk '$AWK_BODY' ${PARENTDIR}/$currentLane/{/.} > ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;
rm ${PARENTDIR}/$currentLane/{/.}"

ls /data/ryanabashbash/raw_data/restriction_site_sequencing/008_11-18-14/DLVR214197Mul-5/203_Evergreen_GCTGGCAACAGA_R1.fastq.gz | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ${PARENTDIR}/$currentLane/{/.};
IFS='_' read -r id1 id2 id3 id4 string <<< {/.};
fileName=${COHORTID}_Evergreen.fastq;
awk '$AWK_BODY' ${PARENTDIR}/$currentLane/{/.} > ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;
rm ${PARENTDIR}/$currentLane/{/.}"

ls /data/ryanabashbash/raw_data/restriction_site_sequencing/008_11-18-14/DLVR214197Mul-5/204_SB_TTGTAGAACGTC_R1.fastq.gz | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ${PARENTDIR}/$currentLane/{/.};
IFS='_' read -r id1 id2 id3 id4 string <<< {/.};
fileName=${COHORTID}_SB.fastq;
awk '$AWK_BODY' ${PARENTDIR}/$currentLane/{/.} > ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;
rm ${PARENTDIR}/$currentLane/{/.}"

ls /data/ryanabashbash/raw_data/restriction_site_sequencing/008_11-18-14/DLVR214197Mul-5/206_JapBr_GGCACTTCTAGT_R1.fastq.gz | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ${PARENTDIR}/$currentLane/{/.};
IFS='_' read -r id1 id2 id3 id4 string <<< {/.};
fileName=${COHORTID}_JpnBroomcorn.fastq;
awk '$AWK_BODY' ${PARENTDIR}/$currentLane/{/.} > ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;
rm ${PARENTDIR}/$currentLane/{/.}"

ls /data/ryanabashbash/raw_data/restriction_site_sequencing/008_11-18-14/DLVR214197Mul-5/99_Acme_Br_Parent_ATTAGCGCGAGA_R1.fastq.gz | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ${PARENTDIR}/$currentLane/{/.};
IFS='_' read -r id1 id2 id3 id4 string <<< {/.};
fileName=${COHORTID}_AcmeBroomcorn.fastq;
awk '$AWK_BODY' ${PARENTDIR}/$currentLane/{/.} > ${PARENTDIR}/$currentLane/\$fileName;
gzip ${PARENTDIR}/$currentLane/\$fileName;
rm ${PARENTDIR}/$currentLane/{/.}"

