// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Integration.Dataverse;
using Microsoft.Bank.Payment;

pageextension 13565 "Payment Terms UI FI" extends "Payment Terms"
{
    layout
    {
#if not CLEAN30
#pragma warning disable AL0432
        modify("Disreg. Pmt. Disc. at Full Pmt")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast(Control1)
        {
            field("Disreg. Full Payment Discount"; Rec."Disreg. Full Payment Discount")
                {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you do not want to post a payment discount when it is not used.';
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
