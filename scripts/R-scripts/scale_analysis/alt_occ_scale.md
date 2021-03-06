Variation in occupancy at multiple scales WITHIN & ABOVE BBS sites
REVISED ANALYSIS - Alternate: 6 region nested loop with nearest rtes paired with focal rtes
Molly F. Jenkins 
11/11/2016
Summary: ID six regions 
for (region in six regions) 
  for (scale in 2:66) (minimum common #' of rtes in each grid)
random sampling for every possible number of rtes between 2:66 instead of relying on a magic number sample for each grain 
create a distance matrix 
calculate great circle distance between routes 
subset distance matrix to focal routes
for (i in 1:length(a) 


```r
  #'for j in (i +1):length(a) <- keeps redundant pairings so can rule out later as needed 
```

when focal route in loop is "2", want to find all of the rows in a where i OR j is the focal route 
then, for five focal routes, rank by distance, and take just the top five 
Set working directory to core-transient folder on github i.e. setwd("C:/git/core-transient/")
#' Please download and install the following packages:
maps, sp, rgdal, raster, maptools, rgeos, dplyr, fields


```r
library(raster)
library(maps)
library(sp)
library(rgdal)
library(maptools)
library(rgeos)
library(dplyr)
library(fields)
```

#'#'#'#'#'#'#'#'
----Write for_loop to calculate distances between every BBS site combination to find focal and associated routes that correspond best----
'store minimum value for each iteration of combos in output table
does any of this use any of the fifty_top6 data? Have we moved on from that?


```r
good_rtes2 = read.csv("//bioark.ad.unc.edu/HurlbertLab/Gartland/BBS scaled/good_rtes2.csv", header = TRUE) 
```

```
## Warning in file(file, "rt"): cannot open file '//bioark.ad.unc.edu/
## HurlbertLab/Gartland/BBS scaled/good_rtes2.csv': Invalid argument
```

```
## Error in file(file, "rt"): cannot open the connection
```

```r
require(fields)
```

Distance calculation between all combination of 


```r
distances = rdist.earth(matrix(c(good_rtes2$Longi, good_rtes2$Lati), ncol=2),
                        matrix(c(good_rtes2$Longi, good_rtes2$Lati), ncol=2),
                        miles=FALSE, R=6371)
```

```
## Error in matrix(c(good_rtes2$Longi, good_rtes2$Lati), ncol = 2): object 'good_rtes2' not found
```

```r
dist.df = data.frame(rte1 = rep(good_rtes2$stateroute, each = nrow(good_rtes2)),
                     rte2 = rep(good_rtes2$stateroute, times = nrow(good_rtes2)),
                     dist = as.vector(distances))
```

```
## Error in data.frame(rte1 = rep(good_rtes2$stateroute, each = nrow(good_rtes2)), : object 'good_rtes2' not found
```

inside loop, e.g., filter(dist.df, rte1 == 2001, rte2 != 2001)


```r
dist.df2 = filter(dist.df, rte1 != rte2)
```

```
## Error in filter_(.data, .dots = lazyeval::lazy_dots(...)): object 'dist.df' not found
```

```r
uniqrtes = unique(dist.df2$rte1)
```

```
## Error in unique(dist.df2$rte1): object 'dist.df2' not found
```

#'#'#'Aggregating loop for above-route scales#'#'#'#' 
bring in NON-50 stop data 


```r
bbs_allyears = read.csv("//bioark.ad.unc.edu/HurlbertLab/Gartland/BBS scaled/bbs_allyears.csv", header = TRUE)
```

```
## Warning in file(file, "rt"): cannot open file '//bioark.ad.unc.edu/
## HurlbertLab/Gartland/BBS scaled/bbs_allyears.csv': Invalid argument
```

```
## Error in file(file, "rt"): cannot open the connection
```

exclude AOU species codes <=2880 [waterbirds, shorebirds, etc], (>=3650 & <=3810) [owls],
(>=3900 &  <=3910) [kingfishers], (>=4160 & <=4210) [nightjars], 7010 [dipper]
^best practices 


```r
bbs_bestAous = bbs_allyears %>% 
  filter(Aou > 2880 & !(Aou >= 3650 & Aou <= 3810) & !(Aou >= 3900 & Aou <= 3910) & 
                 !(Aou >= 4160 & Aou <= 4210) & Aou != 7010)  
```

```
## Error in eval(expr, envir, enclos): object 'bbs_allyears' not found
```

```r
numrtes = 1:65 #' based on min common number in top 6 grid cells 
output = data.frame(r = NULL, nu = NULL, AOU = NULL, occ = NULL)
for (r in uniqrtes) {
  for (nu in numrtes) {
  tmp = filter(dist.df2, rte1 == r) %>%
    arrange(dist)
  tmprtes = tmp$rte2[1:nu]   #'selects rtes to aggregate under focal route by dist from focal route, based on nu in numrtes range
  #' Aggregate those routes together, calc occupancy, etc
  
  bbssub = filter(bbs_bestAous, stateroute %in% c(r, tmprtes)) #'resolves issue of r not being included in occ calc on top of its paired routes
  bbsuniq = unique(bbssub[, c('Aou', 'Year')])
  occs = bbsuniq %>% dplyr::count(Aou) %>% dplyr::mutate(occ = n/15)
  
  temp = data.frame(focalrte = r,
                    numrtes = nu+1,                           #'total #' routes being aggregated
                    meanOcc = mean(occs$occ, na.rm =T),       #'mean occupancy
                    pctCore = sum(occs$occ > 2/3)/nrow(occs), #'fraction of species that are core
                    pctTran = sum(occs$occ <= 1/3)/nrow(occs),#'fraction of species that are transient
                    totalAbun = sum(bbssub$SpeciesTotal)/15,  #'total community size (per year)
                    maxRadius = tmp$dist[nu])                 #'radius including rtes aggregated
  output = rbind(output, temp)
  print(paste("Focal rte", r, "#' rtes sampled", nu))
  
  } #'n loop
  
} #'r loop
```

```
## Error in eval(expr, envir, enclos): object 'uniqrtes' not found
```

```r
bbs_focal_occs = as.data.frame(output)
write.csv(bbs_focal_occs, "//bioark.ad.unc.edu/HurlbertLab/Gartland/BBS scaled/bbs_focal_occs.csv", row.names = FALSE)
```

```
## Warning in file(file, ifelse(append, "a", "w")): cannot open file '//
## bioark.ad.unc.edu/HurlbertLab/Gartland/BBS scaled/bbs_focal_occs.csv':
## Invalid argument
```

```
## Error in file(file, ifelse(append, "a", "w")): cannot open the connection
```

```r
head(output)  
```

```
## data frame with 0 columns and 0 rows
```

#'#'#'#'#'#'#'#'
#'#'#'Calc area for above route scale#'#'#'#'


```r
bbs_focal_occs$area = bbs_focal_occs$numrtes*50*(pi*(0.4^2)) #'in km 
```

number of routes * fifty stops * area in sq km of a stop 
#'#'#'Occupancy vs area/#' rtes#'#'#'#'


```r
plot(bbs_focal_occs$numrtes, bbs_focal_occs$meanOcc, xlab = "#' routes", ylab = "mean occupancy")
```

```
## Warning in min(x): no non-missing arguments to min; returning Inf
```

```
## Warning in max(x): no non-missing arguments to max; returning -Inf
```

```
## Warning in min(x): no non-missing arguments to min; returning Inf
```

```
## Warning in max(x): no non-missing arguments to max; returning -Inf
```

```
## Error in plot.window(...): need finite 'xlim' values
```

![plot of chunk unnamed-chunk-9](figure/unnamed-chunk-9-1.png)

```r
par(mfrow = c(2, 1))
plot(bbs_focal_occs$numrtes, bbs_focal_occs$pctTran, xlab = "#' routes", ylab = "% Trans")
```

```
## Warning in min(x): no non-missing arguments to min; returning Inf

## Warning in min(x): no non-missing arguments to max; returning -Inf
```

```
## Warning in min(x): no non-missing arguments to min; returning Inf
```

```
## Warning in max(x): no non-missing arguments to max; returning -Inf
```

```
## Error in plot.window(...): need finite 'xlim' values
```

```r
plot(bbs_focal_occs$numrtes, bbs_focal_occs$pctCore, xlab = "#' routes", ylab = "% Core")
```

```
## Warning in min(x): no non-missing arguments to min; returning Inf

## Warning in min(x): no non-missing arguments to max; returning -Inf
```

```
## Warning in min(x): no non-missing arguments to min; returning Inf
```

```
## Warning in max(x): no non-missing arguments to max; returning -Inf
```

```
## Error in plot.window(...): need finite 'xlim' values
```

still just at above route scale tho - now need to stitch above and below together again 
#'#'#'Find lat/lons of focal routes, add env data, color code points#'#'#'#'


```r
routes = read.csv('scripts/R-scripts/scale_analysis/routes.csv')
```

```
## Warning in file(file, "rt"): cannot open file 'scripts/R-scripts/
## scale_analysis/routes.csv': No such file or directory
```

```
## Error in file(file, "rt"): cannot open the connection
```

```r
routes$stateroute = 1000*routes$statenum + routes$Route
```

```
## Error in eval(expr, envir, enclos): object 'routes' not found
```

#'#'#'rerun sub-route occ analysis#'#'#'#'


```r
fifty_allyears = read.csv("//bioark.ad.unc.edu/HurlbertLab/Gartland/BBS scaled/fifty_allyears.csv", header = TRUE)
```

```
## Warning in file(file, "rt"): cannot open file '//bioark.ad.unc.edu/
## HurlbertLab/Gartland/BBS scaled/fifty_allyears.csv': Invalid argument
```

```
## Error in file(file, "rt"): cannot open the connection
```

```r
fifty_bestAous = fifty_allyears %>% 
  filter(AOU > 2880 & !(AOU >= 3650 & AOU <= 3810) & !(AOU >= 3900 & AOU <= 3910) & 
           !(AOU >= 4160 & AOU <= 4210) & AOU != 7010) 
```

```
## Error in eval(expr, envir, enclos): object 'fifty_allyears' not found
```

#'#'So for the whole dataset, 10 pt count stops: #'we are only getting one out of five chunks along 
want to estimate occupancy across each one, as of now only estimating for count 10 column 
fifty pt count data and then taking pts 1-5 and collapsing them all together 
#'#'#'#'#'#'#'#'


```r
occ_counts = function(countData, countColumns, scale) {
  bbssub = countData[, c("stateroute", "year", "AOU", countColumns)]
  bbssub$groupCount = rowSums(bbssub[, countColumns])
  bbsu = unique(bbssub[bbssub[, "groupCount"]!= 0, c("stateroute", "year", "AOU")]) #'because this gets rid of 0's...
  
  occ.df = bbsu %>%
    count(stateroute, AOU) %>%
    mutate(occ = n/15, scale = scale, subrouteID = countColumns[1])
    
  occ.summ = occ.df %>%
    group_by(stateroute) %>%
    summarize(meanOcc = mean(occ), 
              pctCore = sum(occ > 2/3)/length(occ),
              pctTran = sum(occ <= 1/3)/length(occ))
  
  abun = bbssub %>% 
    group_by(stateroute, year) %>%  
    summarize(totalN = sum(groupCount)) %>%
    group_by(stateroute) %>%
    summarize(aveN = mean(totalN))
```

```
## Error: <text>:21:0: unexpected end of input
## 19:     group_by(stateroute) %>%
## 20:     summarize(aveN = mean(totalN))
##    ^
```

need to fix nested dataframe output     


```r
  return(list(occ = occ.summ, abun = abun))
}
```

```
## Error: <text>:2:1: unexpected '}'
## 1:   return(list(occ = occ.summ, abun = abun))
## 2: }
##    ^
```

Generic calculation of occupancy for a specified scale


```r
scales = c(5, 10, 25, 50)


output = c()
for (scale in scales) {
  numGroups = floor(50/scale)
  for (g in 1:numGroups) {
    groupedCols = paste("Stop", ((g-1)*scale + 1):(g*scale), sep = "")
    temp = occ_counts(fifty_bestAous, groupedCols, scale)
    output = rbind(output, temp) #'again, need to fix nested dataframe output structure
  }
  
}
```

```
## Error: could not find function "occ_counts"
```

```r
bbs_scalesorted<-output
```

#'#'#'Workspace/junk#'#'#'#'
calc mean occ, abundance, % core and % trans across stateroute, AOU, and subroute ID cluster for each scale 


```r
test_meanocc = bbs_scalesorted %>% 
  group_by(scale, stateroute, subrouteID) %>% #'occ across all AOU's, for each unique combo of rte, scale(segment length), and starting segment
  summarize(mean = mean(occupancy)) %>% 
  group_by(scale, stateroute) %>%
  summarize(mean_occ = mean(mean)) 
```

```
## Error in UseMethod("group_by_"): no applicable method for 'group_by_' applied to an object of class "NULL"
```

```r
test_meanabun = bbs_scalesorted %>% 
  group_by(scale, stateroute, subrouteID) %>%
  summarize(abun = mean(abun)) %>%
  group_by(scale, stateroute) %>%
  summarize(mean_ab = mean(abun)) 
```

```
## Error in UseMethod("group_by_"): no applicable method for 'group_by_' applied to an object of class "NULL"
```

```r
pctCore = sum(test_meanocc$mean > .67)/nrow(test_meanocc) #'fraction of species that are core
```

```
## Error in eval(expr, envir, enclos): object 'test_meanocc' not found
```

```r
pctTran = sum(test_meanocc$mean <= .33)/nrow(test_meanocc)
```

```
## Error in eval(expr, envir, enclos): object 'test_meanocc' not found
```

should do ^ for each scale
how to accumulate "reps" or "numrtes" equiv in below-rte scale accordingly? 
#'#'#'finished above route aggregation of routes#'#'#'#'


```r
bbs_focal_occs = read.csv("//bioark.ad.unc.edu/HurlbertLab/Gartland/BBS scaled/bbs_focal_occs.csv", header = TRUE)
```

```
## Warning in file(file, "rt"): cannot open file '//bioark.ad.unc.edu/
## HurlbertLab/Gartland/BBS scaled/bbs_focal_occs.csv': Invalid argument
```

```
## Error in file(file, "rt"): cannot open the connection
```

^^correct, up-to-date version of ABOVE ROUTE aggregated pairings as of 01/19/2017
