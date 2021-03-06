ITEM_NONE       = 0
ITEM_FISTS      = 1
ITEM_KNIFE      = 2
ITEM_NIGHTSTICK = 3
ITEM_BAT        = 4
ITEM_PISTOL     = 5
ITEM_SHOTGUN    = 6
ITEM_AUTORIFLE  = 7
ITEM_SNIPERRIFLE = 8
ITEM_MINIGUN    = 9
ITEM_FLAMETHROWER = 10
ITEM_LASERRIFLE = 11
ITEM_PLASMAGUN  = 12
ITEM_EMPGENERATOR = 13
ITEM_GRENADELAUNCHER = 14
ITEM_BAZOOKA    = 15
ITEM_EXTINGUISHER = 16
ITEM_GRENADE    = 17
ITEM_MINE       = 18
ITEM_ANIMALBITE = 19 ;Not an actual item, but "weapon" used by animal enemies
ITEM_MEDKIT     = 19
ITEM_BATTERY    = 20
ITEM_ARMOR      = 21
ITEM_PARTS      = 22
ITEM_AMPLIFIER  = 23
ITEM_TRUCKBATTERY = 24
ITEM_FUELCAN    = 25
ITEM_LUNGFILTER = 26
ITEM_WAREHOUSEPASS = 27
ITEM_ITPASS = 28
ITEM_SERVICEPASS = 29
ITEM_SECURITYPASS = 30
ITEM_SCIENCEPASS = 31
ITEM_LV2ITPASS = 32
ITEM_LV2SECURITYPASS = 33
ITEM_SUITEPASS = 34
ITEM_VAULTPASS = 35
ITEM_OLDTUNNELSPASS = 36
ITEM_BIOMETRICID = 37
ITEM_COMMGEAR = 38
ITEM_LAPTOP = 39
ITEM_HAZMATSUIT = 40

ITEM_FIRST_CONSUMABLE = ITEM_GRENADE
ITEM_FIRST_NONWEAPON = ITEM_MEDKIT
ITEM_FIRST_IMPORTANT = ITEM_AMPLIFIER
ITEM_FIRST      = ITEM_FISTS
ITEM_LAST_PICKUP = ITEM_BIOMETRICID
ITEM_LAST       = ITEM_LAPTOP
ITEM_FIRST_MAG  = ITEM_PISTOL
ITEM_LAST_MAG   = ITEM_BAZOOKA

DROP_NOTHING = $00
DROP_MEDKIT = $81
DROP_BATTERY = $82
DROP_ARMOR = $84
DROP_WEAPON = $88
DROP_PARTS = $90

MEDKIT_DROP_PROBABILITY = $20
BATTERY_DROP_PROBABILITY = $20
ARMOR_DROP_PROBABILITY = $20
PARTS_DROP_PROBABILITY = $80

INITIAL_MAX_WEAPONS = 4                         ;3 + fists

USEITEM_ATTACK_DELAY = 5                        ;Attack delay after using an item

MAG_INFINITE    = $ff
NO_ITEM_COUNT   = $ff

        ; Item update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveItem:       lda actMB,x                     ;Skip movement if grounded and stationary
                lsr
                bcs MoveItem_Done
                lda actSY,x                     ;Store original Y-speed for bounce
                sta temp1
                jsr FallingMotionCommon         ;Move & check collisions
                lsr
                bcc MoveItem_Done
                lda temp1                       ;Bounce: negate and halve velocity
                jsr Negate8Asr8
                beq MoveItem_Done               ;If velocity left, clear the grounded
                sta actSY,x                     ;flag
                lda #$00
                sta actMB,x
MoveItem_Done:
FlashActor:     lda #$01
                sta actFlash,x
                rts
FlashActor_CheckDamageFlash:
                lda actFlash,x
                cmp #COLOR_ONETIMEFLASH
                bne FlashActor
                rts

        ; Object marker update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveObjectMarker:
MObjMarker_Cmp: cpx #$00                        ;Remove old objectmarker
                bne MObjMarker_Remove
                lda lvlObjNum                   ;Remove if no object
MObjMarker_ObjCmp:
                cmp #$00
                bne MObjMarker_Remove
                jmp FlashActor
MObjMarker_Remove:
                jmp RemoveActor

        ; Try picking up an item
        ;
        ; Parameters: Y item actor index
        ; Returns: -
        ; Modifies: A,X,Y,temp vars

TryPickup:      sty temp1                       ;Item actor number
                lda actF1,y
                cmp #ITEM_LAST_PICKUP+1         ;Check items which only exist in world / are given
                bcs TP_PickupFail               ;by NPCs but cannot be picked up
                sta temp2                       ;Item type
                ldx actHp,y
                jsr AddItem
                bcc TP_PickupFail
TP_PickupSuccess:
                ldx temp1
                lda zpBitsLo                    ;Was the item swapped?
                beq TP_NoSwap
                sta actF1,x                     ;Store type/ammo after swap
                lda zpBitsHi
                sta actHp,x
                lda levelNum                    ;After swapping, the item has become temporary
                sta actLvlDataOrg,x             ;and is now disconnected from the leveldata
                jmp TP_PrintItemName
TP_NoSwap:      jsr RemoveActor                 ;If not swapped, remove
TP_PrintItemName:
                lda #<txtPickedUp
                ldx #>txtPickedUp
                ldy #INVENTORY_TEXT_DURATION
                jsr PrintPanelText
                lda temp2
                jsr GetItemName
                jsr ContinuePanelText
                lda #SFX_PICKUP
                jmp PlaySfx

        ; Get name of item
        ;
        ; Parameters: A item type
        ; Returns: A,X pointer to item name text
        ; Modifies: A,X,Y

GetItemName:    tay
                lda itemNameLo-1,y
                ldx itemNameHi-1,y
TP_PickupFail:  rts

        ; Find item from inventory (verify that has other than "none" count)
        ;
        ; Parameters: Y item type
        ; Returns: C=1 found, C=0 not found
        ; Modifies: Y

FindItem:       lda #NO_ITEM_COUNT-1
                cmp invCount-1,y
                rts

        ; Return weapon's magazine size
        ;
        ; Parameters: Y item type
        ; Returns: A=$00 & C=0 consumable or weapon with single ammo reserve
        ;          A=$ff & C=0 infinite (melee weapon)
        ;          A=$01-$7f & C=1 firearm with magazine
        ; Modifies: -

GetCurrentItemMagazineSize:
                ldy itemIndex
GetMagazineSize:lda #$00
                cpy #ITEM_LAST_MAG+1
                bcs GMS_Fail
                lda itemMagazineSize-1,y
                bmi GMS_Fail
                cmp #$01
                rts

        ; Select next item in inventory
        ;
        ; Parameters: -
        ; Returns: Y index, C=1 itemIndex updated, C=0 already at end
        ; Modifies: A,Y

SelectNextItem: ldy itemIndex
SNI_HasIndex:   cpy lastItemIndex
                bcs SNI_Fail
SNI_Loop:       iny
                jsr FindItem
                bcc SNI_Loop
SPI_Done:       sty itemIndex
                rts

        ; Select previous item in inventory
        ;
        ; Parameters: -
        ; Returns: Y index, C=1 itemIndex updated, C=0 already at beginning
        ; Modifies: A,Y

SelectPreviousItem:
                ldy itemIndex
SPI_Fast:       cpy #ITEM_FISTS
                beq SPI_Fail
SPI_Loop:       dey
                jsr FindItem
                bcc SPI_Loop
                bcs SPI_Done

        ; Add item to inventory. If too many weapons, swap with current
        ;
        ; Parameters: A item type, X ammo amount
        ; Returns: C=1 successful, C=0 failed (no room), zpBitsLo dropped item (0=none),
        ;          zpBitsHi dropped ammo count
        ; Modifies: A,X,Y,loader temp vars

AddItem:        sta zpSrcLo
                stx zpSrcHi
                cmp #ITEM_FIRST_IMPORTANT       ;Quest item?
                bcc AI_NotQuestItem
                lda #<250
                ldy #>250
                jsr AddScore                    ;Add score for picking them up
                lda zpSrcLo
AI_NotQuestItem:ldx #$00
                stx zpBitsLo                    ;Assume: don't have to drop an existing weapon
                tay
                jsr FindItem
                bcc AI_NewItem
AI_HasItem:     lda invCount-1,y                ;Check for maximum ammo
                cmp itemMaxCount-1,y
                bcc AI_HasRoomForAmmo
SNI_Fail:
SPI_Fail:
GMS_Fail:
AI_Fail:        clc                             ;Maximum ammo already, fail pickup
                rts
AI_HasRoomForAmmo:
                adc zpSrcHi
                bcs AI_CountWrapped
                cmp itemMaxCount-1,y
                bcc AI_AmmoNotExceeded
AI_CountWrapped:lda itemMaxCount-1,y
AI_AmmoNotExceeded:
                sta invCount-1,y
                jmp AI_Success
AI_NewItem:     cpy #ITEM_FIRST_CONSUMABLE      ;If picking up a weapon, check limit now
                bcs AI_NoWeaponLimit
                ldx #$00
                ldy #ITEM_FIRST_CONSUMABLE-1
AI_CheckWeapons:jsr FindItem
                bcc AI_CheckWeaponsNext
                inx
AI_CheckWeaponsNext:
                dey
                bne AI_CheckWeapons
AI_MaxWeaponsCount:
                cpx #INITIAL_MAX_WEAPONS
                bcc AI_NoWeaponLimit
                ldy itemIndex                   ;Swap with current weapon. If fists selected,
                cpy #ITEM_FISTS                 ;select first droppable weapon first
                bne AI_NotUsingFists
AI_RetrySwap:   jsr SNI_HasIndex                ;New index to Y
AI_NotUsingFists:
                cpy #ITEM_FIRST_CONSUMABLE      ;If consumable selected, select first weapon instead
                bcc AI_CanBeSwapped
                ldy #ITEM_FISTS
                bpl AI_RetrySwap
AI_CanBeSwapped:sty zpBitsLo
                lda invCount-1,y
                sta zpBitsHi
                jsr RemoveItem
                lda zpSrcLo                     ;In case of swapping select the new item
                sta itemIndex
AI_NoWeaponLimit:
                ldy zpSrcLo
                lda zpSrcHi
                sta invCount-1,y
                cpy lastItemIndex
                bcc AI_NoNewLastItem
                sty lastItemIndex
AI_NoNewLastItem:
                jsr GetMagazineSize
                bcc AI_Success
                lda #$00                        ;If is a weapon with magazine, start with it empty
                sta invMag-ITEM_FIRST_MAG,y
AI_Success:     sec
SetPanelRedrawItemAmmo:
                lda #REDRAW_ITEM+REDRAW_AMMO
                SKIP2
SetPanelRedrawAmmo:
                lda #REDRAW_AMMO
SetPanelRedraw: ora panelUpdateFlags
                sta panelUpdateFlags
RI_NotFound:    rts

        ; Decrease ammo in inventory
        ;
        ; Parameters: A ammo amount, Y item type
        ; Returns: -
        ; Modifies: A,Y,zpSrcLo

DecreaseAmmoOne:lda #$01
DecreaseAmmo:   sta zpSrcLo
                jsr GetMagazineSize
                bcc DA_NoAmmoInMag
                lda invMag-ITEM_FIRST_MAG,y     ;Decrease ammo in magazine as well
                ;beq DA_NoAmmoInMag
                sbc zpSrcLo                     ;Is assumed not to overflow negatively, as
                sta invMag-ITEM_FIRST_MAG,y     ;when item has a magazine it is decreased
DA_NoAmmoInMag: lda invCount-1,y                ;only by one, and weapon code should not
                sec                             ;allow to fire empty weapon
                sbc zpSrcLo
                bcs DA_NotNegative
                lda #$00
DA_NotNegative: sta invCount-1,y
                bne SetPanelRedrawAmmo
                cpy #ITEM_FIRST_CONSUMABLE      ;If it's a consumable item, remove when ammo
                bcc SetPanelRedrawAmmo          ;goes to zero

        ; Remove item from inventory
        ;
        ; Parameters: Y item type (should never be fists)
        ; Returns: Y new item index after removal
        ; Modifies: A,Y

RemoveItem:     lda #NO_ITEM_COUNT
                sta invCount-1,y
                sta UM_ForceRefresh+1
                sty RI_Cmp+1
                cpy lastItemIndex
                bne RI_NotLast
RI_FindPrevious:dey
                jsr FindItem
                bcc RI_FindPrevious
                sty lastItemIndex
RI_NotLast:     ldy itemIndex                ;If selected item removed, switch
RI_Cmp:         cpy #$00                     ;selection backward
                bne SetPanelRedrawItemAmmo
                jsr SPI_Fast
                bcs SetPanelRedrawItemAmmo

        ; Use an inventory item
        ;
        ; Parameters: Y item type
        ; Returns: -
        ; Modifies: A,X,Y,temp vars

UseItem:        lda actHp+ACTI_PLAYER           ;Can't use/reload after dying
                beq UI_Dead
                lda levelNum
                cpy #ITEM_FIRST_NONWEAPON
                bcc UI_Reload
                cpy #ITEM_MEDKIT
                beq UseMedKit
                cpy #ITEM_BATTERY
                beq UseBattery
                cpy #ITEM_AMPLIFIER
                beq UseAmplifier
                cpy #ITEM_FUELCAN
                beq UseTunnelMachineItems
                cpy #ITEM_TRUCKBATTERY
                beq UseTunnelMachineItems
UI_Dead:
UB_FullBattery:
UTMI_NotRightPosition:
UA_NotRightPosition:
UMK_FullHealth: rts
UseTunnelMachineItems:
                cmp #$0a
                bne UTMI_NotRightPosition
                lda actYH+ACTI_PLAYER
                cmp #$74
                bne UTMI_NotRightPosition
                lda actXH+ACTI_PLAYER
                cmp #$a6
                bcc UTMI_NotRightPosition
                cmp #$aa
                bcs UTMI_NotRightPosition
                lda #<EP_TUNNELMACHINEITEMS
                ldx #>EP_TUNNELMACHINEITEMS
                jmp ExecScript
UseAmplifier:   cmp #$06
                bne UA_NotRightPosition
                lda lvlObjNum
                cmp #$0e
                bne UA_NotRightPosition
                lda #<EP_INSTALLAMPLIFIER
                ldx #>EP_INSTALLAMPLIFIER
                jmp ExecScript
UseBattery:     lda battery+1
                cmp #MAX_BATTERY
                bcs UB_FullBattery
                adc #MAX_BATTERY/2
                cmp #MAX_BATTERY
                bcc UB_NotOver
                lda #$00
                sta battery
                lda #MAX_BATTERY
UB_NotOver:     sta battery+1
                bne UMK_PlaySound
UseMedKit:      lda #HP_PLAYER
                cmp actHp+ACTI_PLAYER
                beq UMK_FullHealth
                sta actHp+ACTI_PLAYER
UMK_PlaySound:  lda #SFX_POWERUP
                jsr PlaySfx
UI_ReduceAmmo:  lda #USEITEM_ATTACK_DELAY       ;In case the item is removed, give an
                sta actAttackD+ACTI_PLAYER      ;attack delay to prevent accidental
                jmp DecreaseAmmoOne             ;fire if a weapon becomes selected next
UI_Reload:      jsr GetMagazineSize
                bcc UI_DontReload
                lda reload                      ;No reload if already reloading
                bne UI_DontReload
                lda actF1+ACTI_PLAYER           ;No reload if dead or swimming
                cmp #FR_DIE
                bcs UI_DontReload
                lda invMag-ITEM_FIRST_MAG,y     ;No reload if magazine already full or no reserve
                cmp itemMagazineSize-1,y
                bcs UI_DontReload
                cmp invCount-1,y
                bcs UI_DontReload
                dec reload
SameLevel:
UI_DontReload:  rts
