                include memory.s

                org chars
                dc.w upgrade1
                dc.w upgrade2
                dc.w upgrade3
                dc.w upgrade4
                dc.w upgrade5
                dc.w upgrade6
                dc.w upgrade7

                org chars+$40
                incbin spr/sight.spr

                org chars+$80

humanShape:     dc.b 32,174,32,0
                dc.b 175,176,177,0
                dc.b 178,179,180,0
                dc.b 181,182,183,0
                dc.b 184,185,186,0
                dc.b 187,188,189,0,0

                org chars+$400
                incbin bg/upgrade.chr

upgrade1:       dc.w nameMovement
                dc.b %00110000
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

upgrade2:       dc.w nameStrength
                dc.b %00001100
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

upgrade3:       dc.w nameFirearms
                dc.b %00000101
                dc.b $00,$00,$89,$00,$00,$89,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$89,$00,$00,$89,$00,$00,$00,$00,$00,$00
                dc.b $f7,$87,$02,$87,$87,$02,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $f7,$87,$02,$87,$87,$02,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$89,$00,$00,$89,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$89,$00,$00,$89,$00,$00,$00,$00,$00,$00

upgrade4:       dc.w nameArmor
                dc.b %00111111
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

upgrade5:       dc.w nameHealing
                dc.b %00000010
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

upgrade6:       dc.w nameDrain
                dc.b %00000010
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

upgrade7:       dc.w nameRecharge
                dc.b %00111111
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

nameMovement:   dc.b "LOWER BODY EXOSKELETON",0
                     ;0123456789012345678901234567
descMovement:   dc.b "ENHANCED MANEUVERABILITY,",0
                dc.b "HIGH JUMPS AND FAST CLIMBING",0
                dc.b "AT THE COST OF EXTRA BATTERY",0
                dc.b "DRAIN",0,0

nameStrength:   dc.b "UPPER BODY EXOSKELETON",0
                     ;0123456789012345678901234567
descStrength:   dc.b "IMPROVED UNARMED OR MELEE",0
                dc.b "STRENGTH AND LOAD CAPACITY",0
                dc.b "AT THE COST OF EXTRA BATTERY",0
                dc.b "DRAIN",0,0

nameFirearms:   dc.b "MOTOR SKILL COPROCESSOR",0
                     ;0123456789012345678901234567
descFirearms:   dc.b "IMPROVED FIREARMS PRECISION",0
                dc.b "(BETTER STOPPING POWER) AND",0
                dc.b "REDUCED RELOAD TIMES",0,0

nameArmor:      dc.b "SUBDERMAL ARMOR",0
                     ;0123456789012345678901234567
descArmor:      dc.b "REDUCED BLUNT AND PIERCING",0
                dc.b "TRAUMA OVER THE ENTIRE BODY",0,0

nameHealing:    dc.b "RECOVERY BOOSTER",0
                     ;0123456789012345678901234567
descHealing:    dc.b "FASTER NANOMECHANICAL TISSUE",0
                dc.b "RESTORATION",0,0

nameDrain:      dc.b "AUXILIARY BATTERY",0
                     ;0123456789012345678901234567
descDrain:      dc.b "INCREASED TIME OF OPERATION",0
                dc.b "BEFORE BATTERY RECHARGE IS",0
                dc.b "REQUIRED",0,0

nameRecharge:   dc.b "BIOELECTRIC RECHARGER",0
                     ;0123456789012345678901234567
descRecharge:   dc.b "CONVERTS BODY ELECTRICITY",0
                dc.b "INTO BATTERY POWER AT THE",0
                dc.b "COST OF INCREASED METABOLIC",0
                dc.b "STRAIN",0,0

                if * > screen2+SCROLLROWS*40
                    err
                endif