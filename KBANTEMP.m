KBANTEMP ; OSE/SMH - Read the temperature on a Raspberry Pi;2018-04-22  9:38 pm
 ;;0.1;SAM'S INDUSTRIAL CONGLOMERATES;
 ;
 ; Reads temperature from a DS18B20 Digital Temperature Sensor
 ; Cf. https://learn.adafruit.com/adafruits-raspberry-pi-lesson-11-ds18b20-temperature-sensing/hardware
 ;
INTERACTIVE ; [Public] Interactive entry point
 ;
 ; According to the datasheet, at 12 bit precision (Default) we can only read every 750ms.
 ;
 N FD S FD=$$GETD()
 N F S F="w1_slave"
 ;
 N TRY F TRY=1:1:10 D
 . N POP
 . D OPEN^%ZISH("F1",FD,F,"R")
 . I $G(POP) W "ERROR READING FILE",! QUIT
 . ;
 . U IO
 . N CNT S CNT=0
 . N DATA
 . F  R X:2 Q:$$STATUS^%ZISH()  S CNT=CNT+1,DATA(CNT)=X
 . D CLOSE^%ZISH("F1")
 . ;
 . I '$D(DATA) QUIT  ; Nothing read
 . ;
 . ; First line ending must equal YES
 . I $E(DATA(1),$L(DATA(1))-2,$L(DATA(1)))'="YES" QUIT
 . ;
 . ; Temperature reported on 2nd line after t=
 . N T S T=$P(DATA(2),"t=",2)/1000
 . W T,!
 QUIT
 ;
GETD() ; $$ [Public] Get Temperature Sensor Reading directory
 ; Find the directory name (first 28* in /sys/bus/w1/devices)
 N A,B S A("28*")=""
 D LIST^%ZISH("/sys/bus/w1/devices","A","B")
 N D S D=$O(B(""))
 Q:D=""
 ;
 ; FD = Full directory
 ; F = file name
 N FD S FD="/sys/bus/w1/devices/"_D_"/"
 quit FD
 ;
BACKGROUND ; [Public] Save 10 temperatures to Fileman
 ; 113100001 -> file number
 N FD S FD=$$GETD()
 N F S F="w1_slave"
 ;
 N TRY F TRY=1:1:10 D
 . N POP
 . D OPEN^%ZISH("F1",FD,F,"R")
 . I $G(POP) W "ERROR READING FILE",! QUIT
 . ;
 . U IO
 . N CNT S CNT=0
 . N DATA
 . F  R X:2 Q:$$STATUS^%ZISH()  S CNT=CNT+1,DATA(CNT)=X
 . D CLOSE^%ZISH("F1")
 . ;
 . I '$D(DATA) QUIT  ; Nothing read
 . ;
 . ; First line ending must equal YES
 . I $E(DATA(1),$L(DATA(1))-2,$L(DATA(1)))'="YES" QUIT
 . ;
 . ; Temperature reported on 2nd line after t=
 . ; ?+1 b/c we may have two temperatures within same second (we read one every 0.750 second)
 . N TEMP S TEMP=$P(DATA(2),"t=",2)/1000
 . N FDA
 . S FDA(113100001,"?+1,",.01)=$$NOW^XLFDT()
 . S FDA(113100001,"?+1,",.02)=TEMP
 . N DIERR
 . D UPDATE^DIE(,"FDA")
 QUIT
 ;
TASKRUN ; [Public] Run the code in the background
 N %VOTH S %VOTH("ZTDTH")=$H
 N % S %=$$NODEV^XUTMDEVQ("TASK^KBANTEMP","Temperature Reading Task",,.%VOTH,1)
 QUIT
 ;
TASK ; [Private] Run the Temperature Reader
 N FD S FD=$$GETD()
 N F S F="w1_slave"
 N LASTTEMP S LASTTEMP=0
 F  D  Q:$$S^%ZTLOAD(LASTTEMP)
 . N POP
 . D OPEN^%ZISH("F1",FD,F,"R")
 . I $G(POP) W "ERROR READING FILE",! QUIT
 . ;
 . U IO
 . N CNT S CNT=0
 . N DATA
 . F  R X:2 Q:$$STATUS^%ZISH()  S CNT=CNT+1,DATA(CNT)=X
 . D CLOSE^%ZISH("F1")
 . ;
 . I '$D(DATA) QUIT  ; Nothing read
 . ;
 . ; First line ending must equal YES
 . I $E(DATA(1),$L(DATA(1))-2,$L(DATA(1)))'="YES" QUIT
 . ;
 . ; Temperature reported on 2nd line after t=
 . ; ?+1 b/c we may have two temperatures within same second (we read one every 0.750 second)
 . N TEMP S TEMP=$P(DATA(2),"t=",2)/1000
 . N FDA
 . S FDA(113100001,"?+1,",.01)=$$NOW^XLFDT()
 . S FDA(113100001,"?+1,",.02)=TEMP
 . N DIERR
 . D UPDATE^DIE(,"FDA")
 . S LASTTEMP=TEMP
 I $$S^%ZTLOAD() S ZTSTOP=1
 QUIT
