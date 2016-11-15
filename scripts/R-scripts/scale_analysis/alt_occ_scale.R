#Variation in occupancy at multiple scales WITHIN & ABOVE BBS sites
#REVISED ANALYSIS - Alternate: 6 region nested loop with nearest rtes paired with focal rtes
#Molly F. Jenkins 
#11/11/2016

#Summary: ID six regions 
#for (region in six regions) 
#   for (scale in 2:66) (minimum common # of rtes in each grid)
#random sampling for every possible number of rtes between 2:66 instead of relying on a magic number sample for each grain 
#create a distance matrix 
#calculate great circle distance between routes 
#subset distance matrix to focal routes
#for (i in 1:length(a) 
  #for j in (i +1):length(a) <- keeps redundant pairings so can rule out later as needed 

#when focal route in loop is "2", want to find all of the rows in a where i OR j is the focal route 
#then, for five focal routes, rank by distance, and take just the top five 



#Set working directory to core-transient folder on github i.e. setwd("C:/git/core-transient/")


## Please download and install the following packages:
# maps, sp, rgdal, raster, maptools, rgeos, dplyr, fields
library(raster)
library(maps)
library(sp)
library(rgdal)
library(maptools)
library(rgeos)
library(dplyr)
library(fields)

####Bringing in BBS50 stop data and prepping it for sub-route scale partitioning####

#bbs50 = ecoretriever::fetch('BBS50')
#bbs50 = bbs50$counts
#bbs50$stateroute = bbs50$statenum*1000 + bbs50$Route
#bbs50$stateroute = as.integer(bbs50$stateroute)
#^derivation of data from ecoretriever; still too large to host on github so save and pull from BioArk

bbs50 = read.csv("//bioark.ad.unc.edu/HurlbertLab/Gartland/BBS scaled/bbs50.csv", header = TRUE)

# Get subset of BBS routes (just routes) btw 1996-2010 surveyed in EVERY year

require(dplyr)
#from Sara's code
good_rtes = bbs50 %>% 
  filter(year >= 2000, year <= 2014) %>% #shifted 15 year window up because missing 1996 data, and 2015 data available
  select(year, stateroute) %>%
  unique() %>%    
  group_by(stateroute) %>%  
  count(stateroute) %>% 
  filter(n == 15) #now getting 1005 routes with consecutive data :^)
#write.csv(good_rtes, "//bioark.ad.unc.edu/HurlbertLab/Gartland/BBS scaled/good_rtes.csv", row.names = FALSE) 

#compare # of routes and route numbers themselves to old version of bbs50 stored in BioArk 
require(dplyr)
# Subset the full BBS dataset to the routes above but including associated data
fifty_allyears = bbs50 %>% 
  filter(year >= 2000, year <= 2014) %>% 
  filter(stateroute %in% good_rtes$stateroute)

#finally works because needed $ specification, 
#can probably collapse into one line 
#write.csv(fifty_allyears, "//bioark.ad.unc.edu/HurlbertLab/Gartland/BBS scaled/fifty_allyears.csv", row.names = FALSE)

#wrote to file just in case 

# merge lat longs from routes file to the list of "good" routes (2000-2014 present all years)
require(dplyr)
good_rtes2 = good_rtes %>% 
  left_join(routes, good_rtes, by = "stateroute") %>%
  dplyr::select(stateroute, Lati, Longi)
#write.csv(good_rtes2, "//bioark.ad.unc.edu/HurlbertLab/Gartland/BBS scaled/good_rtes2.csv", row.names = FALSE)


#########

good_rtes2 = read.csv("//bioark.ad.unc.edu/HurlbertLab/Gartland/BBS scaled/good_rtes2.csv", header = TRUE)
fifty_allyears = read.csv("//bioark.ad.unc.edu/HurlbertLab/Gartland/BBS scaled/fifty_allyears.csv", header = TRUE)

require(dplyr)
bbs50_goodrtes = inner_join(fifty_allyears, good_rtes2, by = "stateroute")
#ID and subset to routes within top six regions id'd in grid_sampling_justification 
#assing "reg" label 
bbs50_goodrtes$grid8ID = paste(floor(bbs50_goodrtes$Lati/8)*8 + 8/2, floor(bbs50_goodrtes$Longi/8)*8 + 8/2, sep = "")
bbs50_goodrtes$grid8ID = as.character(bbs50_goodrtes$grid8ID)


#bring in top 6 grids for max scale (8 degree) from grid_sampling_justification.R script, 66 rte cutoff 
top6_grid8 = read.csv("//bioark.ad.unc.edu/HurlbertLab/Gartland/BBS scaled/top6_grid8.csv", header = TRUE)


#filter the 50 stop data to just those routes present within those 6 grid cell regions of interest 
fifty_top6 = bbs50_goodrtes %>% 
  filter(grid8ID %in% top6_grid8$x) #about halves the bbs50_goodrtes set of usable routes

good_rtes3 = good_rtes2[1:10,]

#----Write for_loop to calculate distances between every BBS site combination to find focal and associated routes that correspond best----
#store minimum value for each iteration of combos in output table

# Distance calculation between all combination of 
distances = rdist.earth(matrix(c(good_rtes3$Longi, good_rtes3$Lati), ncol=2),
                        matrix(c(good_rtes3$Longi, good_rtes3$Lati), ncol=2),
                        miles=FALSE, R=6371)

dist.df = data.frame(rte1 = rep(good_rtes3$stateroute, each = nrow(good_rtes3)),
                     rte2 = rep(good_rtes3$stateroute, times = nrow(good_rtes3)),
                     dist = as.vector(distances))

# inside loop, e.g., filter(dist.df, rte1 == 2001, rte2 != 2001)

require(fields)
output=c()





for(grid in fifty_top6$grid8ID){
  for (sample_range in 2:66){ # num of nearest routes taken/paired -> will inform our gradient of areas
    for(focal_bbs in good_rtes2$stateroute){
      temp.lat=sampled_rtes$Lati[sampled_rtes$stateroute==focal_bbs]
      temp.lon= sampled_rtes$Longi[sampled_rtes$stateroute==focal_bbs] 
      distances = rdist.earth(matrix(c(fifty_top6$Longi, fifty_top6$Lati), ncol=2),matrix(c(temp.lon,temp.lat), ncol=2),miles=FALSE, R=6371)
      minDist = min(distances)
      closest_bbs = fifty_top6$stateroute[distances==minDist]
      output=rbind(output, c("focal_bbs", "closest_bbs", "minDist"))

    }
}
}

bbs_paired_samples = as.data.frame(output)

head(output)
summary(output)

#########
#Alt looping structure: 
#Following distance matrix creation, subset distance matrix by analyzing paired routes for distance 
#and ranking them by minimum great circle distance
#where i is the focal route in the cycle of routes 
#and j is its nearest paired route 
#and the array cited in "length" is the array that contains the routes in all possible combos 
output = c()
for (i in 1:length(fifty_top6)) {
  for (j in i:length(fifty_top6)) {
    dist = i - j
    output = rbind(output, dist)
    }
}

