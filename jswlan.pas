unit jswlan;

interface

uses
  Windows, SysUtils, nduWlanAPI, nduWlanTypes;

function wScan(): widestring;

implementation

uses
  XSuperObject;

function DOT11_AUTH_ALGORITHM_To_String(Dummy: Tndu_DOT11_AUTH_ALGORITHM): AnsiString;
begin
  Result := '';
  case Dummy of
    DOT11_AUTH_ALGO_80211_OPEN:
      Result := '80211_OPEN';
    DOT11_AUTH_ALGO_80211_SHARED_KEY:
      Result := '80211_SHARED_KEY';
    DOT11_AUTH_ALGO_WPA:
      Result := 'WPA';
    DOT11_AUTH_ALGO_WPA_PSK:
      Result := 'WPA_PSK';
    DOT11_AUTH_ALGO_WPA_NONE:
      Result := 'WPA_NONE';
    DOT11_AUTH_ALGO_RSNA:
      Result := 'RSNA';
    DOT11_AUTH_ALGO_RSNA_PSK:
      Result := 'RSNA_PSK';
    DOT11_AUTH_ALGO_IHV_START:
      Result := 'IHV_START';
    DOT11_AUTH_ALGO_IHV_END:
      Result := 'IHV_END';
  end;
end;

function DOT11_CIPHER_ALGORITHM_To_String(Dummy: Tndu_DOT11_CIPHER_ALGORITHM): AnsiString;
begin
  Result := '';
  case Dummy of
    DOT11_CIPHER_ALGO_NONE:
      Result := 'NONE';
    DOT11_CIPHER_ALGO_WEP40:
      Result := 'WEP40';
    DOT11_CIPHER_ALGO_TKIP:
      Result := 'TKIP';
    DOT11_CIPHER_ALGO_CCMP:
      Result := 'CCMP';
    DOT11_CIPHER_ALGO_WEP104:
      Result := 'WEP104';
    DOT11_CIPHER_ALGO_WPA_USE_GROUP:
      Result := 'WPA_USE_GROUP OR RSN_USE_GROUP';
    //DOT11_CIPHER_ALGO_RSN_USE_GROUP : Result:= 'RSN_USE_GROUP';
    DOT11_CIPHER_ALGO_WEP:
      Result := 'WEP';
    DOT11_CIPHER_ALGO_IHV_START:
      Result := 'IHV_START';
    DOT11_CIPHER_ALGO_IHV_END:
      Result := 'IHV_END';
  end;
end;

function wScan(): widestring;
const
  WLAN_AVAILABLE_NETWORK_INCLUDE_ALL_ADHOC_PROFILES = $00000001;
var
  hClient: THandle;
  dwVersion: DWORD;
  ResultInt: DWORD;
  pInterface: Pndu_WLAN_INTERFACE_INFO_LIST;
  i: Integer;
  j: Integer;
  pAvailableNetworkList: Pndu_WLAN_AVAILABLE_NETWORK_LIST;
  pInterfaceGuid: PGUID;
  SDummy: AnsiString;
  X: ISuperObject;
begin
  ResultInt := WlanOpenHandle(1, nil, @dwVersion, @hClient);
  try
    if ResultInt <> ERROR_SUCCESS then
    begin
      //WriteLn('Error Open CLient' + IntToStr(ResultInt));
      Exit;
    end;

    ResultInt := WlanEnumInterfaces(hClient, nil, @pInterface);
    if ResultInt <> ERROR_SUCCESS then
    begin
      //WriteLn('Error Enum Interfaces ' + IntToStr(ResultInt));
      exit;
    end;
    Result := '[';
    for i := 0 to pInterface^.dwNumberOfItems - 1 do
    begin
      X := SO;
      X.S['name'] := pInterface^.InterfaceInfo[i].strInterfaceDescription;
      X.S['guid'] := GUIDToString(pInterface^.InterfaceInfo[i].InterfaceGuid);

      pInterfaceGuid := @pInterface^.InterfaceInfo[pInterface^.dwIndex].InterfaceGuid;

      ResultInt := WlanGetAvailableNetworkList(hClient, pInterfaceGuid, WLAN_AVAILABLE_NETWORK_INCLUDE_ALL_ADHOC_PROFILES, nil, pAvailableNetworkList);
      if ResultInt <> ERROR_SUCCESS then
      begin
        //WriteLn('Error WlanGetAvailableNetworkList ' + IntToStr(ResultInt));
        Exit;
      end;

      for j := 0 to pAvailableNetworkList^.dwNumberOfItems - 1 do
      begin
        with X.A['networks'].O[j] {Auto Create} do
        begin
          S['ssid'] := PAnsiChar(@pAvailableNetworkList^.Network[j].dot11Ssid.ucSSID);
          i['signal'] := pAvailableNetworkList^.Network[j].wlanSignalQuality;
          s['auth'] := DOT11_AUTH_ALGORITHM_To_String(pAvailableNetworkList^.Network[j].dot11DefaultAuthAlgorithm);
          s['cipher'] := DOT11_CIPHER_ALGORITHM_To_String(pAvailableNetworkList^.Network[j].dot11DefaultCipherAlgorithm);
        end;
      end;
      Result := result + X.AsJSON + ',';
    end;
    if Length(Result)>5 then
    delete(Result, length(Result), 1);
    result := result + ']';
  finally
    WlanCloseHandle(hClient, nil);
  end;
end;

end.

