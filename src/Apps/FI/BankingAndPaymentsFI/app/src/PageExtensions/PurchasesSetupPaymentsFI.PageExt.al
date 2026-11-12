// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Purchases.Setup;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Pricing.Calculation;
using Microsoft.Purchases.Vendor;
using Microsoft.Bank.Payment;

pageextension 13569 "Purchases Setup Payments FI" extends "Purchases & Payables Setup"
{
    layout
    {
#if not CLEAN30
#pragma warning disable AL0432
        modify("Bank Batch Nos.")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast("Number Series")
        {
            field("Payment Batch Nos."; Rec."Payment Batch Nos.")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank batch number.';
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
