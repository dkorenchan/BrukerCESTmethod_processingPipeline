# Bruker CEST-MRF Pulse Sequence, for ParaVision 360 3.5

This folder contains the files and installation instructions for ParaVision 360 V3.5 sequence files, right now only for the EPI imaging readout. 

## Installation Instructions

There are two ways of installing the sequence files. One is to import the source files in Bruker format, and the other is to copy the files to the correct directories on the scanner computer and then build/install the full method. Both are documented below.

(NOTE: These instructions are specific for ParaVision installed on a Linux computer. Paths to directories may be slightly different on another operating system.)

### Method 1: Importing Bruker Source Files

1. Download the files in directory source-files_for_import/ in this repository to the Bruker scanner computer running ParaVision 360 V3.5.
2. Place the downloaded files in the directory /opt/PV-360.3.5/share/.
3. Open ParaVision 360 V3.5 on your scanner computer.
4. In ParaVision, go to the Workspace Explorer. (If you do not see it open in a tab, you may need to click Window > Workspace Explorer on the top toolbar.)
5. Under Method Development/, right-click on User Methods (username) and select Import > Source Method...
6. On the lefthand side of the window that pops up, select the Share folder, then the file fpSL_EPI_360.3.5.PvUserSrcMethod from the list.
7. Back in the Workspace Explorer, under Pulse Programs/, right-click on User Methods (username) and select Import...
8. On the lefthand side of the window that pops up, select the Share folder, then the file fpSL_EPI_PrepModulesHead_FpSL_modFile_360.3.5.PvUserPulseProgram from the list.
9. Repeat Steps 7-8 above and select the file fpSL_EPI_SatTrans_FpSL_comboSL_modFile_360.3.5.PvUserPulseProgram.
10. Back in the Workspace Explorer, under Method Development/User Methods (username)/, right-click on fpSL_EPI and select Build/Install...

If the sequence compiled correctly, you are ready to use it!

### Method 2: Copying Raw Files to Computer, then Build/Install

1. Download the files in directory raw_files/ in this repository to the Bruker scanner computer running ParaVision 360 V3.5.
2. Expand the fpSL_EPI.zip file, then move/copy the entire folder to /opt/PV-360.3.5/prog/curdir/[insert username here]/ParaVision/methods/src/.
3. Move/copy both .mod files to /opt/PV-360.3.5/prog/curdir/[insert username here]/ParaVision/exp/lists/pp/.
4. Open ParaVision 360 V3.5 on your scanner computer.
5. In ParaVision, go to the Workspace Explorer. (If you do not see it open in a tab, you may need to click Window > Workspace Explorer on the top toolbar.)
6. Back in the Workspace Explorer, under Method Development/User Methods (username)/, right-click on fpSL_EPI and select Build/Install...

If the sequence compiled correctly, you are ready to use it!