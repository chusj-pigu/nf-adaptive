// Usage help

def helpMessage() {
  log.info """
        Usage:
        The typical command for running the pipeline is as follows:
        nextflow run chusj-pigu/nf-basecall --pod5 /path/to/pod5 --ref /path/to/REF.fasta

        Mandatory arguments:
        """
}

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}

// Import subworklfows and modules

// Main workflow logic