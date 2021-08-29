
/* 
* Sam to sorted bam conversion using samtools
*/
process sam_to_sorted_bam {
    label 'process_medium'
    label 'samtools'

    publishDir path: "${params.outdir}/results/bam/", mode: 'copy',
               saveAs: { item -> item.matches("(.*)minimap2(.*)") ? item : null }

    input:
    path mapped_sam
    path genomeref
    val aligner

    output:
    path "*.bam", emit: sorted_bam
    path "*.bai", emit: bam_index
    path "*stats"

    script:
    def samtools_mem = Math.floor(task.memory.getMega() / task.cpus ) as int
    """
    samtools sort -@ $task.cpus \
        --write-index \
        -o ${params.sampleid}_${aligner}.bam##idx##${params.sampleid}_${aligner}.bam.bai \
        -m ${samtools_mem}M \
        --reference $genomeref \
        -T sorttmp_${params.sampleid}_${aligner} \
        $mapped_sam
    samtools flagstat ${params.sampleid}_${aligner}.bam > ${params.sampleid}_${aligner}.bam.flagstats
    samtools idxstats ${params.sampleid}_${aligner}.bam > ${params.sampleid}_${aligner}.bam.idxstats
    samtools stats ${params.sampleid}_${aligner}.bam > ${params.sampleid}_${aligner}.bam.stats
    """

}