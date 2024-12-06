# nf-adaptive

Template to make [Nextflow] workflows

## Dependencies

Requires [Nextflow] and either [Docker] or [Apptainer] installed.

Usage:

```sh
nextflow run chusj-pigu/nf-adaptive -r main --bam [PATH] [OPTIONS]
```

To list available options and parameters for this workflow, run :

``` sh
nextflow run chusj-pigu/nf-adaptive -r main --help
```

## Overview

This workflow can be run locally or on Compute Canada. To use on Compute Canada, use the `-profile drac` option.

## Inputs

- `--bam`: Path to the full sorted bam file aligned to hg38. Mandatory
- `--bed`: Path to the original bed file used for the adaptive sampling sequencing. Mandatory if run locally with standard profile [default with drac profile: path to st-jude bed file]
- `--bed_nopad`: Path to the bed file with regions not including buffer, has to be the same genes as within the --bed file. Mandatory if run locally with standard profile [default with drac profile: path to st-jude bed file without padding]


## Outputs

This workflow will output:

| File Path             | Description | Condition        |
| --------------------- | ----------- | ---------------- |
| ${sample_name}_bg.bam<br>${sample_name}_bg.bam.bai | Aligned and sorted bam file for background only | Always |
| ${sample_name}_panel.bam<br>${sample_name}_panel.bam.bai | Aligned and sorted bam file for panel only (includding padding region) | Always |
| ${sample_name}_coverage_mapq.pdf | Plot showing coverage for each genes of the panel (without padding region) and each filtering condition | If separate_only is set to false |
| mosdepth_nofilter/${sample_name}_panel_nofilter.regions.bed.gz<br>mosdepth_primary/${sample_name}_panel_primary.regions.bed.gz<br>mosdepth_mapq60/${sample_name}_panel_mapq60.regions.bed.gz | Bed file containing coverage for each gene in the panel under different filtering conditions | If separate_only is set to false |
| multiqc_report.html | Multiqc report for coverage of background | Always |

## Parameters

- `-profile`: Configuration profile, set to drac if running on the Digital Research Alliance of Canada clusters [default: standard]
- `--out_dir`: Path to the desired output directory [default: output]
- `--separate_only`: Boolean, set to true to only separate bam file to background and panel without producing coverage plot [default: false]
- `--publish`: Boolean, set to false to turn off publishing of outputs, usually used in Github Actions [default: true]

## Steps

1. Separate bam file into two files with [samtools]: one containing reads aligned outside the selected panel, and one containing reads aligned inside the selected panel (including buffer region).
2. Run [mosdepth] on the bam containing background alignments to get background coverage.
3. Run [multiqc] on the output of [mosdepth] on background alignemnts.
4. Run [mosdepth] 3 times on the bam containing alignments to panel to get coverage for each genes in the panel (without buffer region) under different filtering conditions :
    a. No mapping quality filter (samtools flag 1540)
    b. No secondary alignments (samtools flag 1796)
    c. MAPQ = 60
5. Run [R] script to produce a coverage plot showing coverage under each filtering conditions for each genes.

[Docker]: https://www.docker.com
[Apptainer]: https://apptainer.org
[Nextflow]: https://www.nextflow.io/docs/latest/index.html
[samtools]: http://www.htslib.org
[multiqc]: https://multiqc.info
[mosdepth]: https://github.com/brentp/mosdepth
[R]: https://www.r-project.org/