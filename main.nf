#!/usr/bin/env nextflow
/*
====================================
            N A N O W G S
====================================
 nanowgs Analysis Pipeline.
https://github.com/AlexanRNA/nanowgs
------------------------------------
*/

nextflow.enable.dsl=2

log.info """\
      LIST OF PARAMETERS
================================
            GENERAL
Results-folder   : $params.outdir
Sample ID:       : $params.sampleid
================================
      INPUT & REFERENCES 
Input-files      : $params.ont_base_dir
Reference genome : $params.genomeref 
================================

"""


// Command line shortcuts, quick entry point:

include { basecall_reads as basecall } from './modules/guppy'
include { filter_reads as filter } from './modules/fastp'
include { parallel_gzip as pigz; parallel_gzip_assembly; parallel_gzip_gfa } from './modules/pigz'

include { minimap_alignment as minimap } from './modules/minimap2'
include { sam_to_sorted_bam as samtobam; bam_to_sorted_bam as bamtobam1; bam_to_sorted_bam as bamtobam2; get_haplotype_readids; index_bam ; ubam2fastq ; sam_to_sorted_bam_qscore } from './modules/samtools'

include { sniffles_sv_calling as sniffles } from './modules/sniffles'
include { svim_sv_calling as svim } from './modules/svim'
include { cutesv_sv_calling as cutesv } from './modules/cutesv'
include { dysgu_sv_calling as dysgu } from './modules/dysgu'
include { svim_sv_filtering as filtersvim; sniffles_sv_filtering as filtersniffles; variant_filtering as filter_snp_indel } from './modules/bcftools'
include { vcf_concat; vcf_concat_sv_snv as merge_sv_snv } from './modules/bcftools'

include { longphase_phase; longphase_tag } from './modules/longphase'
include { seqtk } from './modules/seqtk'

include { survivor_sv_consensus as survivor } from './modules/survivor'

include { megalodon; megalodon_aggregate } from './modules/megalodon'

include { medaka_snv_calling as medaka_snv } from './modules/medaka'
include { deepvariant_snv_calling_slurm  as deepvariant } from './modules/deepvariant'
// include { deepvariant_snv_calling_gpu_parallel as deepvariant_par } from './modules/deepvariant'

include { run_shasta_assembly as shasta } from './modules/shasta'
include { racon_assembly_polishing as racon } from './modules/racon'
include { medaka_assembly_polishing as medaka_polish } from './modules/medaka'
include { medaka_assembly_polish_align; medaka_assembly_polish_stitch; medaka_assembly_polish_consensus } from './modules/medaka'

include { hapdup; hapdup_with_haptagged_bam as hapduptagged; haptagtransfer } from './modules/hapdup'
include { flye_polishing as flye_hap1; flye_polishing as flye_hap2 } from './modules/flye'

include { dipdiff } from './modules/dipdiff'
include { dipdiff as dipdiff_reference } from './modules/dipdiff'

include { create_personal_genome as crossstitch; prepare_svs_stitch } from './modules/crossstitch'

include { run_quast as quast_hap1; run_quast as quast_hap2; run_quast as quast_hap1_ref; run_quast as quast_hap2_ref } from './modules/quast'
include { run_mummer as mummer_hap1; run_mummer as mummer_hap2; run_mummer as mummer_hap1_ref; run_mummer as mummer_hap2_ref } from './modules/mummer'

include { run_pycoqc } from './modules/pycoqc'
include { clair3_variant_calling } from './modules/clair3'
include { fast5_2pod5 } from './modules/pod5'
include { basecall_dorado } from './modules/dorado'
include { cramino } from './modules/cramino'
include { kyber } from './modules/kyber'
include { mosdepth; mosdepth_plot} from './modules/mosdepth'
include { extract_SV_lengths; plot_SV_lengths } from './modules/r-visualisation'
include { modkit_stats; modkit_adjustmods_5mC; modkit_adjustmods_5hC; modkit_adjustmods_m6A; modkit_pileup; modkit_pileup as modkit_pileup2; remove_a; overlap as overlap1; overlap as overlap2; visualise_intersect; visualise_intersect as visualise_intersect2 } from './modules/modkit'


/*
* Dorado basecalling
* Allows to basecall directly from fast5 or pod5
* The output is a bam file
*/
workflow dorado_call {
    // use the below line only if skip is still present 
    // ont_basedir = Channel.fromPath( "${params.ont_base_dir + '/*{fast5_pass,fast5_fail}'}" , checkIfExists: true, type: 'dir' ).collect()
    
    // use parameter fast5 to check if the data are in fast5 or pod5
    if ( params.fast5 ){
        // convert fast5 to pod5 
        ont_basedir = Channel.fromPath( params.ont_base_dir, checkIfExists: true )
        fast5_2pod5(ont_basedir)
        basecall_dorado( fast5_2pod5.out.reads_pod5 )
    } else {
        // if pod5 format, go directly to basecalling
        ont_basedir = Channel.fromPath( params.ont_base_dir, checkIfExists: true )
        basecall_dorado( ont_basedir )
    }
    
   
    
}

/**
* Slurm pipeline using dorado output
* 
*/
workflow slurm_dorado {

    genomeref = Channel.fromPath( params.genomeref, checkIfExists: true  )
    genomerefidx = Channel.fromPath( params.genomerefindex, checkIfExists: true  )
   
    //alignment
    // todo decouple ubam to fastq from the rest, so I can feed fastq to shasta
    // ubam_to_bam(Channel.fromPath( params.ubam , checkIfExists: true ), genomeref)
    // index_bam(ubam_to_bam.out.mapped_bam)

    // ubam to fastq
    ubam2fastq( Channel.fromPath( params.ubam , checkIfExists: true ))


    // mapping and sam to bam
    minimap_align_bamout_qscore( genomeref,  ubam2fastq.out.fastq.collect() )

    // cramino and kyber for quick QC
    kyber ( minimap_align_bamout_qscore.out.bam )
    cramino ( minimap_align_bamout_qscore.out.bam )
    mosdepth (minimap_align_bamout_qscore.out.bam, minimap_align_bamout_qscore.out.idx )
    mosdepth_plot ( mosdepth.out.coverage_txt )

    //TODO test 
    // modified bases QC
    if ( params.mod_bases != "") {
        modkit_stats ( minimap_align_bamout_qscore.out.bam )
        modkit_adjustmods_5hC ( minimap_align_bamout_qscore.out.bam )
        modkit_adjustmods_5mC ( modkit_adjustmods_5hC.out.out_bam )
        modkit_adjustmods_m6A ( minimap_align_bamout_qscore.out.bam  )

        // sort andd index modbams
        bamtobam1 ( modkit_adjustmods_5mC.out.out_bam, genomeref )
        bamtobam2 ( modkit_adjustmods_m6A.out.out_bam, genomeref )
    
        // check if input files exist
        beds = Channel.fromPath( [params.tss_bed, params.ctcf_bed], checkIfExists: true  ).flatten()
    
        beds.view()
        modkit_pileup ( bamtobam1.out.sorted_bam, bamtobam1.out.bam_index )
        modkit_pileup2 ( bamtobam2.out.sorted_bam, bamtobam2.out.bam_index )

        // remove "a" rows from modkit pileup
        remove_a ( modkit_pileup2.out.out_bed )

        // bedtools intersect
        overlap1 ( modkit_pileup.out.out_bed, beds )
        overlap2 ( remove_a.out.out_bed, beds )


        // visualise intersect
        visualise_intersect ( overlap1.out.intersect_beds ) 
        visualise_intersect2 ( overlap2.out.intersect_beds )
    
    }
    
 

    // variant calling from alignment
        
    clair3_variant_calling(minimap_align_bamout_qscore.out.bam, minimap_align_bamout_qscore.out.idx, genomeref, genomerefidx)
    filter_snp_indel( clair3_variant_calling.out.snp_indel )
    
    sniffles( minimap_align_bamout_qscore.out.bam, minimap_align_bamout_qscore.out.idx, genomeref )
    filtersniffles( sniffles.out.sv_calls )
    
    // SV size visualisation
    extract_SV_lengths( filtersniffles.out.variants_pass )
    plot_SV_lengths( extract_SV_lengths.out.dels, extract_SV_lengths.out.ins)


    // longphase
    // phasing
    longphase_phase( genomeref, filter_snp_indel.out.variants_pass, filtersniffles.out.variants_pass, minimap_align_bamout_qscore.out.bam, minimap_align_bamout_qscore.out.idx )
    longphase_tag( longphase_phase.out.snv_indel_phased, longphase_phase.out.sv_phased, minimap_align_bamout_qscore.out.bam, minimap_align_bamout_qscore.out.idx )

     // crossstitch
    crossstitch( longphase_phase.out.snv_indel_phased, longphase_phase.out.sv_phased, minimap_align_bamout_qscore.out.bam, genomeref, params.karyotype )

    // TODO
    // add annotation dfam R script


    // de novo assembly 
    // TODO test both trimmed and untrimmed + below code
    filter( ubam2fastq.out.fastq.collect() )
    shasta( filter.out.fastq_trimmed )
    parallel_gzip_assembly ( shasta.out.assembly )
    parallel_gzip_gfa ( shasta.out.assembly_gfa )

    // hapdup 
    // use reference-based haplotype tags to assure assembly-based haplotypes match reference-based ones
    // TODO test if it works with zipped fasta assembly
    // haptagtransfer( longphase_tag.out.haplotagged_bam, parallel_gzip_assembly.out.assembly )
    // hapduptagged( haptagtransfer.out.retagged_bam, haptagtransfer.out.retagged_bamindex, parallel_gzip_assembly.out.assembly )

}

/*
* Building slurm pipeline with guppy basecalling included
*
*/
workflow slurm_guppy {
    // guppy basecalling
    genomeref = Channel.fromPath( params.genomeref, checkIfExists: true  )
    genomerefidx = Channel.fromPath( params.genomerefindex, checkIfExists: true  )
    basecall( Channel.fromPath( params.ont_base_dir ), genomeref )


    // filtering and trimming
    filter( basecall.out.fastqs.collect() )
    pigz( filter.out.fastq_trimmed )

    // alignment
    minimap_align_bamout( genomeref, pigz.out.fastqgz )
    

    // variant calling from alignment
    deepvariant( minimap_align_bamout.out.bam, minimap_align_bamout.out.idx, genomeref )
    filter_snp_indel( deepvariant.out.indel_snv_vcf )

    clair3_variant_calling(minimap_align_bamout.out.bam, minimap_align_bamout.out.idx, genomeref, genomerefidx)
    
    sniffles( minimap_align_bamout.out.bam, minimap_align_bamout.out.idx, genomeref )
    filtersniffles( sniffles.out.sv_calls )

    // shasta assembly
    shasta( pigz.out.fastqgz  )

    // QC
    run_pycoqc ( basecall.out.seq_summary, minimap_align_bamout.out.bam, minimap_align_bamout.out.idx )
    
    // phasing
    longphase_phase( genomeref, filter_snp_indel.out.variants_pass, filtersniffles.out.variants_pass, minimap_align_bamout.out.bam, minimap_align_bamout.out.idx )
    longphase_tag( longphase_phase.out.snv_indel_phased, longphase_phase.out.sv_phased, minimap_align_bamout.out.bam, minimap_align_bamout.out.idx )

    crossstitch( longphase_phase.out.snv_indel_phased, filtersniffles.out.variants_pass, minimap_align_bamout.out.bam, genomeref, params.karyotype )

    // use reference-based haplotype tags to assure assembly-based haplotypes match reference-based ones
    haptagtransfer( longphase_tag.out.haplotagged_bam, shasta.out.assembly )
    hapduptagged( haptagtransfer.out.retagged_bam, haptagtransfer.out.retagged_bamindex, shasta.out.assembly )

    
}

/*
* Fastq to SV/SNP call
* 
*/
workflow fastq_process {
    // genome
    genomeref = Channel.fromPath( params.genomeref, checkIfExists: true  )
    genomerefidx = Channel.fromPath( params.genomerefindex, checkIfExists: true )
   
    // filtering and trimming
    filter( Channel.fromPath( params.fastq + "*.fastq.gz" ).collect() )
    pigz( filter.out.fastq_trimmed )

    // alignment
    minimap_align_bamout( genomeref, pigz.out.fastqgz )

    // cramino and kyber for quick QC
    kyber ( minimap_align_bamout.out.bam )
    cramino ( minimap_align_bamout.out.bam )
    mosdepth (minimap_align_bamout.out.bam, minimap_align_bamout.out.idx )
    mosdepth_plot ( mosdepth.out.coverage_txt )

    clair3_variant_calling(minimap_align_bamout.out.bam, minimap_align_bamout.out.idx, genomeref, genomerefidx)
    filter_snp_indel( clair3_variant_calling.out.snp_indel )
    
    sniffles( minimap_align_bamout.out.bam, minimap_align_bamout.out.idx, genomeref )
    filtersniffles( sniffles.out.sv_calls )

    // SV size visualisation
    extract_SV_lengths( filtersniffles.out.variants_pass )
    plot_SV_lengths( extract_SV_lengths.out.dels, extract_SV_lengths.out.ins)


    // longphase
    // phasing
    longphase_phase( genomeref, filter_snp_indel.out.variants_pass, filtersniffles.out.variants_pass, minimap_align_bamout_qscore.out.bam, minimap_align_bamout_qscore.out.idx )
    longphase_tag( longphase_phase.out.snv_indel_phased, longphase_phase.out.sv_phased, minimap_align_bamout_qscore.out.bam, minimap_align_bamout_qscore.out.idx )

     // crossstitch
    crossstitch( longphase_phase.out.snv_indel_phased, longphase_phase.out.sv_phased, minimap_align_bamout_qscore.out.bam, genomeref, params.karyotype )

    // de novo assembly 
    shasta( filter.out.fastq_trimmed )
    parallel_gzip_assembly ( shasta.out.assembly )
    parallel_gzip_gfa ( shasta.out.assembly_gfa )
}

/*
* SNP calling, longphase, crossstitch
* 
*/
workflow bam_to_crossstitch {
    // genome
    genomeref = Channel.fromPath( params.genomeref, checkIfExists: true  )
    genomerefidx = Channel.fromPath( params.genomerefindex, checkIfExists: true )

    inputbam = Channel.fromPath( params.bam , checkIfExists: true )
    inputbamidx = Channel.fromPath( params.bamidx , checkIfExists: true )
   
    clair3_variant_calling(inputbam, inputbamidx, genomeref, genomerefidx)
    filter_snp_indel( clair3_variant_calling.out.snp_indel )

    sniffles( inputbam, inputbamidx, genomeref )
    filtersniffles( sniffles.out.sv_calls )
    
    // SV size visualisation
    extract_SV_lengths( filtersniffles.out.variants_pass )
    plot_SV_lengths( extract_SV_lengths.out.dels, extract_SV_lengths.out.ins)


    // longphase
    // phasing
    longphase_phase( genomeref, filter_snp_indel.out.variants_pass, filtersniffles.out.variants_pass, inputbam, inputbamidx )
    longphase_tag( longphase_phase.out.snv_indel_phased, longphase_phase.out.sv_phased, inputbam, inputbamidx )

    // crossstitch
    crossstitch( longphase_phase.out.snv_indel_phased, longphase_phase.out.sv_phased, inputbam, genomeref, params.karyotype )
}


/* 
* Guppy basecalling
*/
workflow guppy_basecalling_cli {

    genomeref = Channel.fromPath( params.genomeref, checkIfExists: true  )
    // genomeindex = Channel.fromPath( params.genomeref + "/indexes/minimap2-ont/genome.mmi" )

    basecall( Channel.fromPath( params.ont_base_dir ), genomeref )

}


/* 
* Sam to sorted bam conversion and indexing – CLI shortcut
*/
workflow sam_to_sorted_bam_cli {

    genomeref = Channel.fromPath( params.genomeref, checkIfExists: true )
    sam = Channel.fromPath( params.mapped_sam, checkIfExists: true )

    samtobam( sam, genomeref )

}


/* 
* Call structural variation and generate consensus
*/
workflow call_svs {
    take:
        genomeref
        bam
        bam_index
        // step

    main:    
        cutesv( bam, bam_index, genomeref )
        sniffles( bam, bam_index, genomeref )
        svim( bam, bam_index, genomeref )
        filtersvim( svim.out.sv_calls )
        dysgu( bam, bam_index, genomeref )

        allsvs = cutesv.out.sv_calls
                    .mix( sniffles.out.sv_calls, filtersvim.out.sv_calls_q10 )
                    .collect()
        survivor( allsvs )
    
    emit:
        cutesv = cutesv.out.sv_calls
        sniffles = sniffles.out.sv_calls
        svim = filtersvim.out.sv_calls_q10
        consensus = survivor.out.sv_consensus

    
}


/* 
* Call structural variation and generate consensus
*/
workflow call_svs_cli {

    genomeref = Channel.fromPath( params.genomeref, checkIfExists: true  )
    // genomeindex = Channel.fromPath( params.genomeref + "/indexes/minimap2-ont/genome.mmi" )
    bam = Channel.fromPath( params.aligned_bam )
    bam_index = Channel.fromPath( params.aligned_bam + ".bai" )
    
    call_svs( genomeref, bam, bam_index, "cli" )
    
}

/* 
* Call small variants using ONT Medaka
*/
workflow medaka_variant_calling_cli {

    genomeref = Channel.fromPath( params.genomeref, checkIfExists: true  )
    // genomeindex = Channel.fromPath( params.genomeref + "/indexes/minimap2-ont/genome.mmi" )
    aligned_reads = Channel.fromPath( params.aligned_bam )
    aligned_reads_idx = Channel.fromPath( params.aligned_bam + ".bai" )

    medaka_snv( aligned_reads, aligned_reads_idx, genomeref )

}


/* 
* Call small variants using PEPPER-Margin-DeepVariant – CLI shortcut
*/
workflow pepper_deepvariant_calling_cli {

    genomeref = Channel.fromPath( params.genomeref, checkIfExists: true  )
    // genomeindex = Channel.fromPath( params.genomeref + "/indexes/minimap2-ont/genome.mmi" )
    bam = Channel.fromPath( params.aligned_bam )
    bam_index = Channel.fromPath( params.aligned_bam + ".bai" )

    deepvariant( bam, bam_index, genomeref )

}


// /* 
// * Run a de novo genome assembly using Shasta – CLI shortcut
// */
// workflow shasta_assembly_cli {

//     fastq = Channel.fromPath( params.processed_reads )
//     config = Channel.fromPath( params.shasta_config )

//     shasta( fastq, config )

// }


workflow assembly_polishing {
    take:
        assembly
        fastq
    
    main:
        minimap( assembly, fastq )
        racon( fastq, minimap.out.mapped_sam, assembly )
        // medaka_polish( fastq, racon.out.consensus )
        medaka_polish_parallel( fastq, racon.out.consensus )

    emit:
        polished_assembly = medaka_polish_parallel.out.consensus
}


workflow deepvariant_parallel {
    take:
        bam
        bam_index
        genomeref

    main:
        contigs = genomeref.splitFasta( record: [id: true, seqString: false ]).map { it.id }

        deepvariant_par( bam, bam_index, genomeref, contigs )

        vcf_concat( deepvariant_par.out.indel_snv_vcf.collect() )
    
    emit:
        indel_snv_vcf = vcf_concat.out.merged_vcf
}


workflow medaka_polish_parallel {
    take:
        fastqs
        draft

    main:
        medaka_assembly_polish_align( fastqs, draft )
        // draft.splitFasta( record: [id: true, seqString: false ]).view { it.id }
        contigs = draft.splitFasta( record: [id: true, seqString: false ]).map { it.id }.randomSample( 100000, 234 ).buffer( size: 50, remainder: true )

        medaka_assembly_polish_consensus( medaka_assembly_polish_align.out.calls_to_draft,
                                         medaka_assembly_polish_align.out.calls_to_draft_index,
                                         contigs )

        medaka_assembly_polish_stitch( medaka_assembly_polish_consensus.out.probs.collect(), draft )
    
    emit:
        consensus = medaka_assembly_polish_stitch.out.consensus
}

workflow medaka_polish_parallel_cli {

    fastqs = Channel.fromPath( params.processed_reads )
    draft = Channel.fromPath( params.genomeref )

    medaka_assembly_polish_parallel( fastqs, draft )    
}



/* 
* Process reads/squiggles from an ONT run
*/
workflow process_reads {
    take:
        genomeref
        ont_base

    main:

        if ( params.rebasecall ) {

            // if ( !file( params.genomeref + "/indexes/minimap2-ont/genome.mmi" ).exists() ) {
            //     create_minimap_index( genomeref )
            //     genomeindex = create_minimap_index.out.mmi
            // } else {
            //     genomeindex = Channel.fromPath( params.genomeref + "/indexes/minimap2-ont/genome.mmi" )
            // }

            basecall( Channel.fromPath( params.ont_base_dir ), genomeref )
            filter( basecall.out.fastqs.collect() )
        } else if ( params.basecall_dir ) {
            filter( Channel.fromPath( params.basecall_dir + "**.fastq.gz" ).collect() )
        } else {
            filter( Channel.fromPath( params.ont_base_dir + "**.fastq.gz" ).collect() )
        }

        pigz( filter.out.fastq_trimmed )

    emit:
        fastq_trimmed = filter.out.fastq_trimmed

}



/* 
* Process reads/squiggles from an ONT run – CLI shortcut
*/
workflow process_reads_cli {

    genomeref = Channel.fromPath( params.genomeref, checkIfExists: true )
    ont_base = Channel.fromPath( params.ont_base_dir )

    process_reads( genomeref, ont_base )

}


/* 
* Align reads to a reference genome using minimap2 and turn into sorted bam – CLI shortcut
*/
workflow minimap_alignment_cli {

    genomeref = Channel.fromPath( params.genomeref, checkIfExists: true )
    fastqs = Channel.fromPath( params.processed_reads )

    minimap( genomeref, fastqs )

}


workflow minimap_align_bamout {
    take:
        genomeref
        fastq
    
    main:
        minimap( genomeref, fastq )
        samtobam( minimap.out.mapped_sam, genomeref )

    emit:
        bam = samtobam.out.sorted_bam
        idx = samtobam.out.bam_index

}

workflow minimap_align_bamout_qscore {
    take:
        genomeref
        fastq
    
    main:
        minimap( genomeref, fastq )
        sam_to_sorted_bam_qscore( minimap.out.mapped_sam, genomeref )

    emit:
        bam = sam_to_sorted_bam_qscore.out.sorted_bam
        idx = sam_to_sorted_bam_qscore.out.bam_index

}


workflow lra_alignment_sv_calling {
    take: 
        fastqs
        genomeref

    main:
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
        samtobam( lra_alignment.out.mapped_sam, genomeref )

        // SV calling using cuteSV
        cutesv( samtobam.out.sorted_bam, samtobam.out.bam_index, genomeref )

}


workflow assembly_based_variant_calling {
    take:
        fastq
        // genomeref
    
    main:
        // 1. Assembly-based pipeline
        shasta( fastq )
        // assembly_polishing( shasta.out.assembly, fastq)

        // minimap_align_bamout( assembly_polishing.out.polished_assembly, fastq )
    //     minimap( assembly_polishing.out.polished_assembly, fastq )
    //     samtobam( minimap.out.mapped_sam, assembly_polishing.out.polished_assembly )

        // call_svs( assembly_polishing.out.polished_assembly, minimap_align_bamout.out.bam, minimap_align_bamout.out.idx, "assembly" )
        // deepvariant( minimap_align_bamout.out.bam, minimap_align_bamout.out.idx, assembly_polishing.out.polished_assembly, "assembly" )
    //     call_svs( assembly_polishing.out.polished_assembly, samtobam.out.sorted_bam, samtobam.out.bam_index )
    //     deepvariant( samtobam.out.sorted_bam, samtobam.out.bam_index, assembly_polishing.out.polished_assembly )

    emit:
        polished_assembly = shasta.out.assembly
        // svs = call_svs.out.consensus
        // snvs = deepvariant.out.indel_snv_vcf
        // snvs_idx = deepvariant.out.indel_snv_vcf_index

}


workflow reference_based_variant_calling {
    take:
        fastq
        genomeref
    
    main:
        // minimap( genomeref, fastq )
        // samtobam( minimap.out.mapped_sam, genomeref )
        minimap_align_bamout( genomeref, fastq )

        // note that on the current VSC system (P100 and V100 nodes) GPU nodes
        // lack sufficient memory to run PEPPER-DeepVariant genome-wide
        // the current if statement reflects that and splits up the genome by chromosome to run as separate jobs
        // if ( params.deepvariant_with_gpu ) {
            // deepvar = deepvariant_parallel( minimap_align_bamout.out.bam, minimap_align_bamout.out.idx, genomeref )
        // } else {
            deepvariant( minimap_align_bamout.out.bam, minimap_align_bamout.out.idx, genomeref )
        // }

        call_svs( genomeref, deepvariant.out.haplotagged_bam, deepvariant.out.haplotagged_bam_idx )


    emit:
        svs = call_svs.out.consensus
        snvs = deepvariant.out.indel_snv_vcf
        snvs_idx = deepvariant.out.indel_snv_vcf_index
        haplotagged_bam = deepvariant.out.haplotagged_bam
        haplotagged_bam_idx = deepvariant.out.haplotagged_bam_idx

}


workflow haploid_to_diploid_assembly {
    take:
        fastq
        reference
        haploid_assembly
    
    main:
        minimap_align_bamout( haploid_assembly, fastq )

        hapdup( minimap_align_bamout.out.bam, minimap_align_bamout.out.idx, haploid_assembly )

        // dipdiff( haploid_assembly, hapdup.out.hap1, hapdup.out.hap2 )
        dipdiff_reference( reference, hapdup.out.hap1, hapdup.out.hap2 )

}


// workflow phased_methylation_calls {
//     take:
//         ont_base
//         genomeref
//         haplotagged_bam
    
//     main:
//         megalodon( genomeref, ont_base )
// }

workflow wgs_analysis_fastq {

    genomeref = Channel.fromPath( params.genomeref, checkIfExists: true  )
    ont_base = Channel.fromPath( params.ont_base_dir, checkIfExists: true )

    // process reads
    process_reads( genomeref, ont_base )

    // 2. Reference alignment-based pipeline
    minimap_align_bamout( genomeref, process_reads.out.fastq_trimmed )

    deepvariant( minimap_align_bamout.out.bam, minimap_align_bamout.out.idx, genomeref )
    filter_snp_indel( deepvariant.out.indel_snv_vcf )
    
    sniffles( minimap_align_bamout.out.bam, minimap_align_bamout.out.idx, genomeref )
    filtersniffles( sniffles.out.sv_calls )

    longphase_phase( genomeref, filter_snp_indel.out.variants_pass, filtersniffles.out.variants_pass, minimap_align_bamout.out.bam, minimap_align_bamout.out.idx )
    longphase_tag( longphase_phase.out.snv_indel_phased, longphase_phase.out.sv_phased, minimap_align_bamout.out.bam, minimap_align_bamout.out.idx )

    // seqtk( longphase_tag.out.hap1ids, longphase_tag.out.hap2ids, process_reads.out.fastq_trimmed )
    // prepare_svs_stitch( longphase_phase.out.sv_phased, genomeref )
    // crossstitch( longphase_phase.out.snv_indel_phased, prepare_svs_stitch.out.fixed_svs, genomeref, params.karyotype )
    crossstitch( longphase_phase.out.snv_indel_phased, filtersniffles.out.variants_pass, minimap_align_bamout.out.bam, genomeref, params.karyotype )

    // de novo assembly using shasta
    shasta( process_reads.out.fastq_trimmed ) 
    // use reference-based haplotype tags to assure assembly-based haplotypes match reference-based ones
    haptagtransfer( longphase_tag.out.haplotagged_bam, shasta.out.assembly )
    hapduptagged( haptagtransfer.out.retagged_bam, haptagtransfer.out.retagged_bamindex, shasta.out.assembly )

    

    // quast_hap1( genomeref, hapduptagged.out.hap1, "hap1" )
    // quast_hap1_ref( genomeref, crossstitch.out.hap1, "hap1" )
    // quast_hap2( genomeref, hapduptagged.out.hap2, "hap2" )
    // quast_hap2_ref( genomeref, crossstitch.out.hap2, "hap2" )

    // mummer_hap1( genomeref, hapduptagged.out.hap1, "hap1" )
    // mummer_hap2( genomeref, hapduptagged.out.hap2, "hap2" )
    // mummer_hap1_ref( genomeref, crossstitch.out.hap1, "hap1" )
    // mummer_hap2_ref( genomeref, crossstitch.out.hap2, "hap2" )
    // snv_indel = reference_based_variant_calling.out.snvs
    
    // get_haplotype_readids( reference_based_variant_calling.out.haplotagged_bam )

}


workflow {

    genomeref = Channel.fromPath( params.genomeref, checkIfExists: true  )
    ont_base = Channel.fromPath( params.ont_base_dir, checkIfExists: true )
    // basecalls = Channel.fromPath( params.basecall_dir )
    // reads = Channel.fromPath( params.processed_reads, checkIfExists: true )
    // genomeindex = Channel.fromPath( params.genomeref + "/indexes/minimap2-ont/genome.mmi" )

    // process reads
    process_reads( genomeref, ont_base )

    // start megalodon
    if ( params.megalodon_recall ) {
        megalodon( genomeref, ont_base )
    }

    // assembly based variant calling
    assembly_based_variant_calling( process_reads.out.fastq_trimmed )

    // 2. Reference alignment-based pipeline
    reference_based_variant_calling( process_reads.out.fastq_trimmed, genomeref )

    // snv_indel = reference_based_variant_calling.out.snvs
    haploid_to_diploid_assembly( process_reads.out.fastq_trimmed, genomeref, assembly_based_variant_calling.out.polished_assembly )
    // lra_alignment_sv_calling( process_reads.out.fastq_trimmed, genomeref )
    // minimap_alignment_snv_calling( process_reads.out.fastq_trimmed, genomeref )

    get_haplotype_readids( reference_based_variant_calling.out.haplotagged_bam )

    if ( params.megalodon_recall ) {
        megalodon_aggregate( megalodon.out.megalodon_results, get_haplotype_readids.out.hap1ids, get_haplotype_readids.out.hap2ids )
    } else if ( params.megalodon_dir ) {
        megalodon_aggregate( Channel.fromPath( params.megalodon_dir, checkIfExists: true  ), get_haplotype_readids.out.hap1ids, get_haplotype_readids.out.hap2ids )
    }

}

// -m ${Math.floor( $task.memory / $task.cpus ) }
// ch_reference_fasta.view()
// ch_reference_index.view()
workflow.onComplete {
    println "Pipeline completed at: ${workflow.complete}"
    println "Time to complete workflow execution: ${workflow.duration}"
    println "Execution status: ${workflow.success ? 'Succesful' : 'Failed' }"
}
