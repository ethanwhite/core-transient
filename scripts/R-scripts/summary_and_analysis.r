###############################################
# Code for running core-transient analysis
# and data summaries over all formatted datasets.
#
# Input files are named propOcc_XXX.csv where
# XXX is the dataset ID.

setwd("C:/git/core-transient")

library(lme4)
library(dplyr)
library(ggplot2)
library(tidyr)
library(maps)
library(gridExtra)
library(RColorBrewer)

source('scripts/R-scripts/core-transient_functions.R')

# Maximum occupancy of transient species
# (and hence the minimum occupancy of core species is 1 - threshold)
threshold = 1/3

# Number of replicates for randomization tests
reps = 999

##################################################################

# If running summaries for the first time (or wanting to start
# anew because all formatted datasets have changed) and a
# 'core-transient_summary.csv' file does not exist yet in the 
# output/tabular_data folder, or if you just want to get summary
# stats for one or a few datasets into R, run this section

# Specify here the datasetIDs and then run the code below.
dataformattingtable = read.csv('data_formatting_table.csv', header = T) 

datasetIDs = dataformattingtable$dataset_ID[dataformattingtable$format_flag == 1]

datasetIDs = datasetIDs[!datasetIDs %in% c(222, 317,67,270,271,319,325)] # 222 is % cover, 317 d/n have neough years

summaries = c()
for (d in datasetIDs) {
  newsumm = summaryStatsFun(d, threshold, reps)
  summaries = rbind(summaries, newsumm)
  print(d)
}

write.csv(summaries, 'output/tabular_data/core-transient_summary.csv', 
          row.names = T)

##################################################################

# If running summaries for the newly updated or created formatted
# datasets to be appended to the existing 'core-transient_summary.csv'
# file, then run this section.

# If you do not want to re-write the existing file, set write = FALSE.

# Also, this command can be used instead of the section above to
# create the 'core-transient_summary.csv' file from scratch for all
# datasets with formatted data.

summ = addNewSummariesFun(threshold, reps, write = TRUE)


#####################lump reptile and ampibian into herptile, get rid of invert if possible - other category?, do a table of communities

# Plotting summary results across datasets for Core-Transient analysis

summ = read.csv('output/tabular_data/core-transient_summary.csv', header=T)
summ$taxa = factor(summ$taxa)
summ$taxa[summ$taxa == "Arthropod"] <- "Invertebrate"
summ$taxa[summ$taxa == "Reptile"] <- NA
summ$system[summ$system == "Aquatic"] <- "Freshwater"
summ$system = factor(summ$system)
summ = na.omit(summ)
summ2 = subset(summ, !datasetID %in% c(99, 85, 90, 91, 92, 97, 124))
dsets = unique(summ2[, c('datasetID', 'system','taxa')])

taxorder = c('Bird', 'Plant', 'Mammal', 'Fish', 'Invertebrate', 'Benthos', 'Plankton')

dsetsBySystem = table(dsets$system)
dsetsByTaxa = table(dsets$taxa)
sitesBySystem = table(summ2$system)
sitesByTaxa = table(summ2$taxa)

colors7 = c(colors()[144], # invert
            rgb(0, 54/255, 117/255), #benthos
            rgb(29/255, 106/255, 155/255), #bird
            colors()[70], #fish
            colors()[551], #mammal
            colors()[552], # plankton
            colors()[612])# plant
            

symbols7 = c(16, 18, 167, 15, 17, 1, 3) 

taxcolors = data.frame(taxa = unique(summ$taxa), color = colors7, pch = symbols7)

taxcolors$abbrev = taxcolors$taxa
taxcolors$abbrev = gsub("Benthos", 'Be', taxcolors$abbrev)
taxcolors$abbrev = gsub("Bird", 'Bi', taxcolors$abbrev)
taxcolors$abbrev = gsub("Fish", 'F', taxcolors$abbrev)
taxcolors$abbrev = gsub("Invertebrate", 'I', taxcolors$abbrev)
taxcolors$abbrev = gsub("Mammal", 'M', taxcolors$abbrev)
taxcolors$abbrev = gsub("Plankton", 'Pn', taxcolors$abbrev)
taxcolors$abbrev = gsub("Plant", 'Pt', taxcolors$abbrev)


pdf('output/plots/data_summary_hists.pdf', height = 8, width = 10)
par(mfrow = c(2, 2), mar = c(6,6,1,1), cex = 1.25, oma = c(0,0,0,0), las = 1,
    cex.lab = 1)
b1=barplot(dsetsBySystem, col = c('skyblue', 'navy', 'burlywood')) 
mtext("# Datasets", 2, cex = 1, las = 0, line = 2.5)
barplot(log10(sitesBySystem), col = c('skyblue', 'navy', 'burlywood'), cex.names = 1, 
        yaxt = "n", ylim = c(0,3)) 
axis(2, 0:3)
mtext(expression(log[10] ~ " # Assemblages"), 2, cex = 1.5, las = 0, line = 2.5)
bar1 = barplot(dsetsByTaxa[taxorder], xaxt = "n", axisnames = F,
               col = as.character(taxcolors$color[match(taxorder, taxcolors$taxa)]))
# text(bar1, par("usr")[3], taxcolors$abbrev, adj = c(1, 1), xpd = TRUE, cex = 1) 

mtext("# Datasets", 2, cex = 1.5, las = 0, line = 2.5)
bar2 = barplot(log10(sitesByTaxa[taxorder]), axes = F, axisnames = F, ylim = c(0,3),
               col = as.character(taxcolors$color[match(taxorder, taxcolors$taxa)]))
axis(2, 0:3)
mtext(expression(log[10] ~ " # Assemblages"), 2, cex = 1.5, las = 0, line = 2.5)
dev.off()


#### barplot of mean occ by taxa #####
numCT = read.csv("output/tabular_data/numCT.csv", header=TRUE)
numCT_plot$taxa = as.factor(numCT_plot$taxa)
numCT_plot$taxa <-droplevels(numCT_plot$taxa, exclude = c("","All","Amphibian", "Reptile"))

# n calculates number of sites by taxa -nested sites
n = numCT_taxa %>%
  dplyr::count(site, taxa) %>%
  group_by(taxa) %>%
  tally(n)
n = data.frame(n)
# calculates number of sites by taxa -raw
sitetally = summ %>%
  dplyr::count(site, taxa) %>%
  group_by(taxa) %>%
  dplyr::tally()
sitetally = data.frame(sitetally)

numCT_box=merge(numCT_taxa, taxcolors, by="taxa")

nrank = summ %>% 
  group_by(taxa) %>%
  dplyr::summarize(mean(mu)) 
nrank = data.frame(nrank)
nrank = arrange(nrank, desc(mean.mu.))

summ_plot = merge(summ, nrank, by = "taxa", all.x=TRUE)

summ$taxa <- factor(summ$taxa,
                       levels = c('Bird','Mammal','Plankton','Benthos','Invertebrate','Plant','Fish'),ordered = TRUE)
rankedtaxorder = c('Bird','Mammal','Plankton','Benthos','Invertebrate','Plant','Fish')

dsetsBySystem = table(dsets$system)
dsetsByTaxa = table(dsets$taxa)
sitesBySystem = table(summ2$system)
sitesByTaxa = table(summ2$taxa)

colorsrank = c(rgb(0, 54/255, 117/255), #bird
               colors()[551],#mammal
               colors()[552], # plankton
               rgb(29/255, 106/255, 155/255), # benthos
               colors()[144], # arth
               colors()[612],# plant
               colors()[600]) #fish


symbols7 = c(16, 18, 167, 15, 17, 1, 3) 
taxcolorsrank = data.frame(taxa = unique(summ$taxa), color = colorsrank, pch = symbols7)

w <- ggplot(summ, aes(factor(taxa), mu))+theme_classic()+
  theme(axis.text.x=element_text(angle=90,size=10,vjust=0.5)) + xlab("Taxa") + ylab("Mean Occupancy\n")
w + geom_boxplot(width=1, position=position_dodge(width=0.6),aes(x=taxa, y=mu), fill = taxcolorsrank$color)+
  scale_fill_manual(labels = taxcolors$taxa, values = taxcolors$color)+theme(axis.ticks=element_blank(),axis.text.x=element_text(size=14),axis.text.y=element_text(size=14),axis.title.x=element_text(size=22),axis.title.y=element_text(size=22,angle=90,vjust = 1)) + guides(fill=guide_legend(title=""))+ theme(plot.margin = unit(c(.5,.5,.5,.5),"lines")) + annotate("text", x = nrank$taxa, y = 1.05, label = sitetally$n,size=5,vjust=0.8, color = "black")
ggsave("C:/Git/core-transient/output/plots/meanOcc.pdf", height = 8, width = 12)

###########   ######################################################
# Explaining variation in mean occupancy within BBS
# Merge taxa color and symbol codes into summary data
summ$taxa = factor(summ$taxa)
summ$system = factor(summ$system)
summ2 = subset(summ, !datasetID %in% c(99, 85, 90, 91, 92, 97, 124))
summ3 = merge(summ2, taxcolors, by = 'taxa', all.x = T)
summ3$color = as.character(summ3$color)
notbbs = subset(summ3, datasetID != 1)
bbssumm = subset(summ3, datasetID == 1)
env = read.csv('data/raw_datasets/dataset_1RAW/env_data.csv')
bbsumm = merge(bbssumm, env, by.x = 'site', by.y = 'stateroute')

par(mfrow = c(2,1), mar = c(6, 4, 1, 1), mgp = c(3, 1, 0), 
    oma = c(0, 4, 0, 0), las = 1, cex.axis = 1.5, cex.lab = 2)
plot(bbsumm$sum.NDVI.mean, bbsumm$mu, xlab = "NDVI", ylab = "", pch = 16, col = 'gray40')
lm.ndvi = lm(mu ~ sum.NDVI.mean, data = bbsumm)
abline(lm.ndvi, col = 'red', lty = 'dashed', lwd = 4)
text(0.25, 0.85, bquote(R^2 ~ "=" ~ .(round(summary(lm.ndvi)$r.squared, 2))), cex = 1.5)
plot(bbsumm$elev.mean, bbsumm$mu, xlab = "Elevation (m)", ylab = "", pch = 16, col = 'gray40')
lm.elev = lm(mu ~ elev.mean, data = bbsumm)
abline(lm.elev, col = 'red', lty = 'dashed', lwd = 4)
text(2600, 0.85, bquote(R^2 ~ "=" ~ .(round(summary(lm.elev)$r.squared, 2))), cex = 1.5)
mtext("Mean occupancy", 2, outer = T, cex = 2, las = 0)


##### Boxplots showing distribution of core and transient species by taxon #####
core = summ2 %>%
  dplyr::group_by(taxa) %>%
  dplyr::summarize(mean(propCore)) 
trans = summ2 %>%
  dplyr::group_by(taxa) %>%
  dplyr::summarize(mean(propTrans)) 

propCT = merge(core, trans, by = "taxa")
propCT = data.frame(propCT)
propCT$mean.propNeither. = 1 - propCT$mean.propCore. - propCT$mean.propTrans.


propCT_long = gather(propCT, "class","value", c(mean.propCore.:mean.propNeither.))
propCT_long = arrange(propCT_long, desc(class))
propCT_long$taxa = as.factor(propCT_long$taxa)
propCT_long$taxa = factor(propCT_long$taxa,
                    levels = c('Invertebrate','Plankton','Fish','Mammal','Plant','Bird','Benthos'),ordered = TRUE)
colscale = c("#c51b8a", "#fdd49e", "#225ea8")


##################################################################
# barplot of % transients versus community size at diff thresholds
datasetIDs = dataformattingtable$dataset_ID[dataformattingtable$format_flag == 1]

### Have to cut out stuff that have mean abundance NA
datasetIDs = datasetIDs[!datasetIDs %in% c(67,270,271,317,319,325)]


summaryTransFun = function(datasetID){
  # Get data:
  dataList = getDataList(datasetID)
  sites  = as.character(dataList$siteSummary$site)
  # Get summary stats for each site:       
  outList = list(length = length(sites))
  for(i in 1:length(sites)){
    propOcc = subset(dataList$propOcc, site == sites[i])$propOcc
    siteSummary = subset(dataList$siteSummary, site == sites[i])
    nTime = siteSummary$nTime
    spRichTotal = siteSummary$spRich
    spRichCore33 = length(propOcc[propOcc > 1 - 1/3])
    spRichTrans33 = length(propOcc[propOcc <= 1/3])
    spRichTrans25 = length(propOcc[propOcc <= 1/4])
    if(nTime > 9){
    spRichTrans10 = length(propOcc[propOcc <= .1])
    propTrans10 = spRichTrans10/spRichTotal
    }
    else{
      propTrans10 = NA
    }
    propCore33 = spRichCore33/spRichTotal
    propTrans33 = spRichTrans33/spRichTotal
    propTrans25 = spRichTrans25/spRichTotal
    
    outList[[i]] = data.frame(datasetID, site = sites[i],
                              system = dataList$system, taxa = dataList$taxa,
                              nTime, spRichTotal, spRichCore33, spRichTrans33,
                              propCore33,  propTrans33, propTrans25, propTrans10)
  }
  return(rbind.fill(outList))
}

percTransSummaries = c()
for (d in datasetIDs) {
  percTransSumm = summaryTransFun(d)
  
  percTransSummaries = rbind(percTransSummaries, percTransSumm)
  print(d)
}

CT_plot=merge(percTransSummaries, taxcolors, by="taxa")
CT_long = gather(CT_plot, "level_trans","pTrans", propTrans33:propTrans10)

ttrans = CT_plot %>%
  dplyr::group_by(taxa) %>%
  dplyr::summarize(mean(propTrans33)) 

propCT_long$abbrev = propCT_long$taxa
propCT_long$abbrev = gsub("Benthos", 'Be', propCT_long$abbrev)
propCT_long$abbrev = gsub("Bird", 'Bi', propCT_long$abbrev)
propCT_long$abbrev = gsub("Fish", 'F', propCT_long$abbrev)
propCT_long$abbrev = gsub("Invertebrate", 'I', propCT_long$abbrev)
propCT_long$abbrev = gsub("Mammal", 'M', propCT_long$abbrev)
propCT_long$abbrev = gsub("Plankton", 'Pn', propCT_long$abbrev)
propCT_long$abbrev = gsub("Plant", 'Pt', propCT_long$abbrev)
propCT_long$abbrev = factor(propCT_long$abbrev,
                            levels = c('I','Pn','F','M','Pt','Bi','Be'),ordered = TRUE)

colscale = c("#c51b8a", "#fdd49e", "#225ea8")
m = ggplot(data=propCT_long, aes(factor(abbrev), y=value, fill=factor(class))) + geom_bar(stat = "identity")  + theme_classic() + xlab("Taxa") + ylab("Proportion of Species")+ scale_fill_manual(labels = c("Core", "Other", "Transient"),
                                                                                                                                                                                                  values = colscale)+theme(axis.ticks.x=element_blank(),axis.text.x=element_text(size=20),axis.text.y=element_text(size=20),axis.title.x=element_text(size=24),axis.title.y=element_text(size=24,angle=90,vjust = 2.5))+ theme(legend.text=element_text(size=24),legend.key.size = unit(2, 'lines'))+theme(legend.position="top", legend.justification=c(0, 1), legend.key.width=unit(1, "lines"))+ guides(fill = guide_legend(keywidth = 3, keyheight = 1,title="", reverse=TRUE))+ coord_fixed(ratio = 4)

#### barplot of percent transients by taxa ---FIXED
CT_long$taxa = as.factor(CT_long$taxa)
CT_long$abbrev = CT_long$taxa
CT_long$abbrev = gsub("Benthos", 'Be', CT_long$abbrev)
CT_long$abbrev = gsub("Bird", 'Bi', CT_long$abbrev)
CT_long$abbrev = gsub("Fish", 'F', CT_long$abbrev)
CT_long$abbrev = gsub("Invertebrate", 'I', CT_long$abbrev)
CT_long$abbrev = gsub("Mammal", 'M', CT_long$abbrev)
CT_long$abbrev = gsub("Plankton", 'Pn', CT_long$abbrev)
CT_long$abbrev = gsub("Plant", 'Pt', CT_long$abbrev)
CT_long$abbrev = factor(CT_long$abbrev,
                            levels = c('I','Pn','F','M','Pt','Bi','Be'),ordered = TRUE)


p <- ggplot(CT_long, aes(x = reorder(abbrev, -pTrans), y = pTrans))+theme_classic()

cols <- (CT_long$color)
cols=c("#ece7f2","#9ecae1",  "#225ea8")


p = p+geom_boxplot(width=0.8,position=position_dodge(width=0.8),aes(x=factor(abbrev), y=pTrans, fill=level_trans))+ 
  scale_colour_manual(breaks = CT_long$level_trans,
                      values = taxcolors$color)  + xlab("Taxa") + ylab("Proportion of Species")+
  scale_fill_manual(labels = c("10%", "25%", "33%"),
                    values = cols)+theme(axis.ticks.x=element_blank(),axis.text.x=element_text(size=20),axis.text.y=element_text(size=20),axis.title.x=element_text(size=24),axis.title.y=element_text(size=24,angle=90,vjust = 2))+guides(fill=guide_legend(title="",keywidth = 2, keyheight = 1)) + theme(legend.text=element_text(size=24),legend.key.size = unit(2, 'lines'), legend.title=element_text(size=24))+theme(legend.position="top", legend.justification=c(0, 1), legend.key.width=unit(1, "lines"))+ coord_fixed(ratio = 4)

colscale = c("#c51b8a", "#fdd49e", "#225ea8")
plot1 <- m
cols=c("#ece7f2","#9ecae1",  "#225ea8")
plot2 <- p
grid = grid.arrange(plot1, plot2, ncol=2)

ggsave(file="C:/Git/core-transient/output/plots/comboplot.pdf", height = 10, width = 15,grid)

#################### FIG 3 ######################### 
mod = read.csv("mod.csv", header=TRUE)

pdf('output/plots/sara_scale_transient_reg.pdf', height = 6, width = 7.5)
par(mfrow = c(1, 1), mar = c(6, 6, 1, 1), mgp = c(4, 1, 0), 
    cex.axis = 1.5, cex.lab = 2, las = 1)
palette(colors7)

occ_taxa=read.csv("output/tabular_data/occ_taxa.csv",header=TRUE)
scaleIDs = filter(dataformattingtable, spatial_scale_variable == 'Y',
                  format_flag == 1)$dataset_ID
scaleIDs = scaleIDs[scaleIDs != 222]
scaleIDs = scaleIDs[scaleIDs != 317]
bbs_abun = read.csv("bbs_abun_occ.csv", header=TRUE)

totalspp = bbs_abun %>% 
  group_by(AOU, stateroute) %>%
  tally(sum.groupCount.)
for(i in bbs_abun$AOU){
  sum(bbs_abun$occupancy <= 1/3)/(totalspp$n)
}

mod3 = lm(abun$occupancy ~ log10(abun$sum.groupCount.))
xnew = range(log10(abun$sum.groupCount.))
xhat <- predict(mod3, newdata = data.frame((xnew)))
xhats = range(xhat)
print(xhats)


for(id in scaleIDs){
  print(id)
  plotsub = subset(occ_taxa,datasetID == id)
  mod3 = lm(plotsub$pctTrans ~ log10(plotsub$meanAbundance))
  xnew = range(log10(plotsub$meanAbundance))
  xhat <- predict(mod3, newdata = data.frame((xnew)))
  xhats = range(xhat)
  print(xhats)
  taxcolor = subset(taxcolors, taxa == as.character(plotsub$taxa)[1])
  y=summary(mod3)$coef[1] + (xhats)*summary(mod3)$coef[2]
  plot(NA, xlim = c(-1, 7), ylim = c(0,1), col = as.character(taxcolor$color), xlab = expression("Log"[10]*" Community Size"), ylab = "% Transients", cex = 1.5)
  lines(log10(plotsub$meanAbundance), fitted(mod3), col=as.character(taxcolor$color),lwd=5)
  par(new=TRUE)
}
segments(0,  1, x1 = 5.607, y1 = 0, col = rgb(29/255, 106/255, 155/255), lwd=5)
par(new=TRUE)
legend('topright', legend = taxcolors$taxa, lty=1,lwd=3,col = as.character(taxcolors$color), cex = 1.35)
dev.off()

pdf('output/plots/sara_scale_core_reg.pdf', height = 6, width = 7.5)
par(mfrow = c(1, 1), mar = c(6, 6, 1, 1), mgp = c(4, 1, 0), 
    cex.axis = 1.5, cex.lab = 2, las = 1)
palette(colors7)
for(id in scaleIDs){
  print(id)
  plotsub = subset(occ_taxa,datasetID == id)
  mod3 = lm((1-plotsub$pctTrans) ~ log10(plotsub$meanAbundance))
  xnew=range(log10(plotsub$meanAbundance))
  xhat <- predict(mod3, newdata = data.frame((xnew)))
  xhats = range(xhat)
  print(xhats)
  taxcolor=subset(taxcolors, taxa == as.character(plotsub$taxa)[1])
  y=summary(mod3)$coef[1] + (xhats)*summary(mod3)$coef[2]
  plot(NA, xlim = c(-1, 7), ylim = c(0,1), col = as.character(taxcolor$color), xlab = expression("Log"[10]*" Community Size"), ylab = "% Core", cex = 1.5)
  lines(log10(plotsub$meanAbundance), fitted(mod3), col=as.character(taxcolor$color),lwd=5)
  par(new=TRUE)
}
segments(0,  0, x1 = 5.607, y1 = 1, col = rgb(29/255, 106/255, 155/255), lwd=5)
par(new=TRUE)
dev.off()

####### MODELS ######
latlongs_mult = read.csv("data/latlongs/latlongs.csv", header =TRUE)

dft = subset(dataformattingtable, countFormat == "count" & format_flag == 1) # only want count data for model
dft = subset(dft, !dataset_ID %in% c(1,247,248,269,289,309,315))
dft = dft[,c("CentralLatitude", "CentralLongitude","dataset_ID", "taxa")]
names(dft) <- c("Lat","Lon", "datasetID", "taxa")

latlongs_mult = latlongs_mult[,c(1:4)]

all_latlongs = rbind(dft, latlongs_mult)
all_latlongs = na.omit(all_latlongs)

lat_scale = merge(occ_taxa, all_latlongs, by = "datasetID")

library('sp')
library('rgdal')
library("raster")

# Makes routes into a spatialPointsDataframe
coordinates(all_latlongs)=c('Lon','Lat')
projection(all_latlongs) = CRS("+proj=longlat +ellps=WGS84")
prj.string <- "+proj=laea +lat_0=45.235 +lon_0=-106.675 +units=km"
# Transforms routes to an equal-area projection - see previously defined prj.string
routes.laea = spTransform(all_latlongs, CRS(prj.string))

# A function that draws a circle of radius r around a point: p (x,y)
RADIUS = 40

make.cir = function(p,r){
  points=c()
  for(i in 1:360){
    theta = i*2*pi/360
    y = p[2] + r*cos(theta)
    x = p[1] + r*sin(theta)
    points = rbind(points,c(x,y))
  }
  points=rbind(points,points[1,])
  circle=Polygon(points,hole=F)
  circle
}

#Draw circles around all routes ---- erroring in here
circs = sapply(1:nrow(routes.laea), function(x){
  circ =  make.cir(routes.laea@coords[x,],RADIUS)
  circ = Polygons(list(circ),ID=routes.laea@data$stateroute[x])
}
)
circs.sp = SpatialPolygons(circs, proj4string=CRS(prj.string))

# Check that circle loactions look right
plot(circs.sp)

elev <- getData("worldclim", var = "alt", res = 10)
alt_files<-paste('alt_10m_bil', sep='')

elev.point = raster::extract(elev, routes)
elev.mean = raster::extract(elev, circs.sp, fun = mean, na.rm=T)
elev.var = raster::extract(elev, circs.sp, fun = var, na.rm=T)

env_elev = data.frame(stateroute = names(circs.sp), elev.point = elev.point, elev.mean = elev.mean, elev.var = elev.var)

mod1 = lmer(pctTrans ~ (1|taxa.x) * spRich * Lat, data=lat_scale) # need to add in env heterogeneity AKA Elev





