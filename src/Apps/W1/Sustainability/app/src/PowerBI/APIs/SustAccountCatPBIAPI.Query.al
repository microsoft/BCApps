namespace Microsoft.Sustainability.PowerBIReports;

using Microsoft.Sustainability.Account;

query 6218 "Sust Account Cat - PBI API"
{
    Access = Internal;
    QueryType = API;
    AboutText = 'Provides access to sustainability account category data including codes, descriptions, and emission scopes. Enables Power BI reports to classify emissions by Scope 1, 2, and 3 categories and organize sustainability accounts for greenhouse gas protocol compliance reporting.';
    Caption = 'Power BI Sustainability Entries';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'pbiSustainabilityAccountCategory';
    EntitySetName = 'pbiSustainabilityAccountCategories';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(SustainabilityAccountCat; "Sustain. Account Category")
        {
            column(code; Code) { }
            column(description; Description) { }
            column(emissionScope; "Emission Scope") { }
        }
    }
}