################################################################################*
# Dataset 246, Channel Island fish in the Kelp Forest Monitoring Programming
#
# Data from http://esapubs.org/archive/ecol/E094/245/metadata.php
#
# NOTE: These data are from the Roving Diver Fish Count dataset (RDFC data.csv)
#       which attempted to monitor all fish species present,
#       and NOT the Fish density data which only monitored 13 species.
#
# Formatted by Allen Hurlbert
#
#-------------------------------------------------------------------------------*
# ---- SET-UP ----
#===============================================================================*

# This script is best viewed in RStudio. I like to reduced the size of my window
# to roughly the width of the section lines (as above). Additionally, ensure 
# that your global options are set to soft-wrap by selecting:
# Tools/Global Options .../Code Editing/Soft-wrap R source files

# Load libraries:

library(stringr)
library(plyr)
library(ggplot2)
library(grid)
library(gridExtra)
library(MASS)


# Source the functions file:

getwd()

source('scripts/R-scripts/core-transient_functions.R')

# Get data. First specify the dataset number ('datasetID') you are working with.

#####
datasetID = 246

list.files('data/raw_datasets')

dataset = read.csv(paste('data/raw_datasets/dataset_', datasetID, '.csv', sep = ''))

dataFormattingTable = read.csv('data_formatting_table.csv')

dataFormattingTable[,'Raw_datafile_name'] = 
  dataFormattingTableFieldUpdate(datasetID, 'Raw_datafile_name',  
                                 
                                 #--! PROVIDE INFO !--#
                                 'RDFC data.csv') 

########################################################
# ANALYSIS CRITERIA                                    #  
########################################################

# Min number of time samples required 
minNTime = 6

# Min number of species required
minSpRich = 10

# Ultimately, the largest number of spatial and 
# temporal subsamples will be chosen to characterize
# an assemblage such that at least this fraction
# of site-years will be represented.
topFractionSites = 0.5

#######################################################

#-------------------------------------------------------------------------------*
# ---- EXPLORE THE DATASET ----
#===============================================================================*
# Here, you are predominantly interested in getting to know the dataset, and determine what the fields represent and  which fields are relavent.

# View field names:

names(dataset)

# View how many records and fields:

dim(dataset)

# View the structure of the dataset:


# View first 6 rows of the dataset:

head(dataset)

# Here, we can see that there are some fields that we won't use. Let's remove them, note that I've given a new name here "dataset1", this is to ensure that we don't have to go back to square 1 if we've miscoded anything.

# If all fields will be used, then set unusedFields = 9999.

names(dataset)

#####
unusedFieldNames = c('record_id','observernumber','commonname', 'year')


unusedFields = which(names(dataset) %in% unusedFieldNames)

dataset1 = dataset[,-unusedFields]


# You also might want to change the names of the identified species field [to 'species'] and/or the identified site field [to 'site']. Just make sure you make specific comments on what the field name was before you made the change, as seen above.

# Explore, if everything looks okay, you're ready to move forward. If not, retrace your steps to look for and fix errors. 

head(dataset1, 10)

# I've found it helpful to explore more than just the first 6 data points given with just a head(), so I used head(dataset#, 10) or even 20 to 50 to get a better snapshot of what the data looks like.  Do this periodically throughout the formatting process

# !GIT-ADD-COMMIT-PUSH AND DESCRIBE HOW THE DATA WERE MODIFIED!

#!DATA FORMATTING TABLE UPDATE! 
# Are the ONLY site identifiers the latitude and longitude of the observation or 
# sample? (I.e., there are no site names or site IDs or other designations) Y/N

dataFormattingTable[,'LatLong_sites'] = 
  dataFormattingTableFieldUpdate(datasetID, 'LatLong_sites',   # Fill value in below

#####
                                 'N') 


#-------------------------------------------------------------------------------*
# ---- FORMAT TIME DATA ----
#===============================================================================*
# Here, we need to extract the sampling dates. 

# What is the name of the field that has information on sampling date?
# If date info is in separate columns (e.g., 'day', 'month', and 'year' cols),
# then write these field names as a vector from largest to smallest temporal grain.

#####
dateFieldName = c('record_date')

# If necessary, paste together date info from multiple columns into single field
if (length(dateFieldName) > 1) {
  newDateField = dataset1[, dateFieldName[1]]
  for (i in dateFieldName[2:length(dateFieldName)]) { newDateField = paste(newDateField, dataset[,i], sep = "-") }
  dataset1$date = newDateField
  datefield = 'date'
} else {
  datefield = dateFieldName
}

# What is the format in which date data is recorded? For example, if it is
# recorded as 5/30/94, then this would be '%m/%d/%y', while 1994-5-30 would
# be '%Y-%m-%d'. Type "?strptime" for other examples of date formatting.

#####
dateformat = '%d%b%Y'

# If date is only listed in years:

# dateformat = '%Y'

# If the date is just a year, then make sure it is of class numeric
# and not a factor. Otherwise change to a true date object.

if (dateformat == '%Y' | dateformat == '%y') {
  date = as.numeric(as.character(dataset1[, datefield]))
} else {
  date = as.POSIXct(strptime(dataset1[, datefield], dateformat))
}

# A check on the structure lets you know that date field is now a date object:

class(date)

# Give a double-check, if everything looks okay replace the column:

head(dataset1[, datefield])

head(date)

dataset2 = dataset1

# Delete the old date field
dataset2 = dataset2[, -which(names(dataset2) %in% dateFieldName)]

# Assign the new date values in a field called 'date'
dataset2$date = date

# Check the results:

head(dataset2)

# !GIT-ADD-COMMIT-PUSH AND DESCRIBE HOW THE DATE DATA WERE MODIFIED!

#!DATA FORMATTING TABLE UPDATE!

# Notes_timeFormat. Provide a thorough description of any modifications that were made to the time field.

dataFormattingTable[,'Notes_timeFormat'] = 
  dataFormattingTableFieldUpdate(datasetID, 'Notes_timeFormat',  # Fill value in below

#####
                                 'Temporal data provided as dates. The only modification to this field involved converting to a date object.')

# subannualTgrain. After exploring the time data, was this dataset sampled at a sub-annual temporal grain? Y/N


dataFormattingTable[,'subannualTgrain'] = 
  dataFormattingTableFieldUpdate(datasetID, 'subannualTgrain',    # Fill value in below

#####                                 
                                 'Y')

#-------------------------------------------------------------------------------*
# ---- EXPLORE AND FORMAT SITE DATA ----
#===============================================================================*
# From the previous head commmand, we can see that sites are broken up into (potentially) 5 fields. Find the metadata link in the data formatting table use that link to determine how sites are characterized.

#  -- If sampling is nested (e.g., site, block, plot, quad as in this study), use each of the identifying fields and separate each field with an underscore. For nested samples be sure the order of concatenated columns goes from coarser to finer scales (e.g. "km_m_cm")

# -- If sites are listed as lats and longs, use the finest available grain and separate lat and long fields with an underscore.

# -- If the site definition is clear, make a new site column as necessary.

# -- If the dataset is for just a single site, and there is no site column, then add one.

# Here, we will concatenate all of the potential fields that describe the site 
# in hierarchical order from largest to smallest grain. Based on the dataset,
# fill in the fields that specify nested spatial grains below.

#####
site_grain_names = c("site")

# We will now create the site field with these codes concatenated if there
# are multiple grain fields. Otherwise, site will just be the single grain field.
num_grains = length(site_grain_names)

site = dataset2[, site_grain_names[1]]
if (num_grains > 1) {
  for (i in 2:num_grains) {
    site = paste(site, dataset2[, site_grain_names[i]], sep = "_")
  } 
}

# What is the spatial grain of the finest sampling scale? For example, this might be
# a 0.25 m2 quadrat, or a 5 m transect, or a 50 ml water sample.

dataFormattingTable[,'Raw_spatial_grain'] = 
  dataFormattingTableFieldUpdate(datasetID, 'Raw_spatial_grain',  
                                 
                                 #--! PROVIDE INFO !--#
                                 2000) 

dataFormattingTable[,'Raw_spatial_grain_unit'] = 
  dataFormattingTableFieldUpdate(datasetID, 'Raw_spatial_grain_unit',  
                                 
                                 #--! PROVIDE INFO !--#
                                 'm2') 


# BEFORE YOU CONTINUE. We need to make sure that there are at least minNTime for sites at the coarsest possilbe spatial grain. 

siteCoarse = dataset2[, site_grain_names[1]]

if (dateformat == '%Y' | dateformat == '%y') {
  dateYear = dataset2$date
} else {
  dateYear = format(dataset2$date, '%Y')
}

datasetYearTest = data.frame(siteCoarse, dateYear)

ddply(datasetYearTest, .(siteCoarse), summarise, 
      lengthYears =  length(unique(dateYear)))

# If the dataset has less than minNTime years per site, do not continue processing. 


# Do some quality control by comparing the site fields in the dataset with the new vector of sites:

head(site)

# Check how evenly represented all of the sites are in the dataset. If this is the
# type of dataset where every site was sampled on a regular schedule, then you
# expect to see similar values here across sites. Sites that only show up a small
# percent of the time may reflect typos.

data.frame(table(site))

# All looks correct, so replace the site column in the dataset (as a factor) and remove the unnecessary fields, start by renaming the dataset to dataset2:

dataset3 = dataset2

dataset3$site = factor(site)

# Check the new dataset (are the columns as they should be?):

head(dataset3)

# !GIT-ADD-COMMIT-PUSH AND DESCRIBE HOW THE SITE DATA WERE MODIFIED!

# !DATA FORMATTING TABLE UPDATE! 

# Raw_siteUnit. How a site is coded (i.e. if the field was concatenated such as this one, it was coded as "site_block_plot_quad"). Alternatively, if the site were concatenated from latitude and longitude fields, the encoding would be "lat_long". 

dataFormattingTable[,'Raw_siteUnit'] = 
  dataFormattingTableFieldUpdate(datasetID, 'Raw_siteUnit',       # Fill value below in quotes

#####
                                 'site') 


# spatial_scale_variable. Is a site potentially nested (e.g., plot within a quad or decimal lat longs that could be scaled up)? Y/N

dataFormattingTable[,'spatial_scale_variable'] = 
  dataFormattingTableFieldUpdate(datasetID, 'spatial_scale_variable',

#####
                                 'N') # Fill value here in quotes

# Notes_siteFormat. Use this field to THOROUGHLY describe any changes made to the site field during formatting.

dataFormattingTable[,'Notes_siteFormat'] = 
  dataFormattingTableFieldUpdate(datasetID, 'Notes_siteFormat',  # Fill value below in quotes

#####
  'Site is a 2000 m2 (20 x 100 m transect) area surveyed over 30 minutes')


#-------------------------------------------------------------------------------*
# ---- EXPLORE AND FORMAT COUNT DATA ----
#===============================================================================*
# Next, we need to explore the count records. For filling out the data formatting table, we need to change the name of the field which represents counts, densities, percent cover, etc to "count". Then we will clean up unnecessary values.

names(dataset3)
summary(dataset3)

# This dataset has two fields with abundance info, 'abundance' which is categorical,
# and 'count' which is numeric. Prior to 2003, no numeric values are provided.
# When 'abundance' is NA, "this is eqivalent to saying the fish was not observed, 
# and later in the dataset is typically paired with a count of "0"."

# Here, we replace all NA's in the count field with numeric values based on the
# reported definition of abundance categories in the metadata:

# Abundance category  Equivalent count  Replaced value
#     Single              1                 1
#     Few               2 - 10              6
#     Common            11 - 100            55
#     Many                100+              100

dataset3$count[is.na(dataset3$count) & dataset3$abundance == "Single"] = 1
dataset3$count[is.na(dataset3$count) & dataset3$abundance == "Few"] = 6
dataset3$count[is.na(dataset3$count) & dataset3$abundance == "Common"] = 55
dataset3$count[is.na(dataset3$count) & dataset3$abundance == "Many"] = 100
dataset3$count[is.na(dataset3$count) & is.na(dataset3$abundance)] = 0

# Now drop the categorical abundance field
dataset3 = dataset3[, -which(names(dataset3) == 'abundance')]

# Fill in the original field name here

#####
countfield = 'count'

# Renaming it
names(dataset3)[which(names(dataset3) == countfield)] = 'count'

# Now we will remove zero counts and NA's:

summary(dataset3)

# Can usually tell if there are any zeros or NAs from that summary(). If there aren't any showing, still run these functions or continue with the update of dataset# so that you are consistent with this template.

# Subset to records > 0 (if applicable):
dataset4 = subset(dataset3, count > 0) 

summary(dataset4)

# Check to make sure that by removing 0's that you haven't completely removed
# any sampling events in which nothing was observed. Compare the number of 
# unique site-dates in dataset3 and dataset4.

# If there are no sampling events lost, then we can go ahead and use the 
# smaller dataset4 which could save some time in subsequent analyses.
# If there are sampling events lost, then we'll keep the 0's (use dataset3).
numEventsd3 = nrow(unique(dataset3[, c('site', 'date')]))
numEventsd4 = nrow(unique(dataset4[, c('site', 'date')]))
if(numEventsd3 > numEventsd4) {
  dataset4 = dataset3
} else {
  dataset4 = dataset4
}

# Remove NA's:

dataset5 = na.omit(dataset4)

head(dataset5)

# !GIT-ADD-COMMIT-PUSH AND DESCRIBE HOW THE COUNT DATA WERE MODIFIED!

#!DATA FORMATTING TABLE UPDATE!

# Possible values for countFormat field are density, cover, presence and count.

dataFormattingTable[,'countFormat'] = 
  dataFormattingTableFieldUpdate(datasetID, 'countFormat',    # Fill value below in quotes

#####                                 
                                 'count')

dataFormattingTable[,'Notes_countFormat'] = 
  dataFormattingTableFieldUpdate(datasetID, 'Notes_countFormat', # Fill value below in quotes
                                 
#####                                 
                                 'Data prior to 2003 include abundance categories rather than numeric counts that were converted to numeric values based on category midpoints.')

#-------------------------------------------------------------------------------*
# ---- EXPLORE AND FORMAT SPECIES DATA ----
#===============================================================================*
# Here, your primary goal is to ensure that all of your species are valid. To do so, you need to look at the list of unique species very carefully. Avoid being too liberal in interpretation, if you notice an entry that MIGHT be a problem, but you can't say with certainty, create an issue on GitHub.

# First, what is the field name in which species or taxonomic data are stored? 
# It will get converted to 'species'

#####
speciesField = 'scientificname'

dataset5$species = dataset5[, speciesField]
dataset5 = dataset5[, -which(names(dataset5) == speciesField)]

# Look at the individual species present and how frequently they occur: This way you can more easily scan the species names (listed alphabetically) and identify potential misspellings, extra characters or blank space, or other issues.

data.frame(table(dataset5$species))

# If there are entries that only specify the genus while there are others that specify the species in addition to that same genus, they need to be regrouped in order to avoid ambiguity. For example, if there are entries of 'Cygnus', 'Cygnus_columbianus', and 'Cygnus_cygnus', 'Cygnus' could refer to either species, but the observer could not identify it. This causes ambiguity in the data, and must be fixed by either 1. deleting the genus-only entry altogether, or 2. renaming the genus-species entries to just the genus-only entry. 
# This decision can be fairly subjective, but generally if less than 25% of the entries are genus-only, then they can be deleted (using bad_sp). If more than 25% of the entries for that genus are only specified to the genus, then the genus-species entries should be renamed to be genus-only (using typo_name). 

table(dataset5$species)

# If species names are coded (not scientific names) go back to study's metadata to learn what species should and shouldn't be in the data. 

# In this example, a quick look at the metadata is not informative, unfortunately. Because of this, you should really stop here and post an issue on GitHub. With some more thorough digging, however, I've found the names represent "Kartez codes". Several species can be removed (double-checked with USDA plant codes at plants.usda.gov and another Sevilleta study (dataset 254) that provides species names for some codes). Some codes were identified with this pdf from White Sands: https://nhnm.unm.edu/sites/default/files/nonsensitive/publications/nhnm/U00MUL02NMUS.pdf

#####
bad_sp = c('baitfish unidentified, all','Embiotocidae spp., adult', 'Embiotocidae spp., all', 
           'Embiotocidae spp., juvenile', 'Gobiidae spp.', 'larval fish spp., all', 
           'Neoclinus spp., all','Sebastes atrovirens/carnatus/caurinus/chrysomelas, juvenile',
           'Sebastes spp., adult', 'Sebastes spp., all', 'Sebastes spp., juvenile')

dataset6 = dataset5[!dataset5$species %in% bad_sp,]

# It may be useful to count the number of times each name occurs, as misspellings or typos will likely
# only show up one time.

table(dataset6$species)

# If you find any potential typos, try to confirm that the "mispelling" isn't actually a valid name.
# If not, then list the typos in typo_name, and the correct spellings in good_name,
# and then replace them using the for loop below:

# In this case, we are lumping juvenile and adult life stages into single taxonomic entities

#####
typo_name = c('Aulorhynchus flavidus, adult',
              'Aulorhynchus flavidus, juvenile',
              'Bathymasteridae spp., all',
              'Caulolatilus princeps, adult',
              'Chromis punctipinnis, adult',
              'Chromis punctipinnis, juvenile',
              'Citharichthys spp., all',
              'Embiotoca jacksoni, adult',
              'Embiotoca jacksoni, juvenile',
              'Embiotoca lateralis, adult',
              'Embiotoca lateralis, juvenile',
              'Gibbonsia elegans, all',
              'Gibbonsia montereyensis, all',
              'Girella nigricans, adult',
              'Girella nigricans, juvenile',
              'Halichoeres semicinctus, female',
              'Halichoeres semicinctus, male',
              'Halichoeres semicinctus, juvenile',
              'Heterostichus rostratus, adult',
              'Heterostichus rostratus, juvenile',
              'Hypsypops rubicundus, adult',
              'Hypsypops rubicundus, juvenile',
              'Medialuna californiensis, adult',
              'Ophiodon elongatus, adult',
              'Oxyjulis californica, adult',
              'Oxyjulis californica, juvenile',
              'Paralabrax clathratus, adult',
              'Paralabrax clathratus, juvenile',
              'Porichthys notatus, all',
              'Rhacochilus vacca, adult',
              'Rhacochilus vacca, juvenile',
              'Scorpaena guttata, adult',
              'Scorpaenichthys marmoratus, adult',
              'Scorpaenichthys marmoratus, juvenile',
              'Sebastes atrovirens, adult',
              'Sebastes atrovirens, juvenile',
              'Sebastes auriculatus, adult',
              'Sebastes auriculatus, juvenile',
              'Sebastes auriculatus , juvenile',
              'Sebastes carnatus, adult',
              'Sebastes carnatus, juvenile',
              'Sebastes caurinus, adult',
              'Sebastes caurinus, juvenile',
              'Sebastes chrysomelas, adult',
              'Sebastes chrysomelas/carnatus, juvenile',
              'Sebastes miniatus, adult',
              'Sebastes miniatus, juvenile',
              'Sebastes mystinus, adult',
              'Sebastes mystinus, juvenile',
              'Sebastes paucispinis, adult',
              'Sebastes paucispinis, juvenile',
              'Sebastes rastrelliger, adult',
              'Sebastes saxicola, adult',
              'Sebastes saxicola, juvenile',
              'Sebastes serranoides, adult',
              'Sebastes serranoides/flavidus, juvenile', #only 2 flavidus adults in dataset
              'Sebastes serriceps, adult',
              'Sebastes serriceps, juvenile',
              'Semicossyphus pulcher, male',
              'Semicossyphus pulcher, female',
              'Semicossyphus pulcher, juvenile',
              'Stereolepis gigas, adult'
              )
#####
good_name = c('Aulorhynchus flavidus, all',
              'Aulorhynchus flavidus, all',
              'Bathymasteridae, all',
              'Caulolatilus princeps, all',
              'Chromis punctipinnis, all',
              'Citharichthys stigmaeus, all',
              'Chromis punctipinnis, all',
              'Embiotoca jacksoni, all',
              'Embiotoca jacksoni, all',
              'Embiotoca lateralis, all',
              'Embiotoca lateralis, all',
              'Gibbonsia spp., all',
              'Gibbonsia spp., all',
              'Girella nigricans, all',
              'Girella nigricans, all',
              'Halichoeres semicinctus, all',
              'Halichoeres semicinctus, all',
              'Halichoeres semicinctus, all',
              'Heterostichus rostratus, all',
              'Heterostichus rostratus, all',
              'Hypsypops rubicundus, all',
              'Hypsypops rubicundus, all',
              'Medialuna californiensis, all',
              'Ophiodon elongatus, all',
              'Oxyjulis californica, all',
              'Oxyjulis californica, all',
              'Paralabrax clathratus, all',
              'Paralabrax clathratus, all',
              'Porichthys spp., all',
              'Rhacochilus vacca, all',
              'Rhacochilus vacca, all',
              'Scorpaena guttata, all',
              'Scorpaenichthys marmoratus, all',
              'Scorpaenichthys marmoratus, all',
              'Sebastes atrovirens, all',
              'Sebastes atrovirens, all',
              'Sebastes auriculatus, all',
              'Sebastes auriculatus, all',
              'Sebastes auriculatus, all',
              'Sebastes carnatus, all',
              'Sebastes carnatus, all',
              'Sebastes caurinus, all',
              'Sebastes caurinus, all',
              'Sebastes chrysomelas, all',
              'Sebastes chrysomelas, all',
              'Sebastes miniatus, all',
              'Sebastes miniatus, all',
              'Sebastes mystinus, all',
              'Sebastes mystinus, all',
              'Sebastes paucispinis, all',
              'Sebastes paucispinis, all',
              'Sebastes rastrelliger, all',
              'Sebastes saxicola, all',
              'Sebastes saxicola, all',
              'Sebastes serranoides, all',
              'Sebastes serranoides, all',
              'Sebastes serriceps, all',
              'Sebastes serriceps, all',
              'Semicossyphus pulcher, all',
              'Semicossyphus pulcher, all',
              'Semicossyphus pulcher, all',
              'Stereolepis gigas, all'
              )

if (length(typo_name) > 0) {
  for (n in 1:length(typo_name)) {
    dataset6$species[dataset6$species == typo_name[n]] = good_name[n]
  }
}


# Reset the factor levels:

dataset6$species = factor(dataset6$species)

# Let's look at how the removal of bad species and altered the length of the dataset:

nrow(dataset5)

nrow(dataset6)

# Look at the head of the dataset to ensure everything is correct:

head(dataset6)

# !GIT-ADD-COMMIT-PUSH AND DESCRIBE HOW THE SPECIES DATA WERE MODIFIED!

#!DATA FORMATTING TABLE UPDATE!

# Column M. Notes_spFormat. Provide a THOROUGH description of any changes made
# to the species field, including why any species were removed.


dataFormattingTable[,'Notes_spFormat'] = 
  dataFormattingTableFieldUpdate(datasetID, 'Notes_spFormat',    # Fill value below in quotes

#####                                 
  'Several unidentified taxa removed. Juvenile and adult (and occasionally male and female) classes of the same species were lumped into single entities.')

#-------------------------------------------------------------------------------*
# ---- MAKE DATA FRAME OF COUNT BY SITES, SPECIES, AND YEAR ----
#===============================================================================*
# Now we will make the final formatted dataset, add a datasetID field, check for errors, and remove records that cant be used for our purposes.

# First, lets add the datasetID:

dataset6$datasetID = datasetID
  
# Now make the compiled dataframe:

dataset7 = ddply(dataset6,.(datasetID, site, date, species),
                 summarize, count = sum(count))

# Explore the data frame:

dim(dataset7)

head(dataset7, 15)

summary(dataset7)

# !GIT-ADD-COMMIT-PUSH AND DESCRIBE HOW THE DATA WERE MODIFIED!
#-------------------------------------------------------------------------------*
# ---- UPDATE THE DATA FORMATTING TABLE AND WRITE OUTPUT DATA FRAMES  ----
#===============================================================================*

# Update the data formatting table (this may take a moment to process). Note that the inputs for this are 'datasetID', the datasetID and the dataset form that you consider to be fully formatted.

dataFormattingTable = dataFormattingTableUpdate(datasetID, dataset7)

# Take a final look at the dataset:

head(dataset7)

summary (dataset7)

# If everything is looks okay we're ready to write formatted data frame:

write.csv(dataset7, paste("data/formatted_datasets/dataset_", datasetID, ".csv", sep = ""), row.names = F)

# !GIT-ADD-COMMIT-PUSH THE FORMATTED DATASET IN THE DATA FILE, THEN GIT-ADD-COMMIT-PUSH THE UPDATED DATA FOLDER!

# As we've now successfully created the formatted dataset, we will now update the format flag field. 

dataFormattingTable[,'format_flag'] = 
  dataFormattingTableFieldUpdate(datasetID, 'format_flag',    # Fill value below
     
#####                                 
                                 1)

# Flag codes are as follows:
# 0 = not currently worked on
# 1 = formatting complete
# 2 = formatting in process
# 3 = formatting halted, issue
# 4 = data unavailable
# 5 = data insufficient for generating occupancy data

# !GIT-ADD-COMMIT-PUSH THE DATA FORMATTING TABLE!

###################################################################################*
# ---- END DATA FORMATTING. START PROPOCC AND DATA SUMMARY ----
###################################################################################*
# We have now formatted the dataset to the finest possible spatial and temporal grain, removed bad species, and added the dataset ID. It's now to make some scale decisions and determine the proportional occupancies.

# Load additional required libraries and dataset:

library(dplyr)
library(tidyr)

# Read in formatted dataset if skipping above formatting code (lines 1-450).

#dataset7 = read.csv(paste("data/formatted_datasets/dataset_",
#                         datasetID, ".csv", sep =''))

# Have a look at the dimensions of the dataset and number of sites:

dim(dataset7)
length(unique(dataset7$site))
length(unique(dataset7$date))
head(dataset7)

# Get the data formatting table for that dataset:

dataDescription = dataFormattingTable[dataFormattingTable$dataset_ID == datasetID,]

# or read it in from the saved data_formatting_table.csv if skipping lines 1-450.

#dataDescription = subset(read.csv("data_formatting_table.csv"),
#                             dataset_ID == datasetID)

# Check relevant table values:

dataDescription$LatLong_sites

dataDescription$spatial_scale_variable

dataDescription$Raw_siteUnit

dataDescription$subannualTgrain

# Before proceeding, we need to make decisions about the spatial and temporal grains at
# which we will conduct our analyses. Except in unusual circumstances, the temporal
# grain will almost always be 'year', but the spatial grain that best represents the
# scale of a "community" will  vary based on the sampling design and the taxonomic 
# group. Justify your spatial scale below with a comment.

#####
tGrain = 'year'

# Refresh your memory about the spatial grain names if this is NOT a lat-long-only
# based dataset. Set sGrain = to the hierarchical scale for analysis.

# HOWEVER, if the sites are purely defined by lat-longs, then sGrain should equal
# a numerical value specifying the block size in degrees latitude for analysis.

site_grain_names

#####
sGrain = 'site'

# This is a reasonable choice of spatial grain because ...
# ...this is the only spatial resolution of the study. Sites are typically separated
# by tens to 100s of km, so it does not make sense to aggregate them in most cases.

# The function "richnessYearSubsetFun" below will subset the data to sites with an 
# adequate number of years of sampling and species richness. If there are no 
# adequate years, the function will return a custom error message and you can
# try resetting sGrain above to something coarser. Keep trying until this
# runs without an error. If a particular sGrain value led to an error in this 
# function, you can make a note of that in the spatial grain justification comment
# above. If this function fails for ALL spatial grains, then this dataset will
# not be suitable for analysis and you can STOP HERE.

richnessYearsTest = richnessYearSubsetFun(dataset7, spatialGrain = sGrain, 
                                          temporalGrain = tGrain, 
                                          minNTime = minNTime, 
                                          minSpRich = minSpRich,
                                          dataDescription)

head(richnessYearsTest)
dim(richnessYearsTest) ; dim(dataset7)

#Number of unique sites meeting criteria
goodSites = unique(richnessYearsTest$analysisSite)
length(goodSites)

# Now subset dataset7 to just those goodSites as defined. This is tricky though
# because assuming Sgrain is not the finest resolution, we will need to use
# grep to match site names that begin with the string in goodSites.
# The reason to do this is that sites which don't meet the criteria (e.g. not
# enough years of data) may also have low sampling intensity that constrains
# the subsampling level of the well sampled sites.

uniqueSites = unique(dataset7$site)
fullGoodSites = c()
for (s in goodSites) {
  tmp = as.character(uniqueSites[grepl(paste(s, "_", sep = ""), paste(uniqueSites, "_", sep = ""))])
  fullGoodSites = c(fullGoodSites, tmp)
}

dataset8 = subset(dataset7, site %in% fullGoodSites)

# Once we've settled on spatial and temporal grains that pass our test above,
# we then need to 1) figure out what levels of spatial and temporal subsampling
# we should use to characterize that analysis grain, and 2) subset the
# formatted dataset down to that standardized level of subsampling.

# For example, if some sites had 20 spatial subsamples (e.g. quads) per year while
# others had only 16, or 10, we would identify the level of subsampling that 
# at least 'topFractionSites' of sites met (with a default of 50%). We would 
# discard "poorly subsampled" sites (based on this criterion) from further analysis. 
# For the "well-sampled" sites, the function below randomly samples the 
# appropriate number of subsamples for each year or site,
# and bases the characterization of the community in that site-year based on
# the aggregate of those standardized subsamples.

dataSubset = subsetDataFun(dataset8, 
                           datasetID, 
                           spatialGrain = sGrain, 
                           temporalGrain = tGrain,
                           minNTime = minNTime, minSpRich = minSpRich,
                           proportionalThreshold = topFractionSites,
                           dataDescription)

subsettedData = dataSubset$data

# Take a look at the propOcc:

head(propOccFun(subsettedData))

hist(propOccFun(subsettedData)$propOcc)

# Take a look at the site summary frame:

siteSummaryFun(subsettedData)

# If everything looks good, write the files:

writePropOccSiteSummary(subsettedData)

# Save the spatial and temporal subsampling values to the data formatting table:
dataFormattingTable[,'Spatial_subsamples'] = 
  dataFormattingTableFieldUpdate(datasetID, 'Spatial_subsamples', dataSubset$w)

dataFormattingTable[,'Temporal_subsamples'] = 
  dataFormattingTableFieldUpdate(datasetID, 'Temporal_subsamples', dataSubset$z)


# Update Data Formatting Table with summary stats of the formatted,
# properly subsetted dataset
dataFormattingTable = dataFormattingTableUpdateFinished(datasetID, subsettedData)

# And write the final data formatting table:

write.csv(dataFormattingTable, 'data_formatting_table.csv', row.names = F)

# Remove all objects except for functions from the environment:

rm(list = setdiff(ls(), lsf.str()))

