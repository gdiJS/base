unit SetupApiHelper;

interface
uses
windows,
sysutils;

type
  Tport = packed record
   name:string;
   desc:string;
   busy:Boolean;
end;
Tports = array of Tport;

function EnumSerialPorts: Tports;
implementation

uses
stringtools,
SetupApiLite;

function EnumSerialPorts: Tports;
var
  Guid: TGUID;
  Size: DWORD;
  hDevInf: HDEVINFO;
  Index: DWORD;
  DevInfoData: SP_DEVINFO_DATA;
  S1: String;
  hRegKey: HKEY;
  S2: String;
  RegType: DWORD;
  PortNo: Integer;
  i:integer;
  hc:Thandle;
begin
 Result := 0;
 SetLength(Result,0);
  Size := 0;
  if SetupDiClassGuidsFromName('Ports',@Guid,1,Size) = False then
  begin
    RaiseLastOSError;
  end;

  hDevInf := SetupDiGetClassDevs(@Guid,nil,0,DIGCF_PRESENT);
  if hDevInf = INVALID_HANDLE_VALUE then
  begin
    RaiseLastOSError;
  end;

  try
    Index := 0;
    while True do
    begin
      FillChar(DevInfoData,SizeOf(DevInfoData),0);
      DevInfoData.cbSize := SizeOf(DevInfoData);
      if SetupDiEnumDeviceInfo(hDevInf,Index,DevInfoData) = False then
      begin
        Break;
      end;

      SetupDiGetDeviceRegistryProperty(hDevInf,DevInfoData,SPDRP_FRIENDLYNAME,
                                       nil,nil,0,Size);
      SetLength(S1,(Size + SizeOf(Char)) div SizeOf(Char));

      if SetupDiGetDeviceRegistryProperty(hDevInf,DevInfoData,SPDRP_FRIENDLYNAME,
                                          nil,PChar(S1),Size,Size) = True then
      begin
        SetLength(S1,StrLen(PChar(S1)));
        hRegKey := SetupDiOpenDevRegKey(hDevInf,DevInfoData,DICS_FLAG_GLOBAL,0,DIREG_DEV,KEY_READ);
        if hRegKey <> INVALID_HANDLE_VALUE then
        begin
          try
            if RegQueryInfoKey(hRegKey,nil,nil,nil,nil,nil,nil,nil,nil,
                               @Size,nil,nil) = ERROR_SUCCESS then
            begin
              SetLength(S2,(Size + SizeOf(Char)) div SizeOf(Char));
              if (RegQueryValueEx(hRegKey,'PortName',nil,@RegType,Pointer(PChar(S2)),
                                  @Size) = ERROR_SUCCESS) and
                 (RegType = REG_SZ) then
              begin
                SetLength(S2,StrLen(PChar(S2)));
                if CompareText(Copy(S2,1,3),'COM') = 0 then
                begin
                i:=Length(Result);
                SetLength(Result,i+1);
                if ParseBracket(S1)=S2 then S1:=trim(SearchAndReplace(S1,'('+S2+')',''));
                result[i].name:=S2;
                result[i].desc:=S1;
                hc:=CreateFile(pchar('\\.\'+S2+#0),
                                      GENERIC_READ or GENERIC_WRITE,
                                      0,
                                      nil,
                                      OPEN_EXISTING,
                                      FILE_ATTRIBUTE_NORMAL,
                                      0);
                       if hc <> INVALID_HANDLE_VALUE then begin
                       CloseHandle(hc);
                       result[i].busy:= false;
                       end
                       else result[i].busy:= true;

                end;
              end;
            end;

          finally
            RegCloseKey(hRegKey);
          end;
        end;
      end;

      Index := Index + 1;
    end;

  finally
    SetupDiDestroyDeviceInfoList(hDevInf);
  end;

end;

end.