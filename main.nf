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

include { COVERAGE_SEPARATE } from './subworkflows/coverage_separate'
include { PLOT } from './subworkflows/visualization'

// Main workflow logic

workflow {

  // Channels
  bam_ch = Channel.fromPath(params.bam)
  bed_full_ch = Channel.fromPath(params.bed)        // Bed file including buffer region

  // Point to empty bed file to get background coverage
  nobed_ch = Channel.fromPath("${projectDir}/assets/NO_BED")

  padding_ch = Channel.value(params.padding)        // Padding added downstream and upstream of the ROI

  low_fidelity_ch = Channel.fromPath(params.low_fidelity_list)

  COVERAGE_SEPARATE(bam_ch, bed_full_ch, nobed_ch, padding_ch)
  PLOT(COVERAGE_SEPARATE.out.bed, COVERAGE_SEPARATE.out.summary, low_fidelity_ch)
  
}


