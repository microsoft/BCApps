namespace Microsoft.Sustainability.PowerBIReports;

using Microsoft.Sustainability.Account;

query 6219 "Sust Accounts - PBI API"
{
    Access = Internal;
    QueryType = API;
    AboutText = 'Provides access to sustainability account master data including account numbers, names, categories, and subcategories. Enables Power BI reports to retrieve the chart of sustainability accounts for structuring emission tracking, environmental impact analysis, and ESG reporting.';
    Caption = 'Power BI Sustainability Entries';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'pbiSustainabilityAccount';
    EntitySetName = 'pbiSustainabilityAccounts';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(SustainabilityAccount; "Sustainability Account")
        {
            column(sustainabilityAccountNo; "No.") { }
            column(sustainabilityAccountName; Name) { }
            column(sustainabilityAccountCategory; Category) { }
            column(sustainabilityAccountSubCategory; Subcategory) { }
        }
    }
}