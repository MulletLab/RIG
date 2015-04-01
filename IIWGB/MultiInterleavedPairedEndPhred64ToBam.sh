#!/bin/bash
############
#Informed Whole Genome Pipeline
#Written by Ryan McCormick
#04/01/15
#Texas A&M University
#This is provided without warranty, and is unlikely to work right out of the box
#due to architecture differences between clusters and job submission systems.
###########

PIPELINEVERSION="IIWGB1003"

echo -e "\n\tEntering the pipeline with the following inputs:\n"
echo -e "Number threads for BWA:\t\t${NUMTHREADSBWA}"
echo -e "Group ID:\t\t\t${GROUPID}"
echo -e "BWA binary path:\t\t${BWAPATH}"
echo -e "BWA index path:\t\t\t${BWAINDEX}"
echo -e "Picard path:\t\t\t${PICARDPATH}"
echo -e "Output path:\t\t\t${OUTPUTPATH}"
echo -e "Log path:\t\t\t${LOGPATH}"
echo -e "Memory allocated to the JVM:\t${JAVAMEMORY}"
echo -e "GATK path:\t\t\t${GATKPATH}"
echo -e "Number of threads for GATK:\t${GATKNUMTHREADS}"
echo -e "Additional options passed to each qsub call:\t${GLOBALQSUBOPTIONS}"
echo -e "GATK reference FASTA:\t\t${REFERENCEFASTA}"
echo -e "Interval file:\t\t\t${INTERVALFILE}"
echo -e "Pipeline version:\t\t${PIPELINEVERSION}"
echo -e "RIG path:\t\t${RIGPATH}"
echo -e "Input directories:"
for dir in ${FASTQDIRS[@]}
do
	        echo -e "\t\t$dir"
done

#Perform some checks on inputs:

echo -e "\n"
checkExecutable ${BWAPATH} "BWA executable"
checkBWAindex ${BWAINDEX} "BWA index"
checkDirectory ${OUTPUTPATH} "Output"
checkDirectory ${LOGPATH} "Logging"
checkFile ${INTERVALFILE} "Intervals"
checkFile ${PICARDPATH} "Picard's .jar"
checkFile ${GATKPATH} "GATK's .jar"
checkFile ${REFERENCEFASTA} "Reference fasta file"
checkFile ${REFERENCEFASTA}.fai "Index for reference fasta file"

#Check for the input FASTQ files
let TOTALFASTQ=0
for dir in ${FASTQDIRS[@]}
do
	if [ -d $dir ]
	then
		NUMFASTQ=$(ls ${dir}*.fastq* | wc -l)
		echo -e "Found $NUMFASTQ .fastq files in $dir"
		let TOTALFASTQ=TOTALFASTQ+NUMFASTQ
	else
		echo -e "\n\tCannot find FASTQ directory $dir. Please verify its location.\n"
		exit 1
	fi
done
echo -e "Found $TOTALFASTQ .fastq files across all directories"
if [ "$TOTALFASTQ" -le "0" ]
then
	echo -e "Unable to find any .fastq files. Verify file location and that files have .fastq or .fastq.gz extension."
	exit 1
fi


#Finished checking pipeline inputs. Proceed with pipeline
echo -e "\n\tInitial checks passed. Proceeding with pipeline.\n"

DEPENDENCYSTRING=""
JOBARRAY=()
#Clean the log?
rm -f ${LOGPATH}*.*[oe]*
#Resolve individual files
for dir in ${FASTQDIRS[@]}
do
	
        SAMPLEFILEARRAY=()
	REMOVALARRAY=()
	DEPENDENCYSTRING=""
	FILES=$dir*.fastq.gz

	parentDir=$(basename ${dir})
	sampleID=${parentDir}
	SAMName=${sampleID}.sam

	for file in $FILES
	do
		checkJobQueueLimit 75 600 #Arg1 = jobs allowed, Arg2 = wait period.

		fileID=$(basename ${file})
		fileID=${fileID%.fastq.gz}

		RG="@RG\tID:${fileID}_phred64\tSM:${sampleID}\tPL:ILLUMINA-HiSeq-2000\tLB:${fileID}_phred64\tPU:${fileID}_phred64"
        	echo -e "\nStarting sample $SAMName with read group: $RG"

		qsub -N BWA_${fileID}_phred64 ${GLOBALQSUBOPTIONS} -l num_threads=${NUMTHREADSBWA} -o ${LOGPATH}BWA_${fileID}_phred64.o -e ${LOGPATH}BWA_${fileID}_phred64.e ${RIGPATH}/jobScripts/BWAjobPEinterleaved.sh ${BWAPATH} ${NUMTHREADSBWA} $RG ${BWAINDEX} ${file} ${OUTPUTPATH}${fileID}_phred64.sam >& ${LOGPATH}qsub.tmp

		job=`extractJobId ${LOGPATH}`
		JOBARRAY+=($job)
		echo "BWA phred64 job submitted as $job."
	
                SAMPLEFILEARRAY+=(${OUTPUTPATH}${fileID}_phred64.sam)
		REMOVALARRAY+=(${OUTPUTPATH}${fileID}_phred64.sam)
		DEPENDENCYSTRING=${DEPENDENCYSTRING},BWA_${fileID}_phred64

	done

	checkJobQueueLimit 75 600 #Arg1 = jobs allowed, Arg2 = wait period.

        qsub -N Picard_${sampleID} -hold_jid ${DEPENDENCYSTRING#,} ${GLOBALQSUBOPTIONS} -l num_threads=1 -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Picard_${sampleID}.o -e ${LOGPATH}Picard_${sampleID}.e ${RIGPATH}jobScripts/PicardMultiMergejob.sh ${PICARDPATH} ${OUTPUTPATH}${sampleID}.merged.sorted.bam ${SAMPLEFILEARRAY[@]} >& ${LOGPATH}qsub.tmp

        job=`extractJobId ${LOGPATH}`
	JOBARRAY+=($job)
	echo "Picard Merge job submitted as $job."

	qsub -N PicardMarkDup_${sampleID} -hold_jid Picard_${sampleID} ${GLOBALQSUBOPTIONS} -l num_threads=1 -l mem_free=${JAVAMEMORY} -o ${LOGPATH}PicardMarkDup_${sampleID}.o -e ${LOGPATH}PicardMarkDup_${sampleID}.e ${RIGPATH}jobScripts/PicardMarkDupjob.sh ${PICARDPATH} ${OUTPUTPATH}${sampleID}.merged.sorted.bam ${OUTPUTPATH}${sampleID}.dedupped.sorted.bam >& ${LOGPATH}qsub.tmp

        job=`extractJobId ${LOGPATH}`
        JOBARRAY+=($job)
        echo "Picard Mark Duplicates job submitted as $job."

	qsub -N Cleanup1_${sampleID} -hold_jid PicardMarkDup_${sampleID} ${GLOBALQSUBOPTIONS} -l num_threads=1 -l mem_free=1g -o ${LOGPATH}CleanupIntermediates1_${sampleID}.o -e ${LOGPATH}CleanupIntermediates1_${sampleID}.e ${RIGPATH}jobScripts/CleanupIntermediatesjob.sh ${REMOVALARRAY[@]} >& ${LOGPATH}qsub.tmp

	job=`extractJobId ${LOGPATH}`
	JOBARRAY+=($job)
	echo "Cleanup1 job submitted as $job."

	qsub -N Target_${sampleID} -hold_jid PicardMarkDup_${sampleID} ${GLOBALQSUBOPTIONS} -l num_threads=${GATKNUMTHREADS} -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Target_${sampleID}.o -e ${LOGPATH}Target_${sampleID}.e ${RIGPATH}jobScripts/TargetPhred64job.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH}${sampleID}.dedupped.sorted.bam ${OUTPUTPATH}${sampleID}.intervals >& ${LOGPATH}qsub.tmp
	
	job=`extractJobId ${LOGPATH}`
	JOBARRAY+=($job)
	echo "TargetIdentification job submitted as $job."
	
	qsub -N Realigner_${sampleID} -hold_jid Target_${sampleID} ${GLOBALQSUBOPTIONS} -l num_threads=1 -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Realigner_${sampleID}.o -e ${LOGPATH}Realigner_${sampleID}.e ${RIGPATH}jobScripts/RealignerPhred64job.sh ${JAVAMEMORY} ${GATKPATH} 1 ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH}${sampleID}.dedupped.sorted.bam ${OUTPUTPATH}${sampleID}.intervals ${OUTPUTPATH}${sampleID}.realigned.bam >& ${LOGPATH}qsub.tmp
	
	job=`extractJobId ${LOGPATH}`
	JOBARRAY+=($job)
	echo "IndelRealignment job submitted as $job."

        fileRemovalArray2[1]=${OUTPUTPATH}${sampleID}.merged.sorted.bam
        fileRemovalArray2[2]=${OUTPUTPATH}${sampleID}.merged.sorted.bai
        fileRemovalArray2[3]=${OUTPUTPATH}${sampleID}.dedupped.sorted.bam
        fileRemovalArray2[4]=${OUTPUTPATH}${sampleID}.dedupped.sorted.bai
        fileRemovalArray2[5]=${OUTPUTPATH}${sampleID}.intervals

	qsub -N Cleanup2_${sampleID} -hold_jid Realigner_${sampleID} ${GLOBALQSUBOPTIONS} -l num_threads=1 -l mem_free=1g -o ${LOGPATH}CleanupIntermediates2_${sampleID}.o -e ${LOGPATH}CleanupIntermediates2_${sampleID}.e ${RIGPATH}jobScripts/CleanupIntermediatesjob.sh ${fileRemovalArray2[@]} >& ${LOGPATH}qsub.tmp

        job=`extractJobId ${LOGPATH}`
        JOBARRAY+=($job)
        echo "Cleanup2 job submitted as $job."

done

checkJobsInArrayForCompletion ${JOBARRAY[@]}
ALLSUCCESSFUL=`checkJobsInArrayForFailure ${LOGPATH} ${JOBARRAY[@]}`
if [ $ALLSUCCESSFUL = "False" ]
then
	echo -e "The following jobs failed:"
	cat ${LOGPATH}failedJobs.txt
fi
