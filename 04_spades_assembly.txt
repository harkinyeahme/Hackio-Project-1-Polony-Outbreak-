#!/bin/bash
# Purpose: 
#   Assemble genomes from trimmed reads using SPAdes.
# Input: trimmed_reads/*.trimmed.fastq.gz
# Output: assembly/<SAMPLE>/contigs.fasta



mkdir -p assembly

echo "[INFO] Starting genome assembly with SPAdes..."
for R1 in trimmed_reads/*_1.trimmed.fastq.gz; do
    [[ -f "$R1" ]] || continue
    SAMPLE=$(basename "$R1" _1.trimmed.fastq.gz)
    R2="trimmed_reads/${SAMPLE}_2.trimmed.fastq.gz"

    spades.py \
        -1 "$R1" \
        -2 "$R2" \
        -o "assembly/$SAMPLE" \
        --phred-offset 33 \
        --threads 8

    echo "[INFO] Assembly completed for $SAMPLE"
done

echo "[INFO] Assembly completed for all samples."
