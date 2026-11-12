// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.BankAccount;

using Microsoft.Bank.Payment;

page 13512 "Payment Method Codes FI"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Method Codes';
    PageType = List;
    SourceTable = "Foreign Payment Types FI";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code to identify the payment term.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the terms.';
                }
                field(Banks; Rec.Banks)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank name for the payment type.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
#if not CLEAN30
        BankingFeature.EnsureEnabled();
#endif
    end;

#if not CLEAN30
    var
        BankingFeature: Codeunit "Banking Payments Feature FI";
#endif
}
