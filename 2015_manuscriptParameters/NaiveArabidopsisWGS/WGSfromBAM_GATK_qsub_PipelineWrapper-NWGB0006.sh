#!/bin/bash
############
#Naive Reduced Representation Pipeline
#Written by Ryan McCormick
#06/25/14
#Texas A&M University
#This is provided without warranty, and is unlikely to work right out of the box
#due to architecture differences between clusters and job submission systems.
###########

#TODO: Add a tmp directory
PIPELINEVERSION="NWGB0006"

#Hardware values
NUMTHREADSBWA=1
GATKNUMTHREADS=7
GATKNUMCPUTHREADS=7
JAVAMEMORY="32g"

#Group ID used to name output files
GROUPID="WGS-trainingSupplement_naive"

#File paths
#The parent directory of samples will be used as the read group, so place samples from the same read group in the same directory.
BAMDIRS[0]=/data/ryanabashbash/GATK_pipeline/WGS/RIG_ArabidopsisValidation/WGS-collection/TrainingSupplement/data/results_trainingSupplement/

OUTPUTPATH=/data/ryanabashbash/GATK_pipeline/WGS/RIG_ArabidopsisValidation/WGS-collection/TrainingSupplement/results_trainingSupplement/
LOGPATH=/data/ryanabashbash/GATK_pipeline/WGS/RIG_ArabidopsisValidation/WGS-collection/TrainingSupplement/log_trainingSupplement/
INTERVALLISTDIR=/data/ryanabashbash/GATK_pipeline/WGS/RIG_ArabidopsisValidation/WGS-collection/TrainingSupplement/intervalLists/
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

for dir in ${BAMDIRS[@]}
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
			
#Check for the file of contigs
if [ -d ${INTERVALLISTDIR} ]
then
	echo -e "Contig directory found."
else
	echo -e "\n\tCannot find the contig directory. Please verify its location.\n"
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

#Check for the input BAM files
#TODO: Add an exit here if no BAM file are found
let TOTALFASTQ=0
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
echo -e "Found $TOTALBAM .bam files across all directories"


#Finished checking pipeline inputs. Proceed with pipeline
echo -e "\n\tInitial checks passed. Proceeding with pipeline.\n"

DEPENDENCYSTRING=""
HAPLOCALLERARRAY=()
HAPLOCALLERJOBSTRINGARRAY=()
#Clean the log?
:<<"SNURFLE"
rm -f ${LOGPATH}*.*[oe]*
#Resolve individual files
for dir in ${BAMDIRS[@]}
do
	FILES=$dir*.bam
        for file in $FILES
        do
                dirName=$(dirname $file)
                parentDir=${dirName##*/}
                stripPath=${file##*/}
                sampleID=${stripPath%%.*}
	
		echo -e "\n\tOn sample ${sampleID}\n"
		
		#Submit the jobs for individual intervals so that we can re-run them individually on GATK threading crash
		intervalFiles=${INTERVALLISTDIR}*.intervals
		for intervalList in ${intervalFiles}
		do
			interval=${intervalList##*/}
			interval=${interval%%.*}
			numJobs=`qstat | wc -l`
	                jobsAllowed=70
	                while [ $numJobs -ge $jobsAllowed ]
	                do
	                        echo `date` "There are $numJobs in queue. Waiting for some jobs to finish before submitting more."
	                        sleep 600
	                        numJobs=`qstat | wc -l`
	                done

#			haplocallJobString="qsub -N HaploCall_${sampleID}_${interval} -l mem_free=${JAVAMEMORY} -l num_threads=${GATKNUMTHREADS} -o ${LOGPATH}HaplotypeCaller_${sampleID}_${interval}.o -e ${LOGPATH}HaplotypeCaller_${sampleID}_${interval}.e ./jobScripts/HaploCallerIntervalsjob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${file} ${OUTPUTPATH}${sampleID}_${interval}.GVCF.vcf ${intervalList} >& ${LOGPATH}qsub.tmp"
			#Haplotype Caller multithreading bug is still too common so making it single threaded.
			haplocallJobString="qsub -N HaploCall_${sampleID}_${interval} -l mem_free=${JAVAMEMORY} -l num_threads=1 -o ${LOGPATH}HaplotypeCaller_${sampleID}_${interval}.o -e ${LOGPATH}HaplotypeCaller_${sampleID}_${interval}.e ./jobScripts/HaploCallerIntervalsjob.sh ${JAVAMEMORY} ${GATKPATH} 1 ${REFERENCEFASTA} ${file} ${OUTPUTPATH}${sampleID}_${interval}.GVCF.vcf ${intervalList} >& ${LOGPATH}qsub.tmp"

			eval ${haplocallJobString}

			job=`grep "Your job" ${LOGPATH}qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
			HAPLOCALLERJOBARRAY+=($job)
			HAPLOCALLERJOBSTRINGARRAY+=("$haplocallJobString")
       			echo "HaplotypeCaller job on interval $interval submitted as $job."
			DEPENDENCYSTRING=${DEPENDENCYSTRING},HaploCall_${sampleID}_${interval}
		done
	done
done

for indJob in ${HAPLOCALLERJOBARRAY[@]}
do
        qstat -j $indJob >& ${LOGPATH}qstat.tmp
        while [ $? -eq 0 ]
        do
	        echo `date` "Waiting for all individual HC jobs to complete. Currently waiting on ${indJob}."
		sleep 600
                qstat -j $indJob >& ${LOGPATH}qstat.tmp
        done    
done

ALLHAPLOSUCCESSFUL="False"
rm ${LOGPATH}failedHaploJobs.txt
while [ $ALLHAPLOSUCCESSFUL = "False" ]
do
	nextIterHCJobArray=()
	nextIterHCJobStringArray=()
	for jobIndex in ${!HAPLOCALLERJOBARRAY[@]}
	do
		#echo "The Array values at index ${jobIndex} are:"
		#echo ${HAPLOCALLERJOBARRAY[${jobIndex}]}
		#echo "${HAPLOCALLERJOBSTRINGARRAY[${jobIndex}]}"
		indJob=${HAPLOCALLERJOBARRAY[${jobIndex}]}
		exitStatus=`qacct -o ryanabashbash -j ${indJob} | grep exit_status | awk '{print $2}'`
	        if [ $exitStatus = "1" ]
        	then
			numJobs=`qstat | wc -l`
			jobsAllowed=70
			while [ $numJobs -ge $jobsAllowed ]
			do
				echo `date` "There are $numJobs in queue. Waiting for some jobs to finish before submitting more."
				sleep 600
				numJobs=`qstat | wc -l`
			done

			jobName=`qacct -o ryanabashbash -j $indJob | grep jobname | awk '{print $2}'`
                	echo Job $indJob named $jobName failed.
	                echo Job $indJob named $jobName failed. >> ${LOGPATH}failedHaploJobs.txt
			eval "${HAPLOCALLERJOBSTRINGARRAY[${jobIndex}]}"
	                job=`grep "Your job" ${LOGPATH}qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
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
		for indJob in ${nextIterHCJobArray[@]}
		do
	        	qstat -j $indJob >& ${LOGPATH}qstat.tmp
	        	while [ $? -eq 0 ]
	        	do
	                	echo `date` "Waiting for all individual resubmitted HC jobs to complete. Currently waiting on ${indJob}."
	                	sleep 600
	                	qstat -j $indJob >& ${LOGPATH}qstat.tmp
	        	done
		done
		HAPLOCALLERJOBARRAY=(${nextIterHCJobArray[@]})
	        HAPLOCALLERJOBSTRINGARRAY=("${nextIterHCJobStringArray[@]}")
	fi
done

#TODO: Store the list of GVCF files as an array since the way it's done here causes
#      unexpected behavior if the output directory has GVCFs already.
GVCFFILES=${OUTPUTPATH}*GVCF.vcf
GVCFARRAY=()
COMBINEJOBARRAY=()
for file in $GVCFFILES
do
	GVCFARRAY+=($file)
done

lastFile="NULL"
rangeLength=50
GVCFiter=1
while [ ${#GVCFARRAY[@]} -gt 1 ]
do
	qsub -N CombineSamples_${GVCFiter} -hold_jid ${DEPENDENCYSTRING#,} -l mem_free=${JAVAMEMORY} -l num_threads=${GATKNUMTHREADS} -o ${LOGPATH}CombineSamples_${GVCFiter}.o -e ${LOGPATH}CombineSamples_${GVCFiter}.e ./jobScripts/CombineGVCFjob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${OUTPUTPATH} ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_${GVCFiter}.popGVCF.vcf ${GVCFARRAY[@]:0:${rangeLength}} >& ${LOGPATH}qsub.tmp

	job=`grep "Your job" ${LOGPATH}qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
	COMBINEJOBARRAY+=($job)
	echo "CombineSamples on iteration ${GVCFiter} submitted as $job"

	qsub -N CleanupGVCFs_${GVCFiter} -hold_jid CombineSamples_${GVCFiter} -l mem_free=1g -l num_threads=1 -o ${LOGPATH}CleanupGVCFs_${GVCFiter}.o -e ${LOGPATH}CleanupGVCFs_${GVCFiter}.e ./jobScripts/CleanupGVCFsjob.sh ${GVCFARRAY[@]:0:${rangeLength}} >& ${LOGPATH}qsub.tmp

        job=`grep "Your job" ${LOGPATH}qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`
        COMBINEJOBARRAY+=($job)
        echo "Cleanup on iteration ${GVCFiter} submitted as $job"

	let "GVCFiter=${GVCFiter}+1"

	for indJob in ${COMBINEJOBARRAY[@]}
	do
	        qstat -j $indJob >& ${LOGPATH}qstat.tmp
		while [ $? -eq 0 ]
	        do
	                echo `date` "Waiting for all individual Combine jobs to complete. Currently waiting on ${indJob}."
	                sleep 600
	                qstat -j $indJob >& ${LOGPATH}qstat.tmp
	        done
	done

	GVCFFILES=${OUTPUTPATH}*GVCF.vcf
        GVCFARRAY=()
        for file in $GVCFFILES
        do
		GVCFARRAY+=($file)
		lastFile=${file}
        done
done

#TODO: Add tmp directory argument for Java into this one. It's currently hardcoded in the job file.
qsub -N JointGenotype -hold_jid CombineSamples -l mem_free=${JAVAMEMORY} -l num_threads=${GATKNUMTHREADS} -o ${LOGPATH}JointGenotype.o -e ${LOGPATH}JointGenotype.e ./jobScripts/JointGenotypejob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${lastFile} ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_unfiltered.vcf
SNURFLE
qsub -N FilterVariants -hold_jid JointGenotype -l mem_free=1g -l num_threads=${GATKNUMTHREADS} -o ${LOGPATH}FilterVariants.o -e ${LOGPATH}FilterVariants.e ./jobScripts/FilterVariantsjob.sh ${JAVAMEMORY} ${GATKPATH} ${GATKNUMTHREADS} ${REFERENCEFASTA} ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}_unfiltered.vcf ${OUTPUTPATH}${GROUPID}_${PIPELINEVERSION}.vcf


