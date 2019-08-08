	.segment "ROUTINES"

;//////////////////   J U M P   T A B L E   R O U T I N E S   \\\\\\\\\\\\\\\\\

.if 0 ; NOTYET
setbnk	sta ba         ;set up ba variable & filename bank
	stx fnbank
	rts

;  look up secondary address:
;
;       enter with sa sought in y.  routine looks for match in tables.
;       exits with .c=1 if not found, else .c=0 & .a=la, .x=fa, .y=sa

lkupsa
	tya
	ldx ldtnd       ;get lat, fat, sat table index

:       dex
	bmi lkupng      ;...branch if end of table (not found)
	cmp sat,x
	bne :-          ;...keep looking

lkupok	jsr getlfs      ;set up la, fa, sa   (** lkupla enters here **)
	tax
	lda la
	ldy sa
	clc             ;flag 'we found it'
	rts

lkupng	sec             ;flag 'not found'
	rts

;  look up logical file address:
;
;       enter with la sought in a.  routine looks for match in tables.
;       exits with .c=1 if not found, else .c=0 & .a=la, .x=fa, .y=sa

lkupla
	tax
	jsr lookup      ;search lat table
	beq lkupok      ;...branch if found
	bne lkupng      ;else return with .c=1
.endif


; \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
indfet
	sta fetvec      ; LDA (fetvec),Y  utility
	jmp fetch


;/////////////////////   K E R N A L   R A M   C O D E  \\\\\\\\\\\\\\\\\\\\\\\

.segment "KERNRAM"

;  FETCH  ram code      ( LDA (fetch_vector),Y  from any bank )
;
;  enter with 'fetvec' pointing to indirect adr & .y= index
;             .x= memory configuration
;
;  exits with .a= data byte & status flags valid
;             .x altered

dl_beg

fetch	lda d1pra       ;save current config (RAM)
	pha
	lda d1prb       ;save current config (ROM)
	pha
	txa
	sta d1pra       ;set RAM bank
	and #$07
	sta d1prb       ;set ROM bank
fetvec	=*=1
	lda ($ff),y     ;get the byte ($ff here is a dummy address, 'FETVEC')
	tax
	pla
	sta d1prb       ;restore previous memory configuration
	pla
	sta d1pra
	txa
	rts



;  STASH  ram code      ( STA (stash_vector),Y  to any bank )
;
;  enter with 'stavec' pointing to indirect adr & .y= index
;             .a= data byte to store
;             .x= memory configuration (writes to rom bleed thru to ram)
;
;  exits with .x & status altered

stash	pha
	lda d1pra       ;save current config (RAM)
	pha
	txa
	sta d1pra       ;set RAM bank
	and #$07
	ldx d1prb       ;save current config (ROM)
	sta d1prb       ;set ROM bank
	pla
stavec	=*=1
	sta ($ff),y     ;put the byte ($ff here is a dummy address, 'STAVEC')
	stx d1prb       ;restore previous memory configuration
	pla
	sta d1pra
	rts



;  CMPARE  ram code      ( CMP (cmpare_vector),Y  to any bank )
;
;  enter with 'cmpvec' pointing to indirect adr & .y= index
;             .a= data byte to compare to memory
;             .x= memory configuration
;
;  exits with .a= data byte & status flags valid, .x is altered

cmpare	pha
	lda d1pra       ;save current config (RAM)
	pha
	txa
	sta d1pra       ;set RAM bank
	and #$07
	ldx d1prb       ;save current config (ROM)
	sta d1prb       ;set ROM bank
	pla
cmpvec	=*=1
	cmp ($ff),y     ;compare bytes ($ff here is a dummy address, 'CMPVEC')
	php
	stx d1prb       ;restore previous memory configuration
	pla
	tax
	pla
	sta d1pra
	txa
	pha
	plp
	rts
s
.if 0 ; NOTYET
; LONG CALL  utility
;

	jsr jmpfar      ;execute jmp_long routine as a subroutine
	sta a_reg
	stx x_reg
	sty y_reg
	php
	pla
	sta s_reg
	tsx
	stx stkptr
	lda #sysbnk
	sta mmucr
	rts



; LONG JUMP utility
;

	ldx #0
:       lda pc_hi,x     ;put address & status on stack
	pha
	inx
	cpx #3
	bcc :-
	ldx bank
	jsr get_cfg     ;convert 'bank' to mmu data     ??????????? rom routine ??????????
	sta mmucr       ;set up memory configuration
	lda a_reg
	ldx x_reg       ;set up registers
	ldy y_reg
	rti             ;goto it
.endif
dl_end

; \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;     *** print immediate ***
;  a jsr to this routine is followed by an immediate ascii string,
;  terminated by a $00. the immediate string must not be longer
;  than 255 characters including the terminator.

primm
	pha             ;save registers
	txa
	pha
	tya
	pha
	ldy #0

@1      tsx             ;increment return address on stack
	inc $104,x      ;and make imparm = return address
	bne @2
	inc $105,x
@2      lda $104,x
	sta imparm
	lda $105,x
	sta imparm+1

	lda (imparm),y  ;fetch character to print (*** always system bank ***)
	beq @3          ;null= eol
	jsr bsout       ;print the character
	bcc @1

@3      pla             ;restore registers
	tay
	pla
	tax
	pla
	rts             ;return