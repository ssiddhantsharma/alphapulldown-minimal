#!/bin/bash
#SBATCH --job-name=AP_step2
#SBATCH --error=AP_step2_%A_%a.err
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=48:00:00
#SBATCH --mem=120G
#SBATCH --no-requeue
#SBATCH --export=NONE
#SBATCH --array=1

unset SLURM_EXPORT_ENV

module load conda
source activate AlphaPulldown

BAITS_FILE="/nfs/scistore20/praetgrp/ssharma/rfd_mpnn_colab/alphapull/baits.txt"
CANDIDATES_FILE="/nfs/scistore20/praetgrp/ssharma/rfd_mpnn_colab/alphapull/candidates.txt"
FEATURES_DIR="/nfs/scistore20/praetgrp/ssharma/rfd_mpnn_colab/alphapull/features"
MODELS_DIR="/nfs/scistore20/praetgrp/ssharma/rfd_mpnn_colab/alphapull/models"

mkdir -p "$MODELS_DIR"

srun run_multimer_jobs.py \
    --mode=pulldown \
    --num_cycle=3 \
    --num_predictions_per_model=1 \
    --output_path="$MODELS_DIR" \
    --data_dir="/nfs/scistore14/rcsb/alphafold.database_2023_04_11" \
    --protein_lists="${BAITS_FILE},${CANDIDATES_FILE}" \
    --monomer_objects_dir="$FEATURES_DIR" \
    --job_index=$SLURM_ARRAY_TASK_ID \
    --compress_result_pickles=True \
    --remove_result_pickles=True

if [[ $SLURM_ARRAY_TASK_ID -eq 1 ]]; then
    cd "$MODELS_DIR"
    create_notebook.py --cutoff=5.0 --output_dir="$(pwd)"
fi