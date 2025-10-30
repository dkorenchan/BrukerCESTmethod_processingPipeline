/****************************************************************
 *
 * Copyright (c) 2013 - 2020
 * Bruker BioSpin MRI GmbH
 * D-76275 Ettlingen, Germany
 *
 * All Rights Reserved
 *
 ****************************************************************/

#ifndef METHRELS_H
#define METHRELS_H

/* gen/src/prg/methods/EPI/initMeth.c */
void initMeth(void);
/* gen/src/prg/methods/EPI/loadMeth.c */
void loadMeth(const char *);
/* gen/src/prg/methods/EPI/parsRelations.c */
void ExcPulseEnumRelation(void);
void ExcPulRelation(void);
void ExcPulRange(void);
void ExcPulseAmplRel(void);
void RefPulseEnumRelation(void);
void RefPulRelation(void);
void RefPulRange(void);
void RefPulseAmplRel(void);
void SLprepPulseEnumRelation(void);
void SLprepPulRelation(void);
void SLprepPulRange(void);
void SLprepPulseAmplRel(void);
void SLrfcPulseEnumRelation(void);
void SLrfcPulRelation(void);
void SLrfcPulRange(void);
void SLrfcPulseAmplRel(void);
void HandleRFPulseAmplitudes(void);
void PackDelRange(void);
void PackDelRelation(void);
void RephaseTimeRels(void);
void RephaseTimeRange(void);
void Local_NAveragesRange(void);
void Local_NAveragesHandler(void);
void LocalSWhRange(void);
void LocalSWhRels(void);
void NSegmentsRels(void);
void NSegmentsRange(void);
void SliceSpoilerRel(void);
void Fp_ReadFromFile(void);
void Fp_ReadFromFileRels(void);
//void Fp_NExpRel(void);
void Fp_NExpRels(void);
//void Fp_Init(void);
void Update_FpExperiment(void);
/* gen/src/prg/methods/EPI/BaseLevelRelations.c */
void SetBaseLevelParam(void);
void SetBasicParameters(void);
void SetFrequencyParameters(void);
void SetGradientParameters(void);
void SetInfoParameters(void);
void SetPpgParameters(void);
void SetAcquisitionParameters(void);
/* gen/src/prg/methods/EPI/RecoRelations.c */
void SetRecoParam(int);
void RecoDerive(void);
/* gen/src/prg/methods/EPI/adjust.c */
void HandleAdjustmentRequests(void);
void HandleAdjustmentResults(void);
void HandleGopAdjResults(void);
void setRGGhostAdj(YesNo);
void setSpinEcho(void);
void setTrajAdj(void);
/* gen/src/prg/methods/EPI/backbone.c */
void backbone(void);
void rfcSpoilerUpdate(void);
void echoTimeRels(void);
void repetitionTimeRels(void);
void LocalGeometryMinimaRels(double, double, double *);
void LocalGradientStrengthRels(void);
void LocalFrequencyOffsetRels(void);
bool GridGrad(double *, double *, double, double, double, double);
/* gen/src/prg/methods/EPI/deriveVisu.c */
void deriveVisu(void);


#endif

/****************************************************************/
/*      E N D   O F   F I L E                                   */
/****************************************************************/

