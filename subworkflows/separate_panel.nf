include { multiqc } from '../modules/multiqc'
include { mosdepth } from '../modules/mosdepth'
include { separate_panel } from '../modules/samtools'

workflow SEPARATE {

    take:
    bam
    bed
    nobed

    main:
    // First separate reads mapped to panel from the background
    separate_panel(bam, bed)

    // Compute background coverage
    mosdepth(separate_panel.out.bg, nobed, 1796, 0, 'background')
    multi_ch = Channel.empty()
        .mix(mosdepth.out.summary, mosdepth.out.dist)
        .collect()
    multiqc(multi_ch)

    emit:
    panel = separate_panel.out.panel
    mosdepth_bg = mosdepth.out.summary
}