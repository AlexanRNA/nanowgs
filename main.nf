#!/usr/bin/env nextflow
/*
====================================
            N A N O W G S
====================================
 nanowgs Analysis Pipeline.
 https://github.com/jdemeul/nanowgs
------------------------------------
*/

nextflow.enable.dsl=2


// Command line shortcuts, quick entry point:

/* 
* Guppy basecalling
*/
workflow guppy_basecalling {

    include { basecall_reads } from './modules/guppy'

    genomeref = Channel.fromPath( params.genomeref + "/fasta/genome.fa", checkIfExists: true  )
    genomeindex = Channel.fromPath( params.genomeref + "/indexes/minimap2-ont/genome.mmi" )

    basecall_reads( Channel.fromPath( params.ont_base_dir ), genomeref, genomeindex )

}


/* 
* Sam to sorted bam conversion and indexing
*/
workflow sam_to_sorted_bam {

    include { sam_to_sorted_bam } from './modules/samtools'

    genomeref = Channel.fromPath( params.genomeref + "/fasta/genome.fa", checkIfExists: true )

    sam_to_sorted_bam( Channel.fromPath( params.mapped_sam ), genomeref )

}


/* 
* Call structural variation and generate consensus
*/
workflow call_svs {

    include { sniffles_sv_calling } from './modules/sniffles'
    include { svim_sv_calling } from './modules/svim'
    include { cutesv_sv_calling } from './modules/cutesv'
    include { svim_sv_filtering } from './modules/bcftools'
    include { survivor_sv_consensus } from './modules/survivor'

    genomeref = Channel.fromPath( params.genomeref + "/fasta/genome.fa", checkIfExists: true  )
    genomeindex = Channel.fromPath( params.genomeref + "/indexes/minimap2-ont/genome.mmi" )
    aligned_reads = Channel.fromPath( params.aligned_bam )
    aligned_reads_idx = Channel.fromPath( params.aligned_bam + ".bai" )
    
    cutesv_sv_calling( aligned_reads, aligned_reads_idx, genomeref, genomeindex )
    sniffles_sv_calling( aligned_reads, aligned_reads_idx )
    svim_sv_calling( aligned_reads, aligned_reads_idx, genomeref, genomeindex )
    svim_sv_filtering( svim_sv_calling.out.sv_calls )

    allsvs = cutesv_sv_calling.out.sv_calls
                .mix( sniffles_sv_calling.out.sv_calls, svim_sv_filtering.out.sv_calls_q10 )
                .collect()
    survivor_sv_consensus( allsvs )

    
}

/* 
* Call small variants using ONT Medaka
*/
workflow medaka_variant_calling {

    include { medaka_snv_calling } from './modules/medaka'

    genomeref = Channel.fromPath( params.genomeref + "/fasta/genome.fa", checkIfExists: true  )
    genomeindex = Channel.fromPath( params.genomeref + "/indexes/minimap2-ont/genome.mmi" )
    aligned_reads = Channel.fromPath( params.aligned_bam )
    aligned_reads_idx = Channel.fromPath( params.aligned_bam + ".bai" )

    medaka_snv_calling( aligned_reads, aligned_reads_idx, genomeref, genomeindex )

}


/* 
* Call small variants using PEPPER-Margin-DeepVariant
*/
workflow pepper_deepvariant_calling {

    include { deepvariant_snv_calling } from './modules/deepvariant'

    genomeref = Channel.fromPath( params.genomeref + "/fasta/genome.fa", checkIfExists: true  )
    genomeindex = Channel.fromPath( params.genomeref + "/indexes/minimap2-ont/genome.mmi" )
    aligned_reads = Channel.fromPath( params.aligned_bam )
    aligned_reads_idx = Channel.fromPath( params.aligned_bam + ".bai" )

    deepvariant_snv_calling( aligned_reads, aligned_reads_idx, genomeref, genomeindex )

}


/* 
* Run a de novo genome assembly using Shasta
*/
workflow shasta_assembly {

    include { run_shasta_assembly } from './modules/shasta'

    fastq = Channel.fromPath( params.processed_reads )
    config = Channel.fromPath( params.shasta_config )

    run_shasta_assembly( fastq, config )

}



// Proper workflows
workflow process_reads {
    take:
        genomeref
        ont_base

    main:
    
        include { create_minimap_index } from './modules/minimap2'
        include { basecall_reads } from './modules/guppy'
        include { filter_reads } from './modules/fastp'

        if ( params.rebasecall ) {

            if ( !file( params.genomeref + "/indexes/minimap2-ont/genome.mmi" ).exists() ) {
                create_minimap_index( genomeref )
                genomeindex = create_minimap_index.out.mmi
            } else {
                genomeindex = Channel.fromPath( params.genomeref + "/indexes/minimap2-ont/genome.mmi" )
            }

            basecall_reads( Channel.fromPath( params.ont_base_dir ), genomeref, genomeindex )
            filter_reads( basecall_reads.out.fastqs.collect() )
        } else {
            filter_reads( Channel.fromPath( params.ont_base_dir + "**.fastq.gz" ).collect() )
        }

    emit:
        fastq_trimmed = filter_reads.out.fastq_trimmed

}


workflow minimap_alignment {
    take: 
        fastqs
        genomeref

    main:
        include { create_lra_index; lra_alignment } from './modules/minimap2'
        include { sam_to_sorted_bam } from './modules/samtools'
        
        // genome indexing
        if ( !file( params.genomeref + "/indexes/minimap2-ont/genome.mmi" ).exists() ) {
            create_minimap_index( genomeref )
            genomeindex = create_minimap_index.out.mmi
        } else {
            genomeindex = Channel.fromPath( params.genomeref + "/indexes/minimap2-ont/genome.mmi" )
        }

        // alignment and covnersion into indexed sorted bam
        minimap_alignment( genomeref, genomeindex, fastqs )
        sam_to_sorted_bam( minimap_alignment.out.mapped_sam, genomeref, minimap_alignment.out.aligner )

    emit:
        sorted_bam = sam_to_sorted_bam.out.sorted_bam
        bam_index = sam_to_sorted_bam.out.bam_index

}


workflow lra_alignment_sv_calling {
    take: 
        fastqs
        genomeref

    main:
        include { create_lra_index; lra_alignment } from './modules/lra'
        include { sam_to_sorted_bam } from './modules/samtools'
        include { cutesv_sv_calling } from './modules/cutesv'

        // genome indexing
        if ( !file( params.genomeref + "/indexes/lra-ont/genome.fa.gli" ).exists() || !file( params.genomeref + "/indexes/lra-ont/genome.fa.mmi" ).exists() ) {
            create_lra_index( genomeref )
            genomeindex_gli = create_lra_index.out.gli
            genomeindex_mmi = create_lra_index.out.mmi
        } else {
            genomeindex_gli = Channel.fromPath( params.genomeref + "/indexes/lra-ont/genome.fa.gli" )
            genomeindex_mmi = Channel.fromPath( params.genomeref + "/indexes/lra-ont/genome.fa.mmi" )
        }

        // alignment and conversion into indexed sorted bam
        lra_alignment( genomeref, fastqs, genomeindex_gli, genomeindex_mmi )
        sam_to_sorted_bam( lra_alignment.out.mapped_sam, genomeref, lra_alignment.out.aligner )

        // SV calling using cuteSV
        cutesv_sv_calling( sam_to_sorted_bam.out.sorted_bam, sam_to_sorted_bam.out.bam_index, genomeref )

}






workflow {

    genomeref = Channel.fromPath( params.genomeref + "/fasta/genome.fa", checkIfExists: true  )
    genomeindex = Channel.fromPath( params.genomeref + "/indexes/minimap2-ont/genome.mmi" )
    // ont_base = Channel.fromPath( params.ont_base_dir, checkIfExists: true )
    reads = Channel.fromPath( params.processed_reads, checkIfExists: true )

    // alignment and covnersion into indexed sorted bam
    minimap_alignment( genomeref, genomeindex, reads )
    sam_to_sorted_bam( minimap_alignment.out.mapped_sam, genomeref, minimap_alignment.out.aligner )
    sv_calling( sam_to_sorted_bam.out.sorted_bam, sam_to_sorted_bam.out.bam_index, genomeref )

    // process_reads( genomeref, ont_base )
    // lra_alignment_sv_calling( process_reads.out.fastq_trimmed, genomeref )
    // minimap_alignment_snv_calling( process_reads.out.fastq_trimmed, genomeref )

}

// -m ${Math.floor( $task.memory / $task.cpus ) }
// ch_reference_fasta.view()
// ch_reference_index.view()