// Usage help

def helpMessage() {
  log.info """
        Usage:
        The typical command for running the pipeline is as follows:
        nextflow run chusj-pigu/nf-basecall --pod5 /path/to/pod5 --ref /path/to/REF.fasta

        Mandatory arguments:
        --bam                           Path to the full sorted bam file aligned to hg38

        Optional arguments:
        --bed                           Path to the original bed file used for the adaptive sampling sequencing. Mandatory if run locally with standard profile [default with drac profile: path to st-jude bed file]
        -profile                        Configuration profile, set to drac if running on the Digital Research Alliance of Canada clusters [default: standard]
        --bed_nopad                     Path to the bed file with regions not including buffer, has to be the same genes as within the --bed file. Mandatory if run locally with standard profile [default with drac profile: path to st-jude bed file without padding]
        --out_dir                       Path to the desired output directory [default: output]
        --separate_only                 Boolean, set to true to only separate bam file to background and panel without producing coverage plot [default: false]               
        --publish                       Boolean to turn off publishing of outputs, usually used in Github Actions [default: true]
        --help                          This usage statement.
        """
}

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}

// Import subworkflows and modules

include { SEPARATE } from './subworkflows/separate_panel'
include { CREATE_BED as BED_FULL } from './subworkflows/mosdepth'
include { CREATE_BED as BED_PRIM } from './subworkflows/mosdepth'
include { CREATE_BED as BED_UNIQ } from './subworkflows/mosdepth'
include { coverage_as } from './modules/rscripts'

// Main workflow logic

workflow {

  // Channels
  bam_ch = Channel.fromPath(params.bam)
  bed_full_ch = Channel.fromPath(params.bed)        // Bed file including buffer region

  // Point to empty bed file to get background coverage
  nobed_ch = Channel.fromPath("${projectDir}/assets/NO_BED")

  SEPARATE(bam_ch, bed_full_ch, nobed_ch)

  // Point to empty bed file to get background coverage
  nobed_ch = Channel.fromPath("${projectDir}/assets/NO_BED")

  if (!params.separate_only) {
  // Create bed files for panel without buffer with different filters
  // Filter out only read unmapped, read fails platform/vendor quality checks and read is PCR or optical duplicate (baseline):
  bed_nopad_ch = Channel.fromPath(params.bed_nopad) // Bed file without buffer region
  //all_flag = Channel.of(1540)

  BED_FULL(SEPARATE.out.panel, bed_nopad_ch, 1540, 0, 'nofilter')
  nofilt_bed = BED_FULL.out.bed

  // Filter out secondary alignment:
  BED_PRIM(SEPARATE.out.panel, bed_nopad_ch, 1796, 0, 'primary')
  prim_bed = BED_PRIM.out.bed
  // Keep only mapping quality 60 (uniquely mapped reads)
  BED_UNIQ(SEPARATE.out.panel, bed_nopad_ch, 1796, 60, 'mapq60')
  uniq_bed = BED_UNIQ.out.bed

  // Extract background coverage to value:

  background_coverage = SEPARATE.out.mosdepth_bg
    .splitText()
    .last()
    .map { row -> row.tokenize('\t')[3].toDouble() }

  // Coverage plot :

  coverage_as(nofilt_bed, prim_bed, uniq_bed, background_coverage)

  }

}
