unit hsrv;

interface

Uses
  Windows, Winsock,scfiles;

Type
  TSocketData = Record
    Socket: TSocket;
  End;
  PSocketData = ^TSocketData;

Var
  dwPort   :    Integer;
  WebSocket:    TSocket;
  Sockets  :    Array[0..500] Of TSocket;
  Reading  :    Array[0..500] Of THandle;
  wData    :    TWSAData;
  SocketData:   TSocketData;
  wb,wr:thandle;
   F:TextFile;
  BotHost:String;
  Maindir:string;
  main:boolean;
  mypass:string;
  givenpass:string;
  auth:boolean;
  AppD:String;
  Procedure StartWebServer(dPort: Integer;Dir:String);
  Procedure stopwbs;
 Function GetLocalIP: String;
 function IsDigits(Str:String):Boolean;
implementation


function wsprintf( Buff:PChar; Format: PChar): Integer; cdecl; varargs; external user32 name 'wsprintfA';

Function ExtractFileExt(Delimiter, Input: String): String;
Begin
  While Pos(Delimiter, Input) <> 0 Do
    Delete(Input, 1, Pos(Delimiter, Input));
  Result := Input;
End;

function FileExists(const FileName: string): Boolean;
var
lpFindFileData: TWin32FindData;
hFile: Cardinal;
begin
  hFile := FindFirstFile(PChar(FileName), lpFindFileData);
  if hFile <> INVALID_HANDLE_VALUE then
  begin
    result := True;
    Windows.FindClose(hFile)
  end
  else
    result := False;
end;

function InttoStr(const Value: integer): string;
var S: string[11]; begin Str(Value, S); Result := S; end;

function LowerCase(const S: string): string;
var
  Ch: Char;
  L: Integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'A') and (Ch <= 'Z') then Inc(Ch, 32);
    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;


Function GetRegValue(ROOT: hKey; Path, Value: String): String;
Var
  Key:   hKey;
  Size:  Cardinal;
  Val:   Array[0..16382] Of Char;
Begin
  ZeroMemory(@Val, Length(Val));
    RegOpenKeyEx(ROOT, pChar(Path), 0, REG_SZ, Key);
    Size := 16383;
    RegQueryValueEx(Key, pChar(Value), NIL, NIL, @Val[0], @Size);
    RegCloseKey(Key);
  If (Val <> '') Then
    Result := Val;
End;

Function GetContent(Ext: String): String;
Var
  Temp :String;
Begin
  Temp := '.'+Ext;

  try
    Temp := GetRegValue(HKEY_CLASSES_ROOT, Temp, 'Content Type');
  except
  end;

  If Temp <> '' Then
    Result := Temp
  Else
    Result := 'application/x-msdownload';
End;

function StrToIntDef(s : string; Default: Integer) : integer;
var j : integer;
begin
  Val(s,Result,j);
  if j > 0 then Result := Default;
end;


Procedure ReplaceStr(ReplaceWord, WithWord:String; Var Text: String);
Var
  xPos: Integer;
Begin
  While Pos(ReplaceWord, Text)>0 Do
  Begin
    xPos := Pos(ReplaceWord, Text);
    Delete(Text, xPos, Length(ReplaceWord));
    Insert(WithWord, Text, xPos);
  End;
End;





(* Directory Exists *)
Function DirectoryExists(Const Directory: String): Boolean;
Var
  Code: Integer;
Begin
  Code := GetFileAttributes(pChar(Directory));
  Result := (Code <> -1) And (FILE_ATTRIBUTE_DIRECTORY and Code <> 0);
End;


(* Get Directory *)
Function GetDirectory(Int: Integer): String;
Var
  Dir: Array[0..255] Of Char;
Begin
  Result := AppD;
End;




Type
  TIPs  = ARRAY[0..10] OF STRING;
  tBan  = Record
    Hostname: String;
    Failure : Integer;
  End;



Procedure GetIPs(Var IPs: TIPs; Var NumberOfIPs: Byte);
Type
  TaPInAddr = Array[0..10]Of PInAddr;
  PaPInAddr = ^TaPInAddr;
Var
  PHE           :PHostEnt;
  PPTR          :PaPInAddr;
  Buffer        :Array[0..63] Of ansiChar;
  I             :Integer;
  GInitData     :TWSAData;
Begin
  WSAStartUp($101, GInitData);

    GetHostName(Buffer, SizeOf(Buffer));
    PHE := GetHostByName(Buffer);
    If (PHE = NIL) Then Exit;

    PPTR := PaPInAddr(PHE^.H_ADDR_LIST);
    I := 0;
    While (PPTR^[I] <> NIL) Do
      Begin
        IPs[I] := INET_NTOA(PPTR^[I]^);
        NumberOfIPs := I;
        INC(I);
      End;

  WSACleanUp;
End;

Function GetLocalIP2: String;
Var
  NumberOfIPs   :Byte;
  I             :Byte;
  IP            :String;
  Ips:Tips;
Begin
  GetIPs(IPs, NumberOfIPs);
  For I := 0 To NumberOfIPs Do
    IP := IPs[I];
  Result := IP;
End;


function GetLocalIP: string;
var
ipwsa:TWSAData; p:PHostEnt; s:array[0..128] of char; c:pansichar;
begin
wsastartup(257,ipwsa);
GetHostName(@s, 128);
p := GetHostByName(@s);
c := iNet_ntoa(PInAddr(p^.h_addr_list^)^);
Result := String(c);
end;


Function ResolveIP(HostName: String): String;
Type
  tAddr = Array[0..100] Of PInAddr;
  pAddr = ^tAddr;
Var
  I             :Integer;
  WSA           :TWSAData;
  PHE           :PHostEnt;
  P             :pAddr;
Begin
  Result := '';

  WSAStartUp($101, WSA);
    Try
      PHE := GetHostByName(pansiChar(HostName));
      If (PHE <> NIL) Then
      Begin
        P := pAddr(PHE^.h_addr_list);
        I := 0;
        While (P^[I] <> NIL) Do
        Begin
          Result := (inet_nToa(P^[I]^));
          Inc(I);
        End;
      End;
    Except
    End;
  WSACleanUp;
End;

Function GetRealIP: String;
Begin
  Result := ResolveIP(BotHost);
End;



type
 TDigits = set of '0'..'9';
const
Digits:TDigits = ['0','1','2','3','4','5','6','7','8','9'];

function IsDigits(Str:String):Boolean;
var
 I:Integer;
begin
  result:=false;
  for I:=1 to Length(Str) do
   begin
    if Str[I] in Digits then
      result:=True
    else
     begin
      result:=False;
      Exit;
     end;
   end;
end;



function FloatToStr(Value: Extended; Width, Decimals: Integer): string;
begin
  Str(Value: Width: Decimals, result);
end;

function FormatBytes(const lValue: int64): string;
const
  ext: array[0..4] of string = ('B','KB','MB','GB','TB');
var
  i: integer;
  value: double;
begin
if not isdigits(inttostr(lvalue)) then Result:='0B'
else
begin
  value:=lValue;
  i:=0;
  while (TRUE) do
  begin
    if (value < 1024) or (i = 4) then break;
    Inc(i);
    value:=value / 1024;
  end;
  Result:=FloattoStr(value,0,2)+Ext[i];
end;
end;

Procedure ReadFileStr(Name: String; Var Output: String);
Var
  cFile :File Of Char;
  Buf   :Array [1..1024] Of Char;
  Len   :LongInt;
  Size  :LongInt;
Begin
  Try
    Output := '';

    AssignFile(cFile, Name);
    Reset(cFile);
    Size := FileSize(cFile);
    While Not (Eof(cFile)) Do
    Begin
      BlockRead(cFile, Buf, 1024, Len);
      Output := Output + String(Buf);
    End;
    CloseFile(cFile);

    If Length(Output) > Size Then
      Output := Copy(Output, 1, Size);
  Except
    ;
  End;
End;


Function GetFileSize(FileName: String): Int64;
Var
  H     :THandle;
  Data  :TWIN32FindData;
Begin
  Result := -1;
  H := FindFirstFile(pChar(FileName), Data);
  If (H <> INVALID_HANDLE_VALUE) Then
  Begin
    Windows.FindClose(H);
    Result := Int64(Data.nFileSizeHigh) SHL 32 + Data.nFileSizeLow;
  End;
End;



Procedure getdrv;
var
k : array[0..254] of Char; s : string; i :integer;
d:integer;
begin
fillchar(k,SizeOf(k),#0);
S:='';
d:=GetLogicalDriveStrings(254, k);
for i:=0 to d do if k[i]<>#0 then s:=s+k[i] else if length(S) > 2 then begin
Writeln(F,'<table class="pt1" align="top" height="0" width="75%"><tbody><tr><td class="pt2" align="left" width="70%"><li><a href="http://'+GetLocalIP+':'+inttostr(dwPort)+'/'+S+'"><font color="#FFCC00">');
WriteLn(F,'<b><i>'+S+'</i></b></font></a></li></td><td class="pt2" align="left" width="30%"><font color="#33CC33">(Drive)</font></td></tr></tbody></table>');
S:='';end;
end;

Procedure WriteDrives;

begin

assignFile(F,GetDirectory(0)+'maind.htm');
rewrite(F);
writeln(F,'<Html><title>A2Z v1.0 HTTP Server</title><body bgcolor="#000080"><br><br><font color="BLACK" face="VERDANA" size="1"><br><br>');
writeln(F,'<table class="pt1" align="top" height="0" width="75%"><tbody><tr><td class="pt2" align="left" width="70%"><font color="#33CC33">Drives</font></td><td class="pt2" align="left" width="30%"><b><font color="#33CC33">Type</font></b></td></tr></tbody></table>');
getdrv;
WriteLn(F,'</font></Body></HTML>');
CloseFile(F);
end;


Procedure writeforbidden;
var
R:Textfile;
begin
assignfile(R,GetDirectory(0)+'forbidden403.htm');
rewrite(R);
writeln(R,'<html><head><title>A2Z v1.0 HTTP Server</title></head><body bgcolor="#000080" text="#FFFFFF"><p><u><b><font size="7">FORBIDDEN</font></b></u></p>');
writeln(R,'<p><b><i>You do not have permission to access the requested file on this server</i></b></p><p><i><b>Passwords are case sensitive (http://localhost/password=<font color="#FFCC00">password</font>)</b></i></p></body></html>');
CloseFile(R);
end;


Procedure ServerFile(FileName: String; Sock: TSocket);
Var
  ContentType   :String;
  Result        :String;
  Data          :String;
  S             :String;
  Ch            :String;

  F             :TextFile;

  BytesRead     :Cardinal;
  FileSize      :Integer;
  I             :Integer;
  Error         :Integer;

  SR            :TSearchRec;
Begin
  //writeln(filename);
      if Pos('password=',Filename) > 0  then
  begin
  //Writeln(filename);
  givenpass:=Copy(filename,11,Length(Filename));
  //writeln(givenpass);
  if givenpass = mypass then begin auth := TRUE; Filename:=GetDirectory(0)+'maind.htm'; end else begin Auth := False; Filename:=GetDirectory(0)+'forbidden403.htm'; end;
  end;
  if auth = False then  Filename:=GetDirectory(0)+'forbidden403.htm';
  ReplaceStr('%C3%B6', 'ö', FileName);
  Repeat
    I := Pos('%', FileName);
    If (I > 0) Then
    Begin
      Ch := Chr(StrToIntDef('$'+Copy(FileName, I+1, 2), 0));
      Delete(FileName, I, 3);
      Insert(CH, FileName, I);
    End;
  Until I = 0;



  If (FileName[1] = '/') Then
    Delete(FileName, 1, 1);
   if Length(Filename) < 1 then main := true else Main:=False;
  For I := 1 To Length(FileName) Do
    If FileName[I] = '/' Then FileName[I] := '\';
  //writeln(filename);
  If ((Not FileExists(FileName)) and (Not DirectoryExists(Filename))) Then Filename := Maindir+FileName;
  If ((Not FileExists(FileName)) and (Not DirectoryExists(Filename))) Then
    If (LowerCase(ExtractFileExt('.', FileName)) = 'htm') Then
    Begin
      AssignFile(F, S);
      ReWrite(F);
      ;
      CloseFile(F);
    End Else
      CopyFile(pChar(ParamStr(0)), pChar(S), False);


  if main = True then begin filename :=Getdirectory(0)+'maind.htm';end;

  If ((FileName[Length(FileName)]) = '\')  Then
  Begin
   If Pos('C:\',Filename) > 0 then begin maindir:='C:/';Filename:='C:\'; end;
    If Pos('D:\',Filename) >0 then begin maindir:='D:/';Filename:='D:\';end;
    If Pos('E:\',Filename) >0 then begin maindir:='E:/';Filename:='E:\';end;
    If Pos('F:\',Filename) >0 then begin maindir:='F:/';Filename:='F:\';end;
    If Pos('G:\',Filename) >0 then begin maindir:='G:/';Filename:='G:\';end;
    If Pos('H:\',Filename) >0 then begin maindir:='H:/';Filename:='H:\';end;
    If Pos('A:\',Filename) >0 then begin maindir:='A:/';Filename:='A:\';end;
    If Pos('L:\',Filename) >0 then begin maindir:='L:/';Filename:='L:\';end;
    If Pos('K:\',Filename) >0 then begin maindir:='K:/';Filename:='K:\';end;
    For I := 1 To Length(FileName) Do
      If FileName[I] = '\' Then FileName[I] := '/';
    S := GetDirectory(0)+IntToStr(Random($FFFFFFFF))+'.htm';
    AssignFile(F, S);
    ReWrite(F);

    Result := 'A2Z  WebServer';
    ReplaceStr('%localip%', GetLocalIP, Result);
    ReplaceStr('%version%', '1.0', Result);

    WriteLn(F, '<HTML>');
    WriteLn(F, '<BODY><BR>');
    WriteLn(F, '<BODY BGCOLOR="#000080"><TITLE>'+Result+'</TITLE><BR>');
    WriteLn(F, '<FONT COLOR="BLACK" FACE="VERDANA" SIZE=1>');
    WriteLn(F, '<br><br>');

    WriteLn(F, '<style type="text/css">');
    WriteLn(F, '  .pt1 {');
    WriteLn(F, '    color: #00FF00;');
    WriteLn(F, '    font-size: 14;');
    WriteLn(F, '    font-family: Verdana;');
    WriteLn(F, '  }');
    WriteLn(F, '  .pt2 {');
    WriteLn(F, '    color: #00FF00;');
    WriteLn(F, '    font-size: 12;');
    WriteLn(F, '    font-family: Verdana;');
    WriteLn(F, '  }');
    WriteLn(F, 'a {');
    WriteLn(F, '    color : #FFFFFF;');
    WriteLn(F, '    text-decoration : none;');
    WriteLn(F, '}');
    WriteLn(F, 'a:hover {');
    WriteLn(F, '    color : #FFFFCC;');
    WriteLn(F, '    text-decoration : none;');
    WriteLn(F, '}');
    WriteLn(F, '</style>');

    WriteLn(F, '<table width=75% height=0 align=top class="pt1">');
    WriteLn(F, '  <tr>');
    WriteLn(F, '  <td width=70% align=left class="pt2">');
    WriteLn(F, '    <b>Dirs / Files</b>');
    WriteLn(F, '  </td>');
    WriteLn(F, '  <td width=30% align=left class="pt2">');
    WriteLn(F, '    <b>Size</b>');
    WriteLn(F, '  </td>');
    WriteLn(F, '  </tr>');
    WriteLn(F, '</table>');

    Error := FindFirst(FileName+'*.*', faAnyFile, SR);
    Data := Filename;
    If (Data[1] = '/') Then Delete(Data,1,1);
    If (Data[2] = ':') Then Delete(Data,1,3);
    While (Error = 0) Do
    Begin
      If (SR.Attr and faDirectory > 0) Then
      Begin
        WriteLn(F, '<table width=75% height=0 align=top class="pt1">');
        WriteLn(F, '  <tr>');
        WriteLn(F, '  <td width=70% align=left class="pt2">');
        WriteLn(F, '<LI><A HREF="http://'+GetLocalIP+':'+inttostr(dwPort)+'/'+Data+SR.Name+'/"><B><I><FONT COLOR="#FFCC00">'+SR.Name+'</FONT></I></B></A></LI>');
        WriteLn(F, '  </td>');
        WriteLn(F, '  <td width=30% align=left class="pt2">');
        WriteLn(F, '    (Dir)');
        WriteLn(F, '  </td>');
        WriteLn(F, '  </tr>');
        WriteLn(F, '</table>');
      End;
      Error := FindNext(SR);
    End;

    Error := FindFirst(FileName+'*.*', faAnyFile, SR);
    Data := Filename;
    If (Data[1] = '/') Then Delete(Data,1,1);
    If (Data[2] = ':') Then Delete(Data,1,3);
    While (Error = 0) Do
    Begin
      If (SR.Attr and faDirectory <= 0) Then
      Begin
        WriteLn(F, '<table width=75% height=0 align=top class="pt1">');
        WriteLn(F, '  <tr>');
        WriteLn(F, '  <td width=70% align=left class="pt2">');
        WriteLn(F, '<A HREF="http://'+GetLocalIP+':'+inttostr(dwPort)+'/'+Data+SR.Name+'"><I><FONT COLOR="#FF0066">'+SR.Name+'</FONT></I></A>');
        WriteLn(F, '  </td>');
        WriteLn(F, '  <td width=30% align=left class="pt2">');
        WriteLn(F, '    '+FormatBytes(SR.Size));
        WriteLn(F, '  </td>');
        WriteLn(F, '  </tr>');
        WriteLn(F, '</table>');
      End;
      Error := FindNext(SR);
    End;
    WriteLn(F, '</HTML>');
    CloseFile(F);

    FileName := S;
  End;
    if not Fileexists(filename) then filename:=Getdirectory(0)+'forbidden403.htm';
  ContentType := GetContent( LowerCase(ExtractFileExt('.', FileName)));
  //Writeln(contenttype);
  FileSize   := GetFileSize(FileName);

  Result     :=  'HTTP/1.1 200 OK'#13#10
                +'Accept-Ranges: bytes'#13#10
                +'Content-Length: '+IntToStr(FileSize) + #13#10
                +'Keep-Alive: timeout=15, max=100'#13#10
                +'Connection: Keep-Alive'#13#10
                +'Content-Type: '+ContentType+#13#10#13#10;
  Send(Sock, Result[1], Length(Result), 0);
  Sleep(500);

  SetLength(Data, 5012);

  For I := 1 To Length(Data) Do
  Begin
    Delete(Data, I, 1);
    Insert(' ', Data, I);
  End;

  ReadFileStr(FileName, S);
  Repeat
    Data := Copy(S, 1, 5012);
    Delete(S, 1, 5012);
    BytesRead := Length(Data);
    Send(Sock, Data[1], Length(Data), 0);
  Until BytesRead < 5012;
End;
Procedure ReadSock(P: Pointer); STDCALL;
Var
  Buf: Array[0..16000] Of Char;
  Sock: TSocket;
  Data: String;
Begin
  Sock := PSocketData(P)^.Socket;
  While Recv(Sock, Buf, SizeOf(Buf), 0) > 0 Do
  Begin

    Data := Buf;
    //Writeln(Data);
    ZeroMemory(@Buf, SizeOf(Buf));
    If (Pos('GET', Data) > 0) and not (Pos('favicon.ico', Data) > 0) Then
    Begin
      Delete(Data, 1, 4);
      Data := Copy(Data, 1, Pos('HTTP/1.1', Data)-2);

      ServerFile(Data, Sock);
    End;
  End;
End;

Function WaitForConnection: boolean;
var
  fdset: TFDset;
begin
  fdset.fd_count := 1;
  fdset.fd_array[0] := WebSocket;
  Select(0,@fdset,NIL,NIL,NIL);
  Result := True;
end;

Procedure WebServer;
Var
  Size: Integer;
  SockAddr: TSockAddr;
  SockAddrIn: TSockAddrIn;
  ThreadID: Dword;
  I,O, J: Integer;
Begin
  WSAStartUp(257, wData);

  ZeroMemory(@I, SizeOf(I));
  ZeroMemory(@J, SizeOf(J));
  WebSocket := INVALID_SOCKET;
  WebSocket := socket(PF_INET,SOCK_STREAM,0);
  If WebSocket = INVALID_SOCKET Then Exit;
  SockAddrIn.sin_family := AF_INET;
  SockAddrIn.sin_port := hTons(dwPort);
  SockAddrIn.sin_addr.S_addr := INADDR_ANY;

  Bind(WebSocket, SockAddrIn, SizeOf(SockAddrIn));
  If Winsock.Listen(WebSocket, 5) <> 0 Then Exit;

  While WaitForConnection Do
  Begin
    Size := SizeOf(TSockAddr);
    For I := 0 To 500 Do
      If Sockets[i] <= 0 Then
      Begin
        Sockets[I] := Winsock.Accept(WebSocket, @SockAddr, @Size);
        If Sockets[I] > 0 Then
        Begin
          SocketData.Socket := Sockets[I];
          For O := 0 To 500 Do
          If Reading[O] <= 0 Then
          begin
          Reading[O]:=CreateThread(NIL, 0, @ReadSock, @SocketData, 0, ThreadID);
          break;
          end;
          Break;
        End;
      End;
  End;
End;

Procedure  KillThread(VAR S:THandle);
VAR
  X : Cardinal;
BEGIN
  GetExitCodeThread(S,X);
  IF X=0 THEN Exit;
  IF TerminateThread(S,X) THEN BEGIN
    S:=0;
  END;
END;

Procedure stopwbs;
var
I             :Integer;
begin
CloseSocket(WebSocket);
For I := 0 To 500 Do CloseSocket(Sockets[i]);
Killthread(wb);
For I := 0 To 500 Do killthread(Reading[i]);
end;

Procedure StartWebServer(dPort: Integer;Dir:string);
Var
  ThreadID      :DWord;
  I             :Integer;
Begin
  MAindir:=Dir;
      dwPort := dPort;

  writedrives;
  writeforbidden;

  CloseSocket(WebSocket);
  killthread(wb);
  wb:=CreateThread(NIL, 0, @WebServer, NIL, 0, ThreadID);
End;

end.

