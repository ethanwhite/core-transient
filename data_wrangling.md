# Core-Transient Dataset Wrangling Sprint

You'll be helping to enter and/or transform a dataset into a standardized format
that will facilitate its analysis under our core vs transient species framework.
Thanks! Below is a guide describing the organization of the repository and 
the steps you are expected to follow.

*Step 0:*  
Follow the instructions [here](https://github.com/hurlbertlab/core-transient/blob/master/Reference/git_generate_ssh_windows.md) to set up (clone) the core-transient repository and data submodule for 
the first time. This involves getting a ssh key prior to using `git clone` and 
`git submodule`.
WARNING: This repository takes up 1+ GB of space!


*Step 1:*  
Identify a dataset to work on. For the Sprint, choose from the datasets
listed at this [GoogleDoc](https://docs.google.com/spreadsheets/d/1WtfzSf5oEhFdhZcaCyygpR0K0I6EcjPUzwkBfFnfjtY/edit?usp=sharing).
Write your name under the 'data_wrangler' field so that no one else tries to
work on the same dataset. If this is not part of the Sprint, then you may 
just be working down the list of datasets that haven't yet been incorporated
based on the 'data_formatting_table.csv' file in the main repository.

*Step 2:*  
Check to see whether the raw dataset is already in repository. If so, it will
be in the /data/raw_datasets folder, and will be called dataset_XXX.csv, where
XXX is the datasetID from the Data Formatting Table. If there is no dataset
in this folder, then either a digital form doesn't exist (e.g., the data could
be in a table in a published paper which you will need to enter) or it hasn't 
been downloaded yet. 

*Step 3:*  
Click on the link in the 'data_source' field. If there was do raw data file in
the repository, then you should be able to figure out how to obtain the data
from this link. Regardless, this link should take you either to a published paper
or a data repository that has a description of the dataset including all of
the relevant methods that will be useful in understanding that dataset.

*Step 4:*
Save the raw dataset (if it wasn't already there) into the /data/raw_datasets 
folder with the name dataset_XXX.csv where XXX is the datasetID. You then need
to update the git repository by adding, committing, and pushing from inside
the data submodule, as well as by adding, committing, and pushing from the main
repository. Do the following:
```
cd data
git status
git add raw_datasets/dataset_XXX.csv [modify as appropriate]
git commit -m "adding raw dataset XXX to submodule"
git push origin master
cd ..
git add data
git commit -m "updating data submodule with new raw dataset"
git push origin master
```

*Step 5:*  
Using RStudio, open the 'data_formatting_template.R' which can be found in
/scripts/R-scripts/data_cleaning_scripts/. Immediately click on Save As and 
rename the file as 'dwork_XXX_III.R' where XXX is the datasetID and III are your
initials.

*Step 6:*  
Fill in the the dataset name, paste in the data_source link from the Data
Formatting Table, and add your name in the top commented section.

*Step 7:*  
Follow instructions in the data_formatting_template file. You will first want to
set your working directory in R using something like:

`setwd('c:/git/core-transient/')`

depending on where on your machine you have cloned the core-transient repository.
You should run each line of code, and read along with the comments so you
understand what each section is doing. Whenever you see a comment like this:

\#--! PROVIDE INFO !--\#

this means you are expected to fill in or modify the subsequent line of code
based on the dataset you are working on. Filling in some of this information
will require a detailed understanding of the sampling methodology (what was
the sampling scale, did they have hierarchical sampling levels like quadrats
within plots, how frequently did they sample, etc). You will be constantly 
referring back to the paper or website that describes the study.

*Step 7a:*
Throughout the data_formatting_template you are asked to git add-commit-push to
save your changes and keep the file up to date in the git repository. This means
at each prompting you should do this (making sure you are in the core-transient 
folder, not the data folder).
```
git commit -am "<short informative message about your changes>"
git push origin master
```

*Step 8:*  
When you are finished formatting the dataset (or if you have finished your
work for the day), be sure to save it. We now need to commit all of the changes
we have made to the repository, including the creation of new files (like
the formatted dataset, and a siteSummary file, etc). Try the following in the 
Git bash window, filling in the appropriate datasetID for XXX:

```
cd data
git status
git add formatted_datasets/dataset_XXX.csv
git add siteSummaries/siteSummary_XXX.csv
git add propOcc_datasets/propOcc_XXX.csv
git commit -am "added formatted dataset, site summary, and propOcc for dXXX"

cd ..
git add scripts/R-scripts/data_cleaning_scripts/dwork_XXX_III.R
git add data_formatting_table.csv
git commit -m "added cleaning script for dXXX and modified formatting table"
git commit -am "updated data subrepo with data and summary files for dXXX"
git push origin master
git status
```

All of your changes have now been pushed to the master repository!

FEEL FREE TO ASK QUESTIONS AT ANY TIME IF SOMETHING IS UNCLEAR. ALMOST ALL
DATASETS HAVE *something* WEIRD OR UNCLEAR ABOUT THEM!

###Happy wrangling!
