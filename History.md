---
title: Historical Projects
description: Some rather historical projects.
---

I had some old floppy discs lying around and after more than 30 years, I thought that revitalizing some of my early projects might be a nice thing to do before they might finally become unreadable.
The process of bringing this to github was more elaborate than I thought, but in the end successful. Sorry for all non-german speaking folks, the programs are targeted at german speakers.  

First, my 20 year old PC was rendered disfunctional after some undefinable explosion (maybe a capacitor) during switching the power on.
Thus my floppy discs had to be read with an external USB drive, so after this was successful, I first retrieved a project that was used to help plan shifts in my wife's child-nurse department back in 1991 (I studied computer science at that time).

## Dienst (Shift planning software)

After getting all the files from the floppy disc, I discovered that no software from the 90's worked, so in order to get the documentation up and running and start the program, I found the [Dosbox project](http://www.dosbox.com) and abother hint to a free installation of [Word for DOS](http://download.microsoft.com/download/word97win/Wd55_be/97/WIN98/EN-US/Wd55_ben.exe).

Now I could run the executable again and the documentation finally was restored to a modern format using the [Legacy File Converter (Word for Word for DOS)](http://www.columbia.edu/~em36/legacyfileconverter.html).

So here is the documentation as a modern [PDF](https://raw.githubusercontent.com/rkapl123/rkapl123.github.io/master/Dienst/HANDBUCH.pdf), below some screenshots from the dos-based planning software:

### Entry Screen
![Image of screenshot1](https://raw.githubusercontent.com/rkapl123/rkapl123.github.io/master/Dienst/DienstSchedule.PNG)

### Schedule editing
![Image of screenshot2](https://raw.githubusercontent.com/rkapl123/rkapl123.github.io/master/Dienst/DienstEntryScreen.PNG)

If you're interested, you can even hack the pascal source DIENST.PAS download from [here](https://github.com/rkapl123/rkapl123.github.io/tree/master/Dienst) and compile it with the contained turbo pascal 6.0 (for a fresh install go to [https://winworldpc.com/product/turbo-pascal/6x](https://winworldpc.com/product/turbo-pascal/6x)).

The documentation is also still there in source format (Word for DOS format), it's called `HANDBUCH_orig.DOC`.

Another program that I wrote even further back in time (1985, when I started with computers we had the [Commodore 64 era](https://www.commodore.ca)) was used to help me with the heaps of software (mostly games) that accumulated a lot back then.
I called it

## Diskmanager C64

The Software was written with very tight memory management in mind (all my collected software had to fit into 64KB (minus the program) !), so many functions were put into assembler code residing "below" the ROM area (the C-64 had a technique of mapping multiple memory sources (System ROM and RAM) onto the same address area by switching these on and off)
Unfortunately I haven't yet found the assembler code (you can see it being loaded in the first line). Until then have fun reading almost completely unintelligible code (and bad style as well).
To help you refresh your memory in C-64 BASIC, here is the [C-64 programmers reference guide](https://www.commodore.ca/commodore-manuals/commodore-64-programmers-reference-guide/).

The many `#` characters are actually unconvertable special characters used to format text (bold, background colour, inverse, etc.)

```
READY.

1 IFA=0THENA=1:LOAD"LIBRARY $*",8,1
100 POKE53280,11:POKE53281,11
110 POKE53277,255
120 FORX=0TO7:POKE53287+X,15:POKE2040+X,11:NEXT
130 FORX=0TO14STEP2:POKE53249+X,192:NEXT
140 FORX=0TO1:FORY=0TO5:POKE704+X*10*3+Y,255:NEXT:NEXT
150 FORX=0TO8STEP2:POKE53248+X,24+(X/2)*6*8:NEXT
160 POKE53264,96:POKE53258,8:POKE53260,56:POKE2047,13:POKE53262,140
170 FORX=0TO3*9STEP3:POKE832+X,3:NEXT
180 REM ** SONSTIGES **
181 S1=49152:S2=50060:S3=50257:S4=50309:S5=50336:S6=50369:S7=50379:S8=50484
182 S9=50500:T1=50521:T2=50600
185 X$="                                     "
190 PRINTCHR$(8);:DIMA$(16)
200 A$(0)="LIBRARY V1.0":T3=50312
210 A$(1)="BITTE DISKETTE EINLEGEN"
220 A$(2)="AUFNEHMEN (J/N)?":T4=50670
230 A$(3)="DISKETTENBEFEHLE":MAX=100
240 A$(4)="SORTIEREN":T5=50720
250 A$(5)="GELADEN WIRD: ":T6=50757:T7=50808
260 A$(6)="ABSPEICHERN"
270 A$(7)="#D#ISKETTE(N) ODER #S#PEICHER ?"
280 A$(8)="AUSDRUCKEN"
290 A$(9)="GESCHRIEBEN WIRD:
300 A$(10)="DISKETTE WECHSELN (J/N)?"
310 A$(11)="DATUM :"
320 A$(12)="UEBERSCHRIFT :"
330 A$(13)="EINTRAG AENDERN"
340 A$(14)="EINTRAG EINFUEGEN"
345 A$(15)="ERROR:"
360 C$="#                                        "
370 DIMPRG$(200):REM RESTORE
385 SYSS5:POKE56325,40
390 PRINT"#":SYSS6,18:FORX=0TO5:PRINT"#"PRG$(X):NEXT:SYST3:OPEN1,8,15:CLOSE1
400 PRINTPRG$(6));:POKE53269,255:PS=0
440 TEXT=0:GOSUB 10020
445 GOSUB 10040
450 IFA$="#"THEN 625
460 IFA$="#"THEN 750
470 IFA$="#"THEN 840
480 IFA$="#"THEN GOSUB 920: GOTO 390
490 IFA$="#"THEN 1500
500 IFA$="#"THEN 1310
510 IFA$="#"THEN GOSUB 1810
520 IFA$="#"THEN 1130
530 IFA$="#"THEN 1000
540 IFA$="#"THEN 1040 
550 IFA$="#"THEN 1080 
570 IFA$="#"THEN 390
580 IFA$="#"THEN 1190
590 IFA$="#"THEN 1250
595 IFA$="#"THEN 1440
600 GOTO440
605 REM
610 REM ** AUFNEHMEN **
620 REM
625 TEXT=1:GOSUB 10010:GOSUB 10040:POKE53269,132
626 OPEN1,8,15:OPEN2,8,5,"#"
627 PRINT#1,"B-R";5;0;18;0:PRINT#1,"B-P"5;162:GET#2,A$:GET#2,B$
628 POKE2512,ASC(A$):POKE2513,ASC(B$):CLOSE2:CLOSE1
630 SYST1:TEXT=2:GOSUB10010
640 SYST2:IFPEEK(783)=240THEN715
660 SYSS6,18:PRINT"#"LEFT$(X$,36)
670 GOSUB 10040:IFA$="J"THEN700
690 GOTO640
700 PRG$(PRG)=LEFT$(X$,36):PRG=PRG+1:IFPRG>MAXTHENGOTO715
710 SYSS4:GOTO640
715 POKE53280,15:SYS46374:POKE53280,11:GOTO390
720 REM
730 REM ** DISKCOMMAND **
740 REM
750 TEXT=3:GOSUB 10010:POKE53269,255:POKE646,15
760 SYSS2:IFPEEK(783)<>48THEN390 
770 SYST7:POKE53269,0
780 IFLEFT$(X$,1)="$"THENPRINT"#":SYSS6,18:SYSS7:GOSUB10040:GOTO750
790 GOSUB10010:OPEN1,8,15:PRINT#1,LEFT$(X$,16)
800 CLOSE1:GOTO750
810 REM
820 REM ** DISKERROR **
830 REM
840 POKE53269,0:TEXT=15:GOSUB10010
850 SYSS6,0:PRINT"######";
860 OPEN1,8,15:PRINT"##"; 
870 GET#1,B$:PRINTB$;:IFB$<>CHR$(13)THEN870
875 POKE53280,15:SYS46374:POKE53280,11
880 CLOSE1:PRINT"#";:GOSUB10040:GOTO390 
890 REM
900 REM ** SORTIEREN ** 
910 REM
920 TEXT=7:GOSUB 10010:GOSUB 10040:TEXT=4:GOSUB 10010:IFA$="D"THEN1670 
930 SYSS1,PRG,PRG$(0):PS=0
940 PRINT"###############";PS:IFPS=PRGANDPRG<0THENPRG=0:PS=0:RETURN 
945 IFPS=PRGTHENPS=0:RETURN
950 IFLEFT$(PRG$(PS),16)=LEFT$(PRG$(PS+1),16)THEN GOSUB 10070:GOTO 940 
960 PS=PS+1:GOTO 940
970 REM
980 REM ** CLEAR **
990 REM
1000 FORX=0TOPRG:PRG$(X)="":NEXTX:PRG=0:POKE53280,15:SYS46374:POKE53280,11
1005 GOTO390
1010 REM
1020 REM ** DELETE **
1030 REM
1040 IFPS=PRG-1THENGOSUB10070:SYSS8:GOSUB10020:GOTO1190
1042 IFPRG>=0THENGOSUB 10070
1045 SYSS8:SYSS6,24:PRINT"#"PRG$(PS+6);:GOTO440 
1050 REM
1060 REM ** INSERT **
1070 REM
1080 TEXT=14:GOSUB 10020:IFPS=PRG-1THENSYSS4:SYSS6,18:PRINT"#":SYSS2
1082 IFPS=PRG-1ANDPEEK(783)<>48THENPS=PS+1:GOTO 1190
1083 IFPS=PRG-1THENPS=PS+1:PRG=PRG+1:SYST7:PRG$(PS)=LEFT$(X$,36):GOTO440 
1085 IFPRG>MAXTHEN440
1087 SYSS9:SYSS6,18:PRINTC$;:SYSS9:PRINTC$;:SYSS8
1090 SYSS6,24:PRINTPRG$(PS+5);:SYSS6,18:PRINT"#":SYSS2:IFPEEK(783)<>48THEN1045 
1095 SYST7:GOSUB10090:PRG$(PS)=LEFT$(X$,36):GOTO440 
1100 REM
1110 REM ** AENDERN **
1120 REM
1130 TEXT=13:GOSUB 10020
1140 PRINT"#":SYSS2:IFPEEK(783)<>48THENSYSS6,18:PRINTPRG$(PS)"   ";:GOTO440 
1150 SYST7:PRG$(PS)=LEFT$(X$,36):GOTO440 
1160 REM 
1170 REM ** RAUF ** 
1180 REM
1190 IFPS=0ORPRG=0THEN445
1200 SYSS3:IFPS-18<0THENSYSS6,1:PRINTC$;:PS=PS-1:GOTO445
1210 SYSS6,1:PRINTPRG$(PS-18);:PS=PS-1:GOTO445 
1220 REM 
1230 REM ** RUNTER **
1240 REM
1250 IFPS=PRG-1ORPRG=0THEN445
1260 SYSS4:IFPS+7>PRGTHENPS=PS+1:GOTO445
1270 SYSS6,24:PRINTPRG$(PS+7);:PS=PS+1:GOTO445 
1280 REM
1290 REM ** SPEICHERN ** 
1300 REM
1310 TEXT=6:GOSUB10010:GOSUB930:PS=0:POKE53269,0:TEXT=1:GOSUB10010:GOSUB10040
1312 TEXT=9:GOSUB10010
1315 PRG$(PRG)=" "
1320 FORX=32 TO 90
1330 IFX=34ORX=35ORX=36ORX=42ORX=44ORX=58ORX=61ORX=63THENNEXTX 
1335 IFASC(LEFT$(PRG$(PS),1))<>XTHENNEXTX
1340 OPEN2,8,2,CHR$(X)+",S,R":CLOSE2:OPEN1,8,15:INPUT#1,Y:CLOSE1:IFY<>0THEN1380
1350 OPEN2,8,2,CHR$(X)+",S,A":POKE53280,15:SYS46374:POKE53280,11
1355 IFPRG$(PS)=""THENCLOSE2:GOTO390
1360 IFASC(LEFT$(PRG$(PS),1))<>XTHENCLOSE2:NEXTX
1365 IFPS=PRGTHENCLOSE2:GOTO390 
1370 SYSS6,18:PRINTPRG$(PS):PRINT#2,PRG$(PS):PS=PS+1:GOTO1360 
1380 TEXT=10:GOSUB 10010:GOSUB 10040
1390 IFA$="J"THENTEXT=9:GOSUB 10000:CLOSE 2:GOTO 1340
1400 CLOSE2:GOTO390
1410 REM
1420 REM ** RVS-HOME **
1430 REM
1440 TEXT=0:GOSUB10010:SYSS6,1
1450 PS=PRG-1:FORX=PS-17TOPS:IFX<0THENPRINTC$:NEXTX:IFPS<0THENPS=0:GOTO440 
1460 PRINTPRG$(X):NEXTX:SYST3:GOTO440
1470 REM 
1480 REM ** LADEN ** 
1490 REM
1500 TEXT=1:GOSUB 10010:GOSUB 10040
1510 TEXT=5 : GOSUB 10010: X=32 : POKE53269,0 
1515 PS=0
1520 OPEN2,8,2,CHR$(X)+",S,R":CLOSE2:OPEN1,8,15: INPUT#1,Y:CLOSE1:IFY<>0THEN1560
1525 OPEN2,8,2,CHR$(X)+",S,R":POKE53280,15:SYS46374:POKE53280,11 
1530 INPUT#2,PRG$(PS):IFPRG$(PS)="["THEN 1540
1535 SYSS6,18:PRINT"#"PRG$(PS):PS=PS+1:PRG=PRG+1:IFPRG>MAXTHEN 1590 
1540 IFST<>64THEN1530
1545 X=X+1:CLOSE2:IFX=34ORX=35ORX=36ORX=42ORX=44ORX=58ORX=61ORX=63THEN1545
1550 IFX=91THEN390
1555 GOTO1520 
1560 TEXT=10:GOSUB 10010:GOSUB 10040
1570 IFA$="J"THENTEXT=9:GOSUB 10000: GOTO 1550 
1580 CLOSE2:GOTO390
1590 PRINT"###W#EITERLADEN, #D#RUCKEN ODER #B#ENDEN ?      #":GOSUB 10040
1600 IFA$="B"THEN CLOSE2:GOTO390
1610 IFA$="W"THEN PS=0:GOTO1530
1620 IFA$="D"THEN GOSUB DRUCKEN
1630 GOTO1590
1640 REM
1650 REM ** DISK SORTIEREN **
1660 REM
1670 FORX= 32 TO 90:PRINT"##############(DISK):";CHR$(X):PRG=0:PS=0 
1680 IFX=34ORX=35ORX=36ORX=42ORX=44ORX=58ORX=61ORX=63THENNEXTX
1690 OPEN2,8,2,CHR$(X)+",S,R":CLOSE2:OPEN1,8,15:INPUT#1,Y:CLOSE1:IFY<>OTHEN1800
1700 OPEN2,8,2,CHR$(X)+",S,R":POKE53280,15:SYS46374:POKE53280,11:INPUT#2,X$
1710 IFST=64THEN1735
1720 INPUT#2,PRG$(PS):PS=PS+1:PRG=PRG+1:IFPRG>MAX THEN ERROR
1730 GOTO1710
1735 CLOSE2 
1740 GOSUB 900:OPEN1,8,15,"S:"+CHR$(X):CLOSE1
1750 OPEN2,8,2,CHR$(X)+",S,W":PS=0:PRINT#2,"["
1760 PRINT#2,PRG$(PS):PS=PS+1:IFPS<>PRG-1THEN1760
1770 CLOSE2:NEXTX:RETURN
1780 REM
1790 REM ** DRUCKEN **
1800 REM
1810 END
10000 REM ** KOPFZEILE + BEMERKUNG **
10010 PRINT"#" 
10020 PRINT"###"C$"#"A$(TE);TAB(30)PRG;"#":RETURN
10030 REM ** TASTENDRUCK **
10040 GETA$:IFA$=""THEN10040
10050 RETURN
10060 REM ** DELETE EINEN EINTRAG **
10070 SYST6,PEEK(47)+PEEK(48)*256+65+3*PS:PRG=PRG-1:IFPRG<0THENPRG=0:RETURN
10075 RETURN
10080 REM ** INSERT EINEN EINTRAG **
10090 SYST5,PEEK(47)+PEEK(48)*256+66+3*PS:PRG=PRG+1:RETURN

READY.
```
