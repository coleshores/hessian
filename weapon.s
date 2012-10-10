AIM_UP          = 0
AIM_DIAGONALUP  = 1
AIM_HORIZONTAL  = 2
AIM_DIAGONALDOWN = 3
AIM_DOWN        = 4
AIM_NONE        = $ff

WD_BITS         = 0
WD_MINAIM       = 1
WD_MAXAIM       = 2
WD_ATTACKDELAY  = 3
WD_BULLETTYPE   = 4
WD_DAMAGE       = 5
WD_DURATION     = 6
WD_BULLETSPEED  = 7
WD_SPEEDTABLEOFFSET = 8
WD_SFX          = 9
WD_IDLEFR       = 10
WD_IDLEFRLEFT   = 11
WD_PREPAREFR    = 12
WD_PREPAREFRLEFT = 13
WD_ATTACKFR     = 14
WD_ATTACKFRLEFT = 19
WD_RELOADDELAY  = 24
WD_RELOADSFX    = 25
WD_RELOADDONESFX = 26

WDB_NONE        = 0
WDB_NOWEAPONSPRITE = 1
WDB_BULLETDIRFRAME = 2
WDB_FLICKERBULLET = 4
WDB_THROW       = 8
WDB_MELEE       = 16

NO_MODIFY       = 8

        ; Actor attack routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

AH_NoAttack:    lda actAttackD,x
                beq AH_SetIdleWeaponFrame
                bpl AH_DecrementDelay      ;Break failed or incomplete melee attack
                lda #$01
                sta actAttackD,x    
AH_DecrementDelay:
                dec actAttackD,x
AH_SetIdleWeaponFrame:
                lda actF1,x
                sta actF2,x                    
                cmp #FR_CLIMB
                bcs AH_NoWeaponFrame
                ldy #WD_IDLEFR
AH_SetPrepareWeaponFrame:
                lda temp3
                lsr
                bcs AH_NoWeaponFrame
                lda actD,x
                bpl AH_NoAttackRight
                iny
AH_NoAttackRight:
                lda (wpnLo),y
                bpl AH_WeaponFrameDone
AH_NoWeaponFrame:
                lda #$ff
AH_WeaponFrameDone:
                sta actWpnF,x
                rts

AttackHuman:    ldy actWpn,x
                beq AH_NoWeaponFrame
                lda wpnTblLo-1,y
                sta wpnLo
                lda wpnTblHi-1,y
                sta wpnHi
                ldy #WD_BITS
                lda (wpnLo),y
                sta temp3
                txa
                bne AH_NotPlayer
                ldy itemIndex                   ;Check for ammo & reloading
                lda magazineSize
                bmi AH_AmmoCheckOK              ;Melee weapon, no ammo check / no reload
                bne AH_CheckFirearm
                lda invCount,y                  ;Consumable item: no attack if out of ammo
                bne AH_AmmoCheckOK
                beq AH_NoAttack
AH_CheckFirearm:lda invMag,y                    ;Check if reload ongoing
                bpl AH_NotReloading
                lda actAttackD+ACTI_PLAYER
                cmp #$01
                bcs AH_NoAttack                 ;While ongoing, keep weapon in down position
                lda invCount,y                  ;Finish reloading
                cmp magazineSize
                bcc AH_ReloadSizeOK
                lda magazineSize
AH_ReloadSizeOK:sta invMag,y
                ldy #WD_RELOADDONESFX
                lda (wpnLo),y
                jsr PlaySfx
AH_RedrawAmmoNoAttack:
                jsr SetPanelRedrawAmmo
                jmp AH_NoAttack
AH_NotReloading:bne AH_AmmoCheckOK
AH_EmptyMagazine:
                lda invCount,y                  ;Initiate reloading if mag empty and reserve left
                beq AH_FirearmEmpty
                lda actAttackD+ACTI_PLAYER      ;Do not start reloading before attack delay
                bne AH_AmmoCheckOK              ;zero
                lda #$ff
                sta invMag,y
                ldy #WD_RELOADDELAY
                lda (wpnLo),y
AH_ReloadDelayBonus:
                ldy #NO_MODIFY
                jsr ModifyDamage
                sta actAttackD+ACTI_PLAYER
                ldy #WD_RELOADSFX
                lda (wpnLo),y
                jsr PlaySfx
                jmp AH_RedrawAmmoNoAttack
AH_NoAttack2:   jmp AH_NoAttack
AH_FirearmEmpty:lda #$01                        ;If no bullets, set a constant attack delay to
                sta actAttackD+ACTI_PLAYER      ;prevent firing but allow brandishing empty weapon
AH_AmmoCheckOK: lda menuMode                    ;If player is in any menu mode, do not attack
                bne AH_NoAttack2
AH_NotPlayer:   lda actPrevCtrl,x               ;Require fire pressed also in previous controls
                and #JOY_FIRE                   ;to "debounce" erroneous attacks
                beq AH_NoAttack2
                lda actCtrl,x
                cmp #JOY_FIRE
                bcc AH_NoAttack2
                ldy actF1,x
                cpy #FR_DIE
                bcs AH_NoAttack2
                and #JOY_LEFT|JOY_RIGHT         ;If left/right attack, turn actor
                beq AH_NoTurn2
                lsr
                lsr
                lsr
                ror
                sta actD,x
AH_NoTurn2:     lda actCtrl,x
AH_NoTurn:      and #JOY_UP|JOY_DOWN|JOY_LEFT|JOY_RIGHT
                tay
                lda attackTbl,y
                bmi AH_NoAttack2
                ldy #WD_MINAIM                  ;Check that aim direction is OK for weapon
                cmp (wpnLo),y                   ;in question, limit if necessary
                bcs AH_DirOk1
                lda (wpnLo),y
AH_DirOk1:      iny
                cmp (wpnLo),y
                bcc AH_DirOk2
                lda (wpnLo),y
AH_DirOk2:      pha
                clc
                adc #FR_ATTACK
                sta actF2,x
                pla
                ldy actD,x
                bpl AH_AimRight
                adc #5
AH_AimRight:    sta temp1
                adc #WD_ATTACKFR
                tay
                lda temp3
                lsr
                lda #$ff
                bcs AH_NoWeaponFrame2
                lda (wpnLo),y
AH_NoWeaponFrame2:
                sta actWpnF,x
                lda actAttackD,x
                beq AH_CanFire
                dec actAttackD,x                ;Decrement delay / progress the melee animation
                bmi AH_MeleeAnimation
                lda temp3
                and #WDB_THROW|WDB_MELEE
                beq AH_CannotFire
                bne AH_MeleeIdle
AH_MeleeFailed: inc actAttackD,x                ;If melee failed, restore previous counter value
AH_MeleeIdle:   jmp AH_SetIdleWeaponFrame
AH_MeleeStrike:
AH_CannotFire:  rts

AH_CanFire:     lda temp3                       ;Check for melee/throw weapon and play its
                and #WDB_THROW|WDB_MELEE        ;animation, else go directly to firing
                beq AH_SpawnBullet
AH_ThrownOrMelee:
                lda #$84                        ;Setup the melee animation counter
                sta actAttackD,x
AH_MeleePrepare:lda #FR_PREPARE                 ;Show prepare frame for hands & weapon
                ldy temp3
                cpy #WDB_MELEE
                adc #$00
                sta actF2,x
                ldy #WD_PREPAREFR
                jmp AH_SetPrepareWeaponFrame
AH_MeleeAnimation:
                lda actAttackD,x                ;Check for finishing animation, or reaching
                cmp #$83                        ;"failed to attack" state in which the attack
                bcs AH_MeleePrepare             ;must be released before retrying
                cmp #$81
                bcc AH_MeleeFailed
                bne AH_MeleeStrike              ;Show strike frame just before spawning bullet

AH_SpawnBullet: jsr GetBulletOffset
                bcc AH_CannotFire
                txa                             ;Check whether to use player or NPC bullet actor
                bne AH_IsPlayer                 ;indices
                lda #ACTI_FIRSTNPCBULLET
                ldy #ACTI_LASTNPCBULLET
                bne AH_IsNpc
AH_IsPlayer:    lda #ACTI_FIRSTPLRBULLET
                ldy #ACTI_LASTPLRBULLET
AH_IsNpc:       jsr GetFreeActor
                bcc AH_CannotFire
                sty temp2
                ldy #WD_BULLETTYPE
                lda (wpnLo),y
                ldy temp2
                jsr SpawnWithOffset
                lda temp3
                and #WDB_BULLETDIRFRAME
                beq AH_BulletFrameDone
                lda temp1
AH_BulletFrameDone:
                sta actF1,y
                ldy #WD_BULLETSPEED
                lda (wpnLo),y
                sta temp4
                iny
                lda temp1
                clc
                adc (wpnLo),y
                tay
                sty zpSrcLo
                lda bulletXSpdTbl,y
                ldy temp4
                ldx #temp5
                jsr MulU
                ldy zpSrcLo
                lda bulletYSpdTbl,y
                ldy temp4
                ldx #temp7
                jsr MulU
                lda zpSrcLo
                ldx temp2
                jsr GetCharInfo                 ;Check if spawned inside wall
                and #CI_OBSTACLE                ;and destroy immediately in that case
                bne AH_InsideWall
                lda temp5                       ;Set speed
                sta actSX,x
                lda temp7
                sta actSY,x
                jsr InitActor                   ;Set collision size
                lda #ORG_NONE                   ;Bullets have no leveldata origin
                sta actLvlOrg,x
                ldy #WD_DAMAGE                  ;Set duration and damage
                lda (wpnLo),y
                sta actHp,x
                sta temp8
                iny
                lda (wpnLo),y
                sta actTime,x
                lda temp3
                and #WDB_FLICKERBULLET
                beq AH_NoBulletFlicker
                txa
                jsr GetFlickerColorOverride
                sta actC,x
AH_NoBulletFlicker:
                ldx actIndex                    ;If player, decrement ammo and apply skill bonus
                bne AH_NoAmmoDecrement
                lda magazineSize
                bmi AH_PlayerMeleeBonus
                ldy itemIndex
                lda #$01
                jsr DecreaseAmmo
                lda magazineSize
                beq AH_PlayerMeleeBonus
AH_PlayerFirearmBonus:
                ldy #NO_MODIFY
                bpl AH_PlayerBonusCommon
AH_PlayerMeleeBonus:
                ldy #NO_MODIFY
AH_PlayerBonusCommon:
                lda temp8
                jsr ModifyDamage
                ldy temp2
                sta actHp,y
AH_NoAmmoDecrement:
                ldy #WD_ATTACKDELAY
                lda (wpnLo),y
                sta actAttackD,x
                ldy #WD_SFX
                lda (wpnLo),y
                jmp PlaySfx
AH_InsideWall:  jsr RemoveActor
                ldx actIndex
                rts
                
        ; Find spawn offset for bullet
        ;
        ; Parameters: X actor index
        ; Returns: C=1 success (temp5-temp6 X offset, temp7-temp8 Y offset), C=0 failure (sprites unloaded)
        ; Modifies: A,Y,loader temp regs

GetBulletOffset:ldy actT,x
                lda actDispTblLo-1,y            ;Get actor display structure address
                sta actLo
                lda actDispTblHi-1,y
                sta actHi
                ldy #
                sty temp5
                sty temp7
                clc
                lda (actLo),y                   ;Get display type
                bmi GBO_Humanoid
                sta zpBitsLo                    ;Sprite counter
                iny
                lda (actLo),y                   ;Sprite file
                sta GBO_NormalSprFile+1
                lda actF1,x
                ldy actD,x
                bpl GBO_NormalRight
                ldy #AD_LEFTFRADD               ;Add left frame offset if necessary
                adc (actLo),y
GBO_NormalRight:adc #AD_FRAMES
GBO_NormalLoop: sta zpBitsHi                    ;Frame index
                tay
                lda (actLo),y
GBO_NormalSprFile:
                ldy #$00
                jsr GBO_Sub
                ldy #AD_NUMFRAMES
                lda zpBitsHi                    ;Advance framepointer
                clc
                adc (actLo),y
                dec zpBitsLo
                bpl GBO_NormalLoop
                bmi GBO_Common

GBO_Humanoid:   jsr DA_GetHumanFrames
                dey
                lda (actLo),y
                tay
                lda DA_HumanFrame1+1
                jsr GBO_Sub
                ldy #ADH_SPRFILE2
                lda (actLo),y
                tay
                lda DA_HumanFrame2+1
                jsr GBO_Sub
                lda actWpnF,x                   ;If no weapon frame, spawn projectile from the hand
                bmi GBO_Common
                ldy #C_WEAPON
                jsr GBO_Sub
GBO_Common:     lda #$00
                asl temp5
                bcc GBO_XPos
                lda #$ff
GBO_XPos:       rol
                asl temp5
                rol
                asl temp5
                rol
                sta temp6
                lda #$00
                asl temp7
                bcc GBO_YPos
                lda #$ff
GBO_YPos:       rol
                asl temp7
                rol
                asl temp7
                rol
                sta temp8
                sec
                rts

GBO_Sub:        pha
                lda fileHi,y
                beq GBO_Fail
                sta zpSrcHi
                lda fileLo,y
                sta zpSrcLo
                pla
                asl
                tay
                lda (zpSrcLo),y
                sta frameLo
                iny
                lda (zpSrcLo),y
                sta frameHi
                ldy #SPRH_CONNECTSPOTY
                lda temp7
                adc (frameLo),y
                dey
                sec
                sbc (frameLo),y
                sta temp7
                dey
                lda temp5
                clc
                adc (frameLo),y
                dey
                sec
                sbc (frameLo),y
                sta temp5
                rts
GBO_Fail:       pla
                pla
                pla
                clc
                rts

        ; Modify damage
        ;
        ; Parameters: A damage Y multiplier (8 = unmodified)
        ; Returns: A modified damage
        ; Modifies: A,Y,loader temp vars

ModifyDamage:   ora #$00                        ;Zero in - zero out
                beq MD_Zero
                stx zpBitsLo
                ldx #zpSrcLo
                jsr MulU
                lda zpSrcLo
                lsr zpSrcHi                     ;Divide by 8
                ror
                lsr zpSrcHi
                ror
                lsr zpSrcHi
                ror
                bne MD_NotZero
                lda #$01                        ;Never reduce to zero
MD_NotZero:     ldx zpBitsLo
MD_Zero:        rts
