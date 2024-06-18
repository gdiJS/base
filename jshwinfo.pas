unit jshwinfo;

interface

uses
  windows, SetupApi, xsuperobject, DeviceHelper, crc32, System.SysUtils;

type
  Tdevice = packed record
    id: DWORD;
    path: string;
    name: string;
  end;

  Tdevices = array of Tdevice;

const
  PINVALID_HANDLE_VALUE = Pointer(INVALID_HANDLE_VALUE);

function listdevices: Tdevices;

function DevicesAsJson(meta: Tdevices): string;

implementation

function DevicesAsJson(meta: Tdevices): string;
begin
  result := TJSON.Stringify<Tdevices>(meta);
end;

function listdevices: Tdevices;
var
  dwIndex: DWORD;
  DeviceInfoData: SP_DEVINFO_DATA;
  DeviceName, DeviceClassName: string;
  DeviceClassesCount, DevicesCount: Integer;
  hAllDevices: HDEVINFO;
  DeviceHelper: TDeviceHelper;
  z: Integer;
var
  dwFlags: DWORD;
begin
  DeviceHelper := TDeviceHelper.Create;
  dwFlags := dwFlags or DIGCF_ALLCLASSES or DIGCF_PRESENT;
  hAllDevices := SetupDiGetClassDevsExA(nil, nil, 0, dwFlags, nil, nil, nil);
  if hAllDevices = PINVALID_HANDLE_VALUE then
  begin
      // err
    exit;
  end;
  DeviceHelper.DeviceListHandle := hAllDevices;

  SetLength(result, 0);
  try
    dwIndex := 0;
    DeviceClassesCount := 0;
    DevicesCount := 0;

    ZeroMemory(@DeviceInfoData, SizeOf(SP_DEVINFO_DATA));
    DeviceInfoData.cbSize := SizeOf(SP_DEVINFO_DATA);

    while SetupDiEnumDeviceInfo(hAllDevices, dwIndex, DeviceInfoData) do
    begin
      DeviceHelper.DeviceInfoData := DeviceInfoData;
      DeviceName := DeviceHelper.FriendlyName;
      DeviceClassName := DeviceHelper.HardwareID;
      if DeviceName = '' then
        DeviceName := DeviceHelper.Description;
      Inc(dwIndex);
      if (DeviceName <> '') and (Pos('\', DeviceClassName) > 0) then
      begin
        z := Length(result);
        SetLength(result, z + 1);
        result[z].path := DeviceClassName;
        result[z].name := DeviceName;
        result[z].id := CalcStringCRC32(DeviceClassName + DeviceName);
      end;
    end;
  finally
    DeviceHelper.Free;
    SetupDiDestroyDeviceInfoList(hAllDevices);
    ZeroMemory(@DeviceInfoData, SizeOf(SP_DEVINFO_DATA));
  end;
end;

initialization
  LoadsetupAPI;

finalization
  UnloadSetupApi;

end.

