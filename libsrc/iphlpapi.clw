  MEMBER

  PRAGMA('compile(CWUTIL.CLW)')

  MAP
    MODULE('IPHLPAPI LIBRARY')
      iphlp::GetAdaptersInfo(*STRING pAdapterInfo, *ULONG pOutBufLen), ULONG, PROC, RAW, PASCAL, NAME('fptr_GetAdaptersInfo'), DLL
    END

    MODULE('WIN API')
      iphlp::LoadLibrary(*CSTRING szLibFileName), LONG, PASCAL, RAW, NAME('LoadLibraryA')
      iphlp::FreeLibrary(LONG hModule), BOOL, PASCAL, PROC, NAME('FreeLibrary')
      iphlp::GetProcAddress(LONG hModule, *CSTRING szProcName), LONG, PASCAL, RAW, NAME('GetProcAddress')
      iphlp::OutputDebugString(*CSTRING lpOutputString), PASCAL, RAW, NAME('OutputDebugStringA')
    END

    INCLUDE('CWUTIL.INC'),ONCE
  END

  INCLUDE('iphlpapi.inc'), ONCE

szGetAdaptersInfo             CSTRING('GetAdaptersInfo'), STATIC
paGetAdaptersInfo             LONG, NAME('fptr_GetAdaptersInfo')

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
  
iphlp::Trace                  PROCEDURE(STRING pMsg)
sPrefix                         CSTRING('[iphlpapi] ')
szMsg                           &CSTRING
  CODE
  szMsg &= NEW CSTRING(LEN(sPrefix) + 1 + LEN(CLIP(pMsg)) + 1)
  szMsg = sPrefix & CLIP(pMsg)
  iphlp::OutputDebugString(szMsg)
  DISPOSE(szMsg)

TIPAdapterInfo.Construct      PROCEDURE()
szDllName                       CSTRING('iphlpapi')
  CODE
  SELF.hDll = iphlp::LoadLibrary(szDllName)
  IF SELF.hDll
    paGetAdaptersInfo = iphlp::GetProcAddress(SELF.hDll, szGetAdaptersInfo)
  END

  SELF.adapters &= NEW typAdapterInfoQ
  
TIPAdapterInfo.Destruct       PROCEDURE()
  CODE
  IF SELF.hDll
    iphlp::FreeLibrary(SELF.hDll)
  END

  FREE(SELF.adapters)
  DISPOSE(SELF.adapters)

TIPAdapterInfo.GetAdaptersInfo    PROCEDURE()
buf                                 &STRING
adapterInfo                         &IP_ADAPTER_INFO
adapter                             &IP_ADAPTER_INFO
dwRetVal                            ULONG
i                                   ULONG, AUTO
ulOutBufLen                         ULONG, AUTO
  CODE
  FREE(SELF.adapters)
  
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
  
  IF dwRetVal <> 0  !NO_ERROR
    DISPOSE(buf)
    MESSAGE('GetAdaptersInfo failed with error '& dwRetVal)
    RETURN dwRetVal
  END
  
  adapterInfo &= (ADDRESS(buf))
  
  adapter &= adapterInfo
  LOOP WHILE NOT adapter &= NULL
    CLEAR(SELF.adapters)
    SELF.adapters.ComboIndex = adapter.ComboIndex
    SELF.adapters.AdapterName = adapter.AdapterName
    SELF.adapters.Description = adapter.Description
    SELF.adapters.Index = adapter.Index
    SELF.adapters.Type = adapter.Type
    SELF.adapters.IpAddress = adapter.IpAddressList.IpAddress
    SELF.adapters.IpMask = adapter.IpAddressList.IpMask
    SELF.adapters.Gateway = adapter.GatewayList.IpAddress
    SELF.adapters.DhcpEnabled = adapter.DhcpEnabled
    SELF.adapters.DhcpServer = adapter.DhcpServer.IpAddress
    SELF.adapters.DhcpMask = adapter.DhcpServer.IpMask
    SELF.adapters.HaveWins = adapter.HaveWins
    SELF.adapters.PrimaryWinsServer = adapter.PrimaryWinsServer.IpAddress
    SELF.adapters.SecondaryWinsServer = adapter.SecondaryWinsServer.IpAddress
    
    IF NOT adapter.CurrentIpAddress &= NULL
      SELF.adapters.CurrentIpAddress = adapter.CurrentIpAddress.IpAddress
    END
    
    LOOP i = 1 TO adapter.AddressLength
      SELF.adapters.Address = CLIP(SELF.adapters.Address) & ByteToHex(adapter.Address[i])
      IF i < adapter.AddressLength
        SELF.adapters.Address = CLIP(SELF.adapters.Address) & '-'
      END
    END

    ADD(SELF.adapters)
    
    adapter &= (adapter.Next)
  END

  DISPOSE(buf)
  
  RETURN NO_ERROR
  
TIPAdapterInfo.GetAdatperTypeName PROCEDURE(ULONG pType)
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
