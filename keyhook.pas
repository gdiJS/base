// ----------------------------------------------------------------------------
//
// Keyhook Component version 1.0
// Copyright (c) NetworkLab All rights reserved

// Modified For Judith
// root@psychip.net - 2013
// ----------------------------------------------------------------------------

unit keyhook;

interface

uses
  Windows, Classes, Messages;

type
  TKeyHookAction = (khaUp, khaRepeat, khaDown);

  TKeyHookHandler = function: Boolean; stdcall;

  TKeyHookNotifyEvent = procedure(Sender: TObject; Action: TKeyHookAction; KeyName: string; keycode: integer) of object;

  // ----------------------------------------------------------------------------
  // TKeyHook
  // ----------------------------------------------------------------------------
  TKeyHook = class(TComponent)
  protected
    FDLLHandle: HMODULE;
    KeyHookOn: TKeyHookHandler;
    KeyHookOff: TKeyHookHandler;
    FMemFile: THandle;
    FReceiver: ^integer;
  protected
    FHandle: THandle;
    FOldProc: TFNWndProc;
    procedure ChangeProc;
    procedure RecoverProc;
  protected
    FActive: Boolean;
    FOnHook: TKeyHookNotifyEvent;
  public
    property Active: Boolean read FActive;
  published
    property OnHook: TKeyHookNotifyEvent read FOnHook write FOnHook;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Open(Handle: THandle; const libdir: string = 'keyboard.dll'): Boolean;
    function Close: Boolean;
  end;

implementation

const
  CM_SEND_KEY = WM_USER + $1000;

var
  g_KeyHook: TKeyHook = nil;

type
  Thookstruct = packed record
    vkCode: DWord;
    ScanCode: DWord;
    Flags: DWord;
    Time: DWord;
    dwExtraInfo: integer;
  end;

type
  tagKBDLLHOOKSTRUCT = packed record
    vkCode: DWord;
    ScanCode: DWord;
    Flags: DWord;
    Time: DWord;
    dwExtraInfo: integer;
  end;

  KBDLLHOOKSTRUCT = tagKBDLLHOOKSTRUCT;
  PKBDLLHOOKSTRUCT = ^KBDLLHOOKSTRUCT;

procedure gtrace(err: string);
begin
    // if Assigned(judith) then
    // judith.log('ERROR', err);
end;

function KeyboardProc(hwnd: hwnd; iMsg: UINT; wParam: wParam; lParam: lParam): LRESULT; stdcall;
var
  Action: TKeyHookAction;
  KeyName: array[0..100] of Char;
  Msg: TMessage;
begin
  case iMsg of
    CM_SEND_KEY:
      begin
        if g_KeyHook = nil then
        begin
          gtrace('[KeyHook.pas] KeyboardProc g_KeyHook = nil');
        end
        else
        begin
          if Assigned(g_KeyHook.FOnHook) then
          begin
            Msg.wParam := wParam;
            Msg.lParam := lParam;
            GetKeyNameText(lParam, @KeyName[0], 100);

            if ((lParam shr 31) and 1) = 1 then
              Action := khaUp
            else if ((lParam shr 30) and 1) = 1 then
              Action := khaRepeat
            else
              Action := khaDown;

            g_KeyHook.OnHook(g_KeyHook, Action, KeyName, TWMKey(Msg).CharCode);
          end;
        end;
        Result := 0;
        exit;
      end;

  end;
  Result := CallWindowProc(g_KeyHook.FOldProc, hwnd, iMsg, wParam, lParam);
end;

// ----------------------------------------------------------------------------
// TKeyHook
// ----------------------------------------------------------------------------
procedure TKeyHook.ChangeProc;
begin
  FOldProc := TFNWndProc(SetWindowLong(FHandle, GWL_WNDPROC, Longint(@KeyboardProc)));
  SetWindowLong(FHandle, GWL_USERDATA, Longint(FOldProc));
end;

procedure TKeyHook.RecoverProc;
begin
    // SetWindowLong(FHandle, GWL_WNDPROC, GetWindowLong(FControlHandle, GWL_USERDATA));
  SetWindowLong(FHandle, GWL_WNDPROC, Longint(FOldProc));
end;

constructor TKeyHook.Create(AOwner: TComponent);
begin
  inherited;
  FDLLHandle := HMODULE(0);
  KeyHookOn := nil;
  KeyHookOff := nil;
  FMemFile := THandle(0);
  FReceiver := nil;
  g_KeyHook := Self;
  FHandle := THandle(0);
  FOldProc := TFNWndProc(0);
  FActive := false;
end;

destructor TKeyHook.Destroy;
begin
  Close;
  g_KeyHook := nil;
  inherited;
end;

function TKeyHook.Open(Handle: THandle; const libdir: string = 'keyboard.dll'): Boolean;
label
  _error;
begin
  if FActive then
  begin
    gtrace('[KeyHook.pas] TKeyHook.Open already opened');
    goto _error;
  end;
  FHandle := Handle;
  FDLLHandle := LoadLibrary(PChar(libdir));
  if FDLLHandle = HMODULE(0) then
  begin
    gtrace('[KeyHook.pas] TKeyHook.Open LoadLibrafy fail');
    goto _error;
  end;
  @KeyHookOn := GetProcAddress(FDLLHandle, 'Open');
  if not Assigned(KeyHookOn) then
  begin
    gtrace('[KeyHook.pas] TKeyHook.Open  can not find KeyHookOn');
    goto _error;
  end;
  @KeyHookOff := GetProcAddress(FDLLHandle, 'Close');
  if not Assigned(KeyHookOff) then
  begin
    gtrace('[KeyHook.pas] TKeyHook.Open  can not find KeyHookOff');
    goto _error;
  end;

  FMemFile := CreateFileMapping($FFFFFFFF, nil, PAGE_READWRITE, 0, sizeof(integer), 'zgzReciever');
  if FMemFile = 0 then
  begin
    gtrace('[KeyHook.pas] TKeyHook.Open can not create file');
    goto _error;
  end;

  FReceiver := MapViewOfFile(FMemFile, FILE_MAP_WRITE, 0, 0, 0);

  FReceiver^ := FHandle;

  ChangeProc;

  if not KeyHookOn then
  begin
    gtrace('[KeyHook.pas] TKeyHook.Open KeyHookOn return false');
    RecoverProc;
    goto _error;
  end;

  FActive := true;
  Result := true;
  exit;
_error:
  Close;
  Result := false;
end;

function TKeyHook.Close: Boolean;
begin
  if not FActive then
  begin
    gtrace('[KeyHook.pas] TKeyHook.Close already closed');
    Result := false;
    exit;
  end;

  RecoverProc;

  if Assigned(KeyHookOff) then
    KeyHookOff;
  if FDLLHandle <> HMODULE(0) then
  begin
    FreeLibrary(FDLLHandle);
    FDLLHandle := HMODULE(0);
  end;

  KeyHookOn := nil;
  KeyHookOff := nil;

  if FMemFile <> 0 then
  begin
    UnmapViewOfFile(FReceiver);
    FReceiver := nil;
    CloseHandle(FMemFile);
    FMemFile := THandle(0);
  end;
  FActive := false;
  Result := true;
end;

end.

