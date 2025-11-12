namespace System.Azure.Identity;

using System.Telemetry;
using Microsoft.Foundation.Company;

codeunit 6304 "Setup Azure AD Mgt. Provider"
{
    var
        CustomAzureADMgtSetupTxt: Label 'A custom Microsoft Entra ID Mgt. Setup is saved', Locked = true;

    trigger OnRun()
    begin
        InitSetup();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Azure AD Mgt. Setup", 'RIM')]
    local procedure InitSetup()
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
    begin
        if not AzureADMgtSetup.Get() then begin
            AzureADMgtSetup.ResetToDefault();
            AzureADMgtSetup.Insert();
        end else
            if AzureADMgtSetup.IsSetupDifferentFromDefault() then begin
                AzureADMgtSetup.ResetToDefault();
                AzureADMgtSetup.Modify();
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Azure AD Mgt. Setup", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertAzureADMgtSetup(var Rec: Record "Azure AD Mgt. Setup"; RunTrigger: Boolean)
    begin
        SendTelemetryOnCustomSetup(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Azure AD Mgt. Setup", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyAzureADMgtSetup(var Rec: Record "Azure AD Mgt. Setup"; RunTrigger: Boolean)
    begin
        SendTelemetryOnCustomSetup(Rec);
    end;

    local procedure SendTelemetryOnCustomSetup(var AzureADMgtSetup: Record "Azure AD Mgt. Setup")
    var
        Telemetry: Codeunit Telemetry;
    begin
        if AzureADMgtSetup.IsTemporary() then
            exit;

        if AzureADMgtSetup.IsSetupDifferentFromDefault() then
            Telemetry.LogMessage('0000GQC', CustomAzureADMgtSetupTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher);
    end;
}

