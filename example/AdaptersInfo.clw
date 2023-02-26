  PROGRAM

  MAP
    GetAdaptersInfo()
    INCLUDE('printf.inc'), ONCE
  END

  INCLUDE('iphlpapi.inc'), ONCE

NO_ERROR                      EQUATE(0)

iphlp                         TIPHlpApi

  CODE
  GetAdaptersInfo()
  
GetAdaptersInfo               PROCEDURE()
ai                              QUEUE(typAdapterInfoQ).
res                             ULONG, AUTO
i                               LONG, AUTO
j                               LONG, AUTO
  CODE
  res = iphlp.GetAdaptersInfo(ai)
  IF res = NO_ERROR
    LOOP i = 1 TO RECORDS(ai)
      GET(ai, i)
      iphlp::Trace(printf('Adapter #%i', i))
      
      iphlp::Trace(printf('  Index: %i', ai.Index))
      iphlp::Trace(printf('  Adapter Name: %s', ai.AdapterName))
      iphlp::Trace(printf('  Adapter Desc: %s', ai.Description))
      iphlp::Trace(printf('  Type: %s', iphlp.GetAdatperTypeName(ai.Type)))
      iphlp::Trace(printf('  Address: %s', ai.Address))
      
      iphlp::Trace(printf('  IP count: %i', ai.IpAddressListCount))
      LOOP j=1 TO MAXIMUM(ai.IpAddressList, 1)
        IF j > ai.IpAddressListCount
          BREAK
        END
        
        iphlp::Trace(printf('  IP address[%i]: %s', j, ai.IpAddressList[j].IpAddress))
        iphlp::Trace(printf('  IP mask[%i]: %s', j, ai.IpAddressList[j].IpMask))
      END
            
      iphlp::Trace(printf('  Gateway count: %i', ai.GatewayListCount))
      LOOP j=1 TO MAXIMUM(ai.GatewayList, 1)
        IF j > ai.GatewayListCount
          BREAK
        END
        
        iphlp::Trace(printf('  Gateway[%i]: %s', j, ai.GatewayList[j].Gateway))
        iphlp::Trace(printf('  Gateway mask[%i]: %s', j, ai.GatewayList[j].GatewayMask))
      END

      IF ai.DhcpEnabled
        iphlp::Trace('  Dhcp enabled: Yes')
        iphlp::Trace(printf('  DHCP server: %s', ai.DhcpServer))
        iphlp::Trace(printf('  DHCP mask: %s', ai.DhcpMask))
      ELSE
        iphlp::Trace('  Dhcp enabled: No')
      END
      
      IF ai.HaveWins
        iphlp::Trace('  Have Wins: Yes')
        iphlp::Trace(printf('  Primary Win server: %s', ai.PrimaryWinsServer))
        iphlp::Trace(printf('  Secondary Win server: %s', ai.SecondaryWinsServer))
      ELSE
        iphlp::Trace('  Have Wins: No')
      END
    END
 
    MESSAGE('GetAdaptersInfo succeed.', 'iphlpapi', ICON:Asterisk)
  ELSE
    MESSAGE('GetAdaptersInfo failed, error '& res, 'iphlpapi', ICON:Exclamation)
  END
