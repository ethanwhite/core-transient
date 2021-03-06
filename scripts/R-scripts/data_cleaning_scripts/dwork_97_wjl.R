################################################################################*
#  DATASET 97: Arctic Sea Zooplankton
#
#  Data info can be found at http://iobis.org/mapper/?dataset=2282

# As a pelagic dataset with only lat-longs as site identifiers, we've decided the data are unsuitable 
# for analysis of temporal occupancy at a relevant assemblage scale.

# NO NEED TO RUN SCRIPT


#-------------------------------------------------------------------------------*
# ---- SET-UP ----
#===============================================================================*

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

datasetID = 97 

list.files('data/raw_datasets')

dataset = read.csv(paste('data/raw_datasets/dataset_', datasetID, '.csv', sep = ''))

dataFormattingTable = read.csv('data_formatting_table.csv')

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

unusedFields = c(1, 2)

dataset1 = dataset[,-unusedFields]

# Let's change the name of the "Species" column to simply "species":

names(dataset1)[3] = 'species'

head(dataset1, 10)

# !GIT-ADD-COMMIT-PUSH AND DESCRIBE HOW THE DATA WERE MODIFIED!

#!DATA FORMATTING TABLE UPDATE! 
# Are the ONLY site identifiers the latitude and longitude of the observation or 
# sample? (I.e., there are no site names or site IDs or other designations) Y/N

dataFormattingTable[,'LatLong_sites'] = 
  dataFormattingTableFieldUpdate(datasetID, 'LatLong_sites',   # Fill value in below
                                 
                                 'Y') 


#-------------------------------------------------------------------------------*
# ---- FORMAT TIME DATA ----
#===============================================================================*
# Here, we need to extract the sampling dates. 

# What is the name of the field that has information on sampling date?
datefield = 'Year'

# What is the format in which date data is recorded? For example, if it is
# recorded as 5/30/94, then this would be '%m/%d/%y', while 1994-5-30 would
# be '%Y-%m-%d'. Type "?strptime" for other examples of date formatting.

dateformat = '%Y'

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
dataset2 = dataset2[, -which(names(dataset2) == datefield)]

# Assign the new date values in a field called 'date'
dataset2$date = date

# Check the results:

head(dataset2)

# !GIT-ADD-COMMIT-PUSH AND DESCRIBE HOW THE DATE DATA WERE MODIFIED!

#!DATA FORMATTING TABLE UPDATE!

# Notes_timeFormat. Provide a thorough description of any modifications that were made to the time field.

dataFormattingTable[,'Notes_timeFormat'] = 
  dataFormattingTableFieldUpdate(datasetID, 'Notes_timeFormat',  # Fill value in below
                                 
                                 'temporal data provided as years. The only modification to this field involved converting to a numeric object.')

# subannualTgrain. After exploring the time data, was this dataset sampled at a sub-annual temporal grain? Y/N

dataFormattingTable[,'subannualTgrain'] = 
  dataFormattingTableFieldUpdate(datasetID, 'subannualTgrain',    # Fill value in below
                                 
                                 'N')

#-------------------------------------------------------------------------------*
# ---- EXPLORE AND FORMAT SITE DATA ----
#===============================================================================*

#  -- If sampling is nested (e.g., site, block, treatment, plot, quad as in this study), use each of the identifying fields and separate each field with an underscore. For nested samples be sure the order of concatenated columns goes from coarser to finer scales (e.g. "km_m_cm")

# -- If sites are listed as lats and longs, use the finest available grain and separate lat and long fields with an underscore.

# -- If the site definition is clear, make a new site column as necessary.

# -- If the dataset is for just a single site, and there is no site column, then add one.

# Here, we will concatenate all of the potential fields that describe the site 
# in hierarchical order from largest to smallest grain. Based on the dataset,
# fill in the fields that specify nested spatial grains below.

site_grain_names = c("SampleID")

# We will now create the site field with these codes concatenated if there
# are multiple grain fields. Otherwise, site will just be the single grain field.
num_grains = length(site_grain_names)

site = dataset2[, site_grain_names[1]]
if (num_grains > 1) {
  for (i in 2:num_grains) {
    site = paste(site, dataset2[, site_grain_names[i]], sep = "_")
  } 
}

# Only useful info in each site entry is lat/long coordinates. 

site = paste(word(site,-2,sep="_"),word(site,-1,sep="_"), sep="_")

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

dataset3 = dataset3[,-c(1)]

# Check the new dataset (are the columns as they should be?):

head(dataset3)

# !GIT-ADD-COMMIT-PUSH AND DESCRIBE HOW THE SITE DATA WERE MODIFIED!

# !DATA FORMATTING TABLE UPDATE! 

# Raw_siteUnit. How a site is coded (i.e. if the field was concatenated such as this one, it was coded as "site_block_treatment_plot_quad"). Alternatively, if the site were concatenated from latitude and longitude fields, the encoding would be "lat_long". 

dataFormattingTable[,'Raw_siteUnit'] = 
  dataFormattingTableFieldUpdate(datasetID, 'Raw_siteUnit',       # Fill value below in quotes
                                 
                                 'lat_long') 


# spatial_scale_variable. Is a site potentially nested (e.g., plot within a quad or decimal lat longs that could be scaled up)? Y/N

dataFormattingTable[,'spatial_scale_variable'] = 
  dataFormattingTableFieldUpdate(datasetID, 'spatial_scale_variable',
                                 
                                 'Y') # Fill value here in quotes

# Notes_siteFormat. Use this field to THOROUGHLY describe any changes made to the site field during formatting.

dataFormattingTable[,'Notes_siteFormat'] = 
  dataFormattingTableFieldUpdate(datasetID, 'Notes_siteFormat',  # Fill value below in quotes
                                 
                                 'only useful information was lat/long values. removed other unneccessary informaton')


#-------------------------------------------------------------------------------*
# ---- EXPLORE AND FORMAT COUNT DATA ----
#===============================================================================*
# Next, we need to explore the count records. For filling out the data formatting table, we need to change the name of the field which represents counts, densities, percent cover, etc to "count". Then we will clean up unnecessary values.

names(dataset3)
summary(dataset3)

# Fill in the original field name here
countfield = 'Abundance'

# Renaming it
names(dataset3)[which(names(dataset3) == countfield)] = 'count'

# Now we will remove zero counts and NA's:

summary(dataset3)

# Summary says that the minimum value for count is 0.0, but that is just because the values are so small (as small as 1x10^-4) and the summary function rounds to the 1st decimal place. 

# Subset to records > 0 (if applicable):

dataset4 = subset(dataset3, count > 0) 

summary(dataset4)

# Remove NA's:

dataset5 = na.omit(dataset4)


# How does it look?

head(dataset5)

# !GIT-ADD-COMMIT-PUSH AND DESCRIBE HOW THE COUNT DATA WERE MODIFIED!

#!DATA FORMATTING TABLE UPDATE!

# Possible values for countFormat field are density, cover, presence and count.
dataFormattingTable[,'countFormat'] = 
  dataFormattingTableFieldUpdate(datasetID, 'countFormat',    # Fill value below in quotes
                                 
                                 'density')

dataFormattingTable[,'Notes_countFormat'] = 
  dataFormattingTableFieldUpdate(datasetID, 'Notes_countFormat', # Fill value below in quotes
                                 
                                 'Data represents density. There were no NAs or 0s were present')

#-------------------------------------------------------------------------------*
# ---- EXPLORE AND FORMAT SPECIES DATA ----
#===============================================================================*

# Look at the individual species present:

levels(dataset5$species) 

# The first thing that I notice is that there are lower and upper case entries. Because R is case-sensitive, this will be coded as separate species. Modify this prior to continuing:

dataset5$species = factor(toupper(dataset5$species))

# Now explore the listed species themselves, again. A good trick here to finding problematic entries is to shrink the console below horizontally so that species names will appear in a single column.  This way you can more easily scan the species names (listed alphabetically) and identify potential misspellings, extra characters or blank space, or other issues.

levels(dataset5$species)

# First of all, there are many entries where there is an extra underscore at the end. These must be removed. 

for (i in 1:length(dataset5$species)){
  if (str_sub(dataset5$species[i], -1) == '_'){
    
    levels(dataset5$species) = c(levels(dataset5$species),str_sub(dataset5$species[i],1,nchar(as.character(dataset5$species[i]))-1))
    
    dataset5$species[i] = str_sub(dataset5$species[i],1,nchar(as.character(dataset5$species[i]))-1)
    
  } 
  
  
}

# If there are entries that only specify the genus while there are others that specify the species in addition to that same genus, they need to be regrouped in order to avoid ambiguity. For example, if there are entries of 'Cygnus', 'Cygnus_columbianus', and 'Cygnus_cygnus', 'Cygnus' could refer to either species, but the observer could not identify it. This causes ambiguity in the data, and must be fixed by either 1. deleting the genus-only entry altogether, or 2. renaming the genus-species entries to just the genus-only entry. 
# This decision can be fairly subjective, but generally if less than 25% of the entries are genus-only, then they can be deleted (using bad_sp). If more than 25% of the entries for that genus are only specified to the genus, then the genus-species entries should be renamed to be genus-only (using typo_name). 

table(dataset5$species)

### Entries where the genus-only entry is removed (# of genus of entries; # of species1 entries, # of species2 entries, etc.):

# Acartia: 27; 39, 172
# Aetideidae (family and genus 'Aetidopsis' to be removed): 62; 15; 9, 20, 1, 46, 1 
# Calanus: 132; 3, 639, 125, 367, 3
# Centropages: 4; 1, 26, 1
# Chiridius: 4; 69, 1
# Chiridiella: 30; 2, 4, 2, 16
# Conchoecia: 89; 31, 12, 3
# Eucalanus: 10; 3, 12
# Fritillaria: 106; 304, 1
# Gaetanus: 53; 66; 92
# Hyperiidae (family): 102; 8; 14, 4
# Jaschnovia: 4; 10, 58
# Leprotinnitus: 10; 13, 1
# Limacina: 5; 227, 27
# Lucicutia: 34; 9, 1, 1, 40
# Metridinae (family and genus 'Metridia' to be removed): 3; 35; 380, 1, 79, 1, 7
# Microcalanus: 59; 12, 319
# Oikopleura: 304; 2, 64, 82
# Oithona: 103: 1, 68, 602
# Oncaea: 74; 171, 1, 24, 32
# Paraeuchaeta: 135; 17, 152, 69, 25, 1
# Parafavella: 29; 5, 80, 1, 4, 15
# Pseudocalanus: 586; 1, 1, 2, 90, 108
# Sabinea: 1; 1, 2
# Sarsia: 15; 20, 2
# Scaphocalanus: 44; 88, 77, 3, 1, 14
# Spinocalanidae (family and genus 'Spinocalanus' to be removed): 11; 60; 65, 10, 51, 86, 5, 60, 1
# Themisto: 15; 76, 15, 60
# Thysanoessa: 11; 51, 52, 18
# Tintinnoidea (family and genus 'Tintinnopsis' to be removed): 5; 81; 13, 4, 25, 1, 5, 1
# Xanthocalanus: 19; 1, 3

bad_sp = toupper(c('Acartia', 'Aetideidae', 'Aetidopsis','Calanus','Centropages','Chiridius','Chiridiella','Conchoecia','Eucalanus','Fritillaria','Gaetanus','Jaschnovia','Hyperiidae'  ,'Leprotinnitus','Limacina','Lucicutia' ,'Metridinae' ,'Metridia' ,'Microcalanus' ,'Oikopleura' ,'Oithona' ,'Ocaea' ,'Paraeuchaeta' ,'Parafavella' ,'Pseudocalanus' ,'Sabinea' ,'Sarsia' ,'Scaphocalanus' ,'Spinocalanidae' ,'Spinocalanus' ,'Themisto' ,'Thysanoessa' ,'Tintinnoidea' ,'Xanthocalanus', 'Malacostraca'))

dataset6 = dataset5[!dataset5$species %in% bad_sp,]


### Entries where the species entries are consolidated into the genus-only entries, renaming them all to genus-only entry. 

# Aglantha: 10; 113
# Amphipoda (order): 84; 1, 2
# Echinodermata (phylum): 1; 1; 2 
# Beroe: 20; 24
# Catablema: 1; 6
# Clione: 48; 159
# Cyclopoida (order): 62; 3; 4
# Daphnia: 13; 5
# Dimophyes: 2; 119
# Eukrohnia: 9; 134
# Euphausiacea (order): 157; 5; 2
# Euphysa: 4; 61
# Eusirus: 1; 3
# Evadne: 3; 28
# Gammaridae (family): 31; 5
# Globigerina: 27; 2
# Halitholus: 1; 49
# Harpacticoida (family): 145; 17; 11; 11
# Heterorhabdus: 13; 75
# Keratella: 1; 2
# Lubbockia: 2; 61
# Mertensia: 6; 12
# Microsetella: 19; 117
# Mormonilla: 2; 69
# Mysidae: (family): 15; 3; 41
# Neocalanus: 6; 8
# Nereidae (family): 1; 5
# Obelia: 2; 27
# Onchocalanus: 2; 2
# Ophiuroidea: 8; 16
# Pelagobia: 1; 1
# Physophora: 1; 2
# Pseudochirella: 3; 42
# Ptychocylis: 39; 12
# Sagitta: 220; 107
# Scolecitrichidae (family): 51; 3; 97
# Sida: 1; 6
# Spiratellidae (family): 2; 2
# Spongotrochus: 1; 1
# Temora: 2; 33

# Moving species to genus level:

genuslist = toupper(c('Aglantha','Beroe','Catablema','Clione','Daphnia','Dimophyes','Eukrohnia','Euphysa','Eusirus','Evadne','Globigerina','Halitholus','Heterorhabdus','Keratella','Lubbockia','Mertensia','Microsetella','Mormonilla','Neocalanus','Obelia','Onchocalanus','Ophiuroidea','Pelagobia','Physophora','Pseudochirella','Ptychocylis','Sagitta','Sida','Spongotrochus','Temora'))

for (i in 1:length(dataset6$species)){
  
  
  if (any((word(dataset6$species[i],1,sep="_")) == genuslist)){
    
    dataset6$species[i] = (word(dataset6$species[i],1,sep="_"))
    # print((word(dataset6$species[i],1,sep="_")))
    
    
  
  }
  
}

# For other issues (to family or above):

typo_name = c('AMPHITHOPSIS_LONGICAUDATA',
              'CYCLOCARIS',
              'ASTERIAS',
              'ASTEROIDEA',
              'CYCLOPIDAE',
              'CYCLOPS',
              'EUPHAUSIA',
              'EUPHAUSIIDAE',
              'GAMMARIDEA',
              'GAMMARUS_WILKITZKII',
              'HARPACTICIDAE',
              'HARPACTICUS',
              'HARPACTICUS_UNIREMIS',
              'MYSIS',
              'MYSIS_OCULATA',
              'NEREIS',
              'SCOLECITHRICELLA_MINOR',
              'SCOLECITHRICELLA',
              'SPIRATELLA')

good_name = c('AMPHIPODA',
              'AMPHIPODA',
              'ECHINODERMATA',
              'ECHINODERMATA',
              'CYCLOPOIDA',
              'CYCLOPOIDA',
              'EUPHAUSIACEA',
              'EUPHAUSIACEA',
              'GAMMARIDAE',
              'GAMMARIDAE',
              'HARPACTICOIDA',
              'HARPACTICOIDA',
              'HARPACTICOIDA',
              'MYSIDAE',
              'MYSIDAE',
              'NEREIDAE',
              'SCOLECITRICHIDAE',
              'SCOLECITRICHIDAE',
              'SPIRATELLIDAE')

levels(dataset6$species) = c(levels(dataset6$species), typo_name)

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
                                 
                                 'several species removed. There were many instances where some entries were identified down to the species while others were not, leaving possible overlap. If there is one species under the genus-only entry, it is combined with the genus only entry, but if there is more than one species entry under a genus-only entry, the genus only entries are deleted. ')

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

# As we've now successfully created the formatted dataset, we will now update the format priority and format flag fields. 

dataFormattingTable[,'format_priority'] = 
  dataFormattingTableFieldUpdate(datasetID, 'format_priority',    # Fill value below in quotes 
                                 
                                 'NA')

dataFormattingTable[,'format_flag'] = 
  dataFormattingTableFieldUpdate(datasetID, 'format_flag',    # Fill value below
                                 
                                 1)

# And update the data formatting table:

write.csv(dataFormattingTable, 'data_formatting_table.csv', row.names = F)

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

tGrain = 'year'

# Refresh your memory about the spatial grain names if this is NOT a lat-long-only
# based dataset. Set sGrain = to the hierarchical scale for analysis.

# HOWEVER, if the sites are purely defined by lat-longs, then sGrain should equal
# a numerical value specifying the block size in degrees latitude for analysis.

site_grain_names

sGrain = 5

# This is a reasonable choice of spatial grain because it is the finest possible grain size that yields 3 sites. 

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
length(unique(richnessYearsTest$analysisSite))

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

subsettedData = subsetDataFun(dataset7, datasetID, spatialGrain = sGrain, 
                              temporalGrain = tGrain,
                              minNTime = minNTime, minSpRich = minSpRich,
                              proportionalThreshold = topFractionSites,
                              dataDescription)

# Take a look at the propOcc:

head(propOccFun(subsettedData))

hist(propOccFun(subsettedData)$propOcc)

# Take a look at the site summary frame:

siteSummaryFun(subsettedData)

# If everything looks good, write the files:

writePropOccSiteSummary(subsettedData)

# Remove all objects except for functions from the environment:

rm(list = setdiff(ls(), lsf.str()))
