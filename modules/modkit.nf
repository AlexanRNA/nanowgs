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
    modkit summary -t $task.cpus --tsv --only-mapped $bam > ${params.sampleid}_modstats.txt
    """
}

/*
*
* Pileup BAM modifications into a bedmethyl file
* Separate files for each modification type
* // TODO add CTCF and TSS bed files --> cn directly subset bed here
* // TODO make it possible ot run parallel for CTCF and TSS
*/
process modkit_pileup {
    label 'modkit'
    label 'cpu_mid'
    label 'mem_mid'
    label 'time_mid'

    input:
    path bam
    path bed

    output:
    emit bed5mC
    emit bed6mA

    script:
    """
    modkit pileup -t $task.cpus --seed 7 \
    --include-bed $bed \
    $bam 
    """
}


/*
* visualise the bedmethyl files in R
*/
// TODO create docker with bedtools
// TODO files for CTCF and TSS intersect
process intersect {
    
    label 'cpu_mid'
    label 'mem_mid'
    label 'time_mid'
}

/*
* visualise the bedmethyl file intesected with CTCF and TSS
*/
// TODO create docker with R and dependencies
// TODO add R script to the bin folder
process visualise_intersect {
    label 'cpu_low'
    label 'mem_mid'
    label 'time_mid'

}

