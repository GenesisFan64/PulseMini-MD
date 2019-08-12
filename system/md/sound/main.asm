; ====================================================================
; ----------------------------------------------------------------
; Sound
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init Sound
; 
; Uses:
; a0-a1,d0-d1
; --------------------------------------------------------

Sound_Init:
		move.w	#$0100,(z80_bus).l		; Stop Z80
		move.b	#1,(z80_reset).l		; Reset
.wait:
		btst	#0,(z80_bus).l			; Wait for it
		bne.s	.wait
		lea	(z80_cpu).l,a0
		move.w	#$1FFF,d0
		moveq	#0,d1
.cleanup:
		move.b	d1,(a0)+
		dbf	d0,.cleanup
		lea	(Z80_CODE).l,a0			; Send this code
		lea	(z80_cpu).l,a1
		move.w	#(Z80_CODE_END-Z80_CODE)-1,d0
.copy:
		move.b	(a0)+,(a1)+
		dbf	d0,.copy
		move.b	#1,(z80_reset).l		; Reset
		nop 
		nop 
		nop 
		move.w	#0,(z80_bus).l
		rts
		
; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Sound_SetTrack
; 
; Input:
; d0 | LONG - Track blocks (Z80 WORD) | Track pattern (Z80 WORD)
; d1 | LONG - Track instruments (Z80 WORD) | ROM bank 
; d2 | LONG - 00 | Start Block | Tempo bits | Ticks
; d3 | WORD - Slot
; --------------------------------------------------------

Sound_SetTrack:
		move.w	#$0100,(z80_bus).l
.wait:
		btst	#0,(z80_bus).l
		bne.s	.wait

		move.w	d3,d4
		add.w	d4,d4
		add.w	d4,d4
		movea.l	SndDrv_TrckBuffers(pc,d4.w),a4

		move.l	d0,d4
		move.b	d4,trck_ReqPatt(a4)
		lsr.l	#8,d4
		move.b	d4,trck_ReqPatt+1(a4)
		lsr.l	#8,d4
		move.b	d4,trck_ReqBlk(a4)
		lsr.l	#8,d4
		move.b	d4,trck_ReqBlk+1(a4)

		move.l	d1,d4
		swap	d4
		move.b	d4,trck_ReqIns(a4)
		lsr.w	#8,d4
		move.b	d4,trck_ReqIns+1(a4)
		swap	d4
		move.b	d4,trck_ReqSndBnk(a4)
		
		move.l	d2,d4	
		move.b	d4,trck_ReqTicks(a4)		; Ticks
		lsr.l	#8,d4
		move.b	d4,trck_ReqTempo(a4)		; Tempo
		lsr.l	#8,d4
		move.b	d4,trck_ReqCurrBlk(a4)		; Block start

		move.w	#1,d4
		move.b	d4,trck_ReqFlag(a4)		; Request $01, set and play song
		
		move.w	#0,(z80_bus).l
		rts

SndDrv_TrckBuffers:
		dc.l SndBuff_Track_1|Z80_CPU
		dc.l SndBuff_Track_2|Z80_CPU

; --------------------------------------------------------
; Sound_Stop
; 
; Input:
; d0 | WORD - Request Type
; d1 | WORD - Slot
; --------------------------------------------------------

Sound_StopTrack:
		move.w	#$0100,(z80_bus).l
.wait:
		btst	#0,(z80_bus).l
		bne.s	.wait

		move.w	d1,d4
		add.w	d4,d4
		add.w	d4,d4
		movea.l	SndDrv_TrckBuffers(pc,d4.w),a4
		move.w	d0,d4
		move.b	d4,trck_ReqFlag(a4)

		move.w	#0,(z80_bus).l
		rts

; ====================================================================
; ----------------------------------------------------------------
; Z80 Code
; 
; Maximum size: 2000h-stack
; ----------------------------------------------------------------

		align $100
Z80_CODE:
		cpu Z80				; [AS] Set to Z80
		phase 0				; [AS] Reset PC to zero, for this section
		
; ====================================================================
; Z80 goes here

		include "system/md/sound/z80.asm"
		
; ====================================================================

		cpu 68000
		padding off
		phase Z80_CODE+*
Z80_CODE_END:
		align 2

; ====================================================================
; ----------------------------------------------------------------
; Sound data goes here
; ----------------------------------------------------------------
