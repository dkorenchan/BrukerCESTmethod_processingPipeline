/****************************************************************
 *
 * Copyright (c) 1999-2022
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 ****************************************************************/

/****************************************************************/
/*	PARAMETER CLASSES				       	*/
/****************************************************************/


/*--------------------------------------------------------------*
 * Definition of the PV class...
 *--------------------------------------------------------------*/

pargroup
{
  PVM_EffSWh; 
  RephaseTime;
  PVM_MinFov;
  PVM_MinSliceThick;
  SliceSpoiler;
}
attributes
{
  display_name "Sequence Details";
} Sequence_Details;

pargroup
{
  ExcPulseEnum;
  ExcPul;
  ExcPulseAmpl;
  ExcPulseShape;
  RefPulseEnum;
  RefPul;
  RefPulseAmpl;
  RefPulseShape;
  SLprepPulseEnum;
  SLprepPul;
  SLprepPulseAmpl;
  SLprepPulseShape;  
  SLrfcPulseEnum;
  SLrfcPul;
  SLrfcPulseAmpl;
  SLrfcPulseShape;
} 
attributes
{
  display_name "RF Pulses";
} RF_Pulses;




pargroup
{
  DummyScans_Parameters;

  PVM_TriggerModule;
  Trigger_Parameters;

  PVM_TaggingOnOff;
  Tagging_Parameters;

  PVM_FatSupOnOff;
  Fat_Sup_Parameters;

  PVM_SatTransOnOff;
  Sat_Transfer_Parameters;

  PVM_FovSatOnOff;
  Fov_Sat_Parameters;

  PVM_TriggerOutOnOff;
  TriggerOut_Parameters;

  DriftComp_Parameters;
} Preparation;

pargroup
{      
  Number_fp_Experiments;  
  Fp_InputModeEnum;
  Fp_PathName;
  Fp_FileName;
  Fp_FlipAngle;
  Fp_SLFlipAngle;
  PpgPowerList2;
  Fp_TRs;
  Fp_TRDels;
  Fp_SatDur;
  Fp_SatPows;
  Fp_SatOffset;
  Fp_SatOffsetHz;
  Fp_SLflag;
  PpgPowerList1;
  PpgPowerList3;
  }
attributes
{
  display_name "MR Fingerprint Parameters";
} FpParameters;


extend pargroup
{
  PVM_EffSWh;
  EchoTime;
  PVM_MinEchoTime;
  PVM_EchoTime;
  NSegments;
  PVM_RepetitionTime;
  PackDel;
  FpParameters;
  PVM_NEchoImages;
  PVM_NAverages;
  PVM_NRepetitions;
  PVM_ScanTimeStr;
  PVM_ScanTime;
  PVM_SignalType;
  PVM_DeriveGains;
  Encoding;
  EPI_Parameters;
  RF_Pulses;
  Nuclei;
  Sequence_Details;
  ImageGeometry;
  Preparation;
  MapShim;
  TempGridding;
  GopAdj;
} MethodClass;

// parameters for reconstruction 
extend pargroup
{
  ParentDset;   
}
attributes
{
  display_name "Reconstruction Options";
}MethodRecoGroup;

// parameters that should be tested after any editing
conflicts
{
  EchoTime;
  PVM_RepetitionTime;
  PVM_Fov;
  PVM_SliceThick;
  NSegments;
  ExcPul.Flipangle;
  RefPul.Flipangle;
  SLprepPul.Flipangle;
  SLrfcPul.Flipangle;  
};

/****************************************************************/
/*	E N D   O F   F I L E					*/
/****************************************************************/



