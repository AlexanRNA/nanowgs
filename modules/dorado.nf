/* 
* Basecall reads with dorado
* 
*/
process basecall_dorado {
    label 'dorado'

    label ( workflow.profile.contains('slurm') ? 'wice_gpu' : 'with_p100node' ) //if slurm run wice, else P100 NVIDIA

    publishDir path: "${params.sampleid}/", mode: 'copy'

    input:
    path reads_pod5
    
    output:
    path "${params.sampleid}_mod_calls.bam", emit: ubam 

    script:
    """
    dorado basecaller /opt/dorado/bin/${params.dorado_config} \
    $reads_pod5 --modified-bases ${params.mod_bases} | samtools view -Sh > ${params.sampleid}_mod_calls.bam
    """
}


