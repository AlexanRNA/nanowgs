// 
/* 
* convert fast5 files to pod5
*/

process fast5_2pod5 {
    label 'cpu_high'
    label 'mem_mid'
    label 'time_mid'
    label 'pod5'

    //publishDir path: "${params.outdir}/${params.sampleid}/", mode: 'copy'

    input:
    path ont_base
    
    output:
    path "./pod5/", emit: reads_pod5 // emit path only, since dorado does not accept file, only dir
    

    script:
    """
    pod5 convert fast5 -r -t $task.cpus $ont_base \
    -o ./pod5/${params.sampleid}.pod5
    """
}