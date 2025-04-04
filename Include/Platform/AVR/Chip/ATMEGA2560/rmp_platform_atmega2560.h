/******************************************************************************
Filename   : rmp_platform_atmega2560.h
Author     : pry
Date       : 24/06/2017
Licence    : The Unlicense; see LICENSE for details.
Description: The configuration file for ATMEGA2560.
******************************************************************************/

/* Define ********************************************************************/
/* The AVR I/O library */
#include "avr/io.h"

/* Debugging */
/* Assertion */
#define RMP_ASSERT_ENABLE           (1U)
/* Invalid parameter checking */
#define RMP_CHECK_ENABLE            (1U)
/* Debug logging */
#define RMP_DBGLOG_ENABLE           (1U)

/* System */
/* The maximum number of preemption priorities */
#define RMP_PREEMPT_PRIO_NUM        (16U)
/* The maximum number of slices allowed */
#define RMP_SLICE_MAX               (10000U)
/* The maximum number of semaphore counts allowed */
#define RMP_SEM_CNT_MAX             (1000U)
/* The stack size of the init thread */
#define RMP_INIT_STACK_SIZE         (256U)

/* GUI */
#define RMP_GUI_ENABLE              (0U)
/* Anti-aliasing */
#define RMP_GUI_ANTIALIAS_ENABLE    (0U)
/* Widgets */
#define RMP_GUI_WIDGET_ENABLE       (0U)

/* What is the Systick value? 50U = 12800 cycles = 0.8ms */
#define RMP_AVR_TICK_VAL            (50U)
/* Does the chip have RAMP, EIND, and is it XMEGA? */
#define RMP_AVR_COP_RAMP            (1U)
#define RMP_AVR_COP_EIND            (1U)
#define RMP_AVR_COP_XMEGA           (0U)

/* Other low-level initialization stuff - clock and serial.
 * This is the default initialization sequence. If you wish to supply
 * your own, just redirect this macro to a custom function, or do your
 * initialization stuff in the initialization hook (RMP_START_HOOK). */
#define RMP_AVR_LOWLVL_INIT() \
do \
{ \
    /* USART0 TX pin - PE1 */ \
    DDRE=0x02U; \
    /* USART0 - double speed, TX only, 115200-8-N-1 */ \
    UCSR0A=0x02U; \
    UCSR0B=0x08U; \
    UCSR0C=0x06U; \
    UBRR0=16U; \
    /* Timer 0 - CTC mode, UP counter, prescaler 256 */ \
    TCNT0=0x00U; \
    OCR0A=RMP_AVR_TICK_VAL; \
    TIFR0=0x00U; \
    TCCR0A=0x02U; \
    TCCR0B=0x04U; \
    TIMSK0=0x02U; \
} \
while(0)

/* Flag is auto cleared upon entry so this is not really needed */
#define RMP_AVR_TIM_CLR()           (TIFR0=0xFFU)

/* This is for debugging output */
#define RMP_AVR_PUTCHAR(CHAR) \
do \
{ \
    /* Wait for transmit buffer to be empty */ \
    while((UCSR0A&0x20U)==0U); \
    UDR0=(CHAR); \
} \
while(0)
/* End Define ****************************************************************/

/* End Of File ***************************************************************/

/* Copyright (C) Evo-Devo Instrum. All rights reserved ***********************/
