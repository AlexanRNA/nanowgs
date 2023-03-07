/*
* for quick visual QC of aligned bam
*/
process kyber {
    label 'cpu_low'
    label 'memory_low'
    label 'time_low'
    label 'kyber'

    publishDir path: "${params.outdir}/${params.sampleid}/kyber/", mode: 'copy'

    input:
    path bam_sorted


    output:
    path "${params.sampleid}_accuracy_heatmap.png"

    script:
    """
    kyber -p -c purple -o ${params.sampleid}_accuracy_heatmap.png $bam_sorted 
    """

}