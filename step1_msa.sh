#!/bin/bash
#SBATCH --job-name=AP_step1_mmseqs
#SBATCH --error=AP_step1_mmseqs_%A_%a.err
#SBATCH --cpus-per-task=4
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=6:00:00
#SBATCH --mem=32G
#SBATCH --no-requeue
#SBATCH --export=NONE
#SBATCH --array=1-21

unset SLURM_EXPORT_ENV

module load conda
source activate AlphaPulldown

BAITS_FASTA="/nfs/scistore20/praetgrp/ssharma/rfd_mpnn_colab/alphapull/baits_example1.fasta"
CANDIDATES_FASTA="/nfs/scistore20/praetgrp/ssharma/rfd_mpnn_colab/alphapull/candidates_shorter_example1.fasta"
OUTPUT_DIR="/nfs/scistore20/praetgrp/ssharma/rfd_mpnn_colab/alphapull/features"

mkdir -p "$OUTPUT_DIR"
srun create_individual_features.py \
    --fasta_paths="${BAITS_FASTA},${CANDIDATES_FASTA}" \
    --output_dir="$OUTPUT_DIR" \
    --use_mmseqs2=True \
    --save_msa_files=False \
    --max_template_date="2050-01-01" \
    --skip_existing=False \
    --seq_index=$SLURM_ARRAY_TASK_ID