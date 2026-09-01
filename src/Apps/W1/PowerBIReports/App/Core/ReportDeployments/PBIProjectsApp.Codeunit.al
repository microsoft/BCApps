namespace Microsoft.PowerBIReports;
using System.Environment;
using System.Integration.PowerBI;

codeunit 36969 "PBI Projects App" implements "Power BI Deployable Report", "PBI Report Setup"
{
    Access = Internal;

    procedure GetReportName(): Text[200]
    begin
        exit('Projects');
    end;

    procedure GetStream(var InStr: InStream)
    begin
        NavApp.GetResource('Projects app.pbix', InStr);
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

    procedure GetDeployableReportType(): Enum "Power BI Deployable Report"
    begin
        exit(Enum::"Power BI Deployable Report"::"Projects App");
    end;

    procedure GetSetupReportIdFieldNo(): Integer
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
    begin
        exit(PowerBIReportsSetup.FieldNo("Projects Report Id"));
    end;

    procedure GetSetupReportNameFieldNo(): Integer
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
    begin
        exit(PowerBIReportsSetup.FieldNo("Projects Report Name"));
    end;
}
