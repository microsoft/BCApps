namespace Microsoft.PowerBIReports;
using System.Integration.PowerBI;

codeunit 36959 "Power BI Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PBI Deployment Events", OnReportDeployed, '', false, false)]
    local procedure OnReportDeployed(var Report: Interface "Power BI Uploadable Report"; DeployableReportType: Enum "Power BI Deployable Report")
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
        SetupHelper: Codeunit "Power BI Report Setup";
        RecRef: RecordRef;
        UploadTracker: Interface "Power BI Upload Tracker";
        ReportSetup: Interface "PBI Report Setup";
        ReportName: Text[200];
    begin
        if not SetupHelper.FindReportSetup(DeployableReportType, ReportSetup) then
            exit;

        Report.GetUploadTracker(UploadTracker);
        UploadTracker.Load(Report.GetReportKey());
        ReportName := CopyStr(UploadTracker.GetUploadedReportName(), 1, MaxStrLen(ReportName));

        PowerBIReportsSetup.GetOrCreate();
        RecRef.GetTable(PowerBIReportsSetup);
        RecRef.Field(ReportSetup.GetSetupReportIdFieldNo()).Value := UploadTracker.GetUploadedReportId();
        RecRef.Field(ReportSetup.GetSetupReportNameFieldNo()).Value := ReportName;
        RecRef.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PBI Deployment Events", OnAfterDeleteDeploymentRecord, '', false, false)]
    local procedure OnAfterDeleteDeploymentRecord(PowerBIDeployment: Record "Power BI Deployment")
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
        SetupHelper: Codeunit "Power BI Report Setup";
        RecRef: RecordRef;
        ReportSetup: Interface "PBI Report Setup";
        EmptyGuid: Guid;
        LinkedReportId: Guid;
    begin
        if IsNullGuid(PowerBIDeployment."Uploaded Report ID") then
            exit;
        if not SetupHelper.FindReportSetup(PowerBIDeployment."Report Id", ReportSetup) then
            exit;
        if not PowerBIReportsSetup.Get() then
            exit;

        RecRef.GetTable(PowerBIReportsSetup);
        LinkedReportId := RecRef.Field(ReportSetup.GetSetupReportIdFieldNo()).Value();
        if LinkedReportId <> PowerBIDeployment."Uploaded Report ID" then
            exit;

        RecRef.Field(ReportSetup.GetSetupReportIdFieldNo()).Value := EmptyGuid;
        RecRef.Field(ReportSetup.GetSetupReportNameFieldNo()).Value := '';
        RecRef.Modify();
    end;
}
