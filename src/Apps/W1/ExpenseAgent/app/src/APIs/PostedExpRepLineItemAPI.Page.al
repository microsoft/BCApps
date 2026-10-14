// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6906 "Posted Exp. Rep. Line Item API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Posted Expense Report Line Itemization';
    EntitySetCaption = 'Posted Expense Report Line Itemizations';
    EntityName = 'postedExpenseReportLineItemization';
    EntitySetName = 'postedExpenseReportLineItemizations';
    PageType = API;
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    SourceTable = "Posted Exp. Rep. Line Item";
    AboutText = 'Provides access to the data from the Posted Expense Report Line Itemization table';
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(expenseReportNo; Rec."Expense Report No.")
                {
                    Caption = 'Expense Report No.';
                }
                field(expenseReportLineNo; Rec."Expense Report Line No.")
                {
                    Caption = 'Expense Report Line No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(expenseNo; Rec."Expense No.")
                {
                    Caption = 'Expense No.';
                }
                field(expenseCategoryCode; Rec."Expense Category Code")
                {
                    Caption = 'Expense Category Code';
                }
                field(expenseSubcategoryCode; Rec."Expense Subcategory Code")
                {
                    Caption = 'Expense Subcategory Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(startDate; Rec."Start Date")
                {
                    Caption = 'Start Date';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(dailyRate; Rec."Daily Rate")
                {
                    Caption = 'Daily Rate';
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Amount';
                }
                field(refundable; Rec.Refundable)
                {
                    Caption = 'Refundable';
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;
}