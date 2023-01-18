// TODO properly change scrip, add label pod5 to config and update pod5 to v0.1.0
/* 
* convert fast5 files to pod5
*/

process fast5_2pod5 {
    label 'cpu_high'
    label 'mem_high'
    label 'time_mid'
    label 'pod5'

    publishDir path: "${params.outdir}/${params.sampleid}/", mode: 'copy'

    input:
    path ont_base
    
    output:
    path "/pod5/*", emit: reads_pod5
    

    script:
    """
   pod5-convert-from-fast5 -r --active-readers 36 /staging/leuven/stg_00002/lcb/gc_test/20221017_MM001_Hia5/ \
   /staging/leuven/stg_00096/home/apancik/projects/2021_Ibrahim/data/pod5/20221017_MM001_Hia5
    """
}