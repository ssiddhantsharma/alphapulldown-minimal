# AlphaPulldown SLURM Scripts and AlphaJudge Analysis:

Simple, clean SLURM scripts for running AlphaPulldown protein-protein interaction predictions, and perform alphajudge analysis on the predicted complexes.

## Overview

AlphaPulldown uses AlphaFold2 to predict protein-protein interactions in two steps:

1. **Step 1**: MSA generation and feature computation (CPU)
2. **Step 2**: Structure prediction (GPU)

## Scripts

- `download_sequences.sh` - Download FASTA sequences from UniProt IDs
- `fasta_to_txt.sh` - Extract UniProt IDs from FASTA files
- `step1_mmseqs.sh` - MSA generation using ColabFold MMSeqs2
- `step2_prediction.sh` - Structure prediction (pulldown mode)

## Input Files Required

You need these files in your working directory:
- `baits_example1.fasta` - FASTA sequences of bait proteins
- `candidates_shorter_example1.fasta` - FASTA sequences of candidate proteins  
- `baits.txt` - List of bait protein names (one per line, matching FASTA headers)
- `candidates.txt` - List of candidate protein names (one per line, matching FASTA headers)

## Usage

### Option 1: Starting with UniProt IDs

If you have protein ID lists:

```bash
# Create ID files
echo "P78344" > baits_example1.txt
echo -e "Q14240\nP60842\nO76094" > candidates_shorter_example1.txt

# Download sequences
./fetch_sequences.sh baits_example1.txt candidates_shorter_example1.txt
```

### Option 2: Starting with FASTA files

If you already have FASTA files, extract the protein names:

```bash
./fasta2ID.sh baits_example1.fasta candidates_shorter_example1.fasta
```

### Submit jobs

```bash
# Create directories
mkdir -p logs

# Submit Step 1 (MSA generation) - adjust array size based on total sequences
sbatch --array=1-XX step1_mmseqs.sh

# Submit Step 2 (structure prediction) - adjust array size = number of CANDIDATES 
sbatch --array=1-XX step2_prediction.sh
```

### With dependency (recommended):

```bash
# Submit step1, get job ID, then submit step2 with dependency
step1_jobid=$(sbatch --array=1-XX --parsable step1_mmseqs.sh)
sbatch --array=1-XX --dependency=afterok:$step1_jobid step2_prediction.sh
```

## Notes

- **Step 1** uses ColabFold MMSeqs2 for faster MSA generation
- **Step 2** uses pulldown mode (each bait tested against all candidates)
- Protein names in .txt files must exactly match the FASTA header names (after special character replacement).

## Alphajudge Analysis
```bash
module load conda
conda activate alphajudge

 AlphaJudge interface scoring [-h] [--contact_thresh CONTACT_THRESH] [--pae_filter PAE_FILTER]
                                    [--models_to_analyse {best,all}] [-r] [-o SUMMARY]
                                    [paths ...]

alphajudge /nfs/scistore20/praetgrp/XXX/ --model_to_analyse all -o summary.csv
```
