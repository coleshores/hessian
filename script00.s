                include macros.s
                include mainsym.s

        ; Script 0, title screen & game start/load/save

LOGOSTARTROW    = 1
TEXTSTARTROW    = 12
NUMTEXTROWS     = 8
NUMSAVES        = 5
NUMTITLEPAGES   = 2

LOAD_GAME       = 0
SAVE_GAME       = 1

TITLE_MOVEDELAY = 8
TITLE_PAGEDELAY = 500

CHEATSTRINGLENGTH = 7

saveStateBuffer = screen2

                org scriptCodeStart

                dc.w TitleScreen

TitleScreen:    stx TitleScreenParam+1          ;Go to save screen (X>0) or main menu (X=0)
                jsr BlankScreen
                jsr ClearPanelText
                jsr InitScroll                  ;Make sure no scrolling
                jsr ClearActors                 ;Reset sprites
                jsr DrawActors

        ; Load the always resident sprites

                lda fileHi+C_COMMON             ;If not loaded yet, load the always
                bne SpritesLoaded               ;resident sprites
                ldy #C_COMMON
                jsr LoadSpriteFile
                ldy #C_WEAPON
                jsr LoadSpriteFile
                lda #HP_PLAYER                  ;Init health & fists item immediately
                sta actHp+ACTI_PLAYER           ;even before starting the game so that
                lda #ITEM_FISTS                 ;the panel looks nice
                sta invType

        ; Copy logo chars & clear screen

SpritesLoaded:  ldx #$00
CopyLogoLoop:   lda logoChars,x
                sta textChars+$300,x
                lda logoChars+$100,x
                sta textChars+$400,x
                lda logoChars+$200,x
                sta textChars+$500,x
                inx
                bne CopyLogoLoop
                lda #$00                        ;Show panel chars in gamescreen & position
                sta Irq1_Bg1+1                  ;the screen
                sta scrollY
                sta menuMode                    ;Reset in-game menu mode
                lda #$02
                sta screen
                lda #$0f
                sta scrollX
                ldx #$00
ClearScreenLoop:lda #$20
                sta screen1,x
                sta screen1+$100,x
                sta screen1+$200,x
                sta screen1+$270,x
                lda #$00
                sta colors,x
                sta colors+$100,x
                sta colors+$200,x
                sta colors+$270,x
                inx
                bne ClearScreenLoop

        ; Print logo to screen

                ldx #23
PrintLogoLoop:
M               set 0
                repeat 7
                lda logoScreen+M*24,x
                sta screen1+M*40+8+LOGOSTARTROW*40,x
M               set M+1
                repend
                dex
                bpl PrintLogoLoop
                lda #MUSIC_TITLE                        
                jsr PlaySong

TitleScreenParam:
                lda #0
                beq TitleTexts

        ; Save game

SaveGame:       lda #SAVE_GAME
                jmp LoadOrSaveGame
SaveGameExec:   jsr FadeOutText
                lda #<saveStateEnd
                sta zpDestLo
                lda #>saveStateEnd
                sta zpDestHi
                lda #<saveStateStart
                ldx #>saveStateStart
                jsr SaveFile

        ; Title text display

TitleTexts:     lda #0
TitleNextPage:  sta titlePage
                jsr FadeOutText
                jsr ClearText
                ldy titlePage
                lda titlePageTblLo,y
                ldx titlePageTblHi,y
                jsr PrintPage
TitleTextsLoop: jsr Update
                jsr GetFireClick
                bcs MainMenu
                jsr TitlePageDelay
                bcc TitleTextsLoop
                lda titlePage
                adc #$00
                cmp #NUMTITLEPAGES
                bcc TitleNextPage
                bcs TitleTexts

        ; Main menu
        
MainMenu:       jsr FadeOutText
                jsr ClearText
                lda #<txtMainMenu
                ldx #>txtMainMenu
                jsr PrintPage
MainMenuLoop:   lda #11
                sta temp1
                lda mainMenuChoice
                asl
                ldx #5
                ldy #TEXTSTARTROW+1
                jsr DrawChoiceArrow
                jsr Update
                lda mainMenuChoice
                ldx #2
                jsr TitleMenuControl
                sta mainMenuChoice
                jsr GetFireClick
                bcs MainMenuSelect
                jsr TitlePageDelayInteractive
                bcc MainMenuLoop
                jmp TitleTexts                  ;Page delay expired, return to title
MainMenuSelect: lda #SFX_SELECT
                jsr PlaySfx
                ldx mainMenuChoice
                lda mainMenuJumpTblLo,x
                sta MainMenuJump+1
                lda mainMenuJumpTblHi,x
                sta MainMenuJump+2
MainMenuJump:   jmp $0000

        ; Options menu
        
Options:        lda #0
                sta optionsMenuChoice
                jsr FadeOutText
                jsr ClearText
RefreshOptions: lda musicMode
                ldx #9
                jsr CopyOnOffText
                lda soundMode
                ldx #23
                jsr CopyOnOffText
                lda #<txtOptions
                ldx #>txtOptions
                jsr PrintPage
OptionsLoop:    lda #12
                sta temp1
                lda optionsMenuChoice
                asl
                ldx #5
                ldy #TEXTSTARTROW+1
                jsr DrawChoiceArrow
                jsr Update
                lda optionsMenuChoice
                ldx #2
                jsr TitleMenuControl
                sta optionsMenuChoice
                jsr GetFireClick
                bcs OptionsSelect
                jsr TitlePageDelayInteractive
                bcc OptionsLoop
                jmp TitleTexts                  ;Page delay expired, return to title
OptionsSelect:  ldx optionsMenuChoice
                cpx #2
                bcs OptionsGoBack
                lda musicMode,x
                eor #$01
                sta musicMode,x
                lda #SFX_SELECT
                jsr PlaySfx
                txa
                bne OptionsNoSongReset
                lda PS_CurrentSong+1            ;When music mode toggled, forcibly
                jsr ReplaySong                  ;restart the last played song
OptionsNoSongReset:
                jmp RefreshOptions
OptionsGoBack:  lda #SFX_SELECT
                jsr PlaySfx
                jmp MainMenu

        ; Load/save game
        
LoadGame:       lda #LOAD_GAME
LoadOrSaveGame: sta LoadOrSaveGameMode+1
                jsr FadeOutText
                jsr ClearText
                lda #TEXTSTARTROW
                sta temp2
                lda #<txtLoadSlot
                ldx #>txtLoadSlot
                ldy LoadOrSaveGameMode+1
                beq LoadTextOK
                lda #<txtSaveSlot
                ldx #>txtSaveSlot
LoadTextOK:     jsr PrintTextCenter
                lda #TEXTSTARTROW+2
                sta temp2
                jsr ScanSaves
                jsr ResetPage
LoadGameLoop:   lda #3
                sta temp1
                lda saveSlotChoice
                ldx #NUMSAVES+1
                ldy #TEXTSTARTROW+2
                jsr DrawChoiceArrow
                jsr Update
                lda saveSlotChoice
                ldx #NUMSAVES
                jsr TitleMenuControl
                sta saveSlotChoice
                jsr GetFireClick
                bcc LoadGameLoop
                lda #SFX_SELECT
                jsr PlaySfx
                lda saveSlotChoice
                cmp #NUMSAVES
                bcs LoadGameCancel              ;Cancel load/save (TODO: save needs confirm step as data will be lost)
                ldx #F_SAVE
                jsr MakeFileName
LoadOrSaveGameMode:
                lda #$00
                beq LoadGameExec
                jmp SaveGameExec
LoadGameExec:   jsr OpenFile                    ;Load the savegame now
                lda #<saveStateStart
                ldx #>saveStateStart
                jsr ReadSaveFile
                bcc LoadGameLoop                ;Fail
                lda InitFastLoad+1              ;Fade out screen, unless in slowload mode
                cmp #$01
                beq LoadSkipFade
                jsr FadeOutAll
LoadSkipFade:   jsr RestartCheckpoint           ;Success, start loaded game
                jmp StartMainLoop
LoadGameCancel: jmp TitleTexts

        ; Start new game

StartGame:      jsr FadeOutAll
InitPlayer:     lda #0
                ldx #NUM_SKILLS-1
IP_XPSkillLoop: sta xpLo,x
                sta plrSkills,x
                dex
                bpl IP_XPSkillLoop
                ldx #MAX_INVENTORYITEMS-1
IP_InvLoop:     sta invType,x
                sta invCount,x
                sta invMag,x
                dex
                bpl IP_InvLoop
                sta itemIndex
                sta levelUp
                lda #<FIRST_XPLIMIT
                sta xpLimitLo
                lda #1
                sta xpLevel
                sta invType                     ;1 = fists
                lda #$00
                sta levelNum                    ;Set startposition & level
                sta saveD
                sta saveYL
                lda #$80
                sta saveXL
                lda #6
                sta saveXH
                lda #2
                sta saveYH
                lda #ACT_PLAYER
                sta saveT
                jsr RCP_CreatePlayer
                jsr SaveCheckpoint              ;Save first checkpoint immediately
                jmp StartMainLoop

        ; Update controls, text & logo fade

Update:         jsr GetControls
                jsr FinishFrame_NoScroll
                jsr WaitBottom
                lda keyType
                bmi UC_NoCheat
                ldx cheatIndex
                cmp cheatString,x
                beq UC_CheatCharOK
                ldx #$ff
UC_CheatCharOK: inx
                cpx #CHEATSTRINGLENGTH
                bcc UC_CheatNotDone
                ldx #$00
                lda DA_HealthRechargeDelay      ;Transform LDY into RTS in player damage routine
                eor #$c0
                sta DA_HealthRechargeDelay
                inc Irq1_Bg1+1
                ldy #$10
UC_Delay:       inx
                bne UC_Delay
                dey
                bne UC_Delay
                dec Irq1_Bg1+1
UC_CheatNotDone:stx cheatIndex
UC_NoCheat:     lda textFadeDir
                beq UC_TextDone
                clc
                adc textFade
                sta textFade
                cmp #$ff
                bne UC_TextNotOverLow
                inc textFade
                beq UC_StopTextFade
UC_TextNotOverLow: 
                cmp #16
                bne UC_TextNotOverHigh
                dec textFade
UC_StopTextFade:lda #0
                sta textFadeDir
UC_TextNotOverHigh:
                lda textFade
                lsr
                lsr
                tay
                lda textFadeTbl,y
                ldx #39
UC_UpdateTextLoop:
M               set 0
                repeat NUMTEXTROWS
                sta colors+TEXTSTARTROW*40+M*40,x
M               set M+1
                repend
                dex
                bpl UC_UpdateTextLoop
UC_TextDone:    lda logoFadeDir
                bne UC_HasLogoFade
                rts
UC_HasLogoFade: clc
                adc logoFade
                sta logoFade
                cmp #$ff
                bne UC_LogoNotOverLow
                inc logoFade
                beq UC_StopLogoFade
UC_LogoNotOverLow:
                cmp #16
                bne UC_LogoNotOverHigh
                dec logoFade
UC_StopLogoFade:lda #0
                sta logoFadeDir
UC_LogoNotOverHigh:
                lda logoFade
                lsr
                lsr
                tax
                lda logoFadeBg2Tbl,x
                sta Irq1_Bg2+1
                lda logoFadeBg3Tbl,x
                sta Irq1_Bg3+1
                lda logoFade
                asl
                and #$f8
                sta temp1
                ldx #23
UC_UpdateLogoLoop:
M               set 0
                repeat 7
                lda logoColors+M*24,x
                adc temp1
                tay
                lda logoFadeCharTbl-8,y
                sta colors+M*40+8+LOGOSTARTROW*40,x
M               set M+1
                repend
                dex
                bpl UC_UpdateLogoLoop
UC_LogoDone:    rts

        ; Wait until text faded out

FadeOutAll:     lda #-1
                sta logoFadeDir
FadeOutText:    lda #-1
                sta textFadeDir
FOT_Wait:       jsr Update
                lda textFade
                bne FOT_Wait
                rts
        
        ; Clear text rows
        
ClearText:      lda #$20
                ldx #39
ClearTextLoop:
M               set 0
                repeat NUMTEXTROWS
                sta screen1+TEXTSTARTROW*40+M*40,x
M               set M+1
                repend
                dex
                bpl ClearTextLoop
                rts

        ; Print null-terminated text

PrintText:      sta zpSrcLo
                stx zpSrcHi
PrintTextContinue:
                ldy temp2
                jsr GetRowAddress
                lda temp1
                jsr Add8
                ldy #$00
PrintTextLoop:  lda (zpSrcLo),y
                beq PrintTextDone
                sta (zpDestLo),y
                iny
                bne PrintTextLoop
PrintTextDone:  iny
                tya
                ldx #<zpSrcLo
                jmp Add8

        ; Print centered text

PrintTextCenter:sta zpSrcLo
                stx zpSrcHi
PrintTextCenterContinue:
                lda #20
                sta temp1
                ldy #$00
PTC_Loop:       lda (zpSrcLo),y
                beq PrintTextContinue
                iny
                lda (zpSrcLo),y
                beq PrintTextContinue
                iny
                dec temp1
                bpl PTC_Loop

        ; Print choice arrow
        
DrawChoiceArrow:sta zpSrcLo
                stx zpSrcHi
                jsr GetRowAddress
                ldx #0
                ldy temp1
DCA_Loop:       lda #$20
                cpx zpSrcLo
                bne DCA_NoArrow
                lda #22
DCA_NoArrow:    sta (zpDestLo),y
                lda zpDestLo
                clc
                adc #40
                sta zpDestLo
                bcc DCA_NextRowOK
                inc zpDestHi
DCA_NextRowOK:  inx
                cpx zpSrcHi
                bcc DCA_Loop
                rts

        ; Copy "on" or "off" text

CopyOnOffText:  tay
COOT_Loop:      lda txtOnOff,y     
                sta txtMusic,x
                inx
                iny
                iny
                cpy #6
                bcc COOT_Loop
                rts

        ; Get address of text row Y

GetRowAddress:  lda #40
                ldx #<zpDestLo
                jsr MulU
                lda zpDestHi
                ora #>screen1
                sta zpDestHi
                rts

        ; Scan savegames and print their descriptions

ScanSaves:      lda #0
                sta temp3
                ldx #1                          ;Always select "continue" in main menu after load/save
                stx mainMenuChoice
                ldx saveSlotChoice              ;If "cancel" selected, select first slot instead
                cpx #NUMSAVES
                bne ScanSaveLoop
                sta saveSlotChoice
ScanSaveLoop:   ldx #F_SAVE
                jsr MakeFileName
                jsr OpenFile
                lda #<saveStateBuffer
                ldx #>saveStateBuffer
                jsr ReadSaveFile
                lda #5
                sta temp1
                bcs GetSaveDescription
                lda #<txtEmpty
                ldx #>txtEmpty
                jsr PrintText
SaveDone:       inc temp2
                inc temp3
                lda temp3
                cmp #NUMSAVES
                bcc ScanSaveLoop
                lda #<txtCancel
                ldx #>txtCancel
                jmp PrintText
GetSaveDescription:
                lda #<saveStateBuffer           ;Level name
                ldx #>saveStateBuffer
                jsr PrintText
                lda #$20                        ;Level / XP / XP limit
                sta txtSaveLevel
                sta txtSaveLevel+1
                lda saveStateBuffer+21
                jsr ConvertToBCD8
                ldx #80
                jsr PrintBCDDigitsNoZeroes
CopyLevelText:  lda screen1+23*40-1,x
                sta txtSaveLevel-81,x
                dex
                cpx #81
                bcs CopyLevelText
                lda saveStateBuffer+19
                ldy saveStateBuffer+20
                jsr ConvertToBCD16
                ldx #80
                jsr Print3BCDDigits
                lda #"/"
                sta screen1+25*40+3
                lda saveStateBuffer+22
                ldy saveStateBuffer+23
                jsr ConvertToBCD16
                ldx #84
                jsr Print3BCDDigits
CopyXPText:     lda screen1+23*40-1,x
                sta txtSaveXP-81,x
                dex
                cpx #81
                bcs CopyXPText
                lda #22
                sta temp1
                lda #<txtSaveLevelAndXP
                ldx #>txtSaveLevelAndXP
                jsr PrintText
                jmp SaveDone

        ; Read an opened savefile. C=1 if read to the end

ReadSaveFile:   sta zpDestLo
                stx zpDestHi
                ldy #$00
                ldx #$00
RSF_Loop:       jsr GetByte
                bcs RSF_End
                sta (zpDestLo),y
                iny
                bne RSF_Loop
                inc zpDestHi
                inx
                bne RSF_Loop
RSF_End:        cpx #>(saveStateEnd-saveStateStart)
                bcc RSF_Empty
                bne RSF_NotEmpty
                cpy #<(saveStateEnd-saveStateStart)
RSF_Empty:
RSF_NotEmpty:   rts

        ; Pick choice by joystick up/down
        
TitleMenuControl:
                tay
                stx temp6
                ldx moveDelay
                beq TMC_NoDelay
                dec moveDelay
                rts
TMC_NoDelay:    lda joystick
                lsr
                bcc TMC_NotUp
                dey
                bpl TMC_HasMove
                ldy temp6
TMC_HasMove:    lda #SFX_SELECT
                jsr PlaySfx
                ldx #TITLE_MOVEDELAY
                lda joystick
                cmp prevJoy
                bne TMC_NormalDelay
                dex
                dex
                dex
TMC_NormalDelay:stx moveDelay
TMC_NoMove:     tya
                rts
TMC_NotUp:      lsr
                bcc TMC_NoMove
                iny
                cpy temp6
                bcc TMC_HasMove
                beq TMC_HasMove
                ldy #$00
                beq TMC_HasMove

        ; Title delay counting

TitlePageDelayInteractive:
                lda joystick                    ;Reset delay if joystick moved
                bne ResetTitlePageDelay
TitlePageDelay: inc titlePageDelayLo
                bne TPD_NotOver
                inc titlePageDelayHi
TPD_NotOver:    lda titlePageDelayHi
                cmp #>TITLE_PAGEDELAY
                bne TPD_Done
                lda titlePageDelayLo
                cmp #<TITLE_PAGEDELAY
TPD_Done:       rts

        ; Print page
        
PrintPage:      ldy #TEXTSTARTROW
                sty temp2
                jsr PrintTextCenter
                inc temp2
TitleRowLoop:   jsr PrintTextCenterContinue
                inc temp2
                lda temp2
                cmp #TEXTSTARTROW+7
                bcc TitleRowLoop

        ; Reset title delay, set text to fade in

ResetPage:      lda #1
                sta textFadeDir
ResetTitlePageDelay:
                lda #0
                sta titlePageDelayLo
                sta titlePageDelayHi
                rts

logoFade:       dc.b 0
textFade:       dc.b 0
logoFadeDir:    dc.b 1
textFadeDir:    dc.b 1
moveDelay:      dc.b 0
titlePage:      dc.b 0
titlePageDelayLo:
                dc.b 0
titlePageDelayHi:
                dc.b 0
mainMenuChoice: dc.b 0
optionsMenuChoice:
                dc.b 0
cheatIndex:     dc.b 0

txtCredits:     dc.b "A COVERT BITOPS PRODUCTION IN 2012",0
                dc.b 0
                dc.b 0
                dc.b "CODE, GRAPHICS & AUDIO BY LASSE __RNI",0
                dc.b 0
                dc.b 0
                dc.b "PRESS FIRE FOR MENU",0

txtInstructions:dc.b "USE JOYSTICK IN PORT 2 AND KEYS",0
                dc.b 0
                dc.b ", .     SELECT ITEM",0
                dc.b 0
                dc.b "R       RELOAD     ",0
                dc.b 0
                dc.b "RUNSTOP PAUSE MENU ",0

txtMainMenu:    dc.b 0
                dc.b "START NEW GAME",0
                dc.b 0
                dc.b "CONTINUE GAME ",0
                dc.b 0
                dc.b "OPTIONS       ",0
                dc.b 0

txtOptions:     dc.b 0
txtMusic:       dc.b "MUSIC       ",0
                dc.b 0
txtSound:       dc.b "SOUND FX    ",0
                dc.b 0
                dc.b "BACK        ",0
                dc.b 0

txtOnOff:       dc.b "O FOFN"
txtLoadSlot:    dc.b "CONTINUE FROM SAVE",0
txtSaveSlot:    dc.b "SAVE GAME TO SLOT",0
txtEmpty:       dc.b "EMPTY SLOT",0
txtCancel:      dc.b "CANCEL",0
txtSaveLevelAndXP:
                dc.b "LV."
txtSaveLevel:   dc.b "   "
txtSaveXP:      dc.b "   /   ",0,0

cheatString:    dc.b KEY_T,KEY_A,KEY_C,KEY_G,KEY_N,KEY_O,KEY_L

mainMenuJumpTblLo:
                dc.b <StartGame
                dc.b <LoadGame
                dc.b <Options

mainMenuJumpTblHi:
                dc.b >StartGame
                dc.b >LoadGame
                dc.b >Options
                
titlePageTblLo: dc.b <txtCredits
                dc.b <txtInstructions

titlePageTblHi: dc.b >txtCredits
                dc.b >txtInstructions

logoFadeBg2Tbl: dc.b $00,$00,$06,$0e
logoFadeBg3Tbl: dc.b $00,$06,$0e,$03
logoFadeCharTbl:dc.b $08,$08,$08,$08,$08,$08,$08,$08
                dc.b $08,$0e,$08,$08,$08,$08,$08,$08
                dc.b $08,$0b,$08,$0e,$08,$08,$08,$0b
                dc.b $08,$09,$0a,$0b,$0c,$0d,$0e,$0f

textFadeTbl:    dc.b $00,$06,$03,$01

logoChars:      incbin bg/logo.chr
logoScreen:     incbin bg/logoscr.bin
logoColors:     incbin bg/logocol.bin

                CheckScriptEnd