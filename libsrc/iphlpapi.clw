!* iphlpapi support
!* v1.02
!* mikeduglas 2016-2023
!* mikeduglas@yandex.ru

  MEMBER

  MAP
    MODULE('IPHLPAPI LIBRARY')
      iphlp::GetAdaptersInfo(*STRING pAdapterInfo, *ULONG pOutBufLen), ULONG, PROC, RAW, PASCAL, NAME('fptr_GetAdaptersInfo'), DLL
    END

    MODULE('WIN API')
      iphlp::LoadLibrary(*CSTRING szLibFileName), LONG, PASCAL, RAW, NAME('LoadLibraryA')
      iphlp::FreeLibrary(LONG hModule), BOOL, PASCAL, PROC, NAME('FreeLibrary')
      iphlp::GetProcAddress(LONG hModule, *CSTRING szProcName), LONG, PASCAL, RAW, NAME('GetProcAddress')
    END

    INCLUDE('printf.inc'),ONCE
  END

  INCLUDE('iphlpapi.inc'), ONCE

!!!region Data types and equates
szGetAdaptersInfo             CSTRING('GetAdaptersInfo'), STATIC
paGetAdaptersInfo             LONG, NAME('fptr_GetAdaptersInfo')

!System error codes
NO_ERROR                      EQUATE(0)
ERROR_BUFFER_OVERFLOW         EQUATE(111)
ERROR_INVALID_DATA            EQUATE(13)
ERROR_INVALID_PARAMETER       EQUATE(87)
ERROR_NO_DATA                 EQUATE(232)
ERROR_NOT_SUPPORTED           EQUATE(50)

time_t                        EQUATE(LONG)

!IP_ADDRESS_STRING             GROUP, TYPE
!_String                         STRING(4 * 4)
!                              END
!
!IP_MASK_STRING                LIKE(IP_ADDRESS_STRING), TYPE

IP_ADDR_STRING                GROUP, TYPE
Next                            LONG        !&IP_ADDR_STRING
IpAddress                       STRING(16)  !LIKE(IP_ADDRESS_STRING)
IpMask                          STRING(16)  !LIKE(IP_MASK_STRING)
Context                         ULONG
                              END

IP_ADAPTER_INFO               GROUP, TYPE
Next                            LONG  !&IP_ADAPTER_INFO
ComboIndex                      ULONG
AdapterName                     STRING(MAX_ADAPTER_NAME_LENGTH + 4)
Description                     STRING(MAX_ADAPTER_DESCRIPTION_LENGTH + 4)
AddressLength                   ULONG
Address                         BYTE, DIM(MAX_ADAPTER_ADDRESS_LENGTH)
Index                           ULONG
Type                            ULONG
DhcpEnabled                     ULONG
CurrentIpAddress                &IP_ADDR_STRING !reserved
IpAddressList                   LIKE(IP_ADDR_STRING)
GatewayList                     LIKE(IP_ADDR_STRING)
DhcpServer                      LIKE(IP_ADDR_STRING)
HaveWins                        BOOL
PrimaryWinsServer               LIKE(IP_ADDR_STRING)
SecondaryWinsServer             LIKE(IP_ADDR_STRING)
LeaseObtained                   time_t
LeaseExpires                    time_t
                              END
!!!endregion

!!!region Helper functions
iphlp::Trace                  PROCEDURE(STRING pMsg)
sPrefix                         STRING('[iphlpapi]')
  CODE
  printd('%z %s', sPrefix, pMsg)
!!!endregion

!!!region TIPHlpApi
TIPHlpApi.Construct           PROCEDURE()
szDllName                       CSTRING('iphlpapi')
  CODE
  SELF.hDll = iphlp::LoadLibrary(szDllName)
  IF SELF.hDll
    paGetAdaptersInfo = iphlp::GetProcAddress(SELF.hDll, szGetAdaptersInfo)
  END
  
TIPHlpApi.Destruct            PROCEDURE()
  CODE
  IF SELF.hDll
    iphlp::FreeLibrary(SELF.hDll)
  END

TIPHlpApi.GetAdaptersInfo     PROCEDURE(*typAdapterInfoQ pAdaptersInfo)
buf                             &STRING
adapterInfo                     &IP_ADAPTER_INFO
adapter                         &IP_ADAPTER_INFO
dwRetVal                        ULONG
i                               ULONG, AUTO
ulOutBufLen                     ULONG, AUTO
  CODE
  FREE(pAdaptersInfo)
  
  IF paGetAdaptersInfo
    !Make an initial call to GetAdaptersInfo to get
    !the necessary size into the ulOutBufLen variable
    buf &= NEW STRING(SIZE(IP_ADAPTER_INFO))
    ulOutBufLen = 0
    dwRetVal = iphlp::GetAdaptersInfo(buf, ulOutBufLen)
    IF dwRetVal = ERROR_BUFFER_OVERFLOW
      DISPOSE(buf)
      buf &= NEW STRING(ulOutBufLen)
      dwRetVal = iphlp::GetAdaptersInfo(buf, ulOutBufLen)
    END
  
    IF dwRetVal <> NO_ERROR
      DISPOSE(buf)
      printd('GetAdaptersInfo failed with error '& dwRetVal)
      RETURN dwRetVal
    END
  
    adapterInfo &= (ADDRESS(buf))
  
    adapter &= adapterInfo
    LOOP WHILE NOT adapter &= NULL
      CLEAR(pAdaptersInfo)
      pAdaptersInfo.ComboIndex = adapter.ComboIndex
      pAdaptersInfo.AdapterName = adapter.AdapterName
      pAdaptersInfo.Description = adapter.Description
      pAdaptersInfo.Index = adapter.Index
      pAdaptersInfo.Type = adapter.Type
      pAdaptersInfo.IpAddress = adapter.IpAddressList.IpAddress
      pAdaptersInfo.IpMask = adapter.IpAddressList.IpMask
      pAdaptersInfo.Gateway = adapter.GatewayList.IpAddress
      pAdaptersInfo.DhcpEnabled = adapter.DhcpEnabled
      pAdaptersInfo.DhcpServer = adapter.DhcpServer.IpAddress
      pAdaptersInfo.DhcpMask = adapter.DhcpServer.IpMask
      pAdaptersInfo.HaveWins = adapter.HaveWins
      pAdaptersInfo.PrimaryWinsServer = adapter.PrimaryWinsServer.IpAddress
      pAdaptersInfo.SecondaryWinsServer = adapter.SecondaryWinsServer.IpAddress
    
      IF NOT adapter.CurrentIpAddress &= NULL
        pAdaptersInfo.CurrentIpAddress = adapter.CurrentIpAddress.IpAddress
      END
    
      LOOP i = 1 TO adapter.AddressLength
        pAdaptersInfo.Address = CLIP(pAdaptersInfo.Address) & printf('%X', adapter.Address[i])
        IF i < adapter.AddressLength
          pAdaptersInfo.Address = CLIP(pAdaptersInfo.Address) & '-'
        END
      END

      ADD(pAdaptersInfo)
    
      adapter &= (adapter.Next)
    END

    DISPOSE(buf)
    RETURN NO_ERROR
  ELSE
    RETURN ERROR_NOT_SUPPORTED
  END

TIPHlpApi.GetAdatperTypeName  PROCEDURE(ULONG pType)
  CODE
  CASE pType
  OF MIB_IF_TYPE_OTHER
    RETURN 'Other'
  OF MIB_IF_TYPE_ETHERNET
    RETURN 'Ethernet'
  OF MIB_IF_TYPE_TOKENRING
    RETURN 'Token Ring'
  OF MIB_IF_TYPE_FDDI
    RETURN 'FDDI'
  OF MIB_IF_TYPE_PPP
    RETURN 'PPP'
  OF MIB_IF_TYPE_LOOPBACK
    RETURN 'Lookback'
  OF MIB_IF_TYPE_SLIP
    RETURN 'Slip'
  OF MIB_IF_TYPE_IEEE80211
    RETURN 'IEEE 802.11'
  ELSE
    RETURN 'Unknown type '& pType
  END
!!!endregion