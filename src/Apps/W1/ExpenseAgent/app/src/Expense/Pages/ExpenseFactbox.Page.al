// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6938 "Expense Factbox"
{
    Caption = 'Expense';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = Expense;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique number that identifies the expense.';
                }
                field("Merchant Name"; Rec."Merchant Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the merchant for the expense.';
                }
                field("Merchant Registration No."; Rec."Merchant Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company registration number of the merchant for the expense.';
                }
                field("Merchant VAT Registration No."; Rec."Merchant VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number of the merchant for the expense.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount in the local currency.';
                }
            }
        }
    }
}