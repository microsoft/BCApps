namespace Microsoft.FabricExport;

codeunit 48527 "Fabric Platform Telemetry"
{
    Access = Internal;

    var
        CategoryTok: Label 'MicrosoftFabricExport', Locked = true;
        CredentialChangedMsg: Label 'Fabric 3P credential changed', Locked = true;

    procedure GetDimensions() Dimensions: Dictionary of [Text, Text]
    begin
        Dimensions.Add('Category', CategoryTok);
    end;

    /// <summary>Emits a third-party credential change to publisher and customer telemetry without secret data.</summary>
    /// <param name="CredentialAction">Stored, Replaced, or Deleted.</param>
    /// <param name="ChangeTrigger">SetupPage, Disable, SwitchTo1P, or EnvironmentCleanup. SetupPage includes the setup wizard.</param>
    /// <param name="ClientId">The custom application identifier, not the credential or any value derived from it.</param>
    procedure LogCredentialChanged(CredentialAction: Text; ChangeTrigger: Text; ClientId: Text)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions := GetDimensions();
        Dimensions.Add('Action', CredentialAction);
        Dimensions.Add('Trigger', ChangeTrigger);
        Dimensions.Add('ClientId', ClientId);
        Session.LogMessage('0000WCB', CredentialChangedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;
}
