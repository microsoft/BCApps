namespace Microsoft.PowerBIReports;
using System.Environment;
using System.Integration.PowerBI;

codeunit 36966 "PBI Inventory App" implements "Power BI Deployable Report"
{
    Access = Internal;

    procedure GetReportName(): Text[200]
    begin
        exit('Inventory');
    end;

    procedure GetStream(var InStr: InStream)
    begin
        NavApp.GetResource('Inventory app.pbix', InStr);
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
