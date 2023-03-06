process clair3_variant_calling {
    label 'cpu_high'
    label 'memory_mid'
    label 'time_mid'
    label ( workflow.profile.contains('slurm') ? 'wice_bigmem' : 'cpu_high')

    label 'clair3'

    publishDir path: "${params.outdir}/${params.sampleid}/", mode: 'copy'

    input: 
    path bam
    path bam_index
    path genomeref
    path genomeindex

    output:
    path "clair3/*"  
    path "clair3/merge_output.vcf.gz" emit snp_indel
    // path "clair3/ merge_output.vcf.gz.tbi" emit  snp_indel_idx

    script:
    """
    /opt/bin/run_clair3.sh \
    --bam_fn=$bam \
    --ref_fn=$genomeref \
    --threads=$task.cpus \
    --platform="ont" \
    --model_path=${params.clair3_config} \
    --output=clair3
    """

}