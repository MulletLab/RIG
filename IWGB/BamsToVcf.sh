#!/bin/bash
############
#Informed Whole Genome Pipeline
#Written by Ryan McCormick
#03/08/15
#Texas A&M University
#This is provided without warranty, and is unlikely to work right out of the box
#due to architecture differences between clusters and job submission systems.
###########

PIPELINEVERSION="IWGB1001"

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
echo -e "GATK reference FASTA:\t\t${REFERENCEFASTA}"
echo -e "Interval List Directory:\t\t\t${INTERVALLISTDIR}"
echo -e "Interval file with all intervals:\t\t\t${INTERVALFILE}"
echo -e "Pipeline version:\t\t${PIPELINEVERSION}"
echo -e "RIG path:\t\t${RIGPATH}"
echo -e "Input directories:"
for dir in ${BAMDIRS[@]}
do
	echo -e "\t\t$dir"
done


echo -e "\n"
checkExecutable ${BWAPATH} "BWA executable"
checkBWAindex ${BWAINDEX} "BWA index"
checkDirectory ${OUTPUTPATH} "Output"
checkDirectory ${LOGPATH} "Logging"
checkDirectory ${INTERVALLISTDIR} "Directory with *.intervals files"
checkFile ${INTERVALFILE} "Single interval file with all intervals"
checkFile ${PICARDPATH} "Picard's .jar"
checkFile ${GATKPATH} "GATK's .jar"
checkFile ${REFERENCEFASTA} "Reference fasta file"
checkFile ${REFERENCEFASTA}.fai "Index for reference fasta file"

#Check for the input BAM files
let TOTALBAM=0
for dir in ${BAMDIRS[@]}
do
	if [ -d $dir ]
	then
		NUMBAM=$(ls ${dir}*.bam | wc -l)
		echo -e "Found $NUMBAM .bam files in $dir"
		let TOTALBAM=TOTALBAM+NUMBAM
	else
		echo -e "\n\tCannot find BAM directory $dir. Please verify its location.\n"
		exit 1
	fi
done
echo -e "Found $TOTALBAM BAM files across all directories"								
if [ "$TOTALBAM" -le "0" ]
then
	echo -e "Unable to find any .bam files. Verify file location and that files have .bam extension."
	exit 1
fi


echo -e "\n\tInitial checks passed. Proceeding with pipeline.\n"
DEPENDENCYSTRING=""
JOBARRAY=()
#Clean the log?
rm -f ${LOGPATH}*.*[oe]*
#Resolve individual files

for dir in ${BAMDIRS[@]}
do
	FILES=$dir*.bam
	for file in $FILES
	do
		stripPath=${file##*/}
		sampleID=${stripPath%%.*}
		echo -e "\n\tOn sample ${sampleID}\n"
		
		#Note that jobs are being submitted here a little differently than usual. 
		#The HaplotypeCaller suffers from frequent crashes when parallelized using -nct, so we check for interval files and scatter jobs based on those files to be later gathered.
		#The job string is stored so that we could later resubmit the job if we wanted, but we're excluding that functionality for now (the code is commented out at the bottom of this file).
		intervalFiles=${INTERVALLISTDIR}*.intervals
		for intervalList in ${intervalFiles}
		do
			interval=${intervalList##*/}
			interval=${interval%%.*}
			checkJobQueueLimit 75 600 #Arg1 = jobs allowed, Arg2 = wait period.

			haplocallJobString="qsub -N HaploCall_${sampleID}_${interval} -l num_threads=1 -l mem_free=${JAVAMEMORY} -o ${LOGPATH}HaplotypeCaller_${sampleID}_${interval}.o -e ${LOGPATH}HaplotypeCaller_${sampleID}_${interval}.e ${RIGPATH}/jobScripts/HaploCallerjob.sh ${JAVAMEMORY} ${GATKPATH} 1 ${REFERENCEFASTA} ${intervalList} ${file} ${OUTPUTPATH}${sampleID}_${interval}.GVCF.vcf >& ${LOGPATH}qsub.tmp"

			eval ${haplocallJobString}

			job=`extractJobId ${LOGPATH}`
			HAPLOCALLERJOBARRAY+=($job)
			HAPLOCALLERJOBSTRINGARRAY+=("$haplocallJobString")
			echo "HaplotypeCaller job on interval $interval submitted as $job."
			DEPENDENCYSTRING=${DEPENDENCYSTRING},HaploCall_${sampleID}_${interval}
		done
	done
done

checkJobsInArrayForCompletion ${HAPLOCALLERJOBARRAY[@]}
ALLSUCCESSFUL=`checkJobsInArrayForFailure ${LOGPATH} ${JOBARRAY[@]}`
if [ $ALLSUCCESSFUL = "False" ]
then
	echo -e "The following jobs failed:"
	cat ${LOGPATH}failedJobs.txt
fi

GVCFFILES=${OUTPUTPATH}*.GVCF.vcf
GVCFARRAY=()
for file in $GVCFFILES
do
	GVCFARRAY+=($file)
done

rangeLength=50
rangeBegin=0
rangeEnd=0
let "rangeEnd=${rangeLength}-1"
fileArrayLength=${#GVCFARRAY[@]}
bool_EndOfArrayProcessed="False"
COMBINEJOBARRAY=()
INTERMEDIATESTOMERGE=()

while [ ${bool_EndOfArrayProcessed} = "False" ]
do
	checkJobQueueLimit 75 300 #Arg1 = jobs allowed, Arg2 = wait period.

	qsub -N CombineSamples_${rangeBegin}-${rangeEnd} -hold_jid ${DEPENDENCYSTRING#,} -l mem_free=${JAVAMEMORY} -l num_threads=${GATKNUMTHREADS} -o ${LOGPATH}CombineSamples_${rangeBegin}-${rangeEnd}.o -e ${LOGPATH}CombineSamples_${rangeBegin}-${rangeEnd}.e ${RIGPATH}jobScripts/CombineGVCFjob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH} ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${rangeBegin}-${rangeEnd}.popGVCF.vcf ${GVCFARRAY[@]:${rangeBegin}:${rangeLength}} >& ${LOGPATH}qsub.tmp

        job=`extractJobId ${LOGPATH}`
        COMBINEJOBARRAY+=($job)
        INTERMEDIATESTOMERGE+=(${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${rangeBegin}-${rangeEnd}.popGVCF.vcf)
        echo "CombineSamples on indices ${rangeBegin}-${rangeEnd} submitted as $job"	
	
        qsub -N CleanupGVCFs_${rangeBegin}-${rangeEnd} -hold_jid CombineSamples_${rangeBegin}-${rangeEnd} -l mem_free=1g -l num_threads=1 -o ${LOGPATH}CleanupGVCFs_${rangeBegin}-${rangeEnd}.o -e ${LOGPATH}CleanupGVCFs_${rangeBegin}-${rangeEnd}.e ${RIGPATH}jobScripts/CleanupGVCFsjob.sh ${GVCFARRAY[@]:${rangeBegin}:${rangeLength}} >& ${LOGPATH}qsub.tmp

	job=`extractJobId ${LOGPATH}`
	COMBINEJOBARRAY+=($job)
	echo "Cleanup on indices ${rangeBegin}-${rangeEnd} submitted as $job"


	if [ ${rangeEnd} -gt ${fileArrayLength} ]
	then
		bool_EndOfArrayProcessed="True"
	fi
	let "rangeBegin=${rangeBegin}+${rangeLength}"
	let "rangeEnd=${rangeEnd}+${rangeLength}"

done

checkJobsInArrayForCompletion ${COMBINEJOBARRAY[@]}

qsub -N CombineSamples_Intermediates -l mem_free=${JAVAMEMORY} -l num_threads=${GATKNUMTHREADS} -o ${LOGPATH}CombineSamples_Intermediates.o -e ${LOGPATH}CombineSamples_Intermediates.e ${RIGPATH}jobScripts/CombineGVCFjob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH} ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_merged.popGVCF.vcf ${INTERMEDIATESTOMERGE[@]} >& ${LOGPATH}qsub.tmp

job=`extractJobId ${LOGPATH}`
echo "CombineSamples on ${#INTERMEDIATESTOMERGE[@]} intermediates submitted as $job"

qsub -N CleanupGVCFs_Intermediates -hold_jid CombineSamples_Intermediates -l mem_free=1g -l num_threads=1 -o ${LOGPATH}CleanupGVCFs_Intermediates.o -e ${LOGPATH}CleanupGVCFs_Intermediates.e ${RIGPATH}jobScripts/CleanupGVCFsjob.sh ${INTERMEDIATESTOMERGE[@]} >& ${LOGPATH}qsub.tmp

job=`extractJobId ${LOGPATH}`
echo "Cleanup on intermediate files submitted as $job"


#This isn't parallelized due to low file handle limits on system
qsub -N JointGenotype -hold_jid CombineSamples_Intermediates -l mem_free=${JAVAMEMORY} -l num_threads=1 -o ${LOGPATH}JointGenotype.o -e ${LOGPATH}JointGenotype.e ${RIGPATH}jobScripts/JointGenotypejob.sh ${TMPPATH} ${JAVAMEMORY} ${GATKPATH} 1 ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_merged.popGVCF.vcf ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_unfiltered.vcf



#Code that we may reconsider if non parallelized HC doesn't work out.
:<<"BlockToResubmitFailedHaploCallerJobs"
#This is a deprecated section to resubmit HaplotypeCaller jobs that failed due to the crashes from multithreading.
rm ${LOGPATH}failedHaploJobs.txt
ALLHAPLOSSUCCESSFUL=`checkJobsInArrayForFailure ${LOGPATH} ${HAPLOCALLERJOBARRAY[@]}`
while [ $ALLHAPLOSUCCESSFUL = "False" ]
do
	nextIterHCJobArray=()
	nextIterHCJobStringArray=()
	for jobIndex in ${!HAPLOCALLERJOBARRAY[@]}
	do
		indJob=${HAPLOCALLERJOBARRAY[${jobIndex}]}
		exitStatus=`qacct -o ryanabashbash -j ${indJob} | grep exit_status | awk '{print $2}'`
		if [ $exitStatus = "1" ]
		then
			checkJobQueueLimit 75 600 #Arg1 = jobs allowed, Arg2 = wait period.
			jobName=`qacct -o ryanabashbash -j $indJob | grep jobname | awk '{print $2}'`
			echo Job $indJob named $jobName failed.
			echo Job $indJob named $jobName failed. >> ${LOGPATH}failedHaploJobs.txt
			eval "${HAPLOCALLERJOBSTRINGARRAY[${jobIndex}]}"
			job=`extractJobId ${LOGPATH}`
			nextIterHCJobArray+=($job)
			nextIterHCJobStringArray+=("${HAPLOCALLERJOBSTRINGARRAY[${jobIndex}]}")
			echo "Haplotype job re-submitted as $job."
			IFS=' ' read -a array <<< "${HAPLOTYPECALLERSTRINGARRAY[${jobIndex}]}"
			echo "${array[2]}"
			DEPENDENCYSTRING=${DEPENDENCYSTRING},"${array[2]}"
		fi
	done
	if [ ${#nextIterHCJobArray[@]} -eq 0 ]
	then
		ALLHAPLOSUCCESSFUL="True"
		echo "All HaplotypeCaller jobs were successful."
	else
		echo "Not all HaplotypeCaller jobs were successful. Beginning the next iteration."
		checkJobsInArrayForCompletion ${nextIterHCJobArray[@]}
		HAPLOCALLERJOBARRAY=(${nextIterHCJobArray[@]})
		HAPLOCALLERJOBSTRINGARRAY=("${nextIterHCJobStringArray[@]}")
	fi
done
BlockToResubmitFailedHaploCallerJobs
