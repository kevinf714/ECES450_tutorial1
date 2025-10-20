# ECES450 Tutorial 1: Microbiome Analysis with QIIME2

This repository contains the first tutorial for ECES450, focusing on microbiome data analysis using QIIME2. The project demonstrates a complete bioinformatics pipeline for analyzing 16S rRNA amplicon sequencing data from a cancer microbiome intervention study.

## Overview

This tutorial implements a comprehensive microbiome analysis workflow that includes:
- Data filtering and quality control
- Taxonomic classification
- Phylogenetic tree construction
- Alpha and beta diversity analysis
- Longitudinal statistical analysis

The analysis is based on the [QIIME2 Cancer Microbiome Intervention Tutorial](https://docs.qiime2.org/jupyterbooks/cancer-microbiome-intervention-tutorial/) and focuses on samples from the autoFMT (autologous fecal microbiota transplant) study.

## Project Structure

```
ECES450_tutorial1/
├── tutorial_1.sh              # Main analysis script
├── tutorial_submitter.sh      # SLURM job submission script
├── slurm-*.out               # SLURM job output logs
└── README.md                 # This file
```

## Prerequisites

- Access to a SLURM cluster with Singularity/Apptainer
- QIIME2 container image (`qiime_amplicon_2025.7.sif`)
- Internet connection for downloading reference data

## Quick Start

### 1. Configure the SLURM Job

Before running, update the following in `tutorial_submitter.sh`:
- Email address (line 4): Change to your Drexel email
- Account (line 6): Verify with your professor
- Resource requirements (lines 8-18): Adjust as needed

### 2. Submit the Job

```bash
sbatch tutorial_submitter.sh
```

### 3. Monitor Progress

Check job status and view output:
```bash
squeue -u $USER
tail -f slurm-<job_id>.out
```

## Analysis Pipeline

The tutorial is divided into 6 main parts:

### Part 1: Data Acquisition and Initial Filtering
- Downloads feature table and representative sequences
- Filters samples to include only autoFMT study participants
- Applies temporal filtering (10 days before to 70 days after cell transplant)
- Removes low-frequency features

### Part 2: Taxonomic Classification
- Downloads Greengenes classifier
- Assigns taxonomic information to ASV sequences
- Filters to phylum level, excluding chloroplasts and mitochondria
- Applies minimum sequence count threshold (10,000)

### Part 3: Phylogenetic Analysis
- Performs multiple sequence alignment using MAFFT
- Builds phylogenetic tree using FastTree
- Creates rooted phylogenetic tree

### Part 4: Quality Assessment
- Generates feature table summaries
- Creates alpha rarefaction plots (Shannon diversity)
- Performs beta diversity rarefaction analysis

### Part 5: Diversity Metrics
- Computes core phylogenetic diversity metrics
- Generates distance matrices and PCoA plots
- Calculates alpha diversity indices

### Part 6: Statistical Analysis
- Performs alpha diversity group significance testing
- Conducts longitudinal linear mixed-effects analysis
- Analyzes diversity changes relative to cell transplant and FMT

## Output Files

The analysis generates several QIIME2 artifacts and visualizations:

- **Feature tables**: `feature-table.qza`, `filtered-table-*.qza`
- **Sequences**: `rep-seqs.qza`, `filtered-sequences-*.qza`
- **Taxonomy**: `taxonomy.qza`
- **Phylogeny**: `phylogeny-align-to-tree-mafft-fasttree/`
- **Diversity metrics**: `diversity-core-metrics-phylogenetic/`
- **Visualizations**: `*.qzv` files for interactive viewing

## Viewing Results

QIIME2 visualizations can be viewed using:
```bash
qiime tools view <filename>.qzv
```

Or upload to [QIIME2 View](https://view.qiime2.org/) for web-based visualization.

## Resource Requirements

- **CPUs**: 32 cores
- **Memory**: 32 GB RAM
- **Time**: 15 minutes (adjustable)
- **Storage**: ~500 MB for intermediate files

## Troubleshooting

### Common Issues

1. **Permission errors**: Ensure you have write access to the working directory
2. **Memory issues**: Increase `--mem` parameter in SLURM script
3. **Timeout**: Increase `--time` parameter if job runs longer than expected
4. **Container errors**: Verify Singularity/Apptainer is properly configured

### Log Files

Check the SLURM output files (`slurm-*.out`) for detailed error messages and progress information.

## References

- [QIIME2 Documentation](https://docs.qiime2.org/)
- [Cancer Microbiome Intervention Tutorial](https://docs.qiime2.org/jupyterbooks/cancer-microbiome-intervention-tutorial/)
- [QIIME2 Forum](https://forum.qiime2.org/)

## Course Information

- **Course**: ECES450
- **Institution**: Drexel University
- **Tutorial**: 1
- **Focus**: Microbiome Bioinformatics

## License

This tutorial is for educational purposes as part of ECES450 coursework.
