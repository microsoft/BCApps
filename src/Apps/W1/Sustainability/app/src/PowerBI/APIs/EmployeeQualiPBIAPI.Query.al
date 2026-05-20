namespace Microsoft.Sustainability.PowerBIReports;

using Microsoft.HumanResources.Employee;

query 6214 "Employee Quali - PBI API"
{
    Access = Internal;
    QueryType = API;
    AboutText = 'Provides access to employee qualification records linking employees to their certification codes. Enables Power BI reports to analyze workforce skills, sustainability-related training compliance, and qualification distribution for social governance reporting.';
    Caption = 'Power BI Employee Qualifications';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'pbiEmployeeQualification';
    EntitySetName = 'pbiEmployeeQualifications';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(employeeQualifications; "Employee Qualification")
        {
            column(employeeNo; "Employee No.") { }
            column(qualificationCode; "Qualification Code") { }

        }
    }
}