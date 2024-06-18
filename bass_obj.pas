unit Bass_obj;
{
  Bass 2.4 Object oriented helper
  Allows to easily use of bass audio functions

  Coded by Psy_chip
  root@psychip.net
  2009
}

interface

uses
  windows, SysUtils, Classes, bass;

type
  TWaveData = array[0..2048] of DWORD;

type
  TFFTData = array[0..512] of Single;

type
  TStreamdata = packed record
    buffer: integer;
    error: integer;
    bitrate: integer;
    infotag: string;
    metadata: string;
  end;

type
  Tsample = packed record
    filename: string;
    tag: string;
    len: integer;
    ch: HSAMPLE;
  end;

type
  TBass = class
    currentsource: string;
    volume: integer;
    Length: Int64;
    position: Int64;
    streamdata: Tstreamdata;
    fftdata: TFFTData;
    time: string;
    paused: boolean;
    muted: boolean;
    playing: Boolean;
    streaming: boolean;
    initialized: Boolean;
    procedure stopall;
    procedure playextsample(filename: string; const loop: Boolean = false);
    function isplaying: Boolean;
    procedure loadsample(filename: string; const tag: string = '');
    function playsample(tag: string): integer;
    function lasterror: string;
    procedure pause;
    procedure stop;
    procedure mute;
    function play(filename: string): integer;
    function play_dsp(filename: string): integer;
    procedure stream(url: string);
    function active: dword;
    procedure freesample(tag: string);
    function getfft: TFFTData;
    procedure setvolume(newvolume: integer);
    procedure fadeto(vol: Integer);
    procedure incvol(const level: integer = 2);
    procedure decvol(const level: integer = 2);
    procedure setposition(Pos: Int64);
    function getposition: int64;
    function readbitrate: Integer;
    procedure init_plugins(dir: string);
    procedure MetaSync(handle: HSYNC; channel, data, user: DWORD); stdcall;
    procedure ReadMetaData();
    procedure free_samples;
    procedure free_plugins;
    //procedure UpdateAdvEQ(_275hz, _2200hz, _5000hz, _8300hz: integer; fx: DWORD; eq: BASS_BFX_PEAKEQ);
    procedure seteq(_1, _2, _3, _4: Integer);
    procedure importsamples(samples: Tstringlist);
  published
    constructor create(rate: integer = 44100);
    destructor free; virtual;
  private
    plugins: array[0..32] of HPLUGIN;
    realvolume: single;
    samples: array[0..256] of Tsample;
    samplecount: integer;
    channel: dword;
    prevbitrate: integer;
    dsp: HDSP;
    floatable: DWORD;
    stopsounds: Boolean;
    eqbuf: array[0..4] of Integer;
    currdev: DWORD;
    //procedure _UpdateEQ(b, pos: integer; fx: DWORD; eq: BASS_BFX_PEAKEQ);
    procedure setsamplevolume(sample: HSAMPLE; newvolume: single);
  end;

implementation

uses
  entrypoint;

const
  eaxlevelvar = 1750;     // 999 ms
  input_buffer = 262144; // 256 kb
  output_buffer = 2000;  // 2 seconds
  volume_slide = 350;    // 350 ms

var
  echbuf: array[0..eaxlevelvar - 1, 0..1] of Single;
  echpos: Integer;

procedure Tbass.importsamples(samples: Tstringlist);
var
  i: integer;
begin
  for i := 0 to samples.count - 1 do
  begin
    loadsample(samples.strings[i]);
  end;
end;

procedure processdsp(handle: HDSP; channel: DWORD; buffer: Pointer; length: DWORD; user: DWORD); stdcall;
var
  a: DWORD;
  d: PSingle;
  l, r: Single;
begin
  d := buffer;
  a := 0;

  while (a < (length div 4)) do
  begin
    l := d^ + (echbuf[echpos, 1] / 2);
    Inc(d);
    r := d^ + (echbuf[echpos, 0] / 2);
    Dec(d);

    { Basic "bathroom" reverb }

    d^ := l;
    echbuf[echpos, 0] := l;
    Inc(d);
    d^ := r;
    echbuf[echpos, 1] := r;


    {
     //Echo
    echbuf[echpos, 0] := d^;
    d^ := 1;
    Inc(d);
    echbuf[echpos, 1] := d^;
    d^ := r;
   }
    echpos := echpos + 1;
    if (echpos >= eaxlevelvar) then
      echpos := 0;

    Inc(d);
    a := a + 2;
  end;
end;

procedure Tbass.stopall;
begin
  self.stopsounds := True;
  self.stop;
end;

procedure Tbass.fadeto(vol: Integer);
var
  xvol: single;
begin
  xvol := vol / 100;
  if isplaying then
    BASS_ChannelSlideAttribute(self.channel, BASS_ATTRIB_VOL, xvol, volume_slide);
end;

function Tbass.isplaying: Boolean;
begin
  if BASS_ChannelIsActive(self.channel) = 1 then
    Result := True
  else
    Result := false;
end;

procedure Tbass.incvol(const level: integer = 2);
var
  vol: single;
begin
  vol := (self.volume + level) / 100;
  BASS_ChannelSetAttribute(self.channel, BASS_ATTRIB_VOL, vol);
end;

procedure Tbass.decvol(const level: integer = 2);
var
  vol: single;
begin
  vol := (self.volume - level) / 100;
  BASS_ChannelSetAttribute(self.channel, BASS_ATTRIB_VOL, vol);
end;

procedure Tbass.seteq(_1, _2, _3, _4: Integer);
begin
  self.eqbuf[0] := _1;
  self.eqbuf[1] := _2;
  self.eqbuf[2] := _3;
  self.eqbuf[3] := _4;
end;
      {
procedure Tbass._UpdateEQ(b, pos: integer; fx: DWORD; eq: BASS_BFX_PEAKEQ);
begin
  /// pos: gain in db -15 between +15
  pos := 10 - pos;
  eq.lBand := b;
  BASS_FXGetParameters(fx, @eq);
  eq.fGain := pos;
  BASS_FXSetParameters(fx, @eq);
//  self.eqbuf[b]:=pos;
end;

procedure Tbass.UpdateAdvEQ(_275hz, _2200hz, _5000hz, _8300hz: integer; fx: DWORD; eq: BASS_BFX_PEAKEQ);
begin
  _UpdateEQ(0, _275hz, fx, eq);
  _UpdateEQ(1, _2200hz, fx, eq);
  _UpdateEQ(2, _5000hz, fx, eq);
  _UpdateEQ(3, _8300hz, fx, eq);
end;
           }

function Tbass.play_dsp(filename: string): integer;
var
  oldvolume: integer;
  i, c: integer;
 // fxEQ: DWORD;
  //eq: BASS_BFX_PEAKEQ;
begin
  BASS_SetDevice(self.currdev);

  for i := 0 to High(echbuf) do
  begin
    for c := 0 to High(echbuf[i]) do
    begin
      echbuf[c, i] := 0;
    end;
  end;

  for i := Low(echbuf) to High(echbuf) do
  begin
    echbuf[i, 0] := 0;
    echbuf[i, 1] := 0;
  end;

  FillChar(echbuf, SizeOf(echbuf), 0);

  echpos := 0;
 // debug('playing: ' + filename);
  self.channel := BASS_StreamCreateFile(FALSE, PChar(filename), 0, 0, {$IFDEF UNICODE} BASS_UNICODE {$ENDIF}             or BASS_STREAM_AUTOFREE or BASS_MUSIC_RAMP or floatable or BASS_STREAM_PRESCAN);
//BASS_SetConfig(BASS_CONFIG_ASYNCFILE_BUFFER, input_buffer);
  BASS_SetConfig(BASS_CONFIG_BUFFER, output_buffer);
  result := Round(BASS_ChannelBytes2Seconds(self.channel, BASS_ChannelGetLength(Self.channel, BASS_POS_BYTE)));

//  self.channel := BASS_StreamCreateFile(FALSE, pwidechar(filename), 0, 0, BASS_STREAM_AUTOFREE);
//BASS_SetConfig(BASS_CONFIG_ASYNCFILE_BUFFER, input_buffer);
//BASS_SetConfig(BASS_CONFIG_BUFFER, output_buffer);

//self.Length:=round(BASS_ChannelBytes2Seconds(self.channel, BASS_ChannelGetLength(Self.channel, BASS_POS_BYTE)));

  self.currentsource := filename;

  //BASS_ChannelSetAttribute(self.channel, BASS_ATTRIB_VOL, 0.9);
  {
  fxEQ := BASS_ChannelSetFX(self.channel, BASS_FX_BFX_PEAKEQ, 0);
  with eq do
  begin
    fBandwidth := 2.5;
    FQ := 0;
    fGain := 0;
    lChannel := BASS_BFX_CHANALL;

    eq.lBand := 0;
    eq.fCenter := 275;

    BASS_FXSetParameters(fxEQ, @eq);

    eq.lBand := 1;
    eq.fCenter := 2200;
    BASS_FXSetParameters(fxEQ, @eq);

    eq.lBand := 2;
    eq.fCenter := 5000;
    BASS_FXSetParameters(fxEQ, @eq);

    eq.lBand := 3;
    eq.fCenter := 8300;
    BASS_FXSetParameters(fxEQ, @eq);

  end;
  }
  //UpdateAdvEQ(eqbuf[0], eqbuf[1], eqbuf[2], eqbuf[3], fxEQ, eq);
  Self.dsp := BASS_ChannelSetDSP(Self.channel, @processdsp, 0, 1);
  BASS_ChannelPlay(self.channel, false);
  self.playing := false;
//  BASS_ChannelRemoveDSP(self.channel, self.dsp);
//  BASS_ChannelRemoveFX(self.channel, fxEQ);
end;

procedure Tbass.free_samples;
var
  i: integer;
begin
  for i := 0 to samplecount do
  begin
    if samples[i].ch > 0 then
      BASS_SampleFree(samples[i].ch);
  end;
  ZeroMemory(@samples, 0);
end;

procedure Tbass.loadsample(filename: string; const tag: string = '');
var
  ms: Tmemorystream;
  i: BASS_SAMPLE;
begin
  if not FileExists(filename) then
  begin
    OutputDebugString(PChar('BASS: file not found: ' + filename));
    exit;
  end;
  BASS_SetDevice(self.currdev);
  ms := Tmemorystream.create;
  ms.LoadFromFile(filename);
  self.samples[samplecount].ch := BASS_SampleLoad(true, ms.Memory, 0, ms.Size, 8, BASS_SAMPLE_SOFTWARE or BASS_SAMPLE_OVER_POS or BASS_SAMPLE_VAM or BASS_STREAM_PRESCAN);
  BASS_SampleGetInfo(self.samples[samplecount].ch, i);
  self.samples[samplecount].len := Round(BASS_ChannelBytes2Seconds(self.samples[samplecount].ch, i.length));
  ms.free;
  if tag = '' then
    self.samples[samplecount].tag := ExtractFileName(filename)
  else
    self.samples[samplecount].tag := tag;
  self.samples[samplecount].filename := filename;
  inc(samplecount);
end;

procedure tbass.freesample(tag: string);
var
  i: integer;
begin
  if tag = '' then
    exit;
  for i := 0 to High(self.samples) do
  begin
    if self.samples[i].tag = tag then
    begin
      BASS_SampleFree(self.samples[i].ch);
      self.samples[i].filename := '';
      self.samples[i].tag := '';
    end;
  end;
end;

function Tbass.playsample(tag: string): integer;
var
  ch: HCHANNEL;
  i: integer;
  found: boolean;
begin
  found := False;
  BASS_SetDevice(self.currdev);
  for i := low(self.samples) to High(self.samples) do
  begin
    if self.samples[i].tag = tag then
    begin
      ch := BASS_SampleGetChannel(self.samples[i].ch, false);
      Result := Self.samples[i].len;
      bass_channelplay(ch, false);
      found := true;
      break;
    end;
  end;
  if not found then
  begin
    OutputDebugString(PChar('BASS: sample not found: ' + tag));
  end;
end;

function Tbass.lasterror: string;
var
  code: Integer;
begin
  code := BASS_ErrorGetCode;
  Result := IntToStr(code);
end;

function Tbass.readbitrate;
var
  rate: QWORD;
begin
  rate := BASS_StreamGetFilePosition(self.channel, BASS_FILEPOS_CURRENT) div 100;

  if rate = prevbitrate then
  begin
    result := self.streamdata.bitrate;
    exit;
  end;

  self.streamdata.bitrate := rate - self.prevbitrate;
  result := self.streamdata.bitrate;
  self.prevbitrate := rate;
end;

procedure Tbass.ReadMetaData();
var
  meta: PAnsiChar;
  p: Integer;
begin
  meta := BASS_ChannelGetTags(self.channel, BASS_TAG_META);
  if (meta <> nil) then
  begin
    p := pos('StreamTitle=', string(AnsiString(meta)));
    if (p = 0) then
      Exit;
    p := p + 13;
    self.streamdata.metadata := AnsiString(Copy(meta, p, pos(';', string(meta)) - p - 1));
  end;
end;

procedure TBass.MetaSync(handle: HSYNC; channel, data, user: DWORD); stdcall;
begin
  self.ReadMetaData();
end;

procedure Tbass.Stream(url: string);
var
  icy: PAnsiChar;
  Len, Progress: DWORD;
begin

  Progress := 0;
  Self.streamdata.buffer := 0;
  self.streamdata.error := 0;
  Self.streamdata.infotag := '';
  self.streamdata.metadata := '';
  if self.active <> 0 then
    BASS_StreamFree(self.channel);
  Self.streaming := True;
  self.paused := False;
  self.currentsource := url;
  self.channel := BASS_StreamCreateURL(PChar(url), 0, BASS_STREAM_STATUS, nil, nil);
  self.streamdata.error := Self.channel;
  if self.channel <> 0 then
  begin
    repeat
      Len := BASS_StreamGetFilePosition(self.channel, BASS_FILEPOS_END);
      if (Len = DW_Error) then
        break;
      Progress := (BASS_StreamGetFilePosition(self.channel, BASS_FILEPOS_DOWNLOAD) - BASS_StreamGetFilePosition(self.channel, BASS_FILEPOS_CURRENT)) * 100 div Len;
      self.streamdata.buffer := Progress;
    until Progress > 75;
    icy := BASS_ChannelGetTags(self.channel, BASS_TAG_ICY);
    if (icy = nil) then
      icy := BASS_ChannelGetTags(self.channel, BASS_TAG_HTTP);
    if (icy <> nil) then
      self.streamdata.infotag := icy;
    self.ReadMetaData();
    BASS_ChannelPlay(self.channel, FALSE);
  end;

end;

procedure Tbass.mute;
begin
  if self.muted then
    self.setvolume(self.volume)
  else
    setvolume(0);
  self.muted := not self.muted;
end;

procedure Tbass.setposition(Pos: Int64);
begin
  BASS_ChannelSetPosition(self.channel, BASS_ChannelSeconds2Bytes(self.channel, Pos), BASS_POS_BYTE);
end;

function Tbass.getposition: int64;
begin
  self.position := round(BASS_ChannelBytes2Seconds(self.channel, BASS_ChannelGetPosition(Self.channel, BASS_POS_BYTE)));
  result := self.position;
end;

procedure Tbass.init_plugins(dir: string);

  function findfreeplug: Integer;
  var
    i: integer;
  begin
    for i := low(plugins) to High(plugins) do
    begin
      if plugins[i] <= 0 then
      begin
        result := i;
        exit;
      end;
    end;
  end;

var
  fd: TWin32FindData;
  fh: THandle;
begin
  fh := FindFirstFile(PChar(dir + '*.dll'), fd);
  if (fh <> INVALID_HANDLE_VALUE) then
  try
    repeat
      plugins[findfreeplug] := BASS_PluginLoad(PChar(dir + fd.cFileName), 0 {$IFDEF UNICODE}                                             or BASS_UNICODE {$ENDIF});
    until FindNextFile(fh, fd) = false;
  finally
    Windows.FindClose(fh);
  end;
end;

procedure Tbass.free_plugins;
var
  i: integer;
begin

  for i := low(plugins) to High(plugins) do
  begin
    if plugins[i] > 0 then
      BASS_PluginFree(plugins[i]);
  end;

end;

procedure Tbass.stop();
begin
  if not initialized then
    exit;
  BASS_ChannelStop(self.channel);
  BASS_StreamFree(self.channel);
end;

function Tbass.active: dword;
begin
  result := BASS_ChannelIsActive(self.channel);
end;

procedure Tbass.pause();
begin
  if not initialized then
    exit;
  if self.paused then
    BASS_ChannelPlay(self.channel, false)
  else
    BASS_channelpause(self.channel);
  self.paused := not self.paused;
end;

function Tbass.play(filename: string): integer;
var
  orjvol: single;
begin

  if not FileExists(filename) then
  begin
    OutputDebugString(PChar('BASS: file not found: ' + filename));
    exit;
  end;

  BASS_SetDevice(self.currdev);
  self.stopsounds := false;
  orjvol := 0;
  self.streaming := False;
  self.paused := False;
  if BASS_ChannelIsActive(self.channel) <> 0 then
  begin
    BASS_ChannelStop(self.channel);
//if orjvol>0 then BASS_ChannelSetAttribute(self.channel, BASS_ATTRIB_VOL, orjvol);
    BASS_StreamFree(self.channel);
  end;
  self.channel := BASS_StreamCreateFile(FALSE, PChar(filename), 0, 0, 0 {$IFDEF UNICODE}                                             or BASS_UNICODE {$ENDIF}                                             or BASS_STREAM_AUTOFREE or BASS_MUSIC_RAMP or floatable);
//BASS_SetConfig(BASS_CONFIG_ASYNCFILE_BUFFER, input_buffer);
//  BASS_SetConfig(BASS_CONFIG_BUFFER, output_buffer);
  result := round(BASS_ChannelBytes2Seconds(self.channel, BASS_ChannelGetLength(Self.channel, BASS_POS_BYTE)));
//if orjvol>0 then BASS_ChannelSetAttribute(self.channel, BASS_ATTRIB_VOL, orjvol);
  BASS_ChannelPlay(self.channel, true);
  self.currentsource := filename;
end;

procedure Tbass.playextsample(filename: string; const loop: Boolean = false);
var
  newch: HCHANNEL;
  sample: HSAMPLE;
begin

  self.stopsounds := false;
  if not FileExists(filename) then
  begin

    exit;
  end;
  if loop then
    sample := BASS_SampleLoad(false, PChar(filename), 0, 0, 8, BASS_SAMPLE_OVER_POS or BASS_SAMPLE_LOOP)
  else
    sample := BASS_SampleLoad(false, PChar(filename), 0, 0, 8, BASS_SAMPLE_OVER_POS);
  newch := BASS_SampleGetChannel(sample, True);
  BASS_ChannelPlay(newch, true);

//  repeat
  //  sleep(1);
    if self.stopsounds then
    begin
      self.stopsounds := false;
      BASS_ChannelSlideAttribute(newch, BASS_ATTRIB_VOL, 0, volume_slide);
      BASS_ChannelStop(newch);
    end;
//  until BASS_ChannelIsActive(newch) = 0;
 // BASS_SampleFree(sample);

end;

procedure Tbass.setsamplevolume(sample: HSAMPLE; newvolume: single);
var
  info: BASS_SAMPLE;
begin
  BASS_SampleGetInfo(sample, info);
  info.volume := newvolume;
  BASS_SampleSetInfo(sample, info);
end;

procedure Tbass.setvolume(newvolume: integer);
var
  vol: single;
  i: integer;
begin
  vol := newvolume / 100;
  if BASS_ChannelIsActive(self.channel) = 1 then
    BASS_ChannelSlideAttribute(self.channel, BASS_ATTRIB_VOL, vol, volume_slide)
  else
    BASS_ChannelSetAttribute(self.channel, BASS_ATTRIB_VOL, vol);

  for i := 0 to High(self.samples) do
  begin
    setsamplevolume(self.samples[i].ch, vol);
  end;

  self.realvolume := vol;
  self.volume := newvolume;
end;

constructor Tbass.create(rate: integer = 44100);
begin

  if (HiWord(BASS_GetVersion()) <> BASSVERSION) then
  begin
    OutputDebugString(PChar('An incorrect version of BASS.DLL was loaded (2.4 is required)'));
    exit;
  end;

          {
  // check the correct BASS_FX was loaded
  if (HiWord(BASS_FX_GetVersion()) <> BASSVERSION) then
  begin
    OutputDebugString(PChar('An incorrect version of BASS_FX.DLL was loaded (2.4 is required)'));
    exit;
  end;

         }
//Load_BASSDLL(libpath);
//BASS_SetConfig(BASS_CONFIG_ASYNCFILE_BUFFER, input_buffer);
//BASS_SetConfig(BASS_CONFIG_BUFFER, output_buffer);

  BASS_SetConfig(BASS_CONFIG_FLOATDSP, 1);
  rate := 96000;

  if BASS_Init(-1, rate, 0, ahandle, nil) then
  begin  //96000

    //BASS_SetConfig(BASS_CONFIG_ASYNCFILE_BUFFER, input_buffer);
    //BASS_SetConfig(BASS_CONFIG_BUFFER, output_buffer); // amk
    self.currdev := BASS_GetDevice();
    self.setvolume(100);
    samplecount := 0;
    ///////////////////
    //seteq(8, 12, -2, 4);
    //seteq(3, 6, 0, -2);

    ///////////////
    floatable := BASS_StreamCreate(rate, 2, BASS_SAMPLE_FLOAT, nil, nil);
    if (floatable > 0) then
    begin
      BASS_StreamFree(floatable);  //woohoo!
      floatable := BASS_SAMPLE_FLOAT;
    end;

    initialized := True;
  end
  else
    initialized := false;
end;

destructor Tbass.free;
begin
  if initialized then
  begin
    self.stopall;
    BASS_ChannelStop(self.channel);
    BASS_StreamFree(self.channel);
    free_samples;
    free_plugins;
    BASS_Free;
    self.CleanupInstance;
  end;
end;

function Tbass.getfft(): TFFTData;
begin
  BASS_ChannelGetData(self.channel, @self.fftdata, BASS_DATA_FFT1024);
  result := self.fftdata;
end;

end.

