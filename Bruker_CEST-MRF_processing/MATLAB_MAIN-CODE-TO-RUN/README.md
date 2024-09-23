# MATLAB CEST-MRF Processing Functions 
This directory contains MATLAB code for processing study directories obtained from a Bruker preclinical scanner running ParaVision (versions up to PV360). The code calls Python code in another directory to perform dictionary simulation and matching.
## Setup and Installation
1. Download this entire directory to a folder on your MATLAB path
2. Update the contents of each .m folder within MAIN_FILES_TO_EDIT/
   - initUserSettings.m: This contains configuration information, especially the paths to your main Bruker data, the Python code, and where to save data, as well as other things such as the names of the conda environment to activate
   - DictConfigParams.m: This is the file where you will set up the parameter ranges for your dictionary simulation: T1/T2 values, exchange rates, proton volume fractions, etc.
   - initPlotParams.m: The main thing to change in this file is the color bar ranges for image display within the GUI
3. 
