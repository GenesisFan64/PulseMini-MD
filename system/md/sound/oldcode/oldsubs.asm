; ----------------------------------------------------	

.set_sound_chip:
		ld	de,0
		ld	a,(ix+chnl_Chip)
		or	a
		jp	p,.got_fm
		rlca
		rlca
		rlca
		and	00000011h
		add 	a,6
		jp	.set_now
.got_fm:
		cp	3
		jp	nc,.set_now
		dec	a
.set_now:

		add 	a,a
		ld	e,a
		ld	hl,.set_chip
		add	hl,de
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a
		jp	(hl)
.set_chip:
		dw .this_fm
		dw .this_fm
		dw .this_fm
		dw .this_fm
		dw .this_fm
		dw .this_fm
		dw .this_psg
		dw .this_psg	
		dw .this_psg
		dw .both_pnoise

; ----------------------------------------------------
; Bad channel
; ----------------------------------------------------		

.bad_chnl:
		ret

; ----------------------------------------------------
; FM normal channels
; ----------------------------------------------------

.this_fm:
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
; 		ld	a,(ix+chnl_Type)
; 		bit	5,a			; Instrument
; 		jp	nz,.use_newinst
; 		and	0010b
; 		jp	z,.no_newinst
; .use_newinst:
; 		call	.set_fm_ins
; .no_newinst:

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
		ret

; ------------------------------------
; FM normal registers
; ------------------------------------

.set_fm_ins:
		ld	e,(ix+chnl_Chip)
		bit	7,e
		ret	nz
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
		
; ----------------------------------------------------
; PSG1, PSG2 (and PSG3 from both_pnoise)
; ----------------------------------------------------

.this_psg:
		push	ix
; 		call	.srch_slot

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
; 		call	.srch_slot

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
; 		ld	a,(ix+chnl_InsType)
; 		pop	iy
; 		pop	ix			; Return to PSG 3
; 		and	11b
; 		cp	3
; 		jp	nz,.this_psg
; 		ld	a,0DFh
; 		ld	(zpsg_ctrl),a
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
