
/* 
* Joint phasing of SNVs and SVs using longphase
*/
process longphase_phase {
    label 'cpu_mid'
    label 'mem_mid'
    label 'time_low'
    label 'longphase'

    // publishDir path: "${params.outdir}/${params.sampleid}/longphase_phase/", mode: 'copy'

    input:
    path reference
    path snv_indel
    path svs
    path bam
    path bamidx

    output:
    path "${params.sampleid}_longphase.vcf", emit: snv_indel_phased
    path "${params.sampleid}_longphase_SV.vcf", emit: sv_phased

    script:
    """
    longphase phase \
        --ont \
        -t $task.cpus \
        -s $snv_indel \
        --sv-file $svs \
        -r $reference \
        -b $bam \
        --indels \
        -o ${params.sampleid}_longphase
    """

}





/* 
* Longphase haplotagging of a bam file
*/
process longphase_tag {
    label 'cpu_mid'
    label 'mem_mid'
    label 'time_low'
    label 'longphase'

    // 20240912 - no cpying of longphase output
    // publishDir path: "${params.outdir}/${params.sampleid}/longphase_tag/", mode: 'copy'

    input:
    path snv_indel
    path svs
    path bam
    path bamidx
    path reference

    output:
    path "${params.sampleid}_haplotagged.bam", emit: haplotagged_bam
    path hap1ids, emit: hap1ids
    path hap2ids, emit: hap2ids

    shell:
    '''
    longphase haplotag \
        -b !{bam} \
        -t !{task.cpus} \
        -s !{snv_indel} \
        --sv-file !{svs} \
        -r !{reference} \
        --log \
        -o !{params.sampleid}_haplotagged
    
    # generate haplotype files
    grep -v "#" !{params.sampleid}_haplotagged.out | cut -f1,5 | awk '{ $0 = gensub(/\\./, int(rand()*2), "g", $0) }1' > "haplotagged_all.out"
    grep "1$" haplotagged_all.out | cut -f1 > hap1ids
    grep "2$" haplotagged_all.out | cut -f1 > hap2ids
    '''
}

/*
* zipping and indexing Longphase VCF output
*/
process longphase_zip_index {
    label 'cpu_low'
    label 'mem_low'
    label 'time_low'
    label 'bcftools'

    publishDir path: "${params.outdir}/${params.sampleid}/longphase_phase/", mode: 'copy'

    input:
    path snv_indels
    path svs

    output:
    path "${params.sampleid}_longphase.vcf.gz"
    path "${params.sampleid}_longphase.vcf.gz.csi"
    path "${params.sampleid}_longphase_SV.vcf.gz"
    path "${params.sampleid}_longphase_SV.vcf.gz.csi"

    script:
    """
    bgzip $snv_indels
    bgzip $svs
    bcftools index ${snv_indels}.gz
    bcftools index ${svs}.gz
    
    """


}
