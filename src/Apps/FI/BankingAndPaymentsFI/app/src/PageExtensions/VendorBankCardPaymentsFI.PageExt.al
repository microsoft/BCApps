// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Purchases.Vendor;

using Microsoft.Foundation.Address;
using System.Automation;
using Microsoft.Bank.Payment;

pageextension 13570 "Vendor Bank Card Payments FI" extends "Vendor Bank Account Card"
{
    layout
    {
#if not CLEAN30
#pragma warning disable AL0432
        modify("Clearing Code")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast(Transfer)
        {
            field("Payment Clearing Code"; Rec."Payment Clearing Code")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a clearing code if the country/region uses the clearing system.';
                }
        }
#if not CLEAN30
#pragma warning disable AL0432
        modify("SEPA Payment")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast(Transfer)
        {
            field("SEPA Payment Enabled"; Rec."SEPA Payment Enabled")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the vendor bank account allows SEPA payments.';
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
