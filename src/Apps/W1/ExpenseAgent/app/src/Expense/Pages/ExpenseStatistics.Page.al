// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6904 "Expense Statistics"
{
    PageType = CardPart;
    SourceTable = Expense;
    Caption = 'Expense Statistics';

    layout
    {
        area(Content)
        {
            field(Amount; Rec.Amount)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total amount in the expense currency.';
            }
            field("VAT Amount"; VATAmount)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                AutoFormatExpression = Rec."Currency Code";
                Caption = 'VAT Amount';
                ToolTip = 'Specifies the total VAT amount in the expense currency.';
                Visible = IsVATCalculated;
            }
            field("Reimbursable Amount"; Rec."Reimbursable Amount")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the amount eligible for reimbursement based on policy.';
            }
            field("Currency Code"; Rec."Currency Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the currency used for this expense.';
            }
            field("Amount (LCY)"; Rec."Amount (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total amount in the local currency.';
            }
            field("VAT Amount (LCY)"; VATAmountLCY)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                AutoFormatExpression = '';
                Caption = 'VAT Amount (LCY)';
                ToolTip = 'Specifies the total VAT amount in the local currency.';
                Visible = IsVATCalculated;
            }
            field("Reimbursable Amount (LCY)"; Rec."Reimbursable Amount (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the reimbursable amount in the local currency.';
            }
            field("Expense Date"; Rec."Expense Date")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the date the expense occurred.';
            }
            field("Expense Category"; Rec."Expense Category")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the category assigned to this expense.';
            }
            field(Description; Rec.Description)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies a short description of the expense.';
            }
            field("Merchant Name"; Rec."Merchant Name")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the vendor or merchant for this expense.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsVATCalculated := Rec.GetVATAmounts(VATAmount, VATAmountLCY);
    end;

    var
        VATAmount, VATAmountLCY : Decimal;
        IsVATCalculated: Boolean;
}