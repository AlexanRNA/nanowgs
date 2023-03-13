
/* 
* Process (filter + trim) fastq files with fastp
*/
process parallel_gzip {
    label 'cpu_mid'
    label 'mem_low'
    label 'time_low'
    label 'pigz'
    

    publishDir path: "${params.outdir}/${params.sampleid}/pigz/", mode: 'copy'

    input:
    path fastq

    output:
    path "${params.sampleid}.gz", emit: fastqgz

    script:
    """
    pigz \
        --best \
        --stdout \
        --processes $task.cpus \
        $fastq > ${params.sampleid}.gz
    """
}



/* 
* pigz zipping specifically for the shasta fa output
*/
process parallel_gzip_assembly {
    label 'cpu_mid'
    label 'mem_low'
    label 'time_low'
    label 'pigz'
    

    publishDir path: "${params.outdir}/${params.sampleid}/shasta_assembly/", mode: 'copy'

    input:
    path fastq

    output:
    path "${params.sampleid}.assembly.fa.gz", emit: assembly

    script:
    """
    pigz \
        --best \
        --stdout \
        --processes $task.cpus \
        $fastq > ${params.sampleid}.assembly.fa.gz
    """
}


/* 
* pigz zipping specifically for the shasta gfa output
*/
process parallel_gzip_gfa {
    label 'cpu_mid'
    label 'mem_low'
    label 'time_low'
    label 'pigz'
    

    publishDir path: "${params.outdir}/${params.sampleid}/shasta_assembly/", mode: 'copy'

    input:
    path fastq

    output:
    path "${params.sampleid}.assembly.gfa.gz"

    script:
    // specify if gfa so the file is not overwritten when copied to final directory
    """
    pigz \
        --best \
        --stdout \
        --processes $task.cpus \
        $fastq > ${params.sampleid}.assembly.gfa.gz
    """
}

