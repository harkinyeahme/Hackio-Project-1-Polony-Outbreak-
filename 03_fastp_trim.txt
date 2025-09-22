#!/bin/bash
# Purpose: 
#   Trim adapters and low-quality bases from raw reads using fastp,
#   then summarize with MultiQC.
# Input: raw_reads/*.fastq.gz
# Output: trimmed_reads/ + fastp_reports/ + multiqc_reports_trimmed/


mkdir -p trimmed_reads fastp_reports

echo "[INFO] Starting trimming with fastp..."
for R1 in raw_reads/*_1.fastq.gz; do
    [[ -f "$R1" ]] || continue
    SAMPLE=$(basename "$R1" _1.fastq.gz)
    R2="raw_reads/${SAMPLE}_2.fastq.gz"

    fastp \
        -i "$R1" \
        -I "$R2" \
        -o "trimmed_reads/${SAMPLE}_1.trimmed.fastq.gz" \
        -O "trimmed_reads/${SAMPLE}_2.trimmed.fastq.gz" \
        -h "fastp_reports/${SAMPLE}.html" \
        -j "fastp_reports/${SAMPLE}.json"

    echo "[INFO] fastp trimming completed for sample: $SAMPLE"
done

echo "[INFO] All reads trimmed. Running MultiQC..."
multiqc fastp_reports/ -o multiqc_reports_trimmed/

echo "[INFO] fastp + MultiQC completed."
