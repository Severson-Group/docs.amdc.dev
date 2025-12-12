/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: integrator.h
 *
 * Code generated for Simulink model 'integrator'.
 *
 * Model version                  : 1.2
 * Simulink Coder version         : 25.2 (R2025b) 28-Jul-2025
 * C/C++ source code generated on : Fri Dec 12 15:58:48 2025
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: Intel->x86-64 (Windows64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef integrator_h_
#define integrator_h_
#ifndef integrator_COMMON_INCLUDES_
#define integrator_COMMON_INCLUDES_
#include "rtwtypes.h"
#include "math.h"
#endif                                 /* integrator_COMMON_INCLUDES_ */

#include "integrator_types.h"

/* Macros for accessing real-time model data structure */
#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm)         ((rtm)->errorStatus)
#endif

#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val)    ((rtm)->errorStatus = (val))
#endif

/* Block states (default storage) for system '<Root>' */
typedef struct {
  real_T DiscreteTimeIntegrator_DSTATE;/* '<Root>/Discrete-Time Integrator' */
} DW_integrator_T;

/* External inputs (root inport signals with default storage) */
typedef struct {
  real_T In1;                          /* '<Root>/In1' */
} ExtU_integrator_T;

/* External outputs (root outports fed by signals with default storage) */
typedef struct {
  real_T Out1;                         /* '<Root>/Out1' */
} ExtY_integrator_T;

/* Real-time Model Data Structure */
struct tag_RTM_integrator_T {
  const char_T * volatile errorStatus;
};

/* Block states (default storage) */
extern DW_integrator_T integrator_DW;

/* External inputs (root inport signals with default storage) */
extern ExtU_integrator_T integrator_U;

/* External outputs (root outports fed by signals with default storage) */
extern ExtY_integrator_T integrator_Y;

/* Model entry point functions */
extern void integrator_initialize(void);
extern void integrator_step(void);
extern void integrator_terminate(void);

/* Real-time Model object */
extern RT_MODEL_integrator_T *const integrator_M;

/*-
 * The generated code includes comments that allow you to trace directly
 * back to the appropriate location in the model.  The basic format
 * is <system>/block_name, where system is the system number (uniquely
 * assigned by Simulink) and block_name is the name of the block.
 *
 * Use the MATLAB hilite_system command to trace the generated code back
 * to the model.  For example,
 *
 * hilite_system('<S3>')    - opens system 3
 * hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
 *
 * Here is the system hierarchy for this model
 *
 * '<Root>' : 'integrator'
 */
#endif                                 /* integrator_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
