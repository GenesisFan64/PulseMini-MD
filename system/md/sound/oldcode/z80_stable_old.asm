; ====================================================================
; ----------------------------------------------------------------
; Z80 Code
; ----------------------------------------------------------------

MAX_CHNLS	equ	10			; Only first 10 are used

; --------------------------------------------------------
; Init
; --------------------------------------------------------

		di				; Disable interrputs
		im	1			; Interrput mode 1 (standard)
		ld	sp,2000h		; Set stack at the end of Z80, goes backwards
		jr	z80_init		; Jump to z80_init

; --------------------------------------------------------
; RST 0008h
; 
; Set ROM Bank
; ; a - 0xxx xxxx x0000 0000
; --------------------------------------------------------

		org 0008h
		push	hl
		ld	hl,zbank
		ld	(hl),a
		rrca
		ld	(hl),a
		rrca
		ld	(hl),a
		rrca
		ld	(hl),a
		rrca
		ld	(hl),a
		rrca
		ld	(hl),a
		rrca
		ld	(hl),a
		rrca
		ld	(hl),a
		xor	a
		ld	(hl),a
		pop	hl
		ret
		
; ----------------------------------------------------
; DAC Sample buffer
; ----------------------------------------------------

Sample_Flags	db 00000011b				; Request
Sample_Read	db 0					; Read
		dw (WavIns_SeaLove1&7FFFh)|8000h	
		db WavIns_SeaLove1>>15
Sample_Start	dw (WavIns_SeaLove1&7FFFh)|8000h		; Start
		db WavIns_SeaLove1>>15
Sample_End	dw (WavIns_SeaLove1_e&7FFFh)|8000h	; End
		db WavIns_SeaLove1_e>>15
Sample_Loop	dw (WavIns_SeaLove1&7FFFh)|8000h		; Loop
		db WavIns_SeaLove1>>15
Sample_Speed	dw 0100h				; update me with bit 1 on Sample_Flags

; --------------------------------------------------------

curr_Jsr	db 0C3h					; (moved here)
		dw 0
curr_SndBank	db 0					; Current ROM bank for pulsemini

; --------------------------------------------------------
; Z80 Interrupt at 0038h
; 
; VBlank only
; --------------------------------------------------------

		org 0038h			; align to 0038h
		jp	z80_int
		
; --------------------------------------------------------
; Z80 Init
; --------------------------------------------------------

z80_init:
		call	SndDrv_Init
		ei

; --------------------------------------------------------
; Sample playback LOOP
; --------------------------------------------------------

.loop:
		nop
		ld	a,(Sample_Flags)
		or	a
		jp	p,.request
		ld	a,2Ah
		ld	(zym_ctrl_1),a
		ld	hl,(Sample_Read+1)
		ld	a,(hl)
		add	hl,bc
		jp	c,.exit
		ld	(zym_data_1),a
		ld	hl,(Sample_Read)	; 0000XX.XX
		add 	hl,de
		ld	(Sample_Read),hl
		jp	nc,.loop
		ld	a,(Sample_Read+2)	; 00XX00.00
		inc 	a
		ld	(Sample_Read+2),a
		jp	m,.loop
		ld	a,(Sample_Read+3)	; XX8000.00
		inc	a
		ld	h,a
		ld	(Sample_Read+3),a
		rst	8
		ld	a,(Sample_Read+2)
		or	80h
		ld	(Sample_Read+2),a
		ld	bc,0
		ld	a,(Sample_End+2)
		cp	h
		jp	nz,.loop
		ld	hl,(Sample_End)
		ld	bc,(Sample_End)
		ccf
		sbc 	hl,bc
		ccf
		sbc 	hl,bc
		ld	b,h
		ld	c,l
		jr	.loop

; ------------------------------------------------
; WAV Exit
; ------------------------------------------------

.exit:
		ld	a,(Sample_Flags)
		res	7,a
		ld	(Sample_Flags),a
		bit 	6,a
		jp	z,.full_stop

		xor	a
		ld	(Sample_Read),a
		ld	hl,(Sample_Loop)
		ld	a,(Sample_Loop+2)
		ld	(Sample_Read+3),a
		ld	(Sample_Read+1),hl
		rst	8
		
		ld	a,(Sample_Flags)
		set	7,a
		ld	(Sample_Flags),a
		ld	bc,0
		ld	a,(Sample_Read+3)
		ld	h,a
		ld	a,(Sample_End+2)
		cp	h
		jp	nz,.loop
		ld	hl,(Sample_End)
		ld	bc,(Sample_End)
		ccf
		sbc 	hl,bc
		ccf
		sbc 	hl,bc
		ld	b,h
		ld	c,l
		jp	.loop

; ----------------------------------------

.full_stop:
		ld	a,2Bh
		ld	(zym_ctrl_1),a
		xor	a
		ld	(zym_data_1),a
		ld	(Sample_Flags),a
		
; ------------------------------------------------
; WAV Request
; ------------------------------------------------

.request:
		ld	a,(Sample_Flags)
		bit 	2,a
		jp	nz,.pitch
		bit	6,a
		jp	nz,.turn_off
		or	a
		jp	z,.request
		
; ----------------------------------------

.restart:
		ld	a,2Bh
		ld	(zym_ctrl_1),a
		ld	a,80h
		ld	(zym_data_1),a
		ld	bc,0
		ld	a,(Sample_Flags)
		or	10000000b
		bit 	1,a			; LOOP bit?
		jp	z,.nlpfl
		or	01000000b
.nlpfl:
		and 	11110000b
		ld	(Sample_Flags),a
		ld	de,(Sample_Speed)
		
		xor	a
		ld	(Sample_Read),a
		ld	hl,(Sample_Start)
		ld	a,(Sample_Start+2)
		ld	(Sample_Read+1),hl
		ld	(Sample_Read+3),a
		rst 	8

		ld	bc,0			; full size
		ld	a,(Sample_Start+2)
		ld	h,a
		ld	a,(Sample_End+2)
		cp	h
		jp	nz,.loop
		ld	hl,(Sample_End)
		ld	bc,(Sample_End)
		ccf
		sbc 	hl,bc
		ccf
		sbc 	hl,bc
		ld	b,h
		ld	c,l
		jp	.loop

; ----------------------------------------

.pitch:
		ld	de,(Sample_Speed)
		ld	a,(Sample_Flags)
		and	11111011b
		or	80h
		ld	(Sample_Flags),a
		jp	.loop

; ------------------------------------------------
; Stop WAV
; ------------------------------------------------

.turn_off:
		ld	a,2Bh
		ld	(zym_ctrl_1),a
		xor	a
		ld	(Sample_Flags),a
		ld	(zym_data_1),a
		jp	.loop
		
; ====================================================================
; ----------------------------------------------------------------
; FM/PSG track player
; 
; ticks: 150 + trck_tempo_bits*10
; speed: trck_speed - 1
; ----------------------------------------------------------------

z80_int:
		di
		push	af
		exx

; ------------------------------------
; Read tracks
; ------------------------------------

		ld	a,(curr_SndBank)		; Move ROM bank to music data
		rst 	8
		ld	iy,SndBuff_Track_1
		ld	ix,SndBuff_ChnlBuff_1
		call	SndDrv_ReadTrack
		ld	iy,SndBuff_Track_2
		ld	ix,SndBuff_ChnlBuff_2
		call	SndDrv_ReadTrack
 	
; ------------------------------
; Play channels
; ------------------------------

		ld	ix,SndBuff_ChnlBuff_1
		ld	iy,SndBuff_ChnlBuff_2
		call	.this_fm
		call	.this_fm
		call	.this_fm
		call	.this_fm
		call	.this_fm
		call	.this_fm
		call	.this_psg
		call	.this_psg
		call	.both_pnoise

; ------------------------------------
; Exit Vint
; ------------------------------------

		ld	a,(Sample_Read+3)		; Return ROM bank to sample
		rst 	8
		ld	d,2Ah				; Play last byte
		ld	hl,(Sample_Read+1)
		ld	e,(hl)
		call	SndDrv_FmSet_1

; ------------------------------------

.no_trcks:
		exx
		pop	af
		ei					; Re-enable interrupts before exiting
		ret					; Return

; ----------------------------------------------------
; FM normal channels
; ----------------------------------------------------

.this_fm:
		push	ix
		call	.srch_slot
		ld	a,(ix+chnl_Type)
		or	a
		jp	z,.fm_turnoff

; --------------------------------
; Update by request
; --------------------------------

		ld	a,(ix+chnl_Update)
		or	a
		jp	z,.exit_fm
		ld	(ix+chnl_Update),0

	; ------------------------------------
		ld	a,(ix+chnl_Type)
		bit	5,a			; Instrument
		jp	nz,.use_newinst
		and	0010b
		jp	z,.no_newinst
.use_newinst:
		call	.set_fm_ins
.no_newinst:

	; ------------------------------------
		ld	a,(ix+chnl_Type)
		bit	6,a			; Volume
		jp	nz,.use_newvol
		and	0100b
		jp	z,.no_newvol
.use_newvol:
		ld	b,(ix+chnl_Vol)
		ld	(ix+chnl_EfNewVol),b
		call	.set_fm_vol
.no_newvol:

	; ------------------------------------
		call	.run_effects

	; ------------------------------------
		ld	a,(ix+chnl_Type)
		bit	4,a			; Note
		jp	nz,.use_newnote
		and	0001b
		jp	z,.exit_fm
.use_newnote:
		ld	h,(ix+(chnl_Freq+1))	; Copy freq
		ld	l,(ix+chnl_Freq)
		ld	(ix+(chnl_EfNewFreq+1)),h
		ld	(ix+chnl_EfNewFreq),l
		ld	e,(ix+chnl_Chip)	; KEYS OFF
		ld	d,28h
		call	SndDrv_FmSet_1
		call	.set_fm_freq
		ld	e,(ix+chnl_FmRegKeys)	; KEYS ON
		ld	a,(ix+chnl_Chip)
		or	e
		ld	e,a
		ld	d,28h
		call	SndDrv_FmSet_1

.exit_fm:
		pop	ix
		ld	de,20h
		add 	ix,de
		add 	iy,de
		ret

; ------------------------------------
; Silence current FM
; 
; TL = 07Fh
; ------------------------------------

.fm_turnoff:
		ld	a,(ix+chnl_Chip)
; 		cp	6
; 		jp	nz,.not_dac
; 		ld	a,40h
; 		ld	(Sample_Flags),a
; .not_dac:
		ld	e,a
		ld	d,28h
		call	SndDrv_FmSet_1
		ld	a,e
		and	11b
		or	40h
		ld	e,7Fh
		ld	d,a
		call	SndDrv_FmAutoSet
		inc	d
		inc	d
		inc	d
		inc	d
		call	SndDrv_FmAutoSet
		inc	d
		inc	d
		inc	d
		inc	d
		call	SndDrv_FmAutoSet
		inc	d
		inc	d
		inc	d
		inc	d
		call	SndDrv_FmAutoSet
		jp	.exit_fm

; ------------------------------------
; FM normal registers
; ------------------------------------

.set_fm_ins:
		ld	e,(ix+chnl_Chip)
		ld	d,28h
		call	SndDrv_FmSet_1
		ld	h,(ix+(chnl_InsAddr+1))
		ld	l,(ix+chnl_InsAddr)
		ld	a,h
		or	l
		ret	z
		ld	a,e
		cp	6
		jp	nz,.no_chnl6
		ld	a,(ix+chnl_InsType)
		cp	2			; Type 2?
		jp	z,.set_sampl
		ld	a,40h
		ld	(Sample_Flags),a
.no_chnl6:
		ld	a,e
		and	11b
		or	30h
		ld	d,a
		ld	b,1Ch/4
.fmfiles:
		ld	e,(hl)
		inc 	hl
		call	SndDrv_FmAutoSet
		inc 	d
		inc 	d
		inc 	d
		inc 	d
		ld	e,(hl)
		inc 	hl
		call	SndDrv_FmAutoSet
		inc 	d
		inc 	d
		inc 	d
		inc 	d
		ld	e,(hl)
		inc 	hl
		call	SndDrv_FmAutoSet
		inc 	d
		inc 	d
		inc 	d
		inc 	d
		ld	e,(hl)
		inc 	hl
		call	SndDrv_FmAutoSet
		inc 	d
		inc 	d
		inc 	d
		inc 	d
		djnz	.fmfiles

		ld	d,0B0h
		ld	a,(ix+chnl_Chip)
		and	11b
		or	d
		ld	d,a
		ld	e,(hl)			; 0B0h
		ld	(ix+chnl_FmRegB0),e
		call	SndDrv_FmAutoSet
		inc 	hl
		ld	e,(hl)			; 0B4h
		ld	d,0B4h
		ld	a,(ix+chnl_Chip)
		and	11b
		or	d
		ld	d,a
		ld	a,(hl)
		ld	(ix+chnl_FmRegB4),a	
		or	(ix+chnl_FmPan)		; FM panning
		ld	e,a
		call	SndDrv_FmAutoSet
		inc 	hl
		ld	e,(hl)			; FM3 flag
		inc 	hl
		ld	a,(hl)			; 028h
		inc 	hl
		ld	(ix+chnl_FmRegKeys),a
		
		ld	a,(ix+chnl_Chip)
		cp	2			; Channel 3?
		ret	nz
		ld	e,0
		ld	a,(ix+chnl_InsType)
		cp	1			; Type 1?
		jp	nz,.set_fm3reg
		ld	d,0A6h			; OP1
		ld	e,(hl)
		call	SndDrv_FmAutoSet
		inc 	hl
		ld	d,0A2h
		ld	e,(hl)
		call	SndDrv_FmAutoSet
		inc 	hl
		ld	d,0ACh			; OP2
		ld	e,(hl)
		call	SndDrv_FmAutoSet
		inc 	hl
		ld	d,0A8h
		ld	e,(hl)
		call	SndDrv_FmAutoSet
		inc 	hl
		ld	d,0ADh			; OP3
		ld	e,(hl)
		call	SndDrv_FmAutoSet
		inc 	hl
		ld	d,0A9h
		ld	e,(hl)
		call	SndDrv_FmAutoSet
		inc 	hl
		ld	d,0AEh			; OP4
		ld	e,(hl)
		call	SndDrv_FmAutoSet
		inc 	hl
		ld	d,0AAh
		ld	e,(hl)
		call	SndDrv_FmAutoSet
		ld	e,(ix+chnl_FmRegKeys)	; KEYS ON
		ld	a,(ix+chnl_Chip)
		or	e
		ld	e,a
		ld	d,28h
		call	SndDrv_FmSet_1
		ld	e,40h
.set_fm3reg:
		ld	d,27h
		jp	SndDrv_FmSet_1
 
; ------------------------------------
; Set FM frequency
; 
; hl - frequency
; ------------------------------------

.set_fm_freq:
		ld	a,(ix+chnl_Chip)
		ld	e,(ix+chnl_InsType)
		cp	6			; Check channel 6
		jp	nz,.no_chnl6f
		ld	a,e
		cp	2
		jp	z,.play_sampl
.no_chnl6f:
		cp	2			; Check channel 3
		jp	nz,.no_chnl3f
		ld	a,e
		cp	1
		ret	z
.no_chnl3f:

		ld	e,a
		ld	a,(ix+chnl_Note)
		cp	-10
		jp	z,.set_keycut
		cp	-1
		ret	z
		cp	-2
		jp	nz,.no_keycut
.set_keycut:
		ld	a,e
		and	11b
		or	40h
		ld	e,7Fh
		ld	d,a
		call	SndDrv_FmAutoSet
		inc	d
		inc	d
		inc	d
		inc	d
		call	SndDrv_FmAutoSet
		inc	d
		inc	d
		inc	d
		inc	d
		call	SndDrv_FmAutoSet
		inc	d
		inc	d
		inc	d
		inc	d
		jp	SndDrv_FmAutoSet
.no_keycut:
		ld	a,e
		and	11b
		ld	b,a
		ld	a,0A4h
		or	b
		ld	d,a
		ld	e,h
		call	SndDrv_FmAutoSet
		dec 	d
		dec 	d
		dec	d
		dec 	d
		ld	e,l
		jp	SndDrv_FmAutoSet

; Sample mode
.play_sampl:
		ld	a,(ix+chnl_Note)
		ld	e,040h
		cp	-1
		jp	z,.set_smpflag
		cp	-2
		jp	z,.set_smpflag
		cp	-10
		jp	z,.set_smpflag
		ld	h,(ix+(chnl_InsAddr+1))
		ld	l,(ix+chnl_InsAddr)
		ld	a,h
		or	l
		ret	z
		ld	a,(ix+chnl_SmplFlags)
		rlca
		or	1
		ld	e,a
.set_smpflag:
		ld	a,e
		ld	(Sample_Flags),a
		ret

; ------------------------------------
; Set FM Volume
; ------------------------------------

.set_fm_vol:
		ld	a,(ix+chnl_Chip)
		ld	e,a
		cp	6
		jp	nz,.notdac
		ld	a,(ix+chnl_InsType)
		cp	2
		ret	z
.notdac:
		ld	h,(ix+(chnl_InsAddr+1))
		ld	l,(ix+chnl_InsAddr)
		ld	a,h
		or	l
		ret	z
		inc 	hl			; Skip 30h
		inc 	hl
		inc 	hl
		inc 	hl
		ld	a,b
		cp	40h
		jp	c,.too_much
		ld	a,40h
.too_much:
		or	a
		jp	p,.too_low
		xor	a
.too_low:

		sub 	a,40h
		cpl
		inc 	a
		ld	c,a
		ld	d,40h			; 40h
		ld	a,(ix+chnl_Chip)
		and	11b
		or	d
		ld	d,a
		ld	a,(ix+chnl_FmRegB0)
		and	111b
		ld	b,a
		cp	7
		jp	nz,.tl_lv1
		ld	a,(hl)
		add 	a,c
		or	a
		jp	p,.tl_lv1_tm
		ld	a,7Fh
.tl_lv1_tm:
		ld	e,a
		call	SndDrv_FmAutoSet
.tl_lv1:
		inc 	hl
		inc 	d
		inc 	d
		inc 	d
		inc 	d
		ld	a,b
		cp	7
		jp	z,.tl_lv2_ok
		cp	6
		jp	z,.tl_lv2_ok
		cp	5
		jp	nz,.tl_lv2
.tl_lv2_ok:
		ld	a,(hl)
		add 	a,c
		or	a
		jp	p,.tl_lv2_tm
		ld	a,7Fh
.tl_lv2_tm:
		ld	e,a
		call	SndDrv_FmAutoSet
.tl_lv2:
		inc 	hl
		inc 	d
		inc 	d
		inc 	d
		inc 	d
		ld	a,b
		and	100b
		or	a
		jp	z,.tl_lv3
		ld	a,(hl)
		add 	a,c
		or	a
		jp	p,.tl_lv3_tm
		ld	a,7Fh
.tl_lv3_tm:
		ld	e,a
		call	SndDrv_FmAutoSet
.tl_lv3:
		inc 	hl
		inc 	d
		inc 	d
		inc 	d
		inc 	d
		ld	a,(hl)
		add 	a,c
		or	a
		jp	p,.tl_lv4_tm
		ld	a,7Fh
.tl_lv4_tm:
		ld	e,a
		inc 	hl
		jp	SndDrv_FmAutoSet

.set_sampl:
		ld	h,(ix+(chnl_InsAddr+1))
		ld	l,(ix+chnl_InsAddr)

		ld	e,(hl)
		inc 	hl
		ld	d,(hl)
		inc 	hl
		ld	a,(hl)
		inc 	hl
		ld	(Sample_Start),de
		ld	(Sample_Start+2),a

		ld	e,(hl)
		inc 	hl
		ld	d,(hl)
		inc 	hl
		ld	a,(hl)
		inc 	hl
		ld	(Sample_End),de
		ld	(Sample_End+2),a
		
		ld	e,(hl)
		inc 	hl
		ld	d,(hl)
		inc 	hl
		ld	a,(hl)
		inc 	hl
		ld	(Sample_Loop),de
		ld	(Sample_Loop+2),a
		
		ld	a,(hl)
		ld	(ix+chnl_SmplFlags),a
		ret
		
; ----------------------------------------------------
; PSG1, PSG2 (and PSG3 from both_pnoise)
; ----------------------------------------------------

.this_psg:
		push	ix
		call	.srch_slot

		ld	a,(ix+chnl_Chip)
		or	1Fh
		ld	e,a
		ld	a,(ix+chnl_Type)
		or	a
		jp	z,.set_vol
		ld	a,(ix+chnl_Note)
		cp	-1
		jp	z,.set_vol
		cp	-2
		jp	z,.set_vol
		
; --------------------------------
; Update by request
; --------------------------------

		ld	a,(ix+chnl_Update)
		or	a
		jp	z,.psgupd_once
		ld	(ix+chnl_Update),0
		
	; ------------------------------------
		ld	a,(ix+chnl_Type)
		bit	6,a			; Volume
		jp	nz,.use_pnewvol
		and	0100b
		jp	z,.no_pnewvol
.use_pnewvol:
		ld	a,(ix+chnl_Vol)
		ld	(ix+chnl_EfNewVol),a
		call	.set_psg_vol
.no_pnewvol:

	; ------------------------------------
		ld	a,(ix+chnl_Type)
		bit 	4,a
		jp	nz,.new_pfreq
		and	0001b
		jp	z,.no_pfreq
.new_pfreq:
		ld	h,(ix+(chnl_Freq+1))		; Copy freq
		ld	l,(ix+chnl_Freq)
		ld	(ix+(chnl_EfNewFreq+1)),h
		ld	(ix+chnl_EfNewFreq),l
		call	.set_psg_freq
.no_pfreq:

	; ------------------------------------
		call	.run_effects

.psgupd_once:

; --------------------------------
; Update always
; --------------------------------

		ld	a,(ix+chnl_Chip)
		or	1Fh
		ld	e,a
		ld	h,(ix+(chnl_InsAddr+1))
		ld	l,(ix+chnl_InsAddr)
		ld	a,h
		or	l
		jp	z,.set_vol
		ld	e,(ix+chnl_PsgVolBase)	; Set volume
		ld	bc,0
		ld	c,(ix+chnl_PsgIndx)
		add 	hl,bc
		ld	a,(hl)
		cp	-1
		jp	z,.last_env
		ld	(ix+chnl_PsgVolEnv),a
		inc 	(ix+chnl_PsgIndx)
.last_env:
		ld	a,(ix+chnl_PsgVolEnv)
		add 	a,e
		ld	e,a
		and	11110000b
		jp	z,.no_max
		ld	e,00001111b
.no_max:
		ld	a,e
		or	00010000b
		or	(ix+chnl_Chip)
		ld	e,a
.set_vol:
		ld	a,e
		ld	(zpsg_ctrl),a
		
.nxt_psg:
		pop	ix
		ld	de,20h
		add 	ix,de
		add 	iy,de
		ret

; ----------------------------------------------------
; PSG 3+PSG NOISE
; 
; Reads 2 channels
; ----------------------------------------------------

.both_pnoise:
		push	ix
		push	iy
		ld	de,20h			; Go to NOISE channel
		add 	ix,de
		add 	iy,de
		call	.srch_slot

		ld	a,(ix+chnl_Chip)
		ld	b,a
		or	1Fh
		ld	e,a
		ld	a,(ix+chnl_Type)
		or	a
		jp	z,.set_nvol
		ld	a,(ix+chnl_Note)
		cp	-1
		jp	z,.set_nvol
		cp	-2
		jp	z,.set_nvol

; --------------------------------
; Update by request
; --------------------------------

		ld	a,(ix+chnl_Update)
		or	a
		jp	z,.psgupdn_once
		ld	(ix+chnl_Update),0

	; ------------------------------------
		ld	a,(ix+chnl_Type)
		bit	5,a			; Instrument
		jp	nz,.use_noiseins
		and	0010b
		jp	z,.no_noiseins
.use_noiseins:
		ld	a,(ix+chnl_InsType)	; Set new noise type
		ld	(zpsg_ctrl),a
		
.no_noiseins:
		
	; ------------------------------------
		ld	a,(ix+chnl_Type)
		bit	6,a			; Volume
		jp	nz,.use_pnewvols
		and	0100b
		jp	z,.no_pnewvols
.use_pnewvols:
		ld	a,(ix+chnl_Vol)
		ld	(ix+chnl_EfNewVol),a
		call	.set_psg_vol
.no_pnewvols:

	; ------------------------------------
		call	.run_effects

.psgupdn_once:

; --------------------------------
; Update always
; --------------------------------

		ld	a,(ix+chnl_Type)	; Set frequency
		bit 	4,a
		jp	nz,.new_nfreq
		and	0001b
		jp	z,.no_nfreq
.new_nfreq:
		ld	h,(ix+(chnl_Freq+1))		; Copy freq
		ld	l,(ix+chnl_Freq)
		ld	(ix+(chnl_EfNewFreq+1)),h
		ld	(ix+chnl_EfNewFreq),l
		call	.set_psg_freq
.no_nfreq:

		ld	a,(ix+chnl_Chip)
		or	1Fh
		ld	e,a
		ld	h,(ix+(chnl_InsAddr+1))
		ld	l,(ix+chnl_InsAddr)
		ld	a,h
		or	l
		jp	z,.set_nvol
		ld	e,(ix+chnl_PsgVolBase)	; Set volume
		ld	bc,0
		ld	c,(ix+chnl_PsgIndx)
		add 	hl,bc
		ld	a,(hl)
		cp	-1
		jp	z,.last_nenv
		ld	(ix+chnl_PsgVolEnv),a
		inc 	(ix+chnl_PsgIndx)
.last_nenv:
		ld	a,(ix+chnl_PsgVolEnv)
		add 	a,e
		ld	e,a
		and	11110000b
		jp	z,.no_nmax
		ld	e,00001111b
.no_nmax:
		ld	a,e
		or	00010000b
		or	(ix+chnl_Chip)
		ld	e,a
.set_nvol:
		ld	a,e
		ld	(zpsg_ctrl),a

.nxt_npsg:
		ld	a,(ix+chnl_InsType)
		pop	iy
		pop	ix			; Return to PSG 3
		and	11b
		cp	3
		jp	nz,.this_psg
		ld	a,0DFh
		ld	(zpsg_ctrl),a
		ret

; --------------------------------------------

.srch_slot:
		ld	a,(ix+chnl_Type)
		or	a
		jp	nz,.no_incrslot
		push	iy
		pop	ix
.no_incrslot:
		ret
	
; --------------------------------------------
; Set PSG Volume
; --------------------------------------------

.set_psg_vol:
		ld	e,0
		cp	40h
		jp	c,.pntoo_much
		ld	a,40h
.pntoo_much:
		or	a
		jp	p,.pntoo_low
		xor	a
.pntoo_low:
		cp	40h
		jp	z,.pntoppsgv
		dec 	a
		rrca
		rrca
		cpl
		and	00001111b
		ld	e,a
.pntoppsgv:
		ld	(ix+chnl_PsgVolBase),e
		ret

; --------------------------------------------
; Set PSG Frequency
; 
; hl - frequency
; --------------------------------------------

.set_psg_freq:
		ld	a,(ix+chnl_Chip)
		and	11100000b
		ld	b,a
		cp	0E0h
		jp	nz,.not_nse
		ld	a,(ix+chnl_InsType)
		and	011b
		cp	3
		ret	nz
		ld	b,0C0h
.not_nse:
		ld	a,h
		or	l
		ret	z
		
		ld	a,l
		ld	d,a
		and 	00001111b
		or	b
		ld	e,a
		ld	a,l
		rrca
		rrca
		rrca
		rrca
		and	00001111b
		ld	d,a
		ld	a,h
		rrca
		rrca
		rrca
		rrca
		and	00110000b
		or	d
		ld	d,a
		
		ld	a,e
		ld	(zpsg_ctrl),a
		ld	a,d
		ld	(zpsg_ctrl),a
		ret

; --------------------------------
; Effect actions
; 
; effects are shared
; with both FM and PSG
; --------------------------------

.run_effects:
		ld	a,(ix+chnl_Type)	; Effect
		bit	7,a
		jp	nz,.has_neweff
		and	1000b
		ret	z
.has_neweff:
		ld	de,0
		ld	a,(ix+chnl_EffId)
		add 	a,a
		and	11111110b
		ld	e,a
		ld	hl,.list_doeff
		add	hl,de
		ld	b,(ix+chnl_Chip)
		ld	c,(ix+chnl_EffArg)
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a
		jp	(hl)
.list_doeff:
		dw .eff_null
		dw .eff_null	; A | Set ticks
		dw .eff_null	; B | Jump to block
		dw .eff_null	; C | Break to row (not possible here)
		dw .set_D	; D | Volume slide
		dw .set_E_F	; E
		dw .set_E_F	; F
		dw .eff_null	; G
		dw .eff_null	; H
		dw .eff_null	; I
		dw .eff_null	; J	
		dw .eff_null	; K
		dw .eff_null	; L
		dw .eff_null	; M
		dw .eff_null	; N
		dw .eff_null	; O
		dw .eff_null	; P
		dw .eff_null	; Q
		dw .eff_null	; R
		dw .eff_null	; S
		dw .eff_null	; T
		dw .eff_null	; U
		dw .eff_null	; V
		dw .eff_null	; W
		dw .set_X	; X
		dw .eff_null	; Y
		dw .eff_null	; Z

; ------------------------------------

.eff_null:
		ret

; ------------------------------------
; Effect D - Volume slide
; ------------------------------------

.set_D:
		ld	a,(ix+chnl_EfNewVol)
		add 	a,(ix+chnl_EfVolSlide)
		ld	(ix+chnl_EfNewVol),a
		bit	7,b
		jp	nz,.setpsg_vol
		ld	b,(ix+chnl_EfNewVol)
		jp	.set_fm_vol
.setpsg_vol:
		ld	a,(ix+chnl_EfNewVol)
		jp	.set_psg_vol

; ------------------------------------
; Effect E - Portametro down
; ------------------------------------

.set_E_F:
		bit	7,(ix+chnl_Chip)
		jp	nz,.psg_EF
		
		ld	d,(ix+(chnl_EfPortam+1))
		ld	e,(ix+chnl_EfPortam)
		ld	h,(ix+(chnl_EfNewFreq+1))
		ld	l,(ix+chnl_EfNewFreq)
		add 	hl,de
		ld	(ix+(chnl_EfNewFreq+1)),h
		ld	(ix+chnl_EfNewFreq),l
		jp	.set_fm_freq

.psg_EF:
		ld	d,(ix+(chnl_EfPortam+1))
		ld	e,(ix+chnl_EfPortam)
		ld	h,(ix+(chnl_EfNewFreq+1))
		ld	l,(ix+chnl_EfNewFreq)
		scf
		sbc 	hl,de
		jp	p,.toolow
		ld	hl,0
.toolow:
		ld	(ix+(chnl_EfNewFreq+1)),h
		ld	(ix+chnl_EfNewFreq),l
		jp	.set_psg_freq
		
; ------------------------------------
; Effect X - Set panning (FM ONLY)
; ------------------------------------

.set_X:
		ld	d,0B4h
		ld	a,(ix+chnl_Chip)
		and	11b
		or	d
		ld	d,a
		ld	a,(ix+chnl_FmRegB4)
		or	(ix+chnl_FmPan)
		ld	e,a
		jp	SndDrv_FmAutoSet

; ===================================================================
; ------------------------------------
; Init driver
; ------------------------------------

SndDrv_Init:
		ld	de,220Bh		; LFO 03h
		call	SndDrv_FmSet_1
		ld	de,2700h
		call	SndDrv_FmSet_1
		ld	de,2800h
		call	SndDrv_FmSet_1
		ld	de,2801h
		call	SndDrv_FmSet_1
		ld	de,2802h
		call	SndDrv_FmSet_1
		ld	de,2804h
		call	SndDrv_FmSet_1
		ld	de,2805h
		call	SndDrv_FmSet_1
		ld	de,2806h
		call	SndDrv_FmSet_1
		ld	de,2B00h
		call	SndDrv_FmSet_1
		ld	a,09Fh
		ld	(Zpsg_ctrl),a
		ld	a,0BFh
		ld	(Zpsg_ctrl),a		
		ld	a,0DFh
		ld	(Zpsg_ctrl),a	
		ld	a,0FFh
		ld	(Zpsg_ctrl),a
		ret

; ===================================================================
; ------------------------------------
; Read track
; 
; iy - Pattern buffer
; ix - Channel list
; ------------------------------------

SndDrv_ReadTrack:
		ld	a,(iy+trck_ReqFlag)
		or	a
		call	nz,SndDrv_ReqTrack

		ld	a,(iy+trck_Flags)
		or	a
		ret	z
		ld	a,(iy+trck_TempoBits)
		rrca
		ld	(iy+trck_TempoBits),a
		jp	c,.force_on
		dec 	(iy+trck_TicksRead)
		ret	p
		ld	a,(iy+trck_TicksCurr)		; save Ticks
		ld	(iy+trck_TicksRead),a
.force_on:
		dec	(iy+trck_RowWait)		; row countdown
		jp	p,.row_countdwn
		ld	(iy+trck_RowWait),0

; ------------------------------
; check for new track data
; ------------------------------

		ld	e,(iy+trck_RowSteps)		; Row finished?
		ld	d,(iy+(trck_RowSteps+1))
		ld	a,e
		or	d
		jp	nz,.dontupd_trck

.trck_restart:
		ld	de,0
		ld	e,(iy+trck_BlockCurr)
		ld	l,(iy+trck_Blocks)
		ld	h,(iy+(trck_Blocks+1))
		ld	c,l				; bc - copy of hl
		ld	b,h
		add 	hl,de
		ld	a,(hl)
		cp	0FEh
		jp	z,.skip_block
		cp	0FFh				; End of song marker? 0FFh
		jp	z,.stop_track
		rlca
		rlca
		and	11111100b
		inc 	hl
		inc 	(iy+trck_BlockCurr)
		ld	de,0
		ld	e,a
		ld	l,(iy+trck_PattBase)
		ld	h,(iy+(trck_PattBase+1))
		add 	hl,de
		ld	c,(hl)
		inc 	hl
		ld	b,(hl)
		inc 	hl
		ld	e,(hl)
		inc 	hl
		ld	d,(hl)
		ld	l,(iy+trck_PattBase)
		ld	h,(iy+(trck_PattBase+1))
		add 	hl,bc
		ld	(iy+trck_PattRead),l
		ld	(iy+(trck_PattRead+1)),h
		ld	(iy+trck_RowSteps),e
		ld	(iy+(trck_RowSteps+1)),d
.dontupd_trck:
		ld	l,(iy+trck_PattRead)
		ld	h,(iy+(trck_PattRead+1))

	; ------------------------------
	; Check timer or note data
	; ------------------------------
		ld	a,(hl)
		or	a
		jp	p,.set_timer
.loop_me:
		inc	hl
		ld	c,a
		and	00111111b

		ld	de,0
		ld	e,a
		and	00011000b
		rrca
		rrca
		rrca
		ld	d,a
		ld	a,e
		and	00000111b
		rrca
		rrca
		rrca
		ld	e,a
		push	ix
		add	ix,de

		bit 	6,c
		jp	z,.keep_ctrl
		ld	a,(hl)
		inc	hl
		ld	(ix+chnl_Type),a
.keep_ctrl:
		ld	a,(ix+chnl_Type)
		rrca
		jp	nc,.no_note
		ld	c,(hl)				; Note
		inc 	hl
		ld	(ix+chnl_Note),c
.no_note:
		rrca					; Instrument
		jp	nc,.no_inst
		ld	c,(hl)
		inc 	hl
		ld	(ix+chnl_Ins),c
.no_inst:
		rrca					; Volume
		jp	nc,.no_vol
		ld	c,(hl)
		inc 	hl
		ld	(ix+chnl_Vol),c
.no_vol:
		rrca					; Effect
		jp	nc,.no_eff
		ld	c,(hl)
		inc 	hl
		ld	(ix+chnl_EffId),c
		ld	c,(hl)
		inc 	hl
		ld	(ix+chnl_EffArg),c
.no_eff:
; 		bit	bitTrckReset,(iy+trck_Flags)	; Check flags
; 		jp	nz,.exit_track
		call	.chip_setup
		pop	ix
		ld	a,(hl)
		or	a
		jp	z,.exit_notes
		jp	.loop_me

; ------------------------------
; block 0FEh
; skip block
; ------------------------------

; TODO
.skip_block:
		jp	$
		
; ------------------------------
; block 0FFh
; end of tracks
; ------------------------------

.stop_track:
		call	SndDrv_ResetChan

		ld	(iy+trck_Flags),0
		ret

; ------------------------------
; Exit track
; ------------------------------

.exit_track:
		res	bitTrckReset,(iy+trck_Flags)
		jp	.trck_restart

; ------------------------------
; Set ROW wait timer
; ------------------------------

.set_timer:
		ld	(iy+trck_RowWait),a

; ------------------------------
; Note pack exit
; ------------------------------

.exit_notes:
		inc 	hl

.exit_busy:
		ld	(iy+trck_PattRead),l		; save new read
		ld	(iy+(trck_PattRead+1)),h

; ------------------------------
; Decrement rows
; ------------------------------

.row_countdwn:
		ld	e,(iy+trck_RowSteps)
		ld	d,(iy+(trck_RowSteps+1))
		dec 	de
		ld	(iy+trck_RowSteps),e
		ld	(iy+(trck_RowSteps+1)),d
		ret

; ------------------------------------
; Set chip
; 
; iy - track buffer
; ix - current channel
; ------------------------------------

.chip_setup:
		ld	a,(ix+chnl_Chip)
		and	111b
		cp	3
		ret	z			; 03h invalid channel

; ---------------------------------------------
; Track channel list:
; FM1 FM2 FM4 FM5 FM3 FM6 PSG1 PSG2 PSG3 NOISE
; ---------------------------------------------

		push	hl
		ld	(ix+chnl_Update),1

	; ---------------------------------------------
		ld	a,(ix+chnl_Type)
		bit	7,a			; Effect
		jp	nz,.use_neweff
		and	1000b
		jp	z,.no_neweff
.use_neweff:	
		call	.set_effect
.no_neweff:

	; ---------------------------------------------
		bit	5,(ix+chnl_Type)	; Instrument
		jp	nz,.use_newinst
		bit	1,(ix+chnl_Type)
		jp	z,.no_newinst
.use_newinst:
		call	.grab_instslot
		ld	a,(hl)
		cp	-1
		jp	z,.no_newinst
		ld	(ix+chnl_InsType),a
		inc	hl
		ld	a,(hl)
		ld	(ix+chnl_InsOpt),a
		inc	hl
		ld	a,(hl)
		ld	(ix+chnl_InsAddr),a
		inc	hl
		ld	a,(hl)
		ld	(ix+(chnl_InsAddr+1)),a	
.no_newinst:

	; ---------------------------------------------
		bit	4,(ix+chnl_Type)	; Note
		jp	nz,.use_notereq
		bit	0,(ix+chnl_Type)
		jp	z,.no_notereq
.use_notereq:
		call	.grab_instslot
		ld	a,(hl)
		cp	-1
		jp	z,.no_notereq

		ld	b,(ix+chnl_InsType)
		ld	c,(ix+chnl_Chip)
		ld	a,b
		or	a			; Type 080h/0E0h?
		jp	p,.notype3
		bit 	7,c			; PSG channel?
		jp	nz,.setfreq_psg
.notype3:
		ld	a,b
		cp	2			; Type 2?
		jp	nz,.fm_normalchnl
		ld	a,c			; Channel 6?
		cp	6
		jp	nz,.fm_normalchnl

; ---------------------------------------------
; Play FM6 SAMPLE
; ---------------------------------------------

		ld	a,(ix+chnl_Note)
		cp	-2
		jp	z,.exit_notereq
		cp	-1
		jp	z,.exit_notereq
		add 	a,(ix+chnl_InsOpt)
		rlca
		and	11111110b
		ld	de,0
		ld	e,a
		ld	hl,wavFreq_List
		add 	hl,de
		ld	a,(hl)
		inc 	hl
		ld	(ix+chnl_SmplFreq),a
		ld	a,(hl)
		inc 	hl
		ld	(ix+(chnl_SmplFreq+1)),a
		jp	.exit_notereq

; ---------------------------------------------
; Play FM channel
; ---------------------------------------------

.fm_normalchnl:
		ld	a,(ix+chnl_Chip)
		bit 	7,a
		jp	nz,.exit_notereq		; failsafe

		ld	a,(ix+chnl_Note)
		cp	-1
		jp	z,.exit_notereq
		cp	-2
		jp	z,.exit_notereq
		cp	-10
		jp	z,.exit_notereq

		ld	hl,fmFreq_List
		ld	de,0
		add 	a,(ix+chnl_InsOpt)
		rlca
		and	11111110b
		ld	e,a
		add	hl,de
		ld	a,(hl)
		ld	(ix+chnl_Freq),a
		inc	hl
		ld	a,(hl)
		ld	(ix+(chnl_Freq+1)),a
		jp	.exit_notereq
		
; ---------------------------------------------
; Play PSG normal channel
; ---------------------------------------------

.setfreq_psg:
		ld	a,(ix+chnl_Chip)
		or	a
		jp	p,.exit_notereq
		ld	b,a
		or	01Fh
		ld	c,a
		ld	a,(ix+chnl_Note)
		cp	-10
		jp	z,.del_chtype
		cp	-2
		jp	z,.exit_notereq
		cp	-1
		jp	z,.exit_notereq
		ld	c,a

		ld	hl,0
		ld	a,c
		rlca
		and	11111110b
		ld	de,0
		ld	e,a
		add 	hl,de
		ld	a,(ix+chnl_InsOpt)
		rlca
		and	11111110b
		ld	de,0
		ld	e,a
		add 	hl,de
		ld	d,h
		ld	e,l	
		ld	hl,psgFreq_List
		add	hl,de
	
		ld	a,(hl)
		ld	(ix+chnl_Freq),a
		inc 	hl
		ld	a,(hl)
		ld	(ix+(chnl_Freq+1)),a

		ld	(ix+chnl_PsgIndx),0
		jp	.exit_notereq

.del_chtype:
		xor	a
		ld	(ix+chnl_Type),a

.exit_notereq:
; 		ld	(ix+chnl_Update),1

.no_notereq:
		pop	hl
		ret

; ------------------------------------
; Set effects
; ------------------------------------

.set_effect:
		push	hl
		ld	a,(ix+chnl_EffId)
		add 	a,a
		and	11111110b
		ld	c,(ix+chnl_EffArg)
		ld	de,0
		ld	e,a
		ld	hl,.eff_list
		add	hl,de
		ld	a,(hl)
		inc	hl
		ld	(curr_Jsr+1),a
		ld	a,(hl)
		ld	(curr_Jsr+2),a
		call	(curr_Jsr)
		pop	hl
.eff_null:
		ret
.eff_list:
		dw .eff_null
		dw .eff_A	; A | Set ticks
		dw .eff_B	; B | Jump to block
		dw .eff_null	; C | Break to row (not possible here)
		dw .eff_D	; D | Volume slide
		dw .eff_E	; E | Portametro down
		dw .eff_F	; F | Portametro up
		dw .eff_null	; G
		dw .eff_null	; H
		dw .eff_null	; I
		dw .eff_null	; J	
		dw .eff_null	; K
		dw .eff_null	; L
		dw .eff_null	; M
		dw .eff_null	; N
		dw .eff_null	; O
		dw .eff_null	; P
		dw .eff_null	; Q
		dw .eff_null	; R
		dw .eff_null	; S
		dw .eff_null	; T
		dw .eff_null	; U
		dw .eff_null	; V
		dw .eff_null	; W
		dw .eff_X	; X
		dw .eff_null	; Y
		dw .eff_null	; Z

; ------------------------------------
; Effect A - Set ticks
; ------------------------------------

.eff_A:
		dec 	c
		ld	(iy+trck_TicksCurr),c
		ld	(iy+trck_TicksRead),c
		ret

; ------------------------------------
; Effect B - Set panning (FM ONLY)
; ------------------------------------

.eff_B:
; 		set	bitTrckReset,(iy+trck_Flags)
		ld	(iy+trck_BlockCurr),c
		xor	a
		ld	(iy+trck_RowSteps),a
		ld	(iy+(trck_RowSteps+1)),a
		ld	(iy+trck_RowWait),a
		ret

; ------------------------------------
; Effect D - Volume slide
; ------------------------------------

.eff_D:
		ld	a,c
		and	11110000b		; X0h - slide up
		jp	nz,.go_up
		ld	a,c
		and	00001111b		; 0Xh - slide down
		ret	z			; 00h - slide continue
.go_down:
		cpl
		inc	a
		ld	(ix+chnl_EfVolSlide),a
		ret
.go_up:
		rrca
		rrca
		rrca
		rrca
		and	00001111b
		ld	(ix+chnl_EfVolSlide),a
		ret

; ------------------------------------
; Effect E - Portametro down
; ------------------------------------

.eff_E:
		ld	a,c
		or	a
		jp	z,.prtdwn_cont
		and	11110000b
		cp	0E0h
		jp	z,.dwn_exfine
		cp	0F0h
		jp	z,.dwn_fine
		
; Normal
		ld	a,c
		and	00011111b
		cpl
		inc	a
		ld	d,a
		add	a,a
		add	a,a
		ld	e,a
		ld	a,d
		rrca
		rrca
		and	00000011b
		or	11111100b
		ld	d,a
		jp	.set_portam
.dwn_exfine:
		ld	de,-1
		ld	a,c
		and	00001111b
		cpl
		inc	a
		sra	a
		ld	e,a
		jp	.set_portam
.dwn_fine:
		ld	de,-1
		ld	a,c
		and	00001111b
		cpl
		inc	a
		add	a,a
		ld	e,a

; shared with effects E and F
.set_portam:
		ld	(ix+(chnl_EfPortam+1)),d
		ld	(ix+chnl_EfPortam),e
.prtdwn_cont:
		ret

; ------------------------------------
; Effect F - Portametro up
; ------------------------------------

.eff_F:
		ld	a,c
		or	a
		jp	z,.prtup_cont
		and	11110000b
		cp	0E0h
		jp	z,.up_exfine
		cp	0F0h
		jp	z,.up_fine
		
; Normal
		ld	a,c
		and	00011111b
		ld	d,a
		add	a,a
		add	a,a
		ld	e,a
		ld	a,d
		rlca
		rlca	
		and	00000001b
		ld	d,a
		jp	.set_portam
.up_exfine:
		ld	de,0
		ld	a,c
		and	00001111b
		sra	a
		ld	e,a
		jp	.set_portam
.up_fine:
		ld	de,0
		ld	a,c
		and	00001111b
		add	a,a
		ld	e,a
		jp	.set_portam
.prtup_cont:
		ret
		
; ------------------------------------
; Effect X - Set panning (FM ONLY)
; ------------------------------------

.eff_X:
		ld	a,c
		rlca
		rlca
		and	11b
		ld	de,.fmpan_list
		add 	a,e
		ld	e,a
		ld	a,(de)
		ld	(ix+chnl_FmPan),a
		ret
.fmpan_list:
		db 080h
		db 080h
		db 0C0h
		db 040h

; ---------------------------------------------

.grab_instslot:
		ld	l,(iy+trck_Instr)
		ld	h,(iy+(trck_Instr+1))
		ld	a,(ix+chnl_Ins)
		dec 	a
		ld	b,a
		add 	a,a
		add 	a,a
		ld	c,a
		ld	a,b
		rlca
		rlca
		and	3
		ld	b,a
		add	hl,bc
		ret
		
; ===================================================================
; ----------------------------------------------------
; Subs
; ----------------------------------------------------

; ------------------------------------
; Track request
; ------------------------------------

SndDrv_ReqTrack:
		ld	a,(iy+trck_ReqFlag)
		rlca
		and	11111110b
		ld	de,0
		ld	e,a
		ld	hl,.req_list
		add	hl,de
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a
		jp	(hl)
.req_list:
		dw 0
		dw .req01
		dw .req02

; ------------------------------------
; Flag 01h
; ------------------------------------

.req01:
		ld	b,(iy+trck_ReqBlk)		; Copy addresses
		ld	c,(iy+(trck_ReqBlk+1))
		ld	d,(iy+trck_ReqPatt)
		ld	e,(iy+(trck_ReqPatt+1))
		ld	h,(iy+trck_ReqIns)
		ld	l,(iy+(trck_ReqIns+1))
		ld	(iy+trck_Blocks),b
		ld	(iy+(trck_Blocks+1)),c
		ld	(iy+trck_PattBase),d
		ld	(iy+(trck_PattBase+1)),e
		ld	(iy+trck_PattRead),d
		ld	(iy+(trck_PattRead+1)),e
		ld	(iy+trck_Instr),h
		ld	(iy+(trck_Instr+1)),l
		ld	d,(iy+trck_ReqTicks)		; Tempo and ticks
		ld	c,(iy+trck_ReqTempo)
		ld	b,(iy+trck_ReqCurrBlk)
		ld	a,(iy+trck_ReqSndBnk)
		ld	(iy+trck_TicksCurr),d
		ld	(iy+trck_TicksMain),d
		ld	(iy+trck_TicksRead),d
		ld	(iy+trck_TempoBits),c
		ld	(iy+trck_BlockCurr),b
		ld	(curr_SndBank),a
		xor	a
		ld	(iy+trck_ReqFlag),a
		ld	(iy+trck_RowSteps),a
		ld	(iy+(trck_RowSteps+1)),a		
		ld	(iy+trck_RowWait),a
		inc 	a
		ld	(iy+trck_Flags),a
		jp	SndDrv_ResetChan

; ------------------------------------
; Flag 02h
; ------------------------------------

.req02:
		xor	a
		ld	(iy+trck_Flags),a

SndDrv_ResetChan:
		push	ix
		ld	b,MAX_CHNLS
		xor	a
		ld	de,20h
		xor	a
.initchnls:
		ld	(ix+chnl_Type),a	; Note request
		ld	(ix+chnl_Note),-2	; Set Note off
		ld	(ix+chnl_Vol),64	; Max volume
		ld	(ix+chnl_EfNewVol),64
		ld	(ix+chnl_FmPan),0C0h
		ld	(ix+chnl_InsType),a
		ld	(ix+chnl_InsOpt),a
		ld	(ix+chnl_EfVolSlide),a
; 		ld	(ix+chnl_Flags),a
		ld	(ix+chnl_PsgVolEnv),a
		ld	(ix+chnl_PsgIndx),a
		ld	(ix+chnl_Update),1

		add 	ix,de
		djnz	.initchnls
		pop	ix
		ret
		
; ---------------------------------------------
; FM send registers
; 
; Input:
; d - ctrl
; e - data
; c - channel
; ---------------------------------------------

SndDrv_FmAutoSet:
		bit 	2,(ix+chnl_Chip)
		jp	nz,SndDrv_FmSet_2
		
SndDrv_FmSet_1:
		ld	a,d
		ld	(Zym_ctrl_1),a
		nop
		ld	a,e
		ld	(Zym_data_1),a
		nop
		ret

SndDrv_FmSet_2:
		ld	a,d
		ld	(Zym_ctrl_2),a
		nop
		ld	a,e
		ld	(Zym_data_2),a
		nop
		ret

; ====================================================================
fmFreq_List:	dw 644			; C-0
		dw 681
		dw 722
		dw 765
		dw 810
		dw 858
		dw 910
		dw 964
		dw 1021
		dw 1081
		dw 1146
		dw 1214
		dw 644|800h		; C-1
		dw 681|800h
		dw 722|800h
		dw 765|800h
		dw 810|800h
		dw 858|800h
		dw 910|800h
		dw 964|800h
		dw 1021|800h
		dw 1081|800h
		dw 1146|800h
		dw 1214|800h
		dw 644|1000h		; C-2
		dw 681|1000h
		dw 722|1000h
		dw 765|1000h
		dw 810|1000h
		dw 858|1000h
		dw 910|1000h
		dw 964|1000h
		dw 1021|1000h
		dw 1081|1000h
		dw 1146|1000h
		dw 1214|1000h
		dw 644|1800h		; C-3
		dw 681|1800h
		dw 722|1800h
		dw 765|1800h
		dw 810|1800h
		dw 858|1800h
		dw 910|1800h
		dw 964|1800h
		dw 1021|1800h
		dw 1081|1800h
		dw 1146|1800h
		dw 1214|1800h
		dw 644|2000h		; C-4
		dw 681|2000h
		dw 722|2000h
		dw 765|2000h
		dw 810|2000h
		dw 858|2000h
		dw 910|2000h
		dw 964|2000h
		dw 1021|2000h
		dw 1081|2000h
		dw 1146|2000h
		dw 1214|2000h
		dw 644|2800h		; C-5
		dw 681|2800h
		dw 722|2800h
		dw 765|2800h
		dw 810|2800h
		dw 858|2800h
		dw 910|2800h
		dw 964|2800h
		dw 1021|2800h
		dw 1081|2800h
		dw 1146|2800h
		dw 1214|2800h		
		dw 644|3000h		; C-6
		dw 681|3000h
		dw 722|3000h
		dw 765|3000h
		dw 810|3000h
		dw 858|3000h
		dw 910|3000h
		dw 964|3000h
		dw 1021|3000h
		dw 1081|3000h
		dw 1146|3000h
		dw 1214|3000h
		dw 644|3800h		; C-7
		dw 681|3800h
		dw 722|3800h
		dw 765|3800h
		dw 810|3800h
		dw 858|3800h
		dw 910|3800h
		dw 964|3800h
		dw 1021|3800h
		dw 1081|3800h
		dw 1146|3800h
		dw 1214|3800h

psgFreq_List:
		dw -1		; C-0 $0
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1		; C-1 $C
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1		; C-2 $18
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1		; C-3 $24
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw 3F8h
		dw 3BFh
		dw 389h
		dw 356h		;C-4 30
		dw 326h
		dw 2F9h
		dw 2CEh
		dw 2A5h
		dw 280h
		dw 25Ch
		dw 23Ah
		dw 21Ah
		dw 1FBh
		dw 1DFh
		dw 1C4h
		dw 1ABh		;C-5 3C
		dw 193h
		dw 17Dh
		dw 167h
		dw 153h
		dw 140h
		dw 12Eh
		dw 11Dh
		dw 10Dh
		dw 0FEh
		dw 0EFh
		dw 0E2h
		dw 0D6h		;C-6 48
		dw 0C9h
		dw 0BEh
		dw 0B4h
		dw 0A9h
		dw 0A0h
		dw 97h
		dw 8Fh
		dw 87h
		dw 7Fh
		dw 78h
		dw 71h
		dw 6Bh		; C-7 54
		dw 65h
		dw 5Fh
		dw 5Ah
		dw 55h
		dw 50h
		dw 4Bh
		dw 47h
		dw 43h
		dw 40h
		dw 3Ch
		dw 39h
		dw 36h		; C-8 $60
		dw 33h
		dw 30h
		dw 2Dh
		dw 2Bh
		dw 28h
		dw 26h
		dw 24h
		dw 22h
		dw 20h
		dw 1Fh
		dw 1Dh
		dw 1Bh		; C-9 $6C
		dw 1Ah
		dw 18h
		dw 17h
		dw 16h
		dw 15h
		dw 13h
		dw 12h
		dw 11h
 		dw 10h
 		dw 9h
 		dw 8h
		dw 0		; use +60 if using C-5 for tone 3 noise
		
wavFreq_List:	dw 100h		; C-0
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h	
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h		; C-1
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h	
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h		; C-2
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 03Bh
		dw 03Eh		; C-3 5512
		dw 043h		; C#3
		dw 046h		; D-3
		dw 049h		; D#3
		dw 04Eh		; E-3
		dw 054h		; F-3
		dw 058h		; F#3
		dw 05Eh		; G-3
		dw 063h		; G#3
		dw 068h		; A-3
		dw 070h		; A#3
		dw 075h		; B-3
		dw 07Fh		; C-4 11025
		dw 088h		; C#4
		dw 08Fh		; D-4
		dw 097h		; D#4
		dw 0A0h		; E-4
		dw 0ADh		; F-4
		dw 0B5h		; F#4
		dw 0C0h		; G-4
		dw 0CCh		; G#4
		dw 0D7h		; A-4
		dw 0E7h		; A#4
		dw 0F0h		; B-4
		dw 100h		; C-5 22050
		dw 110h		; C#5
		dw 120h		; D-5
		dw 12Ch		; D#5
		dw 142h		; E-5
		dw 158h		; F-5
		dw 16Ah		; F#5
		dw 17Eh		; G-5
		dw 190h		; G#5
		dw 1ACh		; A-5
		dw 1C2h		; A#5
		dw 1E0h		; B-5
		dw 1F8h		; C-6 44100
		dw 210h		; C#6
		dw 240h		; D-6
		dw 260h		; D#6
		dw 280h		; E-6
		dw 2A0h		; F-6
		dw 2D0h		; F#6
		dw 2F8h		; G-6
		dw 320h		; G#6
		dw 350h		; A-6
		dw 380h		; A#6
		dw 3C0h		; B-6
		dw 400h		; C-7 88200
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h	
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h	
		dw 100h		; C-8
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h	
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h	
		dw 100h		; C-9
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h	
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h

chnChips_List:
		db 00h,01h,04h,05h,02h,06h,080h,0A0h,0C0h,0E0h
		db 3,3,3,3,3,3
		
; ====================================================================
; ----------------------------------------------------------------
; Z80 RAM
; ----------------------------------------------------------------

; ----------------------------------------------------
; Tracker data buffer
; ----------------------------------------------------

trck_Blocks	equ 00h		; word
trck_PattBase	equ 02h		; word
trck_Instr	equ 04h		; word
trck_TicksMain 	equ 06h
trck_TempoBits	equ 07h
trck_PattRead	equ 08h		; word
trck_RowSteps	equ 0Ah		; word
trck_RowWait	equ 0Ch
trck_TicksCurr	equ 0Dh
trck_TicksRead	equ 0Eh
trck_Flags	equ 0Fh
trck_BlockCurr	equ 10h
trck_MasterVol	equ 11h

trck_ReqBlk	equ 15h		; word
trck_ReqPatt	equ 17h		; word
trck_ReqIns	equ 19h		; word
trck_ReqTicks	equ 1Bh		;
trck_ReqTempo	equ 1Ch		;
trck_ReqCurrBlk	equ 1Dh		;
trck_ReqSndBnk	equ 1Eh		;
trck_ReqFlag	equ 1Fh		;

; trck_Flags
bitTrckReset	equ 1

; ----------------------------------------------------
; Track buffer
; ----------------------------------------------------

SndBuff_Track_1:
		ds 20h
SndBuff_Track_2:
		ds 20h

; ----------------------------------------------------
; Tracker note buffers
; ----------------------------------------------------

chnl_Chip	equ 0
chnl_Type	equ 1
chnl_Note	equ 2
chnl_Ins	equ 3
chnl_Vol	equ 4
chnl_EffId	equ 5
chnl_EffArg	equ 6
chnl_Update	equ 7
chnl_InsAddr	equ 8		; word
chnl_Freq	equ 0Ah		; word
chnl_InsType	equ 0Ch
chnl_InsOpt	equ 0Dh

chnl_FmPan	equ 0Eh
chnl_FmRegB0	equ 0Fh
chnl_FmRegB4	equ 10h
chnl_FmRegKeys	equ 11h
chnl_PsgVolBase	equ 12h
chnl_PsgVolEnv	equ 13h
chnl_PsgIndx	equ 14h
chnl_SmplFlags	equ 15h
chnl_EfVolSlide	equ 16h
chnl_EfNewVol	equ 17h

chnl_SmplFreq	equ 18h		; word
chnl_EfPortam	equ 1Ah		; word
chnl_EfNewFreq	equ 1Ch		; word


; chnl_Flags
bitChnlSlide	equ 0

SndBuff_ChnlBuff_1:
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		
		db 01h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

		db 04h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

		db 05h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		
		db 02h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

		db 06h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

SndBuff_ChnlPsg_1:
		db 80h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

		db 0A0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

		db 0E0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

		
SndBuff_ChnlBuff_2:
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		
		db 01h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

		db 04h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

		db 05h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		
		db 02h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

		db 06h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

SndBuff_ChnlPsg_2:
		db 80h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

		db 0A0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

		db 0E0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 0C0h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

; ====================================================================
; ----------------------------------------------------------------
; MUSIC DATA
; ----------------------------------------------------------------

; ----------------------------------------------------
; PSG Instruments
; ----------------------------------------------------

PsgIns_00:	db 0
		db -1
PsgIns_01:	db 0,1,2,3,4,6
		db -1
PsgIns_02:	db 1,1,3,4,5,5,6
		db -1
PsgIns_03:	db 1,1,2,2,3,5,6
		db -1
PsgIns_04:	db 0,2,4,6,10
		db -1	
		align 4
		
; ----------------------------------------------------
; FM Instruments
; ----------------------------------------------------

; .gsx instruments; filename,$2478,$20 ($28 for FM3 instruments)
FmIns_Fm3_OpenHat:
		binclude "game/sound/instr/fm/fm3_openhat.gsx",2478h,28h
FmIns_Fm3_ClosedHat:
		binclude "game/sound/instr/fm/fm3_closedhat.gsx",2478h,28h
FmIns_DrumKick:
		binclude "game/sound/instr/fm/drum_kick.gsx",2478h,20h
FmIns_DrumSnare:
		binclude "game/sound/instr/fm/drum_snare.gsx",2478h,20h
FmIns_DrumCloseHat:
		binclude "game/sound/instr/fm/drum_closehat.gsx",2478h,20h
FmIns_PianoM1:
		binclude "game/sound/instr/fm/piano_m1.gsx",2478h,20h
FmIns_Bass_gum:
		binclude "game/sound/instr/fm/bass_gum.gsx",2478h,20h
FmIns_Bass_calm:
		binclude "game/sound/instr/fm/bass_calm.gsx",2478h,20h
FmIns_Bass_heavy:
		binclude "game/sound/instr/fm/bass_heavy.gsx",2478h,20h
FmIns_Brass_gummy:
		binclude "game/sound/instr/fm/brass_gummy.gsx",2478h,20h
FmIns_Flaute_1:
		binclude "game/sound/instr/fm/flaute_1.gsx",2478h,20h
FmIns_Bass_2:
		binclude "game/sound/instr/fm/bass_2.gsx",2478h,20h
FmIns_Bass_3:
		binclude "game/sound/instr/fm/bass_3.gsx",2478h,20h
FmIns_Bass_5:
		binclude "game/sound/instr/fm/bass_5.gsx",2478h,20h
FmIns_Guitar_1:
		binclude "game/sound/instr/fm/guitar_1.gsx",2478h,20h
FmIns_Horn_1:
		binclude "game/sound/instr/fm/horn_1.gsx",2478h,20h
FmIns_Organ_M1:
		binclude "game/sound/instr/fm/organ_m1.gsx",2478h,20h
FmIns_Bass_Beach:
		binclude "game/sound/instr/fm/bass_beach.gsx",2478h,20h
FmIns_Bass_Beach_2:
		binclude "game/sound/instr/fm/bass_beach_2.gsx",2478h,20h
FmIns_Brass_Cave:
		binclude "game/sound/instr/fm/brass_cave.gsx",2478h,20h
FmIns_Piano_Small:
		binclude "game/sound/instr/fm/piano_small.gsx",2478h,20h
FmIns_Trumpet_2:
		binclude "game/sound/instr/fm/trumpet_2.gsx",2478h,20h
FmIns_Bell_Glass:
		binclude "game/sound/instr/fm/bell_glass.gsx",2478h,20h
FmIns_Marimba_1:
		binclude "game/sound/instr/fm/marimba_1.gsx",2478h,20h
