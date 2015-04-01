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
	checkJobQueueLimit 75 600 #Arg1 = jobs allowed, Arg2 = wait period.

	parentDir=$(basename ${dir})
	sampleID=${parentDir}
	SAMName=${sampleID}.sam
 
	RG="@RG\tID:${sampleID}_paired_end\tSM:${sampleID}\tPL:ILLUMINA-HiSeq-2000\tLB:${sampleID}_paired_end\tPU:${sampleID}_paired_end"
        echo -e "\nStarting sample ${sampleID} with read group: $RG"
	
	qsub -N BWA_${sampleID}_paired_end ${GLOBALQSUBOPTIONS} -l num_threads=${NUMTHREADSBWA} -o ${LOGPATH}BWA_${sampleID}_paired_end.o -e ${LOGPATH}BWA_${sampleID}_paired_end.e ${RIGPATH}jobScripts/BWAjobPEmateFile.sh ${BWAPATH} ${NUMTHREADSBWA} $RG ${BWAINDEX} ${dir}${sampleID}_R1.fastq.gz ${dir}${sampleID}_R2.fastq.gz ${OUTPUTPATH}${sampleID}_paired_end.sam >& ${LOGPATH}qsub.tmp

	job=`extractJobId ${LOGPATH}`
	JOBARRAY+=($job)
	echo "BWA paired end job submitted as $job."
	
	qsub -N Picard_${sampleID} -hold_jid BWA_${sampleID}_paired_end ${GLOBALQSUBOPTIONS} -l num_threads=1 -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Picard_${sampleID}.o -e ${LOGPATH}Picard_${sampleID}.e ${RIGPATH}jobScripts/PicardSortjob.sh ${PICARDPATH} ${OUTPUTPATH}${sampleID}_paired_end.sam ${OUTPUTPATH}${sampleID}.sorted.bam >& ${LOGPATH}qsub.tmp

	job=`extractJobId ${LOGPATH}`
	JOBARRAY+=($job)
	echo "Picard Sort job submitted as $job."
        
	qsub -N PicardMarkDup_${sampleID} -hold_jid Picard_${sampleID} ${GLOBALQSUBOPTIONS} -l num_threads=1 -l mem_free=${JAVAMEMORY} -o ${LOGPATH}PicardMarkDup_${sampleID}.o -e ${LOGPATH}PicardMarkDup_${sampleID}.e ${RIGPATH}jobScripts/PicardMarkDupjob.sh ${PICARDPATH} ${OUTPUTPATH}${sampleID}.sorted.bam ${OUTPUTPATH}${sampleID}.dedupped.sorted.bam >& ${LOGPATH}qsub.tmp

        job=`extractJobId ${LOGPATH}`
        JOBARRAY+=($job)
        echo "Picard Mark Duplicates job submitted as $job."

	fileRemovalArray1[0]=${OUTPUTPATH}${sampleID}_paired_end.sam

	qsub -N Cleanup1_${sampleID} -hold_jid PicardMarkDup_${sampleID} ${GLOBALQSUBOPTIONS} -l num_threads=1 -l mem_free=1g -o ${LOGPATH}CleanupIntermediates1_${sampleID}.o -e ${LOGPATH}CleanupIntermediates1_${sampleID}.e ${RIGPATH}jobScripts/CleanupIntermediatesjob.sh ${fileRemovalArray1[@]} >& ${LOGPATH}qsub.tmp

	job=`extractJobId ${LOGPATH}`
	JOBARRAY+=($job)
	echo "Cleanup1 job submitted as $job."

	qsub -N Target_${sampleID} -hold_jid PicardMarkDup_${sampleID} ${GLOBALQSUBOPTIONS} -l num_threads=${GATKNUMTHREADS} -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Target_${sampleID}.o -e ${LOGPATH}Target_${sampleID}.e ${RIGPATH}jobScripts/TargetPhred33job.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH}${sampleID}.dedupped.sorted.bam ${OUTPUTPATH}${sampleID}.intervals >& ${LOGPATH}qsub.tmp
	
	job=`extractJobId ${LOGPATH}`
	JOBARRAY+=($job)
	echo "TargetIdentification job submitted as $job."
	
	qsub -N Realigner_${sampleID} -hold_jid Target_${sampleID} ${GLOBALQSUBOPTIONS} -l num_threads=1 -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Realigner_${sampleID}.o -e ${LOGPATH}Realigner_${sampleID}.e ${RIGPATH}jobScripts/RealignerPhred33job.sh ${JAVAMEMORY} ${GATKPATH} 1 ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH}${sampleID}.dedupped.sorted.bam ${OUTPUTPATH}${sampleID}.intervals ${OUTPUTPATH}${sampleID}.realigned.bam >& ${LOGPATH}qsub.tmp
	
	job=`extractJobId ${LOGPATH}`
	JOBARRAY+=($job)
	echo "IndelRealignment job submitted as $job."

        fileRemovalArray2[0]=${OUTPUTPATH}${sampleID}.sorted.bam
        fileRemovalArray2[1]=${OUTPUTPATH}${sampleID}.sorted.bai
        fileRemovalArray2[2]=${OUTPUTPATH}${sampleID}.dedupped.sorted.bam
        fileRemovalArray2[3]=${OUTPUTPATH}${sampleID}.dedupped.sorted.bai
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
