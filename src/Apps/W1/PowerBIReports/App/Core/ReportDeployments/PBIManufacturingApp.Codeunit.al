namespace Microsoft.PowerBIReports;
using System.Environment;
using System.Integration.PowerBI;

codeunit 36968 "PBI Manufacturing App" implements "Power BI Deployable Report"
{
    Access = Internal;

    procedure GetReportName(): Text[200]
    begin
        exit('Manufacturing');
    end;

    procedure GetStream(var InStr: InStream)
    begin
        NavApp.GetResource('Manufacturing app.pbix', InStr);
    end;

    procedure GetVersion(): Integer
    begin
        exit(1);
    end;

    procedure GetDatasetParameters() Parameters: Dictionary of [Text, Text]
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        Parameters.Add('COMPANY', CompanyName());
        Parameters.Add('ENVIRONMENT', EnvironmentInformation.GetEnvironmentName());
    end;
}
