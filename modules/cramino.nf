process cramino {
    label 'cpu_low'
    label 'memory_low'
    label 'time_low'
    label 'cramino'

    publishDir path: "${params.outdir}/${params.sampleid}/cramino/", mode: 'copy'

    input:
    path bam_sorted


    output:
    path "${params.sampleid}_cramino.txt"

    script:
    """" 
    cramino $bam_sorted > ${params.sampleid}_cramino.txt
    """"

}