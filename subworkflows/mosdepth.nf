include { mosdepth } from '../modules/mosdepth'
include { gzip } from '../modules/ingress'

workflow CREATE_BED {

    take:
    bam
    bed
    flag 
    qual
    name

    main:
    mosdepth(bam,bed,flag,qual,name)

    gzip(mosdepth.out.bed)

    emit:
    bed = gzip.out
}