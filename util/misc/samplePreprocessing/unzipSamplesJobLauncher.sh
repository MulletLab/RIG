LOGPATH=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/NRRB/data/unzipSamplesLog/
NUMTHREADS=8
rm -f ${LOGPATH}*.*[oe]*

#001_lane1
#001_lane2
#001_lane3
JOBNAME="UnzipESAP"
JOBSCRIPT=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/NRRB/data/unzipSampleJobScripts/unzip_E-SAP.sh
qsub -N ${JOBNAME} -l mem_free=1g -l num_threads=${NUMTHREADS} -o ${LOGPATH}${JOBNAME}.o -e ${LOGPATH}${JOBNAME}.e ${JOBSCRIPT} ${NUMTHREADS}

#002_lane1
#002_lane2
#002_lane3
#002_lane4
#002_lane5
#002_lane6
JOBNAME="UnzipGSAP"
JOBSCRIPT=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/NRRB/data/unzipSampleJobScripts/unzip_G-SAP.sh
qsub -N ${JOBNAME} -l mem_free=1g -l num_threads=${NUMTHREADS} -o ${LOGPATH}${JOBNAME}.o -e ${LOGPATH}${JOBNAME}.e ${JOBSCRIPT} ${NUMTHREADS}

#005_lane8
JOBNAME="UnzipEarlyIntro"
JOBSCRIPT=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/NRRB/data/unzipSampleJobScripts/unzip_EarlyIntro.sh
qsub -N ${JOBNAME} -l mem_free=1g -l num_threads=${NUMTHREADS} -o ${LOGPATH}${JOBNAME}.o -e ${LOGPATH}${JOBNAME}.e ${JOBSCRIPT} ${NUMTHREADS}

#006_lane8
#008_lane4
JOBNAME="UnzipSwSAP"
JOBSCRIPT=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/NRRB/data/unzipSampleJobScripts/unzip_SwSAP.sh
qsub -N ${JOBNAME} -l mem_free=1g -l num_threads=${NUMTHREADS} -o ${LOGPATH}${JOBNAME}.o -e ${LOGPATH}${JOBNAME}.e ${JOBSCRIPT} ${NUMTHREADS}

#008_lane6
JOBNAME="UnzipTx2909Hyb"
JOBSCRIPT=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/NRRB/data/unzipSampleJobScripts/unzip_Tx2909Hyb.sh
qsub -N ${JOBNAME} -l mem_free=1g -l num_threads=${NUMTHREADS} -o ${LOGPATH}${JOBNAME}.o -e ${LOGPATH}${JOBNAME}.e ${JOBSCRIPT} ${NUMTHREADS}

#005_lane2
#007_lane7
#008_lane5
JOBNAME="UnzipMisc"
JOBSCRIPT=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/NRRB/data/unzipSampleJobScripts/unzip_Misc.sh
qsub -N ${JOBNAME} -l mem_free=1g -l num_threads=${NUMTHREADS} -o ${LOGPATH}${JOBNAME}.o -e ${LOGPATH}${JOBNAME}.e ${JOBSCRIPT} ${NUMTHREADS}


#008_lane8
JOBNAME="UnzipDiv-008"
JOBSCRIPT=/data/ryanabashbash/GATK_pipeline/RAD_seq/Populations/Germplasm_collection/NRRB/data/unzipSampleJobScripts/unzip_Div-008.sh
qsub -N ${JOBNAME} -l mem_free=1g -l num_threads=${NUMTHREADS} -o ${LOGPATH}${JOBNAME}.o -e ${LOGPATH}${JOBNAME}.e ${JOBSCRIPT} ${NUMTHREADS}

