/* ***************************************************************
 *
 * Copyright (c) 2022
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 * ***************************************************************/

#define DEBUG	 1

/*:=INFO=:*******************************************************
 *
 * Description :
 *   it contains functions necessary for responding to a 'load'
 *	of this method. This function will be automatically
 *	called in response to a method file for this method
 *	having been read.
 *
 *::=info=:******************************************************/

/****************************************************************/
/****************************************************************/
/*		I N T E R F A C E   S E C T I O N		*/
/****************************************************************/
/****************************************************************/

/****************************************************************/
/*		I N C L U D E   F I L E S			*/
/****************************************************************/

#include "method.h"


/****************************************************************/
/*	I M P L E M E N T A T I O N   S E C T I O N		*/
/****************************************************************/


/****************************************************************/
/*		G L O B A L   F U N C T I O N S			*/
/****************************************************************/


/* ------------------------------------------------------------ 
  backbone 
  The main part of method code. The consitency of all parameters is checked
  chere, relations between them are resolved and, finally, functions setting
  the base level parameters are called.
  --------------------------------------------------------------*/
void backbone( void )
{
  int dim, ret, nImagesPerRep;
  double minFov[3] = {1e-3, 1e-3, 1e-3},
         minThickness;
  double limExSliceGradient = 100;
  double limExSliceRephaseGradient = 50;

  
  
  DB_MSG(("Entering EPI/backbone.c:backbone"));


  /* Nuclei and  PVM_GradCalConst  are handled by this funtion: */
  STB_UpdateNuclei(Yes);
 
 
  /* do not allow a-aliasing */
  PVM_AntiAlias[1] = 1.0;

  //constrain geometry
  STB_ConstrainSliceGeoForMb(PVM_MbEncNBands);
  
  /* Encoding
   * note: Grappa reference lines are disabled. Grappa coeeficients will be set
   * in a special adjustment. */
  STB_UpdateEncodingForEpi(
    &NSegments,        /* number of segments */
    Yes,               /* ppi in 2nd dim allowed */
    Yes,               /* ppi ref lines in 2nd dim allowed */
    Yes,               /* partial ft in 2nd dim allowed */ 
    3);

  dim = PTB_GetSpatDim();
  
  /* handle RF pulse */   
  
  STB_UpdateRFPulse("ExcPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");
  STB_UpdateRFPulse("RefPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");
  STB_UpdateRFPulse("SLprepPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");
  STB_UpdateRFPulse("SLrfcPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");

  if (TempGridding)
  {
    double fac=ExcPul.Rpfac/100.0;
    if (fac < 0.01)
      fac=1.0;
    else
      fac=round(1.0/fac);

    ExcPul.Length=ceil(ExcPul.Length/fac*1000.0)/1000.0*fac; //Total pulse on grid and MOST(!) length*Rpfac on grid
    ExcPul.Bandwidth= MRT_RFPulsePulseLengthToBandwidth(ExcPul.Bwfac, 100.0,ExcPul.Length);
    STB_UpdateRFPulse("ExcPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");
    RefPul.Length=ceil(RefPul.Length*1000.0/2.0)/1000.0*2.0; //half pulse on grid
    RefPul.Bandwidth= MRT_RFPulsePulseLengthToBandwidth(RefPul.Bwfac, 100.0,RefPul.Length);
    STB_UpdateRFPulse("RefPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");

    RephaseTime=ceil(RephaseTime*1000.0)/1000.0;
    PackDel=ceil(PackDel*1000.0)/1000.0;
  }
  
  if(PVM_DeriveGains==Yes)
  {
    ParxRelsParHideInEditor({"ExcPulseAmpl"});
    ParxRelsParHideInEditor({"SLprepPulseAmpl"});
    ParxRelsParHideInEditor({"SLrfcPulseAmpl"});    
  }
  else
  {
    ParxRelsParShowInEditor({"ExcPulseAmpl"});
    ParxRelsParShowInEditor({"SLprepPulseAmpl"});
    ParxRelsParShowInEditor({"SLrfcPulseAmpl"});
  }
  
  if (PVM_SignalType == SignalType_Fid)
  {
    ParxRelsParHideInEditor({"RefPul","RefPulseEnum","RefPulseAmpl"});
  }
  else
  {
    ParxRelsParShowInEditor({"RefPul","RefPulseEnum"});
    if (PVM_DeriveGains == Yes)
    {
      ParxRelsParHideInEditor({"RefPulseAmpl"});
    }
    else
    {
      ParxRelsParShowInEditor({"RefPulseAmpl"});
    }
  }
 
  /*** Update Geometry **/
  
  LocalGeometryMinimaRels(limExSliceGradient, limExSliceRephaseGradient, &minThickness);

  /* do not allow isotropic geometry */
  PVM_IsotropicFovRes = Isot_None;

  // only one package
  int maxPackages = 1;
  int maxPerPackage = dim>2? 1:0;

  STB_UpdateImageGeometry(dim, 
                          PVM_Matrix,
                          minFov,
                          0, // total slices (no restr)
                          maxPackages,
                          maxPerPackage,
                          minThickness,
                          1.0); // sliceFovRatio in 3D

  STB_UpdateMultiBandGeoPars("PVM_SliceGeoObj", 
        PVM_ObjOrderScheme,
        PVM_MbEncNBands);
  
  /** Update EPI parameter group */

  PVM_NRepetitions = MAX_OF(1,PVM_NRepetitions);
  PVM_NEchoImages = 1;
  nImagesPerRep = PVM_NEchoImages * GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices );

  ret = STB_EpiUpdate(No,
		      dim, 
		      PVM_EncMatrix, 
		      PVM_AntiAlias,
		      PVM_Fov, 
		      minFov, 
		      &PVM_EffSWh, 
		      PVM_GradCalConst, 
		      nImagesPerRep,
		      NSegments,
		      PVM_EncCentralStep1,
		      PVM_EncPpi,
                      PVM_EncNReceivers,
                      TempGridding,
                      PVM_MbEncNBands,
                      PVM_MbEncBlipFactor,
                      PVM_EncGenCaipirinha);

  if(ret <0)
    DB_MSG(("--!!!!!!!!!!!!!!! Illegal arguments for STB_UpdateEPI: EPI Module not ready !"));
 //  if (PVM_MagTransOnOff == On)///sos
 // if (PVM_SatTransOnOff == On  &&  PVM_SatTransType == CEST)
    {
    //DB_MSG(("-->sattrans and cest"));
    //  PVM_NRepetitions= MAX_OF(Number_fp_Experiments,1); // forced NR to be Number_fp_Experiments
     //  DB_MSG(("<--sattrans and cest"));
    }
  
  
  //
  /* Constrain MB geometry, min slice distance (minFov[2]) is known */
  STB_ConstrainSliceGeoForMb(PVM_MbEncNBands,minFov[2]);
              
  /* Update geometry again (minFov is known) */ 
  
  STB_UpdateImageGeometry(dim, 
                          PVM_Matrix,
                          minFov,
                          0, // total slices (no restr)
                          maxPackages,
                          maxPerPackage,
                          minThickness,
                          1.0); // sliceFovRatio in 3D
  
  STB_UpdateMultiBandGeoPars("PVM_SliceGeoObj", 
        PVM_ObjOrderScheme,
        PVM_MbEncNBands);
  
  //Update RF Pulses, mb-parameters might have changed
  STB_UpdateRFPulse("ExcPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");
  STB_UpdateRFPulse("RefPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");
  STB_UpdateRFPulse("SLprepPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");
  STB_UpdateRFPulse("SLrfcPul",1,PVM_DeriveGains,Conventional,"PVM_MbEncNBands,PVM_MbRelSliceDist");
  

  /*** end Update Geometry **/

  LocalGradientStrengthRels();  
  LocalFrequencyOffsetRels();

  if (ParxRelsParHasValue("PVM_NAverages") == 0)
     PVM_NAverages = 1;

  /* update slice spoiler */
  double mindurSlice = MAX_OF(2.0, 2.0*CFG_GradientRiseTime());
  double spoilerThick = dim>2 ? PVM_SpatResol[2]*PVM_EncZf[2] : PVM_SliceThick;
  MRT_UpdateSpoiler("SliceSpoiler",5.0,limExSliceGradient,mindurSlice,PVM_GradCalConst,spoilerThick);

  if (TempGridding)
    GridGrad(&SliceSpoiler.dur, &SliceSpoiler.ampl, mindurSlice, 50, 0, limExSliceGradient);



  /* handling of modules */
  STB_UpdateDriftCompModule(spoilerThick, PVM_DeriveGains);
  STB_UpdateFatSupModule(PVM_Nucleus1, PVM_DeriveGains, spoilerThick);
  //STB_UpdateSatTransModule(PVM_DeriveGains);//sos
  
  Update_FpExperiment();
  
  STB_UpdateFovSatModule(PVM_Nucleus1, PVM_DeriveGains);
  STB_UpdateTriggerModule();
  STB_UpdateTriggerOutModule();
  STB_UpdateTaggingModule(dim,PVM_Fov,PVM_Matrix,PVM_SpatResol[0]*PVM_EncZf[0],PVM_DeriveGains); 

  
  
  
  rfcSpoilerUpdate();

  echoTimeRels();

  if (TempGridding)
  {
     EchoTime=ceil(EchoTime*1000.0)/1000.0;
  }

  repetitionTimeRels();

  PTB_ClearAdjustments();

  PTB_AppendOrderAdjustment(per_scan, per_scan, RG_ADJNAME);

  PTB_AppendAdjustment("EpiTraj",
                       "Adjust Traj.",
                       "Adjust EPI Trajectory",
                       on_demand);

  if(PVM_EncPpiRefScan)
  {
    PTB_AppendAdjustment("EpiGrappa",
                         "Adjust GRAPPA Coeff.",
                         "Adjustment of GRAPPA Coefficients",
                         per_scan);
    if(PVM_MbEncAccelFactor > 1){
        PTB_AppendAdjustment("MbRgGhost",
                        "Receiver Gain MB", 
                        "Re-Adjustment of the Receiver Gain for Multi-Band",
                        per_scan);
    }
  }

  STB_UpdateDummyScans(PVM_RepetitionTime);

  /* Set correct DriftCompUpdateTime after TR-upate */
  STB_UpdateDriftComp(PVM_RepetitionTime);
  
  /* update mapshim parameter class */
  STB_UpdateMapShim(PVM_Nucleus1,"PVM_SliceGeoObj");

  /* set baselevel acquisition parameter */
  SetBaseLevelParam();
  
  /* set baselevel reconstruction parameter */
  SetRecoParam(PVM_EncPpi[1]);
 // Fp_ReadFromFile();
// Update_FpExperiment();

  /* adapt size of trajectory arrays if necessary and set 
     PVM_EpiTrajAdj to No if a trajectory relevant parameter has changed */

  STB_EpiCheckTrajectory(PVM_Fov[0],PVM_EffSWh,PVM_SPackArrGradOrient[0][0]);
 
  DB_MSG(("Exiting EPI/backbone.c:backbone"));
}


void rfcSpoilerUpdate(void)
{
  RfcSpoilerStrength = 2*ExSliceGradient;
  RfcSpoilerStrength = MIN_OF(RfcSpoilerStrength,80);
  RfcSpoilerStrength = MAX_OF(RfcSpoilerStrength,30);

  RfcSpoilerDuration = MAX_OF(RefPul.Length, 2*CFG_GradientRiseTime());
}

/****************************************************************/
/*	         L O C A L   F U N C T I O N S			*/
/****************************************************************/


void echoTimeRels( void )
{
  DB_MSG(("Entering EPI/backbone.c:echoTimeRels()"));

  double igwt = CFG_InterGradientWaitTime();
  double riseT = CFG_GradientRiseTime();

  if(PVM_SignalType == SignalType_Fid)
  {
    PVM_MinEchoTime =      /* min gradient echo time */
      ExcPul.Length * ExcPul.Rpfac/100 +
      riseT             +
      igwt              +
      RephaseTime       +
      igwt              +
      PVM_EpiEchoDelay;
    MinTE_right  = MinTE_left = 0.0; /* not used */
  }
  else
  {
    MinTE_left =  /* min half spinecho-time given by left hand side of pi */
    ExcPul.Length * ExcPul.Rpfac/100  +
    riseT             +
    igwt              + 
    RephaseTime       +
    igwt              +
    RfcSpoilerDuration + 
    RefPul.Length/2.0;

    MinTE_right = /* min half spinecho-time given by right hand side of pi */
    RefPul.Length/2.0  +
    RfcSpoilerDuration +
    igwt               +
    PVM_EpiEchoDelay;

    PVM_MinEchoTime = 2 * MAX_OF(MinTE_left, MinTE_right);
  }

  EchoTime = EchoTime < PVM_MinEchoTime ?
    PVM_MinEchoTime : EchoTime;

  if (TempGridding)
  {
    if(PVM_SignalType == SignalType_Fid)

      EchoTime=ceil(EchoTime*1000.0)/1000.0;
    else
      EchoTime=ceil(EchoTime*1000.0/2.0)/1000.0*2.0;
  }

  /* Set Echo Parameters for Scan Editor   */

  /* echo spacing: */
  PVM_EchoTime = 1e3*PVM_Matrix[0]/PVM_EffSWh/PVM_AntiAlias[0];
  PVM_EchoPosition = 50.0;
 
  DB_MSG(("Exiting EPI/backbone.c:echoTimeRels"));
}

void repetitionTimeRels( void )
{
  int nSlices,dim;
  double TotalTime,trigger, trigger_v, trigOutSlice, trigOutVol;

  DB_MSG(("--> minRepetitionTimeRels"));

  trigger = STB_UpdateTriggerModule();
  if(PVM_TriggerMode == per_PhaseStep) /* per volume */
  {
    trigger_v=trigger;
    trigger=0.0; 
  }
  else trigger_v=0.0;

  TotalTime = 0.0;
  nSlices = GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices )/PVM_MbEncNBands;

  if(PVM_TriggerOutOnOff == On)
  {
    switch(PVM_TriggerOutMode)
    {
    case PER_SLICE:   
      trigOutSlice = PVM_TriggerOutModuleTime;
      trigOutVol = 0.0;
      break;

    case PER_VOLUME: 
      trigOutSlice = 0.0;
      trigOutVol = PVM_TriggerOutModuleTime;
      break;

    case AT_START:
    default:
      trigOutSlice = 0.0;
      trigOutVol = 0.0;
      
    }
  }
  else
    trigOutSlice = trigOutVol = 0.0;

  dim = PTB_GetSpatDim();
  
  if(dim>2) /* disable inter-volume delay in 3d */
  {
    PackDel=0;
    ParxRelsParMakeNonEditable({"PackDel"});
  }
  else
  {
    ParxRelsParMakeEditable({"PackDel"});
  }

  double dynshim_event=0;
  if(PVM_DynamicShimEnable==Yes)
    dynshim_event = PVM_DynamicShimEventDuration;
  
  PVM_MinRepetitionTime =
    nSlices * (
               0.03 +                      //UpdateDynPars
               dynshim_event +
               0.01 + 
               PVM_FatSupModuleTime +
               PVM_FovSatModuleTime +
               PVM_SatTransModuleTime +
               trigger +
               trigOutSlice +
               SliceSpoiler.dur +
	             CFG_GradientRiseTime() +
               ExcPul.Length/2 +
               EchoTime +
               PVM_EpiModuleTime - PVM_EpiEchoDelay
    ) + 
    PVM_DriftCompModuleTime +
    PVM_TaggingModuleTime +
    trigOutVol +
    trigger_v +
    PackDel;

  PVM_RepetitionTime = ( PVM_RepetitionTime < PVM_MinRepetitionTime ? 
			 PVM_MinRepetitionTime : PVM_RepetitionTime );

  if (TempGridding)
    PVM_RepetitionTime=ceil(((PVM_RepetitionTime - PVM_MinRepetitionTime)/nSlices)*1000.0)/1000.0*nSlices+PVM_MinRepetitionTime;

  
  /** Calculate Total Scan Time and Set for Scan Editor **/ 

if( dim >1 )
  TotalTime = PVM_RepetitionTime      *
              PVM_EpiNShots           *
              PVM_NAverages           *
              PVM_SatTransRepetitions *
              PVM_NRepetitions;

if( dim >2 )
  TotalTime *= PVM_EncMatrix[2];
  
 /* time for one repetition **/
 OneRepTime = TotalTime/(PVM_NRepetitions*1000.0);

 PVM_ScanTime = TotalTime;
 UT_ScanTimeStr(PVM_ScanTimeStr,TotalTime);
 

  ParxRelsParShowInEditor({"PVM_ScanTimeStr"});
  ParxRelsParMakeNonEditable({"PVM_ScanTimeStr"});


  DB_MSG(("<-- repetitionTimeRels"));
}

void LocalGeometryMinimaRels(double limExSliceGradient, double limExSliceRephaseGradient, double *min_thickness)
{
  /*
    This function calculates the minima for the minimum  slice thickness.
    It is always assumed that all slices have the same thickness
    (WE DO NOT set min_fov[0 and 1] here, this will be done by the epi module) 
 */

  double sliceRampInteg; /* normalised integral falling slice gradient ramp */
  double sliceRephInteg; /* normalised integral slice rephase gradient      */
    
  /* min slice thickness: */
  /*  Calculate the normalised integral of the descending gradient ramp after
      the RF pulse */
  sliceRampInteg = 0.5 *  CFG_GradientRiseTime();
  /* Calculate the normalised integral of the slice selection rephasing
     gradient */
  sliceRephInteg = RephaseTime - CFG_GradientRiseTime();
  
  /*
	Calculate the ratio of the strength of the slice selection gradient to
	the strength of the slice selection rephase gradient

  */
  SliceGradRatio = MRT_SliceGradRatio( ExcPul.Length,
                                       ExcPul.Rpfac,
                                       0.0,
                                       sliceRampInteg,
                                       sliceRephInteg );
  /*
    Calculate the minimum slice thickness
  */
      
  *min_thickness = MRT_MinSliceThickness( ExcPul.Bandwidth,
					  SliceGradRatio,
					  limExSliceGradient,
					  limExSliceRephaseGradient,
					  PVM_GradCalConst );
     
    
} /* end of localGeometryMinima() */



void LocalGradientStrengthRels( void )
{
  /*
    This function calculates all the gradient strengths 
  */

  switch( PTB_GetSpatDim() )
    {
    case 3: /* PHASE ENCODING GRADIENT - 3nd DIM */
     
     /* falls through */
    case 1:
      ReadGradient = (PVM_EpiReadEvenGrad+PVM_EpiReadOddGrad)/2.0; /* used in LocFreqOff */
      [[fallthrough]];
     /* falls through */
    default: /* SLICE SELECTION GRADIENT */
      ExSliceGradient = MRT_SliceGrad( ExcPul.Bandwidth,
				       PVM_SliceThick,
				       PVM_GradCalConst );
      ExSliceRephaseGradient = MRT_SliceRephaseGrad( SliceGradRatio,
							 ExSliceGradient );
      break;
    }
}

void LocalFrequencyOffsetRels( void )
{
  int spatDim;
  int i,nslices;

  spatDim = PTB_GetSpatDim();

  nslices = GTB_NumberOfSlices(PVM_NSPacks,PVM_SPackArrNSlices);

  if(PVM_MbEncNBands > 1){
    nslices /= PVM_MbEncNBands;
    /* set ReadOffsetHz to zero. In EPI the fov offset is made by reco, not by detection freq. offsets */
    MRT_FrequencyOffsetList(nslices,
                            PVM_MbEffReadOffset,
                            ReadGradient,
                            0.0, /* instead PVM_GradCalConst; this sets offHz to zero */
                            PVM_MbReadOffsetHz );

    MRT_FrequencyOffsetList(nslices,
                            PVM_MbEffSliceOffset,
                            ExSliceGradient,
                            PVM_GradCalConst,
                            PVM_MbSliceOffsetHz );
  }
  
    /* set ReadOffsetHz to zero. In EPI the fov offset is made by reco, not by detection freq. offsets */
    MRT_FrequencyOffsetList(nslices,
			  PVM_EffReadOffset,
			  ReadGradient,
			  0.0, /* instead PVM_GradCalConst; this sets offHz to zero */
			  PVM_ReadOffsetHz );

  MRT_FrequencyOffsetList(nslices,
			  PVM_EffSliceOffset,
			  ExSliceGradient,
			  PVM_GradCalConst,
			  PVM_SliceOffsetHz );

  if(spatDim == 3)
  {
    for(i=0;i<nslices;i++)
      PVM_EffPhase2Offset[i] = -PVM_EffSliceOffset[i];
  }

}



//rounds dur and rescales amp, checking limits
bool GridGrad(double* durPt, double* ampPt, double minDur, double maxDur, double minAmp, double maxAmp)
{
  //input in ms

  double dur=*durPt*1000.0;
  double amp=*ampPt;
  minDur*=1000.0;
  maxDur*=1000.0;

  double origDur=dur;
  double origAmp=amp;
  double fac=1.0;
  bool failed=false;

  DB_MSG(("origDur %f", origDur));

  //set dur
  dur=ceil(origDur);
  DB_MSG(("ceil %f", dur));


  if (dur > maxDur)
    dur=floor(origDur);
   DB_MSG(("floor? %f", dur));


  //set amp
  fac=dur/origDur;
  amp=origAmp/fac;

  DB_MSG(("origAmp %f amp %f", origAmp, amp));


  //check amp
  if (amp > maxAmp)
    dur=ceil(origDur);
  if (amp < minAmp)
    dur=floor(origDur);
  
  DB_MSG(("dur %f", dur));


  //re-adjust amp
  fac=dur/origDur;
  amp=origAmp/fac;

  DB_MSG(("amp %f", amp));

  
  //final check
  if (dur < minDur || dur > maxDur || amp < minAmp || amp > maxAmp)
  {
    failed=true;
    dur=origDur;
    amp=origAmp;
  }

  *durPt=dur/1000.0;
  *ampPt=amp;

  return failed;
}

/* relations of MR fingerprint parameters -- added by Shuning Huang */
void Update_FpExperiment(void)
{
 DB_MSG(("--> UpdateFpExperiment"));
   
  int i=0, dim=PTB_GetSpatDim();
  double TotalTime = 0;

   YesNo InputModeChanged = UT_GetRequest("Fp_InputModeEnum");
   YesNo NumExpChanged = UT_GetRequest("Number_fp_Experiments");
  PVM_SatTransOnOff = On; 
  PVM_SatTransType = CEST;
 // PVM_SatTransFreqUnit=unit_ppm;
  PVM_SatTransFreqInput = by_value;

  
  
   
  if (InputModeChanged == Yes)
  { 
    //PVM_MagTransPower = 1;
       PVM_SatTransFreqUnit=unit_ppm;
     STB_UpdateSatTransModule(PVM_DeriveGains);
    
    if (Fp_InputModeEnum == Read_from_file)
    {   
        ParxRelsParShowInEditor({"Fp_PathName", "Fp_FileName"});
        Fp_ReadFromFile();
        if (Number_fp_Experiments < 1)
            Number_fp_Experiments = 1;
        //dk edit: prevent editing of parameters if read from file
        ParxRelsParMakeNonEditable({"Number_fp_Experiments","Fp_SatPows","Fp_TRs","Fp_SatOffset","Fp_FlipAngle","Fp_SatDur","Fp_SLflag","Fp_SLFlipAngle"});
    }
    else
    {
        if (NumExpChanged == Yes)
        {
            
            STB_UpdateSatTransModule(PVM_DeriveGains);
            //Fp_ReadFromFile();
            Number_fp_Experiments = MAX_OF(1, Number_fp_Experiments);
           
          UT_ClearRequest();    
        }
        ParxRelsParMakeEditable({"Number_fp_Experiments","Fp_SatPows","Fp_TRs","Fp_SatOffset","Fp_FlipAngle","Fp_SatDur","Fp_SLflag","Fp_SLFlipAngle"});
    }
   
   UT_ClearRequest();
   
  }


 ParxRelsParChangeDims("Fp_SatPows", {Number_fp_Experiments});
 ParxRelsParChangeDims("Fp_TRs", {Number_fp_Experiments});
 ParxRelsParChangeDims("Fp_SatOffset", {Number_fp_Experiments});
 ParxRelsParChangeDims("Fp_SatOffsetHz", {Number_fp_Experiments});
 ParxRelsParChangeDims("Fp_SatDur", {Number_fp_Experiments});
 ParxRelsParChangeDims("Fp_SatDuration", {Number_fp_Experiments});
 ParxRelsParChangeDims("Fp_FlipAngle", {Number_fp_Experiments});
 ParxRelsParChangeDims("Fp_TRDels", {Number_fp_Experiments});
 //ParxRelsParChangeDims("Fp_TRPadding", {Number_fp_Experiments});
 ParxRelsParChangeDims("Fp_SLflag", {Number_fp_Experiments});
 ParxRelsParChangeDims("Fp_SLFlipAngle", {Number_fp_Experiments});
 
  /* Saturation pulse power list*/
  ParxRelsParChangeDims( "PpgPowerList1", {Number_fp_Experiments});
   /* excitation pulse power list*/
  ParxRelsParChangeDims( "PpgPowerList2", {Number_fp_Experiments}); 
   /* pre-/post-spinlock pulse power list*/
  ParxRelsParChangeDims( "PpgPowerList3", {Number_fp_Experiments});
  
  //sos start//
  
   ParxRelsParChangeDims("PVM_SatTransFreqValues", {Number_fp_Experiments});
    ParxRelsParChangeDims("Fp_SatOffset", {Number_fp_Experiments});  
   ParxRelsParChangeDims("Fp_SatOffsetHz", {Number_fp_Experiments});  
    PVM_SatTransPulseAmpl_uT=1.0; 
    
  for (i=0; i<Number_fp_Experiments; i++ )
    { 
    
   PVM_SatTransFreqUnit=unit_ppm;
   Fp_SatOffset[i]=MIN_OF(Fp_SatOffset[i], (100));
   Fp_SatOffset[i]=MAX_OF(Fp_SatOffset[i], (-100));
   //PVM_SatTransFL[i]=PVM_SatTransFreqValues[i]*BF1;
   Fp_SatOffsetHz[i]=Fp_SatOffset[i]*BF1;   //dk: I uncommented it since it will help w/ calculating the SL tips!
       
       PVM_SatTransFreqValues[i]= Fp_SatOffset[i];
       
   //dk: calculate pre-/post-SL tip angles automatically, if set to 0
    if (Fp_SLFlipAngle[i] == 0 && Fp_SLflag[i] == 1)   //if SL and tip = 0, calculate what it should be based upon omega_eff vector and overwrite value
      {  
         Fp_SLFlipAngle[i] = atan(MAX_OF(Fp_SatPows[i], 0.00001) * 42.577 / Fp_SatOffsetHz[i]) / 3.141592653 * 180;
      }     
 
   }  
  
  //sos end//
  
  Fp_TRs[0] = ( Fp_TRs[0] < PVM_MinRepetitionTime ? 
		PVM_MinRepetitionTime : Fp_TRs[0]); 
  PVM_RepetitionTime = Fp_TRs[0]; 

 // PVM_MagTransPulse1.Length = Fp_SatDur[0];
    PVM_SatTransPulse.Length = MAX_OF(Fp_SatDur[0],0.0);
    STB_UpdateSatTransModule(PVM_DeriveGains);
    repetitionTimeRels(); //dk note: we need to ensure here that minRepetitionTime is calculated properly for proper Fp_TRdels calculation!
  //PVM_SatTransPower = 1;
    
//  ExcPul.Flipangle = Fp_FlipAngle[0];
//  STB_UpdateRFPulse("ExcPul",1,PVM_DeriveGains,Conventional);
//  PpgPowerList2[0] = ExcPul.Pow;

  //dk: use the SLprepPul to fill in PpgPowerList3
//  SLprepPul.Flipangle = Fp_SLFlipAngle[0];
//  STB_UpdateRFPulse("SLprepPul",1,PVM_DeriveGains,Conventional);
//  PpgPowerList3[0] = SLprepPul.Pow;
    
  double MaxSatTransAmpl_uT;
  for (i=0; i<Number_fp_Experiments; i++ )
    {
      
      
      //PVM_ppgPowerList1[i] = PVM_MagTransPulse1Ampl.ppow + 20*log10(PVM_MagTransPower/Fp_SatPows[i]); for ParaVision 5.0
     //** PVM_ppgPowerList1[i] = PVM_MagTransPulse1Ampl.ppow * (Fp_SatPows[i]/PVM_MagTransPower) * (Fp_SatPows[i]/PVM_MagTransPower);
     //PpgPowerList1[i] = PVM_SatTransPulse.Pow * (Fp_SatPows[i]/PVM_SatTransPulseAmpl_uT) * (Fp_SatPows[i]/PVM_SatTransPulseAmpl_uT) ;//Are we sure of this power?sos
      if (ParxRelsParHasValue("PVM_RefPowCh1") == Yes)
      {
            PpgPowerList1[i] = (Fp_SatPows[i]/5.8717) * (Fp_SatPows[i]/5.8717) * MAX_OF(PVM_RefPowCh1, 0.00001);
            MaxSatTransAmpl_uT = sqrt(CFG_MaxCWRFPower(1, PVM_Nucleus1) / PVM_RefPowCh1) * 5.8717;  //dk: this is the max allowed amplitude in uT
      }
      else
      {
          DB_MSG(("!!!!!!!WARNING: Reference power not calibrated -- fpSL_EPI method cannot calculate saturation/locking amplitudes properly!!!!!!!"));
      }
      
      // range check, unit watts (dk add: debug error message + decrease to max CW power)
      if (PpgPowerList1[i] > CFG_MaxCWRFPower(1, PVM_Nucleus1))
      {
         sprintf(PVM_ErrorMessage, "Sat/lock amplitude %d of %d is too high for coil! Max allowed is %2.2f uT (%3.1f W)", (i+1), Number_fp_Experiments, MaxSatTransAmpl_uT, CFG_MaxCWRFPower(1, PVM_Nucleus1));
         UT_ReportError(PVM_ErrorMessage);
      }
      PpgPowerList1[i] = MAX_OF(PpgPowerList1[i], 0.0);
      PpgPowerList1[i] = MIN_OF(PpgPowerList1[i], CFG_MaxCWRFPower(1, PVM_Nucleus1));
    
      
      //dk update: no more scaling by factors! Let PV update the powers for you
//      if (i > 0)  // Excitation pulse power list calculation 
//      {
         //PpgPowerList2[i] = PpgPowerList2[0] * (Fp_FlipAngle[i]/Fp_FlipAngle[0]) * (Fp_FlipAngle[i]/Fp_FlipAngle[0]);
        ExcPul.Flipangle = Fp_FlipAngle[i];
        STB_UpdateRFPulse("ExcPul",1,PVM_DeriveGains,Conventional);
        PpgPowerList2[i] = ExcPul.Pow;
         // range check, unit watts 
         if (PpgPowerList2[i] > CFG_MaxRFPower(1, PVM_Nucleus1, ExcPul.Pint, ExcPul.Length))
         {
             sprintf(PVM_ErrorMessage, "Excitation pulse power %d/%d is too high for coil! Max allowed is %4.1f W", (i+1), Number_fp_Experiments, CFG_MaxRFPower(1, PVM_Nucleus1, ExcPul.Pint, ExcPul.Length));
             UT_ReportError(PVM_ErrorMessage);
         }
         PpgPowerList2[i] = MAX_OF(PpgPowerList2[i], 0);
         PpgPowerList2[i] = MIN_OF(PpgPowerList2[i], CFG_MaxRFPower(1, PVM_Nucleus1, ExcPul.Pint, ExcPul.Length));
         
         if (Fp_SLflag[i] == 1)
         {
//            PpgPowerList3[i] = PpgPowerList2[0] * (Fp_SLFlipAngle[i]/Fp_FlipAngle[0]) * (Fp_SLFlipAngle[i]/Fp_FlipAngle[0]);
            SLprepPul.Flipangle = Fp_SLFlipAngle[i];
            STB_UpdateRFPulse("SLprepPul",1,PVM_DeriveGains,Conventional);
            PpgPowerList3[i] = SLprepPul.Pow;            
            //dk: calculate powers for pre-/post-SL tips + range check, unit watts 
            if (PpgPowerList3[i] > CFG_MaxRFPower(1, PVM_Nucleus1, SLprepPul.Pint, SLprepPul.Length))
            {
             sprintf(PVM_ErrorMessage, "Spinlock preparation pulse power %d/%d is too high for coil! Max allowed is %4.1f W", (i+1), Number_fp_Experiments, CFG_MaxRFPower(1, PVM_Nucleus1, SLprepPul.Pint, SLprepPul.Length));
             UT_ReportError(PVM_ErrorMessage);
            } 
         }
         else
         {
             PpgPowerList3[i] = 0;
         }
         PpgPowerList3[i] = MAX_OF(PpgPowerList3[i], 0);
         PpgPowerList3[i] = MIN_OF(PpgPowerList3[i], CFG_MaxRFPower(1, PVM_Nucleus1, SLprepPul.Pint, SLprepPul.Length));
//      }      
      
      Fp_SatDuration[i] = Fp_SatDur[i] * 1000;
      // Repetition time, delays
      Fp_TRs[i] = ( Fp_TRs[i] < PVM_MinRepetitionTime ? 
		    PVM_MinRepetitionTime : Fp_TRs[i]);
      
      //Fp_TRDels[i] =  ((Fp_TRs[i] - PVM_MinRepetitionTime)/NSLICES 
      	//	       + PVM_InterGradientWaitTime) / 1000.0;
      
      //Fp_TRDels[i] =  ((Fp_TRs[i] - PVM_MinRepetitionTime)/NSLICES 
	//	       + 0.1) / 1000.0;   //from BaseLevelRelations.c
      
      //dk edit: we will calculate the TRDels using each entry of the SatDur, so no more annoying errors if the SatTrans pulse length is left super short!
      //This PROBABLY needs to be CHECKED if >1 slice!!
      Fp_TRDels[i] =  ((Fp_TRs[i] + (NSLICES*PVM_SatTransModuleTime) - PVM_MinRepetitionTime 
                       - Fp_SatDur[i] - (SLprepPul.Length*2*Fp_SLflag[i]))/NSLICES 
		       + 0.1) / 1000;   //from BaseLevelRelations.c
      
      Fp_TRDels[i] = MAX_OF(Fp_TRDels[i],1.0e-6);
      
      //Fp_TRPadding[i] = Fp_TRDels[i] * 1000; // unit in ms
      
      /** Calculate Total Scan Time and Set for Scan Editor **/ 
      if( dim >1 )
	TotalTime = TotalTime + Fp_TRs[i]*PVM_EpiNShots*PVM_NAverages;
      if( dim >2 )
	TotalTime *= PVM_EncMatrix[2]; // caculation for 3D may not be right.
        
    }
  
  //IMPORTANT dk edit: we need to set the power for p2:sp2 to be the 90deg power! Otherwise the B-SL 180s will be <180!
  SLprepPul.Flipangle = 90.0;
  STB_UpdateRFPulse("SLprepPul",1,PVM_DeriveGains,Conventional);
  
  STB_UpdateSatTransModule(PVM_DeriveGains);
  
      /* time for one repetition */
  OneRepTime = TotalTime/(PVM_NRepetitions*1000.0); // this will be the avarage OneRepTime
  
  //ParxRelsParRelations("PpgPowerList1", Yes);
// ParxRelsParRelations("PpgPowerList2", Yes);
  ParxRelsParRelations("ACQ_vd_list",Yes);
  //STB_UpdateSatTransModule(PVM_DeriveGains);
  PVM_ScanTime = TotalTime;
  UT_ScanTimeStr(PVM_ScanTimeStr,TotalTime);
  
  ParxRelsParShowInEditor({"PVM_ScanTimeStr"});
  ParxRelsParMakeNonEditable({"PVM_ScanTimeStr"});

  DB_MSG(("<-- UpdateFpExperiment"));
  
  return;
}

void Fp_ReadFromFile(void)
{
  FILE *fp;
  char  filename[1024];
  float tr, SatPow, offset, fa, SatDur, SL, SLtip;
  int count;
  int nlines;

  DB_MSG (("-->  fp_ReadFromFile()\n")); 
  
  sprintf(filename, "%s/%s", Fp_PathName, Fp_FileName);

  fp = fopen(filename,"r");
  
  if (fp == NULL)
    {
//      printf ("File %s cannot be opened! \n", filename);
//      return;
      sprintf(PVM_ErrorMessage, "File read error: File %s cannot be opened!", filename);
      UT_ReportError(PVM_ErrorMessage);      
    }

  if ( fscanf(fp,"%d",&nlines) != 1 )     // the first line specifies the number of points (experiments)
    {
//      printf("Error reading file at line 0.\n");
      fclose(fp);
//      return;
      sprintf(PVM_ErrorMessage, "File read error: Error reading file %s at line 0.", filename);
      UT_ReportError(PVM_ErrorMessage); 
    }

  count = 0;
  
  for (count=0; count < nlines; count++)
  {
      /*PARX_change_dims("Fp_TRs",  count + 1);
      PARX_change_dims("Fp_SatPows",  count + 1);
      PARX_change_dims("Fp_SatOffset",  count + 1); 
      PARX_change_dims("Fp_FlipAngle",  count + 1); 
      PARX_change_dims("Fp_SatDur",  count + 1); */
     ParxRelsParChangeDims("Fp_TRs",  {count + 1});
     ParxRelsParChangeDims("Fp_SatPows",  {count + 1});
     ParxRelsParChangeDims("Fp_SatOffset",  {count + 1}); 
     ParxRelsParChangeDims("Fp_FlipAngle",  {count + 1}); 
     ParxRelsParChangeDims("Fp_SatDur",  {count + 1});
     ParxRelsParChangeDims("Fp_SLflag",  {count + 1}); 
     ParxRelsParChangeDims("Fp_SLFlipAngle",  {count + 1});
                                                             
             
      if( fscanf(fp,"%f %f %f %f %f %f %f",  &tr, &SatPow, &offset, &fa, &SatDur, &SL, &SLtip) != 7)
	 {
//	   printf("Error reading SatPow file at line %d\n", count+1);
	   fclose(fp);
//	   return;
           sprintf(PVM_ErrorMessage, "File read error: Error reading file %s at line %d.", filename, count+1);
           UT_ReportError(PVM_ErrorMessage);            
	 }
     
      if (tr > 0)	 
       {
	 Fp_TRs[count] = tr;
       }
     else
       {
//	 printf("Fp_TRs[%d] = %f is out of range\n",count,tr);
	 fclose(fp);
//	 return;
         sprintf(PVM_ErrorMessage, "File read error: Fp_TRs[%d] = %f is out of range [0, Inf]", count, tr);
         UT_ReportError(PVM_ErrorMessage);          
       }
     
     if (SatPow > -0.1 && SatPow <= 50)
       {
	 Fp_SatPows[count] = SatPow;
       }
     else
       {
//	 printf("Fp_SatPows[%d] = %f is out of range\n",count,SatPow);
	 fclose(fp);
//	 return;
         sprintf(PVM_ErrorMessage, "File read error: Fp_SatPows[%d] = %f is out of range [0, 50]", count, SatPow);
         UT_ReportError(PVM_ErrorMessage); 
       }

     if (offset >= -2000 && offset <= 2000)
       {
	  Fp_SatOffset[count] = offset;
       }
     else
       {
//	 printf("Fp_SatOffset[%d] = %f is out of range\n",count,offset);
	 fclose(fp);
//	 return;
         sprintf(PVM_ErrorMessage, "File read error: Fp_SatOffset[%d] = %f is out of range [-2000, 2000]", count, offset);
         UT_ReportError(PVM_ErrorMessage);         
       }

     if (fa > 1 && fa <= 90)
       {
	 Fp_FlipAngle[count] = fa;
       }
     else
       {
//	 printf("Fp_FlipAngle[%d] = %f is out of range\n",count,fa);
	 fclose(fp);
//	 return;
         sprintf(PVM_ErrorMessage, "File read error: Fp_FlipAngle[%d] = %f is out of range [1, 90]", count, fa);
         UT_ReportError(PVM_ErrorMessage);         
       }

     
     if (SatDur > 0)
       {
         Fp_SatDur[count] = SatDur;
       }
     else
       {
//	 printf("Fp_SatDur[%d] = %f is out of range\n",count,SatDur);
	 fclose(fp);
//	 return;
         sprintf(PVM_ErrorMessage, "File read error: Fp_SatDur[%d] = %f is out of range [0, Inf]", count, SatDur);
         UT_ReportError(PVM_ErrorMessage);         
       }
    
  
     if (SL == 0 || SL == 1)
       {
         Fp_SLflag[count] = SL;
       }
     else
       {
//	 printf("Fp_SLflag[%d] = %f is invalid value\n",count,SL);
	 fclose(fp);
//	 return;
         sprintf(PVM_ErrorMessage, "File read error: Fp_SLflag[%d] = %f has bad value -- needs to be 0 or 1", count, SL);
         UT_ReportError(PVM_ErrorMessage);
       }
     
     
     if (SLtip >= -90 && SLtip <= 90)
       {
         Fp_SLFlipAngle[count] = SLtip;
       }
     else
       {
//	 printf("Fp_SLFlipAngle[%d] = %f is invalid value\n",count,SLtip);
	 fclose(fp);
//	 return;
         sprintf(PVM_ErrorMessage, "File read error: Fp_SLFlipAngle[%d] = %f is out of range [-90, 90]", count, SLtip);
         UT_ReportError(PVM_ErrorMessage);
       }    
  }  
  
  Number_fp_Experiments = count;  // set the number of MRF experiments
  fclose(fp);
  //backbone();
  DB_MSG (("<--  fp_ReadFromFile()\n")); 
  return;
}
/****************************************************************/
/*		E N D   O F   F I L E				*/
/****************************************************************/
