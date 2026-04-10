/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: integrator.c
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

#include "integrator.h"

/* Block states (default storage) */
DW_integrator_T integrator_DW;

/* External inputs (root inport signals with default storage) */
ExtU_integrator_T integrator_U;

/* External outputs (root outports fed by signals with default storage) */
ExtY_integrator_T integrator_Y;

/* Real-time model */
static RT_MODEL_integrator_T integrator_M_;
RT_MODEL_integrator_T *const integrator_M = &integrator_M_;

/* Model step function */
void integrator_step(void)
{
  /* Outport: '<Root>/Out1' incorporates:
   *  DiscreteIntegrator: '<Root>/Discrete-Time Integrator'
   */
  integrator_Y.Out1 = integrator_DW.DiscreteTimeIntegrator_DSTATE;

  /* Update for DiscreteIntegrator: '<Root>/Discrete-Time Integrator' incorporates:
   *  Inport: '<Root>/In1'
   */
  integrator_DW.DiscreteTimeIntegrator_DSTATE += 0.0001 * integrator_U.In1;
}

/* Model initialize function */
void integrator_initialize(void)
{
  /* (no initialization code required) */
}

/* Model terminate function */
void integrator_terminate(void)
{
  /* (no terminate code required) */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
