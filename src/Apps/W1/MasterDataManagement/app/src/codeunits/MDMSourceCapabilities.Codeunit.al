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
        NegotiatedForUrl: Text;
        ContractVersion: Integer;
        SupportedFeatures: List of [Text];
        UnsupportedFeatureErr: Label 'The source environment does not support the required ''%1'' capability. Update the Master Data Management app on the source environment.', Comment = '%1 = capability name';
        CapabilitiesParseErr: Label 'The source environment returned an invalid capabilities response.';
        CapabilitiesParseTelemetryTxt: Label 'The source environment returned a malformed capabilities response during cross-environment negotiation.', Locked = true;

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
        NegotiatedForUrl := '';
        ContractVersion := 0;
        Clear(SupportedFeatures);
    end;

    // A malformed capabilities response is an internal contract failure; keep the detail in telemetry and show a generic error.
    local procedure InternalError(MessageText: Text): ErrorInfo
    var
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := MessageText;
        ErrInfo.DataClassification := DataClassification::SystemMetadata; // Message is emitted to telemetry
        ErrInfo.ErrorType := ErrorType::Internal;
        exit(ErrInfo);
    end;

    local procedure Negotiate(Transport: Interface "IMDM Source Transport")
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        MasterDataManagement: Codeunit "Master Data Management";
        Capabilities: JsonObject;
        FeaturesToken: JsonToken;
        VersionToken: JsonToken;
        FeatureToken: JsonToken;
        CurrentSource: Text;
    begin
        if MasterDataManagementSetup.Get() then
            CurrentSource := MasterDataManagementSetup."Source Environment URL";
        // Re-negotiate when the configured source changes so a switched environment can't reuse the previous
        // source's cached feature/version data.
        if Negotiated and (NegotiatedForUrl = CurrentSource) then
            exit;
        Negotiated := false;
        ContractVersion := 0;
        Clear(SupportedFeatures);
        // Don't cache a failed parse as a successful (empty) negotiation - that would surface as a misleading
        // "capability unsupported / update the source app" error instead of the real bad-response problem.
        if not Capabilities.ReadFrom(Transport.GetCapabilities()) then begin
            Session.LogMessage('0000VAV', CapabilitiesParseTelemetryTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', MasterDataManagement.GetTelemetryCategory());
            Error(InternalError(CapabilitiesParseErr));
        end;
        if Capabilities.Get('version', VersionToken) then
            if VersionToken.IsValue() then
                ContractVersion := VersionToken.AsValue().AsInteger();
        if Capabilities.Get('features', FeaturesToken) then
            if FeaturesToken.IsArray() then
                foreach FeatureToken in FeaturesToken.AsArray() do
                    if FeatureToken.IsValue() then
                        SupportedFeatures.Add(FeatureToken.AsValue().AsText());
        Negotiated := true;
        NegotiatedForUrl := CurrentSource;
    end;
}
