unit mod_keyhook;

interface

uses
  Windows,
  math,
  SysUtils;

type
  Thotkey = packed record
    id : integer;
    code : integer;
    combination : string;
    key : char;
    keycode : integer;
  end;

function sethotkey(
  handle : HWND;
  entry  : Thotkey ) : boolean;

function shiftdown : boolean;

function caps : boolean;

implementation

function caps : boolean;
  begin
    Result := ( Odd( GetKeyState( VK_CAPITAL ) ) or
      ( GetKeyState( VK_SHIFT ) < 0 ) );
  end;

function shiftdown : boolean;
  var
    state : TKeyboardState;
  begin
    GetKeyboardState( state );
    Result := ( ( state[ VK_SHIFT ] and 128 ) <> 0 );
  end;

function sethotkey(
  handle : HWND;
  entry  : Thotkey ) : boolean;
  var
    code : integer;
    combination : string;
    kc : LongWord;
  begin
    Result := False;
    code := entry.code;
    combination := trim( entry.combination );

    if ( entry.keycode > 0 )
    then
    begin
      kc := ord( entry.keycode );
    end
    else
    begin
      kc := ord( entry.key );
    end;

    if combination = 'CTRL'
    then
    begin
      if RegisterHotkey( handle, code, MOD_CONTROL, kc )
      then
        Result := true
      else
        Result := False;
    end;

    if combination = 'ALT'
    then
    begin
      if RegisterHotkey( handle, code, MOD_ALT, kc )
      then
        Result := true
      else
        Result := False;
    end;

    if combination = 'SHIFT'
    then
    begin
      if RegisterHotkey( handle, code, MOD_SHIFT, kc )
      then
        Result := true
      else
        Result := False;
    end;

    if combination = 'WIN'
    then
    begin
      if RegisterHotkey( handle, code, MOD_WIN, kc )
      then
        Result := true
      else
        Result := False;
    end;

    if combination = 'CTRL+ALT'
    then
    begin
      if RegisterHotkey( handle, code, MOD_CONTROL or MOD_ALT, kc )
      then
        Result := true
      else
        Result := False;
    end;

    if combination = 'CTRL+SHIFT'
    then
    begin
      if RegisterHotkey( handle, code, MOD_CONTROL or MOD_SHIFT, kc )
      then
        Result := true
      else
        Result := False;
    end;

    if combination = 'ALT+SHIFT'
    then
    begin
      if RegisterHotkey( handle, code, MOD_ALT or MOD_SHIFT, kc )
      then
        Result := true
      else
        Result := False;
    end;

    if combination = 'WIN+SHIFT'
    then
    begin
      if RegisterHotkey( handle, code, MOD_WIN or MOD_SHIFT, kc )
      then
        Result := true
      else
        Result := False;
    end;

    if combination = 'WIN+CTRL'
    then
    begin
      if RegisterHotkey( handle, code, MOD_WIN or MOD_CONTROL, kc )
      then
        Result := true
      else
        Result := False;
    end;

    if combination = 'SHIFT+ALT'
    then
    begin
      if RegisterHotkey( handle, code, MOD_SHIFT or MOD_ALT, kc )
      then
        Result := true
      else
        Result := False;
    end;

  end;

end.
