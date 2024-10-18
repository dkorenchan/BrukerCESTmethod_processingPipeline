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
 *   it contains functions necessary for initialisation of the
 *	onepulse method.
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


/*:=MPB=:=======================================================*
 *
 * Global Function: initMeth
 *
 * Description: This procedure is implicitly called when this
 *	method is selected.
 *
 * Error History: 
 *
 * Interface:							*/

void initMeth()
/*:=MPE=:=======================================================*/
{
  int dimRange[2] = { 2,3 };
  int lowMat[3] = { 16, 16, 8 };
  int upMat[3]  = { 512, 512, 256 };
  int defaultMat[3] = {64, 64, 32};

  DB_MSG(( "Entering epi2:initMeth()" ));

  
  /*  Initialize NA ( see code in parsRelations ) */
  Local_NAveragesRange();

  RephaseTimeRange();

  /* segments */
  NSegmentsRange();

  /* Encoding */
  STB_InitEncoding( 2, dimRange, lowMat, upMat, defaultMat);  

  /*Initialisation of repetitions time*/
  if(ParxRelsParHasValue("PVM_RepetitionTime") == No)
      PVM_RepetitionTime = 1000;

  /*Initialisation of automatic derive RF gains*/
  if(ParxRelsParHasValue("PVM_DeriveGains") == No)
      PVM_DeriveGains = Yes;

  /* Initialisation of signal type */
  if(ParxRelsParHasValue("PVM_SignalType") == No)
      PVM_SignalType = SignalType_Echo;


  /* Initialisation of rf pulse parameters */
  
  STB_InitRFPulse("ExcPul",        // name of pulse structure
                  "ExcPulseEnum",  // name of pulse list parameter
                  "ExcPulseAmpl",  // name of pulse amplitude parameter
                  "ExcPulseShape", // name of pulse shape (for calc. pulses)
                  0,               // used for excitation
                  "Calculated", // default shape
                  2000.0,          // default bandwidth
                  90.0);           // default pulse angle
  ExcPulRange();

  STB_InitRFPulse("RefPul",        // name of pulse structure
                  "RefPulseEnum",  // name of pulse list parameter
                  "RefPulseAmpl",  // name of pulse amplitude parameter
                  "RefPulseShape", // name of pulse shape (for calc. pulses)
                  1,               // used for excitation
                  "Calculated", // default shape
                  2000.0,          // default bandwidth
                  180.0);          // default pulse angle
  RefPulRange();
  
  STB_InitRFPulse("SLprepPul",        // name of pulse structure
                  "SLprepPulseEnum",  // name of pulse list parameter
                  "SLprepPulseAmpl",  // name of pulse amplitude parameter
                  "SLprepPulseShape", // name of pulse shape (for calc. pulses)
                  0,               // used for excitation
                  "bp", // default shape
                  12800.0,          // default bandwidth
                  90.0);          // default pulse angle
  SLprepPulRange();
  
  STB_InitRFPulse("SLrfcPul",        // name of pulse structure
                  "SLrfcPulseEnum",  // name of pulse list parameter
                  "SLrfcPulseAmpl",  // name of pulse amplitude parameter
                  "SLrfcPulseShape", // name of pulse shape (for calc. pulses)
                  1,               // used for excitation
                  "bp", // default shape
                  4000.0,          // default bandwidth
                  180.0);          // default pulse angle
  SLrfcPulRange();
  
  //dk: lock SLprepPul to being bp
  //ParxRelsParMakeNonEditable({"SLprepPulseEnum"});

  /* Initialisation of nucleus and frequency */  
  STB_InitNuclei(1);


  /* Initialisation of the delay between the slices packages */  
  PackDelRange();
 
  /* Initialisation of spoilers */
  MRT_InitSpoiler("SliceSpoiler");
  
  /* Initialisation of geometry parameters */ 
  STB_InitImageGeometry();
    
  /* initializtion of bandwidth */
  LocalSWhRange();

  /* Initialisation of modules */
  STB_InitEpi(UserSlope);
  STB_InitFatSupModule();
  STB_InitSatTransModule();
  STB_InitFovSatModule();
  STB_InitTriggerModule();
  STB_InitTriggerOutModule();
  STB_InitTaggingModule();
  STB_InitDummyScans(1000.0);
  STB_InitDriftComp(On);
 
 
  /* initialize mapshim parameter class */
  STB_InitMapShim(Yes);

  
 {
    DB_MSG(("-->fp_Init\n"));
    
  if(ParxRelsParHasValue("Fp_InputModeEnum") == No)
      {
	Fp_InputModeEnum = User_input;
      }

     
     if(ParxRelsParHasValue("PVM_SatTransType") == No) 
 {PVM_SatTransType = CEST;}
     
    if(ParxRelsParHasValue("Number_fp_Experiments") == No)
      {
	Number_fp_Experiments = 1;
     }
 
 //if(ParxRelsParHasValue("PVM_SatTransOnOff") == No)  
// { PVM_SatTransOnOff = On; } 

  //STB_InitFovSatModule();
  
  
    if(ParxRelsParHasValue("Fp_InputModeEnum") == No)
      {
	Fp_InputModeEnum = User_input;
         }

        
   
  if(ParxRelsParHasValue("Number_fp_Experiments") == No)
      {
	Number_fp_Experiments = 1;
     }

  if(ParxRelsParHasValue("Fp_TRs") == No)
      {
	//PARX_change_dims("Fp_TRs", 1);
      ParxRelsParChangeDims("Fp_TRs", {1});
        Fp_TRs[0] = 4000;
      }

  if(ParxRelsParHasValue("Fp_SatPows") == No)
      {
	//PARX_change_dims("Fp_SatPows", 1);
      ParxRelsParChangeDims("Fp_SatPows", {1});
        Fp_SatPows[0] = 3;
      }
  
  if(ParxRelsParHasValue("Fp_SatOffset") == No)
      {
	//PARX_change_dims("Fp_SatOffset", 1);
      ParxRelsParChangeDims("Fp_SatOffset", {1});
        Fp_SatOffset[0] = 0.0;
      }
    
     if(ParxRelsParHasValue("Fp_SatOffsetHz") == No)
      {
	//PARX_change_dims("Fp_SatOffset", 1);
      ParxRelsParChangeDims("Fp_SatOffsetHz", {1});
        Fp_SatOffsetHz[0] = 0;
      }
    
    
    
    
  
  if(ParxRelsParHasValue("Fp_PathName") == No)
    {
      sprintf(Fp_PathName, "/home/dk384/schedules/fpSL_EPI");
    }

  if(ParxRelsParHasValue("Fp_FileName") == No)
    {
      sprintf(Fp_FileName, "amine30ST.txt");
    }

  if(ParxRelsParHasValue("ACQ_vd_list") == No)
    {
      ACQ_vd_list_size=1;
      //PARX_change_dims("ACQ_vd_list",1);
       ParxRelsParChangeDims("ACQ_vd_list", {1});
      ParxRelsParRelations("ACQ_vd_list",Yes); 
      ACQ_vd_list[0] = ((PVM_RepetitionTime - PVM_MinRepetitionTime)/NSLICES 
			+ 0.1) / 1000.0;
    }

  if(ParxRelsParHasValue("PpgPowerList1") == No)
    {
      PpgPowerList1size = Number_fp_Experiments=1;
      //PARX_change_dims("PVM_ppgPowerList1", 1);  
      ParxRelsParChangeDims("PpgPowerList1", {1});
      //ParxRelsParRelations("PpgPowerList1size", Yes); 
     PpgPowerList1[0] = PVM_SatTransPulse.Pow;
    }
  
  if(ParxRelsParHasValue("Fp_FlipAngle") == No)
      {
	//PARX_change_dims("Fp_FlipAngle", 1);
    ParxRelsParChangeDims("Fp_FlipAngle", {1});
        Fp_FlipAngle[0] = 60;
      }
  
  if(ParxRelsParHasValue("PpgPowerList2") == No)
    {
      PpgPowerList2size = Number_fp_Experiments=1;
      //PARX_change_dims("PVM_ppgPowerList2", 1);  
      ParxRelsParChangeDims("PpgPowerList2", {1});
      //ParxRelsParRelations("PpgPowerList2size", Yes); 
      PpgPowerList2[0] = ExcPul.Pow;
    }

  //dk add: extra power list to contain pre/post tip powers for SL
  if(ParxRelsParHasValue("PpgPowerList3") == No)
    {
      PpgPowerList3size = Number_fp_Experiments=1;
      //PARX_change_dims("PVM_ppgPowerList3", 1);  
      ParxRelsParChangeDims("PpgPowerList3", {1});
      //ParxRelsParRelations("PpgPowerList3size", Yes); 
      PpgPowerList3[0] = SLprepPul.Pow; 
    }    
    
  if(ParxRelsParHasValue("Fp_SatDur") == No)
      {
	//PARX_change_dims("Fp_SatDur", 1);
      ParxRelsParChangeDims("Fp_SatDur", {Number_fp_Experiments});
        Fp_SatDur[0] = 3000;
      }

  if(ParxRelsParHasValue("Fp_SLflag") == No)
  {
    //PARX_change_dims("Fp_SatDur", 1);
  ParxRelsParChangeDims("Fp_SLflag", {Number_fp_Experiments});
    Fp_SLflag[0] = 0;
  }

  if(ParxRelsParHasValue("Fp_SLFlipAngle") == No)
  {
    //PARX_change_dims("Fp_SatDur", 1);
  ParxRelsParChangeDims("Fp_SLFlipAngle", {1});
    Fp_SLFlipAngle[0] = 90;
  }    
  
  
  
  
  /* Visibility of Scan Editor parameters */
  ParxRelsParShowInEditor({"PVM_EchoTime","PVM_NEchoImages"});
  ParxRelsParShowInFile({"PVM_EchoTime","PVM_NEchoImages"});
  ParxRelsParMakeNonEditable({"PVM_EchoTime","PVM_MinEchoTime"});
  ParxRelsParMakeNonEditable({"PVM_NEchoImages","PVM_EchoPosition"});


 if(ParxRelsParHasValue("TempGridding") == No)
      TempGridding = No;

  if(!ParxRelsParHasValue("GopAdj"))
    GopAdj = Yes;

  STB_InitAtsReferencePosition();


   


   
   backbone();
 

  DB_MSG(( "Exiting epi2:initMeth()" ));
/* Once all parameters have initial values, the backbone is called
     to assure they are consistent */
  
}
   

  
   
  

  return;
}
  


/****************************************************************/
/*		E N D   O F   F I L E				*/
/****************************************************************/