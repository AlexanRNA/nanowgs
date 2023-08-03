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

    // check to see if we need to use rerio model 
    // check if rerio_config is empty string or not
    if ( params.rerio_config == '' ) {
        // use dorado model
        set val(dorado_config) '/opt/dorado/bin/'+${params.dorado_config}
    } else {
        // use rerio model
        set val(dorado_config) '/rerio/dorado_models/'+{params.rerio_config}
    }

    // check if we also call modified bases
    // check if mod_bases is empty string or not
    if ( params.mod_bases == '' ) {
        // do not call modified bases
        set val(mod_bases) ''
    } else if ( params.rerio_config != '') {
        // call modified bases using rerio model
        // check which modified bases to call
        if ( params.mod_bases == 'm6A') {
            set val(mod_bases) '--modified-bases-models res_dna_r10.4.1_e8.2_400bps_sup@v4.0.1_6mA@v2'
        } else if ( params.mod_bases == '5mC') {
            set val(mod_bases) '--modified-bases-models res_dna_r10.4.1_e8.2_400bps_sup@v4.0.1_5mC@v2'
        } else { // call both 5mC and m6A
            set val(mod_bases) '--modified-bases-models res_dna_r10.4.1_e8.2_400bps_sup@v4.0.1_5mC@v2,res_dna_r10.4.1_e8.2_400bps_sup@v4.0.1_6mA@v2'
        }
        
    } else {
        // call modified bases using dorado model
        set val(mod_bases) '--modified-bases '+${params.mod_bases}
    }

    // write dorado basecalling script  
	script:
	"""
	dorado basecaller !{dorado_config}   -r \
	$reads_pod5 !{mod_bases} > ${params.sampleid}_${params.mod_bases}_calls.bam
    """
    
    
    
}

