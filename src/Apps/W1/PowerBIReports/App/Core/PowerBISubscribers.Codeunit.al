namespace Microsoft.PowerBIReports;
using System.Integration.PowerBI;

codeunit 36959 "Power BI Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PBI Deployment Events", OnReportDeployed, '', false, false)]
    local procedure OnReportDeployed(var Report: Interface "Power BI Uploadable Report"; DeployableReportType: Enum "Power BI Deployable Report")
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
        UploadTracker: Interface "Power BI Upload Tracker";
        ReportId: Guid;
        ReportName: Text[200];
    begin
        Report.GetUploadTracker(UploadTracker);
        UploadTracker.Load(Report.GetReportKey());
        ReportId := UploadTracker.GetUploadedReportId();
        ReportName := CopyStr(UploadTracker.GetUploadedReportName(), 1, MaxStrLen(ReportName));

        PowerBIReportsSetup.GetOrCreate();
        case DeployableReportType of
            DeployableReportType::"Finance App":
                begin
                    PowerBIReportsSetup."Finance Report Id" := ReportId;
                    PowerBIReportsSetup."Finance Report Name" := ReportName;
                end;
            DeployableReportType::"Sales App":
                begin
                    PowerBIReportsSetup."Sales Report Id" := ReportId;
                    PowerBIReportsSetup."Sales Report Name" := ReportName;
                end;
            DeployableReportType::"Purchases App":
                begin
                    PowerBIReportsSetup."Purchases Report Id" := ReportId;
                    PowerBIReportsSetup."Purchases Report Name" := ReportName;
                end;
            DeployableReportType::"Inventory App":
                begin
                    PowerBIReportsSetup."Inventory Report Id" := ReportId;
                    PowerBIReportsSetup."Inventory Report Name" := ReportName;
                end;
            DeployableReportType::"Inventory Valuation App":
                begin
                    PowerBIReportsSetup."Inventory Val. Report Id" := ReportId;
                    PowerBIReportsSetup."Inventory Val. Report Name" := ReportName;
                end;
            DeployableReportType::"Manufacturing App":
                begin
                    PowerBIReportsSetup."Manufacturing Report Id" := ReportId;
                    PowerBIReportsSetup."Manufacturing Report Name" := ReportName;
                end;
            DeployableReportType::"Projects App":
                begin
                    PowerBIReportsSetup."Projects Report Id" := ReportId;
                    PowerBIReportsSetup."Projects Report Name" := ReportName;
                end;
        end;
        PowerBIReportsSetup.Modify();
    end;
}
