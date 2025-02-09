# Nanowgs

This repository contains the Nextflow pipeline used to analyse Nanopore whole-genome sequences in the context of ASAP.
Current version as of 2023-08-08

## Nanowgs on wice

To run nanowgs on VSC HPC ***wICE*** cluster.
- First, clone the repository
```
git clone https://github.com/AlexanRNA/nanowgs.git
```
- Next, you need to update the config file. Update the following parameters. They can also be overwritten by command line input parameters
```
genomeref 
sampleid
guppy_config OR dorado_config
mod_bases
clair3_config
shasta_config
shasta_minreadlength (6000 recommended)
outdir
karyotype 
```
- Update working directory. Preferably, you use your own scratch 
```
workDir = '/scratch/leuven/path/to/scratch/nextflow'
```
-  In singularity profile part of config, you may want to update the location of the singularity images. However, the current location should work for you
```
singularity.cacheDir = '/path/to/images'
```
- Once your config file is updated, you can proceed with actually running the pipeline

Open a new tmux window on one of the reserved Genius nodes (r23i27n14 r23i27n22 r23i27n23 r23i27n24), or any CPU wICE node. Login node is ***not*** recommended, since this pipeline runs for a while and can be thus killed at some point. 
```
tmux new-session -A -s nanowgs
```
 Load nextflow (version >=19.10.0) and export environmental variable. You can also save the environmental variable in your `.bashrc` file
 ```
 ml Nextflow
 export SLURM_CLUSTERS=wice
 ```

 Now, you can run nanowgs nextflow pipeline.
 
 ## Guppy + following analysis  ( pre-Feb 2023 )

 To run guppy basecalling and the following processing, use the following command. I recommend starting the pipeline in your output directory, so you have report and timeline, as well as all nextflow logs at the same location. 
 ```
/path/to/repo/nanowgs/main.nf \
-profile singularity,slurm \
-entry slurm \
--karyotype xx \
--outdir /path/to/output_dir -with-report -with-timeline 
 ```

 ## Dorado basecalling ( August 2023 ) 
 To run new ONT basecaller, use the following command. It will first convert fast5 files to pod5 and then proceed to basecall using ONT Dorado (v0.3.2). Make sure you specify the model and modified bases required.

 If no output directory is specified, the output will be located wherever the nextflow pipeline was started.
 You provide `--fast5` in case your data is in fast5 format and not in pod5. In case of pod5, no parameter/flag needs to be provided.

 You can also use [rerio modified basecalling models](https://github.com/nanoporetech/rerio/tree/master#dorado-models). In that case, you need to update `rerio_config` with the native basecalling model and provide base modification you wish to call in `mod_bases`. 
 ```
/path/to/repo/nanowgs/main.nf \
-profile singularity,slurm \
-entry dorado_call \
--dorado_config "dna_r10.4.1_e8.2_400bps_sup@v4.1.0" \
--mod_bases "5mCG_5hmCG" \
--sampleid ASA_143B \
--ont_base_dir /path/to/fast5 \
--fast5
-with-report -with-timeline 
 ```

 ## Following analysis (August 2023, **still in development**)

This is the command that can be used to run subsequent analysis. However, bear in mind, this part of pipeline is still in development and was not fully tested. The example below is specific for LSK114 chemistry basecalled with `dna_r10.4.1_e8.2_400bps_sup@v4.0.0` basecalling model.
In case your data also hase modified bases information, do include `--mod_bases 5mC` (5mC is just exmaple) to your command to get some statistics and visualisations around TSS/CTCF.
```
/path/to/repo/nanowgs/main.nf \
-profile singularity,slurm \
-entry slurm_dorado \
--ubam /location/of/your/file.bam \
--sampleid ASA_145B \
--outdir /path/to/output_dir \
--clair3_config "/opt/bin/rerio/clair3_models/r1041_e82_400bps_sup_v400" \
--shasta_config "Nanopore-R10-Fast-Nov2022" \
--karyotype xy \
-with-timeline -with-report
```



# TODO

### Todo
 
- [ ] make the bam alignment more effective (too time consuming atm)
- [ ] update dorado version + script
- [ ] investigate CRAM saving

### In Progress

- [ ] modified basecalling QC/checking 
- [X] update sniffles version + size filtering to 50
- [X] update clair3 version + size filtering to 50
- [X] update longphase version


### Done ✓
 
## Cite this work
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.13385065.svg)](https://doi.org/10.5281/zenodo.13385065)


