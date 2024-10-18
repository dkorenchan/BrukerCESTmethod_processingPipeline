/****************************************************************
 *
 * Copyright (c) 1999-2021
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 *
 ****************************************************************/

#define DEBUG		0

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


/*:=MPB=:=======================================================*
 *
 * Global Function: loadMeth
 *
 * Description: This procedure is automatically called in
 *	response to a method file for this method being read.
 *
 * Error History: 
 *
 * Interface:							*/

void loadMeth
  (
  const char *	className
  )

/*:=MPE=:=======================================================*/
{
  DB_MSG(( "Entering EPI:loadMeth( %s )", className ));


  if (0 != className)
  {
      if (0 == strcmp( className, "MethodClass"))
      {
          DB_MSG(( "...responding to loadMeth call - I know this class" ));
          MRT_CheckOperationMode();
          initMeth();
      }
      else if (0 == strcmp(className, "MethodRecoGroup"))
      {
          DB_MSG(("...responding to loadMeth call for MethodRecoGroup."));
          // Adapt parent dataset path.
          if (ParxRelsParHasValue("ParentDset"))
              PvAdjManCorrectProcnoResultPath(ParentDset, study_result);
          SetRecoParam(PVM_EncPpi[1]);
      }
  }
  else
  {
    DB_MSG(( "...ignoring loadMeth call - I don't know this class" ));
  }

  DB_MSG(( "Exiting EPI:loadMeth( %s )", className ));
}

/****************************************************************/
/*		E N D   O F   F I L E				*/
/****************************************************************/


