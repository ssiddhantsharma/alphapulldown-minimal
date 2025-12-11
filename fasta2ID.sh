#!/bin/bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <fasta_file1> [fasta_file2] ..."
    exit 1
fi

extract_uniprot_ids() {
    local fasta_file="$1"
    local txt_file="${fasta_file%.fasta}.txt"
    
    [[ ! -f "$fasta_file" ]] && { echo "Error: $fasta_file not found"; return 1; }
    
    grep '^>' "$fasta_file" | \
        sed 's/^>//' | \
        sed -E 's/^(sp|tr)\|([A-Z0-9]+)\|.*/\2/' | \
        sed -E 's/^([A-Z0-9]+)(\s.*|$)/\1/' | \
        grep -E '^[A-Z0-9]{6,10}$' > "$txt_file"
    
    echo "Extracted $(wc -l < $txt_file) UniProt IDs to $txt_file"
}

for fasta_file in "$@"; do
    extract_uniprot_ids "$fasta_file"
done