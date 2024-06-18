unit hwutil;

interface

uses
windows,
setupapilite,
sysutils;

function EnumSerialCommWithFriendlyName(const S: TStrings): Integer;

implementation


function EnumSerialCommWithFriendlyName(const S: TStrings): Integer;
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
begin

  Result := 0;

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
                  if TryStrToInt(Copy(S2,4,Length(S2)),PortNo) = True then
                  begin
                    S.AddObject(S1,Pointer(PortNo));
                    if Result < PortNo then
                    begin
                      Result := PortNo;
                    end;
                  end;
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
