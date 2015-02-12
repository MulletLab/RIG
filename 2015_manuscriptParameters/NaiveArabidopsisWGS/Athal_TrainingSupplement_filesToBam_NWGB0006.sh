#!/bin/bash
############
#Naive Whole Genome Pipeline - Modified for specific BTx642 and Tx7000 use case
#Written by Ryan McCormick
#08/29/14
#Texas A&M University
#This is provided without warranty, and is unlikely to work right out of the box
#due to architecture differences between clusters and job submission systems.
###########

PIPELINEVERSION="NWGB0006"

#Hardware values
NUMTHREADSBWA=7
GATKNUMTHREADS=7
GATKNUMCPUTHREADS=7 
JAVAMEMORY="32g"

#Group ID used to name output files
GROUPID="NULL"

#File paths
#The parent directory of samples will be used as the read group, so place samples from the same read group in the same directory.
FASTQDIRS[0]=/data/ryanabashbash/raw_data/RIG_ArabidopsisValidation/WGS/TrainingSet/ICE150/
FASTQDIRS[1]=/data/ryanabashbash/raw_data/RIG_ArabidopsisValidation/WGS/TrainingSet/ICE213/
FASTQDIRS[2]=/data/ryanabashbash/raw_data/RIG_ArabidopsisValidation/WGS/TrainingSet/ICE50/
FASTQDIRS[3]=/data/ryanabashbash/raw_data/RIG_ArabidopsisValidation/WGS/TrainingSet/Leo-1/
FASTQDIRS[4]=/data/ryanabashbash/raw_data/RIG_ArabidopsisValidation/WGS/TrainingSet/Yeg-1/
FASTQDIRS[5]=/data/ryanabashbash/raw_data/RIG_ArabidopsisValidation/WGS/TrainingSet/ICE134/

OUTPUTPATH=/data/ryanabashbash/GATK_pipeline/WGS/RIG_ArabidopsisValidation/WGS-collection/TrainingSupplement/data/results_trainingSupplement/
LOGPATH=/data/ryanabashbash/GATK_pipeline/WGS/RIG_ArabidopsisValidation/WGS-collection/TrainingSupplement/data/log_trainingSupplement/
REFERENCEFASTA=/data/ryanabashbash/Ath10_reference/TAIR10/ATgenomeTAIR10.fasta #There also needs to be a fasta index file (.fai) in the same directory as this reference.
PICARDPATH=/data/ryanabashbash/Downloads/picard-tools-1.108/  #This is the path of the directory containing the Picard tools
BWAPATH=/data/ryanabashbash/Downloads/bwa-0.7.7/bwa  #This is the path of the BWA executable
BWAINDEX=/data/ryanabashbash/Ath10_reference/TAIR10/Athaliana_TAIR10 #This is the path of the reference index suffix
GATKPATH=/data/ryanabashbash/Downloads/GenomeAnalysisTK-3.2-2/GenomeAnalysisTK.jar #This is the path of the GATK .jar file


############################
#Below is the pipeline.
############################

#Pipeline
echo -e "\n\tEntering the pipeline with the following inputs:\n"
echo -e "Number threads for BWA:\t\t${NUMTHREADSBWA}"
echo -e "Group ID:\t\t\t${GROUPID}"
echo -e "BWA binary path:\t\t${BWAPATH}"
echo -e "BWA index path:\t\t\t${BWAINDEX}"
echo -e "Picard path:\t\t\t${PICARDPATH}"
echo -e "Output path:\t\t\t${OUTPUTPATH}"
echo -e "Memory allocated to the JVM:\t${JAVAMEMORY}"
echo -e "GATK path:\t\t\t${GATKPATH}"
echo -e "Number of threads for GATK:\t${GATKNUMTHREADS}"
echo -e "GATK reference FASTA:\t\t${REFERENCEFASTA}"
echo -e "Interval file:\t\t\t${INTERVALFILE}"
echo -e "Pipeline version:\t\t${PIPELINEVERSION}"
echo -e "Directories containing .fastq files:"

for dir in ${FASTQDIRS[@]}
do
	        echo -e "\t\t$dir"
done

#Perform some checks on inputs:
#Check for the BWA binary
if [ -x ${BWAPATH} ] 
then
        echo -e "\nBWA binary found."
else
        echo -e "\n\tCannot find BWA binary. Please verify the location and permissions of the BWA executable.\n"
        exit 1
fi

#Check for the BWA index
if [ -f ${BWAINDEX}.amb ]  && [ -f ${BWAINDEX}.ann ] && [ -f ${BWAINDEX}.bwt ] && [ -f ${BWAINDEX}.pac ] && [ -f ${BWAINDEX}.sa ]  
then
	echo -e "BWA index files found."
else
	echo -e "\n\tCannot find BWA index files. Please verify the location of ${BWAINDEX}.amb, ${BWAINDEX}.ann, ${BWAINDEX}.bwt, ${BWAINDEX}.pac, and ${BWAINDEX}.sa.\n"
	exit 1
fi

#Check for the Picard directory
if [ -d ${PICARDPATH} ]
then
        echo -e "Picard directory found."
else
        echo -e "\n\tCannot find the Picard directory. Please verify its location.\n"
        exit 1
fi

#Check for the output directory
if [ -d ${OUTPUTPATH} ]
then
	echo -e "Output directory found."
else
	echo -e "\n\tCannot find the output directory. Please verify its location.\n"
	exit 1
fi

#Check for the logging directory
if [ -d ${LOGPATH} ]
then
        echo -e "Logging directory found."
else
        echo -e "\n\tCannot find the logging directory. Please verify its location.\n"
        exit 1
fi

#Check for the GATK .jar
if [ -f ${GATKPATH} ]
then
	echo -e "GATK's .jar found."
else
	echo -e "\n\tCannot find GATK's .jar file. Please verify its location.\n"
	exit 1
fi

#Check that the reference for the GATK is available
if [ -f ${REFERENCEFASTA} ] && [ -f ${REFERENCEFASTA}.fai ]
then
        echo -e "Reference .fasta and .fasta.fai found."
else
        echo -e "\n\tCannot find the reference .fasta and/or .fasta.fai. Please verify the location of the reference .fasta and .fasta.fai files.\n"
        exit 1
fi

#Check for the input FASTQ files
let TOTALFASTQ=0
for dir in ${FASTQDIRS[@]}
do
	if [ -d $dir ]
	then
		NUMFASTQ=$(ls ${dir}*.fq.gz* | wc -l)
		echo -e "Found $NUMFASTQ .fastq files in $dir"
		let TOTALFASTQ=TOTALFASTQ+NUMFASTQ
	else
		echo -e "\n\tCannot find FASTQ directory $dir. Please verify its location.\n"
		exit 1
	fi
done
echo -e "Found $TOTALFASTQ .fastq files across all directories"


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
	FILES=$dir*.fq.gz
	for file in $FILES
	do
		numJobs=`qstat | wc -l`
        	jobsAllowed=80
        	while [ $numJobs -ge $jobsAllowed ]
        	do
			echo `date` "There are $numJobs in queue. Waiting for some jobs to finish before submitting more."
                	sleep 600
                	numJobs=`qstat | wc -l`
		done    

		parentDir=$(basename ${dir})
		sampleID=${parentDir}
		fileID=$(basename ${file})
		fileID=${fileID%.fq.gz}
		SAMName=${sampleID}.sam
	
		RG="@RG\tID:${fileID}_single_end\tSM:${sampleID}\tPL:ILLUMINA-HiSeq-2000\tLB:${fileID}_single_end\tPU:${fileID}_single_end"
		echo -e "\nStarting sample $fileID with read group: $RG"

		qsub -N BWA_${fileID}_single_end -l num_threads=${NUMTHREADSBWA} -o ${LOGPATH}BWA_${fileID}_single_end.o -e ${LOGPATH}BWA_${fileID}_single_end.e ./jobScripts/BWAjobSE.sh ${BWAPATH} ${NUMTHREADSBWA} $RG ${BWAINDEX} ${file} ${OUTPUTPATH}${fileID}.sam >& ${LOGPATH}qsub.tmp
		                
		job=`grep "Your job" ${LOGPATH}qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
		JOBARRAY+=($job)
		echo "BWA single end job submitted as $job."
		
		SAMPLEFILEARRAY+=(${OUTPUTPATH}${fileID}.sam)
		REMOVALARRAY+=(${OUTPUTPATH}${fileID}.sam)
		DEPENDENCYSTRING=${DEPENDENCYSTRING},BWA_${fileID}_single_end
	done

	qsub -N Picard_${sampleID} -hold_jid ${DEPENDENCYSTRING#,} -l num_threads=1 -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Picard_${sampleID}.o -e ${LOGPATH}Picard_${sampleID}.e ./jobScripts/PicardMergejob.sh ${PICARDPATH} ${OUTPUTPATH}${sampleID}.merged.sorted.bam ${SAMPLEFILEARRAY[@]} >& ${LOGPATH}qsub.tmp

	job=`grep "Your job" ${LOGPATH}qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
	JOBARRAY+=($job)
	echo "Picard job submitted as $job."

        qsub -N PicardMarkDup_${sampleID} -hold_jid Picard_${sampleID} -l num_threads=1 -l mem_free=${JAVAMEMORY} -o ${LOGPATH}PicardMarkDup_${sampleID}.o -e ${LOGPATH}PicardMarkDup_${sampleID}.e ./jobScripts/PicardMarkDupjob.sh ${PICARDPATH} ${OUTPUTPATH}${sampleID}.merged.sorted.bam ${OUTPUTPATH}${sampleID}.dedupped.sorted.bam >& ${LOGPATH}qsub.tmp

        job=`grep "Your job" ${LOGPATH}qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
        JOBARRAY+=($job)
        echo "Picard job submitted as $job."

	qsub -N Target_${sampleID} -hold_jid PicardMarkDup_${sampleID} -l num_threads=${GATKNUMTHREADS} -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Target_${sampleID}.o -e ${LOGPATH}Target_${sampleID}.e ./jobScripts/TargetPhred64job.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${OUTPUTPATH}${sampleID}.dedupped.sorted.bam ${OUTPUTPATH}${sampleID}.intervals >& ${LOGPATH}qsub.tmp

        job=`grep "Your job" ${LOGPATH}qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
        JOBARRAY+=($job)
        echo "TargetIdentification job submitted as $job."

        qsub -N Realigner_${sampleID} -hold_jid Target_${sampleID} -l num_threads=1 -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Realigner_${sampleID}.o -e ${LOGPATH}Realigner_${sampleID}.e ./jobScripts/RealignerPhred64job.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${OUTPUTPATH}${sampleID}.dedupped.sorted.bam ${OUTPUTPATH}${sampleID}.intervals ${OUTPUTPATH}${sampleID}.realigned.bam >& ${LOGPATH}qsub.tmp

        job=`grep "Your job" ${LOGPATH}qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
        JOBARRAY+=($job)
        echo "IndelRealignment job submitted as $job."

	REMOVALARRAY+=(${OUTPUTPATH}${sampleID}.merged.sorted.bam)
	REMOVALARRAY+=(${OUTPUTPATH}${sampleID}.merged.sorted.bai)
	REMOVALARRAY+=(${OUTPUTPATH}${sampleID}.dedupped.sorted.bam)
	REMOVALARRAY+=(${OUTPUTPATH}${sampleID}.dedupped.sorted.bai)
	REMOVALARRAY+=(${OUTPUTPATH}${sampleID}.intervals)

	qsub -N Cleanup_${sampleID} -hold_jid Realigner_${sampleID} -l num_threads=1 -l mem_free=1g -o ${LOGPATH}Cleanup_${sampleID}.o -e ${LOGPATH}Cleanup_${sampleID}.e ./jobScripts/CleanupIntermediatesjob.sh ${REMOVALARRAY[@]} >& ${LOGPATH}qsub.tmp

        job=`grep "Your job" ${LOGPATH}qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
        JOBARRAY+=($job)
        echo "Cleanup job submitted as $job."

done

for indJob in ${JOBARRAY[@]}
do
	qstat -j $indJob >& ${LOGPATH}qstat.tmp
	while [ $? -eq 0 ]
	do
		echo `date` "Waiting for all individual jobs to complete. Currently waiting on ${indJob}."
		sleep 600
		qstat -j $indJob >& ${LOGPATH}qstat.tmp
	done
done

ALLSUCCESSFUL="True"
rm ${LOGPATH}failedJobs.txt
for indJob in ${JOBARRAY[@]}
do
	exitStatus=`qacct -o ryanabashbash -j $indJob | grep exit_status | awk '{print $2}'`
	if [ $exitStatus = "1" ]
	then
		ALLSUCCESSFUL="False"
		jobName=`qacct -o ryanabashbash -j $indJob | grep jobname | awk '{print $2}'`
		echo Job $indJob named $jobName failed.
		echo Job $indJob named $jobName failed. >> ${LOGPATH}failedJobs.txt
	fi
done

