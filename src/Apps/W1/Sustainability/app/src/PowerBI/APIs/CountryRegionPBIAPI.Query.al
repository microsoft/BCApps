namespace Microsoft.Sustainability.PowerBIReports;

using Microsoft.Foundation.Address;

query 6210 "Country Region - PBI API"
{
    Access = Internal;
    QueryType = API;
    AboutText = 'Provides access to country and region reference data including codes and names. Enables Power BI reports and external analytics to retrieve geographic classifications for sustainability reporting, emissions tracking by region, and location-based environmental analysis.';
    Caption = 'Power BI Country Region';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'pbiCountryRegion';
    EntitySetName = 'pbiCountryRegions';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(CountryRegion; "Country/Region")
        {
            column(code; Code) { }
            column(name; Name) { }

        }
    }
}