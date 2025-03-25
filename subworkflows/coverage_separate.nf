include { multiqc } from '../modules/multiqc'
include { mosdepth } from '../modules/mosdepth'
include { nanoplot } from '../modules/nanoplot'
include { separate_panel } from '../modules/samtools'
include { remove_padding } from '../modules/ingress'
include { bamCoverage } from '../modules/deeptools'

workflow COVERAGE_SEPARATE {

    take:
    bam
    bed
    nobed
    padding

    main:
    // First separate reads mapped to panel from the background:
    separate_panel(bam, bed)
    remove_padding(bed, padding)

    // Create channels for creating bigwig files

    bigwig_bg_in = Channel.of('background')
        .combine(separate_panel.out.bg)
    
    bigwig_panel_in = Channel.of('panel')
        .combine(separate_panel.out.panel)

    bigwig_in = bigwig_bg_in
        .mix(bigwig_panel_in)
    
    bamCoverage(bigwig_in)

    // Run nanoplot on both background and panel:
    nano_bg_in = separate_panel.out.bg
        .flatten()
        .first()
        .map { it -> tuple('background', it) }
    
    nano_panel_in = separate_panel.out.panel
        .flatten()
        .first()
        .map { it -> tuple('panel', it) }

    nano_ch = nano_bg_in
        .mix(nano_panel_in)

    nanoplot(nano_ch)

    // Make channels for each bed file and prepare input for mosdepth
    bg_bed_ch = nobed
        .map( it -> tuple(it, 1796, 0))

    bg_mosdepth_in = bam
        .map { file -> "${file.simpleName}_background" }
        .combine(separate_panel.out.bg)
        .combine(bg_bed_ch)

    nofilt_bed_ch = remove_padding.out
        .map( it -> tuple(it, 1540, 0))

    nofilt_mosdepth_in = bam
        .map { file -> "${file.simpleName}_nofilter" }
        .combine(separate_panel.out.panel)
        .combine(nofilt_bed_ch)
    
    prim_bed_ch = remove_padding.out
        .map( it -> tuple(it, 1796, 0))

    prim_mosdepth_in = bam
        .map { file -> "${file.simpleName}_primary" }
        .combine(separate_panel.out.panel)
        .combine(prim_bed_ch)

    uniq_bed_ch = remove_padding.out
        .map( it -> tuple(it, 1796, 60))

    uniq_mosdepth_in = bam
        .map { file -> "${file.simpleName}_mapq60" }
        .combine(separate_panel.out.panel)
        .combine(uniq_bed_ch)
    
    mosdepth_in = bg_mosdepth_in
        .mix(nofilt_mosdepth_in,prim_mosdepth_in,uniq_mosdepth_in)

    mosdepth(mosdepth_in)

    // Multiqc for background and panel
    multi_ch = mosdepth.out.summary
         .mix(mosdepth.out.dist)
         .filter { file -> file.name.contains('background') || file.name.contains('primary') }
         .mix(nanoplot.out)
         .collect()
    multiqc(multi_ch)

    emit:
    bed = mosdepth.out.bed
    summary = mosdepth.out.summary

}