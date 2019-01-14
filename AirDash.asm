;Insert this as any level or gamemode 14.
;Freeram
 if !sa1 == 0
  !Freeram_AirDashTime	= $60
 else
  !Freeram_AirDashTime	= $60
 endif
  ;^[1 byte] Freeram duplicates in case if you are porting your hack and had to move the freeram
  ; somewhere else. This RAM frame timer works like this:
  ; 0: you are able to airdash.
  ; 0 to !Setting_AirDash_Cooldown: the cooldown period
;Settings
 !Setting_AirDash_Duration = 10
  ;^How long is the airdash itself.
 !Setting_AirDash_Cooldown = 20
  ;^after airdash have ended, this is how long before you can airdash again.
 !Setting_AirDash_XSpeeds = $30
  ;^Player X speed when airdashing. $01 to $7F with $7F the fastest.
 !Setting_AirDash_CooldownType = 1
  ;^0 = Touching the ground for at least a single frame instantly cools it. This is the
  ;     only way to enable airdash once again.
  ; 1 = 
  ;
 !Setting_AirDash_ButtonToAirdash = %01000000
  ;^What 1-frame button to press to air dash (you have to hold left or right beforehand). This is
  ; a binary number, using RAM address $16 formatted byetUDLR.
 !Setting_AirDash_RequireHoldLeftRight = 0
  ;^0 = just press one button to airdash
  ; 1 = require holding left or right along with the airdash button.
;Sound effects
 !Setting_AirDash_SoundEffectNumb = $09
 !Setting_AirDash_SoundEffectRAM = $1DFC|!addr

;assert less(!Setting_AirDash_Duration+!Setting_AirDash_Cooldown, 256), "Make sure duration and cooldown total doesn't exceed 255!"

AirDashXSpeeds:
	db $100-!Setting_AirDash_XSpeeds
	db !Setting_AirDash_XSpeeds

main:
	PHB
	PHK
	PLB
	.AirDash
	LDA $9D					;\Don't do anything during a time freeze.
	ORA $13D4|!addr				;|
	BEQ +
	JMP ..Done				;/
	+
	LDA !Freeram_AirDashTime		;\Decrement timer
	BEQ ..NoDecrement			;|
	if !Setting_AirDash_CooldownType == 0
		CMP.b #!Setting_AirDash_Cooldown
		BCC ..NoDecrement
	endif
	DEC					;|
	STA !Freeram_AirDashTime		;/
	..NoDecrement
	LDA $77
	BIT.b #%00000100
	BEQ ..NotOnGround
	LDA #$00
	STA !Freeram_AirDashTime
	BRA ..Done
	..NotOnGround
	LDA $71
	;ORA $xxxxxx				;\Custom RAM here to prevent issues with other uberasm tool
	;ORA $xxxxxx				;/stuff.
	BNE ..ResetAirDash
	
	..AirDashStates
	LDA !Freeram_AirDashTime		;\0 = ready
	BEQ ..ButtonTrigger			;/
	CMP #!Setting_AirDash_Cooldown		;\1 to the cooldown: cooldown range
	BCC ..CoolDown				;/
	
	..AirDashing				;>cooldown to (!Setting_AirDash_Cooldown+!Setting_AirDash_Duration): airdashing state
	LDA $77					;\If mario crashes into a surface, cancel it
	BNE ...CancelAirDashHard		;/
	
	STZ $7D					;>No Y speed
	LDY $76					;\Mario Boost left and right
	LDA AirDashXSpeeds,y			;|
	STA $7B					;/
	LDA.b #%01000011			;\Disable left and right and dash button for no capespinning
	TRB $15					;|
	TRB $16					;/
	STZ $140D|!addr				;>Disable spinjump.
	STZ $14A6|!addr				;>Disable cape spin.
	BRA ..Done
	
	...CancelAirDashHard
	;STZ $7B					;\Cancel Mario airdash with cooldown.
	LDA.b #!Setting_AirDash_Cooldown	;|
	STA !Freeram_AirDashTime		;/
	BRA ..Done
	
	..ResetAirDash
	LDA #$00
	STA !Freeram_AirDashTime
	BRA ..Done
	
	..ButtonTrigger
	if !Setting_AirDash_RequireHoldLeftRight != 0
		LDA $15								;\Button combination
		BIT.b #%00000011						;|
		BEQ ..Done							;|
	endif
	LDA $16								;|
	BIT.b #!Setting_AirDash_ButtonToAirdash				;|
	BEQ ..Done							;/
	LDA.b #!Setting_AirDash_Cooldown+!Setting_AirDash_Duration	;\Mario is now airdashing
	STA !Freeram_AirDashTime					;/
	LDA $7F								;\Prevent screen-wrapping smoke.
	BNE ...NoSmoke							;|
	REP #$20							;|
	LDA $80								;|
	CLC								;|
	ADC #$0010							;|
	SEP #$20							;|
	XBA								;|
	BNE ...NoSmoke							;/
	JSL GenerateSmoke_Smoke						;\Smoke
	CPX #$FF							;|
	BEQ ...NoSmoke							;|
	LDA $94								;|
	STA $17C8|!addr,x						;|
	LDA $96								;|
	CLC								;|
	ADC #$10							;|
	STA $17C4|!addr,x						;/
	...NoSmoke
	LDA #!Setting_AirDash_SoundEffectNumb				;\Sound effects
	STA !Setting_AirDash_SoundEffectRAM				;/
	LDA #$0C							;\Long jump pose.
	STA $72								;/
	BRA ..AirDashing						;>Immidiately assume the player is airdashing right off the bat.
	
	..CoolDown
	..Done
	PLB
	RTL