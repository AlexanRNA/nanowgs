// TODO test
/* 
*  extract sizes of SVs (del and ins) from SV call
*/

process extract_SV_lengths {
    label 'cpu_low'
    label 'mem_low'
    label 'time_low'
    // label 'kyber' // just some linux env

    publishDir path: "${params.outdir}/${params.sampleid}/SV_stats/", mode: 'copy'

    input:
    path variants_pass
    
    output:
    path "${params.sampleid}.deletions.txt", emit: dels // emit path only, since dorado does not accept file, only dir
    path "${params.sampleid}.insertions.txt", emit: ins
    path "${params.sampleid}.SV_count.txt"

    script:
    """
    less $variants_pass | grep -v "^#" | grep DEL | cut -f8 | cut -d";" -f3 | cut -d"=" -f2 > ${params.sampleid}.deletions.txt
    less $variants_pass | grep -v "^#" | grep INS | cut -f8 | cut -d";" -f3 | cut -d"=" -f2 > ${params.sampleid}.insertions.txt
    less $variants_pass | grep -v "^#" | cut -f8 | cut -d';' -f2 | sort | uniq -c > ${params.sampleid}.SV_count.txt
    """
}


// TODO test
/* 
*  plot size distributions
*/

process plot_SV_lengths {
    label 'cpu_low'
    label 'mem_low'
    label 'time_low'
    label 'R' 

    publishDir path: "${params.outdir}/${params.sampleid}/SV_stats/", mode: 'copy'

    input:
    path dels
    path ins
    
    output:
    path "${params.sampleid}.SV_size_dist.pdf"

    script:
    """
    sv_size.R $dels $ins "${params.sampleid}.SV_size_dist.pdf"
    """
}