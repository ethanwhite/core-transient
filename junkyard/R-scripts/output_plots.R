#----------------------------------------------------------------------------------*
# ---- SET-UP ----
#==================================================================================*

# Libraries:

library(reshape2)
library(plyr)
library(ggplot2)
library(gridExtra)
library(wesanderson)

# Get files:

occProp = read.csv('output/occProp.csv')
nTime = read.csv('output/nTime.csv')
outSummary = read.csv('data_source_table.csv')
ctSummary = read.csv('output/tabular_data/core-transient_summary.csv')
modeSummary = read.csv('output/tabular_data/ct_mode_summary.csv')

source('scripts/R-Scripts/core-transient_functions.R')

#----------------------------------------------------------------------------------*
# ---- Stacked barplots ----
#==================================================================================*
# Note: Uses the average of the proportions at a given site.

props = read.csv('output/tabular_data/summary_by_SysTaxa.csv')

# Get the necessary columns and rename:

props = props[,c(1,2,3,5)]
names(props)[3:4] = c('core','trans')

# Make an "other" column representing neither core nor transient species: 

props$other = 1 - props$core - props$trans

# Change to long format and rename:

props = melt(props, id.vars = c('variable','group'))
names(props)[3:4] = c('class','prop')

# Plot by system:

ctPropSystemPlot = ggplot(data=props[props$variable == 'system',],
  aes(x=group, y=prop, fill=class)) +
  geom_bar(stat="identity") +
  geom_bar(stat="identity") +
  scale_fill_manual(values = palette(wes.palette(5,'FantasticFox')),
                    labels = c('Core','Transient','Other'))+
  xlab('Environmental System')+
  ylab('Proportion of species')+
  ggtitle(bquote(bold('Proportional distribution of core
and transient species by system')))+
  theme_CT_NoGrid() 
  
# Plot by taxa:

ctPropTaxaPlot = ggplot(data=props[props$variable == 'taxa',],
  aes(x=group, y=prop, fill=class)) +
  geom_bar(stat="identity") +
  scale_fill_manual(values = palette(wes.palette(5,'FantasticFox')),
                    labels = c('Core','Transient','Other'))+
  xlab('Taxonomic group')+
  ylab('Proportion of species')+
  ggtitle(bquote(bold('Proportional distribution of core and
transient species by taxonomic group')))+
  theme_CT_NoGrid() + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Write output:

pdf('output/plots/ctPropSystem.pdf', width = 8, height = 8)
ctPropSystemPlot
dev.off()

pdf('output/plots/ctPropTaxa.pdf', width = 8, height = 8)
ctPropTaxaPlot
dev.off()

#----------------------------------------------------------------------------------*
# ---- Core-transient histograms  ----
#==================================================================================*
# This script creates a single pdf with all histograms.

ct = read.csv('output/tabular_data/core-transient_summary.csv')

# Run a for loop to create plots for each site:

site = ct[,'site']
outPlots = list()

for(i in site){
  tryCatch({
    outPlots[[i]] = ctHist(i)},
    error = function(e){
      cat('ERROR for site',site[i],':', conditionMessage(e), '\n')
    })
}

# Write plots to file:

pdf('output/plots/CT_histograms.pdf', 
    width = 6.5, height = 5.5, onefile = T)
outPlots
dev.off()

#----------------------------------------------------------------------------------*
# ---- SUMMARIZING BY TAXA AND SYSTEM (TERRESTRIAL, AQUATIC, MARINE)  ----
#==================================================================================*

# Set-up

ct = read.csv('output/tabular_data/core-transient_summary.csv')

ctSub = ct[,c(1:5)]

occSysTaxa = merge(ctSub, occProp, by = 'site',all = T)
occSysTaxa = na.omit(occSysTaxa)

#----------------------------------------------------------------------------------*
# ---- A little bit of exploration ... time effect? ----
#----------------------------------------------------------------------------------*
# Plot of species occurence by the number of time intervals

ggplot(occSysTaxa, aes(x = nTime, y = occ, color = taxa, shape = system)) +
  geom_point()+
  scale_shape_manual(values=c(15,16,17))+
  xlab('Number of time intervals')+
  ylab('Proportion of occurences')+
  ggtitle('Occurences by time\n(points = species at a given site, n = 16303)')+
  theme_CT_NoGrid() + 
  theme(title = element_text(size=16, vjust = 3))

# How much of the variation at a given site is explained by time (i.e., do sp occurences
# become more dispersed with increased time samples?)?

ost2 = ddply(occSysTaxa, .(site, system, taxa, nTime), 
             summarize, dOcc = mean(abs(.5-occ)))

ggplot(ost2, aes(x = nTime, y = dOcc, color = taxa, shape = system)) +
  geom_point()+
  scale_shape_manual(values=c(15,16,17))+
  xlab('Number of time intervals')+
  ylab('Site-level bimodality')+
  ggtitle('Bimodality by time\n(points = sites, n = 539)')+
  theme_CT_NoGrid() + 
  theme(title = element_text(size=16, vjust = 3))

# How much can the existence of core or transient species be explained by the
# number of time intervals?

coreOrTransFun = function(x) length(x)/length(x)

ostCT = ddply(occSysTaxa, .(site, system, taxa, nTime), summarize, 
              ct = length(occ[occ>=2/3|occ<=1/3])/length(occ))

ostC = ddply(occSysTaxa, .(site, system, taxa, nTime), summarize, 
             ct = length(occ[occ>=2/3])/length(occ))

ostT = ddply(occSysTaxa, .(site, system, taxa, nTime), summarize, 
             ct = length(occ[occ<=1/3])/length(occ))

# How much can bimodality  be explained by the
# number of time intervals?

bimodSysTax = ddply(ct, .(site, system, taxa, nTime), 
                    summarize, bm = mean(bimodal))

ggplot(ct, aes(x = nTime, y = bimodal, color = taxa, shape = system)) +
  geom_point()+
  scale_shape_manual(values=c(15,16,17))+
  xlab('Number of time intervals')+
  ylab('Mean absolute difference between\n0.5 and proportional occurence')+
  ggtitle('Variation in occurences by time\n(points = sites, n = 539)')+
  theme_CT_NoGrid() + 
  theme(title = element_text(size=16, vjust = 3))

#----------------------------------------------------------------------------------*
# ---- Plotting bimodality by system and taxa ----
#----------------------------------------------------------------------------------*

# Bimodality by system:

bimodSys = ddply(ct, .(system), summarize, 
                 mean_bimod = mean(bimodal),
                 sd_bimod = sd(bimodal),
                 se_bimod = se(bimodal),
                 n_sites = length(bimodal))

# Bimodality by taxa:

bimodTaxa = ddply(ct, .(taxa), summarize, 
                  mean_bimod = mean(bimodal),
                  sd_bimod = sd(bimodal),
                  se_bimod = se(bimodal),
                  n_sites = length(bimodal))

# Plot bimodality by system

ymin = bimodSys$mean_bimod - bimodSys$se_bimod
ymax = bimodSys$mean_bimod + bimodSys$se_bimod

bimodSys_plot = ggplot(bimodSys, aes(x = system, y = mean_bimod)) +
  geom_point(size = 3)+
  geom_errorbar(aes(ymin = ymin, ymax = ymax), width = .1) + 
  geom_text(aes(system, ymax+.03),label = as.character(bimodSys$n_sites)) +
  ylim(0.2,.7)+
  xlab('System')+
  ylab('Bimodality')+
  ggtitle(bquote(atop(bold('Bimodality by system')))) +
  theme_CT_Grid()

pdf('output/plots/bimodality_by_system.pdf', width = 7, height = 6)
bimodSys_plot
dev.off()

# Plot bimodality by taxanomic class

ymin = bimodTaxa$mean_bimod - bimodTaxa$se_bimod
ymax = bimodTaxa$mean_bimod + bimodTaxa$se_bimod

bimodTaxa_plot = ggplot(bimodTaxa, aes(x = taxa, y = mean_bimod)) +
  geom_point(size = 2) + 
  geom_errorbar(aes(ymin = ymin,
                    ymax = ymax),
                width = .15) + 
  geom_text(aes(taxa, ymax+.03),label = as.character(bimodTaxa$n_sites)) +
  ylim(0,.65) +
  xlab('Taxonomic group')+
  ylab('Bimodality')+
  ggtitle(bquote(bold('Bimodality by taxanomic group')))+
  theme_CT_Grid()
  
pdf('output/plots/bimodality_by_taxa.pdf', width = 7, height = 6.5)
bimodTaxa_plot
dev.off()

#----------------------------------------------------------------------------------*
# ---- Plotting proportion core and transient by system and taxa ----
#----------------------------------------------------------------------------------*

# Create frames summarizing core and transient by system and taxa:

propCoreSys = ddply(ct, .(system), summarize, 
                    mean = mean(prop.core),
                    sd = sd(prop.core),
                    se = se(prop.core),
                    n_sites = length(prop.core))
propCoreSys = na.omit(propCoreSys)
propCoreSys$ct = rep('Core', length(propCoreSys[,1]))

propTransSys = ddply(ct, .(system), summarize, 
                     mean = mean(prop.trans),
                     sd = sd(prop.trans),
                     se = se(prop.trans),
                     n_sites = length(prop.trans))
proTransSys = na.omit(propTransSys)
propTransSys$ct = rep('Transient', length(propTransSys[,1]))

propCoreTaxa = ddply(ct, .(taxa), summarize, 
                     mean = mean(prop.core),
                     sd = sd(prop.core),
                     se = se(prop.core),
                     n_sites = length(prop.core))
propCoreTaxa = na.omit(propCoreTaxa)
propCoreTaxa$ct = rep('Core', length(propCoreTaxa[,1]))

propTransTaxa = ddply(ct, .(taxa), summarize, 
                      mean = mean(prop.trans),
                      sd = sd(prop.trans),
                      se = se(prop.trans),
                      n_sites = length(prop.trans))
propTransTaxa = na.omit(propTransTaxa)
propTransTaxa$ct = rep('Trans', length(propTransTaxa[,1]))

# Bind frames:

propCTSys = rbind(propCoreSys, propTransSys)

propCTTaxa = rbind(propCoreTaxa, propTransTaxa)

# System plot:

limits =  aes(ymax = mean + se, ymin = mean - se)

ctSys_plot = ggplot(propCTSys, aes(x = system, y = mean, color = ct)) +
  geom_point(size = 2) + 
  geom_errorbar(limits,width = .15) + 
  scale_x_discrete(breaks= c('Aquatic','Marine','Terrestrial'), 
                   labels=c(bquote(atop('Aquatic','n = 11')),
                            bquote(atop('Marine','n = 444')),
                            bquote(atop('Terrestrial','n = 84')))) +
  ylim(0,.7) +
  xlab('System')+
  ylab('Proportion of species')+
  ggtitle(bquote(bold('Proportion of core and transient
                      species by system')))+
  theme_CT_Grid()+
  theme(axis.text.x = element_text(size=14, color = 1, vjust = 1, hjust = 1),
        axis.text.y = element_text(size=12, color = 1, hjust = 1),
        title = element_text(vjust = 2.5),
        plot.margin = unit(c(2.5,.5,1.5,.5), "lines"))

pdf('output/plots/ct_by_system.pdf', width = 7, height = 7)
ctSys_plot
dev.off()

# Taxa plot:

ctTaxa_plot = ggplot(propCTTaxa, aes(x = taxa, y = mean, color = ct)) +
  geom_point(size = 2) + 
  geom_errorbar(limits,width = .15) + 
  scale_x_discrete(breaks= c('Arthropod','Benthos','Bird',
                             'Fish','Invertebrate','Mammal',
                             'Plankton','Plant'),
                   labels=c(bquote(atop('Arthropod','n = 3')),
                            bquote(atop('Benthos','n = 81')),
                            bquote(atop('Bird','n = 312')),
                            bquote(atop('Fish','n = 63')),
                            bquote(atop('Invertebrate','n = 2')),
                            bquote(atop('Mammal','n = 19')),
                            bquote(atop('Plankton','n = 8')), 
                            bquote(atop('Plant','n = 51')))) +
  xlab('Taxonomic group')+
  ylab('Proportion of species')+
  ggtitle(bquote(bold('Proportion of core and transient
                      species by taxonomic group')))+
  theme_CT_Grid()+
  theme(axis.text.x = element_text(size=10, color = 1, 
                                   angle = 45, vjust = 1, hjust = 1),
        axis.text.y = element_text(size=12, color = 1, hjust = 1),
        axis.title.x = element_text(size = 18, vjust = -1),
        axis.title.y = element_text(size = 18, vjust = 1.5),
        title = element_text(size=18, vjust = 2.5),
        plot.margin = unit(c(3.5,.5,1.5,.5), "lines"))

pdf('output/plots/ct_by_taxa.pdf', width = 8, height = 8)
ctTaxa_plot
dev.off()

#----------------------------------------------------------------------------------*
# ---- Plotting bimodality by the number of individuals at a site ----
#----------------------------------------------------------------------------------*

ct = read.csv('output/tabular_data/core-transient_summary.csv')
ct = ct[ct$taxa!='Plankton'&ct$nIndividual<5E4,]

bimod_by_indiv = ggplot(ct, aes(x = I(log(nIndividuals)), y = bimodal, color = taxa, shape = system)) +
  ylab('Bimodality') +
  xlab('log(Count of individuals)') +
  ggtitle(bquote(bold('Bimodality of a site by the number of\nindividuals, taxonomic group, and system'))) +
  geom_point(size = 2) + theme_CT_Grid() +
  theme(plot.title = element_text(size=18, vjust = 2.5, hjust = .25),
  plot.margin = unit(c(3.5,.5,1.5,.5), "lines"))

pdf('output/plots/bimod_by_indiv.pdf', width = 8, height = 8)
bimod_by_indiv
dev.off()

summary(lm(bimodal~nIndividuals, data = ct))

summary(lm(bimodal~nIndividuals*taxa, data = ct))

summary(lm(bimodal~nIndividuals+taxa+system, data = ct))

summary(lm(bimodal~nIndividuals*taxa+system, data = ct))



