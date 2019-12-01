
#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
#include <shell.h>

#define BLUE        0xd8
#define GREEN       0x7c
#define BORDERGREEN 0x6c
#define DARKGREEN   0x08
#define WHITE       0xff
#define YELLOW      0x3f
#define CYAN        0x3d
#define RED         0x07

#define X_START     3
#define X_END       67
#define Y_START     5
#define Y_END       69


#define WALL    0xFF
#define SNAKE_R 0x01
#define SNAKE_U 0x02
#define SNAKE_L 0x03
#define SNAKE_D 0x04
#define FOOD    0x32
#define EMPTY   0x00

#define INIT_HEAD_X 16
#define INIT_HEAD_Y 15
#define INIT_TAIL_X 15
#define INIT_TAIL_Y 15

#define RIGHT   0x01
#define UP      0x02
#define LEFT    0x03
#define DOWN    0x04

    .set noreorder
    .set noat
    .section .text.snake
    .p2align 2

###
### Snake Main
###
SnakeEntry:
    addiu sp, sp, -40
    sw ra, 0(sp)
    sw gp, 4(sp)
    sw s0, 8(sp)
    sw s1, 12(sp)
    sw s2, 16(sp)
    sw s3, 20(sp)
    sw s4, 24(sp)
    sw s5, 28(sp)
    sw s6, 32(sp)
    sw s7, 36(sp)
    addiu sp, sp, -1024  # allocate 32 * 32 blocks to save the state
    move gp, sp
SnakeStart:
    # initialize arena
    jal ClearScreen
    nop

    jal PrintSideMessage
    nop
    
    jal FillBackGround
    nop

    jal FillBorder
    nop

    # 
    # initialize head and tail
    #
    li s0, INIT_HEAD_X
    li s1, INIT_HEAD_Y
    li s2, INIT_TAIL_X
    li s3, INIT_TAIL_Y
    #
    # default direction is right
    #
    li s4, RIGHT
    li s5, 0   # scores

    # draw 'em
    move a0, s0
    move a1, s1
    li a2, GREEN
    li a3, SNAKE_R
    jal UpdateAndRenderTile
    nop

    move a0, s2
    move a1, s3
    li a3, SNAKE_R
    jal UpdateAndRenderTile
    nop

    # Get Food and render it
    jal GetFoodPos
    nop
    move a0, v0
    move a1, v1
    li a2, WHITE
    li a3, FOOD
    jal UpdateAndRenderTile
    nop

    move a0, s5
    jal PrintScore
    nop

SnakeLoop:
    # clear previous input
    lui t0, %hi(GPIOBASE)
    sw zero, 0x4(t0)

    # Game loop of snake
    li a0, 500
    jal Sleep
    nop

    # Update direction from GPIO input
    lui t0, %hi(GPIOBASE)
    lw t1, 0x4(t0)
    li t2, 0x8
    beq t1, t2, _InputUp
    nop
    li t2, 0x4
    beq t1, t2, _InputDown
    nop
    li t2, 0x2
    beq t1, t2, _InputLeft
    nop
    li t2, 0x1
    beq t1, t2, _InputRight
    nop
    move t4, s4
    j _NoInput
    nop
_InputUp:
    li t4, UP
    j _NoInput
    nop
_InputDown:
    li t4, DOWN
    j _NoInput
    nop
_InputLeft:
    li t4, LEFT
    j _NoInput
    nop
_InputRight:
    li t4, RIGHT
_NoInput:
    sub t5, t4, s4
    sub t6, s4, t4
    slt t7, t5, zero  # t5 < zero ?
    movn t5, t6, t7   # t5 = abs(dst-src)
    li t6, 2
    sub t5, t5, t6
    movn s4, t4, t5   # if not the opposite direction
    jal MoveSnake
    nop
    bnez v0, SnakeLoop # move success, continue the game
    nop

# fail prompt
    jal PrintFailPrompt
    nop
    bnez v0, SnakeStart # 1 for retry
    nop

SnakeExit:
    # deallocate
    jal ClearScreen
    nop

    addiu sp, sp, 1024
    lw ra, 0(sp)
    lw gp, 4(sp)
    lw s0, 8(sp)
    lw s1, 12(sp)
    lw s2, 16(sp)
    lw s3, 20(sp)
    lw s4, 24(sp)
    lw s5, 28(sp)
    lw s6, 32(sp)
    lw s7, 36(sp)
    addiu sp, sp, 40
    jr ra
    nop

###
### End Snake Main
###

### Helpers
PrintScore:
    # a0: score to print (0-999)
    addiu sp, sp, -16
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)

    move s0, zero
    move s1, zero
    move s2, zero
    beq a0, zero, _Finish
    li t0, 10
_Div0:
    divu a0, t0
    mfhi s0
    mflo a0
    beq a0, zero, _Finish
    nop
_Div1:
    divu a0, t0
    mfhi s1
    mflo s2
_Finish:
    li a0, 75 # x = 75
    li a1, 60 # y = 60
    jal ClearBitMap
    nop

    li a0, 75
    li a1, 60
    li a2, YELLOW
    lui a3, %hi(charcode_0)
    ori a3, a3, %lo(charcode_0)
    li t0, 35
    multu t0, s2
    mflo s2
    addu a3, s2
    jal DrawFromBitMap
    nop

    
    li a0, 82
    li a1, 60
    jal ClearBitMap
    nop

    li a0, 82
    li a1, 60
    li a2, YELLOW
    lui a3, %hi(charcode_0)
    ori a3, a3, %lo(charcode_0)
    li t0, 35
    multu t0, s1
    mflo s1
    addu a3, s1
    jal DrawFromBitMap
    nop

    li a0, 89
    li a1, 60
    jal ClearBitMap
    nop

    li a0, 89
    li a1, 60
    li a2, YELLOW
    lui a3, %hi(charcode_0)
    ori a3, a3, %lo(charcode_0)
    li t0, 35
    multu t0, s0
    mflo s0
    addu a3, s0
    jal DrawFromBitMap
    nop


    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    addiu sp, sp, 16
    jr ra
    nop

PrintFailPrompt:
    addiu sp, sp, -4
    sw ra, 0(sp)

    li a0, X_START
    li a1, Y_START

    # print Oops! in yellow
    li a2, YELLOW
    addiu a1, 16
    addiu a0, 12 + 6
    lui a3, %hi(charcode_O)
    ori a3, a3, %lo(charcode_O)
    jal DrawFromBitMap
    nop

    addiu a0, 6
    lui a3, %hi(charcode_o)
    ori a3, a3, %lo(charcode_o)
    jal DrawFromBitMap
    nop

    addiu a0, 6
    lui a3, %hi(charcode_p)
    ori a3, a3, %lo(charcode_p)
    jal DrawFromBitMap
    nop

    addiu a0, 6
    lui a3, %hi(charcode_s)
    ori a3, a3, %lo(charcode_s)
    jal DrawFromBitMap
    nop

    addiu a0, 6
    lui a3, %hi(charcode_exclaim)
    ori a3, a3, %lo(charcode_exclaim)
    jal DrawFromBitMap
    nop

    # print Retry in cyan
    addiu a1, 20
    li a2, CYAN
    li a0, X_START
    addiu a0, 12

    lui a3, %hi(charcode_R)
    ori a3, a3, %lo(charcode_R)
    jal DrawFromBitMap
    nop

    addiu a0, 6
    lui a3, %hi(charcode_e)
    ori a3, a3, %lo(charcode_e)
    jal DrawFromBitMap
    nop

    addiu a0, 6
    lui a3, %hi(charcode_t)
    ori a3, a3, %lo(charcode_t)
    jal DrawFromBitMap
    nop

    addiu a0, 6
    lui a3, %hi(charcode_r)
    ori a3, a3, %lo(charcode_r)
    jal DrawFromBitMap
    nop

    addiu a0, 6
    lui a3, %hi(charcode_y)
    ori a3, a3, %lo(charcode_y)
    jal DrawFromBitMap
    nop

    addiu a0, 12
    lui a3, %hi(charcode_arrow_up)
    ori a3, a3, %lo(charcode_arrow_up)
    jal DrawFromBitMap
    nop

    # print Exit in red
    addiu a1, 9
    li a2, RED
    li a0, X_START
    addiu a0, 12 + 6

    lui a3, %hi(charcode_E)
    ori a3, a3, %lo(charcode_E)
    jal DrawFromBitMap
    nop

    addiu a0, 6
    lui a3, %hi(charcode_x)
    ori a3, a3, %lo(charcode_x)
    jal DrawFromBitMap
    nop

    addiu a0, 6
    lui a3, %hi(charcode_i)
    ori a3, a3, %lo(charcode_i)
    jal DrawFromBitMap
    nop

    addiu a0, 6
    lui a3, %hi(charcode_t)
    ori a3, a3, %lo(charcode_t)
    jal DrawFromBitMap
    nop

    addiu a0, 12
    lui a3, %hi(charcode_arrow_down)
    ori a3, a3, %lo(charcode_arrow_down)
    jal DrawFromBitMap
    nop

    # clear previous input
    lui t0, %hi(GPIOBASE)
    sw zero, 0x4(t0)
_LWaitInput:
    lui t0, %hi(GPIOBASE)
    li t2, 0x8  # Up arrow
    li t3, 0x4  # Down arrow
    lw t1, 0x4(t0)
    beq t1, t2, _Retry
    nop
    beq t1, t3, _Exit
    nop
    nop
    nop
    nop
    nop
    j _LWaitInput
    nop
_Exit:
    li v0, 0
    j _PromptRet
    nop
_Retry:
    li v0, 1
_PromptRet:
    lw ra, 0(sp)
    addiu sp, sp, 4
    jr ra
    nop

MoveSnake:
    # s0, s1 current head (global var)
    # s2, s3 current tail (gloabl var)
    # s4 direction (gloabl var)
    # s5 scores (gloabl var)
    # s6, s7 local vars
    # returns: v0: can move ?
    addiu sp, sp, -44
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s6, 20(sp)
    sw s7, 24(sp)
    sw a0, 28(sp)
    sw a1, 32(sp)
    sw a2, 36(sp)
    sw a3, 40(sp)

    li t0, UP
    beq s4, t0, _MoveUp
    nop
    li t0, DOWN
    beq s4, t0, _MoveDown
    nop
    li t0, LEFT
    beq s4, t0, _MoveLeft
    nop
_MoveRight:
    addiu s0, s0, 1
    li s6, SNAKE_R
    j _Moving
    nop
_MoveLeft:
    addiu s0, s0, -1
    li s6, SNAKE_L
    j _Moving
    nop
_MoveUp:
    addiu s1, s1, -1
    li s6, SNAKE_U
    j _Moving
    nop
_MoveDown:
    addiu s1, s1, 1
    li s6, SNAKE_D
    j _Moving
    nop

_CheckCanMove:
    li t0, FOOD
    bne v0, t0, _MoveFail  # do not allow move to non-empty blocks other than food
    nop
    # create new food
    move a0, s0
    move a1, s1
    li a2, SNAKE_D # stub status
    jal UpdateTileStatus
    nop
    jal GetFoodPos
    nop
    # render this new food
    move a0, v0
    move a1, v1
    li a2, WHITE
    li a3, FOOD
    jal UpdateAndRenderTile
    addiu s5, s5, 1 # add score
    move a0, s5
    jal PrintScore
    nop
    j _CanMove
    nop
_MoveFail:
    # restore global var
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    move v0, zero
    j _MoveRet
    nop
_Moving:
    move a0, s0
    move a1, s1
    jal GetTileStatus
    nop
    bnez v0, _CheckCanMove
    nop
    # no food available, need to evict tail
    move a0, s2
    move a1, s3
    jal GetTileStatus
    nop
    move s7, v0
    move a0, s2
    move a1, s3
    li a2, DARKGREEN
    li a3, EMPTY
    jal UpdateAndRenderTile
    nop
    li t0, UP
    beq s7, t0, _TailUp
    nop
    li t0, DOWN
    beq s7, t0, _TailDown
    nop
    li t0, LEFT
    beq s7, t0, _TailLeft
    nop
_TailRight:
    addiu s2, s2, 1
    j _TailMoveOk
    nop
_TailUp:
    addiu s3, s3, -1
    j _TailMoveOk
    nop
_TailDown:
    addiu s3, s3, 1
    j _TailMoveOk
    nop
_TailLeft:
    addiu s2, s2, -1
    j _TailMoveOk
    nop
_TailMoveOk:
_CanMove:
    # maintain the status of adjacent blocks
    lw a0, 4(sp)
    lw a1, 8(sp)
    move a2, s6
    jal UpdateTileStatus
    nop

    # move the head
    move a0, s0
    move a1, s1
    li a2, GREEN
    move a3, s6
    jal UpdateAndRenderTile # draw new head
    li v0, 1   # move success

_MoveRet:
    lw ra, 0(sp)
    lw s6, 20(sp)
    lw s7, 24(sp)
    lw a0, 28(sp)
    lw a1, 32(sp)
    lw a2, 36(sp)
    lw a3, 40(sp)
    addiu sp, sp, 44
    jr ra
    nop

UpdateAndRenderTile:
    # a0: x, a1: y, a2: color, a3: set status
    addiu sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    move s0, a0
    move s1, a1
    li a0, X_START
    li a1, Y_START
    sll t0, s0, 1
    sll t1, s1, 1
    addu a0, a0, t0
    addu a1, a1, t1
    jal DrawSnakeTile
    nop
    # set status
    sll t0, s1, 5
    addu t0, t0, s0
    addu t0, t0, gp
    sb a3, 0(t0)
    
    move a0, s0
    move a1, s1
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addiu sp, sp, 12
    jr ra
    nop

UpdateTileStatus:
    # a0: x, a1: y, a2: new_stat
    move t0, a0
    move t1, a1
    sll t0, a1, 5
    addu t0, t0, a0
    addu t0, t0, gp
    sb a2, 0(t0)
    jr ra
    nop

GetTileStatus:
    # a0: x, a1: y
    move t0, a0
    move t1, a1
    sll t0, a1, 5
    addu t0, t0, a0
    addu t0, t0, gp
    lb v0, 0(t0)
    jr ra
    nop

GetFoodPos:
    addiu sp, sp, -4
    sw ra, 0(sp)
_LGetFood:
    mfc0 t0, CP0_COUNT
    multu t0, t0
    mflo t1
    xor t0, t0, t1
    andi t0, t0, (0x20-1)
    srl t1, 5
    andi t1, t1, (0x20-1)
    move a0, t0
    move a1, t1
    jal GetTileStatus
    nop
    andi t0, v0, 0xFF
    bnez t0, _LGetFood
    nop
    move v0, a0
    move v1, a1
    lw ra, 0(sp)
    addiu sp, sp, 4
    jr ra
    nop


PrintSideMessage:
    # print SPIM \n 32 \n SNAKE
    addiu sp, sp, -4
    sw ra, 0(sp)

    li a2, BLUE
    li a1, 8
    li a0, 73  # x = 73
    lui a3, %hi(charcode_S)
    ori a3, a3, %lo(charcode_S)
    jal DrawFromBitMap
    nop

    addiu a0, a0, 6
    lui a3, %hi(charcode_P)
    ori a3, a3, %lo(charcode_P)
    jal DrawFromBitMap
    nop

    addiu a0, a0, 6
    lui a3, %hi(charcode_I)
    ori a3, a3, %lo(charcode_I)
    jal DrawFromBitMap
    nop

    addiu a0, a0, 6
    lui a3, %hi(charcode_M)
    ori a3, a3, %lo(charcode_M)
    jal DrawFromBitMap
    nop

    addiu a1, a1, 9
    li a0, 79
    lui a3, %hi(charcode_2)
    ori a3, a3, %lo(charcode_2)
    jal DrawFromBitMap
    nop

    addiu a0, a0, 6
    lui a3, %hi(charcode_3)
    ori a3, a3, %lo(charcode_3)
    jal DrawFromBitMap
    nop

    addiu a1, a1, 16
    li a0, 70
    li a2, GREEN
    lui a3, %hi(charcode_S)
    ori a3, a3, %lo(charcode_S)
    jal DrawFromBitMap
    nop

    addiu a0, a0, 6
    lui a3, %hi(charcode_N)
    ori a3, a3, %lo(charcode_N)
    jal DrawFromBitMap
    nop

    addiu a0, a0, 6
    lui a3, %hi(charcode_A)
    ori a3, a3, %lo(charcode_A)
    jal DrawFromBitMap
    nop

    addiu a0, a0, 6
    lui a3, %hi(charcode_K)
    ori a3, a3, %lo(charcode_K)
    jal DrawFromBitMap
    nop

    addiu a0, a0, 6
    lui a3, %hi(charcode_E)
    ori a3, a3, %lo(charcode_E)
    jal DrawFromBitMap
    nop

    lw ra, 0(sp)
    addiu sp, sp, 4
    jr ra
    nop

FillBorder:
    addiu sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)

    move s0, zero  # x
    move s1, zero  # y
    li a2, BORDERGREEN
    li a3, WALL

_LFillTopBar:
    move a0, s0
    move a1, s1
    jal UpdateAndRenderTile
    addiu s0, s0, 1
    li t0, 32
    bne s0, t0, _LFillTopBar
    nop

    move s0, zero
    li s1, 1

_LFillSideBar:
    move a0, s0
    move a1, s1
    jal UpdateAndRenderTile
    nop

    addiu a0, a0, 31
    jal UpdateAndRenderTile

    addiu s1, s1, 1
    li t0, 32
    bne s1, t0, _LFillSideBar
    nop

    li s0, 1
    li s1, 31

_LFillBottomBar:
    move a0, s0
    move a1, s1
    jal UpdateAndRenderTile
    addiu s0, s0, 1
    li t0, 31
    bne s0, t0, _LFillBottomBar
    nop

    move s0, zero
    li s1, 1

    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addiu sp, sp, 12
    jr ra
    nop


FillBackGround:
    addiu sp, sp, -4
    sw ra, 0(sp)
    li a2, DARKGREEN
    li a1, Y_START
_FillOuter:
    li a0, X_START
_FillInner:
    jal DrawSnakeTile
    nop
    addiu a0, a0, 2
    li t0, X_END
    bne a0, t0, _FillInner
    nop
    addiu a1, a1, 2
    li t0, Y_END
    bne a1, t0, _FillOuter
    nop
    move t0, gp
    addiu t1, gp, 1024
_InitMem:
    sw zero, 0(t0)
    addiu t0, t0, 4
    bne t0, t1, _InitMem
    nop

    lw ra, 0(sp)
    addiu sp, sp, 4
    jr ra
    nop

/**
Draw tiles that is even larger (16x16)
2x2 equivalently on a predefined 100x75 coordinate system
**/

DrawSnakeTile:
    # a0: x, a1: y, a2: color
    addiu sp, sp, -4
    sw ra, 0(sp)

    jal DrawTile
    nop

    addiu a0, a0, 1
    jal DrawTile
    nop

    addiu a1, a1, 1
    jal DrawTile
    nop

    addiu a0, a0, -1
    jal DrawTile
    nop

    addiu a1, a1, -1

    lw ra, 0(sp)
    addiu sp, sp, 4
    jr ra
    nop

Sleep:
    #  A pseudo sleep function
    # a0: how many ms to sleep ?
    li t0, 15000
    multu a0, t0
    mflo t0
_LSleep:
    addiu t0, t0, -1
    bnez t0, _LSleep
    nop
    jr ra
    nop