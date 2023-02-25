  PROGRAM

  MAP
    GetAdaptersInfo()
    INCLUDE('printf.inc'), ONCE
  END

  INCLUDE('iphlpapi.inc'), ONCE

  CODE
  GetAdaptersInfo()
  
GetAdaptersInfo               PROCEDURE()
iphlp                           TIPHlpApi
ai                              QUEUE(typAdapterInfoQ).
res                             ULONG, AUTO
i                               LONG, AUTO

NO_ERROR                        EQUATE(0)

  CODE
  res = iphlp.GetAdaptersInfo(ai)
  IF res = NO_ERROR
    LOOP i = 1 TO RECORDS(ai)
      GET(ai, i)
      iphlp::Trace(printf('Adapter #%i', i))
      
      iphlp::Trace(printf('  Index: %i', ai.Index))
      iphlp::Trace(printf('  ComboIndex: %i', ai.ComboIndex))
      iphlp::Trace(printf('  Adapter Name: %s', ai.AdapterName))
      iphlp::Trace(printf('  Adapter Desc: %s', ai.Description))
      iphlp::Trace(printf('  Type: %s', iphlp.GetAdatperTypeName(ai.Type)))
      iphlp::Trace(printf('  Address: %s', ai.Address))
      
      IF ai.DhcpEnabled
        iphlp::Trace('  Dhcp enabled')
        iphlp::Trace(printf('  DHCP server: %s', ai.DhcpServer))
        iphlp::Trace(printf('  DHCP mask: %s', ai.DhcpMask))
      END
      
      IF ai.HaveWins
        iphlp::Trace('  Have Wins')
        iphlp::Trace(printf('  Primary Win server: %s', ai.PrimaryWinsServer))
        iphlp::Trace(printf('  Secondary Win server: %s', ai.SecondaryWinsServer))
      END
    END
 
    MESSAGE('GetAdaptersInfo succeed.', 'iphlpapi', ICON:Asterisk)
  ELSE
    MESSAGE('GetAdaptersInfo failed, error '& res, 'iphlpapi', ICON:Exclamation)
  END
