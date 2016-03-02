  MAP
    MODULE('iphlpapi')
      iphlp::Trace(STRING pMsg)
    END
  END

!error codes
NO_ERROR                      EQUATE(0)
ERROR_BUFFER_OVERFLOW         EQUATE(111)
ERROR_INVALID_DATA            EQUATE(13)
ERROR_INVALID_PARAMETER       EQUATE(87)
ERROR_NO_DATA                 EQUATE(232)
ERROR_NOT_SUPPORTED           EQUATE(50)

!adapter types
MIB_IF_TYPE_OTHER             EQUATE(1)
MIB_IF_TYPE_ETHERNET          EQUATE(6)
MIB_IF_TYPE_TOKENRING         EQUATE(9)
MIB_IF_TYPE_FDDI              EQUATE(15)
MIB_IF_TYPE_PPP               EQUATE(23)
MIB_IF_TYPE_LOOPBACK          EQUATE(24)
MIB_IF_TYPE_SLIP              EQUATE(28)
MIB_IF_TYPE_IEEE80211         EQUATE(71)

!string lenghts
MAX_ADAPTER_ADDRESS_LENGTH    EQUATE(8)
MAX_ADAPTER_DESCRIPTION_LENGTH    EQUATE(128)
MAX_ADAPTER_NAME_LENGTH       EQUATE(256)

typAdapterInfoQ               QUEUE, TYPE
ComboIndex                      ULONG
AdapterName                     STRING(MAX_ADAPTER_NAME_LENGTH + 4)
Description                     STRING(MAX_ADAPTER_DESCRIPTION_LENGTH + 4)
Address                         STRING(32)
Index                           ULONG
Type                            ULONG
DhcpEnabled                     ULONG
CurrentIpAddress                STRING(16)
IpAddress                       STRING(16)
IpMask                          STRING(16)
Gateway                         STRING(16)
DhcpServer                      STRING(16)
DhcpMask                        STRING(16)
HaveWins                        BOOL
PrimaryWinsServer               STRING(16)
SecondaryWinsServer             STRING(16)
                              END


TIPAdapterInfo                CLASS, TYPE, MODULE('iphlpapi.clw'), LINK('iphlpapi.clw')
hDll                            LONG, PRIVATE
adapters                        &typAdapterInfoQ

Construct                       PROCEDURE()
Destruct                        PROCEDURE(), VIRTUAL

GetAdaptersInfo                 PROCEDURE(), ULONG, PROC
GetAdatperTypeName              PROCEDURE(ULONG pType), STRING
                              END
