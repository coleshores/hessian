        ; Add a 8-bit value to a 16-bit value
        ;
        ; Parameters: A value to be added, X zeropage base
        ; Returns: zeropage result
        ; Modifies: A

Add8:           clc
                adc $00,x
                sta $00,x
                bcc Add8_Skip
                inc $01,x
Add8_Skip:      rts

        ; Add two 16-bit values
        ;
        ; Parameters: X destination zeropage base, Y source zeropage base
        ; Returns: zeropage result
        ; Modifies: A

Add16:          lda $00,x
                clc
                adc $00,y
                sta $00,x
                lda $01,x
                adc $01,y
                sta $01,x
                rts

        ; Subtract a 8-bit value from a 16-bit value
        ;
        ; Parameters: A value to be subtracted, X zeropage base
        ; Returns: zeropage result
        ; Modifies: A

Sub8:           sta Sub8_Value+1
                lda $00,x
                sec
Sub8_Value:     sbc #$00
                sta $00,x
                bcs Sub8_Skip
                dec $01,x
Sub8_Skip:      rts

        ; Subtract two 16-bit value
        ;
        ; Parameters: X destination zeropage base, Y source zeropage base
        ; Returns: zeropage result
        ; Modifies: A

Sub16:          lda $00,x
                sec
                sbc $00,y
                sta $00,x
                lda $01,x
                sbc $01,y
                sta $01,x
                rts

        ; Multiply two unsigned 8-bit values
        ;
        ; Parameters: A,Y values to be multiplied, X destination zeropage base
        ; Returns: zeropage 16-bit result, A highbyte of result
        ; Modifies: A,Y

MulU:           sta $00,x
                tya
                beq MulU_Zero
                dey
                sty $01,x
                ldy #$07
                lda #$00
                lsr $00,x
                bcc MulU_Shift1
                adc $01,x
MulU_Shift1:    ror
                ror $00,x
                bcc MulU_Shift2
                adc $01,x
MulU_Shift2:    dey
                bne MulU_Shift1
                ror
                sta $01,x
                ror $00,x
                rts
MulU_Zero:      sta $00,x
                sta $01,x
                rts

        ; Divide two unsigned 8-bit values
        ;
        ; Parameters: A value to be divided, Y divider, X destination zeropage base
        ; Returns: zeropage result, A remainder
        ; Modifies: A,X,Y

DivU:           sta $00,x
                tya
                sta $01,x
                lda #$00
                asl $00,x
                ldy #$07
DivU_Loop:      rol
                cmp $01,x
                bcc DivU_Skip
                sbc $01,x
DivU_Skip:      rol $00,x
                dey
                bpl DivU_Loop
                rts

        ; Negate a 8-bit value
        ;
        ; Parameters: A value to be negated
        ; Returns: A result
        ; Modifies: A

Negate8:        clc
Negate8NoCarry: eor #$ff
                adc #$01
                rts

        ; Arithmetic shift right a 8-bit value
        ;
        ; Parameters: A value to be negated
        ; Returns: A result
        ; Modifies: A

Asr8:           lsr
                cmp #$40
                bcc Asr8_Pos
                ora #$80
Asr8_Pos:       rts

        ; Negate a 16-bit value
        ;
        ; Parameters: X zeropage base
        ; Returns: zeropage result
        ; Modifies: A

Negate16:       lda $00,x
                clc
                eor #$ff
                adc #$01
                sta $00,x
                lda $01,x
                eor #$ff
                adc #$00
                sta $01,x
                rts
