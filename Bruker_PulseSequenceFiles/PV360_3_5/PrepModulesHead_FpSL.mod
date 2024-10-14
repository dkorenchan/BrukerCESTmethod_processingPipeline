;****************************************************************
;
; Copyright (c) 2003-2007
; Bruker BioSpin MRI GmbH
; D-76275 Ettlingen, Germany
;
; $Id$
;
; All Rights Reserved
;
; Declaration of pulseprogram parameters and subroutines for 
; preparation  modules
;
; Must be included after MRI.include!
;
;****************************************************************

;**** Fat Suppression ****

#include "FatSup.mod"

;**** Flow Saturation ****

#include "FlowSat.mod" 

;**** Saturation Transfer ****

;#include "SatTrans_FpSL_BSL.mod" 
;#include "SatTrans_FpSL_SL.mod" 
#include "SatTrans_FpSL_comboSL.mod" 

;*** FOV Saturation ***

#include "FovSat.mod"

;**** Black Blood ****

#include "BlBlood.mod"

;**** Trigger ****

#include "Trigger.mod"

;**** Trigger Out ****

#include "TriggerOut.mod"

;**** Outer Volume Suppression ****

#include "WsOvs.mod"

;**** Solvent Suppression module ****

#include "WsSat.mod"

;**** Selective Inversion Recovery ****

#include "SliceSelIr.mod"

;**** Tagging ****

#include "Tagging.mod"

;**** Noe ****

#include "Noe.mod"

;**** Evolution ****

#include "Evolution.mod"

;**** Drift Compensation ****

#include "DriftComp.mod"
