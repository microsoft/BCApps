namespace Microsoft.PowerBIReports;
using System.Environment;
using System.Integration.PowerBI;

codeunit 36963 "PBI Finance App" implements "Power BI Deployable Report"
{
    Access = Internal;

    procedure GetReportName(): Text[200]
    begin
        exit('Finance');
    end;

    procedure GetStream(var InStr: InStream)
    begin
        NavApp.GetResource('Finance app.pbix', InStr);
    end;

    procedure GetVersion(): Integer
    begin
        exit(1);
    end;

    procedure GetChangelog(): Text[2048]
    begin
        exit('Initial release.');
    end;

    procedure GetDatasetParameters() Parameters: List of [Text]
    begin
        Parameters.Add('COMPANY');
        Parameters.Add('ENVIRONMENT');
    end;

    procedure GetDatasetParameterValue(ParameterName: Text): Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        case ParameterName of
            'COMPANY':
                exit(CompanyName());
            'ENVIRONMENT':
                exit(EnvironmentInformation.GetEnvironmentName());
        end;
    end;
}
