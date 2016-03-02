  PROGRAM

  MAP
  END

  INCLUDE('iphlpapi.inc'), ONCE

ai                            TIPAdapterInfo
Res                           ULONG, AUTO
qIndex                        LONG, AUTO

  CODE
  Res = ai.GetAdaptersInfo()
  IF Res = NO_ERROR
    LOOP qIndex = 1 TO RECORDS(ai.adapters)
      GET(ai.adapters, qIndex)
      iphlp::Trace('Adapter #'& qIndex &' Index: '& ai.adapters.Index)
      iphlp::Trace('Adapter #'& qIndex &' ComboIndex: '& ai.adapters.ComboIndex)
      iphlp::Trace('Adapter #'& qIndex &' Adapter Name: '& ai.adapters.AdapterName)
      iphlp::Trace('Adapter #'& qIndex &' Adapter Desc: '& ai.adapters.Description)
      iphlp::Trace('Adapter #'& qIndex &' Type: '& ai.GetAdatperTypeName(ai.adapters.Type))
      iphlp::Trace('Adapter #'& qIndex &' Address: '& ai.adapters.Address)
      
      IF ai.adapters.DhcpEnabled
        iphlp::Trace('Adapter #'& qIndex &' DHCP server: '& ai.adapters.DhcpServer)
        iphlp::Trace('Adapter #'& qIndex &' DHCP mask: '& ai.adapters.DhcpMask)
      END
      
      IF ai.adapters.HaveWins
        iphlp::Trace('Adapter #'& qIndex &' Primary Win server: '& ai.adapters.PrimaryWinsServer)
        iphlp::Trace('Adapter #'& qIndex &' Secondary Win server: '& ai.adapters.SecondaryWinsServer)
      END
    END
 
    MESSAGE('The End')
  ELSE
    MESSAGE('GetAdaptersInfo failed, error '& Res)
  END
