FR_STAND        = 0
FR_WALK         = 1
FR_JUMP         = 9
FR_DUCK         = 12
FR_ENTER        = 14
FR_CLIMB        = 15
FR_DIE          = 19
FR_ROLL         = 22
FR_SWIM         = 28
FR_PREPARE      = 32
FR_ATTACK       = 34

DEATH_DISAPPEAR_DELAY = 75
DEATH_FLICKER_DELAY = 25
DEATH_HEIGHT    = -3                            ;Ceiling check height for dead bodies
DEATH_ACCEL     = 6
DEATH_YSPEED    = -5*8
DEATH_MAX_XSPEED = 6*8
DEATH_BRAKING   = 6
DEATH_WATER_YBRAKING = 3                        ;Extra braking for corpses in water

WATER_XBRAKING = 3
WATER_YBRAKING = 3

HUMAN_MAX_YSPEED = 6*8

DAMAGING_FALL_DISTANCE = 4
MIN_ROLLSAVE_SPEED = 16

FIRST_XPLIMIT   = 100
NEXT_XPLIMIT    = 50
MAX_LEVEL       = 16
MAX_SKILL       = 3
NUM_SKILLS      = 5

INITIAL_GROUNDACC = 5
INITIAL_INAIRACC = 1
INITIAL_GROUNDBRAKE = 6
INITIAL_JUMPSPEED = 40
INITIAL_CLIMBSPEED = 84
INITIAL_HEALTHRECHARGETIMER = 2

HEALTHRECHARGETIMER_RESET = $e0

DIFFICULTY_EASY = 0
DIFFICULTY_MEDIUM = 1
DIFFICULTY_HARD = 2

EASY_DMGMULTIPLIER_REDUCE = 2

DROWNING_TIMER = 1
DROWNING_TIMER_REPEAT = $f0

        ; Player update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MovePlayer:     lda actCtrl+ACTI_PLAYER         ;Get new joystick controls
                sta actPrevCtrl+ACTI_PLAYER
                ldy #$00
                cpy menuMode                    ;When in inventory, no controls (idle)
                bne MP_StoreControlMask
                ldy actF1+ACTI_PLAYER
                cpy #FR_DUCK+1
                bne MP_NoDuckFirePrevent
                cmp #JOY_DOWN                   ;Prevent fire+down immediately after ducking
                bne MP_NoDuckFirePrevent        ;(need to release down direction first)
                lda joystick
                cmp #JOY_DOWN+JOY_FIRE
                bne MP_NoDuckFirePrevent
                ldy #$ff-JOY_FIRE
                bne MP_StoreControlMask
MP_NoDuckFirePrevent:
                lda joystick
                cmp #JOY_DOWN+JOY_FIRE
                beq MP_ControlMask
                ldy #$ff
MP_StoreControlMask:
                sty MP_ControlMask+1
MP_ControlMask: and #$ff
                sta actCtrl+ACTI_PLAYER
                cmp #JOY_FIRE
                bcc MP_NewMoveCtrl
                and #$0f                        ;When fire held down, eliminate the opposite
                tay                             ;directions from the previous move control
                lda moveCtrlAndTbl,y
                ldy actF1+ACTI_PLAYER
                cpy #FR_DUCK+1                  ;When already ducked, keep the down control
                bne MP_NotDucked
                ora #JOY_DOWN
MP_NotDucked:   and actMoveCtrl+ACTI_PLAYER
MP_NewMoveCtrl: sta actMoveCtrl+ACTI_PLAYER
                jsr MoveHuman                   ;Move player
MP_Scroll:      jsr GetActorCharCoords          ;Then check scrolling
                cmp #SCRCENTER_X-1
                bcs MP_NotLeft1
                dex
MP_NotLeft1:    cmp #SCRCENTER_X
                bcs MP_NotLeft2
                dex
MP_NotLeft2:    cmp #SCRCENTER_X+1
                bcc MP_NotRight1
                inx
MP_NotRight1:   cmp #SCRCENTER_X+2
                bcc MP_NotRight2
                inx
MP_NotRight2:   stx scrollSX
                ldx #$00
                cpy #SCRCENTER_Y-2
                bcs MP_NotUp1
                dex
MP_NotUp1:      cpy #SCRCENTER_Y
                bcs MP_NotUp2
                dex
MP_NotUp2:      cpy #SCRCENTER_Y+1
                bcc MP_NotDown1
                inx
MP_NotDown1:    cpy #SCRCENTER_Y+3
                bcc MP_NotDown2
                inx
MP_NotDown2:    stx scrollSY
MP_SetWeapon:   ldy itemIndex                   ;Set player weapon from inventory
                ldx invType,y
                lda itemMagazineSize-1,x        ;Mag size needed for weapon routines,
                sta magazineSize                ;cache it now
                cpx #ITEM_FIRST_NONWEAPON
                bcc MP_WeaponOK
                ldx #ITEM_NONE
MP_WeaponOK:    stx actWpn+ACTI_PLAYER
                ldx #ACTI_PLAYER
                jmp AttackHuman                 ;Finally handle attacks

        ; Humanoid character move routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MH_DeathAnim:   lda #DEATH_HEIGHT               ;Actor height for ceiling check
                sta temp4
                lda #DEATH_ACCEL
                ldy #HUMAN_MAX_YSPEED
                jsr MoveWithGravity
                lsr
                bcs MH_DeathGrounded            ;If grounded, animate faster
                and #MB_HITWALL/2               ;If hit wall, zero X-speed
                beq MH_DeathNoHitWall
                lda #$00
                sta actSX,x
MH_DeathNoHitWall:
                lda #$06
                ldy #FR_DIE+1
                bne MH_DeathAnimDelay
MH_DeathGrounded:
                lda #DEATH_BRAKING
                jsr BrakeActorX
                lda #$02
                ldy #FR_DIE+2
MH_DeathAnimDelay:
                sty temp1
                jsr AnimationDelay
                bcc MH_DeathAnimDone
                lda actF1,x
                cmp temp1
                bcs MH_DeathAnimDone
                adc #$01
                sta actF1,x
                sta actF2,x
MH_DeathAnimDone:
                dec actTime,x
                bmi MH_DeathRemove
                lda actTime,x
                cmp #DEATH_FLICKER_DELAY
                bne MH_DeathDone
                jsr GetFlickerColorOverride
                ora actC,x
                sta actC,x
MH_DeathDone:   rts
MH_DeathRemove: jmp RemoveActor

MoveHuman:      lda actMB,x
                sta temp1                       ;Movement state bits
                and #MB_INWATER
                beq MH_NotInWater
                lda #WATER_XBRAKING             ;Global water braking, both for alive & dead characters
                jsr BrakeActorX
                lda actF1,x                     ;Allow jump in water to begin without braking
                cmp #FR_JUMP                    ;(so that can get out of water)
                beq MH_NoYBraking
                lda actHp,x
                cmp #$01
                lda #WATER_YBRAKING
                bcs MH_NoFloating
                adc #DEATH_WATER_YBRAKING       ;Extra buoyancy for corpses
MH_NoFloating:  jsr BrakeActorY
MH_NoYBraking:  lda lvlWaterDamage              ;Check if water in this level is damaging
                bne MH_HasDamagingWater
                lda #-3                         ;If water itself is not damaging, check drowning
                jsr GetCharInfoOffset           ;(head under water)
                and #CI_WATER
                clc
                beq MH_ResetDrowningTimer
MH_NoDrowningTimerReset:
                lda #DROWNING_TIMER
MH_HasDamagingWater:
                clc
                adc actWaterDamage,x
MH_ResetDrowningTimer:
                sta actWaterDamage,x
                bcc MH_NotInWater
                lda #DMG_WATER
                jsr DamageSelf
                lda lvlWaterDamage
                bne MH_NotInWater
                txa
                bne MH_NotPlayerDrowning
MH_PlayerDrowningTimerRepeat:
                lda #DROWNING_TIMER_REPEAT      ;Drowning is faster after initial damage
                skip2
MH_NotPlayerDrowning:
                lda #DROWNING_TIMER_REPEAT
                sta actWaterDamage,x
MH_NotInWater:  lda actD,x
                sta MH_OldDir+1
                ldy #AL_SIZEUP                  ;Set size up based on currently displayed
                lda (actLo),y                   ;frame
                ldy actF1,x
                sec
                sbc humanSizeReduceTbl,y
                sta actSizeU,x
                lda #$00                        ;Roll flag
                sta temp2
                ldy #AL_MOVEFLAGS
                lda (actLo),y
                sta temp3                       ;Movement capability flags
                iny
                lda (actLo),y
                sta temp4                       ;Movement speed
                lda temp1
                lsr                             ;Check after fall-effects (forced duck, damage)
                bcc MH_NoFallCheck
                ldy actFall,x
                beq MH_NoFallCheck
                and #MB_LANDED/2                ;Falling damage applied right after landing
                beq MH_NoFallDamage
                lda temp3                       ;Possibility to reduce damage by rolling
                and #AMF_ROLL
                beq MH_NoRollSave
                lda actSX,x
                adc #MIN_ROLLSAVE_SPEED-1       ;C=1 here
                cmp #MIN_ROLLSAVE_SPEED*2       ;Must have sufficient X-speed for roll
                bcc MH_NoRollSave
                lda actD,x
                asl
                lda #JOY_DOWN|JOY_RIGHT
                bcc MH_RollSaveRight
                lda #JOY_DOWN|JOY_LEFT
MH_RollSaveRight:
                cmp actMoveCtrl,x
                bne MH_NoRollSave
                lda #$01                        ;Reset prevctrl to allow to start roll
                sta actPrevCtrl,x
                sta actFall,x
                clc
                skip1
MH_NoRollSave:  sec
                tya
                sbc #DAMAGING_FALL_DISTANCE
                bcc MH_NoFallDamage
                beq MH_NoFallDamage
                asl
                sta temp8
                asl
                adc temp8
                jsr DamageSelf
MH_NoFallDamage:dec actFall,x
MH_NoFallCheck: lda actF1,x                     ;Check for special movement states
                cmp #FR_CLIMB
                bcc MH_NoSpecial
                cmp #FR_SWIM
                bcs MH_IsSwimming
                cmp #FR_ROLL
                bcs MH_IsRolling
                cmp #FR_DIE
                bcs MH_IsDying
                jmp MH_Climbing
MH_IsDying:     jmp MH_DeathAnim
MH_IsSwimming:  jmp MH_Swimming
MH_IsRolling:   inc temp2
                bne MH_RollAcc
MH_NoSpecial:   cmp #FR_DUCK+1
                lda actMoveCtrl,x               ;Check turning / X-acceleration / braking
                and #JOY_LEFT|JOY_RIGHT
                beq MH_Brake
                and #JOY_RIGHT
                bne MH_TurnRight
                lda #$80
MH_TurnRight:   sta actD,x
                bcs MH_Brake2                   ;If ducking, only turn, then brake
MH_RollAcc:     lda temp1
                lsr                             ;Faster acceleration when on ground
                ldy #AL_GROUNDACCEL
                bcs MH_OnGroundAcc
                iny
MH_OnGroundAcc: lsr                             ;If in water, halve max speed
                bcc MH_NoWaterMaxSpeed
                lsr temp4
MH_NoWaterMaxSpeed:
                lda actD,x
                asl                             ;Direction to carry
                lda (actLo),y
                ldy temp4
                jsr AccActorXNegOrPos
                jmp MH_HorizMoveDone
MH_Brake:       lda temp1                       ;Only brake when grounded
                lsr
                bcc MH_HorizMoveDone
MH_Brake2:      ldy #AL_BRAKING
                lda (actLo),y
                jsr BrakeActorX
MH_HorizMoveDone:
                lda temp1
                and #MB_HITWALL|MB_LANDED       ;If hit wall (and did not land simultaneously), reset X-speed
                cmp #MB_HITWALL
                bne MH_NoHitWall
                lda temp3
                and #AMF_WALLFLIP
                beq MH_NoWallFlip
                lda temp1                       ;Check for wallflip (push joystick up & opposite to wall)
                lsr
                bcs MH_NoWallFlip
                lda actSY,x                     ;Must not have started descending yet
                bpl MH_NoWallFlip
                lda #JOY_UP|JOY_RIGHT
                ldy actSX,x
                beq MH_NoWallFlip
                bmi MH_WallFlipRight
                lda #JOY_UP|JOY_LEFT
MH_WallFlipRight:
                cmp actMoveCtrl,x
                bne MH_NoWallFlip
                cmp #JOY_UP|JOY_RIGHT
                jsr MH_GetSignedHalfSpeed
                sta actSX,x
                bne MH_StartJump
MH_NoWallFlip:  lda #$00
                sta actSX,x
MH_NoHitWall:   lda temp1
                lsr                             ;Grounded bit to C
                and #MB_HITCEILING/2
                bne MH_NoNewJump
                bcc MH_NoNewJump
                lda actCtrl,x                   ;When holding fire can not initiate jump
                and #JOY_FIRE                   ;or grab a ladder
                bne MH_NoNewJump
                lda actFall,x                   ;If still in falling autoduck mode,
                bne MH_NoNewJump                ;no new jump
                lda actMoveCtrl,x               ;If on ground, can initiate a jump
                and #JOY_UP                     ;except if in the middle of a roll
                beq MH_NoNewJump
                lda temp2
                bne MH_NoNewJump
                txa                             ;If player, check for operating levelobjects
                bne MH_NoOperate
                ldy lvlObjNum
                bmi MH_NoOperate
                lda actMoveCtrl+ACTI_PLAYER
                cmp #JOY_UP                     ;Must be holding only UP to operate
                bne MH_NoOperate
                jsr OperateObject
                ldx #ACTI_PLAYER
                bcs MH_NoNewJump
MH_NoOperate:   lda temp3
                and #AMF_CLIMB
                beq MH_NoInitClimbUp
                jsr GetCharInfo4Above           ;Jump or climb?
                and #CI_CLIMB
                beq MH_NoInitClimbUp
                jmp MH_InitClimb
MH_NoInitClimbUp:
                lda temp3
                and #AMF_JUMP
                beq MH_NoNewJump
                lda actPrevCtrl,x
                and #JOY_UP
                bne MH_NoNewJump
MH_StartJump:   ldy #AL_JUMPSPEED
                lda (actLo),y
                sta actSY,x
                jsr MH_ResetFall
                jsr MH_ResetGrounded
MH_NoNewJump:   ldy #AL_HEIGHT                  ;Actor height for ceiling check
                lda (actLo),y
                sta temp4
                ldy #AL_FALLACCEL               ;Make jump longer by holding joystick up
                lda actSY,x                     ;as long as still has upward velocity
                bpl MH_NoLongJump
                lda actMoveCtrl,x
                and #JOY_UP
                beq MH_NoLongJump
                ldy #AL_LONGJUMPACCEL
MH_NoLongJump:  lda (actLo),y
                ldy #HUMAN_MAX_YSPEED
                jsr MoveWithGravity             ;Actually move & check collisions
                and #MB_INWATER
                beq MH_NoWater                  ;If in water, check for starting to swim
                lda #-3
                jsr GetCharInfoOffset           ;Must be deep in water before
                and #CI_WATER                   ;swimming kicks in
                beq MH_NoWater
                lda temp3                       ;If actor can't swim, kill instantly
                bmi MH_CanSwim
                ldy #NODAMAGESRC
                jmp DestroyActor
MH_CanSwim:     jmp MH_InitSwim
MH_NoWater:     lda actMB,x
                cmp #MB_STARTFALLING
                bcc MH_NoFallStart
                jsr MH_ResetFall
                lda actAIHelp,x                 ;Check AI autojumping or autoturning
                cmp #AIH_AUTOJUMPLEDGE          ;when falling
                bcs MH_AutoJump
                and #AIH_AUTOTURNLEDGE
                beq MH_NoAutoJump
                lda actSX,x
                jsr MoveActorXNeg               ;Back off from the ledge
                jsr MH_SetGrounded              ;Force grounded status
                sec
                bne MH_DoAutoTurn
MH_AutoJump:    ldy #AL_JUMPSPEED
                lda (actLo),y
                sta actSY,x
MH_NoAutoJump:  lda actMB,x
MH_NoFallStart: lsr                             ;Grounded bit to carry
                and #MB_HITWALL/2
                beq MH_NoAutoTurn
                lda actAIHelp,x                 ;Check AI autoturning
                and #AIH_AUTOTURNWALL
                beq MH_NoAutoTurn
MH_DoAutoTurn:  lda actSX,x
                eor actD,x
                bmi MH_NoAutoTurn
                ldy #JOY_LEFT
                lda actD,x
                eor #$80
                bmi MH_AutoTurnLeft
                ldy #JOY_RIGHT
MH_AutoTurnLeft:sta actD,x
                tya
                sta actMoveCtrl,x
MH_NoAutoTurn:  bcs MH_NoIncFall                ;Check for increasing fall distance
                lda temp3
                and #AMF_NOFALLDAMAGE
                bne MH_NoIncFall
                lda actSY,x
                bmi MH_NoIncFall
                asl
                adc actFallL,x
                sta actFallL,x
                bcc MH_NoIncFall
                inc actFall,x
                clc
MH_NoIncFall:   ldy temp2                       ;If rolling, continue roll animation
                bne MH_RollAnim
                bcs MH_GroundAnim
                lda actSY,x                     ;Check for grabbing a ladder while
                bpl MH_GrabLadderOK             ;in midair
                cmp #-2*8
                bcc MH_JumpAnim
MH_GrabLadderOK:lda actMoveCtrl,x
                and #JOY_UP
                beq MH_JumpAnim
                lda actCtrl,x                   ;If fire is held, do not grab ladder
                and #JOY_FIRE
                bne MH_JumpAnim
                lda temp3
                and #AMF_CLIMB
                beq MH_JumpAnim
                jsr GetCharInfo4Above
                and #CI_CLIMB
                beq MH_JumpAnim
                jmp MH_InitClimb
MH_JumpAnim:    ldy #FR_JUMP+1
                lda actSY,x
                bpl MH_JumpAnimDown
MH_JumpAnimUp:  cmp #-1*8
                bcs MH_JumpAnimDone
                dey
                bcc MH_JumpAnimDone
MH_JumpAnimDown:cmp #2*8
                bcc MH_JumpAnimDone
                iny
MH_JumpAnimDone:tya
                jmp MH_AnimDone
MH_AnimDone3:   rts
MH_RollAnim:    lda #$01
                jsr AnimationDelay
                bcc MH_AnimDone3
                lda actF1,x
                adc #$00
                cmp #FR_ROLL+6                  ;Transition from roll to low duck
                bcc MH_RollAnimDone
                lda actMB,x                     ;If rolling and falling, transition
                lsr                             ;to jump instead
                bcs MH_RollToDuck
MH_RollToJump:  lda #FR_JUMP+2
                skip2
MH_RollToDuck:  lda #FR_DUCK+1
MH_RollAnimDone:jmp MH_AnimDone
MH_GroundAnim:  lda actFall,x                   ;Forced duck after falling
                bne MH_NoInitClimbDown
                lda actMoveCtrl,x
                and #JOY_DOWN
                beq MH_NoDuck
MH_NewDuckOrRoll:
                lda temp3
                and #AMF_ROLL
                beq MH_NoNewRoll
                lda actMB,x                     ;Can't roll in water
                and #MB_INWATER
                bne MH_NoNewRoll
                lda actMoveCtrl,x               ;To initiate a roll, must push the
                cmp actPrevCtrl,x               ;joystick diagonally down
                beq MH_NoNewRoll
                and #JOY_LEFT|JOY_RIGHT
                beq MH_NoNewRoll
                lda actD,x
MH_OldDir:      eor #$00
                and #$80
                bne MH_NoNewRoll                ;Also, must not have turned
MH_StartRoll:   lda #$00
                sta actFd,x
                lda #FR_ROLL
                jmp MH_AnimDone
MH_NoNewRoll:   lda temp3
                and #AMF_CLIMB
                beq MH_NoInitClimbDown
                lda actCtrl,x                   ;When holding fire can not initiate climbing
                and #JOY_FIRE
                bne MH_NoInitClimbDown
                jsr GetCharInfo                 ;Duck or climb?
                and #CI_CLIMB
                beq MH_NoInitClimbDown
                jmp MH_InitClimb
MH_NoInitClimbDown:
                lda temp3
                and #AMF_DUCK
                beq MH_NoDuck
                lda actF1,x
                cmp #FR_DUCK
                bcs MH_DuckAnim
                lda #$00
                sta actFd,x
                lda #FR_DUCK
                bne MH_AnimDone
MH_DuckAnim:    lda #$01
                jsr AnimationDelay
                bcc MH_AnimDone2
                lda actF1,x
                adc #$00
                cmp #FR_DUCK+2
                bcc MH_AnimDone
                lda #FR_DUCK+1
                bne MH_AnimDone
MH_NoDuck:      lda actF1,x                     ;If door enter/operate object animation,
                cmp #FR_ENTER                   ;hold it as long as joystick is held up
                bne MH_NoEnterAnim
                lda actMoveCtrl,x
                cmp #JOY_UP
                bne MH_StandAnim
                beq MH_AnimDone2
MH_NoEnterAnim: cmp #FR_DUCK
                bcc MH_StandOrWalk
MH_DuckStandUpAnim:
                lda #$01
                jsr AnimationDelay
                bcc MH_AnimDone2
                lda actF1,x
                sbc #$01
                cmp #FR_DUCK
                bcc MH_StandAnim
                bcs MH_AnimDone
MH_StandOrWalk: lda actMB,x
                and #MB_HITWALL
                bne MH_StandAnim
MH_WalkAnim:    lda actMoveCtrl,x
                and #JOY_LEFT|JOY_RIGHT
                beq MH_StandAnim
                lda actSX,x
                asl
                bcc MH_WalkAnimSpeedPos
                eor #$ff
                adc #$00
MH_WalkAnimSpeedPos:
                adc #$40
                adc actFd,x
                sta actFd,x
                lda actF1,x
                adc #$00
                cmp #FR_WALK+8
                bcc MH_AnimDone
                lda #FR_WALK
                bcs MH_AnimDone
MH_StandAnim:   lda #$00
                sta actFd,x
                lda #FR_STAND
MH_AnimDone:    sta actF1,x
                sta actF2,x
MH_AnimDone2:   rts

MH_InitClimb:   lda #$80
                sta actXL,x
                sta actFd,x
                lda actYL,x
                and #$e0
                sta actYL,x
                and #$30
                cmp #$20
                lda #FR_CLIMB
                adc #$00
                sta actF1,x
                sta actF2,x
                jsr MH_ResetFall
                sta actSX,x
                sta actSY,x
                jmp NoInterpolation

MH_InitSwim:    lda lvlWaterDamage              ;If only water damage is drowning, reset water damage counter
                bne MH_HasDamagingWater2
                sta actWaterDamage,x
MH_HasDamagingWater2:
                lda actSY,x
                bmi MH_SwimNoYSpeedMod          ;If falling down, reduce speed when hit water
                ldy #6
                jsr ModifyDamage                ;Hack: modifydamage used for multiplying Y-speed
                sta actSY,x
MH_SwimNoYSpeedMod:
                lda #FR_SWIM
                jmp MH_AnimDone

MH_Climbing:    jsr GetCharInfo                 ;Check water bit
                sta temp1
                and #CI_WATER
                lsr
                lsr
                sta actMB,x
                ldy #AL_CLIMBSPEED
                lda (actLo),y
                sta zpSrcLo
                lda actF1,x                     ;Reset frame in case attack ended
                sta actF2,x
                lda actMoveCtrl,x
                lsr
                bcc MH_NoClimbUp
                jmp MH_ClimbUp
MH_NoClimbUp:   lsr
                bcs MH_ClimbDown
                lda actMoveCtrl,x               ;Exit ladder?
                and #JOY_LEFT|JOY_RIGHT
                beq MH_ClimbDone
                lsr                             ;Left bit to direction
                lsr
                lsr
                ror
                sta actD,x
                lda temp1                       ;Check ground bit
                lsr
                bcs MH_ClimbExit
                lda actYL,x                     ;If half way a char, check also 1 char
                and #$20                        ;below
                beq MH_ClimbDone
                jsr GetCharInfo1Below
                lsr
                bcc MH_ClimbDone
MH_ClimbExitBelow:
                lda #8*8
                jsr MoveActorY
MH_ClimbExit:   lda actYL,x
                and #$c0
                sta actYL,x
                jsr MH_SetGrounded
                jsr NoInterpolation
                jmp MH_StandAnim

MH_ClimbDown:   lda temp1
                and #CI_CLIMB
                beq MH_ClimbDone
                ldy #4*8
                bne MH_ClimbCommon
MH_ClimbDone:   rts

MH_ClimbUp:     jsr GetCharInfo4Above
                sta temp8
                and #CI_OBSTACLE
                bne MH_ClimbUpNoJump
                lda actMoveCtrl,x               ;Check for exiting the ladder
                cmp actPrevCtrl,x               ;by jumping
                beq MH_ClimbUpNoJump
                and #JOY_LEFT|JOY_RIGHT
                beq MH_ClimbUpNoJump
                lda temp1                       ;If in the middle of an obstacle
                and #CI_OBSTACLE                ;block, can not exit by jump
                bne MH_ClimbUpNoJump
                lda #-2
                jsr GetCharInfoOffset
                and #CI_OBSTACLE
                bne MH_ClimbUpNoJump
                lda actMoveCtrl,x
                cmp #JOY_RIGHT
                jsr MH_GetSignedHalfSpeed
                sta actSX,x
                sta actD,x
                jmp MH_StartJump
MH_ClimbUpNoJump:
                lda actYL,x
                and #$20
                bne MH_ClimbUpOk
                lda temp8
                and #CI_CLIMB
                beq MH_ClimbDone
MH_ClimbUpOk:   ldy #-4*8
MH_ClimbCommon: lda zpSrcLo                     ;Climbing speed
                clc
                adc actFd,x
                sta actFd,x
                bcc MH_ClimbDone
                lda #$01                        ;Add 1 or 3 depending on climbing dir
                cpy #$80
                bcc MH_ClimbAnimDown
                lda #$02                        ;C=1, add one less
MH_ClimbAnimDown:
                adc actF1,x
                sbc #FR_CLIMB-1                 ;Keep within climb frame range
                and #$03
                adc #FR_CLIMB-1
                sta actF1,x
                sta actF2,x
                tya
                jsr MoveActorY
                jmp NoInterpolation

MH_Swimming:    ldy #AL_MOVESPEED
                lda (actLo),y
                lsr                             ;Swimming max speed = half of ground speed
                sta temp4
                iny
                lda (actLo),y
                sta temp5
                ldy actMoveCtrl,x
                cpy #JOY_LEFT
                bcc MH_SwimHorizDone
MH_SwimHorizLeftOrRight:
                lda #$00
                cpy #JOY_RIGHT
                bcs MH_SwimRight
                lda #$80
MH_SwimRight:   sta actD,x
                asl                             ;Direction to carry
                ldy temp4
                lda temp5
                jsr AccActorXNegOrPos
MH_SwimHorizDone:
                lda actMoveCtrl,x
                and #JOY_UP|JOY_DOWN
                beq MH_SwimVertDone
                lsr
                lda temp5
                ldy temp4
                jsr AccActorYNegOrPos
MH_SwimVertDone:lda actSY,x
                bne MH_NotStationary
                lda #-1                         ;If Y-speed stationary, rise up slowly
                sta actSY,x
MH_NotStationary:
                bpl MH_NotSwimmingUp            ;When going up, make sure there's water above
                lda #-2
                jsr GetCharInfoOffset
                tay
                and #CI_WATER
                bne MH_HasWaterAbove
                lda #$00
                sta actSY,x
                lda actMoveCtrl,x               ;If joystick held up, exit if ground above
                lsr
                bcc MH_NotExitingWater
                cmp #JOY_LEFT/2                 ;Check for exiting to left/right
                bcc MH_ExitWaterCheckAbove
                cmp #JOY_RIGHT/2
                lda #8*8
                ldy #3
                bcs MH_ExitWaterCheckRight
                lda #-8*8
                ldy #-3
MH_ExitWaterCheckRight:
                sta temp1
                lda #-2
                jsr GetCharInfoXYOffset
                lsr
                bcc MH_NotExitingWater
MH_GetOutOfWaterLoop:
                lda #-2                         ;Move actor until standing on ground
                jsr GetCharInfoOffset
                lsr
                bcs MH_ExitWaterCommon
                lda temp1
                jsr MoveActorX
                jmp MH_GetOutOfWaterLoop
MH_ExitWaterCheckAbove:
                tya
                lsr
                bcc MH_NotExitingWater
MH_ExitWaterCommon:
                lda #-16*8
                jsr MoveActorY
                lda actYL,x
                and #$c0
                sta actYL,x
                jsr MH_ResetFall
                sta actSY,x
                lda #MB_GROUNDED
                sta actMB,x                     ;Forcibly clear water bit
                jsr NoInterpolation
                lda #FR_DUCK+1
                jmp MH_AnimDone
MH_NotExitingWater:
MH_HasWaterAbove:
MH_NotSwimmingUp:
                lda #2
                sta temp4
                lda #-1                         ;Use middle of player for obstacle check
                ldy #CI_WATER
                jsr MoveFlyer
                lda #$03
                jsr AnimationDelay
                lda actF1,x
                adc #$00
                cmp #FR_SWIM+4
                bcc MH_SwimAnimDone
                lda #FR_SWIM
MH_SwimAnimDone:jmp MH_AnimDone

MH_ResetFall:   lda #$00
                sta actFall,x
                sta actFallL,x
                rts

MH_SetGrounded: lda actMB,x
                ora #MB_GROUNDED
                bne MH_SetMoveBits

MH_ResetGrounded:
                lda actMB,x
                and #$ff-MB_GROUNDED
MH_SetMoveBits: sta actMB,x
                rts

MH_GetSignedHalfSpeed:
                ldy #AL_MOVESPEED
                lda (actLo),y
                php
                lsr
                plp
                bcs MH_GSHSDone
                eor #$ff
                adc #$01
MH_GSHSDone:    rts

        ; Humanoid character destroy routine
        ;
        ; Parameters: X actor index,Y damage source actor or $ff if none
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8

HumanDeath:     tya                             ;Check if has a damage source
                bmi HD_NoDamageSource
                lda actHp,y
                sta temp8
                lda actSX,y                     ;Check if final attack came from right or left
                bne HD_GotDir
                lda actXL,x
                sec
                sbc actXL,y
                lda actXH,x
                sbc actXH,y
HD_GotDir:      asl                             ;Direction to carry
                lda temp8
                ldy #DEATH_MAX_XSPEED
                jsr AccActorXNegOrPos
HD_NoDamageSource:
                lda #SFX_DEATH
                jsr PlaySfx
                lda #FR_DIE
                sta actF1,x
                sta actF2,x
                lda #DEATH_DISAPPEAR_DELAY
                sta actTime,x
                lda #POS_NOTPERSISTENT          ;Bodies are supposed to eventually vanish, so mark as
                sta actLvlDataPos,x             ;nonpersistent if goes off the screen
                lda actMB,x                     ;If in water, do not modify Y-speed
                and #MB_INWATER
                bne HD_NoYSpeed
                lda #DEATH_YSPEED
                sta actSY,x
                jsr MH_ResetGrounded
HD_NoYSpeed:    lda #$00
                sta actFd,x
                sta actHp,x
                sta actAIMode,x                ;Reset any ongoing AI

        ; Drop item from dead enemy
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8

DropItem:       lda #$02                        ;Retry counter
                sta temp7
DI_Retry:       ldy #AL_DROPITEMINDEX
                lda (actLo),y
                bpl DI_ItemNumber
                sta temp5
                jsr Random
                and #DROPTABLERANDOM-1
                adc temp5
                tay
                lda itemDropTable-$80,y
                bne DI_ItemNumber
                lda actWpn,x
                bcc DI_ItemNumber
DI_Override:
DI_ItemNumber:  tay
                beq DI_NoItem
                sta temp5                       ;Item type to drop
                lda #$00
                sta temp8                       ;Capacity counter
                ldy #ACTI_FIRSTITEM             ;Count capacity on both ground and inventory, do not spawn
DI_CountGroundItems:                            ;if player can't pick up
                lda actT,y
                beq DI_CGINext
                lda actF1,y
                cmp temp5
                bne DI_CGINext
                lda actHp,y
                clc
                adc temp8
                bcs DI_NoItem
                sta temp8
DI_CGINext:     iny
                cpy #ACTI_LASTITEM+1
                bcc DI_CountGroundItems
                lda temp4
                jsr FindItem
                bcc DI_NotInInventory
                lda invCount,y
                clc
                adc temp8
                bcs DI_NoItem
                sta temp8
DI_NotInInventory:
                ldy temp5
                lda temp8
                cmp itemMaxCount-1,y
                bcc DI_HasCapacity
                dec temp7
                bne DI_Retry                    ;If player has no capacity, retry to drop something else
DI_NoItem:      rts                             ;(eg. credits)
DI_HasCapacity: lda #ACTI_FIRSTITEM
                ldy #ACTI_LASTITEM
                jsr GetFreeActor
                bcc DI_NoItem
                lda #ACT_ITEM
                jsr SpawnActor
                lda temp5
                stx temp6
                tax
                sta actF1,y
                jsr Random
                and #$03                        ;In case going to drop credits, randomize amount
                adc #$02
                sta defaultCreditsPickup
                lda itemDefaultPickup-1,x
                sta actHp,y
                lda #ITEM_YSPEED
                sta actSY,y
                tya
                tax
                jsr InitActor
                lda #ITEM_SPAWN_OFFSET
                jsr MoveActorY
                lda temp5
                cmp #ITEM_FIRST_IMPORTANT
                ror
                ror
                and #ORG_GLOBAL
                jsr SetPersistence
                ldx temp6
                rts

        ; Give experience points to player, check for leveling
        ;
        ; Parameters: A XP amount
        ; Returns: -
        ; Modifies: A,loader temp vars

GiveXP:         pha
                stx zpSrcLo
                sty zpSrcHi
                ldx #<xpLo
                jsr Add8
                pla
                clc
                adc lastReceivedXP
                bcs GXP_TooMuchXP               ;If last received XP overflows,
                sta lastReceivedXP              ;disregard the latest addition
GXP_TooMuchXP:  ldy #<xpLimitLo                 ;(should not happen)
                jsr Cmp16
                bcc GXP_Done
                lda xpLevel
                cmp #MAX_LEVEL
                bcc GXP_NoMaxLevel
                lda xpLimitLo                   ;Clamp XP on last level
                sta xpLo
                lda xpLimitHi
                sta xpHi
                bne GXP_Done
GXP_NoMaxLevel: sta levelUp                     ;Mark pending levelup
GXP_Done:       jmp PSfx_Done                   ;Hack: PlaySfx ends similarly
                ;ldx zpSrcLo
                ;ldy zpSrcHi
                ;rts

        ; Save an in-memory checkpoint. All actors must be removed from screen at this point
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,temp regs

SaveCheckpoint:
                if OPTIMIZE_SAVE>0
                jsr SaveLevelActorState
                ldx #MAX_LVLACT-1
                ldy #$00
SCP_SaveGlobalActorsLoop:
                lda lvlActT,x
                beq SCP_SaveGlobalNext
                sta saveLvlActT,y
                lda lvlActOrg,x
                sta saveLvlActOrg,y
                bmi SCP_SaveGlobalNext
                asl                             ;Global bit to N flag
                bpl SCP_SaveGlobalNext
                lda lvlActX,x
                sta saveLvlActX,y
                lda lvlActY,x
                sta saveLvlActY,y
                lda lvlActF,x
                sta saveLvlActF,y
                lda lvlActWpn,x
                sta saveLvlActWpn,y
                iny
SCP_SaveGlobalNext:
                dex
                bpl SCP_SaveGlobalActorsLoop
                lda #$00
SCP_SaveGlobalClearLoop:                        ;Clear unused global actors
                sta saveLvlActT,y
                iny
                cpy #MAX_GLOBALACT
                bcc SCP_SaveGlobalClearLoop
                endif
                jsr SaveLevelObjectState
                ldx #15
SCP_LevelName:  lda lvlName,x
                sta saveLvlName,x
                dex
                bpl SCP_LevelName
                ldx #playerStateZPEnd-playerStateZPStart
SCP_ZPState:    lda playerStateZPStart-1,x
                sta saveStateZP-1,x
                dex
                bne SCP_ZPState
                lda #<playerStateStart
                sta zpSrcLo
                lda #>playerStateStart
                sta zpSrcHi
                lda #<saveState
                ldx #>saveState
                jsr SaveState_CopyMemory
                ldx #5
                ldy #5*MAX_ACT
StorePlayerActorVars:
                lda actXL+ACTI_PLAYER,y
                sta saveXL,x
                tya
                sec
                sbc #MAX_ACT
                tay
                dex
                bpl StorePlayerActorVars
                rts

        ; Restore an in-memory checkpoint
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,temp vars

RestartCheckpoint:
                ldx #playerStateZPEnd-playerStateZPStart
RCP_ZPState:    lda saveStateZP-1,x
                sta playerStateZPStart-1,x
                dex
                bne RCP_ZPState
                lda #<saveState
                sta zpSrcLo
                lda #>saveState
                sta zpSrcHi
                lda #<playerStateStart
                ldx #>playerStateStart
                jsr SaveState_CopyMemory
                if OPTIMIZE_SAVE>0
RCP_CopyActors: ldx #MAX_GLOBALACT-1
RCP_CopyGlobalActorsLoop:
                lda saveLvlActX,x
                sta lvlActX,x
                lda saveLvlActY,x
                sta lvlActY,x
                lda saveLvlActF,x
                sta lvlActF,x
                lda saveLvlActT,x
                sta lvlActT,x
                lda saveLvlActWpn,x
                sta lvlActWpn,x
                lda saveLvlActOrg,x
                sta lvlActOrg,x
                dex
                bpl RCP_CopyGlobalActorsLoop
RCP_ClearActors:ldx #MAX_LVLDATAACT-1
                lda #$00
RCP_ClearActorsLoop:
                sta lvlActT+MAX_GLOBALACT,x
                dex
                bpl RCP_ClearActorsLoop
                sec                             ;Need to load leveldata actors again
                else
                clc                             ;Savestate has all actors, do not load from disk
                endif
                jsr CreatePlayerActor
                jmp CenterPlayer

        ; Create player actor and (re)load level
        ;
        ; Parameters: C=0 do not load actors from leveldata, C=1 load actors
        ; Returns: -
        ; Modifies: A,X,Y,temp vars

CreatePlayerActor:
                ldx #MAX_ACT-1                  ;Clear all actors when starting game
RCP_ClearActorLoop:
                jsr RemoveActor
                dex
                bpl RCP_ClearActorLoop
                jsr LoadLevel
                ldy #ACTI_PLAYER
                jsr GFA_Found
                ldx #5
                ldy #5*MAX_ACT
LoadPlayerActorVars:
                lda saveXL,x
                sta actXL+ACTI_PLAYER,y
                tya
                sec
                sbc #MAX_ACT
                tay
                dex
                bpl LoadPlayerActorVars
                inx                             ;X=0
                stx lastReceivedXP
                jsr InitActor
                jsr SetPanelRedrawItemAmmo

        ; Apply skill effects
        ;
        ; Parameters: -
        ; Returns: X=0
        ; Modifies: A,X,Y,temp6-temp8

ApplySkills:

        ; Agility: acceleration, jump height, climbing speed

                ldx plrAgility
                txa
                clc
                adc #INITIAL_GROUNDACC
                sta plrGroundAcc
                txa
                adc #INITIAL_INAIRACC
                sta plrInAirAcc
                txa
                asl
                adc plrAgility
                asl
                adc #INITIAL_CLIMBSPEED
                sta plrClimbSpeed
                txa
                asl
                eor #$ff
                adc #1-INITIAL_JUMPSPEED
                sta plrJumpSpeed

        ; Firearms: damage bonus and faster reloading

                ldx plrFirearms
                lda plrWeaponBonusTbl,x
                sta AH_PlayerFirearmBonus+1
                lda #NO_MODIFY
                sbc plrFirearms                 ;C=1 here
                sta AH_ReloadDelayBonus+1

        ; Melee: damage bonus

                ldx plrMelee
                lda plrWeaponBonusTbl,x
                sta AH_PlayerMeleeBonus+1

        ; Vitality: damage reduction, faster health recharge, slower drowning

                ldy difficulty
                lda plrVitality
                adc #INITIAL_HEALTHRECHARGETIMER-1  ;C=1 here
                cpy #DIFFICULTY_HARD                ;Hard level slows down health recharge
                bcc AS_MediumOrEasy
                lsr
AS_MediumOrEasy:sta ULO_HealthRechargeRate+1
                lda #NO_MODIFY
                sec
                sbc plrVitality
                cpy #DIFFICULTY_MEDIUM              ;On Easy level damage multiplier is lower
                bcs AS_MediumOrHard
                sbc #EASY_DMGMULTIPLIER_REDUCE-1    ;C=0 here, becomes 1
AS_MediumOrHard:sta plrDmgModify
                lda #DROWNING_TIMER_REPEAT/4
                sbc plrVitality
                asl
                asl                                 ;C becomes 0
                sta MH_PlayerDrowningTimerRepeat+1

        ; Carrying: more weapons in inventory and higher ammo limit

                lda plrCarrying
                adc #INITIAL_MAX_WEAPONS
                sta AI_MaxWeaponsCount+1
                ldx #itemDefaultMaxCount - itemMaxCount
AS_AmmoLoop:    lda itemMaxCountAdd-1,x
                ldy plrCarrying
                stx temp6
                ldx #<temp7
                jsr MulU
                ldx temp6
                lda itemDefaultMaxCount-1,x
                clc
                adc temp7
                sta itemMaxCount-1,x
                dex
                bne AS_AmmoLoop
CS_NoFreeActor: rts

        ; Create a water splash
        ;
        ; Parameters: X source actor
        ; Returns: -
        ; Modifies: A,Y

CreateSplash:   lda #ACTI_FIRSTEFFECT
                ldy #ACTI_LASTEFFECT
                jsr GetFreeActor
                bcc CS_NoFreeActor
                lda #ACT_WATERSPLASH
                jsr SpawnActor
                lda actYL,y                     ;Align to char boundary
                and #$c0
                sta actYL,y
                lda lvlWaterSplashColor
                sta actC,y
                lda #SFX_SPLASH
                jmp PlaySfx
