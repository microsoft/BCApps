namespace Microsoft.PowerBIReports;
using System.Integration.PowerBI;

codeunit 36959 "Power BI Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PBI Deployment Events", OnReportDeployed, '', false, false)]
    local procedure OnReportDeployed(var Report: Interface "Power BI Uploadable Report"; DeployableReportType: Enum "Power BI Deployable Report")
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
        UploadTracker: Interface "Power BI Upload Tracker";
        RecRef: RecordRef;
        ReportSetup: Interface "PBI Report Setup";
        Ordinal: Integer;
        ReportName: Text[200];
    begin
        foreach Ordinal in Enum::"PBI Report Setup".Ordinals() do begin
            ReportSetup := Enum::"PBI Report Setup".FromInteger(Ordinal);
            if ReportSetup.GetDeployableReportType() = DeployableReportType then begin
                Report.GetUploadTracker(UploadTracker);
                UploadTracker.Load(Report.GetReportKey());
                ReportName := CopyStr(UploadTracker.GetUploadedReportName(), 1, MaxStrLen(ReportName));

                PowerBIReportsSetup.GetOrCreate();
                RecRef.GetTable(PowerBIReportsSetup);
                RecRef.Field(ReportSetup.GetSetupReportIdFieldNo()).Value := UploadTracker.GetUploadedReportId();
                RecRef.Field(ReportSetup.GetSetupReportNameFieldNo()).Value := ReportName;
                RecRef.Modify();
                exit;
            end;
        end;
    end;
}
