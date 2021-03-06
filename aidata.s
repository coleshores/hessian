        ; AI jumptable

aiJumpTblLo:    dc.b <AI_TurnTo
                dc.b <AI_Follow
                dc.b <AI_Sniper
                dc.b <AI_Mover
                dc.b <AI_Guard
                dc.b <AI_Berzerk
                dc.b <AI_Flyer
                dc.b <AI_Animal
                dc.b <AI_FreeMoveWithTurn
                dc.b <AI_FlyerIdle
                dc.b <AI_Fish

aiJumpTblHi:    dc.b >AI_TurnTo
                dc.b >AI_Follow
                dc.b >AI_Sniper
                dc.b >AI_Mover
                dc.b >AI_Guard
                dc.b >AI_Berzerk
                dc.b >AI_Flyer
                dc.b >AI_Animal
                dc.b >AI_FreeMoveWithTurn
                dc.b >AI_FlyerIdle
                dc.b >AI_Fish

        ; Spawn list entry selection tables

spawnListAndTbl:dc.b $01                        ;0: entries 0-1 (first courtyard)
                dc.b $03                        ;1: entries 1-4 (entrance)
                dc.b $03                        ;2: entries 4-7 (service tunnels)
                dc.b $03                        ;3: entries 7-10 (upper lab)
                dc.b $01                        ;4: entries 10-11 (second courtyard)
                dc.b $01                        ;5: entries 12-13 (first cave)
                dc.b $00                        ;6: entry 14 (lower lab stairwells)
                dc.b $03                        ;7: entries 15-18 (lower lab corridor)
                dc.b $03                        ;8: entries 19-22 (server vault)
                dc.b $07                        ;9: entries 23-30 (nether tunnel)
                dc.b $00                        ;a: entry 31 (nether tunnel lava)
                dc.b $00                        ;b: entry 32 (biodome, second cave)
                dc.b $00                        ;c: entry 33 (second cave rocks)
                dc.b $01                        ;d: entries 34-35 (throne suite)

spawnListAddTbl:dc.b $00                        ;0: entries 0-1 (first courtyard)
                dc.b $01                        ;1: entries 1-4 (entrance)
                dc.b $04                        ;2: entries 4-7 (service tunnels)
                dc.b $07                        ;3: entries 7-10 (upper lab)
                dc.b $0a                        ;4: entries 10-11 (second courtyard)
                dc.b $0c                        ;5: entries 12-13 (first cave)
                dc.b $0e                        ;6: entry 14 (lower lab stairwells)
                dc.b $0f                        ;7: entries 15-18 (lower lab corridor)
                dc.b $13                        ;8: entries 19-22 (server vault)
                dc.b $17                        ;9: entries 23-30 (nether tunnel)
                dc.b $1f                        ;a: entry 31 (nether tunnel lava)
                dc.b $20                        ;b: entry 32 (biodome, second cave)
                dc.b $21                        ;c: entry 33 (second cave rocks)
                dc.b $22                        ;d: entries 34-35 (throne suite)

        ; Spawn list entries

spawnTypeTbl:   dc.b ACT_SMALLWALKER            ;0
                dc.b ACT_SMALLDROID             ;1
                dc.b ACT_COMBATROBOT            ;2
                dc.b ACT_COMBATROBOT            ;3
                dc.b ACT_COMBATROBOT            ;4
                dc.b ACT_RAT                    ;5
                dc.b ACT_SMALLDROID             ;6
                dc.b ACT_COMBATROBOT            ;7
                dc.b ACT_SMALLTANK              ;8
                dc.b ACT_COMBATROBOT            ;9
                dc.b ACT_FLYINGCRAFT            ;10
                dc.b ACT_SMALLWALKER            ;11
                dc.b ACT_SPIDER                 ;12
                dc.b ACT_BAT                    ;13
                dc.b ACT_LARGEDROID             ;14
                dc.b ACT_COMBATROBOT            ;15
                dc.b ACT_MEDIUMWALKER           ;16
                dc.b ACT_FLYINGCRAFT            ;17
                dc.b ACT_COMBATROBOT            ;18
                dc.b ACT_COMBATROBOT            ;19
                dc.b ACT_SMALLTANK              ;20
                dc.b ACT_FLYINGCRAFT            ;21
                dc.b ACT_COMBATROBOTFAST        ;22
                dc.b ACT_SMALLTANK              ;23
                dc.b ACT_FLYINGCRAFT            ;24
                dc.b ACT_FLYINGCRAFT            ;25
                dc.b ACT_ROLLINGMINE            ;26
                dc.b ACT_ROLLINGMINE            ;27
                dc.b ACT_SMALLTANK              ;28
                dc.b ACT_COMBATROBOT            ;29
                dc.b ACT_LARGEWALKER            ;30
                dc.b ACT_FIREBALL               ;31
                dc.b ACT_FLY                    ;32
                dc.b ACT_ROCK                   ;33
                dc.b ACT_HEAVYGUARD             ;34
                dc.b ACT_SMALLTANK              ;35

spawnWpnTbl:    dc.b ITEM_PISTOL                ;0
                dc.b ITEM_PISTOL|SPAWN_AIR      ;1
                dc.b ITEM_NIGHTSTICK            ;2
                dc.b ITEM_PISTOL                ;3
                dc.b ITEM_SHOTGUN               ;4
                dc.b ITEM_ANIMALBITE            ;5
                dc.b ITEM_MINIGUN|SPAWN_AIR     ;6
                dc.b ITEM_AUTORIFLE             ;7
                dc.b ITEM_AUTORIFLE             ;8
                dc.b ITEM_EMPGENERATOR          ;9
                dc.b ITEM_MINIGUN|SPAWN_AIR     ;10
                dc.b ITEM_MINIGUN               ;11
                dc.b ITEM_NONE                  ;12
                dc.b ITEM_NONE|SPAWN_AIR        ;13
                dc.b ITEM_LASERRIFLE|SPAWN_AIRTOP ;14
                dc.b ITEM_LASERRIFLE            ;15
                dc.b ITEM_LASERRIFLE            ;16
                dc.b ITEM_LASERRIFLE|SPAWN_AIR  ;17
                dc.b ITEM_MINIGUN               ;18
                dc.b ITEM_LASERRIFLE            ;19
                dc.b ITEM_MINIGUN               ;20
                dc.b ITEM_PLASMAGUN|SPAWN_AIR   ;21
                dc.b ITEM_PLASMAGUN             ;22
                dc.b ITEM_FLAMETHROWER          ;23
                dc.b ITEM_PLASMAGUN|SPAWN_AIR   ;24
                dc.b ITEM_PLASMAGUN|SPAWN_AIR   ;25
                dc.b ITEM_NONE                  ;26
                dc.b ITEM_NONE                  ;27
                dc.b ITEM_FLAMETHROWER          ;28
                dc.b ITEM_MINIGUN               ;29
                dc.b ITEM_GRENADELAUNCHER       ;30
                dc.b ITEM_NONE|SPAWN_AIRBOTTOM  ;31
                dc.b ITEM_NONE|SPAWN_AIR        ;32
                dc.b ITEM_NONE|SPAWN_AIRTOP     ;33
                dc.b ITEM_AUTORIFLE             ;34
                dc.b ITEM_MINIGUN               ;35