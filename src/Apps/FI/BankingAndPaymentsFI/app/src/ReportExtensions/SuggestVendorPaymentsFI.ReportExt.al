// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Purchases.Payables;

reportextension 13591 "Suggest Vendor Payments FI" extends "Suggest Vendor Payments"
{
    requestpage
    {
        layout
        {
            addbefore(SkipExportedPayments)
            {
                // Report 393 retains SaveValues; saved legacy SendToBank compatibility needs runtime verification.
                field(SentToBankFI; SentToBank)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sent to Bank';
                    ToolTip = 'Specifies if you want the batch job to only include vendor ledger entries for which payments have already been sent to the bank.';
#if not CLEAN30
                    Visible = FeatureEnabled;
#endif
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
#endif
    }

    trigger OnPreReport()
#if not CLEAN30
    var
        Feature: Codeunit "Banking Payments Feature FI";
#endif
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        Payments.Initialize(SentToBank, GenJnlLine2);
        BindSubscription(Payments);
        Bound := true;
    end;

    trigger OnPostReport()
    begin
        if Bound then begin
            UnbindSubscription(Payments);
            Bound := false;
        end;
    end;

    var
        // The report owns this manual instance; report disposal also releases bindings on errors.
        Payments: Codeunit "Suggest Vendor Payments FI";
        SentToBank: Boolean;
        Bound: Boolean;
#if not CLEAN30
        FeatureEnabled: Boolean;
#endif
}
