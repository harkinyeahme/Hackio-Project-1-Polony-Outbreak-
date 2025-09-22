#!/bin/bash
# Purpose: 
#   Perform quality control (FastQC) on raw reads and aggregate results with MultiQC.
# Input: raw_reads/*.fastq.gz
# Output: fastqc_reports/ + multiqc_reports_raw/


mkdir -p fastqc_reports

echo "[INFO] Running FastQC on raw reads..."
for R1 in raw_reads/*_1.fastq.gz; do
    [[ -f "$R1" ]] || continue  # Skip if no file
    SAMPLE=$(basename "$R1" _1.fastq.gz)
    R2="raw_reads/${SAMPLE}_2.fastq.gz"

    fastqc "$R1" "$R2" -o fastqc_reports
    echo "[INFO] FastQC completed for sample: $SAMPLE"
done

# Aggregate all FastQC reports into a summary
mkdir -p multiqc_reports
multiqc fastqc_reports/ -o multiqc_reports_raw/

echo "[INFO] FastQC + MultiQC completed."

