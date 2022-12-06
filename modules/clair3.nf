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

    output:
    path "clair3/*"  // TODO possibly add emitting if will be used for phasing

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