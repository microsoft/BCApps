// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.BankAccount;

using Microsoft.Bank.Payment;

page 32000005 "Payment Method Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Method Codes';
    PageType = List;
    SourceTable = "Foreign Payment Types";
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
}

