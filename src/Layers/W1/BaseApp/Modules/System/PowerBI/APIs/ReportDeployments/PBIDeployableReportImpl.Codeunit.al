namespace System.Integration.PowerBI;

using Microsoft.Foundation.Company;

/// <summary>
/// Adapts a "Power BI Deployable Report" enum value into the "Power BI Uploadable Report" interface,
/// so the report aggregator and upload engine can process it uniformly alongside system table and customer reports.
/// </summary>
codeunit 6350 "PBI Deployable Report Impl." implements "Power BI Uploadable Report"
{
    Access = Internal;

    var
        CurrentReportId: Enum "Power BI Deployable Report";
        DeployableReport: Interface "Power BI Deployable Report";

    internal procedure SetReport(ReportId: Enum "Power BI Deployable Report")
    begin
        CurrentReportId := ReportId;
        DeployableReport := CurrentReportId;
    end;

    procedure GetReportKey(): Text[100]
    begin
        exit(Format(CurrentReportId.AsInteger()));
    end;

    procedure GetReportName(): Text[100]
    begin
        exit(CopyStr(DeployableReport.GetReportName(), 1, 100));
    end;

    procedure GetStream(var InStr: InStream)
    begin
        DeployableReport.GetStream(InStr);
    end;

    procedure GetReportVersion(): Integer
    begin
        exit(DeployableReport.GetVersion());
    end;

    procedure GetUploadTracker(var UploadTracker: Interface "Power BI Upload Tracker")
    var
        DeployUploadTracker: Codeunit "PBI Deploy. Upload Tracker";
    begin
        UploadTracker := DeployUploadTracker;
    end;

    procedure FinalizeUpload(var UploadTracker: Interface "Power BI Upload Tracker"; Context: Text[50])
    var
        PBIDeploymentEvents: Codeunit "PBI Deployment Events";
        UploadableReport: Interface "Power BI Uploadable Report";
    begin
        UploadableReport := this;
        PBIDeploymentEvents.OnReportDeployed(UploadableReport, CurrentReportId);
    end;

    procedure GetDatasetParameters() Parameters: Dictionary of [Text, Text]
    begin
        Parameters := DeployableReport.GetDatasetParameters();
    end;

    procedure GetTargetWorkspaceId(): Guid
    var
        CompanyInformation: Record "Company Information";
        PowerBIDeployment: Record "Power BI Deployment";
    begin
        // An upload can span several job queue runs. Once the import has started, stay in the workspace it started in
        if PowerBIDeployment.Get(CurrentReportId) then
            if PowerBIDeployment.GetUploadStatus() <> Enum::"Power BI Upload Status"::NotStarted then
                exit(PowerBIDeployment."Power BI Workspace Id");

        if CompanyInformation.Get() then
            exit(CompanyInformation."Power BI Workspace Id");
    end;
}
