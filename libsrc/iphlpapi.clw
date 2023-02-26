!* iphlpapi support
!* v1.03
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

    Get_IP_ADDR_STRING_Count(CONST *IP_ADDR_STRING pList), LONG, PRIVATE    !- get a number of entries in a linked-list of IPv4 addresses.
    FormatAddress(*BYTE[] pAddress, ULONG pAddressLength), STRING, PRIVATE  !- format an address to XX-XX-XX-XX-XX-XX string
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
!_String                         STRING(4 * 4)  !xxx.xxx.xxx.xxx
!                              END
!
!IP_MASK_STRING                LIKE(IP_ADDRESS_STRING), TYPE

IP_ADDR_STRING                GROUP, TYPE
Next                            LONG        !&IP_ADDR_STRING
IpAddress                       STRING(16)  !LIKE(IP_ADDRESS_STRING)
IpMask                          STRING(16)  !LIKE(IP_MASK_STRING)
Context                         ULONG
                              END

!https://learn.microsoft.com/en-us/windows/win32/api/iptypes/ns-iptypes-ip_adapter_info
IP_ADAPTER_INFO               GROUP, TYPE
Next                            LONG                                        !&IP_ADAPTER_INFO  A pointer to the next adapter in the list of adapters.
ComboIndex                      ULONG                                       !Reserved.
AdapterName                     STRING(MAX_ADAPTER_NAME_LENGTH + 4)         !An ANSI character string of the name of the adapter.
Description                     STRING(MAX_ADAPTER_DESCRIPTION_LENGTH + 4)  !An ANSI character string that contains the description of the adapter.
AddressLength                   ULONG                                       !The length, in bytes, of the hardware address for the adapter.
Address                         BYTE, DIM(MAX_ADAPTER_ADDRESS_LENGTH)       !The hardware address for the adapter represented as a BYTE array.
Index                           ULONG                                       !The adapter index may change when an adapter is disabled and then enabled, or under other circumstances, and should not be considered persistent.
Type                            ULONG                                       !The adapter type. Possible values for the adapter type are listed in the Ipifcons.h header file.
DhcpEnabled                     ULONG                                       !An option value that specifies whether the dynamic host configuration protocol (DHCP) is enabled for this adapter.
CurrentIpAddress                LONG                                        !&IP_ADDR_STRING Reserved
IpAddressList                   LIKE(IP_ADDR_STRING)                        !The list of IPv4 addresses associated with this adapter represented as a linked list of IP_ADDR_STRING structures. An adapter can have multiple IPv4 addresses assigned to it.
GatewayList                     LIKE(IP_ADDR_STRING)                        !The IPv4 address of the gateway for this adapter represented as a linked list of IP_ADDR_STRING structures. An adapter can have multiple IPv4 gateway addresses assigned to it. This list usually contains a single entry for IPv4 address of the default gateway for this adapter.
DhcpServer                      LIKE(IP_ADDR_STRING)                        !The IPv4 address of the DHCP server for this adapter represented as a linked list of IP_ADDR_STRING structures. This list contains a single entry for the IPv4 address of the DHCP server for this adapter. A value of 255.255.255.255 indicates the DHCP server could not be reached, or is in the process of being reached.
HaveWins                        BOOL                                        !An option value that specifies whether this adapter uses the Windows Internet Name Service (WINS).
PrimaryWinsServer               LIKE(IP_ADDR_STRING)                        !The IPv4 address of the primary WINS server represented as a linked list of IP_ADDR_STRING structures. This list contains a single entry for the IPv4 address of the primary WINS server for this adapter.
SecondaryWinsServer             LIKE(IP_ADDR_STRING)                        !The IPv4 address of the secondary WINS server represented as a linked list of IP_ADDR_STRING structures. An adapter can have multiple secondary WINS server addresses assigned to it.
LeaseObtained                   time_t                                      !The time when the current DHCP lease was obtained.
LeaseExpires                    time_t                                      !The time when the current DHCP lease expires.
                              END
!!!endregion

!!!region Helper functions
iphlp::Trace                  PROCEDURE(STRING pMsg)
  CODE
  printd('[iphlpapi] %s', pMsg)
  
  
Get_IP_ADDR_STRING_Count      PROCEDURE(CONST *IP_ADDR_STRING pList)
slist                           &IP_ADDR_STRING, AUTO
nCount                          LONG, AUTO
  CODE
  nCount = 0
  slist &= pList
  LOOP
    nCount += 1
    slist &= (slist.Next)
  WHILE NOT slist &= NULL
  RETURN nCount
  
FormatAddress                 PROCEDURE(*BYTE[] pAddress, ULONG pAddressLength)
res                             STRING(32)
i                               LONG, AUTO
  CODE
  LOOP i = 1 TO pAddressLength
    res = CLIP(res) & printf('%X', pAddress[i])
    IF i < pAddressLength
      res = CLIP(res) & '-'
    END
  END
  RETURN res
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
buf                             &STRING, AUTO
adapterInfo                     &IP_ADAPTER_INFO, AUTO
adapter                         &IP_ADAPTER_INFO, AUTO
adrList                         &IP_ADDR_STRING, AUTO
dwRetVal                        ULONG, AUTO
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
      CLEAR(pAdaptersInfo.IpAddressList)
      CLEAR(pAdaptersInfo.GatewayList)
      
      pAdaptersInfo.AdapterName = adapter.AdapterName
      pAdaptersInfo.Description = adapter.Description
      pAdaptersInfo.Index = adapter.Index
      pAdaptersInfo.Type = adapter.Type
      pAdaptersInfo.DhcpEnabled = adapter.DhcpEnabled
      IF pAdaptersInfo.DhcpEnabled
        pAdaptersInfo.DhcpServer = adapter.DhcpServer.IpAddress
        pAdaptersInfo.DhcpMask = adapter.DhcpServer.IpMask
      END
      pAdaptersInfo.HaveWins = adapter.HaveWins
      IF pAdaptersInfo.HaveWins
        pAdaptersInfo.PrimaryWinsServer = adapter.PrimaryWinsServer.IpAddress
        pAdaptersInfo.SecondaryWinsServer = adapter.SecondaryWinsServer.IpAddress
      END
      
      !- a number of Ip addresses
      pAdaptersInfo.IpAddressListCount  = Get_IP_ADDR_STRING_Count(adapter.IpAddressList)
      IF pAdaptersInfo.IpAddressListCount > MAXIMUM(pAdaptersInfo.IpAddressList, 1)
        iphlp::Trace(printf('Warning: A number of Ip addresses (%i) is greater then IpAddressList array size (%i)', pAdaptersInfo.IpAddressListCount, MAXIMUM(pAdaptersInfo.IpAddressList, 1)))
      END
      
      !- Ip addresses
      adrList &= adapter.IpAddressList
      LOOP i=1 TO pAdaptersInfo.IpAddressListCount
        pAdaptersInfo.IpAddressList[i].IpAddress = adrList.IpAddress
        pAdaptersInfo.IpAddressList[i].IpMask = adrList.IpMask
        
        adrList &= (adrList.Next)
      WHILE (NOT adrList &= NULL) AND (i <= MAXIMUM(pAdaptersInfo.IpAddressList, 1))
      
      !- a number of gateways
      pAdaptersInfo.GatewayListCount  = Get_IP_ADDR_STRING_Count(adapter.GatewayList)
      IF pAdaptersInfo.GatewayListCount > MAXIMUM(pAdaptersInfo.GatewayList, 1)
        iphlp::Trace(printf('Warning: A number of gateways (%i) is greater then GatewayList array size (%i)', pAdaptersInfo.GatewayListCount, MAXIMUM(pAdaptersInfo.GatewayList, 1)))
      END

      !- gateways
      adrList &= adapter.GatewayList
      LOOP i=1 TO pAdaptersInfo.GatewayListCount
        pAdaptersInfo.GatewayList[i].Gateway = adrList.IpAddress
        pAdaptersInfo.GatewayList[i].GatewayMask = adrList.IpMask
        
        adrList &= (adrList.Next)
      WHILE (NOT adrList &= NULL) AND (i <= MAXIMUM(pAdaptersInfo.GatewayList, 1))

      !- Formatted address
      pAdaptersInfo.Address = FormatAddress(adapter.Address, adapter.AddressLength)

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