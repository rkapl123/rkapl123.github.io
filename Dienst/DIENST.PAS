Program Dienst;

(* Dieses Programm erm”glicht die Erstellung eines Dienstplanes         *)
(* zur flexiblen Diensteinteilung bei einer beliebigen Anzahl von       *)
(* Pflegebediensteten. (maximal 75 Personen)                            *)
(* Autor : Roland Kapl                                                  *)
(* Kommentare in Englisch                                               *)



uses Crt,Dos;

const persmax = 75;   (* not greater than 75 !! (Screen!!) *)
      Holimax = 20;   (* maximum count of Holidays *)
      leer : ARRAY[1..4] OF STRING[31] =
                          ('MMMMMMMMMMMMMMMMMMMMMMMMMMMM'  ,
                           'MMMMMMMMMMMMMMMMMMMMMMMMMMMMM'  ,
                           'MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM'  ,
                           'MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM');
      Wholeer : ARRAY[1..4] OF STRING[31] =
                          ('                            '  ,
                           '                             '  ,
                           '                              '  ,
                           '                               ');
      dayHours = 12.25;          (* Length of a day shift *)
      niteHours = 12.25;         (* Length of a night shift *)
      mornHours = 8;             (* Length of a morning shift *)
      evenHours = 8.5;           (* Length of a evening shift *)
      defaultHours    = 173.0;   (* default for Work-Hours of Person *)
      SollSumVormDef  = 2;       (* Defaults for Staff count of Station *)
      SollSumNachmDef = 2;
      SollSumNachtDef = 2;
      morn = ' F';               (* Representations of Schedule *)
      aft = ' S';                (* On Screen and on Paper *)
      nite = ' N';
      day = ' T';
      sle = ' R';
      fre1 = '--';
      fre2 = '**';
      hol = ' U';
      cour = ' K';
                        (* These are the Default Settings for Holidays *)
      fixItem : ARRAY [0..Holimax-1,1..2] OF INTEGER =
              ( (1,1),
                (1,6),
                (4,11),      (* Month, Day *)
                (4,12),
                (5,1),
                (5,20),
                (5,30),
                (5,31),
                (6,10),
                (8,15),
                (10,26),
                (11,1),
                (12,8),
                (12,25),
                (12,26),
                (12,31),
                (0,0),
                (0,0),
                (0,0),
                (0,0) );


var Date,Schedname           : STRING;
    password1,password2      : STRING;
    Year                     : STRING[3];
    choice,
    currentPerson,
    curPersID,
    numPerson,
    menuPosition,
    responsible              : INTEGER;
    nextPersonID             : WORD;
    Y,M                      : WORD;
    Person                   : ARRAY [1..persmax] OF STRING[26];
    PersonID                 : ARRAY [1..persmax] OF WORD;
    Password                 : ARRAY [1..persmax] OF STRING;
    Overtime                 : ARRAY [1..persmax] OF STRING[31];
    Plan                     : ARRAY [1..persmax] OF STRING[31];
    Suggest                  : ARRAY [1..persmax] OF STRING[31];
    Who                      : ARRAY [1..persmax] OF STRING[31];
    Hours                    : ARRAY [1..persmax] OF REAL;
    changeable               : ARRAY [1..persmax] OF INTEGER;
    SumVormittag             : ARRAY [1..31] OF INTEGER;
    SumNachmittag            : ARRAY [1..31] OF INTEGER;
    SumNachtdienst           : ARRAY [1..31] OF INTEGER;
    Nachtdienste             : ARRAY [1..persmax] OF INTEGER;
    Dienststunden            : ARRAY [1..persmax] OF REAL;
    VirtSumVormittag         : ARRAY [1..31] OF INTEGER;
    VirtSumNachmittag        : ARRAY [1..31] OF INTEGER;
    VirtSumNachtdienst       : ARRAY [1..31] OF INTEGER;
    VirtNachtdienste         : ARRAY [1..persmax] OF INTEGER;
    VirtDienststunden        : ARRAY [1..persmax] OF REAL;
    Oversum                  : ARRAY [1..persmax] OF REAL;
    ex                       : BOOLEAN;
    SollSumVorm              : INTEGER;
    SollSumNachm             : INTEGER;
    SollSumNacht             : INTEGER;
    SonnFeiertag             : ARRAY[1..31] OF BOOLEAN;






function MonthLength (Y,M :WORD):BYTE;
const len: ARRAY [1..12] OF BYTE = (31,28,31,30,31,30,31,31,30,31,30,31);

begin
     if (M=2) AND ((y-1992) MOD 4 = 0) then Monthlength:=29   (* Schaltjahr *)
     else Monthlength:=len[m];
end;




procedure message (msg1,msg2:STRING);
var key:CHAR;

begin
     Window (1, 1, 80, 25);
     TextColor(Lightgray);
     TextBackground(Black);
     Clrscr;
     gotoxy(1,12);
     writeln(msg1);
     writeln;
     writeln(msg2);
     gotoxy(19,25);
     TextBackground(Blue);
     write('---- Bitte irgendeine Taste bet„tigen ----');
     TextBackground(Black);
     key:=Readkey;
end;




procedure setDateString(yea,mon:INTEGER;var strng:STRING);
const item : ARRAY [1..12] OF STRING[10] =
           ('Januar','Februar','M„rz','April','Mai','Juni','Juli',
            'August','September','Oktober','November','Dezember');
Var   ystring:STRING[4];

begin
     Str(yea,ystring);
     strng:=item[mon]+' '+ystring;
end;




procedure convertDate (Y,M :WORD;VAR FileName:STRING);
const month : ARRAY [1..12] OF STRING[10] =
           ('JANUAR.','FEBRUAR.','MAERZ.','APRIL.','MAI.','JUNI.','JULI.',
            'AUGUST.','SEPTEMBE.','OKTOBER.','NOVEMBER.','DEZEMBER.');
var extens: INTEGER;

begin
     extens:=y;
     extens:=extens mod 1000;
     extens:=extens mod 100;
     extens:=extens+100*(y DIV 1000);
     Str(extens, Year);
     Filename:=month[M]+Year;
end;




function testOK:BOOLEAN;

begin
     if Date = '' then
     begin
          message ('Es wurde noch nie ein Dienstplan erstellt ...',
                   '... mit Menpunkt "Person hinzufgen" k”nnen Sie Personen eintragen ! ');
          testOK:=FALSE;
          exit;
     end
     else
         testOK:=TRUE;
end;




procedure recalc;
var i,j,sum : INTEGER;

begin
     For i:=1 to 31 do
         begin
         SumVormittag[i]:=0;
         SumNachmittag[i]:=0;
         SumNachtdienst[i]:=0;
         end;
     For j:=1 to Persmax do
         begin
         Dienststunden[j]:=0;
         Nachtdienste[j]:=0;
         end;
     For i:=1 to MonthLength(Y,M) do
         For j:=1 to numPerson do
             begin
             case Plan[j,i] of
                  'T': begin
                       inc (SumVormittag[i]);
                       inc (SumNachmittag[i]);
                       Dienststunden[j]:=Dienststunden[j]+dayHours;
                       end;
                  'V': begin
                       inc (SumVormittag[i]);
                       Dienststunden[j]:=Dienststunden[j]+mornHours;
                       end;
                  'A': begin
                       inc (SumNachmittag[i]);
                       Dienststunden[j]:=Dienststunden[j]+evenHours;
                       end;
                  'N': begin
                       inc (SumNachtdienst[i]);
                       inc (Nachtdienste[j]);
                       Dienststunden[j]:=Dienststunden[j]+niteHours;
                       end;
                  end;
             end;
end;




procedure virtRecalc;
var i,j,sum : INTEGER;

begin
     For i:=1 to 31 do
         begin
         virtSumVormittag[i]:=0;
         virtSumNachmittag[i]:=0;
         virtSumNachtdienst[i]:=0;
         end;
     For j:=1 to Persmax do
         begin
         virtDienststunden[j]:=0;
         virtNachtdienste[j]:=0;
         end;
     For i:=1 to MonthLength(Y,M) do
         For j:=1 to numPerson do
         begin
             if Suggest[j,i] = ' ' then
             begin
               case Plan[j,i] of
                  'T': begin
                       inc (virtSumVormittag[i]);
                       inc (virtSumNachmittag[i]);
                       virtDienststunden[j]:=virtDienststunden[j]+dayHours;
                       end;
                  'V': begin
                       inc (virtSumVormittag[i]);
                       virtDienststunden[j]:=virtDienststunden[j]+mornHours;
                       end;
                  'A': begin
                       inc (virtSumNachmittag[i]);
                       virtDienststunden[j]:=virtDienststunden[j]+evenHours;
                       end;
                  'N': begin
                       inc (virtSumNachtdienst[i]);
                       inc (virtNachtdienste[j]);
                       virtDienststunden[j]:=virtDienststunden[j]+niteHours;
                       end;
               end;
             end
             else
             begin
               case Suggest[j,i] of
                  'T': begin
                       inc (virtSumVormittag[i]);
                       inc (virtSumNachmittag[i]);
                       virtDienststunden[j]:=virtDienststunden[j]+dayHours;
                       end;
                  'V': begin
                       inc (virtSumVormittag[i]);
                       virtDienststunden[j]:=virtDienststunden[j]+mornHours;
                       end;
                  'A': begin
                       inc (virtSumNachmittag[i]);
                       virtDienststunden[j]:=virtDienststunden[j]+evenHours;
                       end;
                  'N': begin
                       inc (virtSumNachtdienst[i]);
                       inc (virtNachtdienste[j]);
                       virtDienststunden[j]:=virtDienststunden[j]+niteHours;
                       end;
                  't': begin
                       inc (virtSumVormittag[i]);
                       inc (virtSumNachmittag[i]);
                       virtDienststunden[j]:=virtDienststunden[j]+dayHours;
                       end;
                  'v': begin
                       inc (virtSumVormittag[i]);
                       virtDienststunden[j]:=virtDienststunden[j]+mornHours;
                       end;
                  'a': begin
                       inc (virtSumNachmittag[i]);
                       virtDienststunden[j]:=virtDienststunden[j]+evenHours;
                       end;
                  'n': begin
                       inc (virtSumNachtdienst[i]);
                       inc (virtNachtdienste[j]);
                       virtDienststunden[j]:=virtDienststunden[j]+niteHours;
                       end;
                  '4': begin
                       inc (virtSumVormittag[i]);
                       inc (virtSumNachmittag[i]);
                       virtDienststunden[j]:=virtDienststunden[j]+dayHours;
                       end;
                  '6': begin
                       inc (virtSumVormittag[i]);
                       virtDienststunden[j]:=virtDienststunden[j]+mornHours;
                       end;
                  '!': begin
                       inc (virtSumNachmittag[i]);
                       virtDienststunden[j]:=virtDienststunden[j]+evenHours;
                       end;
                  '.': begin
                       inc (virtSumNachtdienst[i]);
                       inc (virtNachtdienste[j]);
                       virtDienststunden[j]:=virtDienststunden[j]+niteHours;
                       end;
               end;
             end

         end;
end;




function FileExists(FileName: string): Boolean;
var  f: file;

begin
  {$I-}
  Assign(f, FileName);
  Reset(f);
  Close(f);
  {$I+}
  FileExists := (IOResult = 0) and (FileName <> '');
end;




function getValue (Xpos,Ypos:INTEGER;VAR def:REAL;
                  lo,hi:REAL;delta:REAL):INTEGER;
var  key  : CHAR;
     fact : INTEGER;

begin
     TextBackground(Blue);
     gotoxy (Xpos,Ypos);
     if delta<>1 then write(def:6:2)
     else write(trunc(def),'  ');
     repeat
       if delta=0.5 then
       begin
       Textbackground(Black);
       Textcolor(Green);
         gotoxy(69,wherey);
         write('šstd:',Oversum[choice]+def:6:2);
       TextBackground(Blue);
       TextColor(White);
       end;
       key:= readkey;
       if key = Chr(0) then
       begin
           key:=readkey;
           if ord(key)= 72 then  (* down *)
              begin
                   if def+delta < hi then def:=def+delta
                   else def:=hi;
                   gotoxy(Xpos,Ypos);
                   TextBackground (blue);
                   if delta<>1 then write(def:6:2)
                   else write(trunc(def),' ');
              end;

           if ord(key)= 80 then  (* up *)
              begin
                   if def-delta > lo then def:=def-delta
                   else def:=lo;
                   gotoxy(Xpos,Ypos);
                   TextBackground (blue);
                   if delta<>1 then write(def:6:2)
                   else write(trunc(def),' ');
              end;
           if ord(key)= 77 then  (* right *)
              begin
                   if delta=0.5 then fact:=5
                   else fact:=1;
                   if def+delta*10/fact < hi then def:=def+delta*10/fact
                   else def:=hi;
                   gotoxy(Xpos,Ypos);
                   TextBackground (blue);
                   if delta<>1 then write(def:6:2)
                   else write(trunc(def),' ');
              end;
           if ord(key)= 75 then  (* left *)
              begin
                   if delta=0.5 then fact:=5
                   else fact:=1;
                   if def-delta*10/fact > lo then def:=def-delta*10/fact
                   else def:=lo;
                   gotoxy(Xpos,Ypos);
                   TextBackground (blue);
                   if delta<>1 then write(def:6:2)
                   else write(trunc(def),' ');
              end;
           if ord(key)= 73 then  (* Pgup *)
              begin
                   if def+delta*100 < hi then def:=def+delta*100
                   else def:=hi;
                   gotoxy(Xpos,Ypos);
                   TextBackground (blue);
                   if delta<>1 then write(def:6:2)
                   else write(trunc(def),' ');
              end;
           if ord(key)= 81 then  (* Pgdn *)
              begin
                   if def-delta*100 > lo then def:=def-delta*100
                   else def:=lo;
                   gotoxy(Xpos,Ypos);
                   TextBackground (blue);
                   if delta<>1 then write(def:6:2)
                   else write(trunc(def),' ');
              end;
       end;
     until ord(key)=13;
     TextBackground(Black);
     getValue:=trunc(def);
end;




function mainmenu: INTEGER;
const numitems = 13;
      start    = 9;

var item : ARRAY [0..numitems-1] OF STRING;
    i,j  : INTEGER;
    key  : CHAR;

begin
     item[0] := 'Person einsteigen';
     item[1] := 'Person aussteigen';
     item[2] := 'Diesen Dienstplan bearbeiten';
     item[3] := 'Einen Dienstplan holen';
     item[4] := 'Neuen Dienstplan erstellen';
     item[5] := 'Diesen Dienstplan ausdrucken';
     item[6] := 'Person l”schen';
     item[7] := 'Person hinzufgen';
     item[8] := 'Passwort „ndern';
     item[9] := 'Monatsstundenzahl (fr Person) „ndern';
     item[10] := 'Besetzungsanzahl (der Station) „ndern';
     item[11] := 'Feiertage des Jahres eingeben';
     item[12] := 'Programm beenden';
     Window (1, 1, 80, 25);
     TextBackground(Black);
     TextColor(Lightgray);
     ClrScr;
     gotoxy(24,24);
     if Date = '' then write ('Es wird kein Dienstplan bearbeitet.')
     else
     begin
          TextBackground(Blue);
          TextColor(White);
          write(Date);
          TextColor(Lightgray);
          TextBackground(Black);
          write(' wird gerade bearbeitet.');
          if currentPerson <> 0 then
          begin
               gotoxy(2,1);
               TextBackground(Blue);
               TextColor(White);
               write(Person[currentPerson]);
               TextColor(Lightgray);
               TextBackground(Black);
               write(' ist eingestiegen.');
          end
          else
          begin
               gotoxy(2,1);
               TextColor(Lightgray);
               TextBackground(Black);
               write('Niemand ist eingestiegen.');
          end
     end;
     gotoxy (29,6);
     write('H A U P T M E N š');
     gotoxy (29,7);
     write('-----------------');
     for i:=0 to numitems-1 do
         begin
         gotoxy (29,start+i);
         write(item[i]);
         end;
     TextBackground(Blue);
     gotoxy (29,start+menuPosition);
     write(item[menuPosition]);
     i:=menuPosition;
     repeat
           key:=readkey;
           j:=i;
           if ord(key)= 80 then
              begin
                   if i = numitems-1 then i:=0
                   else inc(i);
                   gotoxy(29,start+j);
                   TextBackground (Black);
                   write(item[j]);
                   gotoxy(29,start+i);
                   TextBackground (blue);
                   write(item[i]);
              end;
           if ord(key)= 72 then
              begin
                   if i=0 then i:=numitems-1
                   else dec(i);
                   gotoxy(29,start+j);
                   TextBackground (Black);
                   write(item[j]);
                   gotoxy(29,start+i);
                   TextBackground (blue);
                   write(item[i]);
              end
     until ord(key)=13;
     menuPosition:=i;
     mainmenu:=i+1;
     TextBackground (Black);
     TextColor(Lightgray);
end;




function Personmenu: INTEGER;
var i,j,k,zeile,spalte,spaltenanzahl  : INTEGER;
    key : CHAR;

begin
     Window (1, 1, 80, 25);
     TextBackground(Black);
     TextColor(Lightgray);
     ClrScr;
     spaltenanzahl := numPerson div 25;   (* Auswahl in Spalten zu 25 Zeilen *)
     spalte:=0;
     repeat
         if spalte = spaltenanzahl then zeile:= numPerson mod 25
         else zeile:=25;
         for j:=1 to zeile do
         begin
              if spalte > 0 then k:= 1
              else k:= 0;
              gotoxy (1+26*spalte+k,j);
              write(Person[spalte*25+j]);
         end;
         inc (spalte);
     until spalte > spaltenanzahl;
     TextBackground(Blue);
     gotoxy (1,1);
     write(Person[1]);
     i:=1;j:=1;
     repeat
           key:=readkey;
           j:=i;
           if ord(key)= 80 then         (* 1 Person down *)
              begin
                   if i = numPerson then i:=1
                   else inc(i);
                   spalte:=j div 25;
                   zeile:=j mod 25;
                   if zeile = 0 then
                   begin
                      zeile:=25;
                      dec (spalte);
                      if spalte < 0 then spalte := 0;
                   end;
                   if spalte > 0 then k:= 1
                   else k:= 0;
                   gotoxy(1+26*spalte+k,zeile);
                   TextBackground (Black);
                   write(Person[j]);
                   spalte:=i div 25;
                   zeile:=i mod 25;
                   if zeile = 0 then
                   begin
                      zeile:=25;
                      dec (spalte);
                      if spalte < 0 then spalte := 0;
                   end;
                   if spalte > 0 then k:= 1
                   else k:= 0;
                   gotoxy(1+26*spalte+k,zeile);
                   TextBackground (blue);
                   write(Person[i]);
              end;
           if ord(key)= 72 then          (* 1 Person up *)
              begin
                   if i=1 then i:=numPerson
                   else dec(i);
                   spalte:=j div 25;
                   zeile:=j mod 25;
                   if zeile = 0 then
                   begin
                      zeile:=25;
                      dec (spalte);
                      if spalte < 0 then spalte := 0;
                   end;
                   if spalte > 0 then k:= 1
                   else k:= 0;
                   gotoxy(1+26*spalte+k,zeile);
                   TextBackground (Black);
                   write(Person[j]);
                   spalte:=i div 25;
                   zeile:=i mod 25;
                   if zeile = 0 then
                   begin
                      zeile:=25;
                      dec (spalte);
                      if spalte < 0 then spalte := 0;
                   end;
                   if spalte > 0 then k:= 1
                   else k:= 0;
                   gotoxy(1+26*spalte+k,zeile);
                   TextBackground (blue);
                   write(Person[i]);
              end;
              if ord(key)= 77 then           (* 1 Person right *)
              begin
                   if i+25 > numPerson then i:=numPerson
                   else i:=i+25;
                   spalte:=j div 25;
                   zeile:=j mod 25;
                   if zeile = 0 then
                   begin
                      zeile:=25;
                      dec (spalte);
                      if spalte < 0 then spalte := 0;
                   end;
                   if spalte > 0 then k:= 1
                   else k:= 0;
                   gotoxy(1+26*spalte+k,zeile);
                   TextBackground (Black);
                   write(Person[j]);
                   spalte:=i div 25;
                   zeile:=i mod 25;
                   if zeile = 0 then
                   begin
                      zeile:=25;
                      dec (spalte);
                      if spalte < 0 then spalte := 0;
                   end;
                   if spalte > 0 then k:= 1
                   else k:= 0;
                   gotoxy(1+26*spalte+k,zeile);
                   TextBackground (blue);
                   write(Person[i]);
              end;
           if ord(key)= 75 then            (* 1 Person left *)
              begin
                   if i<26 then i:=1
                   else i:=i-25;
                   spalte:=j div 25;
                   zeile:=j mod 25;
                   if zeile = 0 then
                   begin
                      zeile:=25;
                      dec (spalte);
                      if spalte < 0 then spalte := 0;
                   end;
                   if spalte > 0 then k:= 1
                   else k:= 0;
                   gotoxy(1+26*spalte+k,zeile);
                   TextBackground (Black);
                   write(Person[j]);
                   spalte:=i div 25;
                   zeile:=i mod 25;
                   if zeile = 0 then
                   begin
                      zeile:=25;
                      dec (spalte);
                      if spalte < 0 then spalte := 0;
                   end;
                   if spalte > 0 then k:= 1
                   else k:= 0;
                   gotoxy(1+26*spalte+k,zeile);
                   TextBackground (blue);
                   write(Person[i]);
              end;
     until (ord(key)=13) OR (ord(key)=17);
     if ord(key) = 17 then Personmenu:=0
     else Personmenu:=i;
end;




procedure drawFrame;
var i,j : INTEGER;

begin
     Window (1, 1, 80, 25);
     TextBackground(Black);
     TextColor(Lightgray);
     Clrscr;
     write('³                  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³Nd³+/- soll³');
     write('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÄÄÄÄÄÄ´');
     write('³                  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³        ³');
     write('³                  ÃÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÁÄÄÄÄÄÄÄÄ´');
     write('³                  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³           ³');
     write('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÂÄÄÄÄÄÄÄÄ´');
     write('³                  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³        ³');
     write('³                  ÃÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÁÄÄÄÄÄÄÄÄ´');
     write('³                  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³           ³');
     write('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÂÄÄÄÄÄÄÄÄ´');
     write('³                  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³        ³');
     write('³                  ÃÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÁÄÄÄÄÄÄÄÄ´');
     write('³                  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³           ³');
     write('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÂÄÄÄÄÄÄÄÄ´');
     write('³                  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³        ³');
     write('³                  ÃÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÁÄÄÄÄÄÄÄÄ´');
     write('³                  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³           ³');
     write('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÄÄÄÄÄÄÄÄÄ´');
     write('³      Frhdienste ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³           ³');
     write('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄ´           ³');
     write('³      Sp„tdienste ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³           ³');
     write('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄ´           ³');
     write('³     Nachtdienste ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³           ³');
     write('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÄÄÄÄÄÄÄÄÄÙ');
     gotoxy(1,1);
     insLine;
     write('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÄÄÄÄÄÄ¿');
     gotoxy (2,2);
     write(Date);
end;




function calcSunHoliday:BOOLEAN;
var f                           : File of Integer;
    Ye,month,i,j,k,dummy        : INTEGER;
    Sundays                     : ARRAY [1..5,1..12] OF Byte;

begin
     convertDate(Y,M,Schedname);
     for i:=1 to 31 do
         SonnFeiertag[i]:=FALSE;
     for i:=1 to 12 do
         for j:=1 to 5 do
             Sundays[j,i]:=0;
     if NOT FileExists('HOLIDAY.'+Year) then
        begin
        message ('Noch keine Feiertage in diesem Jahr erstellt!',
                 'Bitte mit Menpunkt "Feiertage des Jahres eingeben" erstellen.');
        calcSunHoliday:=FALSE;
        exit;
        end;
     assign(f,'HOLIDAY.'+Year);
     reset(f);
     i:=1;
     calcSunHoliday:=TRUE;
     repeat
           read(f,month);
           if month = M then
              begin
              read(f,j);
              if j<=31 then
                 SonnFeiertag[j]:=TRUE;
              inc(i);
              end
           else
              read(f,dummy);
     until (i > Holimax) OR (eof(f));
     close(f);
     if i > Holimax then
        begin
        message ('Zu viele Feiertage in diesem Jahr!','Bitte den Autor zu kontaktieren.');
        exit;
        end;
    Sundays[1,1]:=3;                    (* 3.J„nner 93 = Sonntag *)
    j:=1;
    Ye:=1993;
    Month:=1;
    while (Ye < Y+1) do
      begin
          dummy:=Sundays[j,Month] + 7;
          if dummy > Monthlength (Ye,Month) then
          begin
             j:=1;
             dummy:= dummy mod MonthLength (Ye,Month);
             if Month = 12 then
                begin
                inc (Ye);
                Month:=1;
                if Ye < Y+1 then
                   for i:=1 to 12 do
                     for k:=1 to 5 do
                        Sundays[k,i]:=0;
                end
             else
                inc(Month);
             if (Ye < Y+1) then Sundays[1,Month]:= dummy;
          end
          else
          begin
              Sundays[j+1,Month]:= dummy;
              inc(j);
          end;
      end;

    for j:= 1 to 5 do
    begin
          if Sundays[j,M] > 0 then
             SonnFeiertag[Sundays[j,M]]:=TRUE;
    end;
end;




procedure NewSuggestFile;
type Suggestrecord = RECORD
              ID        : LONGINT;
              day       : INTEGER;
              Text      : STRING[80];
     end;


var f: file of Suggestrecord;
    fname:STRING[12];

begin
        fname:=Schedname;
        fname[1]:='$';
        Assign(f,fname);
        Rewrite(f);
        Close(f);
end;




procedure MakeSuggestion(choice,Day: BYTE);
type Suggestrecord = RECORD
              ID        : WORD;
              day       : BYTE;
              Text      : STRING[80];
     end;

var f                   : file of Suggestrecord;
    aSuggestrec         : Suggestrecord;
    fname               : STRING[12];
    Suggestion          : STRING[80];
    found               : BOOLEAN;

begin
     Window (1, 19, 80, 25);
     TextColor(Lightgray);
     TextBackground(Black);
     Clrscr;
     write('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÄÄÄÄÄÄÄÄÄÙ');
     Window (1, 20, 80, 25);
     gotoxy(1,1);
     write('Hier k”nnen Sie eine Erkl„rung zu Ihrem Vorschlag geben (max. 80 Zeichen)');
     gotoxy(1,3);
     write('(Sie k”nnen diese M”glichkeit bergehen, indem Sie Return drcken)');
     gotoxy(1,5);
     readln(Suggestion);
     fname:=Schedname;
     fname[1]:='$';
     if NOT FileExists(fname) then NewSuggestfile;
     Assign(f,fname);
     Reset(f);
     found:=FALSE;
     while (NOT found) AND (NOT eof(f)) do
           begin
           read(f,aSuggestrec);
           if ((aSuggestrec.ID=PersonID[choice]) AND (aSuggestrec.day=Day)) then found:=TRUE
           end;

     if (NOT found) then
     begin
         aSuggestrec.ID:=PersonID[choice];
         aSuggestrec.day:=Day;
         aSuggestrec.text:=Suggestion;
         write(f,aSuggestrec);
     end
     else
     begin
         seek(f,FilePos(f)-1);
         aSuggestrec.ID:=PersonID[choice];
         aSuggestrec.day:=Day;
         aSuggestrec.text:=Suggestion;
         write(f,aSuggestrec);
     end;
     close(f);
end;




procedure GetSuggestion(choice,Day: INTEGER);
type Suggestrecord = RECORD
              ID        : WORD;
              Day       : BYTE;
              Text      : STRING[80];
     end;

var f                   : file of Suggestrecord;
    aSuggestrec         : Suggestrecord;
    fname        : STRING[12];
    Suggestion   : STRING[80];
    found        : BOOLEAN;
    key          : CHAR;

begin
     fname:=Schedname;
     fname[1]:='$';
     if NOT FileExists(fname) then NewSuggestfile;
     Assign(f,fname);
     Reset(f);
     found:=FALSE;
     while (NOT found) AND (NOT eof(f)) do
           begin
           read(f,aSuggestrec);
           if ((aSuggestrec.ID=PersonID[choice]) AND (aSuggestrec.day=Day)) then found:=TRUE
           end;

     if (NOT found) then
         close(f)
     else
     begin
         Suggestion:=aSuggestrec.text;
         close(f);
         Window (1, 19, 80, 25);
         TextColor(Lightgray);
         TextBackground(Black);
         Clrscr;
         write('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÄÄÄÄÄÄÄÄÄÙ');
         Window (1, 20, 80, 25);
         write('Hier die Erkl„rung von ',Person[Ord (Who[choice,Day]) - 32],' :');
         gotoxy(1,3);
         write(Suggestion);
         gotoxy(19,5);
         TextBackground(Blue);
         write('---- Bitte irgendeine Taste bet„tigen ----');
         TextBackground(Black);
         key:=Readkey;
         if key=chr(0) then key:=Readkey;
     end;
end;




function makeNewPassword(index:INTEGER;app:BOOLEAN):BOOLEAN;
var i,j:INTEGER;
    c:char;
    f,f2:TEXT;
    ID:WORD;
    dummyPasswd:STRING;

begin
     Window (1, 1, 80, 25);
     TextBackground(Black);
     TextColor(Lightgray);
     Clrscr;
     repeat
           gotoxy(1,13);
           write('Bitte das neue Passwort zu diesem Namen eingeben:');
           TextColor(Black);
           readln(password1);
           TextColor(LightGray);
           if password1 = '' then
              begin
              makeNewPassword:=FALSE;
              exit;
              end;
           writeln;
           write('Bitte das Passwort best„tigen (nocheinmal eingeben):');
           TextColor(Black);
           readln(password2);
           TextColor(LightGray);
           if password1<>password2 then
              begin
              ClrScr;
              gotoxy(1,11);
              write('Falsche Best„tigung, Passwort bitte nocheinmal eingeben !');
              end;
     until password1=password2;

     for j:=1 to ord(password2[0]) do
     begin
          c:=chr(ord(password2[j]) XOR j);
          if c < chr(40) then
                         c:=chr(ord(c)+40);
          password2[j]:=c;
     end;
     Password[index]:=password2;
     if NOT FileExists ('PASSWORD.FIL') then
     begin
          assign(f,'PASSWORD.FIL');
          rewrite(f);
          writeln(f,NextPersonId);
          close(f);
     end;
     if app then
     begin
          assign(f,'PASSWORD.FIL');
          Append(f);
          writeln(f,PersonID[index]);
          writeln(f,Password[index]);
          close(f);
     end;
     assign(f,'PASSWORD.FIL');
     assign(f2,'DUMMY.FIL');
     reset(f);
     rewrite(f2);
     readln(f,ID);
     writeln(f2,nextPersonID);
     j:=0;
     repeat
          if j>0 then
          begin
              readln(f,dummyPasswd);
              writeln(f2,dummyPasswd);
          end;
          inc(j);
          readln(f,ID);
          writeln(f2,ID);
     until (ID=PersonID[index]) OR (eof(f));
     if eof(f) then
     begin
          message ('Es ist ein fataler Fehler aufgetreten,',
                  'bitte kontaktieren Sie den Autor !');
          close(f);close(f2);exit;
     end
     else
     begin
          readln(f,dummyPasswd);
          writeln(f2,Password[index]);
          while NOT (eof(f)) do
          begin
              readln(f,ID);
              readln(f,dummyPasswd);
              writeln(f2,ID);
              writeln(f2,dummyPasswd);
          end;
     end;
     close(f);
     close(f2);
     Assign(f,'PASSWORD.FIL');
     erase(f);
     Assign(f2,'DUMMY.FIL');
     Rename(f2,'PASSWORD.FIL');
     makeNewPassword:=TRUE;
end;




function getPassword(index:INTEGER):BOOLEAN;
var i,j:INTEGER;
      c:CHAR;

begin
     i:=0;
     Window (1, 1, 80, 25);
     TextBackground(Black);
     TextColor(Lightgray);
     Clrscr;
     repeat
           gotoxy(1,13);
           write('Bitte das Passwort zu Ihrem Namen eingeben:');
           TextColor(Black);
           readln(password2);
           TextColor(LightGray);
           if password2 = '' then
              begin
              getPassword:=FALSE;
              exit;
              end;
           for j:=1 to ord(password2[0]) do
           begin
                c:=chr(ord(password2[j]) XOR j);
                if c < chr(40) then
                         c:=chr(ord(c)+40);
                password2[j]:=c;
           end;
           inc(i);
           if password2 <> Password[index] then
           begin
                Clrscr;
                delay(1000);
                gotoxy(1,11);
                write('Passwort falsch, bitte nocheinmal eingeben');
                gotoxy(61,13);
                write('       ');
           end;
     until (password2 = Password[index]) OR (i = 3);
     if (i=3) AND NOT (password2 = Password[index]) then
     begin
         message ('Entweder versuchen Sie das Passwort eines anderen herauszufinden... ',
                  '... oder Sie haben Ihr eigenes vergessen !');
         message ('Sollte letzteres der Fall sein, so l”schen Sie bitte Ihren Eintrag aus der',
                  'Personliste und tragen sich neu ein. (Verlust des eigenen Dienstplans)');
         getPassword:=FALSE;
     end
     else getPassword:=TRUE;
end;




(* Returns the Filename and the Date of the last existing Schedule      *)
(* If there are no Schedules at all, proc sets Date = ''                *)
(* else Date = converted Date                                           *)
(* Filename is ALWAYS set on last exist. Schedule                       *)

procedure getLastSchedule(Var Filename:STRING);
var D,DOW: Word;
    i: INTEGER;
    break,NoFile:BOOLEAN;
    f:TEXT;
    name:STRING;

begin
     GetDate(Y, M, D, DOW);
     break := FALSE;
     NoFile:= TRUE;
     repeat
           name:=Filename;      (* store old FileName ! *)
           convertDate (Y,M,Filename);
           if NOT FileExists (Filename) then break:= TRUE
           else
           begin
                NoFile:=False;
                if M<12 then inc(M)  (* count Dates upwards *)
                else
                begin
                    M:=1;
                    inc(Y)
                end
           end
     until break;
     (* reset the false (not existing) Date back to normal *)
     if M>1 then dec(M)  (* count Dates downwards *)
     else
     begin
        M:=12;
        dec(Y)
     end;
     if NoFile then
        Date:=''
     else
        setDateString(Y,M,Date);
     Filename:=name          (* store back the Result *)
end;




(* Simply reads in a Schedule, specified by Schedname (global) *)
(* Attention: there are no Checks (take care yourself)         *)

procedure readSchedule;
var i,j:INTEGER;
    ID:WORD;
    f:Text;

begin
          Assign(f,Schedname);
          Reset(f);
          Readln(f,SollSumVorm);
          Readln(f,SollSumNachm);
          Readln(f,SollSumNacht);
          Readln(f,responsible);
          i:=1;
          repeat
                readln(f,Person[i]);
                readln(f,PersonID[i]);
                readln(f,Overtime[i]);
                readln(f,Plan[i]);
                readln(f,Suggest[i]);
                readln(f,Who[i]);
                readln(f,Hours[i]);
                readln(f,changeable[i]);
                inc(i);
          until (eof(f)) or (i>persmax) ;
          close(f);
          numPerson:=i-1;
          currentPerson:=0;
          for i:= 1 to numPerson do
          begin
              if PersonID[i]=curpersID then currentPerson:=i;
              Oversum[i]:=0;
              for j:= 1 to MonthLength(Y,M) do
                  OverSum[i]:=Oversum[i]+(ord(OverTime[i,j])-32)*0.5;
          end;

          Assign(f,'PASSWORD.FIL');
          Reset(f);
          readln(f,nextPersonID);
          repeat
               readln(f,ID);
               j:=0;
               repeat inc(j)
               until (ID=PersonID[j]) OR (j>numPerson);
               if j>numPerson then readln(f)
               else readln(f,Password[j]);
          until (eof(f));
          close(f);
end;




(* Simply saves Schedule, specified by Schedname (global) *)

procedure saveSchedule;
var i,j:INTEGER;
    ID:WORD;
    f:Text;

begin
     Assign(f,Schedname);
     Rewrite(f);
     Writeln(f,SollSumVorm);
     Writeln(f,SollSumNachm);
     Writeln(f,SollSumNacht);
     Writeln(f,responsible);
     for i:=1 to numPerson do
     begin
          writeln(f,Person[i]);
          writeln(f,PersonID[i]);
          writeln(f,Overtime[i]);
          writeln(f,Plan[i]);
          writeln(f,Suggest[i]);
          writeln(f,Who[i]);
          writeln(f,Hours[i]);
          writeln(f,changeable[i]);
     end;
     close(f);
end;




(* Appends a new Person to current Schedule, if there is any...           *)
(* if there is none at all, proc creates a Schedule with the Current Date *)
(* with one Person.                                                       *)

procedure newPerson;
var       i,j,hour: Integer;
          D,DOW   : Word;
          name    : STRING[26];
          newVal  : REAL;
          val     : Integer;

begin                    
     if Date = '' then     (* Create one single Schedule-item + Heading *)
     begin
             GetDate(Y, M, D, DOW);
             ConvertDate(Y,M,Schedname);
             setDateString(Y,M,Date);
             responsible:=1;     (* first Person, who creates, is in Charge *)
             (* Defaults, can be changed *)
             SollSumVorm:=SollsumVormDef;
             SollSumNachm:=SollsumNachmDef;
             SollSumNacht:=SollsumNachtDef;
     end;

     if numperson = persmax then
     begin
          message ('Das Programm wurde fr max. 75 Personen ausgelegt, was meistens ausreicht.',
                   '... sollten Sie dennoch hinzufgen wollen, setzen Sie sich bitte mit dem        Autor in Verbindung !');
          exit;
     end;

     if numPerson = 0 then choice:=0
     else
     begin
         message('Anschlieáend bitte Person ausw„hlen, nach der die neue Person',
                 'eingefgt werden soll.');
         choice:=Personmenu;
         if choice = 0 then
            exit;
     end;
     inc(numPerson);

     Window (1, 1, 80, 25);
     TextBackground(Black);
     TextColor(Lightgray);
     Clrscr;
     gotoxy(1,10);
     write('Bitte den Namen eingeben:');
     readln(name);
     if name = '' then
        begin
        dec(numPerson);
        exit;
        end;

     if numPerson = 1 then NewSuggestfile;

     if (choice < numPerson-1) AND (numPerson <> 1) then
     begin
          for i:= numPerson downto choice+2 do
          begin
               Person[i]:=Person[i-1];
               PersonID[i]:=PersonID[i-1];
               Password[i]:=Password[i-1];
               Overtime[i]:=Overtime[i-1];
               Oversum[i]:=Oversum[i-1];
               Plan[i]:=Plan[i-1];
               Suggest[i]:=Suggest[i-1];
               Who[i]:=Who[i-1];
               Hours[i]:=Hours[i-1];
               changeable[i]:=changeable[i-1];
          end;
          for i:= 1 to numPerson do
              for j:= 1 to Monthlength (Y,M) do
                  if (Ord(Who[i,j])-32 >= choice+1) then inc(Who[i,j]);
     end;
     inc(choice);
     if (choice <= responsible) AND (numPerson <> 1) then inc (responsible);
     if (choice <= currentPerson) AND (numPerson <> 1) then inc (currentPerson);

     Person[choice]:=name;
     gotoxy(1,13);
     write('Welche Monatsstundenanzahl :');
     Hours[choice]:=defaultHours;
     val:=getValue (30,13,Hours[choice],0,999.90,0.1);

     PersonID[choice]:=nextPersonID;
     inc(nextPersonID);

     repeat until makeNewPassword (choice,TRUE);   (* make a Password *)

     Oversum[choice]:=0.0;
     Overtime[choice]:=Wholeer[Monthlength (Y,M)-27];
     Plan[choice]:=leer[Monthlength (Y,M)-27];
     Suggest[choice]:=Wholeer[Monthlength (Y,M)-27];
     Who[choice]:=Wholeer[Monthlength (Y,M)-27];
     changeable[choice]:=0;
     saveSchedule;
end;




procedure calcOffset(var vorm,nachm,nacht:INTEGER);
var i:INTEGER;

begin
  vorm:=0;
  nachm:=0;
  nacht:=0;
  for i:= 1 to Monthlength(Y,M) do
  begin
      if SumVormittag[i] < SollSumVorm then
         vorm:=vorm+(SollSumVorm-SumVormittag[i]);
      if SumNachmittag[i] < SollSumNachm then
         nachm:=nachm+(SollSumNachm-SumNachmittag[i]);
      if SumNachtdienst[i] < SollSumNacht then
         nacht:=nacht+(SollSumNacht-SumNachtdienst[i]);
  end;
end;




procedure NewSchedule;
Var i,nY,nM   : INTEGER;
    f         : Text;
    offvorm,
    offnachm,
    offnacht  : INTEGER;
    nextDate  : STRING;
    key       : CHAR;

begin
  if Date <> '' then saveSchedule;
  getLastSchedule(Schedname);
  if Date = '' then
  begin
       message ('Es wurde noch nie ein Dienstplan erstellt (auch kein Personal vorhanden)...',
                '... mit Menpunkt "Personal hinzufgen" k”nnen Sie Personen eintragen ! ');
       exit;
  end;
  readSchedule;
  if currentPerson=0 then
  begin
       message ('Momentan ist niemand eingestiegen, daher kann niemand fr den n„chsten',
                'Dienstplan verantwortlich sein. (w„re die momentan eingestiegene Person) ');
       exit;
  end;
  calcOffset(offvorm,offnachm,offnacht);
  TextBackground(Black);
  TextColor(Lightgray);
  Clrscr;
  gotoxy(10,5);
  write('Nicht erfllte ');
  TextBackground(Blue);
  TextColor(White);
  write('Vormittagsdienste:');
  TextBackground(Black);
  TextColor(LightRed);
  write('     ');
  if offvorm>0 then writeln(offvorm)
  else
  begin
       TextColor(Lightgray);
       writeln('keine (Alles OK.)');
  end;

  TextColor(Lightgray);
  gotoxy(10,7);
  write('Nicht erfllte ');
  TextBackground(Blue);
  TextColor(White);
  write('Nachmittagsdienste:');
  TextBackground(Black);
  TextColor(LightRed);
  write('    ');
  if offnachm>0 then writeln(offnachm)
  else
  begin
       TextColor(Lightgray);
       writeln('keine (Alles OK.)');
  end;

  TextColor(Lightgray);
  gotoxy(10,9);
  write('Nicht erfllte ');
  TextBackground(Blue);
  TextColor(White);
  write('Nachtdienste:');
  TextBackground(Black);
  TextColor(LightRed);
  write('          ');
  if offnacht>0 then writeln(offnacht)
  else
  begin
       TextColor(Lightgray);
       writeln('keine (Alles OK.)');
  end;

  nY:=Y;
  if M<12 then nM:=M+1  (* One Schedule next *)
  else
  begin
      nM:=1;
      inc(nY);
  end;
  setDateString(nY,nM,nextDate);

  gotoxy(5,15);
  TextColor(Lightgray);
  write('N„chster Dienstplan w„re: ');
  TextBackground(Blue);
  TextColor(White);
  writeln(nextDate);

  gotoxy(5,17);
  TextBackground(Black);
  TextColor(Lightgray);
  write('Verantwortlich fr diesen Dienstplan w„re: ');
  TextBackground(Blue);
  TextColor(White);
  writeln(Person[currentPerson]);

  gotoxy(5,20);
  TextBackground(Black);
  TextColor(Lightgray);
  write('Wollen sie wirklich diesen Dienstplan (neu) erstellen (J/N) ?');
  i:=wherex;
  repeat
       key:=readkey;
       if (key = chr(106)) OR (key = chr(110)) then
       begin
           gotoxy (i+1,20);
           write(' ',key);
       end;
       if key = chr(106) then write('')
       else if key <> chr(110) then
            begin
                gotoxy(1,22);
                write('Nur Tasten J oder N drcken !');
            end
            else
            begin
                gotoxy(1,22);
                write('                             ');
            end;
  until (key = chr(106)) OR (key = chr(110));
  if key <> chr(106) then exit;

  responsible:=currentPerson;
  Y:=nY;M:=nM;
  convertDate(Y,M,Schedname);
  Date:=nextDate;

  for i:=1 to numPerson do
  begin
     Oversum[i]:=0.0;
     Overtime[i]:=Wholeer[Monthlength (Y,M)-27];
     Plan[i]:=leer[Monthlength (Y,M)-27];
     Suggest[i]:=Wholeer[Monthlength (Y,M)-27];
     Who[i]:=Wholeer[Monthlength (Y,M)-27];
     changeable[i]:=1;
  end;
  NewSuggestFile;
  saveSchedule;
end;




procedure DelPerson;
var       i,j : Integer;
          key : CHAR;

begin
     if NOT testOK then exit;
     if numPerson = 1 then
     begin
          message ('Sie k”nnen die letzte Person nicht l”schen, da sonst niemand'
                   ,'mehr fr den Dienstplan verantwortlich ist !');
          exit;
     end;
     message('Anschlieáend bitte Person ausw„hlen, welche gel”scht werden soll.','');
     choice:=Personmenu;
     Window (1, 1, 80, 25);
     TextBackground(Black);
     TextColor(Lightgray);
     Clrscr;
     gotoxy(1,12);
     write('Wollen Sie ');
     TextBackground(Blue);
     write(person[choice]);
     TextBackground(Black);
     write(' wirklich l”schen? (J/N):');
     i:=wherex;
     repeat
           key:=readkey;
           if (key = chr(106)) OR (key = chr(110)) then
           begin
              gotoxy (i+1,12);
              write(' ',key);
           end;
           if key = chr(106) then         (* J: Delete the Person *)
           begin
                gotoxy(1,14);
                for i:= 1 to numPerson do
                    for j:= 1 to Monthlength (Y,M) do
                    begin
                        if (Ord(Who[i,j])-32 = choice) then Who[i,j]:=' ';
                        if (Ord(Who[i,j])-32 >= choice+1) then dec(Who[i,j]);
                    end;
                for i:= choice to numperson-1 do
                begin
                     Person[i]:=Person[i+1];
                     PersonID[i]:=PersonID[i+1];
                     Password[i]:=Password[i+1];
                     Oversum[i]:=Oversum[i+1];
                     Overtime[i]:=Overtime[i+1];
                     Plan[i]:=Plan[i+1];
                     Suggest[i]:=Suggest[i+1];
                     Who[i]:=Who[i+1];
                     Hours[i]:=Hours[i+1];
                     changeable[i]:=changeable[i+1];
                end;
                dec(numPerson);
           end
           else if key <> chr(110) then
                begin
                     gotoxy(1,14);
                     write('Nur Tasten J oder N drcken !');
                end
                else
                begin
                     gotoxy(1,14);
                     write('                             ');
                end;
     until (key = chr(106)) OR (key = chr(110));
     if choice < currentPerson then
         dec(currentPerson)
     else if choice = currentPerson then currentPerson:=0;
     if choice < responsible then
         dec(responsible)
     else
         if (responsible = choice) AND (key = chr(106)) then
         begin
          message('Da gel”schte Person fr den aktuellen Dienstplan verantwortlich war,',
                  'bitte Person ausw„hlen, welche in weiterer Folge verantwortlich ist.');
          repeat
          responsible:=Personmenu;
          until responsible <> 0 ;
         end;
     saveSchedule;
end;




procedure ChangePasswd;
var       i: Integer;

begin
     if NOT testOK then exit;
     if currentPerson=0 then exit;
     choice := currentPerson;
     message('Anschlieáend bitte Passwort eingeben,','wenn Passwort wirklich ge„ndert werden soll.');
     if NOT (getPassword (choice)) then exit;

     (* change the Password: *)
     if NOT (makeNewPassword (choice,FALSE)) then exit;
end;




procedure FetchSchedule;
const item : ARRAY [0..11] OF STRING[10] =
           ('Januar','Februar','M„rz','April','Mai','Juni','Juli',
            'August','September','Oktober','November','Dezember');
      numitems = 12;
var i,j             : INTEGER;
    Year            : STRING[4];
    dummy           : REAL;
    f               : TEXT;
    key             : CHAR;

begin
     if Date <> '' then SaveSchedule;
     getLastSchedule(Schedname);
     Window (1, 1, 80, 25);
     TextBackground(Black);
     TextColor(Lightgray);
     Clrscr;
     gotoxy(29,5);
     writeln('W„hlen Sie bitte einen Monat');
     for i:=0 to numitems-1 do
         begin
         gotoxy (29,9+i);
         write(item[i]);
         end;
     TextBackground(Blue);

     gotoxy (29,8+M);
     write(item[M-1]);
     i:=M-1;j:=M-1;
     repeat
           key:=readkey;
           j:=i;
           if ord(key)= 80 then
              begin
                   if i = numitems-1 then i:=0
                   else inc(i);
                   gotoxy(29,9+j);
                   TextBackground (Black);
                   write(item[j]);
                   gotoxy(29,9+i);
                   TextBackground (blue);
                   write(item[i]);
              end;
           if ord(key)= 72 then
              begin
                   if i=0 then i:=numitems-1
                   else dec(i);
                   gotoxy(29,9+j);
                   TextBackground (Black);
                   write(item[j]);
                   gotoxy(29,9+i);
                   TextBackground (blue);
                   write(item[i]);
              end
     until ord(key)=13;
     M:=i+1;
     dummy:=Y;
     TextBackground (Black);
     gotoxy(1,24);
     write('            Welches Jahr :  ');
     Y:=getValue (29,24,dummy,1990,9999,1);
     convertDate(Y,M,Schedname);
     if fileExists(Schedname) then
        setDateString(Y,M,Date)
     else
     begin
        message ('Dienstplan nicht vorhanden !','');
        getLastSchedule(Schedname);
     end;
     if Date<>'' then readSchedule;
end;




procedure editSunHoliday;

var f           : File of Integer;
    item        : ARRAY [0..Holimax-1,1..2] OF INTEGER;
    month,
    day,
    numitems,
    i,j         : INTEGER;
    dummy       : REAL;
    mstring,
    dstring     : STRING;
    ex          : BOOLEAN;
    key         : CHAR;

begin
     convertDate(Y,M,Schedname);          (* To get the String : Year *)
     if not FileExists('HOLIDAY.'+Year) then
     begin
        assign(f,'HOLIDAY.'+Year);
        rewrite(f);
        For i:=0 to Holimax-1 do
        begin
           write(f,fixItem[i,1]);
           write(f,fixItem[i,2]);
        end;
        close(f);
     end;
     assign(f,'HOLIDAY.'+Year);
     reset(f);
     i:=0;
     repeat
           read(f,item[i,1]);
           read(f,item[i,2]);
           inc(i);
     until (i+1 > Holimax) OR (eof(f));
     close(f);
     if i <> Holimax then
        begin
        message ('Dateifehler bei Feiertagsdatei !','Bitte den Autor zu kontaktieren.');
        exit;
        end;

     Window (1, 1, 80, 25);
     TextBackground(Black);
     TextColor(Lightgray);
     Clrscr;
     gotoxy (12,3);
     write('W„hlen Sie bitte einen Termin zum Ver„ndern aus:');
     for i:=1 to Holimax-1 do
         begin
         gotoxy (29,6+i);
         write(item[i,2],'.     ');
         gotoxy (36,6+i);
         write(item[i,1],'.');
         end;
     TextBackground(Blue);
     gotoxy (29,6);
     write(item[0,2],'.     ');
     gotoxy (36,6);
     write(item[0,1],'.');
     i:=0;j:=0;
     repeat
           key:=readkey;
           j:=i;
           if ord(key)= 80 then
              begin
                   if i = Holimax-1 then i:=0
                   else inc(i);
                   TextBackground (Black);
                   gotoxy(29,6+j);
                   write(item[j,2],'.     ');
                   gotoxy (36,6+j);
                   write(item[j,1],'.');
                   TextBackground (blue);
                   gotoxy(29,6+i);
                   write(item[i,2],'.     ');
                   gotoxy (36,6+i);
                   write(item[i,1],'.');
              end;
           if ord(key)= 72 then
              begin
                   if i=0 then i:=Holimax-1
                   else dec(i);
                   TextBackground (Black);
                   gotoxy(29,6+j);
                   write(item[j,2],'.     ');
                   gotoxy (36,6+j);
                   write(item[j,1],'.');
                   TextBackground (blue);
                   gotoxy(29,6+i);
                   write(item[i,2],'.     ');
                   gotoxy (36,6+i);
                   write(item[i,1],'.');
              end
     until ord(key)=13;
     TextBackground (Black);
     gotoxy (10,3);
     write('Sie k”nnen Tag und Monat „ndern oder mit Enter belassen:');
     gotoxy(29,6+i);
     write(item[i,2],'.     ');
     gotoxy (36,6+i);
     write(item[i,1],'.');
     dummy:=item[i,2];
     day:=getValue (29,6+i,dummy,1,31,1);
     dummy:=item[i,1];
     month:=getValue (36,6+i,dummy,1,12,1);

     reset(f);
     seek(f,i*2);
     write(f,month);
     write(f,day);
     close(f);
end;




(* prints a Schedule to Printerport lpt1: *)

procedure PrintOutSchedule;
const fill1 = '                          ';

var h,i,j,k,l,
    pageNum,
    lineCount        : INTEGER;
    OkNotOk          : ARRAY[1..31] OF INTEGER;
    f,Lst            : TEXT;
    InitString       : STRING;
    firsttime,GoOn   : BOOLEAN;


begin
     if NOT testOK then exit;
     recalc;
     if NOT calcSunHoliday then exit;

     (* 11 Persons on 1 Sheet (with 2 Sides) *)
     GoOn:=TRUE;
     pageNum:=0;
     while GoOn do
     begin
          inc(pageNum);
          GoOn:=FALSE;
          if numPerson>11*pageNum then GoOn:=TRUE;
     end;

     (* Init Printer *)

     {$I-}
     Assign(Lst, 'LPT1');
     Rewrite(Lst);
     Write(Lst,' ');
     {$I+}

     if IOresult <> 0 then
        begin
        message ('Drucker reagiert nicht ! (M”glicherweise ist er ausgeschalten)',
                 'Bitte Drucker berprfen, sonst kann nicht ausgedruckt werden !');
        Close(Lst);
        exit;
        end;

     if NOT FileExists ('PRINTER.FIL') then
        begin
        message ('Keine Initialisierungsdatei vorhanden. Bitte eine im folgenden Format erstellen:',
                 'Name: PRINTER.FIL, Inhalt: 1.Zeile šberschrift, 2.-x. Zeile Escape Codes');
        Close(Lst);
        exit;
        end;

     Assign(f, 'PRINTER.FIL');
     Reset(f);
     Readln(f);
     while (not eof (f)) do
     begin
          Readln(f,InitString);
          Writeln(Lst,Chr(27)+InitString);
     end;
     Close(f);

     for i:= 1 to pageNum do
     begin
         if i*11 > numPerson then lineCount:=numPerson-(i-1)*11
         else lineCount:=11;
         writeln(Lst,chr(12));               (* next Page *)


(* print left Side of Sheet *)


         writeln(Lst,'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄ¿');
         write(Lst,'³');
         write(Lst,Date);
         write(Lst,copy(fill1,1,26-Length(Date)));
         write(Lst,'³');
         for j:=1 to 15 do                                 (* Heading *)
         begin
              if j<10 then write(Lst,'0');
              write (Lst,j);
              write (Lst,'³');
         end;
         writeln(Lst);


         firsttime:=TRUE;
         for k:=1 to 31 do OkNotOk[k]:=0;
         for k:=1 to lineCount do        (* write Persons & Schedule *)
         begin
              if firsttime then
              begin
                   write(Lst,'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
                   for j:=1 to 15 do        (* discern Sundays & Holidays ! *)
                   begin
                        if SonnFeiertag[j] then write (Lst,'Åßß')
                        else write (Lst,'ÅÄÄ');
                   end;
                   writeln(Lst,'´');firsttime:=FALSE;
              end
              else
              begin
                   write(Lst,'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
                   for j:=1 to 15 do
                       case OkNotOk[j] of
                            0: write(Lst,'ÅÄÄ');
                            1: write(Lst,'ÅÍÍ');
                            2: write(Lst,'ÅÏÏ');
                       end;
                   writeln(Lst,'´');
              end;

              write(Lst,'³');
              write(Lst,Person[(i-1)*11+k]);
              write(Lst,copy(fill1,1,26-Length(Person[(i-1)*11+k])));
              write(Lst,'³');

              for j:=1 to 15 do              (* Contents of Schedule *)
              begin
                   case Plan[(i-1)*11+k,j] of
                   'M': write(Lst,fre1);
                   'J': write(Lst,fre2);
                   'T': write(Lst,day);
                   'N': write(Lst,nite);
                   'A': write(Lst,aft);
                   'U': write(Lst,hol);
                   'V': write(Lst,morn);
                   'S': write(Lst,sle);
                   end;
                   write (Lst,'³');
              end;
              writeln(Lst);
              writeln(Lst,'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄ´');
              write(Lst,'³                          ³');

              for j:=1 to 15 do              (* Suggestions *)
              begin
                   case Suggest[(i-1)*11+k,j] of
                   'M': begin write(Lst,fre1);OkNotOk[j]:=0; end;
                   'J': begin write(Lst,fre2);OkNotOk[j]:=0; end;
                   'T': begin write(Lst,day);OkNotOk[j]:=0; end;
                   'N': begin write(Lst,nite);OkNotOk[j]:=0; end;
                   'A': begin write(Lst,aft);OkNotOk[j]:=0; end;
                   'U': begin write(Lst,hol);OkNotOk[j]:=0; end;
                   'V': begin write(Lst,morn);OkNotOk[j]:=0; end;
                   'S': begin write(Lst,sle);OkNotOk[j]:=0; end;
                   'k': begin write(Lst,cour);OkNotOk[j]:=0; end;
                   ' ': begin write(Lst,'  ');OkNotOk[j]:=0; end;
                   'm': begin write(Lst,fre1);OkNotOk[j]:=1; end;
                   'j': begin write(Lst,fre2);OkNotOk[j]:=1; end;
                   't': begin write(Lst,day);OkNotOk[j]:=1; end;
                   'n': begin write(Lst,nite);OkNotOk[j]:=1; end;
                   'a': begin write(Lst,aft);OkNotOk[j]:=1; end;
                   'u': begin write(Lst,hol);OkNotOk[j]:=1; end;
                   'v': begin write(Lst,morn);OkNotOk[j]:=1; end;
                   's': begin write(Lst,sle);OkNotOk[j]:=1; end;
                   '-': begin write(Lst,fre1);OkNotOk[j]:=2; end;
                   '*': begin write(Lst,fre2);OkNotOk[j]:=2; end;
                   '4': begin write(Lst,day);OkNotOk[j]:=2; end;
                   '.': begin write(Lst,nite);OkNotOk[j]:=2; end;
                   '!': begin write(Lst,aft);OkNotOk[j]:=2; end;
                   '5': begin write(Lst,hol);OkNotOk[j]:=2; end;
                   '6': begin write(Lst,morn);OkNotOk[j]:=2; end;
                   '3': begin write(Lst,sle);OkNotOk[j]:=2; end;
                   end;
                   write (Lst,'³');
              end;
              writeln(Lst);
         end;
                                                (* write SumVormittag *)
         writeln(Lst,'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄ´');
         write(Lst,'³              Frhdienste ³');
         for j:=1 to 15 do
         begin
              write (Lst,SumVormittag[j]:2);
              write (Lst,'³');
         end;
                                                (* write SumNachmittag *)
         writeln(Lst);
         writeln(Lst,'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄ´');
         write(Lst,'³              Sp„tdienste ³');
         for j:=1 to 15 do
         begin
              write (Lst,SumNachmittag[j]:2);
              write (Lst,'³');
         end;
                                                (* write SumNachtdienst *)
         writeln(Lst);
         writeln(Lst,'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄÅÄÄ´');
         write(Lst,'³             Nachtdienste ³');
         for j:=1 to 15 do
         begin
              write (Lst,SumNachtdienst[j]:2);
              write (Lst,'³');
         end;
                                                (* closing *)
         writeln(Lst);
         writeln(Lst,'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÙ');
         writeln(Lst);
         writeln(Lst,'Seite: ',i,' (links)');
         writeln(Lst,chr(12));               (* next Page *)


(* print right Side of Sheet *)


         write(Lst,'Ú');                        (* Heading *)
         for j:=16 to MonthLength(Y,M) do
              write(Lst,'ÄÄÂ');
         writeln(Lst,'ÄÄÂÄÄÄÄÄÄÄÄ¿');
         write(Lst,'³');
         for j:=16 to MonthLength(Y,M) do
         begin
              write (Lst,j);
              write (Lst,'³');
         end;
         writeln(Lst,'Nd³+/- soll³');


         firsttime:=TRUE;
         for k:=1 to 31 do OkNotOk[k]:=0;
         for k:=1 to lineCount do        (* write Persons & Schedule *)
         begin
              if firsttime then
              begin
                   write(Lst,'Ã');
                   for j:=16 to MonthLength(Y,M) do
                   begin
                        if SonnFeiertag[j] then write (Lst,'ßßÅ')
                        else write (Lst,'ÄÄÅ');
                   end;
                   writeln(Lst,'ÄÄÅÄÄÄÄÄÄÄÄ´');firsttime:=FALSE;
              end
              else
              begin
                   write(Lst,'Ã');
                   for j:=16 to MonthLength(Y,M) do
                       case OkNotOk[j] of
                            0: write(Lst,'ÄÄÅ');
                            1: write(Lst,'ÍÍÅ');
                            2: write(Lst,'ÏÏÅ');
                       end;
                   writeln(Lst,'ÄÄÅÄÄÄÄÄÄÄÄ´');
              end;
              write(Lst,'³');
              for j:=16 to MonthLength(Y,M) do     (* Contents of Schedule *)
              begin
                   case Plan[(i-1)*11+k,j] of
                   'M': write(Lst,fre1);
                   'J': write(Lst,fre2);
                   'T': write(Lst,day);
                   'N': write(Lst,nite);
                   'A': write(Lst,aft);
                   'U': write(Lst,hol);
                   'V': write(Lst,morn);
                   'S': write(Lst,sle);
                   end;
                   write (Lst,'³');
              end;
              write(Lst,Nachtdienste[(i-1)*11+k]:2);
              write(Lst,'³');
              if Dienststunden[(i-1)*11+k] >= Hours[(i-1)*11+k] then
                 write(Lst,'+ ',Dienststunden[(i-1)*11+k]-Hours[(i-1)*11+k]:6:2)
              else
                 write(Lst,'- ',Hours[(i-1)*11+k]-Dienststunden[(i-1)*11+k]:6:2);
              writeln(Lst,'³');

              write(Lst,'Ã');
              for j:=16 to MonthLength(Y,M) do
                  write(Lst,'ÄÄÅ');
              writeln(Lst,'ÄÄÅÄÄÄÄÄÄÄÄ´');
              write(Lst,'³');
              for j:=16 to MonthLength(Y,M) do     (* Contents of Schedule *)
              begin
                   case Suggest[(i-1)*11+k,j] of
                   'M': begin write(Lst,fre1);OkNotOk[j]:=0; end;
                   'J': begin write(Lst,fre2);OkNotOk[j]:=0; end;
                   'T': begin write(Lst,day);OkNotOk[j]:=0; end;
                   'N': begin write(Lst,nite);OkNotOk[j]:=0; end;
                   'A': begin write(Lst,aft);OkNotOk[j]:=0; end;
                   'U': begin write(Lst,hol);OkNotOk[j]:=0; end;
                   'V': begin write(Lst,morn);OkNotOk[j]:=0; end;
                   'S': begin write(Lst,sle);OkNotOk[j]:=0; end;
                   'k': begin write(Lst,cour);OkNotOk[j]:=0; end;
                   ' ': begin write(Lst,'  ');OkNotOk[j]:=0; end;
                   'm': begin write(Lst,fre1);OkNotOk[j]:=1; end;
                   'j': begin write(Lst,fre2);OkNotOk[j]:=1; end;
                   't': begin write(Lst,day);OkNotOk[j]:=1; end;
                   'n': begin write(Lst,nite);OkNotOk[j]:=1; end;
                   'a': begin write(Lst,aft);OkNotOk[j]:=1; end;
                   'u': begin write(Lst,hol);OkNotOk[j]:=1; end;
                   'v': begin write(Lst,morn);OkNotOk[j]:=1; end;
                   's': begin write(Lst,sle);OkNotOk[j]:=1; end;
                   '-': begin write(Lst,fre1);OkNotOk[j]:=2; end;
                   '*': begin write(Lst,fre2);OkNotOk[j]:=2; end;
                   '4': begin write(Lst,day);OkNotOk[j]:=2; end;
                   '.': begin write(Lst,nite);OkNotOk[j]:=2; end;
                   '!': begin write(Lst,aft);OkNotOk[j]:=2; end;
                   '5': begin write(Lst,hol);OkNotOk[j]:=2; end;
                   '6': begin write(Lst,morn);OkNotOk[j]:=2; end;
                   '3': begin write(Lst,sle);OkNotOk[j]:=2; end;
                   end;
                   write (Lst,'³');
              end;
              writeln(Lst,'  ³        ³');
         end;

         write(Lst,'Ã');                (* write SumVormittag *)
         for j:=16 to MonthLength(Y,M) do
             write(Lst,'ÄÄÅ');
         writeln(Lst,'ÄÄÅÄÄÄÄÄÄÄÄ´');
         write (Lst,'³');
         for j:=16 to MonthLength(Y,M) do
         begin
              write (Lst,SumVormittag[j]:2);
              write (Lst,'³');
         end;
         writeln(Lst,'  ³        ³');

         write(Lst,'Ã');                (* write SumNachmittag *)
         for j:=16 to MonthLength(Y,M) do
             write(Lst,'ÄÄÅ');
         writeln(Lst,'ÄÄÅÄÄÄÄÄÄÄÄ´');
         write (Lst,'³');
         for j:=16 to MonthLength(Y,M) do
         begin
              write (Lst,SumNachmittag[j]:2);
              write (Lst,'³');
         end;
         writeln(Lst,'  ³        ³');

         write(Lst,'Ã');                (* write SumNachtdienst *)
         for j:=16 to MonthLength(Y,M) do
             write(Lst,'ÄÄÅ');
         writeln(Lst,'ÄÄÅÄÄÄÄÄÄÄÄ´');
         write (Lst,'³');
         for j:=16 to MonthLength(Y,M) do
         begin
              write (Lst,SumNachtdienst[j]:2);
              write (Lst,'³');
         end;
         writeln(Lst,'  ³        ³');

         write(Lst,'À');

         for j:=16 to MonthLength(Y,M) do              (* Closing *)
              write(Lst,'ÄÄÁ');
         writeln(Lst,'ÄÄÁÄÄÄÄÄÄÄÄÙ');
         writeln(Lst);
         writeln(Lst,'Seite: ',i,' (rechts)');
     end;
     writeln(Lst,chr(12));               (* get Page out *)

     (* Print the Information about Overtimes *)
     writeln(Lst,'Geplante šberstunden:');
     writeln(Lst,'ßßßßßßßßßßßßßßßßßßßßß');
     h:=0;
     for i:=1 to numPerson do        (* write Persons & Schedule *)
     if OverSum[i]>0.0 then
     begin
         if (h>50) then
         begin
            writeln(Lst,chr(12)); (* Page Break *)
            h:=0;
         end;
         write(Lst,Person[i]);
         writeln(Lst,':');
         inc(h);
         l:=0;
         for j:=1 to MonthLength(Y,M) do
           if (ord(Overtime[i,j]) > 32) then
           begin
                  write(Lst,j:2);
                  write(Lst,':');
                  write(Lst,(ord(Overtime[i,j])-32)*0.5:5:2);
                  write(Lst,'İ ');
                  inc(l);
                  if l>6 then
                  begin
                     writeln(Lst);
                     inc(h);
                     l:=0;
                  end;
           end;
         write(Lst,'Summe: ');
         writeln(Lst,Oversum[i]:6:2);
         writeln(Lst);
         inc(h);inc(h);
     end;
     writeln(Lst,chr(12));               (* get Page out *)
     Close(Lst);
end;




procedure ChangePensum;
const numitems = 3;
var item       : ARRAY [0..numitems-1] OF STRING;
    i,j,error  : INTEGER;
    dummy      : REAL;
    key        : CHAR;

begin
     item[0] := 'Anzahl der Frhdienste   :';
     item[1] := 'Anzahl der Sp„tdienste   :';
     item[2] := 'Anzahl der Nachtdienste  :';

     if Date = '' then
     begin
          message ('Es wurde noch nie ein Dienstplan erstellt ...',
                   '... mit Menpunkt "Neues Personal" k”nnen Sie Personen eintragen ! ');
          exit;
     end;
     Window (1, 1, 80, 25);
     TextBackground(Black);
     TextColor(Lightgray);
     ClrScr;
     gotoxy (14,5);
     write('W„hlen Sie bitte, welche Anzahl Sie „ndern m”chten:');
     for i:=1 to numitems-1 do
         begin
         gotoxy (20,10+i);
         write(item[i]);
         end;
     gotoxy(55,10);
     write(SollSumVorm);
     gotoxy(55,11);
     write(SollSumNachm);
     gotoxy(55,12);
     write(SollSumNacht);
     TextBackground(Blue);
     gotoxy (20,10);
     write(item[0]);
     i:=0;j:=0;
     repeat
           key:=readkey;
           j:=i;
           if ord(key)= 80 then
              begin
                   if i = numitems-1 then i:=0
                   else inc(i);
                   gotoxy(20,10+j);
                   TextBackground (Black);
                   write(item[j]);
                   gotoxy(20,10+i);
                   TextBackground (blue);
                   write(item[i]);
              end;
           if ord(key)= 72 then
              begin
                   if i=0 then i:=numitems-1
                   else dec(i);
                   gotoxy(20,10+j);
                   TextBackground (Black);
                   write(item[j]);
                   gotoxy(20,10+i);
                   TextBackground (blue);
                   write(item[i]);
              end
     until ord(key)=13;
     TextBackground(Black);
     TextColor(Lightgray);
     gotoxy (1,5);
     case i of
          0: begin
                   write('Sie k”nnen Anzahl der Frhdienste „ndern, oder mit Enter belassen:');
                   dummy:=SollSumVorm;
                   SollSumVorm:=getValue (55,10,dummy,0,99,1);
             end;
          1: begin
                   write('Sie k”nnen Anzahl der Sp„tdienste „ndern, oder mit Enter belassen:');
                   dummy:=SollSumNachm;
                   SollSumNachm:=getValue (55,11,dummy,0,99,1);
             end;
          2: begin
                   write('Sie k”nnen Anzahl der Nachtdienste „ndern, oder mit Enter belassen:');
                   dummy:=SollSumNacht;
                   SollSumNacht:=getValue (55,12,dummy,0,99,1);
             end;
     end; (* case *)
     saveSchedule;
end;




procedure ChangeMonthHours;
var val:INTEGER;

begin
     if NOT testOK then exit;
     if currentPerson=0 then exit;
     choice:=currentPerson;
     Window (1, 1, 80, 25);
     TextBackground(Black);
     TextColor(Lightgray);
     Clrscr;
     gotoxy(1,11);
     write('Sie k”nnen nun eine neue Stundenanzahl eingeben, oder die alte belassen.');
     gotoxy(1,13);
     write('Welche Monatsstundenanzahl :');
     val:=getValue (30,13,Hours[choice],0,999.90,0.1);
     changeable[choice]:=0;
     saveSchedule;
end;




procedure WorkSchedule;
const Xwidth = 16;
      Ywidth = 8;
var error,Yinc,
    Xpos,Ypos,
    Xmax,Ymax,
    lastPosX,
    lastPosY,
    dummy,
    Xorigin,Yorigin : INTEGER;
    wrong,virtMode,
    undoEmpty       : BOOLEAN;
    buf,key         : CHAR;
    val,OverT       : REAL;



procedure displayCursor;
var absX,absY:INTEGER;

begin
     absX:=(Xpos-Xorigin)*3+21;
     absY:=(Ypos-Yorigin)*2+4;
     gotoxy(absX,absY);
     if ((Ypos-1) DIV 2) +1 = choice then TextColor(White)
         else TextColor(Lightgray);
     if (Ypos mod 2 = 1) then
     begin
        if (ord(Overtime[(Ypos DIV 2)+1,Xpos])>32) then TextColor(Green);
        TextBackground (Blue);
        case Plan[(Ypos DIV 2)+1,Xpos] of
          'M': write(fre1);
          'J': write(fre2);
          'T': write(day);
          'N': write(nite);
          'A': write(aft);
          'U': write(hol);
          'V': write(morn);
          'S': write(sle);
        end;
        TextBackground (Black);
     end
     else
     begin
        TextBackground (Blue);
        case Suggest[(Ypos DIV 2),Xpos] of
          'M': write(fre1);
          'J': write(fre2);
          'T': write(day);
          'N': write(nite);
          'A': write(aft);
          'U': write(hol);
          'V': write(morn);
          'S': write(sle);
          ' ': write('  ');
          'k': write(cour);
        end;
        TextBackground (Cyan);
        case Suggest[(Ypos DIV 2),Xpos] of
          'm': write(fre1);
          'j': write(fre2);
          't': write(day);
          'n': write(nite);
          'a': write(aft);
          'u': write(hol);
          'v': write(morn);
          's': write(sle);
        end;
        TextBackground (Magenta);
        case Suggest[(Ypos DIV 2),Xpos] of
          '-': write(fre1);
          '*': write(fre2);
          '4': write(day);
          '.': write(nite);
          '!': write(aft);
          '5': write(hol);
          '6': write(morn);
          '3': write(sle);
        end;

     end;
     TextBackground (Black);
end;



procedure deleteCursor;
var absX,absY:INTEGER;

begin
     absX:=(Xpos-Xorigin)*3+21;
     absY:=(Ypos-Yorigin)*2+4;
     gotoxy(absX,absY);
     if ((Ypos-1) DIV 2) +1 = choice then TextColor(White)
         else TextColor(Lightgray);
     if (Ypos mod 2 = 1) then
     begin
        if (ord(Overtime[(Ypos DIV 2)+1,Xpos])>32) then TextColor(Green);
        TextBackground (Black);
        case Plan[(Ypos DIV 2)+1,Xpos] of
          'M': write(fre1);
          'J': write(fre2);
          'T': write(day);
          'N': write(nite);
          'A': write(aft);
          'U': write(hol);
          'V': write(morn);
          'S': write(sle);
        end;
        TextBackground (Black);
     end
     else
     begin
        TextBackground (Black);
        case Suggest[(Ypos DIV 2),Xpos] of
          'M': write(fre1);
          'J': write(fre2);
          'T': write(day);
          'N': write(nite);
          'A': write(aft);
          'U': write(hol);
          'V': write(morn);
          'S': write(sle);
          ' ': write('  ');
          'k': write(cour);
        end;
        TextBackground (Green);
        case Suggest[(Ypos DIV 2),Xpos] of
          'm': write(fre1);
          'j': write(fre2);
          't': write(day);
          'n': write(nite);
          'a': write(aft);
          'u': write(hol);
          'v': write(morn);
          's': write(sle);
        end;
        TextBackground (Red);
        case Suggest[(Ypos DIV 2),Xpos] of
          '-': write(fre1);
          '*': write(fre2);
          '4': write(day);
          '.': write(nite);
          '!': write(aft);
          '5': write(hol);
          '6': write(morn);
          '3': write(sle);
        end;
     end;
     TextBackground (Black);
end;



procedure displayScreen;
Var i,j,k,l,m           : INTEGER;
    absX,absY           : INTEGER;
    Deltastring         : STRING[5];
    SuVor,SuNam,SuNach  : INTEGER;

begin
     (* write Date & Sums *)
     For i:= Xorigin to (Xorigin-1)+Xwidth do
     begin
         if SonnFeiertag[i] then TextColor(Red)
         else TextColor(Lightgray);
         gotoxy((i-Xorigin)*3+21,2);
         if i<10 then
            begin
            write('0');
            write(i);
            end
         else
            write(i);
         if virtMode then SuVor:=virtSumVormittag[i]
         else SuVor:=SumVormittag[i];
         if virtMode then SuNam:=virtSumNachmittag[i]
         else SuNam:=SumNachmittag[i];
         if virtMode then SuNach:=virtSumNachtdienst[i]
         else SuNach:=SumNachtdienst[i];

         gotoxy((i-Xorigin)*3+21,20);
         TextColor(Lightgray);
         if SuVor < SollSumVorm then TextColor(LightRed)
         else if SuVor > SollSumVorm then TextColor(LightGreen);
         write(SuVor:2);
         gotoxy((i-Xorigin)*3+21,22);
         TextColor(Lightgray);
         if SuNam < SollSumNachm then TextColor(LightRed)
         else if SuNam > SollSumNachm then TextColor(LightGreen);
         write(SuNam:2);
         gotoxy((i-Xorigin)*3+21,24);
         TextColor(Lightgray);
         if SuNach < SollSumNacht then TextColor(LightRed)
         else if SuNach > SollSumNacht then TextColor(LightGreen);
         write(SuNach:2);
     end;

     (* write names & Nds & +/- *)
     For j:= Yorigin to (Yorigin-1)+Ywidth do
     begin
         k:=j DIV 2;
         absY:=(j-Yorigin)*2+4;
         if ((j-1) DIV 2) +1 = responsible then
            begin
            TextColor(Magenta);
            if ((j-1)DIV 2)+1= choice then TextColor(White);
            end
         else
             begin
             if ((j-1)DIV 2)+1= choice then TextColor(White)
             else TextColor(Lightgray);
             end;
         if j > Ymax then j:=(Yorigin-1)+Ywidth
         else
         begin
           Window(2,absY,19,absY);
           ClrScr;
           Window(2,absY,20,absY);
           if (j mod 2 = 1) then
           begin
              if (Pos(' ', Person [k+1]) > 18) OR (Pos(' ', Person [k+1]) = 0)
                 then l:=18
              else
                 l:= Pos(' ', Person [k+1]);
              Write(Copy (Person [k+1],1,l));            (* Vorname *)
           end
           else
           begin
              if Pos(' ', Person [k]) < 8 then
                 if Pos(' ', Person [k]) = 0 then m:=0
                 else m:=18
              else m:= Length(Person[k])-Pos(' ', Person [k]);
              Write(Copy (Person [k],Pos(' ', Person [k])+1,m));
           end;                                           (* Nachname *)
           Window(1,1,80,25);
           if (j mod 2 = 1) then
           begin
            gotoxy(69,absY);
            if virtMode then write(virtNachtdienste[k+1]:2)
            else write(Nachtdienste[k+1]:2);
            gotoxy(72,absY);
            if virtMode then
            begin
                    if virtDienststunden [k+1] >= Hours [k+1] then
                       write('+ ',virtDienststunden[k+1]-Hours[k+1]:6:2)
                    else
                       write('- ',Hours[k+1]-virtDienststunden[k+1]:6:2);
            end
            else
            begin
                    if Dienststunden [k+1] >= Hours [k+1] then
                       write('+ ',Dienststunden[k+1]-Hours[k+1]:6:2)
                    else
                       write('- ',Hours[k+1]-Dienststunden[k+1]:6:2);
            end;
           end
           else
           begin
            gotoxy(69,absY);
            write(' Vorschlag');
           end;
         end;
     end;


     (* write content of Schedule *)
     For j:= Yorigin to (Yorigin-1)+Ywidth do
         For i:= Xorigin to (Xorigin-1)+Xwidth do
         begin
               if ((j-1) DIV 2) +1 = choice then TextColor(White)
               else TextColor(Lightgray);
               absX:=(i-Xorigin)*3+21;
               absY:=(j-Yorigin)*2+4;
               gotoxy (absX,absY);
               if j > Ymax then write('  ')
               else
               begin
                  if (j mod 2 = 1) then
                  begin
                  if (ord(Overtime[(j DIV 2)+1,i])>32) then TextColor(Green);
                  case Plan[(j DIV 2)+1,i] of
                       'M': write(fre1);
                       'J': write(fre2);
                       'T': write(day);
                       'N': write(nite);
                       'A': write(aft);
                       'U': write(hol);
                       'V': write(morn);
                       'S': write(sle);
                       end
                  end
                  else
                  begin
                  case Suggest[j DIV 2,i] of
                       'M': write(fre1);
                       'J': write(fre2);
                       'T': write(day);
                       'N': write(nite);
                       'A': write(aft);
                       'U': write(hol);
                       'V': write(morn);
                       'S': write(sle);
                       ' ': write('  ');
                       'k': write(cour);
                       end;
                  TextBackground (Green);
                  case Suggest[j DIV 2,i] of
                       'm': write(fre1);
                       'j': write(fre2);
                       't': write(day);
                       'n': write(nite);
                       'a': write(aft);
                       'u': write(hol);
                       'v': write(morn);
                       's': write(sle);
                       end;
                  TextBackground (Red);
                  case Suggest[j DIV 2,i] of
                       '-': write(fre1);
                       '*': write(fre2);
                       '4': write(day);
                       '.': write(nite);
                       '!': write(aft);
                       '5': write(hol);
                       '6': write(morn);
                       '3': write(sle);
                       end;
                  end;
               end;
               TextBackground (Black);
         end;
         TextColor(Lightgray);
end;




function GetMaxHours:Real;

begin
case Plan[choice,Xpos] of
     'M': GetMaxHours:=0.0;
     'J': GetMaxHours:=0.0;
     'T': GetMaxHours:=12.5;
     'N': GetMaxHours:=12.5;
     'A': GetMaxHours:=7.5;
     'U': GetMaxHours:=0.0;
     'V': GetMaxHours:=8.0;
     'S': GetMaxHours:=0.0;
     end
end;




procedure PutItem (PutChar:CHAR);
var buf:CHAR;

begin
     if (Ypos mod 2 = 1) AND (PutChar = 'k') then exit;
     if (Ypos mod 2 = 1) then  (* choice made in plan *)
     begin
        buf:=Suggest[(Ypos DIV 2)+1,Xpos];
        if buf <> 'k' then
        begin
          if (buf = PutChar) OR                      (* Suggestion = Plan ? *)
          (buf = Chr(Ord(PutChar)+32)) OR
          (buf = Chr(Ord(PutChar)-32)) then
            buf := Chr(Ord(PutChar)+32)
          else
          begin                                        (* no t'isnt ! *)
            if ord(buf)-64 > 32 then dec(buf,64);
            if ord(buf)-32 > 32 then dec(buf,32);
          end;
        end;
        Suggest[(Ypos DIV 2)+1,Xpos]:=buf;           (* reset Suggest *)
        Plan[(Ypos DIV 2)+1,Xpos]:=PutChar;
     end
     else                                       (* choice made in Suggest *)
     begin
          Suggest[(Ypos DIV 2),Xpos]:=Putchar;
          displayScreen;
          MakeSuggestion((Ypos DIV 2),Xpos);
          Who[(Ypos DIV 2),Xpos]:=chr(choice+32);
          drawFrame;
     end;
     virtrecalc;
     recalc;
     displayScreen;
                                        (* 1 right *)
     if Xpos+1 > Xmax then
        Xpos:=Xmax
     else
     begin
          if ((Xpos+1)-(Xorigin-1)) > Xwidth then
          begin
               inc (Xorigin);
               inc (Xpos);
               displayScreen;     (* Scroll *)
          end
          else
              inc (Xpos);        (* no Scroll *)
          end;
     displayCursor;
     wrong:=FALSE;
end;



(* begin of Procedure WorkSchedule *)

begin
     if NOT testOK then exit;
     if NOT calcSunHoliday then exit;
     if currentPerson=0 then exit;
     choice:=currentPerson;
     if changeable[choice]=1 then
     begin
          error:=0;
          Clrscr;
          gotoxy(1,9);
          write('Sie haben fr diesen Monat noch keine Stundenanzahl festgelegt !');
          gotoxy(1,11);
          write('Sie k”nnen nun eine neue Stundenanzahl eingeben, oder die alte belassen.');
          gotoxy(1,13);
          write('Welche Monatsstundenanzahl :');
          val:=getValue (30,13,Hours[choice],0,999.90,0.1);
          changeable[choice]:=0;
     end;

     virtrecalc;
     recalc;
     Xmax:=MonthLength(Y,M); Ymax:=numPerson*2;
     Xpos:=1;                Ypos:=(choice-1)*2 + 1;
     Xorigin:= 1;            Yorigin:= (choice-1)*2 + 1;
     wrong:=FALSE;    virtMode:=FALSE;
     drawFrame;       displayScreen;       displayCursor;
     repeat
       TextColor(LightGray);
       TextBackground(Black);
       if wrong then
       begin
            gotoxy(70,20);  write('Falsche  ');
            gotoxy(70,21);  write('Taste    ');
            gotoxy(70,22);  write('bet„tigt ');
       end
       else
       begin
            gotoxy(70,20);  write('Verlassen');
            gotoxy(70,21);  write('mit Taste');
            gotoxy(70,22);  write('Ctrl + Q!');
       end;
       TextColor(White);
       if virtMode then
       begin
            gotoxy(70,24);  write('WWW Modus');
       end
       else
       begin
            gotoxy(70,24);  write('Realmodus');
       end;

       key:=readkey;
       if key = Chr(0) then
       begin
         key:= readkey;
         case ord(key) of
         80: begin                        (* Position down *)
                deleteCursor;
                if ((Ypos-1) DIV 2 = choice-1) then   (* this Item current *)
                   if (Ypos MOD 2 = 1) then Yinc:=1
                   else Yinc:=2
                else Yinc:=2;

                if (Ypos DIV 2 = choice-1) then       (* next Item current *)
                   Yinc:=1
                else Yinc:=2;

                if Ypos+Yinc > Ymax then
                   Ypos:=yMax
                else
                begin
                   if ((Ypos+2)-Yorigin) > Ywidth then
                   begin
                        inc (Yorigin,2);
                        inc (Ypos,Yinc);
                        displayScreen;     (* Scroll *)
                   end
                   else
                        inc (Ypos,Yinc);   (* no Scroll *)
                end;
                displayCursor;
                wrong:=FALSE;
             end;

         72: begin              (* Position up *)
                deleteCursor;
                if ((Ypos-1) DIV 2 = (choice-1)) then
                   Yinc:=1
                else Yinc:=2;

                if Ypos-Yinc < 2 then
                   if ((Ypos-1) DIV 2 = (choice-1)) then
                      Ypos:=1
                   else
                      Ypos:=2
                else
                begin
                   if ((Ypos-Yinc)-Yorigin) < 0 then
                   begin
                        dec (Yorigin,2);
                        dec (Ypos,Yinc);
                        displayScreen;     (* Scroll *)
                   end
                   else
                        dec (Ypos,Yinc);   (* no Scroll *)
                end;
                displayCursor;
                wrong:=FALSE;
             end;

         77: begin         (* Position right *)
                deleteCursor;
                if Xpos+1 > Xmax then
                   Xpos:=Xmax
                else
                begin
                   if ((Xpos+1)-(Xorigin-1)) > Xwidth then
                   begin
                        inc (Xorigin);
                        inc (Xpos);
                        displayScreen;     (* Scroll *)
                   end
                   else
                        inc (Xpos);        (* no Scroll *)
                end;
                displayCursor;
                wrong:=FALSE;
             end;

         75: begin         (* Position left *)
                deleteCursor;
                if Xpos-1 < 1 then
                   Xpos:=1
                else
                begin
                   if ((Xpos-1)-(Xorigin-1)) < 1 then
                   begin
                        dec (Xorigin);
                        dec (Xpos);
                        displayScreen;     (* Scroll *)
                   end
                   else
                        dec (Xpos);        (* no Scroll *)
                end;
                displayCursor;
                wrong:=FALSE;
             end;
         71: begin
              Xpos:=1;
              Xorigin:=1;
              displayScreen;
              displayCursor;
              wrong:=FALSE;
             end;
         79: begin
              Xpos:=Xmax;
              Xorigin:=Xmax-Xwidth+1;
              displayScreen;
              displayCursor;
              wrong:=FALSE;
             end;
         73: begin
             if choice = 1 then Ypos:=1
              else Ypos:=2;
              Yorigin:=1;
              displayScreen;
              displayCursor;
              wrong:=FALSE;
             end;
         81: begin
              if (choice = (Ymax DIV 2) +1) then Ypos:=Ymax
              else Ypos:=Ymax;
              if numPerson<4 then Yorigin:= 1
              else Yorigin:=Ymax-7;
              displayScreen;
              displayCursor;
              wrong:=FALSE;
             end;
         else wrong:= TRUE;
         end; (* case *)
       end
       else
       begin
         case ord(key) of
          32: begin
              (* Toggle Virtual Mode *)
              if virtMode then virtMode:=FALSE
              else virtMode:=TRUE;
              displayScreen;
              displayCursor;
              wrong:=FALSE;
              end;
           8: begin
              (* in Plan: set Free,in Suggest: set Who on ' ' (No Comment) *)
              if (Ypos mod 2 = 1) then
                   Plan[(Ypos DIV 2)+1,Xpos]:='M'
              else
                   begin
                   Suggest[Ypos DIV 2,Xpos]:=' ';
                   Who[Ypos DIV 2,Xpos]:=' ';
              end;
                                                 (* 1 left *)
              if Xpos-1 < 1 then
                   Xpos:=1
              else
              begin
                   if ((Xpos-1)-(Xorigin-1)) < 1 then
                   begin
                        dec (Xorigin);
                        dec (Xpos);
                        displayScreen;     (* Scroll *)
                   end
                   else
                        dec (Xpos);        (* no Scroll *)
              end;
              recalc;
              virtrecalc;
              displayScreen;
              displayCursor;
              wrong:=FALSE;
              end;
          13: begin              (* Return: Overtime/look up Suggestion *)
              (* Set or look up Overtime *)
              if ((Ypos-1) DIV 2 = choice-1) then  (* only in own Schedule *)
                if (Ypos MOD 2 = 1) then
                begin
                   OverT:=(ord(OverTime[choice,Xpos])-32)*0.5;
                   if GetMaxHours<>0.0 then
                   begin
                      OverSum[choice]:=Oversum[choice]-OverT;
                      dummy:=getValue ((Xpos-Xorigin)*3+17,(Ypos-Yorigin)*2+6,OverT,0,GetMaxHours,0.5);
                      OverSum[choice]:=Oversum[choice]+OverT;
                   end;
                   OverTime[choice,Xpos]:=chr(trunc(OverT*2)+32);
                   drawFrame;
                   displayScreen;
                   displayCursor;
                end;
              (* look up Suggestion *)
              if (Ypos mod 2 = 0) AND (Who[Ypos DIV 2,Xpos] <> ' ') then
              begin                        (* Somebody made a Comment *)
                  GetSuggestion (Ypos DIV 2,Xpos);
                  key:=Chr(0);
                  drawFrame;
                  displayScreen;
                  displayCursor;
              end;
              wrong:=FALSE;
              end;
          15: begin              (* Ctrl+O: Ok to Suggestion *)
                if (Ypos mod 2 = 0) AND (Ypos DIV 2 = choice) then
                begin
                  buf:= Suggest [(Ypos DIV 2),Xpos];
                  if (buf <> ' ') AND (buf <> 'k') then
                  begin
                     if ord(buf)+32 < 128 then inc(buf,32);
                     if ord(buf)+32 < 128 then inc(buf,32);
                     Suggest [(Ypos DIV 2),Xpos] := buf;
                  end;
                end;
                displayScreen;
                displayCursor;
                wrong:=FALSE;
              end;
          24: begin              (* Ctrl+X: No Ok to Suggestion *)
                if (Ypos mod 2 = 0) AND (Ypos DIV 2 = choice) then
                begin
                   buf:= Suggest [(Ypos DIV 2),Xpos];
                   if (buf <> ' ') AND (buf <> 'k') then
                   begin
                     if ord(buf)-32 > 32 then dec(buf,32);
                     if ord(buf)-32 > 32 then dec(buf,32);
                     Suggest [(Ypos DIV 2),Xpos] := buf;
                   end;
                end;
                displayScreen;
                displayCursor;
                wrong:=FALSE;
              end;
          42: PutItem ('J');              (* '*': Free any case *)
          43: PutItem ('J');              (* '+': Free any case *)
          45: PutItem ('M');              (* '-': Free *)
          95: PutItem ('M');              (* '-': Free *)
         115: PutItem ('A');              (* 's': afternoon *)
          83: PutItem ('A');              (* 'S': afternoon *)
         110: PutItem ('N');              (* 'n': night *)
          78: PutItem ('N');              (* 'N': night *)
         114: PutItem ('S');              (* 'r': sleeping day *)
          82: PutItem ('S');              (* 'R': sleeping day *)
         116: PutItem ('T');              (* 't': day *)
          84: PutItem ('T');              (* 'T': day *)
         117: Putitem ('U');              (* 'u': holiday *)
          85: Putitem ('U');              (* 'U': holiday *)
         102: Putitem ('V');              (* 'f': morning *)
          70: Putitem ('V');              (* 'F': morning *)
         107: Putitem ('k');              (* 'k': course *)
          75: Putitem ('k');              (* 'K': course *)
         else wrong:= TRUE;
       end; (* case *)
     end;
     until ord(key)=17;
     saveSchedule;
end;




procedure selectPerson;

begin
     if NOT testOK then exit;
     message('Anschlieáend Person ausw„hlen, welche ihren Dienstplan',
               'in weiterer Folge bearbeiten m”chte.');
     currentPerson:=Personmenu;
     curPersId:=PersonId[currentPerson];
     if NOT getPassword(currentPerson) then currentPerson:=0;
end;




procedure DeselectPerson;

begin
     currentPerson:=0;
end;




procedure deleteSchedules;
var
  DirInfo  : SearchRec;
  extens   : INTEGER;
  searchy  : INTEGER;
  ext      : STRING[3];
  f        : file;
  ch       : Char;
  showstr  : STRING;
  key      : CHAR;

begin
  Clrscr;
  searchy:=1990;
  while searchy<y-1 do
  begin
     extens:=searchy;
     extens:=extens mod 1000;
     extens:=extens mod 100;
     extens:=extens+100*(y DIV 1000);
     Str(extens, ext);
     FindFirst('*.'+ext, Archive, DirInfo);
     while DosError = 0 do
     begin
       if (DirInfo.Name[1]<>'$') then
       begin
          showstr:=DirInfo.Name;
          Assign(f,showstr);
          Writeln('L”sche ', showstr);
          if FileExists(showstr) then Erase(f);
          showstr[1]:='$';
          Assign(f,showstr);
          if FileExists(showstr) then Erase(f);
       end;
       FindNext(DirInfo);
     end;
     inc(searchy);
  end;
  writeln;
  gotoxy(19,25);
  TextBackground(Blue);
  write('---- Bitte irgendeine Taste bet„tigen ----');
  TextBackground(Black);
  key:=Readkey;
end;





procedure Titlescreen;
var key:CHAR;

begin
 Window (1, 1, 80, 25);
 TextBackground(Black);
 TextColor(White);
 Clrscr;
 writeln;
 writeln;
 writeln;
 writeln('**********       **   ***********   **        **     ********     ************');
 writeln('***********      **   ***********   ***       **    **********    ************');
 writeln('**        **     **   **            ****      **   **        **        **     ');
 writeln('**         **    **   **            ** **     **   **        **        **     ');
 writeln('**          **   **   **            **  **    **   **        **        **     ');
 writeln('**           **  **   **            **   **   **   **        **        **     ');
 writeln('**           **  **   *******       **    **  **    ****               **     ');
 writeln('**           **  **   *******       **     ** **       ****            **     ');
 writeln('**           **  **   **            **      ****          ****         **     ');
 writeln('**           **  **   **            **       ***   **        **        **     ');
 writeln('**          **   **   **            **        **   **        **        **     ');
 writeln('**         **    **   **            **        **   **        **        **     ');
 writeln('**        **     **   **            **        **   **        **        **     ');
 writeln('***********      **   ***********   **        **    **********         **     ');
 writeln('**********       **   ***********   **        **     ********          **     ');
 writeln;
 writeln;
 writeln('        EIN PROGRAMM ZUR UNTERSTšTZUNG DER FLEXIBLEN DIENST-EINTEILUNG');
 gotoxy(19,25);
 TextBackground(Blue);
 write('---- Bitte irgendeine Taste bet„tigen ----');
 TextBackground(Black);
 TextColor(LightGray);
 key:=Readkey;
end;





(* main program *)

begin
     menuPosition:=0;numperson:=0;nextPersonID:=1;currentPerson:=0;
     curPersId:=0;
     Titlescreen;
     getLastSchedule(Schedname);
     if Date = '' then
     begin
        message ('Es wurde noch nie ein Dienstplan erstellt (auch keine Personen eingetragen)...',
                 '... mit Menpunkt "Person hinzufgen" k”nnen Sie Personen eintragen ! ');
     end
     else
     begin
        readSchedule;
        recalc; virtrecalc;
     end;
     if (DiskFree(0)<100000) then
           begin
           message ('Es ist nur mehr sehr wenig Speicherkapazit„t vorhanden ...',
                   '... l”schen sie alle nicht mehr ben”tigten Dienstpl„ne ! ');
           deleteSchedules;
           end;
     ex:=FALSE;
     repeat
           choice:=mainmenu;
           case choice of
                1: SelectPerson;
                2: DeselectPerson;
                3: WorkSchedule;
                4: FetchSchedule;
                5: NewSchedule;
                6: PrintOutSchedule;
                7: DelPerson;
                8: NewPerson;
                9: ChangePasswd;
                10: ChangeMonthHours;
                11: ChangePensum;
                12: editSunHoliday;
                13: ex:= TRUE;
           end;
     until ex;
     Window (1, 1, 80, 25);
     TextBackground(Black);
     TextColor(Lightgray);
     Clrscr;
     if Date<>'' then SaveSchedule;
end.







