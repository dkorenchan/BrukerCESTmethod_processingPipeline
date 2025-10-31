# Python Dictionary Simulation and Matching 
This directory contains a snapshot version of the Python code available through the Momentum Laboratory:

<a href="https://github.com/momentum-laboratory/molecular-mrf">momentum-laboratory/molecular-mrf repository</a>

It also contains some additional modified Python files that interface with the MATLAB code included in this repository. This Python code is called by the MATLAB code during its execution for CEST-MRF dictionary simulation and matching. 
## Setup and Installation

<b>IMPORTANT NOTE:</b> This code is only currently tested for use with a Mac with an M1 chip. Please let me know if you would like to use it with another OS/computer and I will be happy to help you get it set up.

This Python code currently works by activating two virtual environments simultaneously. One is an Anaconda/Miniforge environment which is contained in the .yml file in the following subdirectory: 

for_installing_conda_env/ 

The other is a Python virtual environment contained in the following subdirectory:

dkpymrf/

The reason for these two environments is, I believe, due to the complexities of the M1 chip. Somehow I got this working at one point, and I don't have the time to figure out a different approach. I hope that Linux users or Mac users with more recent M-series chips will have an easier time getting things working!

### Steps

1. Install Anaconda or Miniforge.
2. Download this code from GitHub.
3. In a terminal, navigate to this_directory/for_installing_conda_env/.
4. Create a new Anaconda/Miniforge environment from the .yml file with this command:
```
conda env create -f MRFcondaenv_base_environment.yml
```
5. 
