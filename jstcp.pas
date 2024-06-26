unit jstcp;

interface

uses
  windows, System.Win.ScktComp, Generics.Collections, v8, System.SysUtils,
  XSuperObject, System.Classes;

function listen(port: integer; eid: string; vm: Pv8Engine): integer;

function close(id: integer): integer;

function kick(id: integer; s: NativeInt): integer;

function write(id: integer; s: NativeInt; data: ansistring): integer;

implementation

type
  Tserver = class
  private
    id: integer;
    socket: TServerSocket;
    eid: string;
    vm: Pv8Engine;
    constructor Create(port, id: integer);
    destructor free;
    procedure ServerSocket1ClientRead(Sender: TObject; socket: TCustomWinSocket);
  end;

  {
    Tclient = class
    id: integer;
    socket: TClientSocket;
    eid: string;
    vm: Pv8Engine;
    constructor connect(port, id: integer);
    destructor free;
    procedure ClientSocketRead(Sender: TObject; Socket: TCustomWinSocket);
    end;
  }
var
  id: integer;
  servers: TDictionary<integer, Tserver>;
type
  TBuff = array of Byte;

procedure Tserver.ServerSocket1ClientRead(Sender: TObject; socket: TCustomWinSocket);
var
  X: ISuperObject;
  data: UTF8String;      // chrome uyumlu
  // data:rawbytestring; // judith studio uyumlu
begin
  try
    if socket.Connected = true then
    begin

    SetLength(data, socket.ReceiveBuf(Pointer(nil)^, -1));
    SetLength(data, socket.ReceiveBuf(Pointer(data)^, Length(data)));
    data := trim(data);
    end;

  finally

    X := SO;
    X.I['id'] := TServerSocket(Sender).Tag;
    X.I['socket'] := socket.SocketHandle;
    X.s['ip'] := socket.RemoteAddress;
    X.s['data'] := data;
     // OutputDebugString(pchar(data));
    OutputDebugString(pchar(X.AsJSON(true)));
    vm.eval(self.eid + '(' + pchar(X.AsJSON(true)) + ');');
  end;
end;

constructor Tserver.Create(port, id: integer);
begin
  socket := TServerSocket.Create(nil);
  socket.ServerType := stNonBlocking;
 //   socket.ServerType:=stThreadBlocking;
 //   socket.ThreadCacheSize := 32;
  socket.port := port;
  socket.Tag := id;
  socket.OnClientRead := ServerSocket1ClientRead;
  socket.Active := True;
end;

destructor Tserver.free;
begin
  socket.close;
  socket.free;
end;

function listen(port: integer; eid: string; vm: Pv8Engine): integer;
var
  srv: Tserver;
begin
  srv := Tserver.Create(port, id);
  srv.eid := eid;
  srv.vm := vm;
  servers.Add(id, srv);
  result := id;
  inc(id);
end;

function close(id: integer): integer;
var
  srv: Tserver;
begin
  if servers.TryGetValue(id, srv) then
  begin
    try
      srv.free;
    finally
      servers.Remove(id);
    end;
  end;
end;

function kick(id: integer; s: NativeInt): integer;
var
  I: integer;
  srv: Tserver;
begin
  result := 0;
  if servers.TryGetValue(id, srv) then
  begin
    for I := 0 to srv.socket.socket.ActiveConnections - 1 do
    begin
      if srv.socket.socket.Connections[I].SocketHandle = s then
      begin
        try
          srv.socket.socket.Connections[I].close;
        finally
          result := 1
        end;
        break;
      end;
    end;
  end;
end;

function write(id: integer; s: NativeInt; data: ansistring): integer;
var
  I: integer;
  srv: Tserver;
begin
  result := 0;
  if servers.TryGetValue(id, srv) then
  begin
    for I := 0 to srv.socket.socket.ActiveConnections - 1 do
    begin
      if srv.socket.socket.Connections[I].SocketHandle = s then
      begin
        try
          result := srv.socket.socket.Connections[I].SendText(data);
        finally
        end;
        break;
      end;
    end;
  end;
end;

procedure freeServers;
var
  Item: TPair<integer, Tserver>;
begin
  for Item in servers do
    Item.Value.free;
  servers.Clear;
end;

initialization
  servers := TDictionary<integer, Tserver>.Create;


finalization
  freeServers;
  servers.free;

end.

