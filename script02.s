                include macros.s
                include mainsym.s

        ; Script 2, entrance texts, left side

                org scriptCodeStart

                dc.w TheatreComputer
                dc.w LobbyComputer
                dc.w OfficeComputer1
                dc.w OfficeComputer2
                dc.w OfficeComputer3
                dc.w OfficeComputer4

TheatreComputer:gettext txtTheatreComputer
DisplayCommon:  ldy #0
                sty temp1
                sty temp2
                jsr SetupTextScreen
                jsr PrintMultipleRows
                jsr WaitForExit
                jmp CenterPlayer

LobbyComputer:  gettext txtLobbyComputer
                bne DisplayCommon

OfficeComputer1:gettext txtOfficeComputer1
                bne DisplayCommon

OfficeComputer2:gettext txtOfficeComputer2
                bne DisplayCommon

OfficeComputer3:gettext txtOfficeComputer3
                bne DisplayCommon

OfficeComputer4:gettext txtOfficeComputer4
                bne DisplayCommon

txtTheatreComputer:
                     ;0123456789012345678901234567890123456789
                dc.b "WHAT IS THE THRONE GROUP?",0
                dc.b "INTERNAL PRESENTATION BY NORMAN THRONE",0
                dc.b " ",0
                dc.b "THRONE GROUP REPRESENTS INTELLECTUAL",0
                dc.b "BRAVERY AND COMMITMENT TO EXCELLENCE.",0
                dc.b "WE REJECT ANY LIMITS IN THE PURSUIT",0
                dc.b "TO ADVANCE MANKIND.",0
                dc.b " ",0
                dc.b "IN AN IDEAL WORLD WE WOULD NOT HAVE TO",0
                dc.b "CONTEND WITH MINOR DETAILS LIKE MONEY.",0
                dc.b "BUT SINCE SUCH WORLD DOES NOT EXIST, WE",0
                dc.b "DO THE NEXT BEST THING - CHOOSE CLIENTS",0
                dc.b "WHO MATCH OUR VISION THE CLOSEST.",0
                dc.b " ",0
                dc.b "SOME ARE AFRAID OF CONCEPTS SUCH AS",0
                dc.b "SINGULARITY, OR THE POST-HUMAN AGE. WE",0
                dc.b "SHOULD NOT BE. IF WE MANAGE TO CREATE",0
                dc.b "SOMETHING THAT SHAKES THE WORLD TO ITS",0
                dc.b "CORE, WE SHOULD ONLY BE PROUD.",0,0
                
txtLobbyComputer:
                     ;0123456789012345678901234567890123456789
                dc.b "LOBBY AUDIO LOG",0
                dc.b " ",0
                dc.b "WHAT'S THAT? GUNFIRE? EXPLOSIONS?",0
                dc.b "IT'S COMING FROM THE PARKING GARAGE.",0
                dc.b "A TERRORIST ATTACK?",0
                dc.b "SHIT. PHONE IS DEAD.",0
                dc.b "I SEE THEM NOW. THEY'RE NOT H-",0,0

txtOfficeComputer1:
                     ;0123456789012345678901234567890123456789
                dc.b "RE: PROJECTS",0
                dc.b " ",0
                dc.b "IS THERE SOMETHING I'M NOT BEING TOLD?",0
                dc.b "I UNDERSTAND THE 'HESSIAN' MILITARY",0
                dc.b "CONTRACT WAS AXED, WHILE THE RELATIVELY",0
                dc.b "MINOR COMBAT ROBOT PROJECT GOES ON. I'M",0
                dc.b "SEEING USE OF FUNDS WE SHOULDN'T BE",0
                dc.b "CAPABLE OF SUSTAINING.",0,0

txtOfficeComputer2:
                     ;0123456789012345678901234567890123456789
                dc.b "RE: RE: PROJECTS",0
                dc.b " ",0
                dc.b "YOU NEED NOT BE CONCERNED. WE ARE NOT",0
                dc.b "OVERSPENDING. NORMAN MAY HAVE UTILIZED",0
                dc.b "SOME OF HIS PERSONAL FUNDS JUST TO KEEP",0
                dc.b "THINGS RUNNING SMOOTHLY. THE ROBOT",0
                dc.b "PROJECT SHOULD SEE A MAJOR EXTENSION",0
                dc.b "SOON. PLEASE KEEP THIS KNOWLEDGE TO",0
                dc.B "YOURSELF FOR NOW.",0,0

txtOfficeComputer3:
                     ;0123456789012345678901234567890123456789
                dc.b "RE: PREPARATION",0
                dc.b " ",0
                dc.b "I AGREE THAT WE MUST BE PREPARED. IF THE",0
                dc.b "PROVERBIAL SHIT HITS THE FAN, VOLUNTEERS",0
                dc.b "COULD ACCEPT THE 'HESSIAN' ENHANCEMENTS",0
                dc.b "FOR INCREASED CHANCES OF SURVIVAL. HOW",0
                dc.b "MUCH THAT WOULD HELP, I DON'T KNOW.",0
                dc.b " ",0
                dc.b "- AMOS",0,0

txtOfficeComputer4:
                     ;0123456789012345678901234567890123456789
                dc.b "RE: PUREXO SERVICES",0
                dc.b " ",0
                dc.b "ON BEHALF OF THE EMPLOYEES I WOULD ASK",0
                dc.b "FOR THE FOLLOWING DESSERTS TO BE SERVED",0
                dc.b "MORE OFTEN DUE TO THEIR CHALLENGING",0
                dc.b "NATURE:",0
                dc.b " ",0
                dc.b "BUN PUDDING",0
                dc.b "ORANGE RICE",0
                dc.b " ",0
                dc.b "--",0
                dc.b "MARY OHR",0
                dc.b "SENIOR COORDINATOR",0,0

                checkscriptend