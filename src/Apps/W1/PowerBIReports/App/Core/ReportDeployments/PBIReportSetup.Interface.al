namespace Microsoft.PowerBIReports;
using System.Integration.PowerBI;

interface "PBI Report Setup"
{
    procedure GetDeployableReportType(): Enum "Power BI Deployable Report";
    procedure GetSetupReportIdFieldNo(): Integer;
    procedure GetSetupReportNameFieldNo(): Integer;
}
