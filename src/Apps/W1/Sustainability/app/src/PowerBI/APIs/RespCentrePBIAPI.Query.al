namespace Microsoft.Sustainability.PowerBIReports;

using Microsoft.Inventory.Location;

query 6216 "Resp Centre - PBI API"
{
    Access = Internal;
    QueryType = API;
    AboutText = 'Provides access to responsibility center data including codes, names, and water capacity thresholds. Enables Power BI reports to analyze organizational units, allocate sustainability metrics by department, and track resource consumption targets for environmental reporting.';
    Caption = 'Power BI Responsibility Centre';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'pbiResponsibilityCentre';
    EntitySetName = 'pbiResponsibilityCentres';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(ResponsibilityCenter; "Responsibility Center")
        {
            column(code; Code) { }
            column(name; Name) { }
            column(waterCapactiybyMonth; "Water Capacity Quantity(Month)") { }
        }
    }
}