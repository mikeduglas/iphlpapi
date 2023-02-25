# iphlpapi

This class is a wrapper around the APIs found in [iphlpapi.dll](https://learn.microsoft.com/en-us/windows/win32/api/iphlpapi/).
At the moment, following APIs are supported:

- GetAdaptersInfo.

## Version history
v1.02
- Removed CWUtil dependency.
- Class TIPAdapterInfo renamed to TIPHlpApi.
- Code refinement.

v1.01
- FREEs adapters queue in .GetAdaptersInfo.

v1.00
- Initial release.