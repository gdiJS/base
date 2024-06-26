unit mod_tts;

interface

uses
  windows, classes,SpeechLib_TLB, ActiveX, system.hash, Math, sysutils;

const
  sentencepausemin = 100;
  sentencepausemax = 1000;

type
  Tsapi = class
    tag: integer;
    speaking: Boolean;
    active: Boolean;
    predelay: integer;
    postdelay: integer;
    function SetVoice(name: string): integer;
    procedure enumvoices(list: TStringList);
    function render(sentence, path: string): string;
    function isvoiceinstalled(vname: string): Boolean;
    procedure speak(sentence:string);
  published
    constructor create;
    destructor free;
  private
    speaker: string;
    SpFileStream1: TSpFileStream;
    SpVoice1: TSpVoice;
    voice: ISpeechObjectToken;
    voices: ISpeechObjectTokens;
  end;

implementation

procedure debug(str: string);
begin
  OutputDebugStringA(Pansichar(AnsiString(str)));
end;

function Tsapi.isvoiceinstalled(vname: string): Boolean;
var
  i: integer;
  voicelist: Tstringlist;
begin
  result := False;
  vname := trim((vname));
  voicelist := TStringlist.create;
  self.enumvoices(voicelist);

  if voicelist.Count > 0 then
  begin
    for i := 0 to voicelist.count - 1 do
    begin
      if ansipos(vname, trim(voicelist.Strings[i])) > 0 then
      begin
        result := True;
        break;
      end;
    end;
  end;
  voicelist.free;
end;

procedure Tsapi.enumvoices(list: TStringList);
var
  I: Integer;
  xSOToken: ISpeechObjectToken;
  xSOTokens: ISpeechObjectTokens;
  xspvoice: TSpVoice;
begin
  xspvoice := TSpVoice.Create(nil);
  xspvoice.EventInterests := SVEAllEvents;
  xSOTokens := xspvoice.GetVoices('', '');
  for I := 0 to xSOTokens.Count - 1 do
  begin
    xSOToken := xSOTokens.Item(I);
    list.Add(xSOToken.GetDescription(0));
    xSOToken._AddRef;
  end;
  xspvoice.Free;
end;

function _md5(str: string): string;
begin
  Result := THashMD5.GetHashString(str);
end;


procedure Tsapi.speak(sentence:string);
var
  hash: string;
  filepath: string;
begin
  if not Assigned(Self) then
    exit;
  try
    spvoice1.speak('<volume level="80"/><rate absspeed="0">' + (sentence), 0);
  except
    on e: exception do
    begin
      OutputDebugString(PChar(e.Message));
    end;
  end;
end;

function Tsapi.render(sentence, path: string): string;
var
  hash: string;
  filepath: string;
begin
  if not Assigned(Self) then
    exit;

  if not directoryexists(path) then
  begin
    result := 'path_error';
    debug('path error:' + path);
    exit;
  end;

  try
    hash := lowercase(_md5(self.speaker + sentence));
    filepath := path + hash + '.wav';
    if fileexists(filepath) then
    begin
      result := filepath;
      debug('second cache hit:' + filepath);
      exit;
    end;

    SpFileStream1.open(filepath, SSFMCreateForWrite, false);
    SpVoice1.AudioOutputStream := SPFileStream1.DefaultInterface;
    spvoice1.speak('<volume level="80"/><rate absspeed="0">' + (sentence), 0);
    SPFileStream1.Close;
    Result := filepath;
  except
    on e: exception do
    begin
      OutputDebugString(PChar(e.Message));
    end;
  end;

  if not FileExists(filepath) then
  begin
    result := 'api_error';
    exit;
  end;

end;

constructor Tsapi.create;
begin
  CoInitialize(nil);
  predelay := 0;
  postdelay := 0;

  SpFileStream1 := TSpFilestream.Create(nil);
  SPVoice1 := TSpVoice.Create(nil);
  SPVoice1.EventInterests := SVEAllEvents;
  self.voices := SpVoice1.GetVoices('', '');
  if self.voices.count <= 0 then
  begin
    debug('there is no tts voice installed on this system');
    active := False;
    exit;
  end;
  SPFileStream1.Format.Type_ := SAFT44kHz16BitStereo;
  self.speaker := self.voices.Item(0).GetDescription(0);
  active := true;
end;

function Tsapi.SetVoice(name: string): integer;
var
  i: integer;
begin

  for i := 0 to self.voices.Count - 1 do
  begin
    self.voice := self.voices.Item(i);
    if ansipos(((name)), (Self.voice.GetDescription(0))) > 0 then
    begin
      debug('voice set: ' + name);
      self.voice._AddRef;
      Break;
    end;
    self.voice._AddRef;
  end;
  SpVoice1.Voice := self.voice;
  self.speaker := Self.voice.GetDescription(0);
  debug('character set to ' + self.speaker);
end;

destructor Tsapi.free;
begin
  try
    SpFileStream1.Free;
    SPVoice1.Free;
    CoUnInitialize;

  except
    on e: exception do
    begin
      //judithcore_reporterror(3, '(Tsapi.free) ' + e.Message);
    end;
  end;

end;

end.

