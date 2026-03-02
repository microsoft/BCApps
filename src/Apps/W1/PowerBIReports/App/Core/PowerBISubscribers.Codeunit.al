namespace Microsoft.PowerBIReports;
using System.Integration.PowerBI;

codeunit 36959 "Power BI Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PBI Deployment Events", OnReportDeployed, '', false, false)]
    local procedure OnReportDeployed(var Report: Interface "Power BI Uploadable Report"; DeployableReportType: Enum "Power BI Deployable Report"; UploadedReportId: Guid)
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
    begin
        PowerBIReportsSetup.GetOrCreate();
        case DeployableReportType of
            DeployableReportType::"Finance App":
                PowerBIReportsSetup."Finance Report Id" := UploadedReportId;
            DeployableReportType::"Sales App":
                PowerBIReportsSetup."Sales Report Id" := UploadedReportId;
            DeployableReportType::"Purchases App":
                PowerBIReportsSetup."Purchases Report Id" := UploadedReportId;
            DeployableReportType::"Inventory App":
                PowerBIReportsSetup."Inventory Report Id" := UploadedReportId;
            DeployableReportType::"Inventory Valuation App":
                PowerBIReportsSetup."Inventory Val. Report Id" := UploadedReportId;
            DeployableReportType::"Manufacturing App":
                PowerBIReportsSetup."Manufacturing Report Id" := UploadedReportId;
            DeployableReportType::"Projects App":
                PowerBIReportsSetup."Projects Report Id" := UploadedReportId;
        end;
        PowerBIReportsSetup.Modify();
    end;
}