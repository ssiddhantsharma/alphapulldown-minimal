#!/bin/bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <baits.txt> <candidates.txt>"
    exit 1
fi

BAITS_FILE="$1"
CANDIDATES_FILE="$2"
BAITS_FASTA="${BAITS_FILE%.txt}.fasta"
CANDIDATES_FASTA="${CANDIDATES_FILE%.txt}.fasta"
FAILED_IDS="failed_downloads.txt"

> "$FAILED_IDS"

fetch_sequences() {
    local input_file="$1"
    local output_fasta="$2"
    local label="$3"
    
    > "$output_fasta"
    
    local total=$(grep -c '' "$input_file" 2>/dev/null || echo "0")
    local count=0
    local failed=0
    
    while IFS= read -r uniprot_id || [[ -n "$uniprot_id" ]]; do
        uniprot_id=$(echo "$uniprot_id" | tr -d '[:space:]')
        [[ -z "$uniprot_id" ]] && continue
        
        ((count++))
        echo -n "[$count/$total] $uniprot_id... "
        
        if curl -s "https://rest.uniprot.org/uniprotkb/${uniprot_id}.fasta" | grep -q "^>"; then
            curl -s "https://rest.uniprot.org/uniprotkb/${uniprot_id}.fasta" >> "$output_fasta"
            echo "" >> "$output_fasta"
            echo "✓"
        else
            echo "✗"
            echo "$uniprot_id" >> "$FAILED_IDS"
            ((failed++))
        fi
        
        sleep 0.5
        
    done < "$input_file"
    
    echo "$label: $((count-failed))/$count successful"
}

create_protein_list() {
    local fasta_file="$1"
    local output_file="$2"
    
    grep '^>' "$fasta_file" | \
        sed 's/^>//' | \
        sed 's/sp|//' | \
        sed 's/tr|//' | \
        sed 's/|/_/g' | \
        sed 's/[[:space:]].*$//' | \
        sed 's/[,;:#]/_/g' > "$output_file"
}

fetch_sequences "$BAITS_FILE" "$BAITS_FASTA" "bait"
fetch_sequences "$CANDIDATES_FILE" "$CANDIDATES_FASTA" "candidate"

create_protein_list "$BAITS_FASTA" "${BAITS_FILE%.txt}_ap.txt"
create_protein_list "$CANDIDATES_FASTA" "${CANDIDATES_FILE%.txt}_ap.txt"

baits_seq=$(grep -c '^>' "$BAITS_FASTA" 2>/dev/null || echo "0")
candidates_seq=$(grep -c '^>' "$CANDIDATES_FASTA" 2>/dev/null || echo "0") 
step1_jobs=$((baits_seq + candidates_seq))
step2_jobs=$baits_seq

echo ""
echo "Baits: $baits_seq | Candidates: $candidates_seq"
[[ -s "$FAILED_IDS" ]] && echo "Failed: $(wc -l < $FAILED_IDS)"
echo "Created ${BAITS_FILE%.txt}_ap.txt and ${CANDIDATES_FILE%.txt}_ap.txt"
echo ""
echo "sbatch --array=1-$step1_jobs%10 step1_mmseqs.sh"
echo "sbatch --array=1-$step2_jobs%5 step2_prediction.sh"