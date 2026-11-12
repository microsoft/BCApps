// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

pageextension 13561 "Payables Activities FI" extends "Acc. Payables Activities"
{
    actions
    {
#if not CLEAN30
#pragma warning disable AL0432
        modify("Edit Bank Payment to send")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addlast(navigation)
        {
            action("Edit Bank Payment to send FI")
                    {
#if not CLEAN30
            Visible = FeatureEnabled;
#endif
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit Bank Payment to send';
                        RunObject = Page "Bank Payments to send FI";
                        ToolTip = 'View and edit the payments that will be registered to the vendors.';
                    }
        }
        addlast(Category_Process)
        {
            actionref("Edit Bank Payment to send FI Promoted"; "Edit Bank Payment to send FI") { }
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
