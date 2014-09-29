LERRG
=====

This respository is an implemenation of the LERRG workflow as a series of Bash scripts. It is not portable since many architecture and user specific values are hardcoded in. Users should seriously consider using a Scala-based implementation using GATK's Queue before resorting to Bash. We resorted to Bash due to Queue and our compute cluster not playing nicely together. We provide this code as is, without warranty or guarantee.

Our implementation consists of 5 "pipelines":

1. Naive Reduced Representation qsub (NRRB)
2. Informed Reduced Representation qsub (IRRB)
3. Naive Whole Genome qsub (NWGB)
4. Initial Informed Whole Genome qsub (IIWGB)
5. Informed Whole Genome qsub (IWGB)

Each pipeline has a directory. Those who are interested in the annotations corresponding to the manuscript that we use for hard filtering and VQSR will find those in the following:

And those interested in the specific software and versions (e.g. BWA) can find those in the following:


Description of file organization
=====

Each of the five pipelines has a wrapper script that launches job scripts, tracks job status, and manages job submission. All input files are designated using the wrapper script. The jobs a wrapper launches are stored in the corresponding jobScripts directory. Some pipelines have a util directory containing some code for post-processing (e.g. converting a genetically structured family to R/qtl-formatted .ods file, or filling in missing genotypes with Beagle). Pipelines also contain an intervals directory that contains intervals used to either parallelize job submission (for the whole genome pipelines) or to only target a subset of the genome (for the reduced representation pipelines). The data directories contain various preprocessing scripts responsible for converting "raw" fastq files to files suitable for the pipeline wrapper.



