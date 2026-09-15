// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

pageextension 10002 SourceCodeSetupNA extends "Source Code Setup"
{
    layout
    {
        addafter(Reversal)
        {
            field("Bank Rec. Adjustment"; Rec."Bank Rec. Adjustment")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code that is assigned to entries that are posted from a bank record adjustment.';
            }
        }
        addafter("Cash Flow Worksheet")
        {
            field(Deposits; Rec.Deposits)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code that is assigned to entries that are posted from a deposit.';
                Visible = not BankDepositFeatureEnabled;
            }
        }
    }

    var
        BankDepositFeatureEnabled: Boolean;

    trigger OnOpenPage()
    begin
        BankDepositFeatureEnabled := true;
    end;
}