unit jsruntime;

interface

uses
  Winapi.Windows, v8, classes, sysutils, xsuperobject, JSNatives, jsfilesystem,
  stringtools, utils;

type
  TjsRuntime = class
    constructor create;
    destructor free;
  public
    log: TStringList;
    filename: string;
    FEngine: Tv8Engine;
    procedure reset;
    procedure start;
    procedure stop;
    procedure processEvent(eid: integer; const sparam: string = ''; const iparam: integer = 0);
    procedure Eval(code: widestring);
    procedure EvalFromRes(name: string);
  private
    active: Boolean;
    queue: array of widestring;
    console: Tv8ObjectTemplate;
    disk: Tv8ObjectTemplate;
    fs: Tv8ObjectTemplate;
    http: Tv8ObjectTemplate;
    sec: Tv8ObjectTemplate;
    db: Tv8ObjectTemplate;
    serial: Tv8ObjectTemplate;
    vm: Tv8ObjectTemplate;
    proc: Tv8ObjectTemplate;
    hw: Tv8ObjectTemplate;
    usr: Tv8ObjectTemplate;
    tcp: Tv8ObjectTemplate;
    bass: Tv8ObjectTemplate;
    dde: Tv8ObjectTemplate;
    tts: Tv8ObjectTemplate;
    udp: Tv8ObjectTemplate;
    procedure CreateNatives;
    procedure KillNatives;
  end;

implementation

uses
  entrypoint, psyapi;

procedure TjsRuntime.Eval(code: widestring);
begin
  FEngine.Eval(code);
  code := '';
end;

procedure TjsRuntime.reset;
begin
  setlength(queue, 0);
  log.Clear;
  stop;
  Sleep(1);
  start;
end;

procedure TjsRuntime.processEvent(eid: integer; const sparam: string = ''; const iparam: integer = 0);
begin
  case eid of
    1:
      _SetDevMsg(true, @FEngine);
    2:
      _SetDevMsg(false, @FEngine);
    3:
      _SetWinMsg(sparam, @FEngine);
    4:
      _NotifyHotkey(iparam, @FEngine);
    5:
      _Notifykey(iparam, @FEngine);
    6:
      _Notifykeys(iparam, sparam, @FEngine);
    7:
      _DebugStr(sparam, @FEngine);
    8:
      _Audstate(iparam, @FEngine);
    9:
      _ipcMessage(sparam, @FEngine);
    10:
      _OsEvent(iparam, @FEngine);
    11:
      __DebugStr(sparam, @FEngine);
    12:
      _fchange(sparam, @FEngine);
    13:
     // _BattEvent(iparam, @Fengine);




  end;
end;

procedure Tjsruntime.EvalFromRes(name: string);
var
  boot: Tstringlist;
  RStream: TResourceStream;
begin
  RStream := TResourceStream.Create(HInstance, name, RT_RCDATA);
  boot := Tstringlist.Create;
  boot.LoadFromStream(RStream);
  FEngine.Eval(boot.Text, true);
  boot.Free;
  RStream.Free;
end;

procedure TjsRuntime.CreateNatives;
var
  i: integer;
  ptmp: string;
  env: Tenvvars;
begin
  OutputDebugString(pchar('initializing'));

  console := Tv8ObjectTemplate.create(1);
  console.AddMethod('write', console_log, nil);
  FEngine.GlobalObject.SetObject('console', console.CreateInstance(nil));

  udp := Tv8ObjectTemplate.create(3);
  udp.AddMethod('_send', _udpSend, nil);
  udp.AddMethod('_listen', _udpListen, nil);
  udp.AddMethod('stop', _udpkill, nil);
  FEngine.GlobalObject.SetObject('udp', udp.CreateInstance(nil));

  fs := Tv8ObjectTemplate.create(5);
  fs.AddMethod('_write', _filewrite, nil);
  fs.AddMethod('_browse', _browse, nil);
  fs.AddMethod('read', _readfile, nil);
  fs.AddMethod('exists', _fileExists, nil);
  fs.AddMethod('mkdir', _dirCreate, nil);
  fs.AddMethod('append', _fileAppend, nil);
  fs.AddMethod('delete', _fileDelete, nil);
  fs.AddMethod('rename', _fileRename, nil);
  fs.AddMethod('md5', _md5file, nil);
  fs.AddMethod('run', _runFile, nil);

  FEngine.GlobalObject.SetObject('fs', fs.CreateInstance(nil));

  http := Tv8ObjectTemplate.create(4);
  http.AddMethod('get', _httpget, nil);
  http.AddMethod('_post', _httpPost, nil);
  http.addMethod('download', _httpdownload, nil);
  FEngine.GlobalObject.SetObject('http', http.CreateInstance(nil));

  disk := Tv8ObjectTemplate.create(3);
  disk.AddMethod('enum', _disklist, nil);
    // disk.AddMethod('size', _disksize, nil);
    // disk.AddMethod('free', _diskfree, nil);

  FEngine.GlobalObject.SetObject('_disk', disk.CreateInstance(nil));

  sec := Tv8ObjectTemplate.create(3);
  sec.AddMethod('md5', _md5, nil);
  sec.AddMethod('crc', _crc32, nil);
  sec.AddMethod('sha1', _sha1, nil);
  FEngine.GlobalObject.SetObject('sec', sec.CreateInstance(nil));

  db := Tv8ObjectTemplate.create(3);
  db.AddMethod('open', _dbopen, nil);
  db.AddMethod('close', _dbclose, nil);
  db.AddMethod('query', _dbquery, nil);
  db.AddMethod('exec', _dbexec, nil);
  db.AddMethod('queryEx', _dbqueryEx, nil);
  FEngine.GlobalObject.SetObject('_sqlite', db.CreateInstance(nil));

  serial := Tv8ObjectTemplate.create(5);
  serial.AddMethod('open', _portopen, nil);
  serial.AddMethod('close', _portclose, nil);
  serial.AddMethod('read', _portread, nil);
  serial.AddMethod('write', _portwrite, nil);
  serial.AddMethod('enum', _portenum, nil);
  serial.AddMethod('inbuf', _portavailable, nil);

  FEngine.GlobalObject.SetObject('_serial', serial.CreateInstance(nil));

  vm := Tv8ObjectTemplate.create(11);
  vm.AddMethod('release', _release, nil);
  vm.AddMethod('message', _GetWinMsg, nil);
  vm.AddMethod('debug', _RegDebug, nil);
  vm.AddMethod('end', _stop, nil);
  vm.AddMethod('terminate', _Halt, nil);
  vm.AddMethod('log', _WriteDebug, nil);
  vm.AddMethod('error', _RegEDebug, nil);
  vm.AddMethod('update', _RegFchange, nil);
  vm.AddMethod('extend', _LoadExtension, nil);
  vm.AddMethod('getTickCount', _gettickcount, nil);
  vm.AddMethod('ramUsage', _ram, nil);
  FEngine.GlobalObject.SetObject('vm', vm.CreateInstance(nil));

  dde := Tv8ObjectTemplate.create(2);
  dde.AddMethod('find', _findwindow, nil);
  dde.AddMethod('send', _sendstring, nil);
  FEngine.GlobalObject.SetObject('_ipc', dde.CreateInstance(nil));

  proc := Tv8ObjectTemplate.create(5);
  proc.AddMethod('create', _proccreate, nil);
  proc.AddMethod('ping', _procping, nil);
  proc.AddMethod('release', _procRelease, nil);
  proc.AddMethod('current', _procInfo, nil);
  proc.AddMethod('list', _procList, nil);
  proc.AddMethod('pipe', _procPipe, nil);

  FEngine.GlobalObject.SetObject('_proc', proc.CreateInstance(nil));

  hw := Tv8ObjectTemplate.create(3);
  hw.AddMethod('list', _hwlist, nil);
  hw.AddMethod('wlan', _wlscan, nil);
  hw.AddMethod('onDevice', _GetDevMsg, nil);
  FEngine.GlobalObject.SetObject('_hw', hw.CreateInstance(nil));

  usr := Tv8ObjectTemplate.create(7);
  usr.AddMethod('key', _SetKey, nil);
  usr.AddMethod('keys', _SetKeys, nil);
  usr.AddMethod('nokeys', _unSetKeys, nil);
  usr.AddMethod('hotkey', _SetHotkey, nil);
  usr.AddMethod('idle', _GetIdle, nil);

  //usr.AddMethod('name', _GetUserName, nil);

  usr.AddMethod('sendkey', _SendKeys, nil);
  usr.AddMethod('screenshot', _ScreenShot, nil);
  usr.AddMethod('resolution', _GetResolution, nil);
  usr.AddMethod('getActiveApp', _GetCurrentApp, nil);
  usr.AddMethod('getActiveWin', _GetCurrentWin, nil);
  usr.AddMethod('isFullScreen', _IsFullscreen, nil);

  usr.AddMethod('toggleMonitor', _ToggleMonitor, nil);
  usr.AddMethod('onEvent', _RegOsEvent, nil);
  usr.AddMethod('onMessage', _RegMessage, nil);
  usr.AddMethod('lock', _Lock, nil);

  usr.AddMethod('getclip', _ScreenShot, nil);
  usr.AddMethod('setclip', _ScreenShot, nil);
  usr.AddMethod('saveclip', _ScreenShot, nil);
  FEngine.GlobalObject.SetObject('_desktop', usr.CreateInstance(nil));

  bass := Tv8ObjectTemplate.create(6);
  bass.AddMethod('init', _audstart, nil);
  bass.AddMethod('kill', _audstop, nil);
  bass.AddMethod('sload', _audload, nil);
  bass.AddMethod('splay', _audplay, nil);
  bass.AddMethod('playd', _audspeech, nil);
  bass.AddMethod('stream', _audstream, nil);
    // bass.AddMethod('volume', _audstream, nil);
  bass.AddMethod('monitor', _RegAudio, nil);

  FEngine.GlobalObject.SetObject('_audio', bass.CreateInstance(nil));

  tcp := Tv8ObjectTemplate.create(4);
  tcp.AddMethod('_listen', _tcplisten, nil);
    // start server, register receiver callback
  tcp.AddMethod('write', _tcpwrite, nil); // send text
  tcp.AddMethod('kick', _tcpkick, nil); // close connection
  tcp.AddMethod('close', _tcpclose, nil); // shutdown server

  FEngine.GlobalObject.SetObject('tcp', tcp.CreateInstance(nil));

  tts := Tv8ObjectTemplate.create(2);
  tts.AddMethod('render', _TTSSpeak, nil);
  FEngine.GlobalObject.SetObject('_tts', tts.CreateInstance(nil));

  FEngine.RegisterNativeFunction('include', _include, nil);

  FEngine.RegisterNativeFunction('alert', _alert, nil);
  FEngine.RegisterNativeFunction('confirm', _confirm, nil);

  FEngine.RegisterNativeFunction('setTimeout', _setTimeout, nil);
  FEngine.RegisterNativeFunction('clearTimeout', _clearTimeout, nil);
  FEngine.RegisterNativeFunction('setInterval', _setInterval, nil);
  FEngine.RegisterNativeFunction('clearInterval', _clearInterval, nil);

  FEngine.RegisterNativeFunction('time', _unixtime, nil);
  FEngine.RegisterNativeFunction('millis', _millis, nil);

  //FEngine.RegisterNativeFunction('iJSON', LoadJson, nil);

  FEngine.Eval('vm.pid=' + inttostr(GetCurrentProcessId) + ';', true);
  FEngine.Eval('vm.handle=' + inttostr(ahandle) + ';', true);
  FEngine.Eval('vm.mode=' + inttostr(mode) + ';', true);
  FEngine.Eval('vm.logging=' + booltostr(assigned(log)) + ';', true);
  FEngine.Eval('vm.zombie=' + booltostr(nokill) + ';', true);
  FEngine.Eval('vm.repl=' + booltostr(repl) + ';', true);

  FEngine.Eval('vm.process="' + SafeString(ParamStr(0)) + '";', true);
  FEngine.Eval('vm.version= + parseFloat(' + quotedstr(version_info) + ');', true);
  FEngine.Eval('vm.arch = ' + quotedstr(version_arch) + ';', true);
  FEngine.Eval('vm.path = {"app":"' + safestring(extractfilepath(paramstr(0))) + '","windows":"' + SafeString(windowspath) + '", "temp":"' + SafeString(GetTempFolder) + '"};', true);
  FEngine.Eval('vm.host = {"name":"' + SafeString(makine) + '", "user":"' + SafeString(GetUserName) + '", "os":"' + getWindowsVersion + '", "ram":' + inttostr(GetSystemMem) + ', "IsAdmin":' + parseBool(IsAdministrator) + ', "IsElevated":' + parseBool(IsElevated) + ', "country":"' + SafeString((LocaleInfoEx(LOCALE_SISO3166CTRYNAME))) + '","timezone":"' + GetTimeZone + '","locale":"' + SafeString(LocaleInfoEx(LOCALE_SNAME)) + '"};', true);
  if ParamCount > 0 then
  begin
    ptmp := 'vm.args = [';
    for i := 1 to ParamCount do
    begin
      ptmp := ptmp + quotedstr(SafeString(ParamStr(i))) + ',';
    end;

    SetLength(ptmp, Length(ptmp) - 1);

    ptmp := ptmp + '];';
    FEngine.Eval(ptmp, true);

  end
  else
  begin
    FEngine.Eval('vm.args = [];', true);
  end;

  env := GetAllEnvVars;

  ptmp := 'vm.env = {';
  for i := low(env) to high(env) do
  begin
    ptmp := ptmp + '"' + safestring(env[i].key) + '":' + quotedstr(SafeString(env[i].value)) + ',';
  end;
  SetLength(ptmp, Length(ptmp) - 1);

  ptmp := ptmp + '};';
  FEngine.Eval(ptmp, true);

  OutputDebugString(pchar('initializing'));

  EvalFromRes('boot');

  if update = true then
  begin
    OutputDebugString(pchar('checking for updates'));
    judith.engine.EvalFromRes('update');
  end;

  ptmp := #0;
  JSNatives.vm := @FEngine;
  OutputDebugString(pchar('started'));

  for i := Low(scripts) to High(scripts) do
  begin
    FEngine.Eval(LoadFileToStr(scripts[i]), true);
  end;

end;

procedure TjsRuntime.KillNatives;
begin
  JSNatives.Jsterminate;
  console.free;
  fs.free;
  http.free;
  disk.free;
  proc.free;
  db.free;
  sec.free;
  serial.free;
  hw.free;
  usr.free;
  tcp.free;
  bass.free;
  dde.free;
  tts.Free;
  vm.free;
end;

constructor TjsRuntime.create;
begin
  setlength(queue, 0);

  if v8.v8_init = false then
  begin
    raise Exception.create('Cannot initialize engine');
  end;

  FEngine := Tv8Engine.create;
  start;
end;

destructor TjsRuntime.free;
begin
  stop;
  FEngine.free;
  v8.v8_cleanup;
  log.free;
end;

procedure TjsRuntime.start;
begin
  FEngine.enter;
  CreateNatives;
  active := true;
end;

procedure TjsRuntime.stop;
begin
  active := false;
  KillNatives;
  FEngine.leave;
end;

end.

