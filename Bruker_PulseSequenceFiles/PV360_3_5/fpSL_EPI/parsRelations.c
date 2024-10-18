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

/* -----------------------------------------------------------
   Relations of ExcPulse
 
   -----------------------------------------------------------*/
   
void ExcPulseEnumRelation(void)
{
  DB_MSG(("-->ExcPulseEnumRelation"));

  UT_SetRequest("ExcPulseEnum");
  backbone();
  
  DB_MSG(("<--ExcPulseEnumRelation"));                                       
}

void ExcPulRelation(void)
{
  DB_MSG(("-->ExcPulRelation"));
  
  UT_SetRequest("ExcPul");
  ExcPulRange();
  backbone();
  
  DB_MSG(("<--ExcPulRelation"));
}

void ExcPulRange(void)
{
  DB_MSG(("-->ExcPulse1Range"));
    
 ExcPul.Flipangle = MIN_OF(90.0,MAX_OF(ExcPul.Flipangle,1.0));

 DB_MSG(("<--ExcPulseRange")); 
}

void ExcPulseAmplRel(void)
{
  DB_MSG(("-->ExcPulseAmplRel"));
  
  UT_SetRequest("ExcPulseAmpl");
  HandleRFPulseAmplitudes();
  
  DB_MSG(("-->ExcPulseAmplRel"));
}

/* --------------------------------------------------------------
   Relations of RefPul

   --------------------------------------------------------------*/

void RefPulseEnumRelation(void)
{
  DB_MSG(("-->RefPulseEnumRelation"));

  UT_SetRequest("RefPulseEnum");
  backbone();
  
  DB_MSG(("<--RefPulseEnumRelation"));                                       
}

void RefPulRelation(void)
{
  DB_MSG(("-->RefPulRelation"));
  
  UT_SetRequest("RefPul");
  RefPulRange();
  backbone();
  
  DB_MSG(("<--RefPulRelation"));
}

void RefPulRange(void)
{
  DB_MSG(("-->RefPulse1Range"));
    
 RefPul.Flipangle = MIN_OF(180.0,MAX_OF(RefPul.Flipangle,1.0));

 DB_MSG(("<--RefPulseRange")); 
}

void RefPulseAmplRel(void)
{
  DB_MSG(("-->RefPulseAmplRel"));
  
  UT_SetRequest("RefPulseAmpl");
  HandleRFPulseAmplitudes();
  
  DB_MSG(("-->RefPulseAmplRel"));
}

/* -----------------------------------------------------------
   Relations of SLprepPulse and SLrfcPulse
 
   -----------------------------------------------------------*/
   
void SLprepPulseEnumRelation(void)
{
  DB_MSG(("-->SLprepPulseEnumRelation"));

  UT_SetRequest("SLprepPulseEnum");
  backbone();
  
  DB_MSG(("<--SLprepPulseEnumRelation"));                                       
}

void SLprepPulRelation(void)
{
  DB_MSG(("-->SLprepPulRelation"));
  
  UT_SetRequest("SLprepPul");
  SLprepPulRange();
  backbone();
  
  DB_MSG(("<--SLprepPulRelation"));
}

void SLprepPulRange(void)
{
  DB_MSG(("-->SLprepPulse1Range"));

 //dk note: I'm not sure the tip angle can be negative...can it?? Will it change the pulse phase?? 
 SLprepPul.Flipangle = MIN_OF(90.0,SLprepPul.Flipangle);
 SLprepPul.Flipangle = MAX_OF(-90.0,SLprepPul.Flipangle);
 
 DB_MSG(("<--SLprepPulseRange")); 
}

void SLprepPulseAmplRel(void)
{
  DB_MSG(("-->SLprepPulseAmplRel"));
  
  UT_SetRequest("SLprepPulseAmpl");
  HandleRFPulseAmplitudes();
  
  DB_MSG(("-->SLprepPulseAmplRel"));
}

void SLrfcPulseEnumRelation(void)
{
  DB_MSG(("-->SLrfcPulseEnumRelation"));

  UT_SetRequest("SLrfcPulseEnum");
  backbone();
  
  DB_MSG(("<--SLrfcPulseEnumRelation"));                                       
}

void SLrfcPulRelation(void)
{
  DB_MSG(("-->SLrfcPulRelation"));
  
  UT_SetRequest("SLrfcPul");
  SLrfcPulRange();
  backbone();
  
  DB_MSG(("<--SLrfcPulRelation"));
}

void SLrfcPulRange(void)
{
  DB_MSG(("-->SLrfcPulse1Range"));

  SLrfcPul.Flipangle = MIN_OF(180.0,MAX_OF(SLrfcPul.Flipangle,1.0));
 
  DB_MSG(("<--SLrfcPulseRange")); 
}

void SLrfcPulseAmplRel(void)
{
  DB_MSG(("-->SLrfcPulseAmplRel"));
  
  UT_SetRequest("SLrfcPulseAmpl");
  HandleRFPulseAmplitudes();
  
  DB_MSG(("-->SLrfcPulseAmplRel"));
}

void HandleRFPulseAmplitudes(void)
{
  DB_MSG(("-->HandleRFPulseAmplitude"));

  STB_UpdateRFShapeAmplitude("ExcPulseAmpl,RefPulseAmpl,SLprepPulseAmpl,SLrfcPulseAmpl",No);
  ATB_SetRFPulse("ExcPul","ACQ_RfShapes[0]");
  ATB_SetRFPulse("RefPul","ACQ_RfShapes[1]");
  ATB_SetRFPulse("SLprepPul","ACQ_RfShapes[2]");
  ATB_SetRFPulse("SLrfcPul","ACQ_RfShapes[3]");

  DB_MSG(("<--HandleRFPulseAmplitude"));
}

/* --------------------------------------------------------------
   Other Relations

   --------------------------------------------------------------*/

void PackDelRange( void )
{
  if(ParxRelsParHasValue("PackDel") == No)
    PackDel = 0.0;
  PackDel = MAX_OF(PackDel,0.0);
}

void PackDelRelation( void )
{
  PackDelRange();
  backbone();
}

void RephaseTimeRels(void)
{
  RephaseTimeRange();
  backbone();
}

void RephaseTimeRange(void)
{
  if(!ParxRelsParHasValue("RephaseTime"))
    RephaseTime = 2.0;

  RephaseTime = MAX_OF(RephaseTime, 2*CFG_GradientRiseTime());
}

void Local_NAveragesRange(void)
{
  int ival;
  DB_MSG(("Entering Local_NAveragesRange"));
  
  /* 
   *  Range check of PVM_NAverages: prevent it to be negative or 0
   */

  if(ParxRelsParHasValue("PVM_NAverages") == No)
    {
      PVM_NAverages = 1;
    }

  ival = PVM_NAverages;
  PVM_NAverages = MAX_OF(ival,1);
  

  DB_MSG(("Exiting Local_NAveragesRange"));


}



void Local_NAveragesHandler(void)
{

  DB_MSG(("Exiting Local_NAveragesHandler with value %d",PVM_NAverages));

  Local_NAveragesRange();

  /*
   *   Averages range check is finished, handle the request by
   *   the method:
   */

  
  backbone();


  DB_MSG(("Exiting Local_NAveragesHandler with value %d",PVM_NAverages));
  return;
}
void LocalSWhRange(void)
{
  DB_MSG(("-->LocalSWhRange"));
  double minmax[2]={50000.0,1000000.0};

  if(!ParxRelsParHasValue("PVM_EffSWh"))
    PVM_EffSWh=200000.0;

  if (ParxRelsParHasValue("PVM_EpiRampComp") && PVM_EpiRampComp != Yes)
    MRT_GetNearestBandwidthInHz("PVM_EffSWh",minmax);

  DB_MSG(("<--LocalSWhRange"));
}

void LocalSWhRels(void)
{
  DB_MSG(("-->LocalSWhRel"));

  LocalSWhRange();
  backbone();

  DB_MSG(("<--LocalSWhRel"));
  return;
}


/* relations of NSegments */

void NSegmentsRels(void)
{
  NSegmentsRange();
  backbone();
}

void NSegmentsRange(void)
{
  if(!ParxRelsParHasValue("NSegments"))
    NSegments = 1;
  else
    NSegments = MAX_OF(1,NSegments);
}

/* relations of slice spoiler */
void SliceSpoilerRel(void)
{
  DB_MSG(("-->SliceSpoilerRel"));
  UT_SetRequest("SliceSpoiler");
  backbone();
  DB_MSG(("<--SliceSpoilerRel"));
}

void Fp_ReadFromFileRels(void)
{
  //DB_MSG(("-->Fp_ReadFromFileRel"));
 UT_SetRequest("Fp_inputmodeEnum");
  backbone();
 // DB_MSG(("<--Fp_ReadFromFileRel"));
}


void Fp_NExpRels(void)
{
   // DB_MSG(("-->Number_fp_Experiments"));
 UT_SetRequest("Number_fp_Experiments");
 backbone();
  DB_MSG(("<--Number_fp_Experiments"));
}

/*
void Fp_SatPulseOffsetRels(void)
{
  UT_SetRequest("Fp_SatOffsetEnum");
  backbone();
 * 
 * UT_SetRequest("RefPulseAmpl");
  HandleRFPulseAmplitudes();
 * 
}
*/
/****************************************************************/
/*		E N D   O F   F I L E				*/
/****************************************************************/
