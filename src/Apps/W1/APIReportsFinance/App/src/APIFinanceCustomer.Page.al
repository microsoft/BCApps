namespace Microsoft.API.FinancialManagement;

using Microsoft.Sales.Customer;

page 30307 "API Finance - Customer"
{
    PageType = API;
    EntityCaption = 'Customer';
    EntityName = 'customer';
    EntitySetName = 'customers';
    APIGroup = 'reportsFinance';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    DataAccessIntent = ReadOnly;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    SourceTable = "Customer";
    ODataKeyFields = SystemId;
    AboutText = 'Provides access to customer data from the Customer table, including customer numbers, names, contact types, addresses, salesperson codes, balances due, credit limits, and blocked status. Supports read-only GET operations for retrieving customer records to enable integration with external financial reporting and accounts receivable platforms.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(displayName; Rec.Name)
                {
                    Caption = 'Display Name';
                }
                field(type; Rec."Contact Type")
                {
                    Caption = 'Type';
                }
                field(city; Rec.City)
                {
                    Caption = 'City';
                }
                field(state; Rec.County)
                {
                    Caption = 'State';
                }
                field(country; Rec."Country/Region Code")
                {
                    Caption = 'Country/Region Code';
                }
                field(postalCode; Rec."Post Code")
                {
                    Caption = 'Post Code';
                }
                field(salespersonCode; Rec."Salesperson Code")
                {
                    Caption = 'Salesperson Code';
                }
                field(balanceDue; Rec."Balance Due")
                {
                    Caption = 'Balance Due';
                    Editable = false;
                }
                field(creditLimit; Rec."Credit Limit (LCY)")
                {
                    Caption = 'Credit Limit';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
                }
            }
        }
    }
}

