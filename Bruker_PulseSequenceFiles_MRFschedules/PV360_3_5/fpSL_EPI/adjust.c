/* ***************************************************************
 *
 * Copyright (c) 2006 - 2021
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 *
 * ***************************************************************/

#define DEBUG		0

#include "method.h"
#include "common/ovl_toolbox/AdjTools.h"


/* -------------------------------------------------------------------
  Relations of PVM_AdjHandler, called when an adjustment is starting.
  Parameter changes made her will be used for the adjustment and then
  disarded (the current scan will not be affected).
  -------------------------------------------------------------------*/
void HandleAdjustmentRequests(void)
{
  YesNo adjPossible=No,TrajAdjRequired=Yes;
  int nSubAdj;
  char  adjSequence[100];

  DB_MSG(("-->HandleAdjustmentRequests"));

  if (Yes==STB_AtsAdj()) {
    return;
  }

  if(No == PTB_AdjustmentStarting())
  {
    DB_MSG(("<--HandleAdjustmentRequests: method should not be rebuilt in adjustment platform"));
    return;
  }

  if((PVM_NSPacks==1)&&(PVM_EpiTrajAdjMeasured==No)&&(PVM_EpiTrajAdjYesNo==Yes)&&(PVM_EpiTrajAdjAutomatic==Yes))
    TrajAdjRequired=Yes;
  else
    TrajAdjRequired=No;

  // Sequence of RG sub-adjustments:
  nSubAdj = 0;
  if(TrajAdjRequired==Yes)
  {
   strcpy(adjSequence,"Traj,");
   nSubAdj++;
  }
  else
    adjSequence[0] = '\0';

  if(PVM_EpiAutoGhost==No || PVM_EpiCombine==Yes)
  {
    strcat(adjSequence,"Rg");
    nSubAdj++;
  }
  else
  {
    if(PVM_SignalType == SignalType_Fid)
    {
      strcat(adjSequence,"SeGhost,Rg");
      nSubAdj+=2;
    }
    else
    {
      strcat(adjSequence,"RgGhost");
      nSubAdj++;
    }
  }

  DB_MSG(("RG sub-adjustment sequence: %s", adjSequence));

  const char * adjName = PTB_GetAdjName();

  PVM_MbEncNBands = 1;
  if(Yes==PTB_AdjMethSpec() &&
     0 == strcmp(adjName, RG_ADJNAME))
  {
      DB_MSG(("setting up RG adjustment"));

      DB_MSG(("Subprocess: %s",PVM_AdjHandler.subprocess));

      if(PTB_CheckSubProcess(0)==Yes)
      {
          if(nSubAdj != PTB_InitSubProcess(adjSequence)) {
              DB_MSG(("Could not initialize subprocesses"));
          }
          DB_MSG(("<--HandleAdjustmentRequests (init subprocesses)"));
          return;
      }
      else if(PTB_CheckSubProcess("Traj")==Yes)
      { // adjust trajectory
          DB_MSG(("RG-Subadjustment: Traj"));
          setTrajAdj();
          adjPossible=Yes;
      }
      else if(PTB_CheckSubProcess("SeGhost")==Yes)
      { // adapt to SE, and adjust RG and ghost
          DB_MSG(("RG-Subadjustment: SeGhost"));
          setSpinEcho();
          setRGGhostAdj(Yes);
          adjPossible=Yes;
      }
      else if(PTB_CheckSubProcess("RgGhost")==Yes)
      { // adjust RG and ghost
          DB_MSG(("RG-Subadjustment: RgGhost"));
          setRGGhostAdj(Yes);
          adjPossible=Yes;
      }
      else if(PTB_CheckSubProcess("Rg")==Yes)
      { // adjust RG only
          DB_MSG(("RG-Subadjustment: Rg"));
          PVM_EpiAutoGhost=No;
          setRGGhostAdj(No);
          adjPossible=Yes;
      }
      else
          DB_MSG(("Unknown sub-adjustment"));
  }
  else if(Yes==PTB_AdjMethSpec() && !strcmp(adjName,"EpiTraj"))
  {
      DB_MSG(("setting up epi trajectory adjustment"));

      setTrajAdj();
      adjPossible = Yes;
  }
  else if(Yes==PTB_AdjMethSpec() &&
          !strcmp(adjName,"EpiGrappa"))
  {
      /* Set up a multi-shot, non-accelerated scan to adjust
         the GRAPPA parameters */

      DB_MSG(("setting up EpiGrappa adjustment"));

      ATB_EpiSetGrappaAdj();
        AdjEnableGlobalResultSave=No;
        AdjEnableUserResultSave=No;
        PvAdjManRequestNewExpno(GopAdj);
        ParentDset = PvAdjGetOriginalDatasetPath();  

        static const std::vector<AdjResultPar> epiGrappaResultPar =
            { 
                PvAdjManCreateResultPar(adj_type, "PVM_GrappaAdjScan"),
                PvAdjManCreateResultPar(adj_type, "RecoGrappaCoefficients"),
                PvAdjManCreateResultPar(adj_type, "RecoSliceGrappaCoefficients")
            };
        PvAdjManSetAdjParameterList(epiGrappaResultPar);   

      int virtualAccel[3] = {1,1,1};
      double storedZf[3] = {1.,1.,1.};
      YesNo storedEncGenPpi = PVM_EncGenPpi;
      YesNo storedEncGenCaipi = PVM_EncGenCaipirinha;
      
      if(PVM_EpiGrappaSegAdj==Yes)
      {
          NSegments *= PVM_EncPpi[1];
          /* Ds for at least 3 sec (do not set
             PVM_DummyScans which has lower priority) */
          PVM_DummyScansDur=3000; 
      }
      else{
          storedZf[1] = PVM_EncZf[1];
          PVM_EncZf[1] *= PVM_EncPpi[1];
      }

      virtualAccel[1] = PVM_EncPpi[1];
      PVM_EncPpi[1] = 1;      
      if(PTB_GetSpatDim()>2){
          PVM_AntiAlias[2] = 1;
          PVM_EncPft[2] = 1;                    
          storedZf[2] = PVM_EncZf[2];
          PVM_EncZf[2] = std::max(1.0,PVM_Matrix[2]/double(PVM_EncPpiGopRefLines[2]));
          virtualAccel[2] = PVM_EncPpi[2];
          PVM_EncPpi[2] = 1;                              
      }
      
      PVM_NRepetitions = 1;
      PVM_NAverages = 1;

      adjPossible = Yes;
      backbone();
      
      if(PTB_GetSpatDim()>2){
        PVM_EncPpi[2] = virtualAccel[2];
      }
      
      PVM_EncGenPpi = storedEncGenPpi;
      PVM_EncGenCaipirinha = storedEncGenCaipi;
      
      /* derive reco, with acceleration */
      SetRecoParam(virtualAccel[1]);
      /* copy back acceleration for further reconstructions */
      PVM_EncPpi[1] = virtualAccel[1];
      PVM_EncZf[1] = storedZf[1];
      if(PTB_GetSpatDim()>2){
        PVM_EncZf[2] = storedZf[2];
      }

  }
  else if(Yes==PTB_AdjMethSpec() &&
         !strcmp(adjName,"MbRgGhost")){
        PVM_MbEncNBands = PVM_MbEncAccelFactor;
        if(PVM_EpiAutoGhost==No || PVM_EpiCombine==Yes)
            setRGGhostAdj(No);
        else
            setRGGhostAdj(Yes);    
        adjPossible=Yes;    
  }  

  if(adjPossible == No)
  {
    PARX_sprintf("Unknown adjustment required");
    /* make illegal adjustment request fail by setting ACQ_SetupAutoName to empty string */
    ACQ_SetupAutoName[0]='\0';
  }

  DB_MSG(("<--HandleAdjustmentRequests"));
  return;
}


/*
 *  This function is called each time an adjustment is finished. Changes made here
 *  will stay for the active scan. This routine is performed in the parameter space
 *  of the active scan and NOT in the parameter space of the adjustment.
 */

void HandleAdjustmentResults(void)
{
  DB_MSG(("-->HandleAdjustmentResults"));

  const char * adjName = PTB_GetAdjResultName();

  if (0 == strcmp(adjName, RG_ADJNAME))
  {
      DB_MSG(("RCVR adjustment result"));

      DB_MSG(("Subadj: %s",PTB_GetAdjResultSubProcess()));

      if(!strcmp(PTB_GetAdjResultSubProcess(),"Traj"))
        STB_EpiHandleTrajAdjResults(PVM_Fov[0],PVM_EffSWh,PVM_SPackArrGradOrient[0][0]);
      /* Mirror parameters:
       * PVM_EpiTrajAdjFov0, PVM_EpiTrajAdjMatrix0, PVM_EpiTrajAdjBw, PVM_EpiTrajAdjComp,
       * PVM_EpiTrajAdjRampmode, PVM_EpiTrajAdjRampform, PVM_EpiTrajAdjRamptime, PVM_EpiTrajAdjReadvec
       */
  }
  else if (!strcmp(adjName,"EpiTraj"))
  {
      STB_EpiHandleTrajAdjResults(PVM_Fov[0],PVM_EffSWh,PVM_SPackArrGradOrient[0][0]);
  }
  else if(!strcmp(adjName, "EpiGrappa"))
  {
    DB_MSG(("-->HandleAdjustmentResults::EpiGrappa"));
    std::vector<std::string> grouplist = MRT_RecoGetPIParameterList(); 
  
    ParentDset = PvAdjGetOriginalDatasetPath();
    char currentScanpath[PATH_MAX];
    memset(currentScanpath,0,PATH_MAX*sizeof(char));
    FormatDataPathname(currentScanpath, 4095, IsExpnoPath, ParentDset, "Grappadset");

    /** Write a list of parameters or groups to a file. */
    ParxRelsWriteParList(grouplist,
                         currentScanpath,
                         Parx::Utils::WriteMode::NormalMode);
    DB_MSG(("<--HandleAdjustmentResults::EpiGrappa"));
    
  }

  DB_MSG(("Calling backbone"));
  backbone();
  DB_MSG(("<--HandleAdjustmentResults"));

}

void setRGGhostAdj(YesNo DoubleShot)
{
  ATB_EpiSetRgAndGhostAdj();

  /* change to to 1-shot with the same echo train length */

  if((DoubleShot==Yes)&&((PVM_EpiDoubleShotAdj==In_All)||((PVM_EpiDoubleShotAdj==In_Multishot)&&(PVM_EpiNShots>1))))
  {
    PVM_EncZf[1] *= (NSegments/2.0);
    NSegments = 2;
    PVM_EpiEchoTimeShifting=Yes;
  }
  else
  {
    PVM_EncZf[1] *= NSegments;
    NSegments = 1;
  }
  PVM_EncZf[1] *= PVM_EncPpi[1];
  PVM_EncPpi[1]=1;


  if(PTB_GetSpatDim() >2) /* limit dimensions to 2 */
  {
    int dimRange[2] = {2,2};
    int lowMat[3] = { 16, 16, 8 };
    int upMat[3]  = { 512, 512, 256 };
    int defaultMat[3] = {64,64,64};
    STB_InitEncoding( 2, dimRange, lowMat, upMat, defaultMat);
  }

  backbone();
}

void setSpinEcho(void)
{
  PVM_SignalType=SignalType_Echo;  /* adapt to SE */
  if(PVM_RepetitionTime<3000.0) PVM_RepetitionTime=3000.0;
  RefPul.Flipangle=180.0;
  ExcPul.Flipangle=90.0;
}

void setTrajAdj(void)
{

  static const std::vector<AdjResultPar> epiAdjPars =
  {
    PvAdjManCreateResultPar(adj_type, "PVM_EpiTrajAdjkx"),
    PvAdjManCreateResultPar(adj_type, "PVM_EpiTrajAdjb0"),
    PvAdjManCreateResultPar(adj_type, "PVM_EpiTrajAdjMeasured")
  };
  PvAdjManSetAdjParameterList(epiAdjPars);

  PVM_EpiAdjustMode = 3;
  PVM_EpiTrajAdjMeasured=No; //do not use previous results

  strcpy(ACQ_SetupAutoName,"PVM_EpiTrajCounter");

  /* change geometry to 2D, single package, 2 slices: */
  {
    int dimRange[2]={2,2}, lowMat[3]={16,16,8}, upMat[3]={512,512,256};
    int defaultMat[3] = {64,64,64};
    STB_InitEncoding( 2, dimRange, lowMat, upMat, defaultMat);
  }

  PVM_SliceThick = PVM_SpatResol[0];
  if(PVM_SliceThick<1.333333*PVM_MinSliceThick)
  {
    /* longer excitation pulse necessary to achieve slice thickness */
    ExcPul.Bandwidth /= (PVM_MinSliceThick / PVM_SliceThick)*1.333333;    
  }

  PVM_SPackArrNSlices[0] = 2;  
  STB_UpdateSliceGeoPars(0, 1, 0, 0.0); /* only one package */
  GObject slicegeo("PVM_SliceGeo");
  double acq_pos[3] = {0, 0, 0};
  slicegeo.getPosToAcq(acq_pos, 0);
  acq_pos[2] = acq_pos[0];
  slicegeo.setAcqToPos(acq_pos, 0);
  slicegeo.setNSubc(2, 2, 2, 0);
  slicegeo.setCuboidPar();
  STB_TransferImagGeo();
  /* Change to to 1-shot and increase zero filling to get approx. same echo train length.
     Rounding of total lines for zero filling and for NSegments may differ.
     However, this is not critical since traj is determined from 4 central odd lines.
     */

  PVM_EncZf[1] *= NSegments*PVM_EncPpi[1];
  NSegments = 1;
  PVM_EncPpi[1]=1;
  PVM_MbEncAccelFactor = 1;
  PVM_DummyScans=0;

  /*reduce Zf to get at least 10 lines for traj recon filter. */
  if (PVM_EncZf[1] >1 && PVM_EpiNEchoes < 10)
  {
    PVM_EncZf[1]= MAX_OF(1.0, PVM_EncZf[1]/(10.0/PVM_EpiNEchoes));
  }

  setSpinEcho(); /* adapt to SE */
  PVM_SPackArrSliceDistance[0] = PVM_Fov[0] * PVM_AntiAlias[0] * PVM_EpiTrajAdjDistRatio;
  PVM_SPackArrSliceGapMode[0] = non_contiguous;
  PVM_ObjOrderScheme = Sequential;
  STB_DeriveImagGeo();
  ParxRelsParRelations("PVM_SPackArrSliceDistance[0]", No); /* ->backbone(); */

  /* disable dynamic shimming for trajectory adjustment */
  PVM_DynamicShimEnable=No;

  /* Orient slices orthogonal to read direction  */

  ACQ_GradientMatrix[0][2][0]= ACQ_GradientMatrix[0][0][0];
  ACQ_GradientMatrix[0][2][1]= ACQ_GradientMatrix[0][0][1];
  ACQ_GradientMatrix[0][2][2]= ACQ_GradientMatrix[0][0][2];

  ACQ_GradientMatrix[0][1][0]=0.0;  //this deactivates blips and phase dephase
  ACQ_GradientMatrix[0][1][1]=0.0;
  ACQ_GradientMatrix[0][1][2]=0.0;

  ACQ_GradientMatrix[1][2][0]= ACQ_GradientMatrix[1][0][0];
  ACQ_GradientMatrix[1][2][1]= ACQ_GradientMatrix[1][0][1];
  ACQ_GradientMatrix[1][2][2]= ACQ_GradientMatrix[1][0][2];

  ACQ_GradientMatrix[1][1][0]=0.0;
  ACQ_GradientMatrix[1][1][1]=0.0;
  ACQ_GradientMatrix[1][1][2]=0.0;
}

void HandleGopAdjResults(void)
{

  std::string adjn(PTB_GetAdjName());
  std::ostringstream oerrst;

  if(adjn == "EpiGrappa")
  {
    DB_MSG(("-->HandleGopAdjResults"));
    bool overflowDetected = false;
    YesNo *overflow=ACQ_adc_overflow;
    int dim=(int)ParxRelsParGetDim("ACQ_adc_overflow",1);
    for(int i=0;i<dim;i++)
    {
      if(overflow[i]==Yes)
      {
        overflowDetected=true;
        oerrst << "overflow on channel " 
               << i+1 << std::endl;
      }
    }
    // write restult into expno directory of parent parameter space

    if(overflowDetected)
      throw PvStdException("Epi Grappa Adjustment failed:\n%s",
                           oerrst.str().c_str());
    PTB_RegisterGopAdj();
    AdjPerformState=adj_successful;
    

    DB_MSG(("<--HandleGopAdjResults"));

  }


 
}

