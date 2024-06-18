unit JSNatives;

interface

uses
  System.Generics.Collections, jsonEx, sysutils, classes, v8, System.strutils,
  wmipc, messages, XSuperObject, XSuperJSON, windows, gfxcore, udputils, jstts,
  activex, Winapi.ShellAPI, console, vcl.Dialogs, utils, jsdownloader;

var
  VM: Pv8Engine;
  winh: THandle;
  hotkeys: TDictionary<word, string>;
  keys: TDictionary<word, string>;
  keyhook: array of string;

var
  CriticalSection: TRTLCriticalSection;

const
  MONITOR_ON = -1;
  MONITOR_OFF = 2;
  MONITOR_STANDBY = 1;

type
  TLockWorkStation = function: Boolean;

  TExtproc = procedure(handle: dword);

  Textension = record
    handle: THandle;
    proc: TExtproc;
    path: string;
  end;

var
  hUser32: HModule;
  LockWorkStation: TLockWorkStation;

procedure _unixtime(_info: V8FunctionCallbackInfo); cdecl;

procedure _millis(_info: V8FunctionCallbackInfo); cdecl;

procedure _LoadExtension(_info: V8FunctionCallbackInfo); cdecl;

procedure LoadJson(_info: V8FunctionCallbackInfo) cdecl;

procedure __DebugStr(str: ansistring; engine: Pv8Engine);

// sapi

procedure _TTSSpeak(_info: V8FunctionCallbackInfo); cdecl;

// filesystem

procedure _md5file(_info: V8FunctionCallbackInfo); cdecl;

procedure _fileDelete(_info: V8FunctionCallbackInfo); cdecl;

procedure _fileRename(_info: V8FunctionCallbackInfo); cdecl;

procedure _fileExists(_info: V8FunctionCallbackInfo); cdecl;

procedure _dirCreate(_info: V8FunctionCallbackInfo); cdecl;

procedure _filewrite(_info: V8FunctionCallbackInfo); cdecl;

procedure _fileAppend(_info: V8FunctionCallbackInfo); cdecl;

procedure _readfile(_info: V8FunctionCallbackInfo); cdecl;

procedure _browse(_info: V8FunctionCallbackInfo); cdecl;

procedure _runfile(_info: V8FunctionCallbackInfo); cdecl;

// timers
procedure _setTimeout(_info: V8FunctionCallbackInfo); cdecl;

procedure _setInterval(_info: V8FunctionCallbackInfo); cdecl;

procedure _clearInterval(_info: V8FunctionCallbackInfo); cdecl;

procedure _clearTimeout(_info: V8FunctionCallbackInfo); cdecl;

// http
procedure _httpget(_info: V8FunctionCallbackInfo); cdecl;

procedure _httpPost(_info: V8FunctionCallbackInfo); cdecl;

procedure _httpDownload(_info: V8FunctionCallbackInfo); cdecl;


// sec
procedure _md5(_info: V8FunctionCallbackInfo); cdecl;

procedure _crc32(_info: V8FunctionCallbackInfo); cdecl;

procedure _sha1(_info: V8FunctionCallbackInfo); cdecl;

// database

procedure _dbquery(_info: V8FunctionCallbackInfo); cdecl;

procedure _dbqueryEx(_info: V8FunctionCallbackInfo); cdecl;

procedure _dbopen(_info: V8FunctionCallbackInfo); cdecl;

procedure _dbclose(_info: V8FunctionCallbackInfo); cdecl;

procedure _dbexec(_info: V8FunctionCallbackInfo); cdecl;

// serial
procedure _portopen(_info: V8FunctionCallbackInfo); cdecl;

procedure _portclose(_info: V8FunctionCallbackInfo); cdecl;

procedure _portwrite(_info: V8FunctionCallbackInfo); cdecl;

procedure _portread(_info: V8FunctionCallbackInfo); cdecl;

procedure _portenum(_info: V8FunctionCallbackInfo); cdecl;

procedure _portavailable(_info: V8FunctionCallbackInfo); cdecl;

// Proc
procedure _proccreate(_info: V8FunctionCallbackInfo); cdecl;

procedure _procPipe(_info: V8FunctionCallbackInfo); cdecl;

procedure _procPing(_info: V8FunctionCallbackInfo); cdecl;

procedure _procRelease(_info: V8FunctionCallbackInfo); cdecl;

procedure _procInfo(_info: V8FunctionCallbackInfo); cdecl;

procedure _procList(_info: V8FunctionCallbackInfo); cdecl;

// HW
procedure _hwlist(_info: V8FunctionCallbackInfo); cdecl;

procedure _wlscan(_info: V8FunctionCallbackInfo); cdecl;

// disk

procedure _disklist(_info: V8FunctionCallbackInfo); cdecl;

// VM
procedure _release(_info: V8FunctionCallbackInfo); cdecl;

procedure _GetWinMsg(_info: V8FunctionCallbackInfo); cdecl;

procedure _GetDevMsg(_info: V8FunctionCallbackInfo); cdecl;

procedure _SetWinMsg(data: ansistring; engine: Pv8Engine);

procedure _SetDevMsg(arrival: Boolean; engine: Pv8Engine);

// natives

procedure _include(_info: V8FunctionCallbackInfo); cdecl;

procedure console_log(_info: V8FunctionCallbackInfo); cdecl;

procedure _alert(_info: V8FunctionCallbackInfo); cdecl;

procedure _confirm(_info: V8FunctionCallbackInfo); cdecl;

procedure _gettickcount(_info: V8FunctionCallbackInfo); cdecl;

procedure _ram(_info: V8FunctionCallbackInfo); cdecl;

procedure JSterminate;

// user routines

procedure _NotifyHotkey(code: integer; engine: Pv8Engine);

procedure _Notifykey(code: integer; engine: Pv8Engine);

procedure _Notifykeys(code: integer; caps: string; engine: Pv8Engine);

procedure _SetHotkey(_info: V8FunctionCallbackInfo); cdecl;

procedure _SetKey(_info: V8FunctionCallbackInfo); cdecl;

procedure _SetKeys(_info: V8FunctionCallbackInfo); cdecl;

procedure _unSetKeys(_info: V8FunctionCallbackInfo); cdecl;

procedure _GetIdle(_info: V8FunctionCallbackInfo); cdecl;

procedure _GetUserName(_info: V8FunctionCallbackInfo); cdecl;

procedure _SendKeys(_info: V8FunctionCallbackInfo); cdecl;

procedure _ScreenShot(_info: V8FunctionCallbackInfo); cdecl;

procedure _GetResolution(_info: V8FunctionCallbackInfo); cdecl;

procedure _ToggleMonitor(_info: V8FunctionCallbackInfo); cdecl;

procedure _Shutdown(_info: V8FunctionCallbackInfo); cdecl;

procedure _Execute(_info: V8FunctionCallbackInfo); cdecl;

procedure _Lock(_info: V8FunctionCallbackInfo); cdecl;
// tcp

procedure _tcplisten(_info: V8FunctionCallbackInfo); cdecl;

procedure _tcpclose(_info: V8FunctionCallbackInfo); cdecl;

procedure _tcpkick(_info: V8FunctionCallbackInfo); cdecl;

procedure _tcpwrite(_info: V8FunctionCallbackInfo); cdecl;

procedure _udpSend(_info: V8FunctionCallbackInfo); cdecl;

procedure _udpListen(_info: V8FunctionCallbackInfo); cdecl;

procedure _udpkill(_info: V8FunctionCallbackInfo); cdecl;
//

procedure _RegEDebug(_info: V8FunctionCallbackInfo); cdecl;

procedure _RegDebug(_info: V8FunctionCallbackInfo); cdecl;

procedure _DebugStr(str: ansistring; engine: Pv8Engine);

procedure _Halt(_info: V8FunctionCallbackInfo); cdecl;

procedure _WriteDebug(_info: V8FunctionCallbackInfo); cdecl;

/// audio

procedure _audstart(_info: V8FunctionCallbackInfo); cdecl;

procedure _audstop(_info: V8FunctionCallbackInfo); cdecl;

procedure _audload(_info: V8FunctionCallbackInfo); cdecl;

procedure _audplay(_info: V8FunctionCallbackInfo); cdecl;

procedure _audspeech(_info: V8FunctionCallbackInfo); cdecl;

procedure _audstream(_info: V8FunctionCallbackInfo); cdecl;

procedure _RegAudio(_info: V8FunctionCallbackInfo); cdecl;

procedure _Audstate(state: integer; engine: Pv8Engine);

///

procedure _findwindow(_info: V8FunctionCallbackInfo); cdecl;

procedure _sendstring(_info: V8FunctionCallbackInfo); cdecl;

procedure _GetCurrentApp(_info: V8FunctionCallbackInfo); cdecl;

procedure _GetCurrentWin(_info: V8FunctionCallbackInfo); cdecl;

procedure _IsFullscreen(_info: V8FunctionCallbackInfo); cdecl;

/// /////
procedure _RegOsEvent(_info: V8FunctionCallbackInfo); cdecl;

procedure _OsEvent(event: integer; engine: Pv8Engine);

procedure _RegMessage(_info: V8FunctionCallbackInfo); cdecl;

procedure _ipcMessage(msg: ansistring; engine: Pv8Engine);

/// //////////

procedure _RegFchange(_info: V8FunctionCallbackInfo); cdecl;

procedure _fchange(str: ansistring; engine: Pv8Engine);

////////////////

procedure _stop(_info: V8FunctionCallbackInfo); cdecl;

implementation

uses
  JSfilesystem, JSajax, jsproc, JSCrypt, libserial, jsdb, setupapihelper,
  JsTimers, jshwinfo, mod_keyhook, sndkey32tr, stringtools, psyapi, jstcp,
  jsaudio, mod_disk, entrypoint;

var
  _start: int64;
  __killswitch: Boolean;
  relbuf: array of string;
  msgbuf: array of string;
  devbuf: array of string;
  dbgbuf: array of string;
  audbuf: array of string;
  cmdbuf: array of string;
  evtbuf: array of string;
  debuf: array of string;
  febuf: array of string;
  extensions: array of Textension;
  ihttp, ipost, itts, ipipe: Int64;

function toJson(str: string): string;
var
  X: ISuperObject;
begin
  X := SO;
  X.S['msg'] := trim(str);
  result := X.AsJSON();
end;

function cleanStr(str: ansistring): ansistring;
begin
  if copy(str, 1, 1) = #27 then
    delete(str, 1, 1);

  if copy(str, Length(str), 1) = #27 then
    delete(str, Length(str), 1);

  if copy(str, Length(str) - 1, 1) = #27 then
    delete(str, Length(str), 1);

  str := AnsiReplaceStr(str, #27, '');
  str := AnsiReplaceStr(str, #13, '');
  str := AnsiReplaceStr(str, #10, '');

  str := quotedstr(str);
  result := str;
end;

function geneid(const pfx: string = ''): string;
begin
  Randomize;
  result := '_' + pfx + inttostr(gettickcount64) + inttostr(random(99999));
end;

procedure _stop(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  //TerminateProcess(getcurrentprocess(), 0);
  v8_FunctionCallbackInfo_return_uint32(_info, 1);
  judith.free;
end;

procedure _Audstate(state: integer; engine: Pv8Engine);
var
  i: integer;
begin
  if __killswitch then
    exit;
  begin
    if (Length(audbuf) > 0) then
    begin
      for i := Low(audbuf) to High(audbuf) do
      begin
        engine.eval(audbuf[i] + '(' + inttostr(state) + ');');
      end;
    end;
  end;
end;

procedure __DebugStr(str: ansistring; engine: Pv8Engine);
var
  i: integer;
    // code: string;
begin
  if __killswitch then
    exit;
  begin
    if (Length(debuf) > 0) then
    begin
        // code := QuotedStr(StringReplace(str, #13#10, ' ', [rfReplaceAll]));
      for i := Low(debuf) to High(debuf) do
      begin
        engine.eval(debuf[i] + '(' + toJson(str) + ');');
      end;
    end;
  end;
end;

procedure _fchange(str: ansistring; engine: Pv8Engine);
var
  i: integer;
begin
  if __killswitch then
    exit;
  begin
    if (Length(febuf) > 0) then
    begin
      for i := Low(febuf) to High(febuf) do
      begin
        engine.eval(febuf[i] + '(' + quotedstr(makePath(str)) + ');');
      end;
    end;
  end;
end;

procedure _OsEvent(event: integer; engine: Pv8Engine);
var
  i: integer;
begin
  if __killswitch then
    exit;
  begin
    if (Length(evtbuf) > 0) then
    begin
      for i := Low(evtbuf) to High(evtbuf) do
      begin
        engine.eval(evtbuf[i] + '(' + inttostr(event) + ');');
      end;
    end;
  end;
end;

procedure _ipcMessage(msg: ansistring; engine: Pv8Engine);
var
  i: integer;
begin
  if __killswitch then
    exit;
  begin
    if copy(msg, 1, 5) = 'eval=' then
    begin
      engine.eval(copy(msg, 6, lstrlenA(PAnsiChar(msg)) - 5));
      exit;
    end;

    if (Length(cmdbuf) > 0) then
    begin
      for i := Low(cmdbuf) to High(cmdbuf) do
      begin
        engine.eval(cmdbuf[i] + '(' + (cleanStr(msg)) + ');');
      end;
    end;
  end;
end;

procedure _TTScreate(_info: V8FunctionCallbackInfo); cdecl;
var
  id: pwidechar;
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  v8_FunctionCallbackInfo_return_string(_info, id);
end;

procedure _TTSFree(_info: V8FunctionCallbackInfo); cdecl;
var
  id: pwidechar;
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  v8_FunctionCallbackInfo_return_string(_info, id);
end;

procedure _TTSSpeak(_info: V8FunctionCallbackInfo); cdecl;
var
  id: string;
  info: Tv8FunctionCallbackInfo;
  v: string;
  text, speaker, path: string;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 1 then
  begin
    Inc(itts);
    v := info.args[2].AsString;
    v := fixpath(v);
    id := ('_$tts' + inttostr(itts));
    VM.GlobalObject.SetObject(id, info.args[3].AsObject);
    text := (info.args[0].AsString);
    speaker := (info.args[1].AsString);
    path := (info.args[2].AsString);
    jstts.renderText(ahandle, text, speaker, path, id);
    v8_FunctionCallbackInfo_return_string(_info, pwidechar(id));
  end;
end;

procedure _TTSSpeakFast(_info: V8FunctionCallbackInfo); cdecl;
var
  id: string;
  info: Tv8FunctionCallbackInfo;
  v: string;
  text, speaker, path: string;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 1 then
  begin
    Inc(itts);
    v := info.args[2].AsString;
    v := fixpath(v);
    id := ('_$ttsf' + inttostr(itts));
    VM.GlobalObject.SetObject(id, info.args[3].AsObject);
    text := (info.args[0].AsString);
    speaker := (info.args[1].AsString);
    path := (info.args[2].AsString);
    jstts.renderText(ahandle, text, speaker, path, id);
    v8_FunctionCallbackInfo_return_string(_info, pwidechar(id));
  end;
end;

procedure _audstart(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    v8_FunctionCallbackInfo_return_int32(_info, jsaudio.audio_init(info.args[0].AsInteger));
  end;
end;

procedure _audstop(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    v8_FunctionCallbackInfo_return_int32(_info, jsaudio.audio_close(info.args[0].AsInteger));
  end;
end;

procedure _audload(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 1 then
  begin
    v8_FunctionCallbackInfo_return_int32(_info, jsaudio.audio_loadsample(info.args[0].AsInteger, fixpath(info.args[1].AsString), (info.args[2].AsString)));
  end;
end;

procedure _audspeech(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 1 then
  begin
    v8_FunctionCallbackInfo_return_int32(_info, jsaudio.audio_speech(info.args[0].AsInteger, fixpath(info.args[1].AsString)));
  end;
end;

procedure _audstream(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 1 then
  begin
    v8_FunctionCallbackInfo_return_int32(_info, jsaudio.audio_stream(info.args[0].AsInteger, fixpath(info.args[1].AsString)));
  end;
end;

procedure _audplay(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 1 then
  begin
    v8_FunctionCallbackInfo_return_int32(_info, jsaudio.audio_playsample(info.args[0].AsInteger, info.args[1].AsString));
  end;
end;

/// ///////////////////////////

procedure _tcplisten(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 1 then
  begin
    eid := geneid;
    VM.GlobalObject.SetObject(eid, info.args[1].AsObject);
    v8_FunctionCallbackInfo_return_int32(_info, jstcp.listen(info.args[0].AsInteger, eid, VM));
  end;
end;

procedure _tcpclose(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    v8_FunctionCallbackInfo_return_int32(_info, jstcp.close(info.args[0].AsInteger));
  end;
end;

procedure _tcpkick(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  r: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 1 then
  begin
    try
      r := jstcp.kick(info.args[0].AsInteger, info.args[1].AsInteger);
      v8_FunctionCallbackInfo_return_int32(_info, r);
    except
      on e: exception do
      begin
        v8_FunctionCallbackInfo_return_int32(_info, 0);
      end;
    end;

  end;
end;

procedure _tcpwrite(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  J: TjsonEx;
  w: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    try
      J := TjsonEx.Create;
      J.Parse(info.args[0].AsString);
      w := jstcp.write(J['id'].AsInteger, J['sock'].AsInteger, J['data'].AsString);
      v8_FunctionCallbackInfo_return_int32(_info, w);
      J.Free;
    except
      on e: exception do
      begin
        v8_FunctionCallbackInfo_return_int32(_info, 0);
      end;
    end;

  end;
end;

procedure _disklist(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  try
    v8_FunctionCallbackInfo_return_string(_info, pchar(DisksAsJson(disklistobj)));
  except
    on e: exception do
    begin
      v8_FunctionCallbackInfo_return_int32(_info, -1);
    end;
  end;
end;

procedure _hwlist(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  try
    v8_FunctionCallbackInfo_return_string(_info, pchar(DevicesAsJson(listdevices)));
  except
    on e: exception do
    begin
      v8_FunctionCallbackInfo_return_int32(_info, -1);
    end;
  end;
end;

procedure _wlscan(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  try
      // v8_FunctionCallbackInfo_return_string(_info, PChar(wScan()));
  except
    on e: exception do
    begin
      v8_FunctionCallbackInfo_return_int32(_info, -1);
    end;
  end;
end;

procedure _procPipe(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  X: ISuperObject;
  id: string;
  app: string;
  path: string;
  cmd: string;
  param: string;
  obj: Iv8Object;
  T: TThread;
  cd: string;
  start: int64;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    cd := extractfilepath(paramstr(0));
    Inc(ipipe);
    id := '_$pipe' + inttostr(ipipe);
    obj := info.args[0].AsObject;

    app := fixpath(obj.GetStr('app'));
    param := obj.getstr('param');
    if param = 'undefined' then
      param := '';

    path := fixpath(obj.GetStr('path'));
    cmd := obj.GetStr('cmd');

    if (FileExists(app)) and (pos(':', app) < 1) then
      app := cd + app;

    if (path = 'undefined') or (path = '') then
    begin
      if pos('\', app) > 0 then
      begin
        path := extractfilepath(app);
      end
      else
        path := cd;
    end;

    if not FileExists(app) then
      app := cd + app;

    VM.GlobalObject.SetObject(id, info.args[1].AsObject);
    start := gettickcount;
    T := TThread.CreateAnonymousThread(
      procedure
      begin
        try
          X := SO;
          EnterCriticalSection(CriticalSection);
          outputdebugstring(pchar(app + ' ' + param));
          if (cmd <> 'undefined') and (cmd <> '') then
            X.S['data'] := GetOutputStdIn(app + ' ' + param, cmd, path)
          else
            X.S['data'] := GetDosOutput(app + ' ' + param, path);
          X.I['took'] := gettickcount - start;
          LeaveCriticalSection(CriticalSection);
        finally
          Sleep(1);
          wm_sendstringex(ahandle, ahandle, pwidechar('~eval=' + id + '(' + X.AsJSON() + ');' + id + '=undefined;'));
          Sleep(1000);
        end;
      end);
    T.FreeOnTerminate := true;
    T.Start;
    v8_FunctionCallbackInfo_return_string(_info, pwidechar(id));
  end;
end;

procedure _proccreate(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  p: Tprocmeta;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 2 then
  begin
    try
      p := RunProcess(pchar(fixpath(info.args[0].AsString)), pchar(info.args[1].AsString), Boolean(info.args[2].AsInteger));
      v8_FunctionCallbackInfo_return_string(_info, pchar(ProcmetaAsJson(p)));
    except
      on e: exception do
      begin
        v8_FunctionCallbackInfo_return_int32(_info, -1);
      end;
    end;
  end;
end;

procedure _procRelease(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    try
      v8_FunctionCallbackInfo_return_int32(_info, releaseProcess(info.args[0].AsInteger));
    except
      on e: exception do
      begin
        v8_FunctionCallbackInfo_return_int32(_info, -1);
      end;
    end;
  end;
end;

procedure _procPing(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    try
      v8_FunctionCallbackInfo_return_int32(_info, integer(pingProcess(info.args[0].AsInteger)));
    except
      on e: exception do
      begin
        v8_FunctionCallbackInfo_return_int32(_info, -1);
      end;
    end;
  end;
end;

procedure _procList(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  v8_FunctionCallbackInfo_return_string(_info, pwidechar(EnumProc));
end;

procedure _findwindow(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
    // id: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    try
      v8_FunctionCallbackInfo_return_uint32(_info, FindWindow(nil, pchar(info.args[0].AsString)));
    except
      on e: exception do
      begin
        v8_FunctionCallbackInfo_return_int32(_info, 0);
      end;
    end;
  end;
end;

procedure _sendstring(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
    // id: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    try
      wm_sendstringex(winh, info.args[0].AsInteger, pwidechar(info.args[1].AsString));
      v8_FunctionCallbackInfo_return_int32(_info, 1);
    except
      on e: exception do
      begin
        v8_FunctionCallbackInfo_return_int32(_info, 0);
      end;
    end;
  end;
end;

procedure _SetWinMsg(data: ansistring; engine: Pv8Engine);
var
  i: integer;
begin
  if __killswitch then
    exit;

  if (Length(msgbuf) > 0) then
  begin
    for i := Low(msgbuf) to High(msgbuf) do
    begin
      engine.eval(msgbuf[i] + '(' + (cleanStr(data)) + ');');
    end;
  end;
end;

procedure _SetDevMsg(arrival: Boolean; engine: Pv8Engine);
var
  i: integer;
begin
  if __killswitch then
    exit;

  if (Length(devbuf) > 0) then
  begin
    for i := Low(devbuf) to High(devbuf) do
    begin
      engine.eval(devbuf[i] + '(' + inttostr(integer(arrival)) + ');');
    end;
  end;
end;

procedure _NotifyHotkey(code: integer; engine: Pv8Engine);
var
  cb: string;
begin
  if __killswitch then
    exit;
  begin
    if hotkeys.TryGetValue(code, cb) then
      engine.eval(cb + '(' + inttostr(code) + ');');
  end;
end;

procedure _procInfo(_info: V8FunctionCallbackInfo); cdecl;
var
    // i: integer;
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  v8_FunctionCallbackInfo_return_string(_info, pwidechar(ReplaceStr(paramstr(0), '\', '/')));
end;

procedure _LoadExtension(_info: V8FunctionCallbackInfo); cdecl;
var
  i: integer;
  path: string;
  fname: string;
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);

  if info.ArgCount > 0 then
  begin
    path := fixpath(info.args[0].AsString);
    fname := info.args[1].AsString;
    if not fileexists(path) then
    begin
      path := Extractfilepath(ParamStr(0)) + '\' + path;
      if not fileexists(path) then
      begin
        v8_FunctionCallbackInfo_return_string(_info, pwidechar('file_not_found'));
        exit;
      end;
    end;

    i := Length(extensions);
    SetLength(extensions, i + 1);
    extensions[i].handle := LoadLibrary(pchar(path));

    if extensions[i].handle <> 0 then
    begin
      @extensions[i].proc := GetProcAddress(extensions[i].handle, pwidechar(fname));
      if Assigned(@extensions[i].proc) then
      begin
        extensions[i].proc(ahandle);
        v8_FunctionCallbackInfo_return_string(_info, pwidechar('ok'));
      end
      else
        v8_FunctionCallbackInfo_return_string(_info, pwidechar('getprocaddress_fail'));
    end
    else
    begin
      v8_FunctionCallbackInfo_return_string(_info, pwidechar('loadlibrary_fail'));
      FreeLibrary(extensions[i].handle);
    end;
  end;
end;

procedure _Halt(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  TerminateProcess(getcurrentprocess(), 0);
  v8_FunctionCallbackInfo_return_uint32(_info, 1);
end;

procedure _WriteDebug(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  OutputDebugString(pchar(info.args[0].AsString));
  v8_FunctionCallbackInfo_return_uint32(_info, 1);
end;

procedure _DebugStr(str: ansistring; engine: Pv8Engine);
var
  i: integer;
begin
  if __killswitch then
    exit;
  begin

    if (Length(dbgbuf) > 0) then
    begin
      for i := Low(dbgbuf) to High(dbgbuf) do
      begin
          // engine.eval(dbgbuf[i] + '(' + (TNetEncoding.Base64.encode(str)) + ');');
        //engine.eval(dbgbuf[i] + '(' + (toJson(str)) + ');');
      end;
    end;
  end;
end;

procedure _Notifykeys(code: integer; caps: string; engine: Pv8Engine);
var
  i: integer;
begin
  if __killswitch then
    exit;
  begin
    if (Length(keyhook) > 0) then
    begin
      for i := Low(keyhook) to High(keyhook) do
      begin
        if keyhook[i] <> '' then
          engine.eval(keyhook[i] + '(' + inttostr(code) + ',' + (caps) + ');');
      end;
    end;
  end;
end;

procedure _Notifykey(code: integer; engine: Pv8Engine);
var
  cb: string;
begin
  if __killswitch then
    exit;
  begin
    if keys.TryGetValue(code, cb) then
      engine.eval(cb + '(' + inttostr(code) + ');');
  end;
end;

procedure _GetCurrentApp(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  try
    v8_FunctionCallbackInfo_return_string(_info, pwidechar(WinmetaAsJson(getWinmeta(GetForegroundWindow))));
  except
    on e: exception do
    begin
      v8_FunctionCallbackInfo_return_string(_info, '{result:err}');
    end;
  end;
end;

procedure _GetCurrentWin(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  try
    v8_FunctionCallbackInfo_return_uint32(_info, GetForegroundWindow);
  except
    on e: exception do
    begin
      v8_FunctionCallbackInfo_return_uint32(_info, 0);
    end;
  end;
end;

procedure _IsFullscreen(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  try
    v8_FunctionCallbackInfo_return_uint32(_info, integer(isfullscreen(info.args[0].AsUInt32)));
  except
    on e: exception do
    begin
      v8_FunctionCallbackInfo_return_uint32(_info, 0);
    end;
  end;
end;

procedure _Lock(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  LockWorkStation;
end;

procedure _ToggleMonitor(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  state: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount <= 0 then
    exit;

  state := info.args[0].AsInteger;
  if state = 1 then
  begin
    postmessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, MONITOR_ON);
    sendkeys('{ESC}{ESCAPE}', true);
  end
  else
  begin
    postmessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, MONITOR_OFF);
  end;
end;

procedure _Execute(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  path: string;
  dir: string;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount <= 0 then
  begin
    v8_FunctionCallbackInfo_return_uint32(_info, 1);
    exit;
  end;
  path := info.args[0].AsString;

  if path <> '' then
  begin
    path := fixpath(path);

    if not FileExists(path, true) then
    begin
      v8_FunctionCallbackInfo_return_uint32(_info, 3);
      exit;
    end;

    if Pos(':', path) = 0 then
    begin
      dir := ExtractFilePath(ParamStr(0));
    end
    else
      dir := Extractfilepath(path);

    v8_FunctionCallbackInfo_return_uint32(_info, 4);
    ShellExecute(GetForegroundWindow(), 'open', PChar(path), nil, PChar(dir), SW_NORMAL);
  end
  else
  begin
    v8_FunctionCallbackInfo_return_uint32(_info, 2);
  end;
end;

procedure _Shutdown(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  state: integer;
  cmd: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount <= 0 then
    exit;

  cmd := 0;
  state := info.args[0].AsInteger;
  case state of
    1:
      cmd := EWX_SHUTDOWN;
    2:
      cmd := EWX_REBOOT;
    3:
      cmd := EWX_LOGOFF;
  end;

  if cmd > 0 then
  begin
     // trigger an application data save sequence in here
    ExitWindowsEx(EWX_FORCE and cmd, 0);
  end;

end;

procedure _ScreenShot(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    try
      SaveScr(100, info.args[0].AsString);
      v8_FunctionCallbackInfo_return_int32(_info, 1);
    except
      on e: exception do
      begin
        v8_FunctionCallbackInfo_return_int32(_info, 0);
      end;
    end;
  end;
end;

procedure _GetResolution(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  v8_FunctionCallbackInfo_return_string(_info, pchar(inttostr(GetSystemMetrics(SM_CXSCREEN)) + 'x' + inttostr(GetSystemMetrics(SM_CYSCREEN))));
end;

procedure _SendKeys(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    sendkeys(pchar(info.args[0].AsString), true);
    v8_FunctionCallbackInfo_return_int32(_info, 1);
  end;
end;

procedure _SetKeys(_info: V8FunctionCallbackInfo); cdecl;
var
  eid: string;
  i: integer;
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    eid := geneid;
    i := Length(keyhook);
    SetLength(keyhook, i + 1);
    keyhook[i] := eid;
    VM.GlobalObject.SetObject(eid, info.args[0].AsObject);
    v8_FunctionCallbackInfo_return_string(_info, pwidechar(eid));
  end
end;

procedure _unSetKeys(_info: V8FunctionCallbackInfo); cdecl;
var
  i: integer;
  id: string;
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    id := info.args[0].AsString;
    for i := Low(keyhook) to High(keyhook) do
    begin
      if keyhook[i] = id then
      begin
        keyhook[i] := '';
        v8_FunctionCallbackInfo_return_int32(_info, 1);
        exit;
      end;
    end;
  end;
  v8_FunctionCallbackInfo_return_int32(_info, 0);
end;

procedure _SetKey(_info: V8FunctionCallbackInfo); cdecl;
var
  eid: string;
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    eid := geneid;
    keys.Add(info.args[0].AsInteger, eid);
    VM.GlobalObject.SetObject(eid, info.args[1].AsObject);
    v8_FunctionCallbackInfo_return_int32(_info, 1);
  end
  else
    v8_FunctionCallbackInfo_return_int32(_info, 0);
end;

procedure _SetHotkey(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
  hk: Thotkey;
    // rnd: integer;
  X: string;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 2 then
  begin
    Randomize;
    hk.keycode := 0;
    hk.code := info.args[0].AsInteger;
    hk.combination := info.args[1].AsString;
    X := info.args[2].AsString;
    if Length(X) > 2 then
    begin
      hk.keycode := StrToInt(trim(stringtools.ParseBracket(X, '{', '}')));
    end
    else
      hk.key := X[1];

    if mod_keyhook.sethotkey(winh, hk) then
    begin
      eid := geneid;
      hotkeys.Add(hk.code, eid);
      VM.GlobalObject.SetObject(eid, info.args[3].AsObject);
      v8_FunctionCallbackInfo_return_int32(_info, 1);
    end
    else
      v8_FunctionCallbackInfo_return_int32(_info, 0);
  end;
end;

procedure _GetUserName(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  v8_FunctionCallbackInfo_return_string(_info, pwidechar(psyapi.GetUserName));
end;

procedure _GetIdle(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  liinfo: TLastInputInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  liinfo.cbSize := SizeOf(TLastInputInfo);
  GetLastInputInfo(liinfo);
  v8_FunctionCallbackInfo_return_uint32(_info, (gettickcount - liinfo.dwTime) div 1000);
end;

procedure _RegOsEvent(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
  i: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    Randomize;
    eid := geneid('OS');
    i := Length(evtbuf);
    SetLength(evtbuf, i + 1);
    evtbuf[i] := eid;
    VM.GlobalObject.SetObject(eid, info.args[0].AsObject);
    v8_FunctionCallbackInfo_return_string(_info, pchar(eid));
  end;
end;

procedure _RegMessage(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
  i: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    Randomize;
    eid := geneid('CMD');
    i := Length(cmdbuf);
    SetLength(cmdbuf, i + 1);
    cmdbuf[i] := eid;
    VM.GlobalObject.SetObject(eid, info.args[0].AsObject);
    v8_FunctionCallbackInfo_return_string(_info, pchar(eid));
  end;
end;

procedure _RegAudio(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
  i: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    Randomize;
    eid := geneid('aud');
    i := Length(audbuf);
    SetLength(audbuf, i + 1);
    audbuf[i] := eid;
    VM.GlobalObject.SetObject(eid, info.args[0].AsObject);
    v8_FunctionCallbackInfo_return_string(_info, pchar(eid));
  end;
end;

procedure _RegDebug(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
  i: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    Randomize;
    eid := geneid('DBG');
    i := Length(dbgbuf);
    SetLength(dbgbuf, i + 1);
    dbgbuf[i] := eid;
    VM.GlobalObject.SetObject(eid, info.args[0].AsObject);
    v8_FunctionCallbackInfo_return_string(_info, pchar(eid));
  end;
end;

procedure _RegFchange(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
  i: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    Randomize;
    eid := geneid('fc');
    i := Length(febuf);
    SetLength(febuf, i + 1);
    febuf[i] := eid;
    VM.GlobalObject.SetObject(eid, info.args[0].AsObject);
    v8_FunctionCallbackInfo_return_string(_info, pchar(eid));
  end;
end;

procedure _RegEDebug(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
  i: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    Randomize;
    eid := geneid('dbg');
    i := Length(debuf);
    SetLength(debuf, i + 1);
    debuf[i] := eid;
    VM.GlobalObject.SetObject(eid, info.args[0].AsObject);
    v8_FunctionCallbackInfo_return_string(_info, pchar(eid));
  end;
end;

procedure _GetDevMsg(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
  i: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    Randomize;
    eid := geneid('dmsg');
    i := Length(devbuf);
    SetLength(devbuf, i + 1);
    devbuf[i] := eid;
    VM.GlobalObject.SetObject(eid, info.args[0].AsObject);
    v8_FunctionCallbackInfo_return_string(_info, pchar(eid));
  end;
end;

procedure _GetWinMsg(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
  i: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    Randomize;
    eid := geneid('wmsg');
    i := Length(msgbuf);
    SetLength(msgbuf, i + 1);
    msgbuf[i] := eid;
    VM.GlobalObject.SetObject(eid, info.args[0].AsObject);
    v8_FunctionCallbackInfo_return_string(_info, pchar(eid));
  end;
end;

procedure _release(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
  i: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    Randomize;
    eid := geneid('rel');
    i := Length(relbuf);
    SetLength(relbuf, i + 1);
    relbuf[i] := eid;
    VM.GlobalObject.SetObject(eid, info.args[0].AsObject);
    v8_FunctionCallbackInfo_return_string(_info, pchar(eid));
  end;
end;

procedure _portopen(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  id: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    try
      id := OpenCOM(pchar(info.args[0].AsString + ':' + info.args[1].AsString + ',N,8,1'));
      if id > -1 then
        BufferSize(id, 1024);
      v8_FunctionCallbackInfo_return_int32(_info, id);
    except
      on e: exception do
      begin
        v8_FunctionCallbackInfo_return_int32(_info, -1);
      end;
    end;
  end;
end;

procedure _portclose(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  id: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    try
      id := info.args[0].AsInteger;
      CLEARBUFFER(id);
      CloseCOM(id);
      v8_FunctionCallbackInfo_return_int32(_info, 1);
    except
      on e: exception do
      begin
        v8_FunctionCallbackInfo_return_int32(_info, 0);
      end;
    end;
  end;
end;

procedure _portwrite(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  id: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    try
      id := info.args[0].AsInteger;
      SendString(id, pchar(info.args[1].AsString));
      v8_FunctionCallbackInfo_return_int32(_info, 1);
    except
      on e: exception do
      begin
        v8_FunctionCallbackInfo_return_int32(_info, 0);
      end;
    end;
  end;
end;

procedure _portavailable(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  buf: widestring;
  id: integer;
  inbuf: DWORD;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    try
      id := info.args[0].AsInteger;
      buf := '';
      inbuf := InBuffer(id);
      v8_FunctionCallbackInfo_return_uint32(_info, inbuf);
    except
      on e: exception do
      begin
        v8_FunctionCallbackInfo_return_int32(_info, -1);
      end;
    end;
  end;
end;

procedure _portread(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  buf: widestring;
  id: integer;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    try
      id := info.args[0].AsInteger;
      buf := '';
      while InBuffer(id) > 0 do
        buf := buf + ReadString(id);
      v8_FunctionCallbackInfo_return_string(_info, pwidechar(buf));
    except
      on e: exception do
      begin
        v8_FunctionCallbackInfo_return_string(_info, pchar('err!'));
      end;
    end;
  end;
end;

procedure _portenum(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  i: integer;
  buf: string;
  ports: Tports;
  json: TjsonEx;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  try
    ports := EnumSerialPorts;
    if Length(ports) <= 0 then
    begin
      v8_FunctionCallbackInfo_return_string(_info, pchar('[]'));
      exit;
    end;

    buf := '[';
    for i := Low(ports) to High(ports) do
    begin
      json := TjsonEx.Create();
      json.Put('port', ports[i].name);
      json.Put('desc', ports[i].desc);
      json.Put('busy', ports[i].busy);
      buf := buf + json.stringify + ',';
      json.Free;
    end;
    delete(buf, Length(buf), 1);
    buf := buf + ']';
    v8_FunctionCallbackInfo_return_string(_info, pwidechar(buf));
    exit;
  except
    on e: exception do
    begin
      v8_FunctionCallbackInfo_return_string(_info, pchar('[]'));
    end;
  end;
end;

procedure JSterminate;
var
  i: integer;
  _now: Cardinal;
begin
  if (Length(relbuf) > 0) then
  begin
    for i := Low(relbuf) to High(relbuf) do
    begin
      VM.eval(relbuf[i] + '();' + relbuf[i] + '=null;');
    end;
  end;

  _now := gettickcount;

  while (gettickcount - _now) < 3000 do
  begin
    Sleep(1);
  end;

  __killswitch := true;
  JsTimers.killall;
  libserial.killall;
  jsaudio.freeAll;
  jsdb.killDb;
end;

procedure _md5(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    v8_FunctionCallbackInfo_return_string(_info, pwidechar(JSCrypt._md5(info.args[0].AsString)));
  end;
end;

procedure _runfile(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  result: integer;
  args: string;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    args := '';
    if info.ArgCount > 1 then
      args := info.args[1].AsString;
    result := integer(RunFileWithParameters(fixpath(info.args[0].AsString), args));
    v8_FunctionCallbackInfo_return_uint32(_info, result);
  end
  else

    v8_FunctionCallbackInfo_return_uint32(_info, 0);
end;

procedure _md5file(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  hash: string;
  id: string;
  start: int64;
  x: Isuperobject;
  T: TThread;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    if info.ArgCount > 1 then
    begin
      id := geneid('_md5file');
      VM.GlobalObject.SetObject(id, info.args[0].AsObject);

      T := TThread.CreateAnonymousThread(
        procedure
        begin
          try
            start := gettickcount64;
            x := SO;
            x.S['file'] := info.args[0].AsString;
            x.S['hash'] := jscrypt._md5file(info.args[0].AsString);
            x.I['took'] := gettickcount64 - start;
          finally
            wm_sendstringex(ahandle, ahandle, pwidechar('~eval=' + id + '(' + x.AsJSON() + ');delete ' + id + ';'));
          end;
        end);
      T.FreeOnTerminate := true;
      T.Start;
    end
    else
    begin
      hash := jscrypt._md5file(info.args[0].AsString);
      v8_FunctionCallbackInfo_return_string(_info, pwidechar(hash));
    end;
  end;
end;

procedure _sha1(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    v8_FunctionCallbackInfo_return_string(_info, pwidechar(JSCrypt.GetStrHashSHA1(info.args[0].AsString)));
  end;
end;

procedure _crc32(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    v8_FunctionCallbackInfo_return_uint32(_info, (JSCrypt._crc32(info.args[0].AsString)));
  end;
end;

procedure _millis(_info: V8FunctionCallbackInfo); cdecl;
begin
  v8_FunctionCallbackInfo_return_uint32(_info, gettickcount64 - _start);
end;

procedure _unixtime(_info: V8FunctionCallbackInfo); cdecl;
begin
  v8_FunctionCallbackInfo_return_uint32(_info, unixTime);
end;

procedure _gettickcount(_info: V8FunctionCallbackInfo); cdecl;
begin
  v8_FunctionCallbackInfo_return_uint32(_info, gettickcount64);
end;

procedure _ram(_info: V8FunctionCallbackInfo); cdecl;
begin
  v8_FunctionCallbackInfo_return_int32(_info, ramdurumu);
end;

procedure _alert(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
  msg: string;
  title: string;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  msg := '';
  title := '';

  case info.ArgCount of
    1:
      begin
        msg := info.args[0].AsString;
      end;
    2:
      begin
        msg := info.args[0].AsString;
        title := info.args[1].AsString;
      end;
  end;
  OutputDebugString(pchar(msg));

  v8_FunctionCallbackInfo_return_int32(_info, MessageBox(GetForegroundWindow, pchar(msg), pchar(title), MB_ICONWARNING or MB_OK));
  if info.ArgCount > 2 then
  begin
    Randomize;
    eid := geneid;
    VM.GlobalObject.SetObject(eid, info.args[2].AsObject);
    VM.eval(eid + '();' + eid + '=null;');
  end;
end;

procedure _confirm(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
  msg: string;
  title: string;
  _Result: string;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  msg := '';
  title := '';

  case info.ArgCount of
    1:
      begin
        msg := info.args[0].AsString;
      end;
    2:
      begin
        msg := info.args[0].AsString;
        title := info.args[1].AsString;
      end;
  end;
  _Result := inputbox(title, msg, '');
  v8_FunctionCallbackInfo_return_string(_info, pwidechar(_Result));
  if info.ArgCount > 2 then
  begin
    Randomize;
    eid := geneid;
    VM.GlobalObject.SetObject(eid, info.args[2].AsObject);
    VM.eval(eid + '();' + eid + '=null;');
  end;
end;

procedure _fileExists(_info: V8FunctionCallbackInfo); cdecl;
var
  result: integer;
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    if (FileExists(fixpath(info.args[0].AsString))) or directoryexists(fixpath(info.args[0].AsString)) then
      result := 1
    else
      result := 0;
    v8_FunctionCallbackInfo_return_int32(_info, result);
  end;
end;

procedure _fileDelete(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    v8_FunctionCallbackInfo_return_int32(_info, integer(deletefile(pwidechar(fixpath(info.args[0].AsString)))));
  end;
end;

procedure _fileRename(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 1 then
  begin
    v8_FunctionCallbackInfo_return_int32(_info, integer(renamefile(pwidechar(fixpath(info.args[0].AsString)), pwidechar(fixpath(info.args[1].AsString)))));
  end;
end;

procedure _dirCreate(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    v8_FunctionCallbackInfo_return_int32(_info, integer(ForceDirectories(fixpath(info.args[0].AsString))));
  end;
end;

procedure _fileAppend(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 1 then
  begin
    if (appendText(fixpath(info.args[0].AsString), info.args[1].AsString)) then
      v8_FunctionCallbackInfo_return_int32(_info, 1)
    else
      v8_FunctionCallbackInfo_return_int32(_info, 0);
  end
  else
    v8_FunctionCallbackInfo_return_int32(_info, 0);
end;

procedure _filewrite(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
    // msg: string;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 1 then
  begin
    StringtoFileUTF8(fixpath(info.args[0].AsString), info.args[1].AsString);
    v8_FunctionCallbackInfo_return_int32(_info, 1);
    if info.ArgCount > 2 then
    begin
      eid := geneid('fw');
      VM.GlobalObject.SetObject(eid, info.args[2].AsObject);
      VM.eval(eid + '(true)');
    end;

  end
  else
    v8_FunctionCallbackInfo_return_int32(_info, 0);
end;

procedure _browse(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  buf: ansistring;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    buf := fixpath(info.args[0].AsString);
    if not DirectoryExists(buf) then
    begin
      v8_FunctionCallbackInfo_return_string(_info, pwidechar('[]'));
      exit;
    end;
    v8_FunctionCallbackInfo_return_string(_info, pwidechar(BrowseFolder(buf)));
  end;

end;

procedure _readfile(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  buf, _file: string;
  e: Tstringlist;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    try
      _file := fixpath(info.args[0].AsString);
      if FileExists(_file) = true then
      begin
        e := Tstringlist.Create;
        e.LoadFromFile(_file);
        buf := e.text;
        e.Free;
        v8_FunctionCallbackInfo_return_string(_info, PChar(buf));
      end
      else
      begin
        v8_FunctionCallbackInfo_return_int32(_info, 0);
      end;
    finally
    end;
  end;
end;

procedure _include(_info: V8FunctionCallbackInfo) cdecl;
var
  c: Tstringlist;
  info: Tv8FunctionCallbackInfo;
  fn: string;
  r: string;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    fn := fixpath(info.args[0].AsString);
    if not FileExists(fn) then
      exit;

    c := Tstringlist.Create;
    c.LoadFromFile(fn);
    r := (extractfilename(fn) + ': ' + VM.eval(c.text));
 //   _DebugStr(r, VM);
 //   if assigned(Log) then
 //     Log.Add(r);
    r := '';
    c.Free;
  end;
end;

procedure LoadJson(_info: V8FunctionCallbackInfo) cdecl;
var
  c: Tstringlist;
  info: Tv8FunctionCallbackInfo;
  fn: string;
  r: string;
    // i: integer;
  eid: string;
  AMember: IMember;
  js: ISuperArray;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    fn := fixpath(info.args[0].AsString);
    if not FileExists(fn) then
      exit;

    c := Tstringlist.Create;
    c.LoadFromFile(fn);
    js := SA(c.text);
    eid := geneid('lj');
    if __killswitch = true then
      exit;
    VM.GlobalObject.SetObject(eid, info.args[1].AsObject);
    for AMember in js do
    begin
      VM.eval(eid + '(' + AMember.ToString() + ');');
    end;

    r := '';
    c.Free;
    VM.eval(eid + '=null;');
  end;
end;

procedure _setTimeout(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 1 then
  begin
    eid := geneid('st');
    if __killswitch = true then
      exit;
    VM.GlobalObject.SetObject(eid, info.args[0].AsObject);
    v8_FunctionCallbackInfo_return_int32(_info, JsTimers.SetTimeout(
      procedure
      begin
        try
          VM.eval(eid + '();' + eid + '=null;');
        finally
        end;
      end, info.args[1].AsInteger));
  end;
end;

procedure _setInterval(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
  obj: Iv8Object;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 1 then
  begin
    eid := geneid('si');
    obj := info.args[0].AsObject;
    VM.GlobalObject.SetObject(eid, obj);
    v8_FunctionCallbackInfo_return_int32(_info, JsTimers.SetInterval(
      procedure
      begin
        if __killswitch = true then
          exit;
        if assigned(VM) then
        begin
          VM.eval(eid + '();');
        end;
      end, info.args[1].AsInteger));
  end;
end;

procedure _clearInterval(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    if __killswitch = true then
      exit;
    v8_FunctionCallbackInfo_return_int32(_info, integer(JsTimers.ClearInterval(info.args[0].AsInteger)));
  end;
end;

procedure _clearTimeout(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    if __killswitch = true then
      exit;
    v8_FunctionCallbackInfo_return_int32(_info, integer(JsTimers.ClearTimeout(info.args[0].AsInteger)));
  end;
end;

procedure _udpkill(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    v8_FunctionCallbackInfo_return_int32(_info, integer(udpStop(info.args[0].AsInteger)));
  end
  else
    v8_FunctionCallbackInfo_return_int32(_info, -1);
end;

procedure _udpListen(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  eid: string;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 1 then
  begin
    eid := geneid('$udpl');
    VM.GlobalObject.SetObject(eid, info.args[1].AsObject);
    v8_FunctionCallbackInfo_return_int32(_info, udpListen(eid, info.args[0].AsInteger));
  end
  else
    v8_FunctionCallbackInfo_return_int32(_info, -1);
end;

procedure _udpSend(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  id: string;
  url: string;
  data: string;
  port: integer;
  T: TThread;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    url := trim(info.args[0].AsString);
    port := info.args[1].AsInteger;
    data := trim(info.args[2].AsString);

    if url = '' then
      exit;

    Inc(ihttp);
    id := '_$udp' + inttostr(ihttp);
    T := TThread.CreateAnonymousThread(
      procedure
      begin
        udpSend(url, port, data);
      end);
    T.FreeOnTerminate := true;
    T.Start;
    v8_FunctionCallbackInfo_return_string(_info, pwidechar(id));
  end;
end;

procedure _httpget(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  res: TAjaxResponse;
  id: string;
  url: string;
  T: TThread;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    url := trim(info.args[0].AsString);
    if url = '' then
      exit;

    Inc(ihttp);
    id := '_$htp' + inttostr(ihttp);
    if info.ArgCount > 1 then
    begin
      VM.GlobalObject.SetObject(id, info.args[1].AsObject);
      v8_FunctionCallbackInfo_return_string(_info, pwidechar(id));
      T := TThread.CreateAnonymousThread(
        procedure
        begin
          try
            res := httpget(url);
          finally
            EnterCriticalSection(CriticalSection);
            //outputdebugstringw(pchar(id + '(' + inttostr(res.result) + ',' + quotedstr(res.response) + ');'));
            TThread.Synchronize(nil,
              procedure
              begin
                if (res.result = 200) and (res.mime = 'application/json') then
                  vm.eval(id + '(JSON.parse(' + quotedstr(safestring(res.response)) + '),' + inttostr(res.result) + ',' + quotedstr(res.mime) + ');delete ' + id, true)
                else
                  vm.eval(id + '(' + quotedstr(safestring(res.response)) + ',' + inttostr(res.result) + ',' + quotedstr(res.mime) + ');delete ' + id, true);
              end);
            LeaveCriticalSection(CriticalSection);
          end;
        end);
      T.FreeOnTerminate := true;
      T.Start;

    end
    else
    begin
      res := httpget(url);
      v8_FunctionCallbackInfo_return_string(_info, pwidechar(res.response));
    end;

  end;
end;

function ExtractFileNameFromURL(const URL: string): string;
var
  LastSlashIndex: Integer;
begin
  LastSlashIndex := LastDelimiter('/', URL);  // Find the last '/' in the URL
  if LastSlashIndex > 0 then
    result := Copy(URL, LastSlashIndex + 1, Length(URL) - LastSlashIndex)  // Extract the filename
  else
    result := '';  // No '/' found, return an empty string
end;

procedure _httpDownload(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  download: Tdownloader;
  T: TThread;
  filename: string;
  url: string;
  onprogress: string;
  onfinish: string;
  res: Tdownload;
  x: Isuperobject;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount >= 1 then
  begin
    onfinish := '';
    onprogress := '';

    url := info.args[0].AsString;

    if url = '' then
    begin
      v8_FunctionCallbackInfo_return_int32(_info, 0);
      exit;
    end;

    if info.ArgCount > 1 then
      filename := info.args[1].AsString
    else
      filename := ExtractFileNameFromURL(url);

    if filename = '' then
    begin
      v8_FunctionCallbackInfo_return_int32(_info, 0);
      exit;
    end;

    Inc(ihttp);

    if info.argcount >= 3 then
    begin
      onfinish := '_$htdlf' + inttostr(ihttp);
      VM.GlobalObject.SetObject(onfinish, info.args[2].AsObject);
    end;

    if info.ArgCount = 4 then
    begin
      onprogress := '_$htdlp' + inttostr(ihttp);
      VM.GlobalObject.SetObject(onprogress, info.args[3].AsObject);
    end;

    T := TThread.CreateAnonymousThread(
      procedure
      begin
        x := SO;
        download := Tdownloader.Create(onprogress);
        res := download.start(url, filename);
        if onfinish <> '' then
        begin

          x.B['result'] := res.success;
          x.I['response'] := res.response;
          x.I['downloaded'] := res.downloaded;
          x.I['size'] := res.length;
          x.S['mime'] := res.mime;
          x.S['local'] := res.local;
          x.S['remote'] := res.remote;

          EnterCriticalSection(CriticalSection);
          TThread.Synchronize(nil,
            procedure
            begin
              vm.eval(onfinish + '(' + x.AsJSON() + ');', true);
            end);
          LeaveCriticalSection(CriticalSection);
        end;
      end);
    T.FreeOnTerminate := true;
    T.Start;
    v8_FunctionCallbackInfo_return_int32(_info, 1);
  end
  else
    v8_FunctionCallbackInfo_return_int32(_info, 0);
end;

procedure _httpPost(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  res: TAjaxResponse;
  typ: string;
  id: string;
  data: string;
  url: string;
  T: TThread;
begin
  typ := 'application/x-www-form-urlencoded';
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 2 then
  begin
    url := info.args[0].AsString;
    data := info.args[1].AsString;
    typ := info.args[2].AsString;
    if url = '' then
      exit;

    if data = '' then
      exit;

    if info.ArgCount > 3 then
    begin
      typ := info.args[3].AsString;
    end;

    Inc(ipost);
    id := '_$htps' + inttostr(ipost);
    VM.GlobalObject.SetObject(id, info.args[2].AsObject);
    T := TThread.CreateAnonymousThread(
      procedure
      begin
        coinitialize(nil);
        res := httpPost(url, data, typ);
        outputdebugstringW(pchar(res.mime));
        EnterCriticalSection(CriticalSection);
        TThread.Synchronize(nil,
          procedure
          begin
            if res.mime = 'application/json' then
              vm.eval(id + '(JSON.parse(' + quotedstr(safestring(res.response)) + '),' + inttostr(res.result) + ',' + quotedstr(res.mime) + ');delete ' + id, true)
            else
              vm.eval(id + '(' + quotedstr(safestring(res.response)) + ',' + inttostr(res.result) + ',' + quotedstr(res.mime) + ');delete ' + id, true);

          end);
        LeaveCriticalSection(CriticalSection);
      end);
    T.FreeOnTerminate := true;
    T.Start;
    v8_FunctionCallbackInfo_return_string(_info, pwidechar(id));
  end;
end;

procedure _dbopen(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    v8_FunctionCallbackInfo_return_int32(_info, jsdb.opendb(fixpath(info.args[0].AsString)));
  end;
end;

procedure _dbclose(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    v8_FunctionCallbackInfo_return_int32(_info, integer(closedb(info.args[0].AsInteger)));
  end;
end;

procedure _dbquery(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    v8_FunctionCallbackInfo_return_string(_info, pwidechar(jsdb.query(info.args[0].AsInteger, info.args[1].AsString)));
  end;
end;

procedure _dbqueryEx(_info: V8FunctionCallbackInfo); cdecl;
var
  T: TThread;
  id: string;
  fn: string;
  query: string;
  result: string;
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    fn := info.args[0].AsString;
    query := info.args[1].AsString;
    id := '_$db' + inttostr(itts);
    VM.GlobalObject.SetObject(id, info.args[2].AsObject);

    T := TThread.CreateAnonymousThread(
      procedure
      begin
        result := jsdb.threadedQuery(fn, query);
        wm_sendstringex(ahandle, ahandle, pwidechar('~eval=' + id + '(' + result + ');' + id + '=undefined;'));
        Sleep(1000);
      end);
    T.FreeOnTerminate := true;
    T.Start;
  end;
end;

procedure _dbexec(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  if info.ArgCount > 0 then
  begin
    v8_FunctionCallbackInfo_return_int32(_info, integer(jsdb.exec(info.args[0].AsInteger, info.args[1].AsString)));
  end;
end;

procedure console_log(_info: V8FunctionCallbackInfo); cdecl;
var
  msg: string;
  argcnt: integer;
  info: Tv8FunctionCallbackInfo;
begin
  if mode = 3 then
    exit;

  info := Tv8FunctionCallbackInfo.Create(_info);
  argcnt := info.ArgCount;
  if argcnt > 0 then
    msg := info.args[0].AsString
  else
    msg := 'undefined';

  WriteColoredText(msg, FOREGROUND_INTENSITY or FOREGROUND_BLUE);
  if assigned(log) then
    log.write(msg);

end;

procedure freeKeys;
var
  Item: TPair<word, string>;
begin
  for Item in hotkeys do
    UnRegisterHotkey(winh, Item.key);
  hotkeys.Clear;
  hotkeys.Free;
end;

initialization
  _start := gettickcount64;
  SetLength(relbuf, 0);
  SetLength(msgbuf, 0);
  SetLength(devbuf, 0);
  SetLength(keyhook, 0);
  SetLength(dbgbuf, 0);
  SetLength(audbuf, 0);
  SetLength(cmdbuf, 0);
  SetLength(evtbuf, 0);
  SetLength(debuf, 0);
  SetLength(febuf, 0);
  SetLength(extensions, 0);
  InitializeCriticalSection(CriticalSection);

  hotkeys := TDictionary<word, string>.Create;
  keys := TDictionary<word, string>.Create;

  hUser32 := GetModuleHandle('USER32.DLL');
  if hUser32 <> 0 then
    @LockWorkStation := GetProcAddress(hUser32, 'LockWorkStation');

  ihttp := 0;
  ipost := 0;


finalization
  SetLength(relbuf, 0);
  SetLength(msgbuf, 0);
  SetLength(devbuf, 0);
  SetLength(keyhook, 0);
  SetLength(dbgbuf, 0);
  SetLength(audbuf, 0);
  SetLength(cmdbuf, 0);
  SetLength(evtbuf, 0);
  SetLength(debuf, 0);
  SetLength(febuf, 0);
  SetLength(extensions, 0);

  freeKeys;
  keys.Free;

end.

