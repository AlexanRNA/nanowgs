
/* 
* SNV and indel calling on aligned reads using PEPPER-Margin-DeepVariant
*/
process deepvariant_snv_calling {
    // label 'process_high'
    label 'deepvariant'
    // memory requirements are forcing this to be run on a bigmem node / superdome
    label ( params.deepvariant_with_gpu ? 'with_gpus': 'bigmemnode' )
    label ( workflow.profile.contains('qsub') ? null: 'cpu_high' )
    // label ( params.with_gpu ? null: 'mem_high' )
    // label ( params.with_gpu ? null: 'time_high' )

    container ( params.deepvariant_with_gpu ? 'kishwars/pepper_deepvariant:r0.8-gpu': 'kishwars/pepper_deepvariant:r0.8' )

    stageInMode 'copy'

    publishDir path: "${params.outdir}/${params.sampleid}/${task.process}/", mode: 'copy'

    input:
    path sorted_bam
    path bam_index
    path genomeref
    // val step
    // path genomerefidx

    output:
    path "deepvar_out/*.vcf.gz", emit: indel_snv_vcf
    path "deepvar_out/*.vcf.gz.tbi", emit: indel_snv_vcf_index
    path "deepvar_out/*visual_report.html", emit: indel_snv_vcf_html  
    // path "deepvar_out/intermediate_files"
    // path "deepvar_out/*.haplotagged.bam", emit: haplotagged_bam
    // path "deepvar_out/*.haplotagged.bam.bai", emit: haplotagged_bam_idx
    // path "deepvar_out/*stats"

    script:
    def localproc = ( workflow.profile.contains('qsub') ? 36: task.cpus )
    if ( params.deepvariant_with_gpu ) 
        """
        # export CUDA_VISIBLE_DEVICES=${params.gpu_devices}
        run_pepper_margin_deepvariant call_variant \
            -b $sorted_bam \
            -f $genomeref \
            -o . \
            -p ${params.sampleid} \
            -s ${params.sampleid} \
            -t 16 \
            --ont_r9_guppy5_sup \
            -g
        #    --phased_output
        #    -t $task.cpus \ number of CPUs on GPU node is fixed
        """
    else 
        """
        run_pepper_margin_deepvariant call_variant \
            -b $sorted_bam \
            -f $genomeref \
            -o deepvar_out \
            -p ${params.sampleid} \
            -s ${params.sampleid} \
            -t ${localproc} \
            --ont_r9_guppy5_sup
        #    --phased_output
        # samtools index -b -@ 18 ./deepvar_out/${params.sampleid}.haplotagged.bam ./deepvar_out/${params.sampleid}.haplotagged.bam.bai
        # samtools flagstat ./deepvar_out/${params.sampleid}.haplotagged.bam > ./deepvar_out/${params.sampleid}.haplotagged.bam.flagstats
        # samtools idxstats ./deepvar_out/${params.sampleid}.haplotagged.bam > ./deepvar_out/${params.sampleid}.haplotagged.bam.idxstats
        # samtools stats ${params.sampleid}_sorted.bam > ${params.sampleid}_sorted.bam.stats
        """
}

/* 
* SNV and indel calling on aligned reads using PEPPER-Margin-DeepVariant on slurm
*/
process deepvariant_snv_calling_slurm {
    // label 'process_high'
    label 'deepvariant'
    // memory requirements are forcing this to be run on a bigmem node / superdome
    // label ( params.deepvariant_with_gpu ? 'with_gpus': 'bigmemnode' )
    // label ( workflow.profile.contains('qsub') ? null: 'cpu_high' )
    label ( workflow.profile.contains('slurm') ? 'wice_gpu': 'cpu_high' ) // ifelse  for slurm/qsub 
    // label ( params.with_gpu ? null: 'mem_high' )
    // label ( params.with_gpu ? null: 'time_high' )

    container ( params.deepvariant_with_gpu ? 'kishwars/pepper_deepvariant:r0.8-gpu': 'kishwars/pepper_deepvariant:r0.8' )

    stageInMode 'copy'

    publishDir path: "${params.outdir}/${params.sampleid}/deepvar_out", mode: 'copy'

    input:
    path sorted_bam
    path bam_index
    path genomeref
    // val step
    // path genomerefidx

    output:
    path "*.vcf.gz", emit: indel_snv_vcf
    path "*.vcf.gz.tbi", emit: indel_snv_vcf_index
    path "*visual_report.html", emit: indel_snv_vcf_html  // TODO test
    // path "deepvar_out/intermediate_files"
    // path "deepvar_out/*.haplotagged.bam", emit: haplotagged_bam
    // path "deepvar_out/*.haplotagged.bam.bai", emit: haplotagged_bam_idx
    // path "deepvar_out/*stats"

    script:
    //def localproc = ( workflow.profile.contains('slurm') ? 36: task.cpus )
    if ( params.deepvariant_with_gpu ) 
        """
        # export CUDA_VISIBLE_DEVICES=${params.gpu_devices}
        run_pepper_margin_deepvariant call_variant \
            -b $sorted_bam \
            -f $genomeref \
            -o . \
            -p ${params.sampleid} \
            -s ${params.sampleid} \
            -t 16 \
            --ont_r9_guppy5_sup \
            -g
        #    --phased_output
        """
    else 
        """
        run_pepper_margin_deepvariant call_variant \
            -b $sorted_bam \
            -f $genomeref \
            -o . \
            -p ${params.sampleid} \
            -s ${params.sampleid} \
            -t $task.cpus \
            --ont_r9_guppy5_sup
        """
}


/* 
* SNV and indel calling on aligned reads using PEPPER-Margin-DeepVariant
*/
process deepvariant_snv_calling_gpu_parallel {
    // label 'process_high'
    label 'deepvariant'
    label 'with_p100'

    container 'kishwars/pepper_deepvariant:r0.8-gpu'

    input:
    path sorted_bam
    path bam_index
    path genomeref
    each region

    output:
    path "*phased.vcf.gz", emit: indel_snv_vcf
    // path "*phased.vcf.gz.tbi", emit: indel_snv_vcf_index

    script:
    """
    run_pepper_margin_deepvariant call_variant \
        -b $sorted_bam \
        -f $genomeref \
        -o . \
        -p ${params.sampleid}_${region}_ \
        -s ${params.sampleid} \
        --ont_r9_guppy5_sup \
        -t 9 \
        -g \
        --phased_output \
        --region $region
    samtools index -b -@ 9 *.haplotagged.bam
    """
}


// /* 
// * Assembly polishing using PEPPER
// * NOT IMPLEMENTED YET
// */
// process pepper_assembly_polishing {
//     label 'pepper'
//     label ( params.with_gpu ? 'with_gpu': 'cpu_high')
//     label ( params.with_gpu ? null: 'mem_high')
//     label ( params.with_gpu ? null: 'time_mid')

//     publishDir path: "${params.outdir}/${params.sampleid}/${task.process}/", mode: 'copy'

//     input:
//     path sorted_bam
//     path bam_index
//     path assemblyref

//     output:
//     path "*.vcf.gz", emit: indel_snv_vcf

//     script:
//     """
//     run_pepper_margin_deepvariant polish_assembly \
//         -b $sorted_bam \
//         -f $assemblyref \
//         -o . \
//         -t $task.cpus \
//         -p ${params.sampleid} \
//         -g \
//         --ont
//     """
// }


// singularity run --nv -B /staging/leuven/stg_00002/lcb/ \
//     -B /scratch/ \
//     -B /local_scratch/ \
//     /staging/leuven/stg_00002/lcb/jdemeul/software/singularity_images/kishwars-pepper_deepvariant-r0.4.img \
//     run_pepper_margin_deepvariant polish_assembly \
//     -b /staging/leuven/stg_00002/lcb/jdemeul/projects/2021_ASAP/results/ASA_Edin_BA24_38_17/results/fastq/ShastaRun/PEPPER-Polishing/ASA_Edin_BA24_38_17_TrimmedReads_ShastaAssembly.aln.bam \
//     -f /staging/leuven/stg_00002/lcb/jdemeul/projects/2021_ASAP/results/ASA_Edin_BA24_38_17/results/fastq/ShastaRun/Assembly.fasta \
//     -o /staging/leuven/stg_00002/lcb/jdemeul/projects/2021_ASAP/results/ASA_Edin_BA24_38_17/results/fastq/ShastaRun/PEPPER-Polishing/out \
//     -t 16 \
//     -p ASA_Edin_BA24_38_17 \
//     -g \
//     --ont

//     # this generates 2 VCFs, one per haplotype
//     HAP1_VCF=PEPPER_MARGIN_DEEPVARIANT_ASM_POLISHED_HAP1.vcf.gz
//     HAP2_VCF=PEPPER_MARGIN_DEEPVARIANT_ASM_POLISHED_HAP2.vcf.gz

//     POLISHED_ASM_HAP1=HG002_Shasta_run1.PMDV.HAP1.fasta
//     POLISHED_ASM_HAP2=HG002_Shasta_run1.PMDV.HAP2.fasta

//     # Apply the VCF to the assembly
//     singularity exec --bind /usr/lib/locale/ \
//     pepper_deepvariant_r0.4.sif \
//     bcftools consensus \
//     -f "${INPUT_DIR}/${ASM}" \
//     -H 2 \
//     -s "${SAMPLE_NAME}" \
//     -o "${OUTPUT_DIR}/${POLISHED_ASM_HAP1}" \
//     "${OUTPUT_DIR}/${HAP1_VCF}"

//     singularity exec --bind /usr/lib/locale/ \
//     pepper_deepvariant_r0.4.sif \
//     bcftools consensus \
//     -f "${INPUT_DIR}/${ASM}" \
//     -H 2 \
//     -s "${SAMPLE_NAME}" \
//     -o "${OUTPUT_DIR}/${POLISHED_ASM_HAP2}" \
//     "${OUTPUT_DIR}/${HAP2_VCF}"
//     """
