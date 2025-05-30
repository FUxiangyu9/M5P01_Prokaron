/******************************************************************************
Filename    : rmp_platform_a7r.c
Author      : pry
Date        : 04/02/2018
Licence     : The Unlicense; see LICENSE for details.
Description : The platform specific file for ARMv7-R.
******************************************************************************/

/* Include *******************************************************************/
#define __HDR_DEF__
#include "Platform/A7R/rmp_platform_a7r.h"
#include "Kernel/rmp_kernel.h"
#undef __HDR_DEF__

#define __HDR_STRUCT__
#include "Platform/A7R/rmp_platform_a7r.h"
#include "Kernel/rmp_kernel.h"
#undef __HDR_STRUCT__

/* Private include */
#include "Platform/A7R/rmp_platform_a7r.h"

#define __HDR_PUBLIC__
#include "Kernel/rmp_kernel.h"
#undef __HDR_PUBLIC__
/* End Include ***************************************************************/

/* Function:_RMP_Stack_Init ***************************************************
Description : Initiate the process stack when trying to start a process. Never
              call this function in user application.
Input       : rmp_ptr_t Stack - The stack address of the thread.
              rmp_ptr_t Size - The stack size of the thread.
              rmp_ptr_t Entry - The entry address of the thread.
              rmp_ptr_t Param - The argument to pass to the thread.
Output      : None.
Return      : rmp_ptr_t - The adjusted stack location.
******************************************************************************/
rmp_ptr_t _RMP_Stack_Init(rmp_ptr_t Stack,
                          rmp_ptr_t Size,
                          rmp_ptr_t Entry,
                          rmp_ptr_t Param)
{
    rmp_ptr_t Ptr;
    struct RMP_A7R_Stack* Ctx;
    
    RMP_STACK_CALC(Ptr,Ctx,Stack,Size);

    Ctx->R0=Param;
    Ctx->R1=0x01010101U;
    Ctx->R2=0x02020202U;
    Ctx->R3=0x03030303U;
    Ctx->R4=0x04040404U;
    Ctx->R5=0x05050505U;
    Ctx->R6=0x06060606U;
    Ctx->R7=0x07070707U;
    Ctx->R8=0x08080808U;
    Ctx->R9=0x09090909U;
    Ctx->R10=0x10101010U;
    Ctx->R11=0x11111111U;
    Ctx->R12=0x12121212U;
    Ctx->LR=0x14141414U;
    Ctx->PC=Entry;
    Ctx->CPSR=RMP_A7R_CPSR_E|RMP_A7R_CPSR_A|RMP_A7R_CPSR_F|RMP_A7R_CPSR_M(RMP_A7R_SYS);

    /* See if the user code is thumb or ARM */
    if((Entry&0x01U)!=0U)
        Ctx->CPSR|=RMP_A7R_CPSR_T;

    return Ptr;
}
/* End Function:_RMP_Stack_Init **********************************************/

/* Function:_RMP_Lowlvl_Init **************************************************
Description : Initialize the low level hardware of the system.
Input       : None
Output      : None.
Return      : None.
******************************************************************************/
void _RMP_Lowlvl_Init(void)
{   
    RMP_A7R_LOWLVL_INIT();
    
    RMP_Int_Disable();
}
/* End Function:_RMP_Lowlvl_Init *********************************************/

/* Function:_RMP_Plat_Hook ****************************************************
Description : Platform-specific hook for system initialization.
Input       : None
Output      : None.
Return      : None.
******************************************************************************/
void _RMP_Plat_Hook(void)
{
    RMP_Int_Enable();
}
/* End Function:_RMP_Plat_Hook ***********************************************/

/* Function:RMP_Putchar *******************************************************
Description : Print a character to the debug console.
Input       : char Char - The character to print.
Output      : None.
Return      : None.
******************************************************************************/
void RMP_Putchar(char Char)
{
    RMP_A7R_PUTCHAR(Char);
}
/* End Function:RMP_Putchar **************************************************/

/* End Of File ***************************************************************/

/* Copyright (C) Evo-Devo Instrum. All rights reserved ***********************/
