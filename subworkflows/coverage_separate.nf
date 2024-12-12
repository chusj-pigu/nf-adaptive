include { multiqc } from '../modules/multiqc'
include { mosdepth } from '../modules/mosdepth'
include { separate_panel } from '../modules/samtools'
include { bamCoverage as bigwig_bg } from '../modules/deeptools'
include { bamCoverage as bigwig_panel } from '../modules/deeptools'

workflow COVERAGE_SEPARATE {

    take:
    bam
    bed
    nobed
    bed_nopad

    main:
    // First separate reads mapped to panel from the background
    separate_panel(bam, bed)
    bigwig_bg(separate_panel.out.bg)
    bigwig_panel(separate_panel.out.panel)

    bg_bed_ch = nobed
        .map( it -> tuple(it, 1796, 0))

    bg_mosdepth_in = bam
        .map { file -> "${file.simpleName}_background" }
        .combine(separate_panel.out.bg)
        .combine(bg_bed_ch)

    nofilt_bed_ch = bed_nopad
        .map( it -> tuple(it, 1540, 0))

    nofilt_mosdepth_in = bam
        .map { file -> "${file.simpleName}_nofilter" }
        .combine(separate_panel.out.panel)
        .combine(nofilt_bed_ch)
    
    prim_bed_ch = bed_nopad
        .map( it -> tuple(it, 1796, 0))

    prim_mosdepth_in = bam
        .map { file -> "${file.simpleName}_primary" }
        .combine(separate_panel.out.panel)
        .combine(prim_bed_ch)

    uniq_bed_ch = bed_nopad
        .map( it -> tuple(it, 1796, 60))

    uniq_mosdepth_in = bam
        .map { file -> "${file.simpleName}_mapq60" }
        .combine(separate_panel.out.panel)
        .combine(uniq_bed_ch)
    
    mosdepth_in = bg_mosdepth_in
        .mix(nofilt_mosdepth_in,prim_mosdepth_in,uniq_mosdepth_in)

    mosdepth(mosdepth_in)

    // Multiqc for background
    multi_ch = mosdepth.out.summary
         .mix(mosdepth.out.dist)
         .filter( file -> file.name.contains('background') )
         .collect()
    multiqc(multi_ch)

    emit:
    bed = mosdepth.out.bed
    summary = mosdepth.out.summary

}