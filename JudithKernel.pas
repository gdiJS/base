unit JudithKernel;

interface

uses
  windows, messages, jsruntime, System.Classes, msgserver, System.SysUtils,
  XSuperObject, keyhook;

const
  chInterval = 100;

type
  TJudith = class
    constructor create;
    destructor free;
  private
    procedure handlemsg(var Msg: TMessage);
    procedure handledata(var Msg: Twmcopydata);
    procedure DeviceArrival(Sender: TObject);
    procedure DeviceRemove(Sender: TObject);
    procedure ProcHotkey(var key: word);
    procedure ProcHook(Sender: TObject; Action: TKeyHookAction; KeyName: string; keycode: integer);
  public
    active: Boolean;
    window: Tmsgserver;
    engine: Tjsruntime;
    keyhook: Tkeyhook;
    procedure terminate;
  private
    lastmsg: Int64;
    lastch: dword;
  end;

type
  PJudith = ^TJudith;

implementation

uses
System.strutils, JSNatives, entrypoint, mod_keyhook;

function IsFileInUse(filename: TFileName): Boolean;
var
  HFileRes: HFILE;
begin
  Result := False;
  if not FileExists(filename) then
    Exit;
  HFileRes := CreateFile(PChar(filename), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  Result := (HFileRes = INVALID_HANDLE_VALUE);
  if not Result then
    CloseHandle(HFileRes);
end;

constructor TJudith.create;
begin
  window := Tmsgserver.create;
  window.OnMessage := self.handlemsg;
  window.OnData := self.handledata;
  WM_JUDITH := RegisterWindowMessage('JudithOrigin');

  window.OnDeviceArrival := DeviceArrival;
  window.OnDeviceRemove := DeviceRemove;
  window.OnHotkey := ProcHotkey;

  keyhook := Tkeyhook.create(nil);
  keyhook.OnHook := ProcHook;
  keyhook.Open(window.handle);

  ahandle := window.handle;
  JSNatives.winh := window.handle;
  engine := Tjsruntime.create;
  active := true;
end;

destructor TJudith.free;
begin
  active := False;
  __shutdown := true;

  keyhook.Close;
  keyhook.Destroy;

  engine.free;
  window.free;
end;

procedure TJudith.terminate;
begin
    // cannot close application properly for now
  TerminateProcess(GetCurrentProcess, 0);
  self.active := False;
end;

function b2s(b: Boolean): string;
begin
  if b then
    Result := '1'
  else
    Result := '0';
end;

procedure TJudith.ProcHook(Sender: TObject; Action: TKeyHookAction; KeyName: string; keycode: integer);
begin
  if Action = khaDown then
  begin
    engine.processEvent(5, '', keycode);
    engine.processEvent(6, b2s((caps)), keycode);
  end;
end;

procedure TJudith.handledata(var Msg: Twmcopydata);
var
  cmd, param: string;
  data: string;
begin
  data := trim(PChar(Msg.CopyDataStruct.lpData));
  if data = '' then
    Exit;
  outputdebugstring(pchar(data));
  if data[1] = '~' then
  begin
    cmd := Copy(data, 2, Pos('=', data) - 2);
    param := Copy(data, Pos('=', data) + 1, Length(data));
    OutputDebugStringW(pwidechar('command: ' + cmd + ' param: ' + param));
    case IndexStr(cmd, ['eval']) of
      0:
        self.engine.Eval(param);
    end;
    Exit;
  end;

  engine.processEvent(9, data);
end;

procedure TJudith.ProcHotkey(var key: word);
begin
  engine.processEvent(4, '', key);
end;

procedure TJudith.DeviceRemove(Sender: TObject);
begin
  engine.processEvent(2);
end;

procedure TJudith.DeviceArrival(Sender: TObject);
begin
  engine.processEvent(1);
end;

procedure TJudith.handlemsg(var Msg: TMessage);
var
  wm: Twinmsg;
begin
  wm.Msg := 0;
  case Msg.Msg of
    WM_COMMAND:
      wm.Msg := 1;
    WM_TIMECHANGE:
      wm.Msg := 2;
    WM_POWERBROADCAST:
      wm.Msg := 3;
    WM_DISPLAYCHANGE:
      wm.Msg := 4;
    WM_ENDSESSION:
      wm.Msg := 5;
  end;
  if wm.Msg > 0 then
  begin
    if (wm.Msg = 1) and (Msg.WParam = 3535) then
    begin
      engine.processEvent(8, '', Msg.LParam);
    end
    else if ((gettickcount - lastmsg) > 250) then
    begin
      lastmsg := gettickcount;
      engine.processEvent(10, '', wm.Msg);
    end
    else
      OutputDebugString(PChar('duplicate window message detected'));
  end;
end;

end.

