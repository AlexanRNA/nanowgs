# Nanowgs

This repository contains the Nextflow pipeline used to analyse Nanopore whole-genome sequences in the context of ASAP.
Current version as of 20221201

## Nanowgs on wice

To run nanowgs on VSC HPC ***wice*** cluster.
- First, clone the repository
```
git clone https://github.com/AlexanRNA/nanowgs.git
```
- Next, you need to update the config file. Update the following parameters. They can also be overwritten by command line input later on.
```
genomeref 
sampleid
guppy_config
outdir
karyotype 
shasta_minreadlength (6000 recommended)
```
- Update working directory. Preferably, you use your own scratch 
```
workDir = '/scratch/leuven/path/to/scratch/nextflow'
```
-  In singularity profile part of config, you may want to update the location of the singularity images. However, the current location should work for you
```
singularity.cacheDir = '/path/to/images'
```
- Once your config file is updated, you can mproceed with actually running the pipeline

Open a new tmux window on one of the reserved Genius nodes (r23i27n14 r23i27n22 r23i27n23 r23i27n24). Login node is not recommended, since this pipeline runs for a while and can be thus killed at some point. 
```
tmux new-session -A -s nanowgs
```
 Load nextflow (version >=19.10.0) and export environmental variable
 ```
 ml Nextflow
 export SLURM_CLUSTERS=wice
 ```

 Now, you can run nanowgs nextflow pipeline using the following command. I recommend starting the pipeline in your output directory, so you have report and timeline, as well as all nextflow logs at the same location. 
 ```
/path/to/repo/nanowgs/main.nf \
-profile singularity,slurm \
-entry slurm \
--karyotype xx \
--outdir /path/to/output_dir -with-report -with-timeline 
 ```

## Nanowgs on genius

You can run this pipeline also on genius. Preferably, you do the basecalling beforehand.
To launch pipeline, you follow the same steps as previously, but your nextflow command is: 
```
/path/to/repo/nanowgs/main.nf -profile singularity,qsub -entry wgs_analysis_fastq \
--ont_base_dir /path/to/fastqs/ --outdir /path/to/output_dir \
--karyotype xx -with-report -with-timeline
```





