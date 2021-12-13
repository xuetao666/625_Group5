#!/bin/bash


#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mem=1G
#SBATCH --cpus-per-task=1


R CMD BATCH --no-save --no-restore LASSO.R