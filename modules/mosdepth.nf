/* 
* mosdepth coverage
*/
process mosdepth {
    label 'cpu_low'
    label 'mem_low'
    label 'time_low'
    label 'mosdepth'

    publishDir path: "${params.outdir}/${params.sampleid}/mosdepth/", mode: 'copy'

    input:
    path bam
    path bam_idx
    

    output:
    path "*txt"
    path "${params.sampleid}.mosdepth.global.dist.txt", emit: coverage_txt 

    // shouldn't use more than 4 threads according to docs
    script:
    """
    mosdepth -t 4 -n --fast-mode ${params.sampleid} $bam
    """
}

process mosdepth_plot {
    label 'cpu_low'
    label 'mem_low'
    label 'time_low'
    label 'python' // just a container with python environment

    publishDir path: "${params.outdir}/${params.sampleid}/mosdepth/", mode: 'copy'

    input:
    path coverage_txt
    

    output:
    path "*html"

   
    script:
    """
    plot-dist.py $coverage_txt
    """
}