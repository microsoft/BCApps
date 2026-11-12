// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Purchases.Vendor;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Bank.Payment;

pageextension 13572 "Vendor Template Payments FI" extends "Vendor Templ. Card"
{
    layout
    {
#if not CLEAN30
#pragma warning disable AL0432
        modify("Business Identity Code")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast(AddressAndContact)
        {
            field("Payment Business Identity Code"; Rec."Payment Business Identity Code")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor business identity code.';
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
