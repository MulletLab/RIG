NUMTHREADS=4

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

rm ./007_lane6/*.fastq*
rm ./007_lane7/*.fastq*

currentLane="007_lane6"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/007_10-02-14/DLVR214140Mul-6/*R1.fastq.gz | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ./$currentLane/{/.};
IFS='_' read -r id id2 id3 string <<< {/.};
fileName=\${id2}_\${id3}.fastq;
awk '$AWK_BODY' ./$currentLane/{/.} > ./$currentLane/\$fileName;
gzip ./$currentLane/\$fileName;
rm ./$currentLane/{/.}"

currentLane="007_lane7"
ls /data/ryanabashbash/raw_data/restriction_site_sequencing/007_10-02-14/DLVR214140Mul-7/*[7-9][0-9]_[0-9]*R1.fastq.gz | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ./$currentLane/{/.};
IFS='_' read -r id1 id2 id3 id4 id5 string <<< {/.};
fileName=\${id2}_\${id3}.fastq;
awk '$AWK_BODY' ./$currentLane/{/.} > ./$currentLane/\$fileName;
gzip ./$currentLane/\$fileName;
rm ./$currentLane/{/.}"

ls /data/ryanabashbash/raw_data/restriction_site_sequencing/007_10-02-14/DLVR214140Mul-7/92_BTx642_Parent_CCATGGACGCAT_R1.fastq.gz | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ./$currentLane/{/.};
awk '$AWK_BODY' ./$currentLane/{/.} >> ./$currentLane/BTx642.fastq;
gzip ./$currentLane/BTx642.fastq;
rm ./$currentLane/{/.};"

ls /data/ryanabashbash/raw_data/restriction_site_sequencing/007_10-02-14/DLVR214140Mul-7/93_Tx7000_Parent_TCTTGGATCGGA_R1.fastq.gz | parallel --gnu -j${NUMTHREADS} --eta \
"echo {.};
gunzip -c {} > ./$currentLane/{/.};
awk '$AWK_BODY' ./$currentLane/{/.} >> ./$currentLane/Tx7000.fastq;
gzip ./$currentLane/Tx7000.fastq;
rm ./$currentLane/{/.};"

