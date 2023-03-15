#!/usr/bin/env Rscript 
args = commandArgs(TRUE)

library(ggplot2)
library(tidyverse)
library(gridExtra)

#############
# Deletions #
#############
f <- args[1]
dat <- read.delim(f, header=F, na.strings="", colClasses="character")
dat$donor <- unlist(strsplit(f,split=".",fixed=T))[1]
dels <- dat


dels$V1 <- as.numeric(dels$V1)
dels$donor <- as.character(dels$donor)
dels$donor <- as.factor(dels$donor)
dels$sampleid<- str_split(dels$donor, '_', simplify = TRUE)[,2]

# as lines
deletions <- dels %>% 
  filter(V1>-1000) %>%
  ggplot(aes(x=V1, color=donor)) +
  geom_line(aes(y=..count..), stat="bin",binwidth=7, lwd=0.5, show.legend = FALSE)+
  xlab("Size (bp)") + ylab("Count") + ggtitle("Deletions under 1 000 bp")+
  theme_minimal() 

# as counts
#deletions over 1000, but less than 10 000
deletions_large <- dels %>% 
  filter(V1< -1000 ) %>%
  filter(V1>-10000) %>%
  ggplot(aes(x=V1, color=donor)) + 
  geom_line(aes(y=..count..), stat="bin",binwidth=500, show.legend = FALSE)+
  xlab("Size (bp)") + ylab("Count") + ggtitle("Deletions between 1 000-10 000 bp")+
  theme_minimal()


####################
#insertions ########
####################

f <- args[2]
dat <- read.delim(f, header=F, na.strings="", colClasses="character")
dat$donor <- unlist(strsplit(f,split=".",fixed=T))[1]
ins <- dat

ins$donor <- as.character(ins$donor)
ins$V1 <- as.numeric(ins$V1)
ins$donor <- as.factor(ins$donor)
ins$sampleid<- str_split(ins$donor, '_', simplify = TRUE)[,2]

#as line
insertions <- ins %>% 
  filter(V1<1000) %>%
  ggplot(aes(x=V1, color=donor)) +
  geom_line(aes(y=..count..), stat="bin",binwidth=7, alpha=.7, show.legend = FALSE)+
  xlab("Size (bp)") + ylab("Count") + ggtitle("Insertions under 1 000 bp")+
  theme_minimal()

insertions_large <- ins %>% 
  filter(V1>1000 ) %>%
  filter(V1<10000) %>%
  ggplot(aes(x=V1, color=donor)) +
  geom_line(aes(y=..count..), stat="bin",binwidth=500, alpha=.7, show.legend = FALSE)+
  xlab("Size (bp)") + ylab("Count") + ggtitle("Insertions between 1 000-10 000 bp")+
  theme_minimal()

########
# save #
########

all <- arrangeGrob(deletions,insertions,deletions_large,insertions_large, ncol = 2)

ggsave(plot = all, args[3], dpi=800, device = "pdf", width = 10, height = 6)