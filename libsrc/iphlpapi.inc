!* iphlpapi support
!* v1.03
!* mikeduglas 2016-2023
!* mikeduglas@yandex.ru

  MAP
    MODULE('iphlpapi')
      iphlp::Trace(STRING pMsg)
    END
  END

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
MAX_ADAPTER_ADDRESS_LENGTH      EQUATE(8)
MAX_ADAPTER_DESCRIPTION_LENGTH  EQUATE(128)
MAX_ADAPTER_NAME_LENGTH         EQUATE(256)

typAdapterInfoQ               QUEUE, TYPE
AdapterName                     STRING(260) !MAX_ADAPTER_NAME_LENGTH + 4
Description                     STRING(132) !MAX_ADAPTER_DESCRIPTION_LENGTH + 4
Address                         STRING(32)
Index                           ULONG
Type                            ULONG
DhcpEnabled                     ULONG
IpAddressListCount              ULONG
IpAddressList                   GROUP, DIM(4) !actually can be more then 4, see IpAddressListCount
IpAddress                         STRING(16)
IpMask                            STRING(16)
                                END
GatewayListCount                ULONG
GatewayList                     GROUP, DIM(4) !actually can be more then 4, see GatewayListCount
Gateway                           STRING(16)
GatewayMask                       STRING(16)
                                END
DhcpServer                      STRING(16)
DhcpMask                        STRING(16)
HaveWins                        BOOL
PrimaryWinsServer               STRING(16)
SecondaryWinsServer             STRING(16)
                              END


TIPHlpApi                     CLASS, TYPE, MODULE('iphlpapi.clw'), LINK('iphlpapi.clw')
hDll                            LONG, PRIVATE

Construct                       PROCEDURE()
Destruct                        PROCEDURE(), VIRTUAL

GetAdaptersInfo                 PROCEDURE(*typAdapterInfoQ pAdaptersInfo), ULONG, PROC
GetAdatperTypeName              PROCEDURE(ULONG pType), STRING
                              END
