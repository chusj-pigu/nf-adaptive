include { mosdepth } from '../modules/mosdepth'
include { gzip } from '../modules/ingress'
include { coverage_as } from '../modules/rscripts'

workflow PLOT {

    take:
    bed
    summary


    main:
    gzip(bed)
    nofilter_bed_ch = gzip.out
        .filter( file -> file.name.contains('nofilter') )

    primary_bed_ch = gzip.out
        .filter( file -> file.name.contains('primary') )

    uniq_bed_ch = gzip.out
        .filter( file -> file.name.contains('mapq60') ) 

    background_coverage = summary
        .filter( file -> file.name.contains('background')) 
        .splitText()
        .last()
        .map { row -> row.tokenize('\t')[3].toDouble() }

    coverage_as(nofilter_bed_ch, primary_bed_ch, uniq_bed_ch, background_coverage)

}