namespace Microsoft.SubscriptionBilling;
using Microsoft.PowerBIReports;
using System.Integration.PowerBI;

codeunit 8102 "PBI Sub. Billing Subscribers"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PBI Deployment Events", OnReportDeployed, '', false, false)]
    local procedure OnReportDeployed(var Report: Interface "Power BI Uploadable Report"; DeployableReportType: Enum "Power BI Deployable Report")
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
        UploadTracker: Interface "Power BI Upload Tracker";
        ReportId: Guid;
        ReportName: Text[200];
    begin
        if DeployableReportType <> DeployableReportType::"Subscription Billing App" then
            exit;

        Report.GetUploadTracker(UploadTracker);
        UploadTracker.Load(Report.GetReportKey());
        ReportId := UploadTracker.GetUploadedReportId();
        ReportName := CopyStr(UploadTracker.GetUploadedReportName(), 1, MaxStrLen(ReportName));

        PowerBIReportsSetup.GetOrCreate();
        PowerBIReportsSetup."Subscription Billing Report Id" := ReportId;
        PowerBIReportsSetup."Subs. Billing Report Name" := ReportName;
        PowerBIReportsSetup.Modify();
    end;
}
