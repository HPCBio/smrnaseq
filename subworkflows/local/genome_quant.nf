//
// Quantify mirna with bowtie and mirtop
//

params.samtools_options = [:]
params.map_options = [:]
params.samtools_sort_options  = [:]
params.samtools_index_options = [:]
params.samtools_stats_options = [:]

include { INDEX_GENOME } from '../../modules/local/bowtie_genome'
include { BOWTIE_MAP_SEQ as BOWTIE_MAP_GENOME } from '../../modules/local/bowtie_map_mirna' addParams( options: params.map_options)
include { BAM_SORT_SAMTOOLS as BAM_STATS_GENOME } from './bam_sort' addParams( sort_options: params.samtools_sort_options, index_options: params.samtools_index_options, stats_options: params.samtools_stats_options )

workflow GENOME_QUANT {
    take:
    fasta
    bt_index
    reads      // channel: [ val(meta), [ reads ] ]

    main:

    if (!bt_index){
        INDEX_GENOME( fasta )
        bt_indices = INDEX_GENOME.out.bt_indices
        fasta_formatted = INDEX_GENOME.out.fasta
    } else {
        bt_indices = Channel.fromPath("${bt_index}**ebwt", checkIfExists: true).ifEmpty { exit 1, "Bowtie1 index directory not found: ${bt_index}" }
        fasta_formatted = fasta
    }

    if (bt_indices){
        BOWTIE_MAP_GENOME ( reads, bt_indices.collect() )
        BAM_STATS_GENOME ( BOWTIE_MAP_GENOME.out.bam, Channel.empty()  )

    }

    emit:
    fasta    = fasta_formatted
    indices  = bt_indices
    stats    = BAM_STATS_GENOME.out.stats


}