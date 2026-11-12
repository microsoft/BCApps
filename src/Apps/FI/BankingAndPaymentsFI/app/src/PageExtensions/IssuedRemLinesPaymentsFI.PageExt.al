// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Sales.Reminder;

using Microsoft.Bank.Payment;

pageextension 13574 "Issued Rem. Lines Payments FI" extends "Issued Reminder Lines"
{
    layout
    {
#if not CLEAN30
#pragma warning disable AL0432
        modify("Reference No.")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast(Control1)
        {
            field("Payment Reference No."; Rec."Payment Reference No.")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference number that is calculated from a reference number sequence.';
                }
        }
    }
#if not CLEAN30
    trigger OnOpenPage()
    var
        Feature: Codeunit "Banking Payments Feature FI";
    begin
        FeatureEnabled := Feature.IsEnabled();
    end;

    var
        FeatureEnabled: Boolean;
#endif
}
