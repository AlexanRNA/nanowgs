/* 
* Basecall reads with dorado
* Note : r9 basecalling is hardcoded due to the bug in this version of dorado (model name mismatch)
*/
process modkit_stats {
    label 'modkit'
    label 'cpu_low'
    label 'mem_low'
    label 'time_mid'

    
    publishDir path: "${params.outdir}/${params.sampleid}/modstats/", mode: 'copy'

    input:
    path bam
    
    output:
    path "${params.sampleid}_modstats.txt"

    script:
    """
    modkit summary $bam > ${params.sampleid}_modstats.txt
    """
}

