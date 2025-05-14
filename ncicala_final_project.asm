;*****************************************************************************
;  Author: Nicholas Cicala
;  Date: 05/14/2025
;  Revision: 1.0
;
;  Description:
;    A Program that implements floating point conversion. user can
;    convert a decimal number to a floating point number
;    16 bit Floating point number is 1 for sign, 5 for exponent, 10 for mantissa
;  Notes:
;    Due to the nature of floating point numbers, very large floating point numbers
;    cannot be translated into decimal.
;       
;
;  Register Usage:
;     R0 Reserved for TRAP
;     R1 Decimal number
;     R2 16 bit floating point number
;     R3 Counter
;     R4 Used for Calculations
;     R5 Used for Calculations
;     R6 Reserved for Stack
;     R7 Subroutine directions

;****************************************************************************/
        .ORIG x3000
        
        ;Initial Setup subroutine
        JSR Setup
        ;Input a number
        JSR Input
        ;Calculate the floating point number
        JSR Calculate
        ;Return the full binary set and find fraction
        AND R1, R1, #0 ;R1 = R2
        ADD R1, R1, R2
        
        
        ADD R1, R1, R6
        JSR Output
        
        HALT
        
;************************Setup*****************************
;This subroutine cleans up used registers.
;
;**************************************************************
Setup
        LD R6, STACK
        
        ST R7,SaveR7S
        ;Clean registers
        AND R0, R0, #0
        AND R1, R1, #0
        AND R2, R2, #0
        AND R3, R3, #0
        AND R4, R4, #0
        AND R5, R5, #0
        
        LD R7,SaveR7S
        RET
        
        SaveR7S  .BLKW #1
        STACK .FILL xFE00
;************************Input*****************************
;This subroutine prints the prompt for the input and handles switching modes
;
;R0 - reserved for TRAP
;R1 - Decimal value
;R5 - Temporary storage for R1
;R7 - address stack usage
;**************************************************************
Input
        ST R7,SaveR7I
        LEA R0,PromptNum ; Starting address of the prompt string
        TRAP x22    ;print prompt
        JSR InputRec
        ADD R1, R5, #0
        LD R7,SaveR7I
        RET
        
        SaveR7I  .BLKW #1
        PromptNum  .STRINGZ "\nEnter a number (Enter to exit, - to negate and exit): "

;************************InputRec*****************************
;This subroutine handles the input (Can handle large numbers hopefully)
;
;R0 - reserved for TRAP
;R1 - decimal value
;R3 - Counter
;R4 - AsctoDec
;R5 - Calculating help
;R6 - Stack usage
;R7 - address stack usage
;**************************************************************
InputRec
        ;save registers using stack
        ADD R6, R6, #-1
        STR R7, R6, #0
        
        TRAP x20    ;read character without display
                    ;the character stored in R0
        TRAP x21    ;write the character
        
        ;Check if user entered enter
        ADD R0, R0, #-10
        BRz Enter
        ADD R0, R0, #10
        
        ;Check if user entered minus
        ADD R0, R0, #-16
        ADD R0, R0, #-16
        ADD R0, R0, #-13
        BRz Minus
        ADD R0, R0, #15
        ADD R0, R0, #15
        ADD R0, R0, #15
        
        ;change ASCII into decimal and store in R2
        LD  R4, AsToDec
        ADD R2, R0, R4
        ADD R1, R1, R2
        
        ;Multiply by 10
        AND R3, R3, #0  ;Setup
        ADD R3, R3, #9
        AND R5, R5, #0
        ADD R5, R5, R1
        ;AND R1, R1, #0
        x10loop ADD R1, R1, R5 ;Multiply
        ADD R3, R3, #-1
        BRp x10loop

        ;Recursive addition
        JSR InputRec
Enter      
        
        ;Restore Registers via stack
        LDR R7, R6, #0
        ADD R6, R6, #1

        RET
        
        Minus
        NOT R5, R5
        ADD R5, R5, #1
        BRnzp Enter
;***************************************************************
AsToDec  .FILL xFFD0 ; -48 use to change ASCII char to decimal
        
;************************Calculate*****************************
;This subroutine converts the decimal number to floating point form
;
;R1 - Decimal
;R2 - Float
;R3 - 2^power value, for calculation
;R4 - Decimal - power of 2
;R5 - Counter
;R6 - Power Value
;R7 - Used as temporary storage for Negative
;**************************************************************
Calculate
        ST R7,SaveR7C
        AND R2,R2,#0
        AND R7,R7,#0
        ;First, check if negative
        ADD R1, R1, #0
        BRzp noNeg
        ADD R2, R2, #1;Add to array
        
        NOT R1, R1 ;invert number if negative
        ADD R1, R1, #1
        ADD R7, R7, #1
        
        
noNeg   ;Then, determine power (2^n > input)
        AND R6, R6, #0 ;Power to zero
        AND R3, R3, #0;Set R3 = #-1
        ADD R3, R3, #-1
        
lpower  ADD R6, R6, #1 ;increment Power
        ADD R4, R3, R1 ;Decimal - power of 2
        ADD R3, R3, R3 ;Double power of 2
        ADD R4, R4, #0 ;Is Decimal - power of 2 less than 0?
        BRzp lpower
        
        ADD R6, R6, #-1 ;Power value is set
        ADD R5, R6, #0 ;Counter is now set
        AND R3, R3, #0;reset R3 = #-1
        ADD R3, R3, #-1 
lexp    ADD R3, R3, R3;Rebuild value
        ADD R5, R5, #-1
        BRp lexp
        
        LD R5, Floatexp
        ADD R6, R5, R6 ;Power = 15 - R6
        AND R3, R3, #0 ;Set Counter to 5
        ADD R3, R3, #5
        
Move1   ADD R2, R2, R2 ; Move five times
        ADD R3, R3, #-1
        BRp Move1
        ADD R2, R2, R6 ; add power to line
        ADD R3, R3, #10
        
Move2   ADD R2, R2, R2 ; Move ten more times
        ADD R3, R3, #-1
        BRp Move2
        
        ADD R4, R4, R7;R4
        NOT R6, R4
        
        LD R7,SaveR7C
        RET
        
        SaveR7C  .BLKW #1
        Floatexp .FILL #15

;************************Output*****************************
;This subroutine outputs the floating point number
;
;R0 - Trap
;R1 - Decimal
;R2 - DectoAsc
;R3 - Counter
;**************************************************************
Output
        ST R7,SaveR7O
        AND R0, R0, #0 ;Prepare R0
        LD R2, DectoAsc ;Load Decimal to ASC conversion
        AND R3, R3, #0 ;Prepare counter for output
        ADD R3, R3, #15
OutLoop        
        ADD R1, R1, #0 ;Check if 1st bit is 1
        BRn neg
        ADD R0, R2, #0 ;first bit is 0, output 0
        TRAP x21
        BRnzp doneOu 
neg     ADD R0, R2, #1 ;first bit is 1, output 1
        TRAP x21 
        
doneOu  ADD R1, R1, R1 ;Shift R1 once
        ADD R3, R3, #-1 ;Decrement counter
        BRzp outLoop
        
        LD R7,SaveR7O
        RET

        DectoAsc .FILL x0030
        SaveR7O  .BLKW #1

        .END
