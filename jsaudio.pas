unit jsaudio;

interface

uses
  windows, Generics.Collections, System.SysUtils, bass, bass_obj;

function audio_init(rate: integer): integer;

function audio_close(id: integer): integer;

function audio_loadsample(id: Integer; filename, tag: string): integer;

function audio_playsample(id: integer; tag: string): integer;

function audio_speech(id: integer; filename: string): integer;

function audio_stream(id: integer; filename: string): integer;

procedure freeAll;

implementation

uses
  entrypoint, classes;

var
  id: integer;
  servers: TDictionary<integer, TBass>;

function audio_init(rate: integer): integer;
var
  srv: Tbass;
begin
  inc(ID);
  result := ID;
  srv := Tbass.create();
  //srv.init_plugins(root + libpath + '\codecs\');
  servers.Add(ID, srv);
end;

function audio_close(id: integer): integer;
var
  srv: Tbass;
begin
  if servers.TryGetValue(id, srv) then
  begin
    srv.free;
    servers.Remove(id);
    Result := 1;
  end;
end;

function audio_loadsample(id: Integer; filename, tag: string): integer;
var
  srv: Tbass;
begin
  if servers.TryGetValue(id, srv) then
  begin
    srv.loadsample(filename, tag);
    Result := 1;
  end
  else
    result := 0;
end;

function audio_speech(id: integer; filename: string): integer;
var
  srv: Tbass;
begin
  if not fileexists(filename) then
  begin
    result := 0;
    exit;
  end;

  if servers.TryGetValue(id, srv) then
  begin
    result := srv.play_dsp(filename);
  end;
end;

function audio_stream(id: integer; filename: string): integer;
var
  srv: Tbass;
begin
  if not fileexists(filename) then
  begin
    OutputDebugString(PChar('BASS: file not found: ' + filename));
    result := 0;
    exit;
  end;

  if servers.TryGetValue(id, srv) then
  begin
    result := srv.play(filename);
  end;
end;

function audio_playsample(id: integer; tag: string): integer;
var
  srv: Tbass;
begin
  if servers.TryGetValue(id, srv) then
  begin
    Result := srv.playsample(tag);
  end;
end;

procedure freeAll;
var
  Item: TPair<integer, Tbass>;
begin
  for Item in servers do
    Item.Value.free;
  servers.Clear;
end;

initialization
  servers := TDictionary<integer, TBass>.Create;

finalization
  freeAll;
  servers.Free;

end.

