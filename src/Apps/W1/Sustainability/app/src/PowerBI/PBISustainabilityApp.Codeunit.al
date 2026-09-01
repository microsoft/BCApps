namespace Microsoft.Sustainability.PowerBIReports;
using Microsoft.PowerBIReports;
using System.Environment;
using System.Integration.PowerBI;

codeunit 6287 "PBI Sustainability App" implements "Power BI Deployable Report", "PBI Report Setup"
{
    Access = Internal;

    procedure GetReportName(): Text[200]
    begin
        exit('Sustainability');
    end;

    procedure GetStream(var InStr: InStream)
    begin
        NavApp.GetResource('Sustainability app.pbix', InStr);
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
        exit(Enum::"Power BI Deployable Report"::"Sustainability App");
    end;

    procedure GetSetupReportIdFieldNo(): Integer
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
    begin
#if not CLEAN27
#pragma warning disable AL0801
#endif
        exit(PowerBIReportsSetup.FieldNo("Sustainability Report Id"));
#if not CLEAN27
#pragma warning restore AL0801
#endif
    end;

    procedure GetSetupReportNameFieldNo(): Integer
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
    begin
#if not CLEAN27
#pragma warning disable AL0801
#endif
        exit(PowerBIReportsSetup.FieldNo("Sustainability Report Name"));
#if not CLEAN27
#pragma warning restore AL0801
#endif
    end;
}
