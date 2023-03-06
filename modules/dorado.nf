/* 
* Basecall reads with dorado
* Note : r9 basecalling is hardcoded due to the bug in this version of dorado (model name mismatch)
*/
process basecall_dorado {
    label 'dorado'

    label ( workflow.profile.contains('slurm') ? 'wice_gpu' : 'with_p100node' ) //if slurm run wice, else P100 NVIDIA

    publishDir path: "${params.outdir}/${params.sampleid}/", mode: 'copy'

    input:
    path reads_pod5
    
    output:
    path "${params.sampleid}_mod_calls.bam", emit: ubam 

    script:
    """
    if [[ ${params.dorado_config} == "dna_r9.4.1_e8_sup@v3.3" ]]; then
        dorado basecaller /opt/dorado/bin/${params.dorado_config} \
        $reads_pod5 --modified-bases-models /opt/dorado/bin/dna_r9.4.1_e8_sup@v3.4_5mCG@v0 | samtools view -Sh > ${params.sampleid}_mod_calls.bam
    else
        dorado basecaller /opt/dorado/bin/${params.dorado_config} \
        $reads_pod5 --modified-bases ${params.mod_bases} | samtools view -Sh > ${params.sampleid}_mod_calls.bam
    fi
    """
}

