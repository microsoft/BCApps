namespace Microsoft.Sustainability.PowerBIReports;

using Microsoft.Sustainability.Account;

query 6217 "SusSub Act Category - PBI API"
{
    Access = Internal;
    QueryType = API;
    AboutText = 'Provides access to sustainability account subcategory data including category codes, descriptions, and renewable energy indicators. Enables Power BI reports to organize emission sources, classify energy types, and structure sustainability accounts for detailed environmental analysis.';
    Caption = 'Power BI Sustainability Entries';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'pbiSustainabilitySubAccountCategory';
    EntitySetName = 'pbiSustainabilitySubAccountCategories';
    DataAccessIntent = ReadOnly;
    elements
    {
        dataitem(SustainabilitySubcategory; "Sustain. Account Subcategory")
        {
            column(categoryCode; "Category Code") { }
            column(subcategoryCode; Code) { }
            column(subCategoryDescription; Description) { }
            column(subCategoryRenewableEnergy; "Renewable Energy") { }
        }
    }
}