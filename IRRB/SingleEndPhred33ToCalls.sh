#!/bin/bash
############
#Informed Reduced Representation Pipeline
#Written by Ryan McCormick
#03/02/15
#Texas A&M University
#This is provided without warranty, and is unlikely to work right out of the box
#due to architecture differences between clusters and job submission systems.
###########

PIPELINEVERSION="IRRB2002"

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
checkDirectory ${TMPPATH} "Temporary files"
checkFile ${INTERVALFILE} "Intervals"
checkFile ${PICARDPATH} "Picard's .jar"
checkFile ${GATKPATH} "GATK's .jar"
checkFile ${REFERENCEFASTA} "Reference fasta file"
checkFile ${REFERENCEFASTA}.fai "Index for reference fasta file"
checkFile ${FAMILYREFERENCE} "Reference VCF from families"
checkFile ${POPULATIONREFERENCE} "Referene VCF from populations"
checkFile ${WGSREFERENCE} "Reference VCF from WGS"

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


echo -e "\n\tInitial checks passed. Proceeding with pipeline.\n"

DEPENDENCYSTRING=""
JOBARRAY=()
#Clean the log?
rm -f ${LOGPATH}*.*[oe]*
#Resolve individual files
for dir in ${FASTQDIRS[@]}
do
	LANEFILEARRAY=()
	FILES=$dir*.fastq*
	for file in $FILES
	do
		checkJobQueueLimit 75 300 #Arg1 = jobs allowed, Arg2 = wait period.

                dirName=$(dirname $file)
		parentDir=${dirName##*/}
		stripPath=${file##*/}
		sampleID=${stripPath%.fastq.gz}
		RG="@RG\tID:${sampleID}_single_end\tSM:${sampleID}\tPL:ILLUMINA-HiSeq-2500\tLB:${sampleID}_single_end\tPU:${sampleID}_single_end"
        	echo -e "\nStarting sample ${sampleID} with read group: $RG"
	
		qsub -N BWA_${sampleID}_single_end -l num_threads=${NUMTHREADSBWA} -o ${LOGPATH}BWA_${sampleID}_single_end.o -e ${LOGPATH}BWA_${sampleID}_single_end.e ${RIGPATH}jobScripts/BWAjobSE.sh ${BWAPATH} ${NUMTHREADSBWA} $RG ${BWAINDEX} $file ${OUTPUTPATH}${sampleID}.sam >& ${LOGPATH}qsub.tmp

		job=`extractJobId ${LOGPATH}`
		JOBARRAY+=($job)
		echo "BWA paired end job submitted as $job."
	
		qsub -N Picard_${sampleID} -hold_jid BWA_${sampleID}_single_end -l num_threads=1 -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Picard_${sampleID}.o -e ${LOGPATH}Picard_${sampleID}.e ${RIGPATH}jobScripts/PicardSortjob.sh ${PICARDPATH} ${OUTPUTPATH}${sampleID}.sam ${OUTPUTPATH}${sampleID}.sorted.bam >& ${LOGPATH}qsub.tmp

		job=`extractJobId ${LOGPATH}`
		JOBARRAY+=($job)
		echo "Picard Sort job submitted as $job."
        
		fileRemovalArray1[0]=${OUTPUTPATH}${sampleID}.sam

		qsub -N Cleanup1_${sampleID} -hold_jid Picard_${sampleID} -l num_threads=1 -l mem_free=1g -o ${LOGPATH}CleanupIntermediates1_${sampleID}.o -e ${LOGPATH}CleanupIntermediates1_${sampleID}.e ${RIGPATH}jobScripts/CleanupIntermediatesjob.sh ${fileRemovalArray1[@]} >& ${LOGPATH}qsub.tmp

		job=`extractJobId ${LOGPATH}`
		JOBARRAY+=($job)
		echo "Cleanup1 job submitted as $job."

		qsub -N Target_${sampleID} -hold_jid Picard_${sampleID} -l num_threads=${GATKNUMTHREADS} -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Target_${sampleID}.o -e ${LOGPATH}Target_${sampleID}.e ${RIGPATH}jobScripts/TargetPhred33job.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH}${sampleID}.sorted.bam ${OUTPUTPATH}${sampleID}.intervals >& ${LOGPATH}qsub.tmp
	
		job=`extractJobId ${LOGPATH}`
		JOBARRAY+=($job)
		echo "TargetIdentification job submitted as $job."
	
		qsub -N Realigner_${sampleID} -hold_jid Target_${sampleID} -l num_threads=1 -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Realigner_${sampleID}.o -e ${LOGPATH}Realigner_${sampleID}.e ${RIGPATH}jobScripts/RealignerPhred33job.sh ${JAVAMEMORY} ${GATKPATH} 1 ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH}${sampleID}.sorted.bam ${OUTPUTPATH}${sampleID}.intervals ${OUTPUTPATH}${sampleID}.realigned.bam >& ${LOGPATH}qsub.tmp
	
		job=`extractJobId ${LOGPATH}`
		JOBARRAY+=($job)
		echo "IndelRealignment job submitted as $job."
		LANEFILEARRAY+=(${OUTPUTPATH}${sampleID}.realigned.bam)

		fileRemovalArray2[0]=${OUTPUTPATH}${sampleID}.sorted.bam
        	fileRemovalArray2[1]=${OUTPUTPATH}${sampleID}.sorted.bai
        	fileRemovalArray2[2]=${OUTPUTPATH}${sampleID}.intervals

		qsub -N Cleanup2_${sampleID} -hold_jid Realigner_${sampleID} -l num_threads=1 -l mem_free=1g -o ${LOGPATH}CleanupIntermediates2_${sampleID}.o -e ${LOGPATH}CleanupIntermediates2_${sampleID}.e ${RIGPATH}jobScripts/CleanupIntermediatesjob.sh ${fileRemovalArray2[@]} >& ${LOGPATH}qsub.tmp

        	job=`extractJobId ${LOGPATH}`
        	JOBARRAY+=($job)
        	echo "Cleanup2 job submitted as $job."

		DEPENDENCYSTRING=${DEPENDENCYSTRING},Cleanup2_${sampleID}
	done

	checkJobsInArrayForCompletion ${JOBARRAY[@]}
	
	qsub -N BaseRecalibration_${parentDir} -hold_jid ${DEPENDENCYSTRING#,} -l num_threads=${GATKNUMTHREADS} -l mem_free=${JAVAMEMORY} -o ${LOGPATH}BaseRecalibration_${parentDir}.o -e ${LOGPATH}BaseRecalibration_${parentDir}.e ${RIGPATH}jobScripts/BaseRecalibrationMultiSampleLanejob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${INTERVALFILE} ${WGSREFERENCE} ${OUTPUTPATH}${parentDir}-realigned.recal.table ${LANEFILEARRAY[@]} >& ${LOGPATH}qsub.tmp
        
	job=`extractJobId ${LOGPATH}`
	JOBARRAY+=($job)
	echo "BaseRecalibration job submitted as $job."

	DEPENDENCYSTRING=""
	RECALIBRATEDARRAY=()
	REALIGNEDREMOVALARRAY=()
	for file in ${LANEFILEARRAY[@]}
	do
		checkJobQueueLimit 75 300 #Arg1 = jobs allowed, Arg2 = wait period.
		stripPath=${file##*/}
		sampleID=${stripPath%.realigned.bam}
		qsub -N ApplyRecalibration_${sampleID} -hold_jid BaseRecalibration_${parentDir} -l num_threads=1 -l mem_free=${JAVAMEMORY} -o ${LOGPATH}ApplyRecalibration_${sampleID}.o -e ${LOGPATH}ApplyRecalibration_${sampleID}.e ${RIGPATH}jobScripts/ApplyRecalibrationjob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH}${parentDir}-realigned.recal.table ${file} ${OUTPUTPATH}${sampleID}.recalibrated.bam >& ${LOGPATH}qsub.tmp

		job=`extractJobId ${LOGPATH}`
		JOBARRAY+=($job)
		echo "ApplyRecalibration job submitted as $job."
		RECALIBRATEDARRAY+=(${OUTPUTPATH}${sampleID}.recalibrated.bam)
		REMOVALARRAY+=(${OUTPUTPATH}${sampleID}.realigned.bam)
		REMOVALARRAY+=(${OUTPUTPATH}${sampleID}.realigned.bai)
		REMOVALARRAY+=(${OUTPUTPATH}${sampleID}.recalibrated.bam)
		REMOVALARRAY+=(${OUTPUTPATH}${sampleID}.recalibrated.bai)
		DEPENDENCYSTRING=${DEPENDENCYSTRING},ApplyRecalibration_${sampleID}
	done

        qsub -N BaseRecalibration2_${parentDir} -hold_jid ${DEPENDENCYSTRING#,} -l num_threads=${GATKNUMTHREADS} -l mem_free=${JAVAMEMORY} -o ${LOGPATH}BaseRecalibration2_${parentDir}.o -e ${LOGPATH}BaseRecalibration2_${parentDir}.e ${RIGPATH}jobScripts/BaseRecalibrationMultiSampleLanejob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${INTERVALFILE} ${WGSREFERENCE} ${OUTPUTPATH}${parentDir}-recalibrated.recal.table ${RECALIBRATEDARRAY[@]} >& ${LOGPATH}qsub.tmp

	job=`extractJobId ${LOGPATH}`
	JOBARRAY+=($job)
	echo "BaseRecalibration2 job submitted as $job."

	DEPENDENCYSTRING=""
        for file in ${RECALIBRATEDARRAY[@]}
	do
		checkJobQueueLimit 75 300 #Arg1 = jobs allowed, Arg2 = wait period.
		stripPath=${file##*/}
		sampleID=${stripPath%.recalibrated.bam}
		#Due to thread safety crashes, the HaplotypeCaller is set to use only 1 processor.
		qsub -N HaploCall_${sampleID} -hold_jid BaseRecalibration2_${parentDir} -l num_threads=1 -l mem_free=${JAVAMEMORY} -o ${LOGPATH}HaploCall_${sampleID}.o -e ${LOGPATH}HaploCall_${sampleID}.e ${RIGPATH}jobScripts/HaploCallerjob.sh ${JAVAMEMORY} ${GATKPATH} 1 ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH}${sampleID}.recalibrated.bam ${OUTPUTPATH}${sampleID}.GVCF.vcf >& ${LOGPATH}qsub.tmp 

		job=`extractJobId ${LOGPATH}`
		JOBARRAY+=($job)
		echo "HaplotypeCaller job submitted as $job."

		DEPENDENCYSTRING=${DEPENDENCYSTRING},HaploCall_${sampleID}
	done   
        qsub -N Cleanup_${sampleID} -hold_jid ${DEPENDENCYSTRING#,} -l num_threads=1 -l mem_free=1g -o ${LOGPATH}Cleanup_${sampleID}.o -e ${LOGPATH}Cleanup_${sampleID}.e ${RIGPATH}jobScripts/CleanupIntermediatesjob.sh ${REMOVALARRAY[@]} >& ${LOGPATH}qsub.tmp

	job=`extractJobId ${LOGPATH}`
	JOBARRAY+=($job)
	echo "Cleanup job submitted as $job."

done

checkJobsInArrayForCompletion ${JOBARRAY[@]}
ALLSUCCESSFUL=`checkJobsInArrayForFailure ${LOGPATH} ${JOBARRAY[@]}`
if [ $ALLSUCCESSFUL = "False" ]
then
	echo -e "The following jobs failed:"
	cat ${LOGPATH}failedJobs.txt
	exit 1
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
qsub -N JointGenotype -hold_jid CombineSamples_Intermediates -l mem_free=${JAVAMEMORY} -l num_threads=1 -o ${LOGPATH}JointGenotype.o -e ${LOGPATH}JointGenotype.e ${RIGPATH}jobScripts/JointGenotypejob.sh ${TMPPATH} ${JAVAMEMORY} ${GATKPATH} 1 ${REFERENCEFASTA} ${INTERVALFILE} ${lastFile} ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_unfiltered.vcf

