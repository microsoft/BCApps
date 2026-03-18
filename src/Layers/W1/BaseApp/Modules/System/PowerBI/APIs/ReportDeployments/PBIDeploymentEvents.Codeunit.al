namespace System.Integration.PowerBI;

/// <summary>
/// Publishes integration events for deployable report lifecycle milestones.
/// Subscribers in dependent apps (e.g. PowerBIReports) can react to deployment completions.
/// </summary>
codeunit 6351 "PBI Deployment Events"
{
    [IntegrationEvent(false, false)]
    procedure OnReportDeployed(var Report: Interface "Power BI Uploadable Report"; DeployableReportType: Enum "Power BI Deployable Report"; UploadedReportId: Guid)
    begin
    end;
}
