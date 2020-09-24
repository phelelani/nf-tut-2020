#!/usr/bin/env nexflow

folder = file(params.data, type:'dir')

input_ch = Channel.fromPath("${folder}/*.bim")

process getIDs {
    publishDir 'clean_ids', mode: 'copy'
    
    input:
    file(input) from input_ch

    output:
    file("${input.baseName}") into id_ch
    file(input) into orig_ch
  
    """
    cut -f 2 $input | sort > ${input.baseName}

    """
    
}

// orig_ch.subscribe { println "$it"}
    

process getDups {
    publishDir 'clean_ids', mode: 'copy'

    input:
    file input from id_ch
  
    output:
    file "${input.baseName}.dups" into dups_ch
  
    script:
    """
    uniq -d $input > ${input.baseName}.dups
    touch ignore
    """
}

process removeDups {
    publishDir 'clean_ids', mode: 'copy'

    input:
    file badids from dups_ch
    file orig from orig_ch
    
    output:
    file "${orig.baseName}_clean.bim" into cleaned_ch
    
    script:
    "grep -v -f $badids $orig > ${orig.baseName}_clean.bim "
}

splits = [400,500,600]

process splitIDs {
    publishDir 'split_files', mode: 'copy'
    
    input:
    file(bim) from cleaned_ch
    each split from splits
  
    output:
    file ("*-$split-*") into output_ch;
    
    script:
    "split -l $split $bim ${bim.baseName}-$split- "
}

output_ch.subscribe {
    println "$it.baseName"
}
