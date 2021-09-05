 
/*
 * Defines some parameters in order to specify the refence genomes
 * and read pairs by using the command line options
 */
params.reads = "$baseDir/data/ggal/*_{1,2}.fq"
params.annot = "$baseDir/data/ggal/ggal_1_48850000_49020000.bed.gff"
params.genome = "$baseDir/data/ggal/ggal_1_48850000_49020000.Ggal71.500bpflank.fa"
params.genometrim = "$baseDir/data/ggal/ggal_1_48850000_49020000.Ggal71.500bpflank"
params.outdir = 'results'

log.info """\
         TFG   P I P E L I N E    
         =============================
         genome: ${params.genome}
         annot : ${params.annot}
         reads : ${params.reads}
         outdir: ${params.outdir}
         """
         .stripIndent()
 
Channel
    .fromFilePairs( params.reads )
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .into { read_pairs_ch; read_pairs_fastqc }

process fastqc {
	tag "$pair_id"
	
	input:
	set val(name), file(reads) from read_pairs_fastqc
	
	output:
	file "*_fastqc.{zip,html}" into fastqc_results
	
	script:
	"""
	fastqc -q $reads
	"""
}

process buildIndex {
    tag "$genome.baseName"
    publishDir params.outdir, mode: 'copy'
    
    input:
    path genome from params.genome
    path annot from params.annot
     
    output:
    path 'g_index' into index_ch
    file "g_index/*out" into starindex_results
    
    """
    mkdir g_index
    STAR --runThreadN 2 --runMode genomeGenerate --sjdbGTFtagExonParentTranscript Parent --sjdbGTFfile ${annot} --genomeDir g_index --genomeFastaFiles ${genome}
    """
}

process mapping {
	tag "$pair_id"
     
    input:
    path genome from params.genome 
    path annot from params.annot
    path index from index_ch
    tuple val(pair_id), path(reads) from read_pairs_ch
 
    output:
    set pair_id, "*.bam" into bam_ch
    file "*out" into starmap_results
 
    """
    STAR --genomeDir ${index} --readFilesIn $reads --outSAMtype BAM SortedByCoordinate --outFileNamePrefix ${pair_id}
    """
}

process markDupsNSort {
    tag "$pair_id"
    publishDir params.outdir, mode: 'copy'  
       
    input:
    tuple val(pair_id), path(bam_file) from bam_ch
     
    output:
    set pair_id, "mark_dups_*.bam" into dup_ch
    tuple val(pair_id), path('mark_dups_*.bam')
    file "mark_dups_*" into dups_results
 
    """
    gatk MarkDuplicates --INPUT $bam_file --OUTPUT mark_dups_${pair_id}.bam --METRICS_FILE mark_dups_${pair_id}.metrics
    """
}	

process multiqc {
	publishDir "${params.outdir}/MultiQC", mode: 'copy'  
	
	input:
	file ("fastqc/*") from fastqc_results.collect().ifEmpty([])
	file ("star/*") from starindex_results.collect().ifEmpty([]) 
	file ("star/*") from starmap_results.collect().ifEmpty([]) 
	file ("dups/*") from dups_results.collect().ifEmpty([]) 

	output:
	file "multiqc_report.html" into multiqc_report
	file "*_data"
	
	script:
	"""
	multiqc .
	"""
}
 
workflow.onComplete { 
	log.info ( workflow.success ? "Done!" : "Oops .. something went wrong" )
}
