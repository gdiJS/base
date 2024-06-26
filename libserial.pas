unit libserial;

interface

uses
  Windows;

type
  Tportlist = array[0..32] of THandle;

var
  ph: Tportlist;

function OPENCOM(OpenString: Pchar): Integer; stdcall;

procedure TIMEOUTS(id, TOut: Integer);

procedure BUFFERSIZE(id, Size: Integer);

procedure CLOSECOM(id: integer);

procedure SENDBYTE(id, Dat: Integer);

function READBYTE(id: integer): Integer;

procedure SENDSTRING(id: Integer; Buffer: string);

function READSTRING(id: integer): Pchar;

procedure CLEARBUFFER(id: integer);

function INBUFFER(id: integer): DWORD;

function OUTBUFFER(id: integer): DWORD;

procedure DTR(id, State: integer);

procedure RTS(id, State: integer);

procedure TXD(id, State: integer);

function CTS(id: integer): Integer;

function DSR(id: integer): Integer;

function RI(id: integer): Integer;

function DCD(id: integer): Integer;

function INPUTS(id: integer): Integer;

procedure TIMEINIT();

function TIMEREAD(): Real;

procedure DELAY(DelayTime: Real);

procedure REALTIME();

procedure NORMALTIME();

function killall: integer;

implementation

var
  StartTime: Int64;
  TimeUnit: Real = 0.000838;
  shutdown: Boolean;

function killall: integer;
var
  i: integer;
  count: integer;
begin
  Result := -1;

  for i := Low(ph) to High(ph) do
  begin
    if (ph[i] > 0) and (ph[i] <> INVALID_HANDLE_VALUE) then
    begin
      PurgeComm(ph[i], PURGE_TXCLEAR);
      PurgeComm(ph[i], PURGE_RXCLEAR);
      CloseHandle(ph[i]);
      ph[i] := 0;
      inc(count);
    end;
  end;
  Result := count;

end;

function getavailslot: Integer;
var
  i: integer;
begin
  Result := -1;
  for i := Low(ph) to High(ph) do
  begin
    if (ph[i] = 0) or (ph[i] = INVALID_HANDLE_VALUE) then
    begin
      Result := i;
      exit;
    end;
  end;
end;

function OPENCOM(OpenString: pchar): Integer;
var
  PortStr, Parameter: string;
  DCB: TDCB;
  h: integer;
begin
  Result := 0;
  h := getavailslot;
  if h < 0 then
  begin
    Result := -1;
    exit;
  end;

  Parameter := OpenString;
  PortStr := copy(Parameter, 1, 4);
  ph[h] := CreateFile(PChar(PortStr), GENERIC_READ or GENERIC_WRITE, 0, NIL, OPEN_EXISTING, 0, 0);
  GetCommState(ph[h], DCB);
  BuildCommDCB(PChar(Parameter), DCB);
  // DCB.Flags := 1;
  if SetCommState(ph[h], DCB) then
    Result := h;
  TimeOuts(h, 10);
end;

procedure TIMEOUTS(id: Integer; TOut: Integer);
var
  TimeOut: TCOMMTIMEOUTS;
begin
  TimeOut.ReadIntervalTimeout := 1;
  TimeOut.ReadTotalTimeoutMultiplier := 1;
  TimeOut.ReadTotalTimeoutConstant := TOut;
  TimeOut.WriteTotalTimeoutMultiplier := 10;
  TimeOut.WriteTotalTimeoutConstant := TOut;
  SetCommTimeouts(ph[id], TimeOut);
end;

procedure BUFFERSIZE(id: Integer; Size: Integer);
begin
  SetupComm(ph[id], Size, Size);
end;

procedure CLOSECOM(id: Integer);
begin
  PurgeComm(ph[id], PURGE_TXCLEAR);
  PurgeComm(ph[id], PURGE_RXCLEAR);
  CloseHandle(ph[id]);
  ph[id] := 0;
end;

procedure SENDBYTE(id: Integer; Dat: Integer);
var
  BytesWritten: DWord;
begin
  if shutdown then
    exit;
  WriteFile(ph[id], Dat, 1, BytesWritten, NIL);
end;

function READBYTE(id: Integer): Integer;
var
  Dat: Byte;
  BytesRead: DWORD;
begin
  if shutdown then
    exit;
  ReadFile(ph[id], Dat, 1, BytesRead, NIL);
  if BytesRead = 1 then
    Result := Dat
  else
    Result := -1;
end;

procedure SENDSTRING(id: Integer; Buffer: string);
var
  BytesWritten: DWord;
  sa: Ansistring;
var
  i: integer;
  ts: integer;
begin
  if shutdown then
    exit;
  if Length(Buffer) > 0 then
  begin
    setlength(sa, length(Buffer));
    if length(sa) > 0 then
    begin
      for i := 1 to length(Buffer) do
        sa[i] := ansichar(byte(Buffer[i]));
      move(sa[1], Buffer[1], length(sa));
    end;
    CLEARBUFFER(ph[id]);
//  RTS(ph[id],1);
//  while CTS(ph[id])=0 do begin
//  Sleep(1);
// / inc(ts);
//  if ts>3000 then break
//  end;

//  TXD(ph[id],1);
    WriteFile(ph[id], Buffer[1], Length(Buffer), BytesWritten, NIL);
//  TXD(ph[id],0);
  end;

end;

function READSTRING(id: Integer): Pchar;
var
  Dat: Integer;
  Data: string;
begin
  Dat := 0;
  if shutdown then
    exit;
  while Dat > -1 do
  begin
    Dat := READBYTE(id);
    Data := Data + chr(Dat);
  end;
  result := PChar(Data);

  {
  while ((Dat > -1) and (Dat <> 13)) do
  begin
    Dat := ReadByte(id);
    if ((Dat > -1) and (Dat <> 13)) then
      Data := Data + Chr(Dat);
  end;
  READSTRING := pchar(Data);

  }
end;

procedure CLEARBUFFER(id: Integer);
begin
  PurgeComm(ph[id], PURGE_TXCLEAR);
  PurgeComm(ph[id], PURGE_RXCLEAR);
end;

function INBUFFER(id: Integer): DWORD;
var
  Comstat: _Comstat;
  Errors: DWORD;
begin
  if ClearCommError(ph[id], Errors, @Comstat) then
    INBUFFER := Comstat.cbInQue
  else
    INBUFFER := 0;
end;

function OUTBUFFER(id: Integer): DWORD;
var
  Comstat: _Comstat;
  Errors: DWORD;
begin
  if ClearCommError(ph[id], Errors, @Comstat) then
    OUTBUFFER := Comstat.cbOutQue
  else
    OUTBUFFER := 0;
end;

procedure DTR(id: Integer; State: integer);
begin
  if (State = 0) then
    EscapeCommFunction(ph[id], CLRDTR)
  else
    EscapeCommFunction(ph[id], SETDTR);
end;

procedure RTS(id: Integer; State: integer);
begin
  if (State = 0) then
    EscapeCommFunction(ph[id], CLRRTS)
  else
    EscapeCommFunction(ph[id], SETRTS);
end;

procedure TXD(id: Integer; State: integer);
begin
  if (State = 0) then
    EscapeCommFunction(ph[id], CLRBREAK)
  else
    EscapeCommFunction(ph[id], SETBREAK);
end;

function CTS(id: Integer): Integer;
var
  mask: Dword;
begin
  GetCommModemStatus(ph[id], mask);
  if (mask and MS_CTS_ON) = 0 then
    result := 0
  else
    result := 1;
end;

function DSR(id: Integer): Integer;
var
  mask: Dword;
begin
  GetCommModemStatus(ph[id], mask);
  if (mask and MS_DSR_ON) = 0 then
    result := 0
  else
    result := 1;
end;

function RI(id: Integer): Integer;
var
  mask: Dword;
begin
  GetCommModemStatus(ph[id], mask);
  if (mask and MS_RING_ON) = 0 then
    result := 0
  else
    result := 1;
end;

function DCD(id: Integer): Integer;
var
  mask: Dword;
begin
  GetCommModemStatus(ph[id], mask);
  if (mask and MS_RLSD_ON) = 0 then
    result := 0
  else
    result := 1;
end;

function INPUTS(id: integer): Integer;
var
  mask: Dword;
begin
  GetCommModemStatus(ph[id], mask);
  INPUTS := (mask div 16) and 15;
end;

procedure TIMEINIT();
var
  f: Int64;
begin
  QueryPerformanceFrequency(f);
  TimeUnit := 1000 / f;
  QueryPerformanceCounter(StartTime)
end;

function TIMEREAD(): Real;
var
  t: Int64;
begin
  QueryPerformanceCounter(t);
  TIMEREAD := TimeUnit * (t - StartTime);
end;

procedure DELAY(DelayTime: Real);
var
  TimeStart: real;
begin
  TimeStart := TIMEREAD;
  while TIMEREAD < (TimeStart + DelayTime) do
    ;
end;

procedure REALTIME();
begin
  SetPriorityClass(GetCurrentProcess(), REALTIME_PRIORITY_CLASS);
end;

procedure NORMALTIME();
begin
  SetPriorityClass(GetCurrentProcess(), NORMAL_PRIORITY_CLASS);
end;

initialization
  TIMEINIT();

end.

