/*** asmMult.s   ***/
    
/* Tell the assembler to allow both 16b and 32b extended Thumb instructions */
.syntax unified

/* Tell the assembler that what follows is in data memory    */
.data
.align
 
/* define and initialize global variables that C can access */

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Vivian Overbey"  

.align   /* realign so that next mem allocations are on word boundaries */
 
/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global a_Multiplicand,b_Multiplier,a_Sign,b_Sign,a_Abs,b_Abs,init_Product,final_Product
.type a_Multiplicand,%gnu_unique_object
.type b_Multiplier,%gnu_unique_object
.type rng_Error,%gnu_unique_object
.type a_Sign,%gnu_unique_object
.type b_Sign,%gnu_unique_object
.type prod_Is_Neg,%gnu_unique_object
.type a_Abs,%gnu_unique_object
.type b_Abs,%gnu_unique_object
.type init_Product,%gnu_unique_object
.type final_Product,%gnu_unique_object

/* NOTE! These are only initialized ONCE, right before the program runs.
 * If you want these to be 0 every time asmMult gets called, you must set
 * them to 0 at the start of your code!
 */
a_Multiplicand:  .word     0  
b_Multiplier:    .word     0  
rng_Error:       .word     0 
a_Sign:          .word     0  
b_Sign:          .word     0 
prod_Is_Neg:     .word     0 
a_Abs:           .word     0  
b_Abs:           .word     0 
init_Product:    .word     0
final_Product:   .word     0

 /* Tell the assembler that what follows is in instruction memory    */
.text
.align

.global asmUnpack, asmAbs, asmMult, asmFixSign, asmMain
.type asmUnpack,%function
.type asmAbs,%function
.type asmMult,%function
.type asmFixSign,%function
.type asmMain,%function

 
/* function: asmUnpack
 *    inputs:   r0: contains the packed value. 
 *                  MSB 16bits is signed multiplicand (a)
 *                  LSB 16bits is signed multiplier (b)
 *              r1: address where to store unpacked, 
 *                  sign-extended 32 bit a value
 *              r2: address where to store unpacked, 
 *                  sign-extended 32 bit b value
 *    outputs:  r0: No return value
 *              memory: 
 *                  1) store unpacked A value in location
 *                     specified by r1
 *                  2) store unpacked B value in location
 *                     specified by r2
 */
asmUnpack:      
    /* preserve (calling convention part 1) */
    push {r4-r11,LR} /* preserve non-parameter registers, and link */

    /* function */
    /* use arithmetic shift to move 16 MSB into lower 16 MSB (a) */
    ASR r11, r0, 16 
    
    /* shift left, and then back right arithmeticaly to clear MSBs and extend sign (b) */
    LSL r10, r0, 16
    ASR r10, r10, 16 
    
    /* store results */
    STR r11, [r1]
    STR r10, [r2]
    
    /* restore (calling convention part 2) */
    pop {r4-r11,LR} /* restore non-parameter registers, and link */
    MOV PC, LR /* move the link register to the program counter to branch back to caller */

 
/* function: asmAbs
 *    inputs:   r0: contains signed value
 *              r1: address where to store absolute value
 *              r2: address where to store sign bit 0 = "+", 1 = "-")
 *    outputs:  r0: Absolute value of r0 input. Same value as stored to location given in r1
 *              memory: store absolute value in location given by r1
 *                      store sign bit in location given by r2
 */    
asmAbs:  
    /* preserve (calling convention part 1) */
    push {r4-r11,LR} /* preserve non-parameter registers, and link */

    /* function */    
    CMP r0, 0 /* updates flags for inputs */
    NEGMI r0, r0 /* if value is negative (MI), negate to get abs */
    MOVMI r11, 1 /* if value is negative (MI), set r11 to 1 to indicate negative */
    MOVPL r11, 0 /* if value is positive (PL), set r11 to 0 to indicate positive. Zero is considered positive */
    /* store in outputs */
    STR r0, [r1]
    STR r11, [r2]
    
    /* restore (calling convention part 2) */
    pop {r4-r11,LR} /* restore non-parameter registers, and link */
    MOV PC, LR /* move the link register to the program counter to branch back to caller */

 
/* function: asmMult
 *    inputs:   r0: contains abs value of multiplicand (a)
 *              r1: contains abs value of multiplier (b)
 *    outputs:  r0: initial product: r0 * r1
 */ 
asmMult:   
    /* preserve (calling convention part 1) */
    push {r4-r11,LR} /* preserve non-parameter registers, and link */

    /* function */
    MUL r0, r0, r1 /* multiply instruction for simplicity (slides said it was OK to use) */
    
    /* restore (calling convention part 2) */
    pop {r4-r11,LR} /* restore non-parameter registers, and link */
    MOV PC, LR /* move the link register to the program counter to branch back to caller */
    
    
/* function: asmFixSign
 *    inputs:   r0: initial product from previous step: 
 *              (abs value of A) * (abs value of B)
 *              r1: sign bit of originally unpacked value
 *                  of A
 *              r2: sign bit of originally unpacked value
 *                  of B
 *    outputs:  r0: final product:
 *                  sign-corrected version of initial product
 */ 
asmFixSign:   
    /* preserve (calling convention part 1) */
    push {r4-r11,LR} /* preserve non-parameter registers, and link */

    /* function */
    TEQ r1, r2 /* performs exclusive or. If only one sign is negative, the product will be negative */
    NEGNE r0, r0 /* negate the product if the result of the TEQ is not 0 (product is negative, as 1 negative sign is present) */
    
    /* restore (calling convention part 2) */
    pop {r4-r11,LR} /* restore non-parameter registers, and link */
    MOV PC, LR /* move the link register to the program counter to branch back to caller */


/* function: asmMain
 *    inputs:   r0: contains packed value to be multiplied
 *                  using shift-and-add algorithm
 *           where: MSB 16bits is signed multiplicand (a)
 *                  LSB 16bits is signed multiplier (b)
 *    outputs:  r0: final product: sign-corrected product
 *                  of the two unpacked A and B input values
 *    NOTE TO STUDENTS: 
 *           To implement asmMain, follow the steps outlined
 *           in the comments in the body of the function
 *           definition below.
 */  
asmMain:   
    push {r4-r11,LR}
    
    /* function */
    
    /* Step 1:
     * call asmUnpack. Have it store the output values in a_Multiplicand
     * and b_Multiplier.
     */

    /* r1 and r2 need to hold addresses for storing unpacked values to work with asmUnpack function */
     LDR r1, =a_Multiplicand 
     LDR r2, =b_Multiplier
    /* INPUTS: r0 - packed value, r1 - address to store unpacked a, r2 - address to store unpacked b */
    /* OUTPUT: none, memory is modified */
     BL asmUnpack

     /* pull the values back out of memory while we still have the addresses loaded */
     LDR r0, [r1]
     LDR r11, [r2] /* put aside for now */
     
     
     /* Step 2a:
      * call asmAbs for the multiplicand (a). Have it store the absolute value
      * in a_Abs, and the sign in a_Sign.
      */

     LDR r1, =a_Abs
     LDR r2, =a_Sign
    /* INPUTS: r0 - value, r1 - address to store ABS, r2 - adress where to store sign */
    /* OUTPUT: r0 - value ABS */
     BL asmAbs
     MOV r10, r0 /* put aside ABS of a for now */
     
     /* Step 2b:
      * call asmAbs for the multiplier (b). Have it store the absolute value
      * in b_Abs, and the sign in b_Sign.
      */

     MOV r0, r11 /* move back b value */
     LDR r1, =b_Abs
     LDR r2, =b_Sign
    /* INPUTS: r0 - value, r1 - Adress to store ABS, r2, adress where to store sign */
    /* OUTPUT: r0 - value ABS */
     BL asmAbs

    /* Step 3:
     * call asmMult. Pass a_Abs as the multiplicand, 
     * and b_Abs as the multiplier.
     * asmMult returns the initial (positive) product in r0.
     * In this function (asmMain), store the output value  
     * returned asmMult in r0 to mem location init_Product.
     */

    /* move values into appropiate input registers. 
     Alternativly could just use the singular instruction "MOV r1, r0", however
     This way keeps the opperands in the specified order. Dosen't affect the
     math at all either way. */
    MOV r1, r0
    MOV r0, r10
    /* INPUTS: r0 - multiplicand (a), r1 - multiplier (b)*/
    /* OUTPUT: r0 - product */
    BL asmMult

    /* store intial product for tests */
    LDR r11, =init_Product; STR r0, [r11]
    
    /* Step 4:
     * call asmFixSign. Pass in the initial product, and the
     * sign bits for the original a and b inputs. 
     * asmFixSign returns the final product with the correct
     * sign. Store the value returned in r0 to mem location 
     * final_Product.
     */
    
    /* retreive the signs from memory */
    LDR r1, =a_Sign; LDR r1, [r1]
    LDR r2, =b_Sign; LDR r2, [r2]
    
    /* INPUTS: r0 - ABS product, r1 - multiplicand (a) sign, r2 - multiplier (b) sign */
    /* OUTPUT: r0 - product with fixed sign */
    BL asmFixSign

    /* store final product for tests */
    LDR r11, =final_Product; STR r0, [r11]
    
    
     /* Step 5:
      * END! Return to caller. Make sure of the following:
      * 1) Stack has been correctly managed.
      * 2) the final answer is stored in r0, so that the C call 
      *    can access it.
      */

    /* restore (calling convention part 2) */
    pop {r4-r11,LR} /* restore non-parameter registers, and link */
    MOV PC, LR /* move the link register to the program counter to branch back to caller */

 
.end   /* the assembler will ignore anything after this line. */
