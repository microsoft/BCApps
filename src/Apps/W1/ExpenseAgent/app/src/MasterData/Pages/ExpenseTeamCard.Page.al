// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7143 "Expense Team Card"
{
    Caption = 'Expense Team';
    PageType = Card;
    ApplicationArea = Basic, Suite;
    SourceTable = "Expense Team";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code that identifies the Expense Team.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the team description.';
                }
                field("Number Of Team Members"; Rec."Number Of Team Members")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of Expense Users assigned to this team.';
                }
            }
            group("Expense Information")
            {
                Caption = 'Expense Information';

                field("Spending Limit Per Team"; Rec."Spending Limit Per Team")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether a spend limit is configured directly for this Expense Team.';
                }
                field("Available Spend Limit (LCY)"; AvailableSpendLimitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Available Spend Limit (LCY)';
                    Editable = false;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    ToolTip = 'Specifies the applicable expense spend limit in local currency.';
                }
                field("Current Spending (LCY)"; CurrentSpendingLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Current Spending (LCY)';
                    Editable = false;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    ToolTip = 'Specifies the amount already spent by this team in the applicable period, in local currency.';
                }
                field("Available To Use (LCY)"; AvailableToUseLCY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Available To Use (LCY)';
                    Editable = false;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    ToolTip = 'Specifies the remaining amount available for this team to spend in local currency.';
                }
                field("Spend Limit Payment Method"; SpendLimitPaymentMethodCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Spend Limit Payment Method';
                    Editable = false;
                    ToolTip = 'Specifies the payment method of the spend limit used for this summary. Blank means all payment methods.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateSpendLimitInformation();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateSpendLimitInformation();
    end;

    var
        AvailableSpendLimitLCY: Decimal;
        CurrentSpendingLCY: Decimal;
        AvailableToUseLCY: Decimal;
        SpendLimitPaymentMethodCode: Code[10];

    local procedure UpdateSpendLimitInformation()
    var
        ExpenseSpendLimitMgt: Codeunit "Expense Spend Limit Mgt.";
    begin
        ExpenseSpendLimitMgt.GetExpenseTeamSpendLimitInfo(Rec, AvailableSpendLimitLCY, CurrentSpendingLCY, AvailableToUseLCY, SpendLimitPaymentMethodCode);
    end;
}