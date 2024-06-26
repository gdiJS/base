unit shmem;

interface
uses
  SysUtils, Windows, threads;

type
  TCallbackProcedure = procedure(msg:ansistring) of object;

  Tshmemclient = class
  SharedMemHandle: THandle;
  SharedMemPtr: Pointer;
  EventHandle: THandle;
  buffer:ansistring;
  ready:boolean;
  procedure send(MsgToSend:ansistring);
  constructor create(name:ansistring;SharedMemSize:integer=4096);
  destructor free;
  procedure error(content:ansistring);
end;

implementation

{ name is required, size is optional}
constructor Tshmemclient.create(name:ansistring;SharedMemSize:integer=4096);
begin
    SharedMemHandle := OpenFileMapping(FILE_MAP_WRITE, False, pwidechar(name));
    if SharedMemHandle = 0 then error('Failed to open shared memory');

    SharedMemPtr := MapViewOfFile(SharedMemHandle, FILE_MAP_WRITE, 0, 0, SharedMemSize);
    if SharedMemPtr = nil then error('Failed to map shared memory');

    EventHandle := OpenEvent(EVENT_MODIFY_STATE, False, pwidechar(name+'_'));
    if EventHandle = 0 then error('Failed to open event');
  ready:=true;
end;

procedure Tshmemclient.send(MsgToSend:ansistring);
begin
if not ready then error('engine not initialized');

buffer:=ansistring(MsgToSend);
if buffer <> '' then begin
StrPCopy(PAnsiChar(SharedMemPtr), buffer);
SetEvent(EventHandle);
end;
end;

destructor Tshmemclient.free;
begin
   if SharedMemPtr <> nil then
      UnmapViewOfFile(SharedMemPtr);

    if SharedMemHandle <> 0 then
      CloseHandle(SharedMemHandle);

    if EventHandle <> 0 then
      CloseHandle(EventHandle);

end;


procedure Tshmemclient.error(content:ansistring);
begin
 outputdebugstringW(pwidechar('shmem: '+content));
end;

end.
