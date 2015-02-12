#!/bin/bash
#Utility functions for the RIG pipelines.
#Written by Ryan McCormick
#02/03/15
#Texas A&M University
#This is provided without warranty, and is unlikely to work right out of the box
#due to architecture differences between clusters and job submission systems.
###########

#Checks if input argument 1 is an executable file.
#Input: $1 = path to executable file (string).
#Input: $2 = descriptor (string).
checkExecutable () {
	if [ -x $1 ]
	then
		echo -e "Executable at $1 found for $2."
	else
		echo -e "\n\tCannot find executable at $1 for $2. Please verify the location.\n"
		exit 1
	fi
}

#Check if input argument is a directory.
#Input: $1 = path to directory (string).
#Input: $2 = descriptor (string).
checkDirectory () {
	if [ -d $1 ]
	then
		echo -e "Directory at $1 found for $2."
	else
		echo -e "\n\tCannot find directory at $1 for $2. Please verify the location.\n"
		exit 1
	fi
}

#Check if input argument is a file.
#Input: $1 = path to file (string).
#Input: $2 = descriptor (string).
checkFile () {
	if [ -f $1 ]
	then
		echo -e "File at $1 found for $2."
	else
		echo -e "\n\tCannot find file at $1 for $2. Please verify the location.\n"
		exit 1
	fi
}

#Checks if all of the files corresponding to the input BWA index are available
#Input: $1 = path to BWA prefix
checkBWAindex () {
	if [ -f $1.amb ] && [ -f $1.ann ] && [ -f $1.bwt ] && [ -f $1.pac ] && [ -f $1.sa ]
	then
		echo -e "Files at $1 found for the BWA index."
	else
		echo -e "\n\tCannot find BWA index files. Please verify the location of $1.amb, $1.ann, $1.bwt, $1.pac, and $1.sa.\n"
		exit 1
	fi
}

#Checks if too many jobs are in queue, and pauses until sufficient time has passed.
#Input: $1 = number of jobs allowed (int)
#Input: $2 = time in seconds to sleep (int)
checkJobQueueLimit () {
	numJobs=`qstat | wc -l`
	while [ $numJobs -ge $1 ]
	do
		echo `date` "There are $numJobs in queue. Waiting for fewer than $1 before proceeding. Waiting $2 seconds."
		sleep $2
		numJobs=`qstat | wc -l`
	done
}

#Checks if all submitted jobs in the input array have completed, and waits 600 seconds otherwise before checking again.
#Input: $@ : Array of job ids (array of ints).
checkJobsInArrayForCompletion () {
for indJob in ${@}
do
	qstat -j $indJob >& ${LOGPATH}qstat.tmp
	while [ $? -eq 0 ] #qstat -j JobID returns 1 if job is finished.
	do
		echo `date` "Waiting for all individual jobs to complete. Currently waiting on ${indJob}."
		sleep 600
		qstat -j $indJob >& ${LOGPATH}qstat.tmp
	done
done
}

#Checks if all submitted jobs in the input array have successfully completed.
#Input: $1 : Path to logging directory (string).
#Input: ${@:2} : Array of job ids (array of ints).
#Output: "True" or "False" (string)
checkJobsInArrayForFailure () {
rm ${1}failedJobs.txt
ALLSUCCESSFUL="True"
for indJob in ${@:2}
do
	exitStatus=`qacct -o ryanabashbash -j $indJob | grep exit_status | awk '{print $2}'`
	if [ $exitStatus = "1" ]
	then
		ALLSUCCESSFUL="False"
		jobName=`qacct -o ryanabashbash -j $indJob | grep jobname | awk '{print $2}'`
		echo Job $indJob named $jobName failed. >> ${1}failedJobs.txt
	fi
done
echo $ALLSUCCESSFUL
}

#Extracts the job ID from the qsub.tmp log file.
#Input: $1 = path to the log directory (string).
extractJobId () {
	id=`grep "Your job" ${1}qsub.tmp | cut -f 1 -d '"' | cut -f 3 -d ' '`  #This is specific to the job submission system.
	echo $id
}


