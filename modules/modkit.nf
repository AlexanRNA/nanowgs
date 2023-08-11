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
process modkit_adjustmods_5hC {
    label 'modkit'
    label 'cpu_high'
    label 'mem_high'
    label 'time_mid'

    input:
    path bam


    output:
    path "5hC_m6A.bam", emit: out_bam

    script:
    """
    modkit  adjust-mods -t $task.cpus --ignore h $bam 5hC_m6A.bam
    """
}

/*
*
* Remove 5mC and 5hMC modifications from the BAM file
*/
process modkit_adjustmods_5mC {
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
    modkit adjust-mods -t $task.cpus --ignore m $bam m6A.bam
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
    label 'mem_high'
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
    bamName = bam.name.split("\\.")[0]
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
    label 'cpu_high'
    label 'mem_mid'
    label 'time_mid'

    input:
    path modbed
    each bed

   output:
    val bedName
    val modbedName
    path "${params.sampleid}__${bedName}_${modbedName}_intersect.bed", emit: intersect_beds


    script:
    bedName = bed.name.split("\\.")[0]
    modbedName = modbed.name.split("\\.")[0]
    """
    bedtools intersect -a $modbed -b $bed -wa -wb \
   > "${params.sampleid}__${bedName}_${modbedName}_intersect.bed"
    """
}


/*
* visualise the bedmethyl file intesected with CTCF and TSS
*/
process visualise_intersect {

    label 'cpu_mid'
    label 'mem_mid'
    label 'time_mid'
    label 'rgen'

    publishDir path: "${params.outdir}/${params.sampleid}/modbed/", mode: 'copy'

    input:
    each intersect
     
    output:
    path "*pdf"

    script:
    """
    modkit_plot_mod.R $intersect
    """

 }

