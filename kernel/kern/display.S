#include <regdef.h>
#include <mipsregs.h>
#include <unistd.h>
#include <shell.h>
    .set noreorder
    .set noat
    .global DrawTile
    .global DrawFromBitMap
    .global ClearScreen
    .global ClearBitMap
    .global charcode_A
    .global charcode_C
    .global charcode_E
    .global charcode_K
    .global charcode_I
    .global charcode_M
    .global charcode_N
    .global charcode_O
    .global charcode_P
    .global charcode_R
    .global charcode_S
    .global charcode_e
    .global charcode_i
    .global charcode_o
    .global charcode_p
    .global charcode_q
    .global charcode_r
    .global charcode_s
    .global charcode_t
    .global charcode_x
    .global charcode_y
    .global charcode_0
    .global charcode_1
    .global charcode_2
    .global charcode_3
    .global charcode_4
    .global charcode_5
    .global charcode_6
    .global charcode_7
    .global charcode_8
    .global charcode_9
    .global charcode_exclaim
    .global charcode_arrow_up
    .global charcode_arrow_down
    .section .text.display
    .p2align 2

/**
    Draw 8x8 tiles on screen
**/

ClearScreen:
    lui t0, %hi(GRAMBASE)
    li t1, 800*600
    addu t1, t1, t0
_LClearScreen:
    sb zero, 0(t0)
    addiu t0, t0, 1
    bne t0, t1, _LClearScreen
    nop
    jr ra
    nop

DrawTile:
    # draw a 8x8 tile
    # a0: tile_x, a1: tile_y, a2: color
    lui t0, %hi(GRAMBASE)
    sll t1, a0, 3   # actual pixel x
    sll t2, a1, 3   # actual pixel y
    addu t0, t0, t1  # BASE + x + 800y
    ori t1, zero, 800
    multu t2, t1
    mflo t2
    addu t0, t0, t2
    ori t1, zero, 8
_LDrawTile:
    sb a2, 0(t0)
    sb a2, 1(t0)
    sb a2, 2(t0)
    sb a2, 3(t0)
    sb a2, 4(t0)
    sb a2, 5(t0)
    sb a2, 6(t0)
    sb a2, 7(t0)
    addiu t1, t1, -1
    addiu t0, t0, 800 # next row
    bnez t1, _LDrawTile
    nop
    jr ra
    nop

/**
    Helper functions to draw characters from predefined bitmap
**/

ClearBitMap:
    # clear bitmap
    # a0 - x, a1 - y
    addiu sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    move s0, a0
    move s1, a1

    move a2, zero # black

_LClearBitMap:
    move a0, s0
    jal DrawTile
    nop

    addiu a0, a0, 1
    jal DrawTile
    nop

    addiu a0, a0, 1
    jal DrawTile
    nop

    addiu a0, a0, 1
    jal DrawTile
    nop

    addiu a0, a0, 1
    jal DrawTile
    nop

    addiu a1, 1
    addiu t0, s1, 7
    bne a1, t0, _LClearBitMap
    nop

    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addiu sp, sp, 12
    jr ra
    nop

DrawFromBitMap:
    # load bitmap from stack
    # print 5 x 7 bitmap
    # a0 - x, a1 - y, a2 - color, a3 - bitmap addr
    addiu sp, sp, -36
    sw ra, 32(sp)
    sw s0, 28(sp)
    sw s1, 24(sp)
    sw s2, 20(sp)
    sw s3, 16(sp)
    sw s4, 12(sp)
    sw s5, 8(sp)
    sw s6, 4(sp)
    sw s7, 0(sp)
    
    move s0, a0  # backup x
    move s1, a1  # backup y
    move s2, zero  # i
    move s4, a3  # ptr
    ori s6, zero, 5
    ori s7, zero, 7
_LDrawFromBitmapOuter:
    move s3, zero  # j = 0
_LDrawFromBitmapInner:
    lb s5, 0(s4)
    addiu s5, s5, -48  # - '0'
    beq s5, zero, _LDDrawL1 # ignore if '0'
    addu a0, s0, s3    # x + j
    addu a1, s1, s2    # y + i
    jal DrawTile
_LDDrawL1:
    addiu s3, s3, 1
    addiu s4, s4, 1 # ++addr
    bne s3, s6, _LDrawFromBitmapInner  # ++j < 5 ?
    nop
    addiu s2, s2, 1
    bne s2, s7, _LDrawFromBitmapOuter # ++i < 7 ?
    nop
    or a0, zero, s0 # restore a0
    or a1, zero, s1 # restore a1
    # restore callee saved
    
    lw ra, 32(sp)
    lw s0, 28(sp)
    lw s1, 24(sp)
    lw s2, 20(sp)
    lw s3, 16(sp)
    lw s4, 12(sp)
    lw s5, 8(sp)
    lw s6, 4(sp)
    lw s7, 0(sp)
    addiu sp, sp, 36
    jr ra
    nop
charcode_A:
    .ascii "01110100011000110001111111000110001"
charcode_C:
    .ascii "01110100011000010000100001000101110"
charcode_E:
    .ascii "11111100001000011110100001000011111"
charcode_K:
    .ascii "10001100101010011000101001001010001"
charcode_I:
    .ascii "01110001000010000100001000010001110"
charcode_M:
    .ascii "10001110111010110101100011000110001"
charcode_N:
    .ascii "10001100011100110101100111000110001"
charcode_O:
    .ascii "01110100011000110001100011000101110"
charcode_P:
    .ascii "11110100011000111110100001000010000"
charcode_R:
    .ascii "11110100011000111110101001001010001"
charcode_S:
    .ascii "01111100001000001110000010000111110"
charcode_e:
    .ascii "00000000000111010001111111000001111"
charcode_i:
    .ascii "00000001000000000100001000010000100"
charcode_o:
    .ascii "00000000000111010001100011000101110"
charcode_p:
    .ascii "00000000001111010001111101000010000"
charcode_q:
    .ascii "00000000000111110001011110000100001"
charcode_r:
    .ascii "00000000001011011001100001000010000"
charcode_s:
    .ascii "00000000000111110000011100000111110"
charcode_t:
    .ascii "00100001001111100100001000010100010"
charcode_x:
    .ascii "00000000001000101010001000101010001"
charcode_y:
    .ascii "00000000001000101010001000010001000"
charcode_0:
    .ascii "01110100011001110101110011000101110"
charcode_1:
    .ascii "00100011000010000100001000010001110"
charcode_2:
    .ascii "01110100010000100010001000100011111"
charcode_3:
    .ascii "11111000100010000010000011000101110"
charcode_4:
    .ascii "00010001100101010010111110001000010"
charcode_5:
    .ascii "11111100001111000001000011000101110"
charcode_6:
    .ascii "00110010001000011110100011000101110"
charcode_7:
    .ascii "11111000010001000100010000100001000"
charcode_8:
    .ascii "01110100011000101110100011000101110"
charcode_9:
    .ascii "01110100011000101111000010001001100"
charcode_exclaim:
    .ascii "00100001000010000100000000000000100"
charcode_arrow_up:
    .ascii "00100011101010100100001000010000100"
charcode_arrow_down:
    .ascii "00100001000010000100101010111000100"