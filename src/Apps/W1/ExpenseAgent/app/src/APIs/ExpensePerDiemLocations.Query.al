// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

query 7082 "Expense Per Diem Locations"
{
    QueryType = API;
    Access = Internal;
    APIPublisher = 'microsoft';
    APIGroup = 'expense';
    APIVersion = 'beta';
    EntityName = 'expensePerDiemLocation';
    EntitySetName = 'expensePerDiemLocations';
    Caption = 'Expense Per Diem Locations';
    DataAccessIntent = ReadOnly;
    AboutTitle = 'Expense Per Diem Locations';
    AboutText = 'Returns the expense locations that are linked, through an expense rule, to an expense category whose Expense Detail Required is set to Per Diem.';

    elements
    {
        dataitem(expenseRuleHeader; "Expense Rule Header")
        {
            DataItemTableFilter = "Expense Location" = filter(<> '');

            dataitem(expenseCategory; "Expense Category")
            {
                DataItemLink = "Code" = expenseRuleHeader."Expense Category Code";
                DataItemTableFilter = "Expense Detail Required" = const("Per Diem");
                SqlJoinType = InnerJoin;

                dataitem(expenseLocation; "Expense Location")
                {
                    DataItemLink = "No." = expenseRuleHeader."Expense Location";
                    SqlJoinType = InnerJoin;

                    column(locationSystemId; SystemId) { }
                    column(locationNo; "No.") { }
                    column(locationDescription; Description) { }
                    column(countryRegionCode; "Country/Region Code") { }
                    column(city; City) { }
                    column(county; County) { }
                }
            }
        }
    }

    trigger OnBeforeOpen()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;
}
