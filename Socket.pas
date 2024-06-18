unit Socket;

interface

uses
  Windows, Winsock, sysutils;

type
  TClientSocket = class(TObject)
  private
    FAddress: PAnsiChar;
    FData: pointer;
    FTag: integer;
    FConnected: boolean;
    _sent: Int64;
    //_rcv: Int64;
    function GetLocalAddress: string;
    function GetLocalPort: integer;
    function GetRemoteAddress: string;
    function GetRemotePort: integer;
  protected
    FSocket: TSocket;
  public
    procedure Connect(Address: AnsiString; Port: integer);
    property Connected: boolean read FConnected;
    property Data: pointer read FData write FData;
    destructor Destroy; override;
    procedure Disconnect(const code: integer = 0);
    procedure Idle(Seconds: integer);
    property LocalAddress: string read GetLocalAddress;
    property LocalPort: integer read GetLocalPort;
    function ReceiveBuffer(var Buffer; BufferSize: integer): integer;
    function ReceiveLength: integer;
    function ReceiveString: UTF8String;
    property RemoteAddress: string read GetRemoteAddress;
    property RemotePort: integer read GetRemotePort;
    function SendBuffer(var Buffer; BufferSize: integer): integer;
    function SendString(const Buffer: UTF8String): integer;
    property Socket: TSocket read FSocket;
    property Tag: integer read FTag write FTag;
    function SentTTL: int64;
    function RecvTTL: int64;
  end;

var
  WSAData: TWSAData;

function GetIPFromHost(const HostName: AnsiString): AnsiString;

implementation

function TClientSocket.SentTTL: int64;
begin
  result := gettickcount64 - _sent;
end;

function TClientSocket.RecvTTL: int64;
begin
//  result := gettickcount64 - _rcv;
end;

function GetIPFromHost(const HostName: AnsiString): AnsiString;
type
  TaPInAddr = array[0..10] of PInAddr;

  PaPInAddr = ^TaPInAddr;
var
  phe: PHostEnt;
  pptr: PaPInAddr;
  i: Integer;
begin
  Result := '';
  phe := GetHostByName(PAnsiChar(HostName));
  if phe = nil then
    Exit;
  pptr := PaPInAddr(phe^.h_addr_list);
  i := 0;
  while pptr^[i] <> nil do
  begin
    Result := inet_ntoa(pptr^[i]^);
    Inc(i);
  end;
end;

procedure TClientSocket.Connect(Address: AnsiString; Port: integer);
var
  SockAddrIn: TSockAddrIn;
  HostEnt: PHostEnt;
  OptVal: DWORD;
  timeout: integer;
begin
  Disconnect;
  FAddress := PAnsiChar(AnsiString(GetIPFromHost(Address)));
  if FAddress = '' then
    exit;

  FSocket := Winsock.socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
  SockAddrIn.sin_family := AF_INET;
  SockAddrIn.sin_port := htons(Port);
  SockAddrIn.sin_addr.s_addr := inet_addr(FAddress);
  if SockAddrIn.sin_addr.s_addr = INADDR_NONE then
  begin
    HostEnt := gethostbyname(PAnsiChar(FAddress));
    if HostEnt = nil then
    begin
      Exit;
    end;
    SockAddrIn.sin_addr.s_addr := Longint(PLongint(HostEnt^.h_addr_list^)^);
  end;
  Winsock.Connect(FSocket, SockAddrIn, SizeOf(SockAddrIn));
  FConnected := True;
  //_sent := gettickcount64;
  //_rcv := gettickcount64;
  OptVal := 1;
  timeout := 15000;
 setsockopt(FSocket, SOL_SOCKET, SO_KEEPALIVE, PAnsiChar(@OptVal), SizeOf(OptVal));
  SetSockOpt(FSocket, SOL_SOCKET, SO_RCVTIMEO, @timeout, SizeOf(timeout));
  SetSockOpt(FSocket, SOL_SOCKET, SO_SNDTIMEO, @timeout, SizeOf(timeout));
end;

procedure TClientSocket.Disconnect(const code: integer = 0);
begin
  outputdebugstring(pwidechar(inttostr(code)));

  closesocket(FSocket);
  FConnected := False;
end;

function TClientSocket.GetLocalAddress: string;
var
  SockAddrIn: TSockAddrIn;
  Size: integer;
begin
  Size := sizeof(SockAddrIn);
  getsockname(FSocket, SockAddrIn, Size);
  Result := inet_ntoa(SockAddrIn.sin_addr);
end;

function TClientSocket.GetLocalPort: integer;
var
  SockAddrIn: TSockAddrIn;
  Size: Integer;
begin
  Size := sizeof(SockAddrIn);
  getsockname(FSocket, SockAddrIn, Size);
  Result := ntohs(SockAddrIn.sin_port);
end;

function TClientSocket.GetRemoteAddress: string;
var
  SockAddrIn: TSockAddrIn;
  Size: Integer;
begin
  Size := sizeof(SockAddrIn);
  getpeername(FSocket, SockAddrIn, Size);
  Result := inet_ntoa(SockAddrIn.sin_addr);
end;

function TClientSocket.GetRemotePort: integer;
var
  SockAddrIn: TSockAddrIn;
  Size: Integer;
begin
  Size := sizeof(SockAddrIn);
  getpeername(FSocket, SockAddrIn, Size);
  Result := ntohs(SockAddrIn.sin_port);
end;

procedure TClientSocket.Idle(Seconds: integer);
var
  FDset: TFDset;
  TimeVal: TTimeVal;
begin
  if Seconds = 0 then
  begin
    FD_ZERO(FDset);
    FD_SET(FSocket, FDset);
    select(0, @FDset, nil, nil, nil);
  end
  else
  begin
    TimeVal.tv_sec := Seconds;
    TimeVal.tv_usec := 0;
    FD_ZERO(FDset);
    FD_SET(FSocket, FDset);
    select(0, @FDset, nil, nil, @TimeVal);
  end;
end;

function TClientSocket.ReceiveLength: integer;
begin
  Result := ReceiveBuffer(pointer(nil)^, -1);
end;

function TClientSocket.ReceiveBuffer(var Buffer; BufferSize: integer): integer;
begin
  if BufferSize = -1 then
  begin
    if ioctlsocket(FSocket, FIONREAD, Longint(Result)) = SOCKET_ERROR then
    begin
      Result := SOCKET_ERROR;
      Disconnect(1);
    end;
  end
  else
  begin
    Result := recv(FSocket, Buffer, BufferSize, 0);
    if Result = 0 then
    begin
      //Disconnect(2);
    end;
    if Result = SOCKET_ERROR then
    begin
      Result := WSAGetLastError;
      if Result = WSAEWOULDBLOCK then
      begin
        Result := 0;
      end
      else
      begin
        Disconnect(3);
      end;
    end;
  end;
end;

function TClientSocket.ReceiveString: UTF8String;
begin
  SetLength(Result, ReceiveBuffer(pointer(nil)^, -1));
  SetLength(Result, ReceiveBuffer(pointer(Result)^, Length(Result)));
  //_rcv := gettickcount64;
end;

function TClientSocket.SendBuffer(var Buffer; BufferSize: integer): integer;
var
  ErrorCode: integer;
begin
  Result := send(FSocket, Buffer, BufferSize, 0);
  if Result = SOCKET_ERROR then
  begin
    ErrorCode := WSAGetLastError;
    if (ErrorCode = WSAEWOULDBLOCK) then
    begin
      Result := -1;
    end
    else
    begin
      Disconnect(4);
    end;
  end;
end;

function TClientSocket.SendString(const Buffer: UTF8String): integer;
begin
  Result := SendBuffer(pointer(Buffer)^, Length(Buffer));
//  _sent := gettickcount64;
end;

destructor TClientSocket.Destroy;
begin
  inherited Destroy;
  Disconnect(5);
end;

initialization
  WSAStartup($0202, WSAData);


finalization
  WSACleanup;

end.

