/****************************************************************
 *
 * Copyright (c) 2001 - 2021
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 ****************************************************************/

#define DEBUG           0

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



void SetBaseLevelParam( void )
{

  DB_MSG(("Entering SetBaseLevelParam()"));

  SetBasicParameters();
  SetFrequencyParameters();
  SetPpgParameters();
  SetAcquisitionParameters();
  SetGradientParameters();
  SetInfoParameters();

  ATB_SetReceiverGains();
  /* setting baselevel parameters used by modules */
  ATB_SetFatSupBaselevel();
  ATB_SetSatTransBaseLevel();
  ATB_SetFovSatBaseLevel();
  ATB_EpiSetBaseLevel();
  ATB_SetTaggingBaseLevel();

#if DEBUG
  printTiming();
#endif

  DB_MSG(("Exiting SetBaseLevelParam"));

}


/* Toolboxes referenced in this file: ATB, GTB, PTB, STB, UT */


void SetBasicParameters( void )
{
  int nSlices;
  int dim;

  DB_MSG(("Entering SetBasicParameters()"));
    
  /* NSLICES */

  nSlices = GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices );

  ATB_SetNSlices( nSlices );

  /* NR */

  ATB_SetNR( PVM_SatTransRepetitions * PVM_NRepetitions );

  /* NI */

  ATB_SetNI( nSlices/PVM_MbEncNBands * PVM_NEchoImages );

  /* NA */

  ATB_SetNA( PVM_NAverages );

  /* NAE */

  ATB_SetNAE( 1 );

  /* ACQ_ns */

  ACQ_ns_list_size = PVM_NEchoImages;
  
  dim = ParxRelsParGetDim("ACQ_ns_list",1);
  if( dim != 1 )
  {
    ParxRelsParChangeDims( "ACQ_ns_list",{1});
  }
  ACQ_ns_list[0] = 1;

  /* NECHOES */

  NECHOES = PVM_NEchoImages;

  /* ACQ_obj_order */

  ParxRelsParChangeDims("ACQ_obj_order",{NI});

  if(PVM_MbEncNBands > 1){
    ATB_SetAcqObjOrder( nSlices/PVM_MbEncNBands, PVM_MbObjOrderList, PVM_NEchoImages, 1 );
  }else{
    ATB_SetAcqObjOrder( nSlices, PVM_ObjOrderList, PVM_NEchoImages, 1 );
  }  

  DB_MSG(("Exiting SetBasicParameters()"));
}

void SetFrequencyParameters( void )
{
  int nslices;

  DB_MSG(("Entering SetFrequencyParameters()"));

  ATB_SetNuc1(PVM_Nucleus1);
 
  sprintf(NUC2,"off");
  sprintf(NUC3,"off");
  sprintf(NUC4,"off");
  sprintf(NUC5,"off");
  sprintf(NUC6,"off");
  sprintf(NUC7,"off");
  sprintf(NUC8,"off");

  ATB_SetNucleus(PVM_Nucleus1);

  ACQ_O1_mode = BF_plus_Offset_list;
  ParxRelsParRelations("ACQ_O1_mode",Yes);

  O1 = 0.0;
  O2 = 0.0;
  O3 = 0.0;
  O4 = 0.0;
  O5 = 0.0;
  O6 = 0.0;
  O7 = 0.0;
  O8 = 0.0;

  /* Set BF's to working frequencies on used channels */
  ACQ_BF_enable = No;
  BF1 = PVM_FrqWork[0];
  BF2 = PVM_FrqWork[1];
  /* call relations of BF1 (no need for other BF's) */
  ParxRelsParRelations("BF1", Yes); 

  nslices = GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices );

  if(PVM_MbEncNBands > 1){
    nslices /= PVM_MbEncNBands;
    ATB_SetAcqO1List( nslices,
                      PVM_MbObjOrderList,
                      PVM_MbSliceOffsetHz );

    ATB_SetAcqO1BList( nslices,
                       PVM_MbObjOrderList,
                       PVM_MbReadOffsetHz);
  }else{
    ATB_SetAcqO1List( nslices,
                    PVM_ObjOrderList,
                    PVM_SliceOffsetHz );

    ATB_SetAcqO1BList( nslices,
                     PVM_ObjOrderList,
                     PVM_ReadOffsetHz);
  }

  ATB_SetAcqReadOffsetHzFac("PVM_SliceGeo", PVM_GradCalConst, Logical_Read_Grad, PVM_EpiReadOffsetHzFac);
          
  DB_MSG(("Exiting SetFrequencyParameters()"));
}

void SetGradientParameters( void )
{
  int spatDim, i;

  DB_MSG(("Entering SetGradientParameters()"));
  
  spatDim = PTB_GetSpatDim();

  ParxRelsParChangeDims("ACQ_phase_encoding_mode", {spatDim} );
  ParxRelsParChangeDims("ACQ_phase_enc_start", {spatDim} );

  ACQ_phase_encoding_mode[0] = Read;
  ACQ_phase_encoding_mode[1] = Linear;
  if(spatDim==3)
  {
    ACQ_phase_encoding_mode[2] = User_Defined_Encoding;
    ACQ_spatial_size_2 = PVM_EncMatrix[2];
    ParxRelsParCopy("ACQ_spatial_phase_2","PVM_EncValues2");
  }
  ParxRelsParRelations("ACQ_phase_encoding_mode",Yes);

  for( i=0; i<spatDim; i++ )
  {
    ACQ_phase_enc_start[i] = -1;
  }
   
  if(PVM_MbEncNBands > 1)
    ATB_SetAcqGradMatrix("PVM_MbSliceGeoObj");
  else
    ATB_SetAcqGradMatrix("PVM_SliceGeoObj");

  ACQ_scaling_read  = 1.0;
  ACQ_scaling_phase = 1.0;
  ACQ_scaling_slice = 1.0;

  /* gradient amplitudes */
  ACQ_gradient_amplitude[0] = ExSliceGradient;         /* g0 */
  ACQ_gradient_amplitude[1] = -ExSliceRephaseGradient; /* g1 */
  ACQ_gradient_amplitude[2] = SliceSpoiler.ampl;       /* g2 */
  ACQ_gradient_amplitude[3] = RfcSpoilerStrength;      /* g3 */

  DB_MSG(("Exiting SetGradientParameters()"));
}

void SetInfoParameters( void )
{
  int slices, i, spatDim, nrep;

  DB_MSG(("Entering SetInfoParameters()"));

  // initialize ACQ_n_echo_images ACQ_echo_descr
  //            ACQ_n_movie_frames ACQ_movie_descr
  ATB_ResetEchoDescr();
  ATB_ResetMovieDescr();

  spatDim = PTB_GetSpatDim();

  /* ACQ_dim */
  ACQ_dim = spatDim;
  ParxRelsParRelations("ACQ_dim",Yes);

  /* ACQ_dim_desc */
  ATB_SetAcqDimDesc( 0, spatDim, NULL );

  nrep = PVM_NRepetitions;

  ATB_SetAcqFov( Spatial, spatDim, PVM_Fov, PVM_AntiAlias );

  ACQ_flip_angle = ExcPul.Flipangle;

  ParxRelsParChangeDims("ACQ_echo_time",{1});
  ACQ_echo_time[0] = EchoTime;

  ParxRelsParChangeDims("ACQ_inter_echo_time",{1});
  ACQ_inter_echo_time[0] = PVM_EchoTime;

  ParxRelsParChangeDims("ACQ_repetition_time",{1});
  ACQ_repetition_time[0] = PVM_RepetitionTime;

  ParxRelsParChangeDims("ACQ_recov_time",{1});
  ACQ_recov_time[0] =  PVM_RepetitionTime - ExcPul.Length;

  /* calculation of ACQ_time_points */
  ParxRelsParChangeDims("ACQ_time_points",{nrep});
  ACQ_time_points[0] = 0;
  for(i=1; i<nrep; i++)
    ACQ_time_points[i] = OneRepTime * i; 
  
  ParxRelsParChangeDims("ACQ_inversion_time",{1});
  ACQ_inversion_time[0] = PVM_InversionTime;

  ATB_SetAcqSliceAngle( PtrType3x3 PVM_SPackArrGradOrient[0],
			PVM_NSPacks );

  ACQ_slice_orient = Arbitrary_Oblique;

  ACQ_slice_thick = PVM_SliceThick;

  slices = GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices );

  ParxRelsParChangeDims("ACQ_slice_offset",{slices});
  ParxRelsParChangeDims("ACQ_read_offset",{slices});
  ParxRelsParChangeDims("ACQ_phase1_offset",{slices});
  ParxRelsParChangeDims("ACQ_phase2_offset",{slices});

  for(i=0;i<slices;i++)
  {
    ACQ_slice_offset[i]  = PVM_SliceOffset[i];
    ACQ_read_offset[i]   = PVM_ReadOffset[i];
    ACQ_phase1_offset[i] = PVM_Phase1Offset[i];
    ACQ_phase2_offset[i] = PVM_Phase2Offset[i];
  }


  ACQ_read_ext = (int)PVM_AntiAlias[0];

  ParxRelsParChangeDims("ACQ_slice_sepn", {slices==1 ? 1 : slices-1});

  if( slices == 1 )
  {
    ACQ_slice_sepn[0] = 0.0;
  }
  else
  {
    for( i=1; i<slices;i++ )
	  {
	    ACQ_slice_sepn[i-1]=PVM_SliceOffset[i]-PVM_SliceOffset[i-1];
	  }
  }

  ATB_SetAcqSliceSepn( PVM_SPackArrSliceDistance,
                       PVM_NSPacks );

  ACQ_n_t1_points = 1;

  if( ParxRelsParHasValue("ACQ_transmitter_coil") == No )
  {
    ACQ_transmitter_coil[0] = '\0';
  }

  if( ParxRelsParHasValue("ACQ_contrast_agent") == No )
  {
      ACQ_contrast_agent[0] = '\0';
  }

  if( ParxRelsParHasValue("ACQ_contrast") == No )
  {
      ACQ_contrast.volume = 0.0;
      ACQ_contrast.dose = 0.0;
      ACQ_contrast.route[0] = '\0';
      ACQ_contrast.start_time[0] = '\0';
      ACQ_contrast.stop_time[0] = '\0';
  }

  ParxRelsParRelations("ACQ_contrast_agent",Yes);

  ACQ_position_X = 0.0;
  ACQ_position_Y = 0.0;
  ACQ_position_Z = 0.0;

  ParxRelsParChangeDims("ACQ_temporal_delay",{1});
  ACQ_temporal_delay[0] = 0.0;

  ACQ_RF_power = 0;

  ACQ_n_echo_images = PVM_NEchoImages;
  ACQ_n_movie_frames = 1;
 
  DB_MSG(("Exiting SetInfoParameters()"));

}


void SetPpgParameters( void )
{
  DB_MSG(("Entering SetPpgParameters()"));
  
   /* added for fpEPI*/
  if (PVM_SatTransOnOff == Off)
    {  
      ACQ_vd_list_size=1;
      ParxRelsParChangeDims("ACQ_vd_list",{1});
      //ACQ_vd_list[0] = 1e-6;   original code
      ACQ_vd_list[0] = ((PVM_RepetitionTime - PVM_MinRepetitionTime)/NSLICES 
			+ 0.1) / 1000.0;
      ParxRelsParRelations("ACQ_vd_list",Yes);
    }
  
  if (PVM_SatTransOnOff == On)
    {
      ACQ_vd_list_size = Number_fp_Experiments;
      ParxRelsParRelations("ACQ_vd_list_size",Yes);
     ParxRelsParChangeDims("ACQ_vd_list",{Number_fp_Experiments});
      
      for (int i=0; i < Number_fp_Experiments; i++ ) 
	{
          //dk edit: actually using Fp_TRDels here!!
	  //ACQ_vd_list[i] = 
	    //(Fp_TRs[i] - PVM_MinRepetitionTime)*1.0e-3/NSLICES + 0.1/1000;
          ACQ_vd_list[i] = Fp_TRDels[i];
	  ACQ_vd_list[i] = MAX_OF(ACQ_vd_list[i],1.0e-6);
	}
      
      ParxRelsParRelations("ACQ_vd_list",Yes);
    }
  /*****/
  

   ATB_SetPulprog("fpSL_EPI.ppg");

  double igwt = CFG_InterGradientWaitTime();
  double riseTime = CFG_GradientRiseTime();

  D[0] = (PVM_RepetitionTime - PVM_MinRepetitionTime)/NSLICES / 1000.0;
  D[1] = (RephaseTime - riseTime) / 1000.0;
  if (PVM_SignalType == SignalType_Echo)
    D[2]  = (EchoTime/2 - MinTE_right + igwt) / 1000.0;
  else
    D[2] = (EchoTime - PVM_MinEchoTime + igwt) / 1000.0;
  D[4]  = riseTime / 1000.0;
  D[3]  = (riseTime + igwt) / 1000.0;
  D[5] = SliceSpoiler.dur * 1e-3;
  D[6] = PackDel*1e-3;
  D[7]  = (EchoTime/2 - MinTE_left + igwt) / 1000.0;
  D[9] = (RfcSpoilerDuration - riseTime)*1e-3;

  /* set shaped pulses */

  ATB_SetRFPulse("ExcPul","ACQ_RfShapes[0]","P[0]");
  ATB_SetRFPulse("RefPul","ACQ_RfShapes[1]","P[1]");
  ATB_SetRFPulse("SLprepPul","ACQ_RfShapes[2]","P[2]");
  ATB_SetRFPulse("SLrfcPul","ACQ_RfShapes[3]","P[3]");

  /* loop counters */
  L[2] = PTB_GetSpatDim()>2? (PVM_EncGenTotalSteps/PVM_EncMatrix[1]):1;
  DB_MSG(("Exiting SetPpgParameters"));
}

void SetAcquisitionParameters(void)
{
  DB_MSG(("-->SetAcquisitionParameters"));

  JOBPARAMETERS(jobParameters);

  /* ------------------------------------------------ */
  /* -------               Job 0              ------- */
  /* ------------------------------------------------ */

  JOBDESCRIPTION job0=jobParameters->getOrCreateJob("job0");

  job0->initPars(1, PVM_EpiNSamplesPerScan, PVM_EpiBandwidth);

  job0->appendLoop(NSLICES/PVM_MbEncNBands);

  job0->appendLoop(PVM_DummyScans, LOOP_DUMMIES);
 
  job0->appendLoop(NA, LOOP_AVERAGE);

  if (ACQ_SetupDim > 2)
  {
    job0->appendLoop(PVM_EpiNShots); 
    job0->appendLoop(L[2], LOOP_SETUP);  //3D loop
  }
  else
  {
    job0->appendLoop(PVM_EpiNShots, LOOP_SETUP); //setup here, for online reco
    job0->appendLoop(L[2]);  //3D loop
  }

  job0->appendLoop(NR);

  
  /* ------------------------------------------------ */
  /* -------               Job 1              ------- */
  /* ------------------------------------------------ */

  int nTotalScansJob1 = NR * NA * PVM_EpiNShots * L[2];
  int nTransActBlcs = NA * PVM_EpiNShots;
  if (ACQ_SetupDim > 2) nTransActBlcs*=L[2];

  ATB_SetDriftCompBaseLevel(jobParameters, nTransActBlcs, nTotalScansJob1, PVM_DummyScans);

  DB_MSG(("<--SetAcquisitionParameters"));
}



#if DEBUG
#define d(n) D[n]*1e3
#define p(n) P[n]*1e-3

void printTiming(void)
{
  double prep, te,left_te,part1,part2,part3,tr;
  double trigOutSlice, trigOutVol;
  int nsl;

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

  DB_MSG(("-->printTiming"));

  prep=0.030 + 0.010 + PVM_FovSatModuleTime + PVM_SatTransModuleTime + PVM_FatSupModuleTime;
  part1=d(5)+d(4)+p(0)+d(3)+d(1)+d(4);
  part2=d(7)+d(9)+d(4)+p(1)+d(9)+d(4);
  part3=d(2)+(PVM_EpiModuleTime)+d(0);

  nsl = GTB_NumberOfSlices( PVM_NSPacks, PVM_SPackArrNSlices );

  left_te=ExcPul.Rpfac/100.0*p(0)+d(3)+d(1)+d(4)+d(7)+d(9)+d(4)+p(1)/2.0;
  te=ExcPul.Rpfac/100*p(0)+d(3)+d(1)+d(4)+d(2)+PVM_EpiEchoDelay;
  tr=prep+part1+part3;

  if (PVM_SignalType == SignalType_Echo) {
    tr=tr+part2; 
    te=te+part2;  
    DB_MSG(("left TE: %fms, left TE (should be): %fms ",left_te, EchoTime/2.0));
  }

  tr=nsl*(trigOutSlice+tr)+d(6)+ PVM_DriftCompModuleTime + PVM_TaggingModuleTime + trigOutVol;

  DB_MSG(("TR: %fms, TR (should be): %fms, diff: %fms",tr, PVM_RepetitionTime, (tr-PVM_RepetitionTime))); 
  DB_MSG(("TE: %fms, TE (should be): %fms, diff: %fms",te, EchoTime, (te-EchoTime)));


  DB_MSG(("Signal Type: %d,  ExcPulseLength %f, rephase %f, spoilerdur %f, refpulse %f  l %f r %f",
          PVM_SignalType, ExcPul.Length, RephaseTime, RfcSpoilerDuration, RefPul.Length, MinTE_left, MinTE_right ));  
  DB_MSG(("<--printTiming"));
}

#undef d
#undef p
#endif
