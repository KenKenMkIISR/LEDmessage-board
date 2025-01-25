REM Akizuki Denshi 32x16xN dot LED Matrix
REM SPI I/F for MachiKania type PU mini
REM Scroll Yahoo! News
REM Notice!
REM  LED board must be connected to SPI1

REM Connection

REM Machi  Board1  Board1  Board2  Board2
REM Kania   CN1     CN2     CN1     CN2

REM MOSI  - SIN1   SOUT3  - SIN1
REM         SIN2 - SOUT1    SIN2  - SOUT1
REM         SIN3 - SOUT2    SIN3  - SOUT2
REM GP0   - LATCH  LATCH  - LATCH
REM GP0   - STROBE STROBE - STROBE
REM SCK  -R-CLOCK(R:120ohm)
REM +5V   - LEDPWR LEDPWR - LEDPWR
REM +3.3V - ICPWR  ICPWR  - ICPWR
REM GND   - GND    GND    - GND

USECLASS CKNJ16
USECLASS WGET

USEVAR BUF,ROW,LATCH
USEVAR NUM

NUM=4:REM The number of LED matrix board
DIM BUF(16*NUM):REM Video memory
ROW=0:REM Current row number being output
LATCH=0:REM GP0 (Also connect to STROBE)
OUT LATCH,1

CKNJ16::INIT("UTF-8")

SYSTEM 200,0:REM Video OFF
SPI 20000,16,0:REM 20MHz/16bit/mode0

REM Set timer interrupt interval 200us
USETIMER 200
INTERRUPT TIMER,PUTLED

RESTORE URLS
REM Main loop
DO
 U$=READ$()
 IF LEN(U$)=0 THEN
  RESTORE URLS
  U$=READ$()
 ENDIF
 WGET::FORFILE("NEWS.TXT",U$)
 F=0
 DO
  FOPEN "NEWS.TXT","r"
  FSEEK F
  S$=FINPUT$()
  F=FSEEK()
  FCLOSE
  IF LEN(S$)=0 THEN BREAK
  GOSUB PRTNEWS,S$
 LOOP
LOOP

LABEL PRTNEWS
 REM Print a line between <title></title>
 VAR P,Q,T,I,Y,W
 P=ARGS(1)
 I=GOSUB(SEARCH,P,"<title>")
 IF I<0 THEN RETURN 0
 P=P+I+7
 I=GOSUB(SEARCH,P,"</title>")
 IF I<0 THEN RETURN 0
 T$=P$(0,I)
 Q=CKNJ16::GETBMP(T$,1,0)
 W=CKNJ16::GETDW()
 FOR I=0 TO W-1
  FOR Y=0 TO 15
   IF PEEK(Q+I+Y*W) THEN GOSUB SETP,NUM*32-1,Y
  NEXT
  WAIT 1
  GOSUB LSCROL
 NEXT
 DELETE Q
 FOR I=1 TO NUM*32
  WAIT 1
  GOSUB LSCROL
 NEXT
RETURN 1

LABEL SEARCH
 REM Seach a string in a string
 REM Return position or -1
 VAR A,B,P,S,I,D
 A=ARGS(1):B=ARGS(2)
 I=0
 DO
  P=A
  S=B
  DO
   IF PEEK(S)=0 THEN RETURN I
   D=PEEK(P)
   IF D=0 THEN RETURN -1
   IF D!=PEEK(S) THEN BREAK
   S=S+1
   P=P+1
  LOOP
  A=A+1
  I=I+1
 LOOP
RETURN -1

LABEL LSCROL
 REM Left scroll
 VAR I,J
 FOR I=0 TO 15
  J=0
  DO WHILE J<NUM-1
   BUF(J*16+I)=(BUF(J*16+I)>>1)+((BUF(J*16+I+16) AND 1)<<31)
   J=J+1
  LOOP
  BUF(NUM*16+I-16)=BUF(NUM*16+I-16)>>1
 NEXT
RETURN

LABEL SETP
 REM Set a point x,y
 VAR X,Y
 X=ARGS(1):Y=ARGS(2)
 IF X<0 OR X>=NUM*32 THEN RETURN
 IF Y<0 OR Y>=16 THEN RETURN
 DO WHILE X>=32
  X=X-32:Y=Y+16
 LOOP
 BUF(Y)=BUF(Y) OR (1<<X)
RETURN

LABEL PUTLED
 REM Output ROW line to LED matrix
 REM Interrupt survice routine
 VAR Z
 OUT LATCH,1
 FOR Z=NUM-1 TO 0 STEP -1
  SPIWRITE BUF(ROW+Z*16)>>16,BUF(ROW+Z*16),1<<(15-ROW)
 NEXT
 OUT LATCH,0
 ROW=(ROW+1) AND 15
RETURN

LABEL URLS
DATA "https://news.yahoo.co.jp/rss/topics/domestic.xml"
DATA "https://news.yahoo.co.jp/rss/topics/world.xml"
DATA "https://news.yahoo.co.jp/rss/topics/business.xml"
DATA "https://news.yahoo.co.jp/rss/topics/entertainment.xml"
DATA "https://news.yahoo.co.jp/rss/topics/sports.xml"
DATA "https://news.yahoo.co.jp/rss/topics/it.xml"
DATA "https://news.yahoo.co.jp/rss/topics/science.xml"
DATA "https://news.yahoo.co.jp/rss/topics/local.xml"
DATA ""
