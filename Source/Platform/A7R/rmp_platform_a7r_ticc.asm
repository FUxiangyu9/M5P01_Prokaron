;/*****************************************************************************
;Filename    : rmp_platform_a7r_ticc.s
;Author      : pry
;Date        : 10/04/2012
;Description : The assembly part of the RMP RTOS. This is for ARMv7-R.
;*****************************************************************************/

;/* The ARMv7-R Architecture **************************************************
; Sys/User     FIQ   Supervisor   Abort     IRQ    Undefined
;    R0        R0        R0        R0       R0        R0
;    R1        R1        R1        R1       R1        R1
;    R2        R2        R2        R2       R2        R2
;    R3        R3        R3        R3       R3        R3
;    R4        R4        R4        R4       R4        R4
;    R5        R5        R5        R5       R5        R5
;    R6        R6        R6        R6       R6        R6
;    R7        R7        R7        R7       R7        R7
;    R8        R8_F      R8        R8       R8        R8
;    R9        R9_F      R9        R9       R9        R9
;    R10       R10_F     R10       R10      R10       R10
;    R11       R11_F     R11       R11      R11       R11
;    R12       R12_F     R12       R12      R12       R12
;    SP        SP_F      SP_S      SP_A     SP_I      SP_U
;    LR        LR_F      LR_S      LR_A     LR_I      LR_U
;    PC        PC        PC        PC       PC        PC
;---------------------------------------------------------------
;    CPSR      CPSR      CPSR      CPSR     CPSR      CPSR
;              SPSR_F    SPSR_S    SPSR_A   SPSR_I    SPSR_U
; 11111/10000  10001     10011     10111    10010     11011
;---------------------------------------------------------------
;R0-R7  : General purpose registers that are accessible
;R8-R12 : General purpose regsisters that are not accessible by 16-bit thumb
;R13    : SP, Stack pointer
;R14    : LR, Link register
;R15    : PC, Program counter
;CPSR   : Program status word
;SPSR   : Banked program status word
;The ARM Cortex-R4/5/7/8 also include a fp32 FPU.
;*****************************************************************************/

;/* Import *******************************************************************/
    ;The real task switch handling function
    .global             _RMP_Run_High
    ;The real systick handler function
    .global             _RMP_Tim_Handler
    ;The PID of the current thread
    .global             RMP_Thd_Cur
    ;The stack address of current thread
    .global             RMP_SP_Cur
;/* End Import ***************************************************************/

;/* Export *******************************************************************/
    ;Disable all interrupts
    .global             RMP_Int_Disable
    ;Enable all interrupts
    .global             RMP_Int_Enable
     ;Mask/unmask some interrupts
    .global             RMP_Int_Mask
    ;Get the MSB/LSB
    .global             _RMP_A7R_MSB_Get
    .global             _RMP_A7R_LSB_Get
    ;Start the first thread
    .global             _RMP_Start
    ;The PendSV trigger
    .global             _RMP_Yield
    ;The system pending service routine
    .global             ssiInterrupt        ;PendSV_Handler
    ;The systick timer routine
    .global             rtiNotification     ;SysTick_Handler
    ;Other unused error handlers
    .global             phantomInterrupt
;/* End Export ***************************************************************/

;/* Header *******************************************************************/
    .text
    .arm
;/* End Header ***************************************************************/

;/* Function:RMP_Int_Disable **************************************************
;Description : The function for disabling all interrupts. Does not allow nesting.
;              We never mask FIQs on Cortex-R because they are not allowed to
;              perform any non-transparent operations anyway.
;Input       : None.
;Output      : None.
;Return      : None.
;*****************************************************************************/
RMP_Int_Disable         .asmfunc
    ;Disable all interrupts (I is primask,F is Faultmask.)
    CPSID               I
    BX                  LR
    .endasmfunc
;/* End Function:RMP_Int_Disable *********************************************/

;/* Function:RMP_Int_Enable ***************************************************
;Description : The function for enabling all interrupts. Does not allow nesting.
;Input       : None.
;Output      : None.
;Return      : None.
;*****************************************************************************/
RMP_Int_Enable          .asmfunc
    ;Enable all interrupts.
    CPSIE               I
    BX                  LR
    .endasmfunc
;/* End Function:RMP_Int_Enable **********************************************/

;/* Function:RMP_Int_Mask *****************************************************
;Description : The function for masking & unmasking interrupts. This is dummy on
;              Cortex-R.
;Input       : rmp_ptr_t R0 - The new BASEPRI to set.
;Output      : None.
;Return      : None.
;*****************************************************************************/
RMP_Int_Mask            .asmfunc
    ;Mask some interrupts.
    ;MSR                 BASEPRI,R0
    ;BX                  LR
    .endasmfunc
;/* End Function:RMP_Int_Mask ************************************************/

;/* Function:_RMP_A7R_MSB_Get *************************************************
;Description : Get the MSB of the word.
;Input       : rmp_ptr_t R0 - The value.
;Output      : None.
;Return      : rmp_ptr_t R0 - The MSB position.
;*****************************************************************************/
_RMP_A7R_MSB_Get        .asmfunc
    CLZ                 R1,R0
    MOVS                R0,#31
    SUBS                R0,R0,R1
    BX                  LR
    .endasmfunc
;/* End Function:RMP_A7R_MSB_Get *********************************************/

;/* Function:RMP_A7R_LSB_Get **************************************************
;Description : Get the MSB of the word.
;Input       : rmp_ptr_t R0 - The value.
;Output      : None.
;Return      : rmp_ptr_t R0 - The MSB position.
;*****************************************************************************/
_RMP_A7R_LSB_Get        .asmfunc
	RBIT				R0,R0
    CLZ                 R0,R0
    BX                  LR
    .endasmfunc
;/* End Function:_RMP_A7R_LSB_Get ********************************************/

;/* Function:_RMP_Yield *******************************************************
;Description : Trigger a yield to another thread.
;Input       : None.
;Output      : None.
;Return      : None.
;*****************************************************************************/
_RMP_Yield              .asmfunc
    PUSH                {R0-R1}
                
    LDR                 R0,SSI1_Addr        ;The SSI interrupt register address
    MOVS                R1,#0x7500          ;The key needed to trigger such interrupt
    STR                 R1,[R0]             ;Trigger the software interrupt

    ISB                                     ;Repeated ISB to make sure interrupt happens
    ISB
    ISB
                
    POP                 {R0-R1}
    BX                  LR
    .endasmfunc
SSI1_Addr .word         0xFFFFFFB0
;/* End Function:_RMP_Yield **************************************************/

;/* Function:_RMP_Start *******************************************************
;Description : Jump to the user function and will never return from it.
;              Because the CCS startup code put us into the system state already,
;              there's no need to use interrupt return semantics - just branch to it.
;Input       : None.
;Output      : None.
;Return      : None.
;*****************************************************************************/
_RMP_Start              .asmfunc
    ;Should never reach here
    SUBS                R1,R1,#64           ;This is how we push our registers so move forward
    MOVS                SP,R1               ;Set the stack pointer
    BLX                 R0                  ;Branch to our target
Loop:
    B                   Loop                ;Capture faults
    .endasmfunc
;/* End Function:_RMP_Start **************************************************/

;/* Function:PendSV_Handler ***************************************************
;Description : The PendSV interrupt routine. In fact, it will call a C function
;              directly. The reason why the interrupt routine must be an assembly
;              function is that the compiler may deal with the stack in a different 
;              way when different optimization level is chosen. An assembly function
;              can make way around this problem.
;              However, if your compiler support inline assembly functions, this
;              can also be written in C.
;Input       : None.
;Output      : None.
;Return      : None.
;*****************************************************************************/
ssiInterrupt            .asmfunc
                        .endasmfunc
PendSV_Handler          .asmfunc
    SUBS                LR,LR,#0x04         ;Correct the LR value first - the LR is always a word behind
    SRSDB               SP!,#0x1F           ;Save LR at SVC(PC at SYS) and SPSR at SVC(CPSR at SYS)
    CPS                 #0x1F               ;Switch to SYS mode
    PUSH                {R0-R12,LR}         ;Spill all registers to stack
                
    LDR                 R0,SSIF_Addr        ;Clear the software interrupt flag
    MOV                 R1,#0x0F
    STR                 R1,[R0]

    LDR                 R1,RMP_SP_Cur_Addr  ;Save The SP to control block.
    STR                 SP,[R1]
    BL                  _RMP_Run_High       ;Get the highest ready task.
    LDR                 R1,RMP_SP_Cur_Addr  ;Load the SP.
    LDR                 SP,[R1]

    POP                 {R0-R12,LR}
    RFEIA               SP!
    .endasmfunc
SSIF_Addr .word         0xFFFFFFF8
;/* End Function:PendSV_Handler **********************************************/

;/* Function:SysTick_Handler **************************************************
;Description : The SysTick interrupt routine. In fact, it will call a C function
;              directly. The reason why the interrupt routine must be an assembly
;              function is that the compiler may deal with the stack in a different 
;              way when different optimization level is chosen. An assembly function
;              can make way around this problem.
;              However, if your compiler support inline assembly functions, this
;              can also be written in C.
;              In the TI library, this was called by a high-level C function, thus the
;              SRSDB and RFEIA are not needed.
;Input       : None.
;Output      : None.
;Return      : None.
;*****************************************************************************/
rtiNotification         .asmfunc
                        .endasmfunc
SysTick_Handler         .asmfunc
    ;SRSDB              SP!,#0x1F           ;Save LR at SVC(PC at SYS) and SPSR at SVC(CPSR at SYS)
    PUSH                {R0-R3,LR}
                
    MOVS                R0,#0x01            ;We are not using tickless.
    BL                  _RMP_Tim_Handler

    POP                 {R0-R3,PC}
    ;RFEIA              SP!
    .endasmfunc
;/* End Function:SysTick_Handler *********************************************/

RMP_SP_Cur_Addr .word   RMP_SP_Cur

phantomInterrupt .asmfunc
    B                   phantomInterrupt
    .endasmfunc
;/* End Of File **************************************************************/

;/* Copyright (C) Evo-Devo Instrum. All rights reserved **********************/
