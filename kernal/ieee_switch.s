;----------------------------------------------------------------------
; IEEE Switch
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "banks.inc"

.import jsrfar

.import cbdos_secnd
.import cbdos_tksa
.import cbdos_acptr
.import cbdos_ciout
.import cbdos_untlk
.import cbdos_unlsn
.import cbdos_listn
.import cbdos_talk

.import serial_secnd
.import serial_tksa
.import serial_acptr
.import serial_ciout
.import serial_untlk
.import serial_unlsn
.import serial_listn
.import serial_talk

.export secnd
.export tksa
.export acptr
.export ciout
.export untlk
.export unlsn
.export listn
.export talk

.segment "KVAR"

cbdos_enabled:
	.res 1

.segment "IEEESWTCH"

secnd:
	bit cbdos_enabled
	bmi :+
	jmp serial_secnd
:	jsr jsrfar
	.word $c000 + 3 * 0
	.byte BANK_CBDOS
	rts

tksa:
	bit cbdos_enabled
	bmi :+
	jmp serial_tksa
:	jsr jsrfar
	.word $c000 + 3 * 1
	.byte BANK_CBDOS
	rts

acptr:
	bit cbdos_enabled
	bmi :+
	jmp serial_acptr
:	jsr jsrfar
	.word $c000 + 3 * 2
	.byte BANK_CBDOS
	rts

ciout:
	bit cbdos_enabled
	bmi :+
	jmp serial_ciout
:	jsr jsrfar
	.word $c000 + 3 * 3
	.byte BANK_CBDOS
	rts

untlk:
	bit cbdos_enabled
	bmi :+
	jmp serial_untlk
:	jsr jsrfar
	.word $c000 + 3 * 4
	.byte BANK_CBDOS
	rts

unlsn:
	bit cbdos_enabled
	bmi :+
	jmp serial_unlsn
:	jsr jsrfar
	.word $c000 + 3 * 5
	.byte BANK_CBDOS
	rts

listn:
	jsr cbdos_detect
	bit cbdos_enabled
	bmi :+
	jmp serial_listn
:	jsr jsrfar
	.word $c000 + 3 * 6
	.byte BANK_CBDOS
	rts

talk:
	jsr cbdos_detect
	bit cbdos_enabled
	bmi :+
	jmp serial_talk
:	jsr jsrfar
	.word $c000 + 3 * 7
	.byte BANK_CBDOS
	rts

.export cbdos_detect
cbdos_detect:
	pha
	phx
	phy

	php
	sei
	jsr jsrfar
	.word $c000 + 3 * 15
	.byte BANK_CBDOS

	lda 0
	jsr printhex8
	lda 1
	jsr printhex8
	lda 2
	jsr printhex8
	lda 3
	jsr printhex8
	lda 4
	jsr printhex8
	lda 5
	jsr printhex8
	lda 6
	jsr printhex8
	lda 7
	jsr printhex8
	jmp *

	


	beq @detected
	lda #0
	bra :+
@detected:
	lda #$80
:	sta cbdos_enabled
	plp
	ply
	plx
	pla
	rts

printhex8:
	pha
	lsr
	lsr
	lsr
	lsr
	jsr printhex4
	pla
	jsr printhex4
	lda #' '
	jmp $ffd2

printhex4:
	and #$0f
	cmp #$0a
	bcc :+
	adc #$66
:	eor #$30
	jmp $ffd2
