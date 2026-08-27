namespace Microsoft.Integration.MDM;

/// <summary>
/// Wire-contract negotiation: caches the source's advertised version and feature names (GetCapabilities) so the
/// subsidiary only calls actions the source actually supports. A newer subsidiary talking to an older source thus
/// fails with a clear message instead of a 404. SingleInstance: one source connection per session.
/// </summary>
codeunit 7246 "MDM Source Capabilities"
{
    Access = Internal;
    SingleInstance = true;

    var
        Negotiated: Boolean;
        ContractVersion: Integer;
        SupportedFeatures: List of [Text];
        UnsupportedFeatureErr: Label 'The source environment does not support the required ''%1'' capability. Update the Master Data Management app on the source environment.', Comment = '%1 = capability name';

    procedure EnsureSupported(Transport: Interface "IMDM Source Transport"; Feature: Text)
    begin
        if not IsSupported(Transport, Feature) then
            Error(UnsupportedFeatureErr, Feature);
    end;

    procedure IsSupported(Transport: Interface "IMDM Source Transport"; Feature: Text): Boolean
    begin
        Negotiate(Transport);
        exit(SupportedFeatures.Contains(Feature));
    end;

    procedure ContractVersionNo(Transport: Interface "IMDM Source Transport"): Integer
    begin
        Negotiate(Transport);
        exit(ContractVersion);
    end;

    // Clears the cached negotiation (used by tests that swap the injected transport).
    procedure Reset()
    begin
        Negotiated := false;
        ContractVersion := 0;
        Clear(SupportedFeatures);
    end;

    local procedure Negotiate(Transport: Interface "IMDM Source Transport")
    var
        Capabilities: JsonObject;
        FeaturesToken: JsonToken;
        VersionToken: JsonToken;
        FeatureToken: JsonToken;
    begin
        if Negotiated then
            exit;
        if Capabilities.ReadFrom(Transport.GetCapabilities()) then begin
            if Capabilities.Get('version', VersionToken) then
                if VersionToken.IsValue() then
                    ContractVersion := VersionToken.AsValue().AsInteger();
            if Capabilities.Get('features', FeaturesToken) then
                if FeaturesToken.IsArray() then
                    foreach FeatureToken in FeaturesToken.AsArray() do
                        if FeatureToken.IsValue() then
                            SupportedFeatures.Add(FeatureToken.AsValue().AsText());
        end;
        Negotiated := true;
    end;
}
