# nf-adaptive

Workflow to visualize panel coverage for adaptive samping projects.

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

| File Path             | Description |
| --------------------- | ----------- |
| ${out_dir}/alignments/${sample_name}_bg.bam<br>${out_dir}/alignments/${sample_name}_bg.bam.bai | Aligned and sorted bam file for background only |
| ${out_dir}/alignments/${sample_name}_panel.bam<br>${out_dir}/alignments/${sample_name}_panel.bam.bai | Aligned and sorted bam file for panel only (includding padding region) |
| ${out_dir}/reports/${sample_name}_coverage_mapq.pdf | Plot showing coverage for each genes of the panel (without padding region) and each filtering condition |
| ${out_dir}/reports/mosdepth/${sample_name}_nofilter.regions.bed.gz<br>${out_dir}/reports/mosdepth/${sample_name}_primary.regions.bed.gz<br>${out_dir}/reports/mosdepth/${sample_name}_mapq60.regions.bed.gz | Bed file containing coverage for each gene in the panel under different filtering conditions |
| ${out_dir}/alignments/${sample_name}.hg38_bg.bigwig<br>${sample_name}.hg38_panel.bigwig | Tow bigwig files for background and panel |
| ${out_dir}/reports/multiqc_report_background.html | Multiqc report for coverage of background |

## Parameters

- `-profile`: Configuration profile, set to drac if running on the Digital Research Alliance of Canada clusters [default: standard]
- `--out_dir`: Path to the desired output directory [default: output]
- `--publish`: Boolean, set to false to turn off publishing of outputs, usually used in Github Actions [default: true]

## Steps

1. Separate bam file into two files with [samtools]: one containing reads aligned outside the selected panel, and one containing reads aligned inside the selected panel (including buffer region).
2. Create bigwig files for panel and background for future visualization on IGV with [deeptools].
3. Run [mosdepth] on the bam containing background alignments to get background coverage.
4. Run [multiqc] on the output of [mosdepth] on background alignemnts.
5. Run [mosdepth] 3 times on the bam containing alignments to panel to get coverage for each genes in the panel (without buffer region) under different filtering conditions :
    a. No mapping quality filter (samtools flag 1540)
    b. No secondary alignments (samtools flag 1796)
    c. MAPQ = 60
6. Run [R] script to produce a coverage plot showing coverage under each filtering conditions for each genes.

[Docker]: https://www.docker.com
[Apptainer]: https://apptainer.org
[Nextflow]: https://www.nextflow.io/docs/latest/index.html
[samtools]: http://www.htslib.org
[multiqc]: https://multiqc.info
[mosdepth]: https://github.com/brentp/mosdepth
[R]: https://www.r-project.org/
[deeptools]: https://deeptools.readthedocs.io/en/latest/