# PyRHO_workflow

A SLURM pipeline that estimates fine-scale recombination maps from unphased population genotype data with [pyrho](https://github.com/popgenmethods/pyrho). It converts the maps to cM/Mb, masks artefacts and averages the rates into fixed-size windows.

## Requirements

- A SLURM cluster. The scripts use module names from the Digital Research Alliance of Canada clusters (`bcftools`, `python/3.11`). Change `#SBATCH --account=def-shaferab` to your own allocation.
- Python 3 with pyrho installed in a virtual environment. Scripts 02–04 activate `~/ENV`; edit the `source ~/ENV/bin/activate` line if yours is elsewhere.

## Inputs

- A VCF of unrelated individuals from one population, filtered to biallelic SNPs.
- An MSMC demographic history for the same population.
- A per-site, per-generation mutation rate.

## Setup

Put all scripts in the working directory and fill in `config.sh`:

| Variable | Meaning |
|---|---|
| `VCF` | Population VCF |
| `SIZE` | Haploid sample size (2 × number of individuals) |
| `MU` | Mutation rate per site per generation |
| `MSMC` | MSMC output file |
| `WINDOW`, `BPEN` | pyrho `--windowsize` and `--blockpenalty`, chosen from step 3 optimize |
| `WIN_BP` | Window size (bp) for the final averaged map (default 50 kb) |

## Running the pipeline

Run each step after the previous one has finished:

```bash
sbatch 01.vcf_prep.sh
sbatch 02.table_MSMC.sh
sbatch 03.hyperparam.sh     # then set WINDOW and BPEN in config.sh
sbatch 04.optimize.sh       # first set --array=1-N, where N = wc -l < scaff_names
sbatch 05.convert.sh
sbatch 06.mask.sh
```

### 1. VCF prep (`01.vcf_prep.sh`)
Strips the VCF to genotypes only and splits it into one VCF per scaffold. Writes `<scaffold>.vcf` and `scaff_names`, a list of the scaffolds with at least one SNP.

### 2. Lookup table (`02.table_MSMC.sh`)
Builds pyrho's two-locus likelihood lookup table for the sample size, mutation rate and MSMC demography.

### 3. Hyperparameters (`03.hyperparam.sh`)
Simulates data under the MSMC demography and reports how well each combination of window size and block penalty recovers the simulated maps. Pick the best-performing combination and set `WINDOW` and `BPEN` in `config.sh`. `--ploidy 2` is used throughout because the genotypes are unphased.

### 4. Optimize (`04.optimize.sh`)
Infers a recombination map for each scaffold, one SLURM array task per line of `scaff_names`. Writes `<scaffold>.rmap` with columns start, end and rate, where rate is r per bp per generation.

### 5. Convert and edge threshold (`05.convert.sh`)
- Converts each map to cM/Mb, writing `<scaffold>.rmapCM` with columns start, end, rate (cM/Mb), cumulative map position (cM) and interval width (bp).
- Masks recombination spikes with `mask.awk`: intervals above 100 cM/Mb plus the 50 SNPs on either side.
- Computes the edge-masking threshold as the 99th percentile of 1-Mb window rates on the spike-masked map. Writes it to `edge_threshold.txt`, and the 1-Mb windows to `pyrho_spikemasked_1Mb.txt`.

### 6. Mask and window (`06.mask.sh`)
- Repeats the spike masking.
- Masks the first and last pyrho block of each scaffold when its rate exceeds the edge threshold.
- Averages the remaining sequence into windows of `WIN_BP`.

Masked intervals are dropped and treated as missing data, not as zero recombination. Each window's rate is the length-weighted mean over its unmasked sequence. Windows start at 0 and windows with no unmasked sequence are omitted.

## Outputs

| File | Contents |
|---|---|
| `pyrho_Urs_<WIN_KB>kb.txt` | Windowed map: label (`Pyrho`), scaffold, window start, window end, mean rate (cM/Mb) |
| `pyrho_masked.bed` | Unmasked pyrho intervals: scaffold, start, end, rate (cM/Mb). Used for genomic-feature analyses |
| `edge_mask.log` | Scaffold edge blocks that were masked |

The 06 SLURM log also reports the masked sequence (Mb and %) and the genome-wide length-weighted mean rate over unmasked sequence.

## Files

| File | Purpose |
|---|---|
| `config.sh` | Shared settings |
| `01`–`06` | Pipeline steps |
| `convert_Output_pyrho_cM_Mb.awk` | Converts pyrho rates to cM/Mb and cumulative cM |
| `mask.awk` | Spike masking |
| `Rec_windows.py` | Length-weighted window averages; masked gaps are treated as missing data |
