
Smoke:
;X = current smoke sprite index. $FF = no slot found
	LDX #$03
	
	.loop
	LDA $17C0|!addr,x		;\Not free slot, next
	BNE .next			;/
	INC $17C0|!addr,x		;>Set it to #$01
	LDA #$1B			;\Set timer
	STA $17CC|!addr,x		;/
	BRA .Done			;>And done.

	.next
	DEX
	BPL .loop
	
	.Done
	RTL