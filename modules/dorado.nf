/* 
* Basecall reads with dorado
* Note : r9 basecalling is hardcoded due to the bug in this version of dorado (model name mismatch)
*/
// TODO test this process
process basecall_dorado {
    label 'dorado'

    label ( workflow.profile.contains('slurm') ? 'wice_gpu' : 'with_p100node' ) // if slurm run wice, else P100 NVIDIA 

    publishDir path: "${params.sampleid}/", mode: 'copy'

    input:
    path reads_pod5
    
    output:
    path "${params.sampleid}_mod_calls.bam", emit: ubam 

    // dorado basecalling script  
	script:
    if ( params.rerio_config == '' ) {
        """
	    dorado basecaller /opt/dorado/bin/${params.dorado_config} -r \
	    $reads_pod5 '--modified-bases '+${params.mod_bases} > ${params.sampleid}_mod_calls.bam
        """
    } else { // else use rerio model
        // figure out which modified bases model to use 
        if ( params.mod_bases == 'm6A') {
             """
	        dorado basecaller /rerio/dorado_models/${params.rerio_config} -r \
	        $reads_pod5 --modified-bases-models /rerio/dorado_models/res_dna_r10.4.1_e8.2_400bps_sup@v4.0.1_6mA@v2 > \
            ${params.sampleid}_mod_calls.bam
            """
        }
        else if ( params.mod_bases == '5mC') {
             """
	        dorado basecaller /rerio/dorado_models/${params.rerio_config} -r \
	        $reads_pod5 --modified-bases-models /rerio/dorado_models/res_dna_r10.4.1_e8.2_400bps_sup@v4.0.1_5mC@v2 > \
            ${params.sampleid}_mod_calls.bam
            """
        }
        else { // else use both models
             """
	        dorado basecaller /rerio/dorado_models/${params.rerio_config} -r \
	        $reads_pod5 --modified-bases-models /rerio/dorado_models/res_dna_r10.4.1_e8.2_400bps_sup@v4.0.1_5mC@v2,/rerio/dorado_models/res_dna_r10.4.1_e8.2_400bps_sup@v4.0.1_6mA@v2 > \
            ${params.sampleid}_mod_calls.bam
            """
        }
   
    }
	
    
    
    
}

