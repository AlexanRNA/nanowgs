
/* 
* Basecall reads with ONT Guppy
* TODO: implement guppy methyaltion directly if no m6A methylation - create new process maybe?
*/
process basecall_reads {
    label 'guppy'
    // label 'with_p100node'
    label ( workflow.profile.contains('slurm') ? 'wice_gpu' : 'with_p100node' ) //if slurm run wice, else P100 NVIDIA

    publishDir path: "${params.outdir}/${params.sampleid}/", mode: 'copy'

    input:
    path ont_base
    path genomeref
    // path genomrefidx

    output:
    path "basecalls/*fastq.gz", emit: fastqs
    path "basecalls/sequencing_summary.txt", emit: seq_summary 

    script:
    """
    /opt/ont-guppy/bin/guppy_basecaller \
        -i $ont_base \
        -s ./basecalls \
        -c ${params.guppy_config} \
        --recursive \
        --device "cuda:all" \
        --align_ref $genomeref \
        --compress_fastq \
        --disable_qscore_filtering
    """
}

