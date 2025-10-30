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

/*:=INFO=:*******************************************************
 * Description :
 *   This file contains method dependant derivation of the 
 *   visu overlay values.
 *::=info=:******************************************************/

/****************************************************************/
/****************************************************************/
/*		I N T E R F A C E   S E C T I O N		*/
/****************************************************************/
/****************************************************************/

/****************************************************************/
/*		I N C L U D E   F I L E S			*/
/****************************************************************/

#include "machine.h"
/*--------------------------------------------------------------*
 * system include files...
 *--------------------------------------------------------------*/

/*--------------------------------------------------------------*
 * ParaVision include files...
 *--------------------------------------------------------------*/

/*--------------------------------------------------------------*
 * local include files...
 *--------------------------------------------------------------*/
#include "method.h"
#include "generated/VisuIds.h"

/****************************************************************/
/*		E X T E R N A L   F U N C T I O N S		*/
/****************************************************************/

/****************************************************************/
/*		E X T E R N A L   V A R I A B L E S		*/
/****************************************************************/

/****************************************************************/
/*		G L O B A L   V A R I A B L E S			*/
/****************************************************************/

/****************************************************************/
/****************************************************************/
/*	I M P L E M E N T A T I O N   S E C T I O N		*/
/****************************************************************/
/****************************************************************/

/****************************************************************/
/*		L O C A L   D E F I N I T I O N S		*/
/****************************************************************/

/****************************************************************/
/*	L O C A L   F U N C T I O N   P R O T O T Y P E S	*/
/*			forward references			*/
/****************************************************************/

/****************************************************************/
/*		L O C A L   V A R I A B L E S			*/
/****************************************************************/

/****************************************************************/
/*		G L O B A L   F U N C T I O N S			*/
/****************************************************************/


/*:=MPB=:=======================================================*
 *
 * Global Function: deriveVisu
 * Description:
 *	DTI dependant visu creation.
 * Interface:							*/
void 
deriveVisu(void)
/*:=MPE=:=======================================================*/
{
  DB_MSG (("Entered deriveVisu()"));

  /* Standard Visu Derivation */
  ParxRelsParRelations("VisuDerivePars", Yes);
  if (0 == VisuFileVersion)
  {  
    VisuAcqEchoTrainLength = PVM_EpiNEchoes;

    double swh = PVM_EffSWh * PVM_AntiAlias[0];

    if ( 0.0 < swh)
	    VisuAcqPixelBandwidth = swh/(double)PVM_EncMatrix[0];
  }

  if(PVM_EpiAdjustMode == 2){
      if(No==PTB_AdjMethSpec()){
        std::vector<std::string> grouplist = MRT_RecoGetPIParameterList();
        PVM_GrappaAdjScan.procno = VisuProcessingNumber;
        char currentScanpath[PATH_MAX];
        memset(currentScanpath,0,PATH_MAX*sizeof(char));
        FormatDataPathname(currentScanpath, 4095, ParentDset.prefix, ParentDset.study,
                        ParentDset.expno, 0, "Grappadset");

        /** Write a list of parameters or groups to a file. */
        ParxRelsWriteParList(grouplist,
                             currentScanpath,
                             Parx::Utils::WriteMode::NormalMode);  
      }else{
        std::ostringstream oss;
        oss << "ADJ_GRAPPA_E" << ParentDset.expno;
        strncpy(VisuAcquisitionProtocol,oss.str().c_str(),64);
        VisuAcquisitionProtocol[63]='\0';
      }

  }

  DB_MSG (("Leave deriveVisu()"));
}


/****************************************************************/
/*		L O C A L   F U N C T I O N S			*/
/****************************************************************/


/****************************************************************/
/*		E N D   O F   F I L E				*/
/****************************************************************/
