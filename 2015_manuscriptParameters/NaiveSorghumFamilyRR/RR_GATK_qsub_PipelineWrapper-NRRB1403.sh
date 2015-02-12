#!/bin/bash
############
#Naive Reduced Representation Pipeline
#Written by Ryan McCormick
#06/25/14
#Texas A&M University
#This is provided without warranty, and is unlikely to work right out of the box
#due to architecture differences between clusters and job submission systems.
###########

PIPELINEVERSION="NRRB1403"

#Hardware values
NUMTHREADSBWA=8
GATKNUMTHREADS=8
GATKNUMCPUTHREADS=8 
JAVAMEMORY="32g"

#Group ID used to name output files
GROUPID="BTx623xIS3620c_01-02-14_family"

#File paths
#The parent directory of samples will be used as the read group, so place samples from the same read group in the same directory.
FASTQDIRS[0]=/data/ryanabashbash/GATK_pipeline/RAD_seq/BTx623xIS3620c_01-02-14/data/004_lane3/
FASTQDIRS[1]=/data/ryanabashbash/GATK_pipeline/RAD_seq/BTx623xIS3620c_01-02-14/data/parents/005_lane2/
FASTQDIRS[2]=/data/ryanabashbash/GATK_pipeline/RAD_seq/BTx623xIS3620c_01-02-14/data/004_lane4/
FASTQDIRS[3]=/data/ryanabashbash/GATK_pipeline/RAD_seq/BTx623xIS3620c_01-02-14/data/004_lane5/
FASTQDIRS[4]=/data/ryanabashbash/GATK_pipeline/RAD_seq/BTx623xIS3620c_01-02-14/data/004_lane6/
FASTQDIRS[5]=/data/ryanabashbash/GATK_pipeline/RAD_seq/BTx623xIS3620c_01-02-14/data/005_lane1/
FASTQDIRS[6]=/data/ryanabashbash/GATK_pipeline/RAD_seq/BTx623xIS3620c_01-02-14/data/005_lane2/

OUTPUTPATH=/data/ryanabashbash/GATK_pipeline/RAD_seq/BTx623xIS3620c_01-02-14/results/
LOGPATH=/data/ryanabashbash/GATK_pipeline/RAD_seq/BTx623xIS3620c_01-02-14/log/
REFERENCEFASTA=/data/ryanabashbash/Sbi1_reference/reference/sbi1.fasta #There also needs to be a fasta index file (.fai) in the same directory as this reference.
INTERVALFILE=/data/ryanabashbash/GATK_pipeline/RAD_seq/BTx623xIS3620c_01-02-14/intervals/NgoMIVintervals.intervals
PICARDPATH=/data/ryanabashbash/Downloads/picard-tools-1.108/  #This is the path of the directory containing the Picard tools
BWAPATH=/data/ryanabashbash/Downloads/bwa-0.7.7/bwa  #This is the path of the BWA executable
BWAINDEX=/data/ryanabashbash/Sbi1_reference/Sbi1_BWAindex/Sbi1 #This is the path of the reference index suffix
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

#Check for the input interval file for the GATK
if [ -f ${INTERVALFILE} ]
then
	echo -e "Interval file found."
else
	echo -e "\n\tCannot find the interval file. Please verify its location.\n"
        exit 1
fi

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


#Finished checking pipeline inputs. Proceed with pipeline
echo -e "\n\tInitial checks passed. Proceeding with pipeline.\n"

DEPENDENCYSTRING=""
JOBARRAY=()
#Clean the log?
rm -f ${LOGPATH}*.*[oe]* 
#Resolve individual files
for dir in ${FASTQDIRS[@]}
do
	FILES=$dir*.fastq*
        for file in $FILES
        do
		numJobs=`qstat | wc -l`
		jobsAllowed=75
		while [ $numJobs -ge $jobsAllowed ]
		do
			echo `date` "There are $numJobs in queue. Waiting for some jobs to finish before submitting more."
			sleep 600
			numJobs=`qstat | wc -l`
		done

                dirName=$(dirname $file)
                parentDir=${dirName##*/}
                stripPath=${file##*/}
                sampleID=${stripPath%.fastq.gz}
                SAMName=${sampleID}.sam
                RG="@RG\tID:${GROUPID}_${sampleID}\tSM:${sampleID}\tPL:ILLUMINA-HiSeq-2500\tLB:${GROUPID}\tPU:${GROUPID}_${parentDir}"
                echo -e "\nStarting sample $SAMName with read group: $RG"
		
		qsub -N BWA_${sampleID} -pe mpi ${NUMTHREADSBWA} -q normal.q -o ${LOGPATH}BWA_${sampleID}.o -e ${LOGPATH}BWA_${sampleID}.e ./jobScripts/BWAjob.sh ${BWAPATH} ${NUMTHREADSBWA} $RG ${BWAINDEX} ${file} ${OUTPUTPATH}${sampleID}.sam >& qsub.tmp
		                
		job=`grep "Your job" qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
                JOBARRAY+=($job)
		echo "BWA job submitted as $job."
				
		qsub -N Picard_${sampleID} -hold_jid BWA_${sampleID} -pe mpi 1 -q normal.q -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Picard_${sampleID}.o -e ${LOGPATH}Picard_${sampleID}.e ./jobScripts/Picardjob.sh ${PICARDPATH} ${OUTPUTPATH}${SAMName} ${OUTPUTPATH}${sampleID}.sorted.bam >& qsub.tmp

                job=`grep "Your job" qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
		JOBARRAY+=($job)
                echo "Picard job submitted as $job."
	
		qsub -N Target_${sampleID} -hold_jid Picard_${sampleID} -pe mpi ${GATKNUMTHREADS} -q normal.q -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Target_${sampleID}.o -e ${LOGPATH}Target_${sampleID}.e ./jobScripts/Targetjob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH}${sampleID}.sorted.bam ${OUTPUTPATH}${sampleID}.intervals >& qsub.tmp

                job=`grep "Your job" qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
		JOBARRAY+=($job)
                echo "TargetIdentification job submitted as $job."

		qsub -N Realigner_${sampleID} -hold_jid Target_${sampleID} -pe mpi 1 -q normal.q -l mem_free=${JAVAMEMORY} -o ${LOGPATH}Realigner_${sampleID}.o -e ${LOGPATH}Realigner_${sampleID}.e ./jobScripts/Realignerjob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${OUTPUTPATH}${sampleID}.sorted.bam ${OUTPUTPATH}${sampleID}.intervals ${OUTPUTPATH}${sampleID}.realigned.bam >& qsub.tmp

                job=`grep "Your job" qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
		JOBARRAY+=($job)
                echo "IndelRealignment job submitted as $job."

		#Testing a non-multithreaded version to see if it helps the thread saftey crashes
		#qsub -N HaploCall_${sampleID} -hold_jid Realigner_${sampleID} -pe mpi ${GATKNUMTHREADS} -q normal.q -l mem_free=${JAVAMEMORY} HaploCallerjob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH}${sampleID}.realigned.bam ${OUTPUTPATH}${sampleID}.GVCF.vcf >& qsub.tmp
      		
		#Due to thread safety crashes, the HaplotypeCaller is set to use only 1 processor.
		qsub -N HaploCall_${sampleID} -hold_jid Realigner_${sampleID} -pe mpi 1 -q normal.q -l mem_free=${JAVAMEMORY} -o ${LOGPATH}HaploCall_${sampleID}.o -e ${LOGPATH}HaploCall_${sampleID}.e ./jobScripts/HaploCallerjob.sh ${JAVAMEMORY} ${GATKPATH} 1 ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH}${sampleID}.realigned.bam ${OUTPUTPATH}${sampleID}.GVCF.vcf >& qsub.tmp

		job=`grep "Your job" qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
		JOBARRAY+=($job)
         	echo "HaplotypeCaller job submitted as $job."

		qsub -N Cleanup_${sampleID} -hold_jid HaploCall_${sampleID} -pe mpi 1 -q normal.q -l mem_free=1g -o ${LOGPATH}Cleanup_${sampleID}.o -e ${LOGPATH}Cleanup_${sampleID}.e ./jobScripts/CleanupIntermediatesjob.sh ${OUTPUTPATH}${sampleID}.sam ${OUTPUTPATH}${sampleID}.sorted.bam ${OUTPUTPATH}${sampleID}.sorted.bai ${OUTPUTPATH}${sampleID}.intervals ${OUTPUTPATH}${sampleID}.realigned.bam ${OUTPUTPATH}${sampleID}.realigned.bai

		DEPENDENCYSTRING=${DEPENDENCYSTRING},HaploCall_${sampleID},Cleanup_${sampleID}
	done
done

for indJob in ${JOBARRAY[@]}
do
	qstat -j $indJob >& qstat.tmp
	while [ $? -eq 0 ]
	do
		echo `date` "Waiting for all individual jobs to complete. Currently waiting on ${indJob}."
		sleep 600
		qstat -j $indJob >& qstat.tmp
	done
done

ALLSUCCESSFUL="True"
rm failedJobs.txt
for indJob in ${JOBARRAY[@]}
do
	exitStatus=`qacct -o ryanabashbash -j $indJob | grep exit_status | awk '{print $2}'`
	if [ $exitStatus = "1" ]
	then
		ALLSUCCESSFUL="False"
		jobName=`qacct -o ryanabashbash -j $indJob | grep jobname | awk '{print $2}'`
		echo Job $indJob named $jobName failed.
		echo Job $indJob named $jobName failed. >> failedJobs.txt
	fi
done

if [ $ALLSUCCESSFUL = "False" ]
then
	exit 1
fi

GVCFFILES=${OUTPUTPATH}*.GVCF.vcf
GVCFARRAY=()
for file in $GVCFFILES
do 
	GVCFARRAY+=($file)
done


qsub -N CombineSamples -hold_jid ${DEPENDENCYSTRING#,} -pe mpi ${GATKNUMTHREADS} -q normal.q -l mem_free=${JAVAMEMORY} -o ${LOGPATH}CombineSamples_${sampleID}.o -e ${LOGPATH}CombineSamples_${sampleID}.e ./jobScripts/CombineGVCFjob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${OUTPUTPATH} ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}.popGVCF.vcf ${GVCFARRAY[@]} >& qsub.tmp

job=`grep "Your job" qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
JOBARRAY+=($job)
echo "CombineSamples job submitted as $job."

exitStatus=`qacct -o ryanabashbash -j $indJob | grep exit_status | awk '{print $2}'`
if [ $exitStatus = "1" ]
then
	ALLSUCCESSFUL="False"
        echo $indJob Failed.
	echo $indJob >> failedJobs.txt
	exit 1
fi

qsub -N CleanupGVCFs -hold_jid CombineSamples -pe mpi 1 -q normal.q -l mem_free=1g -o ${LOGPATH}CleanupGVCFs_${sampleID}.o -e ${LOGPATH}CleanupGVCFs_${sampleID}.e ./jobScripts/CleanupGVCFsjob.sh ${GVCFARRAY[@]}

qsub -N JointGenotype -hold_jid CleanupGVCFs -pe mpi ${GATKNUMTHREADS} -q normal.q -l mem_free=${JAVAMEMORY} -o ${LOGPATH}JointGenotype_${sampleID}.o -e ${LOGPATH}JointGenotype_${sampleID}.e ./jobScripts/JointGenotypejob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}.popGVCF.vcf ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_unfiltered.vcf

qsub -N FilterVariants -hold_jid JointGenotype -pe mpi 1 -q normal.q -l mem_free=1g -o ${LOGPATH}FilterVariants_${sampleID}.o -e ${LOGPATH}FilterVariants_${sampleID}.e ./jobScripts/FilterVariantsjob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${INTERVALFILE} ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_unfiltered.vcf ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}.vcf


