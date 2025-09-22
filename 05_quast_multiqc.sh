#!/bin/bash
# Purpose: 
#   Assess assembly quality with QUAST and summarize results with MultiQC.
# Input: assembly/*/contigs.fasta
# Output: quast_reports/ (individual + combined)

mkdir -p quast_reports

echo "[INFO] Running QUAST on assemblies..."
for file in assembly/*/contigs.fasta; do
    SAMPLE=$(basename "$(dirname "$file")")
    quast.py "$file" -o quast_reports/$SAMPLE
    echo "[INFO] QUAST completed for $SAMPLE"
done

# Combined report across all assemblies
quast.py assembly/*/contigs.fasta -o quast_reports/combined

# MultiQC summary
multiqc quast_reports/ -o quast_reports/

echo "[INFO] QUAST + MultiQC completed."
