/* ***************************************************************
 *
 * Copyright (c) 2022
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 * ***************************************************************/

#define DEBUG	 0


/****************************************************************/
/****************************************************************/
/*              I N T E R F A C E   S E C T I O N               */
/****************************************************************/
/****************************************************************/

/****************************************************************/
/*              I N C L U D E   F I L E S                       */
/****************************************************************/


#include "method.h"

void SetRecoParam(int acceleration)
{
  DB_MSG(("Entering SetRecoParam"));
  
  ATB_EpiSetRecoPars(acceleration, 1, 1);
  
  if(PVM_EncPpiRefScan && PVM_EpiAdjustMode == 0){
    char currentScanpath[PATH_MAX];
    PvOvlUtilGetExpnoPath(currentScanpath, PATH_MAX, "Grappadset");   
    if(UT_FileAccessForRead(currentScanpath)){
        ParxRelsParMakeNonEditable({MRT_RecoGetPIParameterList()});
        ParxRelsParRelations("RecoGrappaAccelFactor", Yes);
    }
  }
  
  DB_MSG(("Exiting SetRecoParam"));
}

/* Relation of RecoUserUpdate, called at start of reconstruction
   to set reconstrution process */
 
void RecoDerive(void)
{
  DB_MSG(("-->RecoDerive\n"));


  /* standard settings for reconstruction */
  if(RecoPrototype == No && (PVM_EpiAdjustMode != 2 || No==PTB_AdjMethSpec())) //do not call in grappa adj
  {
     SetRecoParam(PVM_EncPpi[1]);
  }

  /* GRAPPA adjustments or reconstruction with existing GRAPPA coefficients */
  if(PVM_EncPpiRefScan && (PVM_EpiAdjustMode == 0 || (PVM_EpiAdjustMode == 2 && No==PTB_AdjMethSpec()))){  
      ParentDset = ATB_SetGrappaReco(true,
              (PVM_EpiAdjustMode == 2 && No==PTB_AdjMethSpec()), 
              PVM_EncNReceivers,ParentDset,false);   
  }

  ATB_EpiSetRecoProcess(PVM_EncNReceivers, PVM_EncCentralStep1, PVM_NEchoImages);

  DB_MSG(("<--RecoDerive\n"));
}
