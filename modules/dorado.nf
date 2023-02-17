/* 
* Basecall reads with dorado
* TODO: test
*/
process basecall_dorado {
    label 'dorado'

    label ( workflow.profile.contains('slurm') ? 'wice_gpu' : 'with_p100node' ) //if slurm run wice, else P100 NVIDIA

    publishDir path: "${params.sampleid}/", mode: 'copy'

    input:
    path reads_pod5
    
    output:
    path "${params.sampleid}_mod_calls.bam", emit: ubam 

    script:
    """
    dorado basecaller /opt/dorado/bin/${params.dorado_config} \
    $reads_pod5 --modified-bases ${params.mod_bases} | samtools view -Sh > ${params.sampleid}_mod_calls.bam
    """
}


// TODO test if this work on non GPU node + add indexing --> only to the workflow, not here
process ubam_to_bam {
    label 'dorado'
    label 'cpu_high'
    label 'mem_high'
    label 'time_high'

    publishDir path: "${params.outdir}/${params.sampleid}/", mode: 'copy'
    
    input:
    path ubam 
    path genomeref

    output 
    path "${params.sampleid}.pass.bam", emit: mapped_bam
    path "${params.sampleid}.fail.bam", emit: mapped_bam_fail


    script:
    """
    bash samtools bam2fq -@ $task.cpus -T "*" ${params.ubam} \
        | minimap2 -y -k 17 -t -@ $task.cpus -ax map-ont -L --secondary=no --MD --cap-kalloc=1g -K 10g $genomeref - \
        | samtools sort -@ $task.cpus -T ./scratch/ - \
        | tee >(samtools view -e '[qs] < 10' -o ${params.sampleid}.fail.bam - ) \
        | samtools view -e '[qs] >= 10' -o ${params.sampleid}.pass.bam -
    """    
}