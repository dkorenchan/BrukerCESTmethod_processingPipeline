;****************************************************************
; $Source$
;
; Copyright (c) 2018
; Bruker BioSpin MRI GmbH
; D-76275 Ettlingen, Germany
;
; All Rights Reserved
;
; SatTrans.mod: Declaration of subroutine for Saturation transfer 
; call
; subr SatTrans()
;
; $Id$
;****************************************************************
;**** Saturation Transfer Module ****


; PVM_SatTransFL:        List of offset frequencies to be measured.
; PVM_SattransNPulses:   Number of pulses used in one saturation event
; PVM_SattransPowerList: List of RF amplitudes for saturation pulses.
;                        Two elements long: first element: 0 Watt,
;                        used for one reference scan. Subsequent scans
;                        use amplitude as specified in UI.
; StReference:           If PVM_SatTransRefScan is On then list StRfPower
;                        has two elements (1st is zero for reference scan)
;                        If RefScan is Off then lsit has only one element.
;			 Nevertheless we increment to avoid another 'if' 
;
; DK note: This module will perform regular spin-locking if the magnetization is
; to be kept along an oblique effective locking B-field. If the water locking is 
; on-resonance (i.e. locking offset = 0; B_eff is in the xy-plane), the sequence 
; will perform a balanced spin-lock sequence instead (see Gram et al, MRM 2021)


if(PVM_SatTransOnOff)
{
  ;define list<frequency> modlis5    = {$PVM_SatTransFL}
  define list<frequency> modlis5    = {$PVM_SatTransFL}
  ;define list<power> StRfPower      = {$PVM_SatTransPowerList}
  define list<power> StRfPower      = {$PpgPowerList1}
  define list<power> PreSLRfPower   = {$PpgPowerList3}   
  ;define list<pulse> SatDuration    = {$Fp_SatDuration }
  ;DK add for saturation/lock flag toggle:
  define list<loopcounter> isSL     = {$Fp_SLflag}      
    
  define delay StD0                 = {$PVM_StD0}
  define delay StD1                 = {$PVM_StD1}
  define delay StD2                 = {$PVM_StD2}
  define delay StD3                 = {$PVM_StD3}

  ; added for on-res SL
  define list<phase> Php1={90.0}
  define list<phase> Php2={0.0}
  define list<phase> Php3={270.0}
  define list<phase> Php4={180.0}
  ; end on-res SL additions

  define list<pulse> StP0           = {$Fp_SatDuration };{$PVM_StP0}

  define loopcounter StNPulses      = {$PVM_SatTransNPulses}
  
  define loopcounter StReference
  "StReference = 1"
}

subroutine SatTransInit()
{
  if(PVM_SatTransOnOff)
  {
              0u    modlis5.res
              0u    StRfPower.res 
              0u    PreSLRfPower.res 
              0u    StP0.res
              0u    isSL.res
  }
}


subroutine SatTransInc()
{
  if(PVM_SatTransOnOff)
  {
       0u    modlis5.inc
       0u    isSL.inc

    if "StReference == 1"
    {
              ;0u    StRfPower.inc
                    "StReference = 0" ;switch off after 1st 'inc'
    }
    
     0u     StRfPower.inc
     0u     PreSLRfPower.inc
     0u     StP0.inc      
  }
}


subroutine SatTrans()
{
  if(PVM_SatTransOnOff)
  {
    if "isSL == 1" goto SL
    goto Sat

     SL,    5u
            "p62 = 0.25 * StP0"
            "p63 = 0.5 * StP0"
            10u PreSLRfPower:f1
            (p2:sp2(currentpower) Php1):f1    ;first 90, on-res w/ H2O
            10u StRfPower:f1
;                lock,   10u gatepulse 1
            StD1    modlis5:f1  ;gatepulse 1
            if "modlis5 == 0" goto BSLlock
            goto regSLlock

            BSLlock,    (p62:sp43(currentpower) Php2):f1
                        StD1    fq1:f1  ;gatepulse 1
                        (p3:sp3 Php2):f1    ;first 180, on-res w/ H2O
                        StD1    modlis5:f1  ;gatepulse 1
                        10u StRfPower:f1    ;gatepulse 1
                        (p63:sp43(currentpower) Php4):f1
                        StD1    fq1:f1  ;gatepulse 1
                        (p3:sp3 Php4):f1    ;second 180, on-res w/ H2O
                        StD1    modlis5:f1  ;gatepulse 1
                        10u StRfPower:f1    ;gatepulse 1
                        (p62:sp43(currentpower) Php2):f1  
                        lo to BSLlock times StNPulses
                        goto PostSL

            regSLlock,  (StP0:sp43(currentpower) Php2):f1
                        lo to regSLlock times StNPulses
                        goto PostSL
               
            PostSL, StD1    fq1:f1  ;gatepulse 1
                    10u PreSLRfPower:f1
                    (p2:sp2(currentpower) Php3):f1
                    goto EndSpoil                        

     Sat,   10u     StRfPower:f1
            pulse,     StD1    modlis5:f1
            StP0:   sp43(currentpower):f1

            lo to pulse times StNPulses
            goto EndSpoil

     EndSpoil,  StD2    grad_ramp{0, 0, PVM_SatTransSpoil.ampl}
                StD3    groff
  }
}
