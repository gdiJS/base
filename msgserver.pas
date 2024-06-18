unit msgserver;

interface

uses
  Windows, Messages, Classes;

type
  PDevBroadcastHdr = ^DEV_BROADCAST_HDR;

  DEV_BROADCAST_HDR = packed record
    dbch_size: DWORD;
    dbch_devicetype: DWORD;
    dbch_reserved: DWORD;
  end;

  PDevBroadcastDeviceInterface = ^DEV_BROADCAST_DEVICEINTERFACE;

  DEV_BROADCAST_DEVICEINTERFACE = record
    dbcc_size: DWORD;
    dbcc_devicetype: DWORD;
    dbcc_reserved: DWORD;
    dbcc_classguid: TGUID;
    dbcc_name: short;
  end;

const
  GUID_DEVINTERFACE_USB_DEVICE: TGUID = '{A5DCBF10-6530-11D2-901F-00C04FB951ED}';
  DBT_DEVICEARRIVAL = $8000;          // system detected a new device
  DBT_DEVICEREMOVECOMPLETE = $8004;          // device is gone
  DBT_DEVTYP_DEVICEINTERFACE = $00000005;      // device interface class

type
  TMsgserverEvent = procedure(var Msg: TMessage) of object;

  TUsbNotifyProc = procedure(Sender: TObject) of object;

  TMsgDataEvent = procedure(var Msg: TWMCopyData) of object;

  THotkeyEvent = procedure(var key: word) of object;

  Twinmsg = packed record
    msg: Cardinal;
    wparam: longint;
    lparam: LongInt;
  end;

  TMsgServer = class
  public
    handle: hwnd;
    WindowMsg: Cardinal;
    OnMessage: TMsgserverEvent;
    OnData: TMsgDataEvent;
    OnHotkey: THotkeyEvent;
    active: Boolean;
  protected
    procedure WMDeviceChange(var Msg: TMessage); dynamic;
  private
    NotifyHandle: Pointer;
    FOnUSBArrival: TUsbNotifyProc;
    FOnUSBRemove: TUsbNotifyProc;
    procedure WndMethod(var Msg: TMessage);
    function RegisterDevNotification: Boolean;
  public
    constructor Create;
    destructor free;
  published
    property OnDeviceArrival: TUsbNotifyProc read FOnUSBArrival write FOnUSBArrival;
    property OnDeviceRemove: TUsbNotifyProc read FOnUSBRemove write FOnUSBRemove;
  end;

implementation

uses
  entrypoint;

function TMsgServer.RegisterDevNotification: Boolean;
var
  dbi: DEV_BROADCAST_DEVICEINTERFACE;
  Size: Integer;
begin
  Result := False;
  try
    Size := SizeOf(DEV_BROADCAST_DEVICEINTERFACE);
    ZeroMemory(@dbi, Size);

    dbi.dbcc_size := Size;
    dbi.dbcc_devicetype := DBT_DEVTYP_DEVICEINTERFACE;
    dbi.dbcc_reserved := 0;
    dbi.dbcc_classguid := GUID_DEVINTERFACE_USB_DEVICE;
    dbi.dbcc_name := 0;

    NotifyHandle := RegisterDeviceNotification(handle, @dbi, DEVICE_NOTIFY_WINDOW_HANDLE);
  finally
  end;
  if Assigned(NotifyHandle) then
    Result := True;
end;

constructor TMsgServer.Create;
begin
  handle := AllocateHWnd(WndMethod);
  RegisterDevNotification;
  active := True;
end;

destructor TMsgServer.Free;
begin
  active := false;
  if Assigned(NotifyHandle) then
    UnregisterDeviceNotification(NotifyHandle);

  DeallocateHWnd(handle);
end;

procedure TMsgServer.WMDeviceChange(var Msg: TMessage);
var
//  devType: Integer;
  Datos: PDevBroadcastHdr;
begin
  if (Msg.wParam = DBT_DEVICEARRIVAL) or (Msg.wParam = DBT_DEVICEREMOVECOMPLETE) then
  begin
    Datos := PDevBroadcastHdr(Msg.lParam);
 //  devType := Datos^.dbch_devicetype;
 //   if devType = DBT_DEVTYP_DEVICEINTERFACE then
 //   begin
    if Msg.wParam = DBT_DEVICEARRIVAL then
    begin
      if Assigned(FOnUSBArrival) then
        FOnUSBArrival(Self);
    end
    else
    begin
      if Assigned(FOnUSBRemove) then
        FOnUSBRemove(Self);
    end;
 //   end;
  end;
end;

procedure TMsgServer.WndMethod(var Msg: TMessage);
begin
  Msg.Result := DefWindowProc(handle, Msg.Msg, Msg.wParam, Msg.lParam);
  if not active then
    exit;

  case Msg.msg of
    WM_HOTKEY:
      begin
        if assigned(OnHotkey) then
          OnHotkey(Msg.WParamLo);
      end;
    WM_COPYDATA:
      begin
        if Assigned(OnData) then
          OnData(TWMcopydata(Msg));
        exit;
      end;
    WM_DEVICECHANGE:
      begin
        WMDeviceChange(Msg);
        exit;
      end;
  end;

  if Assigned(OnMessage) then
    OnMessage(Msg);
end;

end.


