#do tutorial here
#PART 1
#get the feature table data
wget \
  -O 'feature-table.qza' \
  'https://docs.qiime2.org/jupyterbooks/cancer-microbiome-intervention-tutorial/data/030-tutorial-downstream/010-filtering/feature-table.qza'

#download the ASV sequences
wget \
  -O 'rep-seqs.qza' \
  'https://docs.qiime2.org/jupyterbooks/cancer-microbiome-intervention-tutorial/data/030-tutorial-downstream/010-filtering/rep-seqs.qza'

#summary of the tables
qiime feature-table summarize \
  --i-table feature-table.qza \
  --m-sample-metadata-file sample-metadata.tsv \
  --o-visualization table.qzv
qiime feature-table tabulate-seqs \
  --i-data rep-seqs.qza \
  --o-visualization rep-seqs.qzv

#remove samples that aren't part of autoFMT study
qiime feature-table filter-samples \
  --i-table feature-table.qza \
  --m-metadata-file sample-metadata.tsv \
  --p-where 'autoFmtGroup IS NOT NULL' \
  --o-filtered-table autofmt-table.qza

#summarize feature table again
qiime feature-table summarize \
  --i-table autofmt-table.qza \
  --m-sample-metadata-file sample-metadata.tsv \
  --o-visualization autofmt-table-summ.qzv

#filter down to ten days prior to cell transplant to 70 days after
qiime feature-table filter-samples \
  --i-table autofmt-table.qza \
  --m-metadata-file sample-metadata.tsv \
  --p-where 'DayRelativeToNearestHCT BETWEEN -10 AND 70' \
  --o-filtered-table filtered-table-1.qza

#filter out features if they don't occur in at least two samples
qiime feature-table filter-features \
  --i-table filtered-table-1.qza \
  --p-min-samples 2 \
  --o-filtered-table filtered-table-2.qza

#additional filtering
qiime feature-table filter-seqs \
  --i-data rep-seqs.qza \
  --i-table filtered-table-2.qza \
  --o-filtered-data filtered-sequences-1.qza


#PART2
#get taxomic classification
wget \
  -O 'gg-13-8-99-515-806-nb-classifier.qza' \
  'https://docs.qiime2.org/jupyterbooks/cancer-microbiome-intervention-tutorial/data/030-tutorial-downstream/020-taxonomy/gg-13-8-99-515-806-nb-classifier.qza'

#use classifier to assign taxonomic info to ASV sequences
qiime feature-classifier classify-sklearn \
  --i-classifier gg-13-8-99-515-806-nb-classifier.qza \
  --i-reads filtered-sequences-1.qza \
  --o-classification taxonomy.qza

#generate human readable summary of annotations
qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv

#use include and exclude to only keep phylum level tanomony assignments
qiime taxa filter-table \
  --i-table filtered-table-2.qza \
  --i-taxonomy taxonomy.qza \
  --p-mode contains \
  --p-include p__ \
  --p-exclude 'p__;,Chloroplast,Mitochondria' \
  --o-filtered-table filtered-table-3.qza

#exclude anything with less than 10,000 sequences
qiime feature-table filter-samples \
  --i-table filtered-table-3.qza \
  --p-min-frequency 10000 \
  --o-filtered-table filtered-table-4.qza

#remove everything that wasn't passed
qiime feature-table filter-seqs \
  --i-data rep-seqs.qza \
  --i-table filtered-table-4.qza \
  --o-filtered-data filtered-sequences-2.qza

#generate the bar plots
qiime taxa barplot \
  --i-table filtered-table-4.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization taxa-bar-plots-1.qzv


#PART 3
#pipeline to qiime 2 which strings together simple operations
#does a multiple sequence alignment using maft
#filter highly variable positions from the alignment
#build unrooted phylogenetic tree
#add a root
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences filtered-sequences-2.qza \
  --output-dir phylogeny-align-to-tree-mafft-fasttree

#PART 4
#create summary of most recent feature
qiime feature-table summarize \
  --i-table filtered-table-4.qza \
  --m-sample-metadata-file sample-metadata.tsv \
  --o-visualization filtered-table-4-summ.qzv

#use alpha rarefaction plot to make sure sampling depth is stabalized over coverage
qiime diversity alpha-rarefaction \
  --i-table filtered-table-4.qza \
  --p-metrics shannon \
  --m-metadata-file sample-metadata.tsv \
  --p-max-depth 33000 \
  --o-visualization shannon-rarefaction-plot.qzv

#check that beta diversity is stable
qiime diversity beta-rarefaction \
  --i-table filtered-table-4.qza \
  --p-metric braycurtis \
  --p-clustering-method nj \
  --p-sampling-depth 10000 \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization braycurtis-rarefaction-plot.qzv

#PART 5
#Computing Diversity Metrics
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny phylogeny-align-to-tree-mafft-fasttree/rooted_tree.qza \
  --i-table filtered-table-4.qza \
  --p-sampling-depth 10000 \
  --m-metadata-file sample-metadata.tsv \
  --output-dir diversity-core-metrics-phylogenetic

#PART 6
qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity-core-metrics-phylogenetic/observed_features_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization alpha-group-sig-obs-feats.qzv

qiime longitudinal linear-mixed-effects \
  --m-metadata-file sample-metadata.tsv diversity-core-metrics-phylogenetic/observed_features_vector.qza \
  --p-state-column DayRelativeToNearestHCT \
  --p-individual-id-column PatientID \
  --p-metric observed_features \
  --o-visualization lme-obs-features-HCT.qzv

qiime longitudinal linear-mixed-effects \
  --m-metadata-file sample-metadata.tsv diversity-core-metrics-phylogenetic/observed_features_vector.qza \
  --p-state-column day-relative-to-fmt \
  --p-individual-id-column PatientID \
  --p-metric observed_features \
  --o-visualization lme-obs-features-FMT.qzv

qiime longitudinal linear-mixed-effects \
  --m-metadata-file sample-metadata.tsv diversity-core-metrics-phylogenetic/observed_features_vector.qza \
  --p-state-column day-relative-to-fmt \
  --p-group-columns autoFmtGroup \
  --p-individual-id-column PatientID \
  --p-metric observed_features \
  --o-visualization lme-obs-features-treatmentVScontrol.qzv


#PART 7
qiime diversity umap \
  --i-distance-matrix diversity-core-metrics-phylogenetic/unweighted_unifrac_distance_matrix.qza \
  --o-umap uu-umap.qza
qiime diversity umap \
  --i-distance-matrix diversity-core-metrics-phylogenetic/weighted_unifrac_distance_matrix.qza \
  --o-umap wu-umap.qza

qiime metadata tabulate \
  --m-input-file sample-metadata.tsv uu-umap.qza diversity-core-metrics-phylogenetic/faith_pd_vector.qza diversity-core-metrics-phylogenetic/evenness_vector.qza diversity-core-metrics-phylogenetic/shannon_vector.qza \
  --o-visualization expanded-metadata-summ.qzv

qiime taxa barplot \
  --i-table filtered-table-4.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file sample-metadata.tsv uu-umap.qza diversity-core-metrics-phylogenetic/faith_pd_vector.qza diversity-core-metrics-phylogenetic/evenness_vector.qza diversity-core-metrics-phylogenetic/shannon_vector.qza \
  --o-visualization taxa-bar-plots-2.qzv

qiime emperor plot \
  --i-pcoa uu-umap.qza \
  --m-metadata-file sample-metadata.tsv uu-umap.qza diversity-core-metrics-phylogenetic/faith_pd_vector.qza diversity-core-metrics-phylogenetic/evenness_vector.qza diversity-core-metrics-phylogenetic/shannon_vector.qza \
  --p-custom-axes week-relative-to-hct \
  --o-visualization uu-umap-emperor-w-time.qzv
qiime emperor plot \
  --i-pcoa wu-umap.qza \
  --m-metadata-file sample-metadata.tsv uu-umap.qza diversity-core-metrics-phylogenetic/faith_pd_vector.qza diversity-core-metrics-phylogenetic/evenness_vector.qza diversity-core-metrics-phylogenetic/shannon_vector.qza \
  --p-custom-axes week-relative-to-hct \
  --o-visualization wu-umap-emperor-w-time.qzv
qiime emperor plot \
  --i-pcoa diversity-core-metrics-phylogenetic/unweighted_unifrac_pcoa_results.qza \
  --m-metadata-file sample-metadata.tsv uu-umap.qza diversity-core-metrics-phylogenetic/faith_pd_vector.qza diversity-core-metrics-phylogenetic/evenness_vector.qza diversity-core-metrics-phylogenetic/shannon_vector.qza \
  --p-custom-axes week-relative-to-hct \
  --o-visualization uu-pcoa-emperor-w-time.qzv
qiime emperor plot \
  --i-pcoa diversity-core-metrics-phylogenetic/weighted_unifrac_pcoa_results.qza \
  --m-metadata-file sample-metadata.tsv uu-umap.qza diversity-core-metrics-phylogenetic/faith_pd_vector.qza diversity-core-metrics-phylogenetic/evenness_vector.qza diversity-core-metrics-phylogenetic/shannon_vector.qza \
  --p-custom-axes week-relative-to-hct \
  --o-visualization wu-pcoa-emperor-w-time.qzv


#PART 8
qiime taxa collapse \
  --i-table filtered-table-4.qza \
  --i-taxonomy taxonomy.qza \
  --p-level 6 \
  --o-collapsed-table genus-table.qza

qiime feature-table filter-features-conditionally \
  --i-table genus-table.qza \
  --p-prevalence 0.1 \
  --p-abundance 0.01 \
  --o-filtered-table filtered-genus-table.qza

qiime feature-table relative-frequency \
  --i-table filtered-genus-table.qza \
  --o-relative-frequency-table genus-rf-table.qza

qiime longitudinal volatility \
  --i-table genus-rf-table.qza \
  --p-state-column week-relative-to-hct \
  --m-metadata-file sample-metadata.tsv uu-umap.qza diversity-core-metrics-phylogenetic/faith_pd_vector.qza diversity-core-metrics-phylogenetic/evenness_vector.qza diversity-core-metrics-phylogenetic/shannon_vector.qza \
  --p-individual-id-column PatientID \
  --p-default-group-column autoFmtGroup \
  --o-visualization volatility-plot-1.qzv

qiime longitudinal volatility \
  --i-table genus-rf-table.qza \
  --p-state-column week-relative-to-fmt \
  --m-metadata-file sample-metadata.tsv uu-umap.qza diversity-core-metrics-phylogenetic/faith_pd_vector.qza diversity-core-metrics-phylogenetic/evenness_vector.qza diversity-core-metrics-phylogenetic/shannon_vector.qza \
  --p-individual-id-column PatientID \
  --p-default-group-column autoFmtGroup \
  --o-visualization volatility-plot-2.qzv

qiime longitudinal feature-volatility \
  --i-table filtered-genus-table.qza \
  --m-metadata-file sample-metadata.tsv uu-umap.qza diversity-core-metrics-phylogenetic/faith_pd_vector.qza diversity-core-metrics-phylogenetic/evenness_vector.qza diversity-core-metrics-phylogenetic/shannon_vector.qza \
  --p-state-column week-relative-to-hct \
  --p-individual-id-column PatientID \
  --output-dir longitudinal-feature-volatility

qiime longitudinal feature-volatility \
  --i-table filtered-genus-table.qza \
  --m-metadata-file sample-metadata.tsv uu-umap.qza diversity-core-metrics-phylogenetic/faith_pd_vector.qza diversity-core-metrics-phylogenetic/evenness_vector.qza diversity-core-metrics-phylogenetic/shannon_vector.qza \
  --p-state-column week-relative-to-fmt \
  --p-individual-id-column PatientID \
  --output-dir longitudinal-feature-volatility-2
