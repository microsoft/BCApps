namespace Microsoft.PowerBIReports;
using System.Integration.PowerBI;

codeunit 36959 "Power BI Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Power BI Report Synchronizer", OnDeployablePowerBIReportUploadCompleted, '', false, false)]
    local procedure OnDeployablePowerBIReportUploadCompleted(var Report: Interface "Power BI Uploadable Report"; DeployableReportType: Enum "Power BI Deployable Report")
    var
        PowerBIReportSynchronizer: Codeunit "Power BI Report Synchronizer";
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
    begin
        PowerBIReportsSetup.GetOrCreate();
        case DeployableReportType of
            DeployableReportType::"Finance App":
                PowerBIReportsSetup."Finance Report Id" := PowerBIReportSynchronizer.GetUploadedReportId(Report);
            DeployableReportType::"Sales App":
                PowerBIReportsSetup."Sales Report Id" := PowerBIReportSynchronizer.GetUploadedReportId(Report);
            DeployableReportType::"Purchases App":
                PowerBIReportsSetup."Purchases Report Id" := PowerBIReportSynchronizer.GetUploadedReportId(Report);
            DeployableReportType::"Inventory App":
                PowerBIReportsSetup."Inventory Report Id" := PowerBIReportSynchronizer.GetUploadedReportId(Report);
            DeployableReportType::"Inventory Valuation App":
                PowerBIReportsSetup."Inventory Val. Report Id" := PowerBIReportSynchronizer.GetUploadedReportId(Report);
            DeployableReportType::"Manufacturing App":
                PowerBIReportsSetup."Manufacturing Report Id" := PowerBIReportSynchronizer.GetUploadedReportId(Report);
            DeployableReportType::"Projects App":
                PowerBIReportsSetup."Projects Report Id" := PowerBIReportSynchronizer.GetUploadedReportId(Report);
        end;
        PowerBIReportsSetup.Modify();
    end;
}