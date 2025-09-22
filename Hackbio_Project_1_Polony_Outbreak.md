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

2. **Quality control**  
   - Script: `02_fastqc_multiqc.sh`  
   - QC on raw reads.  

3. **Trimming**  
   - Script: `03_fastp_trim.sh`  
   - Removed adapters & low-quality bases.  

4. **Genome assembly**  
   - Script: `04_spades_assembly.sh`  
   - *De novo* assembly with SPAdes.  

5. **Assembly QC**  
   - Script: `05_quast_multiqc.sh`  
   - Assessed genome assemblies.  

6. **Organism identification**  
   - Script: `06_blast_identification.sh`  
   - BLAST on representative assembly → taxonomic assignment.  

7. **AMR & virulence profiling**  
   - Script: `07_abricate_amr_vf.sh`  
   - AMR & VF detection via Abricate.  

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
