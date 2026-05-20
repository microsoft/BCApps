namespace Microsoft.Sustainability.PowerBIReports;

using Microsoft.HumanResources.Employee;

query 6215 "Employees - PBI API"
{
    Access = Internal;
    QueryType = API;
    AboutText = 'Provides access to employee master data including names, gender, status, union membership, and employment lifecycle dates. Enables Power BI reports to analyze workforce demographics, diversity metrics, and employment statistics for social sustainability and ESG reporting.';
    Caption = 'Power BI Employees';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'pbiEmployee';
    EntitySetName = 'pbiEmployees';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Employee; Employee)
        {
            column(no; "No.") { }
            column(firstName; "First Name") { }
            column(lastName; "Last Name") { }
            column(gender; Gender) { }
            column(unionCode; "Union Code") { }
            column(status; Status) { }
            column(casueofInactivty; "Cause of Inactivity Code") { }
            column(inactivedate; "Inactive Date") { }
            column(groudForTermCode; "Grounds for Term. Code") { }
            column(dateOfBirth; "Birth Date") { }

        }
    }
}