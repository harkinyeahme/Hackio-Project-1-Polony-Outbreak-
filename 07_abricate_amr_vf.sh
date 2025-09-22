#!/bin/bash
# Purpose:
#   Identify antimicrobial resistance (AMR) and virulence factor (VF) genes using Abricate.
# Input: assembly/*/contigs.fasta
# Output: AMR/*.tab + VF/*.tab + summary tables

mkdir -p AMR VF

echo "[INFO] Running Abricate for AMR genes..."
for file in assembly/*/contigs.fasta; do
    SAMPLE=$(basename "$(dirname "$file")")
    abricate "$file" > AMR/${SAMPLE}_amr.tab
done
abricate --summary AMR/*.tab > AMR/abricate_summary.amr.tab

echo "[INFO] Running Abricate for virulence genes..."
for file in assembly/*/contigs.fasta; do
    SAMPLE=$(basename "$(dirname "$file")")
    abricate --db vfdb "$file" > VF/${SAMPLE}_vf.tab
done
abricate --summary VF/*.tab > VF/abricate_summary.vf.tab

echo "[INFO] Abricate analysis completed."
