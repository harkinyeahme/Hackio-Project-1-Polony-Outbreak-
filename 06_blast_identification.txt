#!/bin/bash
# BLAST Identification Script
# Purpose:
#   Identify the organism of a representative assembly
#   using the first contig and NCBI nt database (remote BLAST)
# Input:
#   assembly/*/contigs.fasta
# Output:
#   blast/representative_contig.fasta
#   blast/blast_identification_results.tsv
# =============================================

# -----------------------------
# Step 0: Define directories
mkdir -p blast
# -----------------------------
ASSEMBLY_DIR="./assembly"      # Where your contigs.fasta files are stored
BLAST_DIR="./blast"            # Where BLAST outputs will be saved
mkdir -p "$BLAST_DIR"          # Create output folder if it doesn't exist

echo "[INFO] Running BLAST for organism identification (rubric requirement)..."

# -----------------------------
# Step 1: Select a representative assembly
# -----------------------------
REPRESENTATIVE_ASSEMBLY=$(find "$ASSEMBLY_DIR" -name "contigs.fasta" | head -1)

# Check if an assembly was found
if [[ -z "$REPRESENTATIVE_ASSEMBLY" ]]; then
    echo "[ERROR] No assemblies found. Please run the assembly script first."
    exit 1
fi

SAMPLE_NAME=$(basename $(dirname "$REPRESENTATIVE_ASSEMBLY"))
echo "[INFO] Using representative sample: $SAMPLE_NAME"

# -----------------------------
# Step 2: Extract first contig for BLAST
# -----------------------------
head -n 200 "$REPRESENTATIVE_ASSEMBLY" > "$BLAST_DIR/representative_contig.fasta"
echo "[INFO] Representative contig saved to $BLAST_DIR/representative_contig.fasta"

# -----------------------------
# Step 3: Run BLAST remotely
# -----------------------------
echo "[INFO] Running BLAST against NCBI nt database (may take several minutes)..."

blastn \
    -query "$BLAST_DIR/representative_contig.fasta" \
    -db nt \
    -remote \
    -outfmt "6 std stitle" \
    -max_target_seqs 5 \
    -evalue 1e-50 \
    -out "$BLAST_DIR/blast_identification_results.tsv"

# -----------------------------
# Step 4: Show top hits
# -----------------------------
if [[ -f "$BLAST_DIR/blast_identification_results.tsv" ]]; then
    echo "[INFO] BLAST complete. Top hits:"
    echo "----------------------------------------"
    awk -F'\t' '{printf "%-60s %-6s %-6s %-10s\n", $13, $3, $4, $11}' "$BLAST_DIR/blast_identification_results.tsv" | head -5
    echo "----------------------------------------"

    # Check for Listeria in the results
    if grep -q -i "listeria" "$BLAST_DIR/blast_identification_results.tsv"; then
        echo "✓ SUCCESS: Listeria monocytogenes identified via BLAST."
    else
        echo "✗ WARNING: Expected Listeria not found in top BLAST hits."
    fi
else
    echo "[ERROR] BLAST output not found. Check your command and network connection."
fi

echo "[INFO] BLAST identification workflow completed."
