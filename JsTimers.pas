unit JsTimers;

interface

uses
  Windows, messages, Generics.Collections, Classes;

type
  TOnTimerProc = reference to procedure;

function SetInterval(AProc: TOnTimerProc; ATimeout: Cardinal): cardinal;

function SetTimeout(AProc: TOnTimerProc; ATimeout: Cardinal): cardinal;

function ClearTimeout(id: cardinal): boolean;

function ClearInterval(id: cardinal): boolean;

procedure killAll;

type
  TTimerwin = class
    handle: HWND;
    constructor create;
    destructor free;
    procedure handler(var Msg: TMessage);
  end;

var
  timerWin: hwnd;
  w: TTimerwin;
  t: NativeUInt;
  TimerList: TDictionary<NativeUInt, TOnTimerProc>;
  TimerListX: TDictionary<NativeUInt, TOnTimerProc>;
  __kill: Boolean;

implementation

uses
  JSNatives;

procedure killall;
var
  Item: TPair<NativeUInt, TOnTimerProc>;
begin
  __kill := true;
  for Item in TimerList do
    KillTimer(timerWin, Item.Key);

  for Item in TimerListX do
    KillTimer(timerWin, Item.Key);
  timerlist.Clear;
  TimerListX.Clear;
end;

procedure TimerProc(hwnd: hwnd; uMsg: UINT; idEvent: UINT_PTR; dwTime: DWORD); stdcall;
var
  Proc: TOnTimerProc;
begin
  if TimerList.TryGetValue(idEvent, Proc) then
  try
    KillTimer(timerWin, idEvent);
    if not __kill then
      Proc();
  finally
    TimerList.Remove(idEvent);
  end;
end;

procedure TimerProcX(hwnd: hwnd; uMsg: UINT; idEvent: UINT_PTR; dwTime: DWORD); stdcall;
var
  Proc: TOnTimerProc;
begin
  if TimerListX.TryGetValue(idEvent, Proc) then
  try
    if not __kill then
      Proc()
    else
      TimerListX.Remove(idEvent);
  finally
  end;
end;

function SetTimeout(AProc: TOnTimerProc; ATimeout: Cardinal): cardinal;
begin
  if __kill then
    exit;

  Inc(t);
  result := SetTimer(timerWin, t, ATimeout, @TimerProc);
  TimerList.Add(result, AProc);
end;

function ClearTimeout(id: cardinal): boolean;
var
  Proc: TOnTimerProc;
begin
  if __kill then
    exit;

  Result := KillTimer(timerWin, id);
  TimerList.Remove(id);
end;

function ClearInterval(id: cardinal): boolean;
var
  Proc: TOnTimerProc;
begin
  if __kill then
    exit;

  result := KillTimer(timerWin, id);
  TimerListX.Remove(id);
end;

function SetInterval(AProc: TOnTimerProc; ATimeout: Cardinal): cardinal;
begin
  if __kill then
    exit;
  Inc(t);
  Result := SetTimer(timerWin, t, ATimeout, @TimerProcX);
  TimerListX.Add(result, AProc);
end;

procedure ttimerwin.handler(var Msg: TMessage);
begin
  Msg.Result := DefWindowProc(handle, Msg.Msg, Msg.wParam, Msg.lParam);
end;

constructor ttimerwin.create;
begin
  handle := AllocateHWnd(handler);
end;

destructor ttimerwin.free;
begin
  DeallocateHWnd(handle);
end;

initialization
  t := 0;
  w := ttimerwin.create;
  timerwin := w.handle;
  TimerList := TDictionary<NativeUInt, TOnTimerProc>.Create;
  TimerListX := TDictionary<NativeUInt, TOnTimerProc>.Create;

finalization
  TimerListX.Free;
  TimerList.Free;
  w.free;

end.

