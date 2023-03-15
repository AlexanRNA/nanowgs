
/* 
* De novo genome assembly using Shasta
*/
process run_shasta_assembly {
    label 'shasta'
    label ( workflow.profile.contains('qsub') ? 'bigmem': 'cpu_high' )
    label ( workflow.profile.contains('qsub') ? null: 'mem_high' )
    label ( workflow.profile.contains('qsub') ? null: 'time_mid' )
    
    label ( workflow.profile.contains('slurm') ? 'wice_bigmem' : 'cpu_high')

    publishDir path: "${params.outdir}/${params.sampleid}/", mode: 'copy', pattern: "*csv"
    publishDir path: "${params.outdir}/${params.sampleid}/", mode: 'copy', pattern: "*json"
    publishDir path: "${params.outdir}/${params.sampleid}/", mode: 'copy', pattern: "*log"
    publishDir path: "${params.outdir}/${params.sampleid}/", mode: 'copy', pattern: "*conf"
    publishDir path: "${params.outdir}/${params.sampleid}/", mode: 'copy', pattern: "*html"
 

    input:
    path fastq
    // path config

    output:
    path "shasta_assembly/Assembly.fasta", emit: assembly
    path "shasta_assembly/Assembly.gfa", emit: assembly_gfa
    path "shasta_assembly/*"

    script:
    // def localproc = ( workflow.profile.contains('slurm') ? 0: task.cpus )
    if( params.shasta_minreadlength )
            """
            if [[ $fastq == *.gz ]]; then 
                gunzip -c $fastq > uncompressed_reads.fq
            else 
                mv $fastq uncompressed_reads.fq
            fi

            shasta \
                --config ${params.shasta_config} \
                --input uncompressed_reads.fq \
                --assemblyDirectory ./shasta_assembly \
                --threads $task.cpus \
                --Reads.minReadLength ${params.shasta_minreadlength}
        
            if [ -f ./shasta_assembly/Assembly-Haploid.fasta ]
            then mv ./shasta_assembly/Assembly-Haploid.fasta ./shasta_assembly/Assembly.fasta
            fi 
            """
        else
            """
            if [[ $fastq == *.gz ]]; then 
                gunzip -c $fastq > uncompressed_reads.fq
            else 
                mv $fastq uncompressed_reads.fq
            fi

            shasta \
                --config ${params.shasta_config} \
                --input uncompressed_reads.fq \
                --assemblyDirectory ./shasta_assembly \
                --threads $task.cpus
        
            if [ -f ./shasta_assembly/Assembly-Haploid.fasta ]
            then mv ./shasta_assembly/Assembly-Haploid.fasta ./shasta_assembly/Assembly.fasta
            fi 
            """  
}


/* 
* De novo haploid genome assembly using Shasta
* DEPRECATED
*/
process run_shasta_assembly_haploid {
    label 'shasta'
    label ( workflow.profile.contains('qsub') ? 'bigmem': 'cpu_high' )
    label ( workflow.profile.contains('qsub') ? null: 'mem_high' )
    label ( workflow.profile.contains('qsub') ? null: 'time_mid' )

    publishDir path: "${params.outdir}/${params.sampleid}/${task.process}/", mode: 'copy'

    input:
    path hapreads
    val haplotype

    output:
    path "${haplotype}/Assembly.fasta", emit: assembly
    path "${haplotype}"

    script:
    def localproc = ( workflow.profile.contains('qsub') ? 0: task.cpus )
    if( params.shasta_minreadlength )
        """
        shasta \
            --config /shastaconf/conf/${params.shasta_config_haploid} \
            --input $hapreads \
            --assemblyDirectory $haplotype \
            --threads ${localproc} \
            --Reads.minReadLength ${params.shasta_minreadlength}
        """
    else
        """
        shasta \
            --config /shastaconf/conf/${params.shasta_config_haploid} \
            --input $hapreads \
            --assemblyDirectory $haplotype \
            --threads ${localproc}
        """
}



