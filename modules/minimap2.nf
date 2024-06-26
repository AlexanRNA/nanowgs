
/* 
* Index a reference genome with minimap2
* DEPRECATED: doing minimap2 indexing on the fly (few minutes / human genome)
*/
process create_minimap_index {
    // tag "$genomeref"
    label 'cpu_low'
    label 'mem_low'
    label 'time_low'
    label 'minimap'

    publishDir path: "${file(params.genomeref).getParent() + '/indexes/minimap2-ont/'}", mode: 'copy'

    input:
    path genomeref

    output:
    path "genome.mmi", emit: mmi

    script:
    """
    minimap2 -x map-ont -k 17 -t $task.cpus -d genome.mmi $genomeref
    """

}


/* 
* Align reads to a reference genome with minimap2
*/
process minimap_alignment {
    label 'cpu_high'
    label 'mem_high'
    label 'time_mid'
    label 'minimap'

    input:
    path genomeref
    // path index
    path reads

    output:
    path "mapped.sam", emit: mapped_sam
    val "minimap2", emit: aligner

    script:
    """
    minimap2 -ax map-ont -k 17 -t $task.cpus -L -y --secondary=no --MD --cap-kalloc=1g -K 10g $genomeref $reads > mapped.sam
    """
}