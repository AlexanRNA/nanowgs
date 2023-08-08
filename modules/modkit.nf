/* 
* Summary statistics about modification call in the BAM file
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
* Remove 5mC and 5hMC modifications from the BAM file
*/
process modkit_adjustmods_hmC {
    label 'modkit'
    label 'cpu_high'
    label 'mem_high'
    label 'time_mid'

    input:
    path bam


    output:
    path "m6A.bam", emit: out_bam

    script:
    """
    modkit adjust-mods -t $task.cpus --ignore m $bam  | modkit \
    adjust-mods -t $task.cpus --ignore m $bam m6A.bam
    
    """
}


/*
*
* Remove m6A modifications from the BAM file
*/
process modkit_adjustmods_m6A {
    label 'modkit'
    label 'cpu_high'
    label 'mem_high'
    label 'time_mid'

    input:
    path bam


    output:
    path "5hmC.bam", emit: out_bam

    script:
    """
    modkit adjust-mods -t $task.cpus --ignore a  $bam 5hmC.bam
    """
}

/*
*
* Pileup BAM modifications into a bedmethyl file
* 
*/
process modkit_pileup {
    label 'modkit'
    label 'cpu_mid'
    label 'mem_mid'
    label 'time_mid'

    publishDir path: "${params.outdir}/${params.sampleid}/modbed/", mode: 'copy'

    input:
    path bam
    path idx
    //each bed

    output:
    //val bedName
    val bamName
    path "${params.sampleid}_${bamName}.bed", emit: out_bed

    script:
    //bedName = bed.name
    bamName = bam.name
    """
    modkit pileup -t $task.cpus \
    --filter-threshold 0.9 \
    --only-tabs \
    $bam \
    "${params.sampleid}_${bamName}.bed"
    """

}

process overlap {
    label 'bedtools'
    label 'cpu_mid'
    label 'mem_mid'
    label 'time_mid'

    input:
    path modbed
    each bed

   output:
    val bedName
    val modbedName
    path "${params.sampleid}__${bedName}_${modbedName}_intersect.bed", emit: out_bed


    script:
    bedName = bed.name
    modbedName = modbed.name
    """
    bedtools intersect -a $bed -b $modbed -wa -wb \
   > "${params.sampleid}__${bedName}_${modbedName}_intersect.bed"
    """
}


/*
* visualise the bedmethyl files in R
*/
// TODO create docker with bedtools
// TODO files for CTCF and TSS intersect
//process intersect {
//    
//    label 'cpu_mid'
//    label 'mem_mid'/
//    label 'time_mid'
//}

/*
* visualise the bedmethyl file intesected with CTCF and TSS
*/
// TODO create docker with R and dependencies
// TODO add R script to the bin folder
//process visualise_intersect {
//    label 'cpu_low'
//    label 'mem_mid'
////    label 'time_mid'

//}

