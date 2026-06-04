namespace Microsoft.SubscriptionBilling;
using Microsoft.PowerBIReports;
using System.Environment;
using System.Integration.PowerBI;

codeunit 8079 "PBI Sub. Billing App" implements "Power BI Deployable Report", "PBI Report Setup"
{
    Access = Internal;

    procedure GetReportName(): Text[200]
    begin
        exit('Subscription Billing');
    end;

    procedure GetStream(var InStr: InStream)
    begin
        NavApp.GetResource('Subscription Billing app.pbix', InStr);
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
        exit(Enum::"Power BI Deployable Report"::"Subscription Billing App");
    end;

    procedure GetSetupReportIdFieldNo(): Integer
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
    begin
#if not CLEAN28
#pragma warning disable AL0801
#endif
        exit(PowerBIReportsSetup.FieldNo("Subscription Billing Report Id"));
#if not CLEAN28
#pragma warning restore AL0801
#endif
    end;

    procedure GetSetupReportNameFieldNo(): Integer
    var
        PowerBIReportsSetup: Record "PowerBI Reports Setup";
    begin
#if not CLEAN28
#pragma warning disable AL0801
#endif
        exit(PowerBIReportsSetup.FieldNo("Subs. Billing Report Name"));
#if not CLEAN28
#pragma warning restore AL0801
#endif
    end;
}
