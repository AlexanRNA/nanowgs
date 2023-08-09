#!/usr/bin/env Rscript 
# script to visualise the methylation at CTCF and TSS elements
# usage: modkit_plot_mod.R <inputfile>
# inputfile: the output of bedtools intersect of bedMethyl file and bed file with elements
# output: pdf file with the plot of the methylation at the elements and the coverage
# author: @alexanRNA

args = commandArgs(TRUE)

###### load libraries ##########
library(readr)
#library(rtracklayer)
library(ggplot2)


################################
# laod the data in
filepath = args[1]
filename = basename(filepath)


######## define the functions #################################################
# Function to compute the mean methylation level at a given relative position #
###############################################################################

compute_mean_methylation <- function(data) {
  
  data$relpos <- ifelse(data$X6 == "+",data$X2 - (data$X20 + data$X21)/2,
                            (data$X20 + data$X21)/2 - data$X2)
  
  # Compute the mean methylation level for each relative position
  meanmeth <- data.frame(c(by(data = data, INDICES = data$relpos, FUN = function(x) mean(x$X5*x$X11, na.rm = TRUE)/mean(x$X5, na.rm= T))))
  #  Set the relative position column as an integer
  meanmeth$relpos <- as.integer(rownames(meanmeth))
  # Rename the first column to "frac"
  colnames(meanmeth)[1] <- "frac"
  
  # compute mean coverage
  meancov <- data.frame(c(by(data = data, INDICES = data$relpos, FUN = function(x)  mean(x$X5, na.rm = TRUE))))
  colnames(meancov)[1] <- "meancov"
  meanmeth$meancov <- meancov$meancov
  
  return(meanmeth)
}


#function to plot the methylation
plot_methylation <- function(data,name,date,mod, sample){
  p1 <- ggplot(data = data, mapping = aes(x = relpos)) + geom_point(aes(y = frac, color = "frac")) 
  
  p1 <- p1 + theme_minimal() + labs(x = paste0("position relative to ", name), y = paste0(mod," methylation (%)") )
  ggsave(filename = paste0(date,"_",sample, "_",name,"_",mod,".pdf"), plot = p1)
  p1
  p2 <-  ggplot(data = data, mapping = aes(x = relpos)) + geom_point(aes(y = meancov, color = "coverage"))  + theme_minimal()
  #p2
  ggsave(filename = paste0(date,"_",sample, "_",name,"_",mod,"_coverage.pdf"), plot = p2)
}


# specify the date
date <- Sys.Date()
date <- format(date, "%Y%m%d")

sample <- sub("^(.*?)__.*$", "\\1", filename)


# Check if the input comes from m6A or 5mC
contains_m6A <- grepl("m6A", filename)
contains_5mC <- grepl("5mC", filename)
contains_5hmC <- grepl("5hmC", filename)

mod <- ""
# Print the result
if (contains_m6A) {
  mod <- "m6A"
} else if (contains_5mC) {
  mod <- "5mC" 
} else if (contains_5hmC) {
  mod <- "5hmC"
} else {
  mod <- "othermod"
}

# Check if input comes from TSS or CTCF

contains_TSS <- grepl("TSS", filename)
contains_CTCF <- grepl("CTCF", filename)

element <- ""
# Print the result
if (contains_TSS) {
  element <- "TSS"
} else if (contains_CTCF) {
  element <- "CTCF" 
} else {
  element <- "othermod"
}


#### run the functions
inputdata <- read_tsv(file = filepath , col_names = F)
meanmeth <- compute_mean_methylation(inputdata)
plot_methylation(meanmeth,element,date, mod, sample)


