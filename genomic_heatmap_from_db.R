source("genomicHeatmapMaker.R")

#' set all argumentgs for the script
#' @return list of argumentgs
#' @example set_args()
#'          set_args(c("--ref_genome", "mm9"))
#' Rscript genomic_heatmap_from_db.R --ref_genome hg19 hs.csv
#' Rscript genomic_heatmap_from_db.R --ref_genome mm9 mm.csv
#'
set_args <- function(...) {
    library(argparse, quietly=TRUE)
    parser <- ArgumentParser(description="Make genomic heatmap for sites from database")
    parser$add_argument("sample_gtsp", nargs='?',
                        default='samples.csv',
                        help="csv file with sampleName,GTSP columns such as GTSP0657-1,GTSP0657")
    parser$add_argument("-o", "--output_dir", type="character",
                        default="heatmap_output",
                        help="output folder where genomic heat maps files will be saved")
    parser$add_argument("-f", "--ref_genome", type="character",
                        default="hg18", 
                        help="reference genome used for all samples")
    parser$add_argument("-s", "--sites_group", type="character",
                        default="intsites_miseq.read", 
                        help="which group to use for connection")
    
    args <- parser$parse_args(...)
    
    return(args)
}
##set_args()
args <- set_args()
##args <- set_args(c("-f", "mm9", "mouse.csv"))
print(args)

csvfile <- args$sample_gtsp
if( ! file.exists(csvfile) ) stop(csvfile, "not found")
sampleName_GTSP <- read.csv(csvfile)
stopifnot(all(c("sampleName", "GTSP") %in% colnames(sampleName_GTSP)))
message("\nGenerating report from the following sets")
print(sampleName_GTSP)

load_genome <- function(referenceGenome=args$ref_genome) {
    suppressMessages(library(BSgenome))
    UCSCname <- grep(referenceGenome, installed.genomes(), value=TRUE)
    if( length(UCSCname)!=1 ) stop(referenceGenome, " matching ",
                  paste(UCSCname, collapse=" ") )
    message("\nLoading ", UCSCname, "\n")
    suppressMessages(library(UCSCname, character.only=TRUE))
}
load_genome(args$ref_genome)

dbConn <- dbConnect(MySQL(), group=args$sites_group)
info <- dbGetInfo(dbConn)
dbConn <- src_sql("mysql", dbConn, info = info)

unlink(args$output_dir, recursive=TRUE,  force=TRUE)

referenceGenome <- args$ref_genome
output_dir <- args$output_dir
connection <- dbConn

make_heatmap(sampleName_GTSP, args$ref_genome, args$output_dir, dbConn)

