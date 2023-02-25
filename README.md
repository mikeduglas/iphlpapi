# iphlpapi

This class is a wrapper about the APIs found in iphlpapi.dll.
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