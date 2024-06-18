unit setupapilite;

interface

uses
windows;

{ Setup APIs }
type
  { HDEVINFO }
  HDEVINFO = THandle;
  {$EXTERNALSYM HDEVINFO}

  { SP_DEVINFO_DATA }
  SP_DEVINFO_DATA = packed record
    cbSize: DWORD;
    ClassGuid: TGUID;
    DevInst: DWORD;
    Reserved: ULONG_PTR;
  end;
  {$EXTERNALSYM SP_DEVINFO_DATA}

const
  { Flags for SetupDiGetClassDevs }
  DIGCF_PRESENT         = $00000002;
  {$EXTERNALSYM DIGCF_PRESENT}

  { Property for SetupDiGetDeviceRegistryProperty }
  SPDRP_DEVICEDESC      = $00000000;
  {$EXTERNALSYM SPDRP_DEVICEDESC}
  SPDRP_FRIENDLYNAME    = $0000000C;
  {$EXTERNALSYM SPDRP_FRIENDLYNAME}

  { Scope for SetupDiOpenDevRegKey }
  DICS_FLAG_GLOBAL      = $00000001;
  {$EXTERNALSYM DICS_FLAG_GLOBAL}

  { KeyType for SetupDiOpenDevRegKey }
  DIREG_DEV             = $00000001;
  {$EXTERNALSYM DIREG_DEV}

{ SetupDiClassGuidsFromName }
function SetupDiClassGuidsFromName(const ClassName: PChar;
                                   ClassGuidList: PGUID;
                                   ClassGuidListSize: DWORD;
                                   var RequiredSize: DWORD): BOOL; stdcall;
  external 'SetupApi.dll' name
{$IFDEF UNICODE}
  'SetupDiClassGuidsFromNameW';
{$ELSE}
  'SetupDiClassGuidsFromNameA';
{$ENDIF}
{$EXTERNALSYM SetupDiClassGuidsFromName}

{ SetupDiGetClassDevs }
function SetupDiGetClassDevs(ClassGuid: PGUID;
                             const Enumerator: PChar;
                             hwndParent: HWND;
                             Flags: DWORD): HDEVINFO; stdcall;
  external 'SetupApi.dll' name
{$IFDEF UNICODE}
  'SetupDiGetClassDevsW';
{$ELSE}
  'SetupDiGetClassDevsA';
{$ENDIF}
{$EXTERNALSYM SetupDiGetClassDevs}

{ SetupDiDestroyDeviceInfoList }
function SetupDiDestroyDeviceInfoList(DeviceInfoSet: HDEVINFO): BOOL; stdcall;
  external 'SetupApi.dll' name 'SetupDiDestroyDeviceInfoList';
{$EXTERNALSYM SetupDiDestroyDeviceInfoList}

{ SetupDiEnumDeviceInfo }
function SetupDiEnumDeviceInfo(DeviceInfoSet: HDEVINFO;
                               MemberIndex: DWORD;
                               var DeviceInfoData: SP_DEVINFO_DATA): BOOL; stdcall;
  external 'SetupApi.dll' name 'SetupDiEnumDeviceInfo';
{$EXTERNALSYM SetupDiEnumDeviceInfo}

{ SetupDiGetDeviceRegistryProperty }
function SetupDiGetDeviceRegistryProperty(DeviceInfoSet: HDEVINFO;
                                          const DeviceInfoData: SP_DEVINFO_DATA;
                                          Prop: DWORD;
                                          PropertyRegDataType: PDWORD;
                                          PropertyBuffer: Pointer;
                                          PropertyBufferSize: DWORD;
                                          var RequiredSize: DWORD): BOOL; stdcall;
  external 'SetupApi.dll' name
{$IFDEF UNICODE}
  'SetupDiGetDeviceRegistryPropertyW';
{$ELSE}
  'SetupDiGetDeviceRegistryPropertyA';
{$ENDIF}
{$EXTERNALSYM SetupDiGetDeviceRegistryProperty}

{ SetupDiOpenDevRegKey }
function SetupDiOpenDevRegKey(DeviceInfoSet: HDEVINFO;
                              var DeviceInfoData: SP_DEVINFO_DATA;
                              Scope: DWORD;
                              HwProfile: DWORD;
                              KeyType: DWORD;
                              samDesired: REGSAM): HKEY; stdcall;
  external 'SetupApi.dll' name 'SetupDiOpenDevRegKey';
{$EXTERNALSYM SetupDiOpenDevRegKey}

implementation

end.
