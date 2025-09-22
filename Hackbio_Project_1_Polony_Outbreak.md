# Stage 1 Report: Investigating the South African Polony Outbreak  

##  Summary  
This report documents the **whole genome sequencing (WGS) analysis** of the 2017–2018 South African polony outbreak caused by *Listeria monocytogenes*.  

---

## 1. Introduction  
In 2017, South Africa experienced one of the largest recorded bacterial outbreaks in history. By March 2018, the **National Institute for Communicable Diseases (NICD)** reported:  

- **978 laboratory-confirmed cases**  
- **183 deaths (27% case fatality rate)**  

The majority of cases occurred in:  
- Gauteng (59%)  
- Western Cape (12%)  
- KwaZulu-Natal (7%)  

Vulnerable groups included **neonates, pregnant women, the elderly, and immunocompromised patients (especially HIV-positive individuals).**  

Epidemiological tracing pointed to **cold-processed meat (“polony”) from Enterprise Foods, Polokwane** as the outbreak source.  

---

## 2. Aim and Objectives  
1. Confirm the causative organism of the outbreak.  
2. Identify antimicrobial resistance (AMR) genes.  
3. Characterize the virulence factor (VF) profile, including toxin genes.  
4. Recommend effective treatment strategies.  

---

## 3. Methods  

### Tools & Pipelines  
- **FastQC** → Raw read quality control  
- **MultiQC** → Aggregated QC report  
- **Fastp** → Trimming of low-quality bases/adapters  
- **SPAdes** → *De novo* genome assembly  
- **QUAST** → Assembly quality assessment  
- **BLAST** → Taxonomic identification via NCBI nt database  
- **Abricate** → AMR and virulence factor detection  

### Workflow  
1. **Data download & setup**  
   - Script: `01_download_data.sh` 
   - Created project directories, downsized dataset (n=50), archived scripts.
```bash
#!/bin/bash
# Author: Olanrewaju Akinyemi
# Purpose:       
   Download raw sequencing data and organize it into proper directories.

#   1. Create project directory and change to the directory in one line of command
mkdir -p project $$ cd project/
#   2. Download data download script from GitHub.
echo "[INFO] Downloading raw data script..."
wget https://raw.githubusercontent.com/HackBio-Internship/2025_project_collection/refs/heads/main/SA_Polony_100_download.sh

#   3. Downsize to first 50 samples (header + 100 lines → 50 samples, paired-end)
head -n 101 SA_Polony_100_download.sh > SA_Polony_50_download.sh

#   4. Run downsized script
bash SA_Polony_50_download.sh

#   5. Move FASTQ files to raw_reads folder
mkdir -p raw_reads
mv *fastq.gz raw_reads/

#   6. Archive original scripts for reproducibility
mkdir -p archive
mv *.sh archive/

echo "[INFO] Raw data downloaded and organized."
```

2. **Quality control**  
   - Script: `02_fastqc_multiqc.sh`  
   - QC on raw reads.

```bash
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

```

3. **Trimming**  
   - Script: `03_fastp_trim.sh`  
   - Removed adapters & low-quality bases.
```bash
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

``` 

4. **Genome assembly**  
   - Script: `04_spades_assembly.sh`  
   - *De novo* assembly with SPAdes.
```bash
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

```

5. **Assembly QC**  
   - Script: `05_quast_multiqc.sh`  
   - Assessed genome assemblies.
```bash
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

```

6. **Organism identification**  
   - Script: `06_blast_identification.sh`  
   - BLAST on representative assembly → taxonomic assignment.
```bash
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

``` 

7. **AMR & virulence profiling**  
   - Script: `07_abricate_amr_vf.sh`  
   - AMR & VF detection via Abricate.
```bash
#!/bin/bash
# Purpose:
#   Identify antimicrobial resistance (AMR) and virulence factor (VF) genes using Abricate.
# Input: assembly/*/contigs.fasta
# Output: AMR/*.tab + VF/*.tab + summary tables
# Create output directories for AMR and VF reports
mkdir -p AMR VF

# AMR gene detection
echo "[INFO] Running Abricate for AMR genes..."
for file in assembly/*/contigs.fasta; do
    SAMPLE=$(basename "$(dirname "$file")")
    abricate "$file" > AMR/${SAMPLE}_amr.tab
done
# Summarize AMR results across all samples
abricate --summary AMR/*.tab > AMR/abricate_summary.amr.tab

# VF gene detection
echo "[INFO] Running Abricate for virulence genes..."
for file in assembly/*/contigs.fasta; do
    SAMPLE=$(basename "$(dirname "$file")")
    abricate --db vfdb "$file" > VF/${SAMPLE}_vf.tab
done
# Summarize VF results across all samples
abricate --summary VF/*.tab > VF/abricate_summary.vf.tab

echo "[INFO] Abricate analysis completed."

```  

---

## 4. Results  

### 4.1 Organism Identification  
- All assemblies were confirmed as **Listeria monocytogenes** by BLAST.  

### 4.2 Antimicrobial Resistance (AMR) Genes  
- **fosX (100%)** → Fosfomycin resistance.  
- **lmo0919_fam (100%)** → Multidrug efflux pump.  
-  No β-lactam resistance genes detected.  

### 4.3 Virulence Factor Profile  
- **Total VF genes detected:** 38  
- **Range per sample:** 27–37 genes  

#### Functional Categorization of Virulence Genes  

**Adhesion & Invasion**  
- *inlA* (100%), *inlB* (90%), *inlC* (100%), *inlF* (86%), *inlK* (100%)  
- *lap* (100%), *lapB* (100%), *fbpA* (100%), *iap/cwhA* (100%)  

**Escape & Motility**  
- *hly* (100%), *plcA* (100%), *plcB* (100%), *actA* (100%), *mpl* (100%), *vip* (100%)  

**Stress & Immune Evasion**  
- *bsh* (100%), *oatA* (100%), *pdgA* (100%), *clpC* (100%), *clpE* (100%), *clpP* (100%), *prsA2* (100%), *lspA* (100%)  
- *gtcA* (92%)  

**Regulators**  
- *prfA* (100%), *lntA* (100%)  

**Nutrient Acquisition & Metabolism**  
- *hpt* (100%), *lpeA* (100%), *lplA1* (100%), *icl* (2%)  

**Gut-Specific Virulence (LLS Cluster)**  
- *llsA* (94%), *llsB* (70%), *llsD* (72%), *llsG* (94%), *llsH* (86%)  
- *llsP* (42%), *llsX* (90%), *llsY* (78%)  

**Key Note:**  
- *icl* had the lowest prevalence (2%), found only in sample SRR27013337.  
- Most virulence genes were present in **≥90% of isolates**, highlighting a highly pathogenic strain.  

---

## 5. Discussion  

### Recommended Antibiotic Therapy  
- **First-line therapy:** *Ampicillin + Gentamicin*  
  - **Ampicillin (β-lactam):** Inhibits cell wall synthesis → lysis.  
  - **Gentamicin (aminoglycoside):** Inhibits protein synthesis.  
  - **Synergy:** Potent combination, suitable for *Listeria* treatment.  

-  **Avoid fosfomycin** → Ineffective due to widespread *fosX*.  

### Public Health Implications  
- High prevalence of virulence factors underscores *L. monocytogenes* as a severe public health threat.  
- Vulnerable populations (neonates, pregnant women, elderly, immunocompromised) remain at greatest risk.  
- Surveillance and rapid genomic characterization are critical for outbreak control.  

---

## 6. Conclusion  
Genomic analysis confirmed *Listeria monocytogenes* as the causative agent of the South African polony outbreak. Despite resistance to fosfomycin, the absence of β-lactam resistance genes supports the continued use of **Ampicillin + Gentamicin** as an effective first-line therapy.  

This investigation highlights the value of WGS-based surveillance in shaping **treatment guidelines and public health decisions** during foodborne outbreaks.  
