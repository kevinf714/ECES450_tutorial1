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

## Code Explanation

### tutorial_submitter.sh - SLURM Job Configuration

This script configures and submits the microbiome analysis to a high-performance computing cluster:

#### SLURM Directives
```bash
#!/bin/bash
#SBATCH --mail-user=cnp68@drexel.edu
#SBATCH --account=eces450650prj
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --time=0:15:00
#SBATCH --mem=32GB
#SBATCH --partition=edu
```

**What each directive does:**
- `#!/bin/bash`: Uses bash shell for script execution
- `--mail-user`: Sends job notifications to your Drexel email
- `--account`: Specifies the billing account for compute resources
- `--nodes=1`: Requests 1 compute node
- `--ntasks=1`: Runs 1 task (the analysis script)
- `--cpus-per-task=32`: Allocates 32 CPU cores for parallel processing
- `--time=0:15:00`: Sets 15-minute time limit (format: hours:minutes:seconds)
- `--mem=32GB`: Allocates 32 GB of RAM
- `--partition=edu`: Uses the educational partition

#### Cleanup and Container Execution
```bash
/bin/rm -rf out_tmp* core-metrics-results

containerdir=/ECES450_tutorial1
SINGULARITYENV_containerdir=${containerdir} singularity exec --fakeroot --bind .:/${containerdir},${TMP}:/tmp,${TMP}:${TMP} /ifs/groups/eces450650Grp/containers/qiime_amplicon_2025.7.sif bash ${containerdir}/tutorial_1.sh
```

**What this does:**
- **Cleanup**: Removes old output files to start fresh
- **Container setup**: Defines working directory inside container
- **Singularity execution**: Runs the analysis inside a QIIME2 container with:
  - `--fakeroot`: Allows root privileges inside container
  - `--bind`: Mounts current directory and temp space
  - Container path: Points to the QIIME2 2025.7 container
  - Executes: `tutorial_1.sh` inside the container

### tutorial_1.sh - Main Analysis Pipeline

The main script performs 8 sequential analysis parts:

#### Part 1: Data Acquisition and Filtering (Lines 1-53)
```bash
# Download raw data
wget -O 'feature-table.qza' 'https://docs.qiime2.org/.../feature-table.qza'
wget -O 'rep-seqs.qza' 'https://docs.qiime2.org/.../rep-seqs.qza'

# Filter samples to autoFMT study only
qiime feature-table filter-samples \
  --i-table feature-table.qza \
  --m-metadata-file sample-metadata.tsv \
  --p-where 'autoFmtGroup IS NOT NULL' \
  --o-filtered-table autofmt-table.qza

# Temporal filtering (10 days before to 70 days after transplant)
qiime feature-table filter-samples \
  --i-table autofmt-table.qza \
  --p-where 'DayRelativeToNearestHCT BETWEEN -10 AND 70' \
  --o-filtered-table filtered-table-1.qza
```

#### Part 2: Taxonomic Classification (Lines 55-98)
```bash
# Download Greengenes classifier
wget -O 'gg-13-8-99-515-806-nb-classifier.qza' 'https://docs.qiime2.org/.../gg-13-8-99-515-806-nb-classifier.qza'

# Assign taxonomic names to sequences
qiime feature-classifier classify-sklearn \
  --i-classifier gg-13-8-99-515-806-nb-classifier.qza \
  --i-reads filtered-sequences-1.qza \
  --o-classification taxonomy.qza

# Filter to phylum level, exclude chloroplasts/mitochondria
qiime taxa filter-table \
  --i-table filtered-table-2.qza \
  --i-taxonomy taxonomy.qza \
  --p-include p__ \
  --p-exclude 'p__;,Chloroplast,Mitochondria' \
  --o-filtered-table filtered-table-3.qza
```

#### Part 3: Phylogenetic Analysis (Lines 101-109)
```bash
# Build evolutionary tree
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences filtered-sequences-2.qza \
  --output-dir phylogeny-align-to-tree-mafft-fasttree
```

#### Part 4: Quality Assessment (Lines 111-133)
```bash
# Check sampling depth adequacy
qiime diversity alpha-rarefaction \
  --i-table filtered-table-4.qza \
  --p-metrics shannon \
  --p-max-depth 33000 \
  --o-visualization shannon-rarefaction-plot.qzv

# Verify beta diversity stability
qiime diversity beta-rarefaction \
  --i-table filtered-table-4.qza \
  --p-metric braycurtis \
  --p-sampling-depth 10000 \
  --o-visualization braycurtis-rarefaction-plot.qzv
```

#### Part 5: Diversity Metrics (Lines 135-142)
```bash
# Calculate core diversity metrics
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny phylogeny-align-to-tree-mafft-fasttree/rooted_tree.qza \
  --i-table filtered-table-4.qza \
  --p-sampling-depth 10000 \
  --output-dir diversity-core-metrics-phylogenetic
```

#### Part 6: Statistical Analysis (Lines 144-170)
```bash
# Test group differences in diversity
qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity-core-metrics-phylogenetic/observed_features_vector.qza \
  --o-visualization alpha-group-sig-obs-feats.qzv

# Longitudinal analysis relative to cell transplant
qiime longitudinal linear-mixed-effects \
  --p-state-column DayRelativeToNearestHCT \
  --p-individual-id-column PatientID \
  --p-metric observed_features \
  --o-visualization lme-obs-features-HCT.qzv
```

#### Part 7: Advanced Visualization (Lines 172-210)
```bash
# Create UMAP projections
qiime diversity umap \
  --i-distance-matrix diversity-core-metrics-phylogenetic/unweighted_unifrac_distance_matrix.qza \
  --o-umap uu-umap.qza

# Generate interactive 3D plots
qiime emperor plot \
  --i-pcoa uu-umap.qza \
  --p-custom-axes week-relative-to-hct \
  --o-visualization uu-umap-emperor-w-time.qzv
```

#### Part 8: Genus-Level Analysis (Lines 212-259)
```bash
# Collapse to genus level
qiime taxa collapse \
  --i-table filtered-table-4.qza \
  --i-taxonomy taxonomy.qza \
  --p-level 6 \
  --o-collapsed-table genus-table.qza

# Create volatility plots showing genus changes over time
qiime longitudinal volatility \
  --i-table genus-rf-table.qza \
  --p-state-column week-relative-to-hct \
  --p-individual-id-column PatientID \
  --o-visualization volatility-plot-1.qzv
```

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
