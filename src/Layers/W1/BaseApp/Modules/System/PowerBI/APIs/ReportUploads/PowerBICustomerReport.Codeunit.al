namespace System.Integration.PowerBI;

using System.Environment;

/// <summary>
/// Wraps a Power BI Customer Reports record (table 6310) as an uploadable report.
/// </summary>
codeunit 6326 "Power BI Customer Report" implements "Power BI Uploadable Report"
{
    Access = Internal;

    var
        PowerBICustomerReports: Record "Power BI Customer Reports";

    internal procedure SetReportId(ReportId: Guid)
    begin
        PowerBICustomerReports.SetAutoCalcFields("Blob File");
        PowerBICustomerReports.Get(ReportId);
    end;

    procedure GetReportKey(): Text[100]
    begin
        exit(Format(PowerBICustomerReports.Id));
    end;

    procedure GetReportName(): Text[100]
    begin
        exit(CopyStr(PowerBICustomerReports.Name, 1, 100));
    end;

    procedure GetStream(var InStr: InStream)
    begin
        PowerBICustomerReports."Blob File".CreateInStream(InStr);
    end;

    procedure GetReportVersion(): Integer
    begin
        exit(PowerBICustomerReports.Version);
    end;

    procedure GetUploadTracker(var UploadTracker: Interface "Power BI Upload Tracker")
    var
        SystemTracker: Codeunit "Power BI System Upload Tracker";
    begin
        UploadTracker := SystemTracker;
    end;

    procedure FinalizeUpload(var UploadTracker: Interface "Power BI Upload Tracker"; Context: Text[50]; UploadReportName: Text)
    begin
    end;

    procedure GetDatasetParameters() Parameters: Dictionary of [Text, Text]
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        Parameters.Add('Company Name', CompanyName());
        Parameters.Add('Environment', EnvironmentInformation.GetEnvironmentName());
    end;
}
