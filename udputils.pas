unit udputils;

interface

function udpSEND(
  ip   : ansistring;
  port : integer;
  msg  : ansistring ) : Boolean;

function udpListen(
  eid  : string;
  port : Word ) : integer;

function udpStop( id : integer ) : Boolean;

implementation

uses
  windows,
  WinSock,
  sysutils,
  classes,
  XSuperObject,
  entrypoint,
  wmipc;

var
  instances : array of Boolean;
  eids : array of string;
  inscount : integer;

const
  CR = #13;
  LF = #10;
  CRLF = CR + LF;
  BUFFER_SIZE = 64 * 1024; // 64 Kilobytes

procedure UDPLoop(
  port : Word;
  id   : integer );
  var
    S : TSocket;
    Addr : TSockaddr;
    AddrSize : integer;
    FDSet : TFDSet;
    TimeVal : TTimeVal;
    Buffer : PAnsiChar;
    i : integer;
    X : ISuperObject;
  begin
    S := WinSock.Socket( AF_INET, SOCK_DGRAM, IPPROTO_IP );
    if S = INVALID_SOCKET
    then
      Exit;
    with Addr do
    begin
      sin_family := AF_INET;
      sin_port := htons( port );
      sin_addr.s_addr := Inet_Addr( PAnsiChar( '0.0.0.0' ) );
    end;
    if Bind( S, Addr, SizeOf( Addr ) ) = SOCKET_ERROR
    then
    begin
      CloseSocket( S );
      wm_sendstringex( ahandle, ahandle,
        pwidechar( '~eval=' + eids[ id ] + '(false);' + eids[ id ] +
        '=undefined;' ) );
      sleep( 1000 );
      Exit;
    end;
    GetMem( Buffer, BUFFER_SIZE );
    try
      while instances[ id ] = true do
      begin
        TimeVal.tv_sec := 0;
        TimeVal.tv_usec := 500;
        FD_ZERO( FDSet );
        FD_SET( S, FDSet );
        if Select( 0, @FDSet, nil, nil, @TimeVal ) > 0
        then
        begin
          AddrSize := SizeOf( Addr );
          FillChar( Buffer^, BUFFER_SIZE, #0 );
          i := Recvfrom( S, Buffer^, BUFFER_SIZE, 0, sockaddr_in( Addr ),
            AddrSize );
          if i <> SOCKET_ERROR
          then
          begin
            X := SO;
            X.i[ 'id' ] := id;
            X.S[ 'ip' ] := inet_ntoa( Addr.sin_addr );
            X.S[ 'data' ] := Copy( ansistring( Buffer ), 1, i );
            wm_sendstringex( ahandle, ahandle,
              pwidechar( '~eval=' + eids[ id ] + '(' + X.AsJSON( ) + ');' ) );
          end;
        end;
        sleep( 5 );
      end;
    finally
      FreeMem( Buffer );
    end;
    CloseSocket( S );
  end;

function udpListen(
  eid  : string;
  port : Word ) : integer;
  var
    id : integer;
    WSAData : TWSAData;
    T : TThread;
  begin
    id := Length( instances );
    SetLength( instances, id + 1 );
    SetLength( eids, id + 1 );
    instances[ id ] := true;
    eids[ id ] := eid;
    T := TThread.CreateAnonymousThread(
      procedure
        begin
          FillChar( WSAData, SizeOf( WSAData ), 0 );
          if WSAStartup( MAKEWORD( 1, 1 ), WSAData ) = 0
          then
            try
              try
                UDPLoop( port, id );
              except
              end;
            finally
              WSACleanup( );
            end;
        end );
    T.FreeOnTerminate := true;
    T.Start;

  end;

function udpStop( id : integer ) : Boolean;
  begin
    if id > Length( instances )
    then
    begin
      result := False;
      Exit;
    end;

    instances[ id ] := False;
    wm_sendstringex( ahandle, ahandle,
      pwidechar( '~eval=' + eids[ id ] + '=undefined;' ) );
    eids[ id ] := '';
    result := true;
  end;

function udpSEND(
  ip   : ansistring;
  port : integer;
  msg  : ansistring ) : Boolean;
  var
    SendAddr : TSockaddr;
    SendRes : integer;
    fSendSocket : TSocket;
    WSAData : TWSAData;
    res : DWORD;
  begin
    if WSAStartup( $101, WSAData ) <> 0
    then
    begin
      result := False;
      Exit;
    end;

    fSendSocket := Socket( AF_INET, SOCK_DGRAM, IPPROTO_UDP );
    if fSendSocket = INVALID_SOCKET
    then
    begin
      result := False;
      Exit;
    end;

    FillChar( SendAddr.sin_zero, SizeOf( SendAddr.sin_zero ), 0 );
    SendAddr.sin_family := AF_INET;
    SendAddr.sin_port := htons( port );

    SendAddr.sin_addr.s_addr := Inet_Addr( PAnsiChar( ip ) );
    SendRes := sendto( fSendSocket, msg[ 1 ], Length( msg ), 0, SendAddr,
      SizeOf( SendAddr ) );

    CloseSocket( fSendSocket );
    WSACleanup( );
    ZeroMemory( @WSAData, 0 );
    ZeroMemory( @fSendSocket, 0 );
    FillChar( SendAddr.sin_zero, SizeOf( SendAddr.sin_zero ), 0 );
    ZeroMemory( @SendAddr, 0 );
    ZeroMemory( @msg, 0 );
    result := true;
  end;

initialization

SetLength( instances, 0 );
SetLength( eids, 0 );
inscount := 0;

finalization

SetLength( instances, 0 );
SetLength( eids, 0 );

inscount := 0;

end.
