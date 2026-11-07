namespace Microsoft.Sustainability.PowerBIReports;

using Microsoft.HumanResources.Payables;

query 6213 "EmployeeLedgerEntry - PBI API"
{
    Access = Internal;
    QueryType = API;
    AboutText = 'Provides access to employee ledger entries including posting dates, document types, amounts, and dimensions. Enables Power BI reports to analyze employee-related financial transactions for workforce cost analysis and social sustainability reporting.';
    Caption = 'Power BI Employee Ledger Entry';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'pbiEmployeeLedgerEntry';
    EntitySetName = 'pbiEmployeeLedgerEntries';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(employeeLedgerEntry; "Employee Ledger Entry")
        {
            column(employeeNo; "Employee No.") { }
            column(entryNo; "Entry No.") { }
            column(postingDate; "Posting Date") { }
            column(documentType; "Document Type") { }
            column(documentNo; "Document No.") { }
            column(amount; Amount) { }
            column(dimensionSetID; "Dimension Set ID") { }
            column(description; Description) { }
        }
    }
}
