# CEST-MRF Processing Code
This directory contains the following subdirectories:
1. MATLAB code for the main processing scripts available. **THIS IS THE MAIN CODE TO RUN, THROUGH MATLAB.**
2. Python code that is called for CEST-MRF dictionary simulation and matching. This contains additional Python scripts to be added onto the front end of the processing pipeline in the <a href="https://github.com/momentum-laboratory/molecular-mrf">momentum-laboratory/molecular-mrf repository</a>. The Python code is called by the MATLAB code during its execution.
## Setup and Installation
Please see the README.md file within each subdirectory for more information on how to setup the respective MATLAB and Python code.
## IMPORTANT NOTES
 - As of the time of writing, ALL datasets specified in the program must have the SAME FOV and SAME 2D MATRIX SIZE for ROI processing to work between MRF maps, z-spectroscopy data, and other images! (T1 maps, T2 maps, QUESP imaging, WASSR imaging) Be sure to acquire your data accordingly! 

