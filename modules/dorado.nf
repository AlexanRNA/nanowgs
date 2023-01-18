/* 
* Basecall reads with ONT Guppy
* TODO: implement guppy methyaltion directly if no m6A methylation - create new process maybe?
*/
process basecall_reads {
    label 'dorado'

    label ( workflow.profile.contains('slurm') ? 'wice_gpu' : 'with_p100node' ) //if slurm run wice, else P100 NVIDIA

    publishDir path: "${params.outdir}/${params.sampleid}/", mode: 'copy'

    input:
    path ont_base
    
    output:
    path "minimap2_alignemnt/*fastq.gz", emit: fastqs
    path "basecalls/sequencing_summary.txt", emit: seq_summary 

    script:
    """
    
    """
}