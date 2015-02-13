RIG
=====

This respository is an implemenation of the RIG workflow as a series of Bash scripts. Users should seriously consider a Scala-based implementation using GATK's Queue before resorting to Bash. We resorted to Bash due to Queue and our compute cluster not playing nicely together. We provide this code as is, without warranty or guarantee. Users interested in porting this to their architecture would likely need to change the way resources are requested via qsub, and change how logging files are parsed by the utility functions (e.g. currently a user name is hardcoded into the utility functions). See the publication for additional information on the workflow: http://g3journal.org/content/early/2015/02/13/g3.115.017012.full.pdf+html

The current implementation consists of a configuration file, a group of pipelines, and the jobs called by the pipelines. The pipelines are:

1. Naive Reduced Representation qsub (NRRB) 
2. Informed Reduced Representation qsub (IRRB) 
4. Initial Informed Whole Genome qsub (IIWGB)
5. Informed Whole Genome qsub (IWGB)

The current version for each pipeline can be found in its respective directory. Those interested in the annotations and software versions corresponding to the original RIG manuscript that were used for hard filtering and VQSR at the time of writing will find those in the 2015_manuscriptParameters directory:

1. Naive sorghum RR population and family hard filtering: https://github.com/Frogee/RIG/tree/master/2015_manuscriptParameters/NaiveSorghumPopulationRR 
2. Naive Arabidopsis WGS hard filtering:
3. https://github.com/Frogee/RIG/tree/master/2015_manuscriptParameters/NaiveArabidopsisWGS
3. Informed sorghum WGS recalibration: https://github.com/Frogee/RIG/tree/master/2015_manuscriptParameters/InformedSorghumWGS

Description of file organization
=====

A configuration file (e.g. https://github.com/Frogee/RIG/blob/master/RIG_configuration.sh) is used to specify a number of paths and resources, as well as the pipeline that will be used. The configuration file itself is a bash script that is launched, which in turn launches the designated pipeline. The pipeline submits jobs, tracks job status, and manages job submission. The jobs submitted by the pipeline are contained in the jobScripts directory.

Contact
=====

Contact Ryan McCormick at ryanabashbash@tamu.edu with questions or comments regarding the Bash implementation or RIG design. The GATK forums are also a great place for finding answers: http://gatkforums.broadinstitute.org/ 

