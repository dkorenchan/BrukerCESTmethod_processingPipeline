/****************************************************************
 *
 * $Source$
 *
 * Copyright (c) 1999-2003
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 * $Id$
 *
 ****************************************************************/



/****************************************************************/
/* INCLUDE FILES						*/
/****************************************************************/

MRF_input_TYPE parameter
{
  display_name "MRF input mode";
  relations Fp_ReadFromFileRels;
} Fp_InputModeEnum;

enum_attributes MRF_input_TYPE
{
  display_name User_input  "User_input";
  display_name Read_from_file "Read_from_file";
};





double parameter ExSliceGradient;
double parameter ExSliceRephaseGradient;
double parameter RfcSpoilerStrength;
double parameter RfcSpoilerDuration;
double parameter OneRepTime;

double parameter SliceGradRatio;
double parameter ReadGradient;
double parameter MinTE_left;
double parameter MinTE_right;

double parameter 
{
  display_name "Rephasing/encoding time";
  relations RephaseTimeRels;
  units "ms";
  format "%.2f";
} RephaseTime;


int parameter 
{
  display_name "Segments";
  short_description "Number of Segments.";
  relations NSegmentsRels;
} NSegments;

double parameter
{
  display_name "Echo Time";
  units "ms";
  format "%.3f";
  relations backbone;
} EchoTime;

double parameter
{
  display_name "Inter-Volume Delay";
  short_description "Break after every volume acquisition.";
  format "%.2f";
  units "ms";
  relations PackDelRelation;
} PackDel;

PVM_SPOILER_TYPE parameter 
{
  display_name "Slice Spoiler";
  relations SliceSpoilerRel;
}SliceSpoiler;

PV_PULSE_LIST parameter
{
  display_name "Excitation Pulse Shape";
  relations    ExcPulseEnumRelation;
}ExcPulseEnum;

PV_PULSE_LIST parameter
{
  display_name "Refocusing Pulse Shape";
  relations    RefPulseEnumRelation;
}RefPulseEnum;

PV_PULSE_LIST parameter
{
  display_name "Spinlock Pre/Post Pulse Shape";
  relations    SLprepPulseEnumRelation;
}SLprepPulseEnum;

PV_PULSE_LIST parameter
{
  display_name "Spinlock Rfc. Pulse Shape";
  relations    SLrfcPulseEnumRelation;
}SLrfcPulseEnum;

PVM_RF_PULSE parameter
{
  display_name "Excitation Pulse";
  relations    ExcPulRelation;
}ExcPul;

PVM_RF_PULSE parameter
{
  display_name "Refocusing Pulse";
  relations    RefPulRelation;
}RefPul;

PVM_RF_PULSE parameter
{
  display_name "Spinlock Pre/Post Pulse";
  relations    SLprepPulRelation;
}SLprepPul;

PVM_RF_PULSE parameter
{
  display_name "Spinlock Refocusing Pulse";
  relations    SLrfcPulRelation;
}SLrfcPul;

PVM_RF_PULSE_AMP_TYPE parameter
{
  display_name "Excitation Pulse Amplitude";
  relations ExcPulseAmplRel;
}ExcPulseAmpl;

PVM_RF_PULSE_AMP_TYPE parameter
{
  display_name "Refocusing Pulse Amplitude";
  relations RefPulseAmplRel;
}RefPulseAmpl;

PVM_RF_PULSE_AMP_TYPE parameter
{
  display_name "Spinlock Pre/Post Pulse Amplitude";
  relations SLprepPulseAmplRel;
}SLprepPulseAmpl;

PVM_RF_PULSE_AMP_TYPE parameter
{
  display_name "Spinlock Refocusing Pulse Amplitude";
  relations SLrfcPulseAmplRel;
}SLrfcPulseAmpl;

double parameter
{
  editable false;
}ExcPulseShape[];

double parameter
{
  editable false;
}RefPulseShape[];

double parameter
{
  editable false;
}SLprepPulseShape[];

double parameter
{
  editable false;
}SLrfcPulseShape[];

YesNo parameter
{
  short_description "Calculates all delays on a 1us grid.";
  display_name "1us Gridding";
  relations backbone;
}TempGridding;

ImageSeriesReference parameter ParentDset;
YesNo parameter GopAdj;

/**********************************************************/  
/* parameters for MR finger print experiment              */ 
/**********************************************************/

int parameter
{
  display_name "Total Experiments";
  format "%d";
  minimum 1 outofrange nearestval;
maximum 1000 outofrange nearestval;  
  relations Fp_NExpRels;
} Number_fp_Experiments;

double parameter
{
  display_name "Ppg Power List1";
  format "%3f";
  relations Fp_NExpRels;
} PpgPowerList1[];

double parameter
{
  display_name "Ppg Power List2";
  format "%3f";
  relations Fp_NExpRels;
} PpgPowerList2[];

//dk add: extra power list for SL 90's
double parameter
{
  display_name "Ppg Power List3";
  format "%3f";
  relations Fp_NExpRels;
} PpgPowerList3[];

int parameter
{
  display_name "Ppg Power List3 size";
  format "%d";
  relations Fp_NExpRels;
} PpgPowerList3size;

int parameter
{
  display_name "Ppg Power List2 size";
  format "%d";
  relations Fp_NExpRels;
} PpgPowerList2size;

int parameter
{
  display_name "Ppg Power List1 size";
  format "%d";
  relations Fp_NExpRels;
} PpgPowerList1size;


double parameter
{
  display_name "Finger Print TRs";
  format "%.3f";
  units "ms";
  relations backbone;
} Fp_TRs[];

double parameter
{
  display_name "Finger Print TR padding";
  format "%.6f";
  units "s";
  relations backbone;
} Fp_TRDels[];

//double parameter
//{
//  display_name "Finger Print TR padding";
//  format "%.6f";
//  units "ms";
//  relations backbone;
//} Fp_TRPadding[];

double parameter
{
  display_name "Finger Print Sat Pow";
  format "%.3f";
  units "uT";
  relations backbone;
} Fp_SatPows[];

double parameter
{
  display_name "Finger Print Sat Offset";
  format "%.3f";
  //units "unit_ppm";
  relations backbone;
} Fp_SatOffset[];

double parameter
{
  display_name "Finger Print Flip Angle";
  format "%.3f";
  //units "degree";
  relations backbone;
} Fp_FlipAngle[];

double parameter
{
  display_name "Finger Print Sat Dur";
  format "%.3f";
  units "ms";
  relations backbone;
} Fp_SatDur[];

double parameter
{
  display_name "Finger Print Sat Dur";
  format "%.3f";
  units "us";
  relations backbone;
} Fp_SatDuration[];

char parameter
{
  display_name "Input MRF File Path Name";
  relations backbone;
} Fp_PathName[1024];

char parameter
{
  display_name "Input MRF File Name";
  relations backbone; 
} Fp_FileName[128];

int parameter
{
  display_name "Finger Print Sat Offset_Hz";
  format "%d";
  //units "Hz";
  relations backbone;
} Fp_SatOffsetHz[];

int parameter
{
  display_name "Finger Print Spin Lock Flag";
  format "%d";
  relations backbone;
} Fp_SLflag[];

double parameter
{
  display_name "Finger Print Pre-/Post-SL Flip Angle";
  format "%.3f";
  //units "degree";
  relations backbone;
} Fp_SLFlipAngle[];

//char parameter
//{
//  display_name "Input Sat Pulse File Name";
//  relations Fp_SatPulseRels; 
//} Fp_SatPulseFileName[128];

//char parameter
//{
//  display_name "Input MRF SatPow File Name";
//  relations fp_ReadFromFileRels; 
//} Fp_SatPowFileName[128];



/****************************************************************/
/*	E N D   O F   F I L E					*/
/****************************************************************/

