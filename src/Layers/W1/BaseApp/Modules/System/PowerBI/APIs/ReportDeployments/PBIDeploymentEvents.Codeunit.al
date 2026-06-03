namespace System.Integration.PowerBI;

using System.DataAdministration;

/// <summary>
/// Centralizes the deployment lifecycle's event surface — integration events emitted from
/// the deployment domain, in-module subscribers to platform events, and the public entry
/// point used by out-of-module subscribers that can't see Power BI internals (e.g. the
/// Copy Company subscriber in BaseApp root, which lives outside this module's dependency
/// graph).
/// </summary>
codeunit 6351 "PBI Deployment Events"
{
    [IntegrationEvent(false, false)]
    procedure OnReportDeployed(var Report: Interface "Power BI Uploadable Report"; DeployableReportType: Enum "Power BI Deployable Report")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterDeleteAllDeploymentRecords(InCompany: Text[30])
    begin
    end;

    /// <summary>
    /// Wipes Power BI deployment tracking in the given company. Public entry point for
    /// out-of-module subscribers (BaseApp root) that need to react to events on objects
    /// the Power BI module can't reference directly.
    /// </summary>
    internal procedure ClearDeploymentsForCompany(CompanyName: Text[30])
    var
        PowerBIDeployment: Record "Power BI Deployment";
    begin
        PowerBIDeployment.DeleteAllRecords(CompanyName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearCompanyConfig', '', false, false)]
    local procedure ClearDeploymentRecordsOnEnvironmentCopy(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    begin
        // Environment copy carries deployment rows that point to reports uploaded under the source
        // environment's identity. Wipe them so the new environment runs its own deployment cycle.
        ClearDeploymentsForCompany(CopyStr(CompanyName, 1, 30));
    end;
}
