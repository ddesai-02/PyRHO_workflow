# PyRHO_workflow

## 1. VCF Prep
Extracts genotypes and scaffolds population VCF file.

## 2. MSMC to Table
Creates a lookup table using msmc, mutation rate, and sample size.

## 3. Find Optimal Hyperparameters
Finds settings for the main hyperparameters of pyrho: the window size and the smoothness penalty.

## 4. Optimize
After computing a lookup table using and choosing reasonable hyperparameters this infers recombination maps from the real data.

## 5. Convert
Converts to CM/Mb and averages by specified window.
