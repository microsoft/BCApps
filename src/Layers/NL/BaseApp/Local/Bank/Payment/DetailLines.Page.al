// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 11000004 "Detail Lines"
{
    Caption = 'Detail Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Detail Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the account you want to perform payments to, or collections for.';
                }
                field("Serial No. (Entry)"; Rec."Serial No. (Entry)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number of the ledger entry that this detail line is linked to.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account you want to perform payments to, or collections for.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when you want the payment or collection to be performed.';
                }
                field(Bank; Rec.Bank)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the employee/vendor/customer''s bank you want to perform payments to, or collections from.';
                }
                field("Our Bank"; Rec."Our Bank")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of your bank, through which you want to perform payments or collections.';
                }
                field("Transaction Mode"; Rec."Transaction Mode")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction mode used in telebanking.';
                }
                field("Order"; Rec.Order)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order type of the payment history line.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount (including VAT) you want to pay or collect.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec.GetFilter("Connect Lines") <> '' then
            Rec."Connect Lines" := Rec.GetRangeMin("Connect Lines");
    end;
}

