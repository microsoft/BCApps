namespace Microsoft.Integration.MDM;

/// <summary>
/// Single resolution point for the source transport, shared by the cross-environment data source and the change
/// detector. Defaults to the HTTP transport; tests inject an in-process transport via OnResolveSourceTransport.
/// </summary>
codeunit 7244 "MDM Source Connection"
{
    Access = Internal;

    procedure GetTransport() Transport: Interface "IMDM Source Transport"
    var
        HttpTransport: Codeunit "MDM Http Source Transport";
    begin
        Transport := HttpTransport;
        OnResolveSourceTransport(Transport);
    end;

    [InternalEvent(false)]
    local procedure OnResolveSourceTransport(var Transport: Interface "IMDM Source Transport")
    begin
    end;
}
