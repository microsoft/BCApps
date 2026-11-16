// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

pageextension 10842 "Vendor Card" extends "Vendor Card"
{
    layout
    {
#if not CLEAN30
        modify("Payment Balance (LCY)")
        {
            Visible = not FeatureEnabled;
        }
#endif
#if not CLEAN28
#pragma warning disable AL0432
        modify("Payment in progress (LCY)")
        {
            Visible = not FeatureEnabled;
        }
        modify("""Balance (LCY)"" - ""Payment in progress (LCY)""")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addafter("Block Payment Tolerance")
        {
            field("Payment Balance (LCY) FR"; Rec."Balance (LCY)")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Balance (LCY)';
                ToolTip = 'Specifies the total value of your completed purchases from the vendor in the current fiscal year. It is calculated from amounts excluding VAT on all completed purchase invoices and credit memos.';
#if not CLEAN30
                Visible = FeatureEnabled;
#endif

                trigger OnDrillDown()
                var
                    VendLedgEntry: Record "Vendor Ledger Entry";
                    DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                begin
                    DtldVendLedgEntry.SetFilter("Vendor No.", Rec."No.");
                    Rec.CopyFilter("Global Dimension 1 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 1");
                    Rec.CopyFilter("Global Dimension 2 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 2");
                    Rec.CopyFilter("Currency Filter", DtldVendLedgEntry."Currency Code");
                    VendLedgEntry.DrillDownOnEntries(DtldVendLedgEntry);
                end;
            }
            field("Payment in progress (LCY) FR"; Rec."Payment in progress (LCY) FR")
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                AutoFormatExpression = Rec."Currency Code";
                ToolTip = 'Specifies the vendor''s payments in progress.';
#if not CLEAN28
                Visible = FeatureEnabled;
#endif
            }
            field("Net amount (LCY)"; Rec."Balance (LCY)" - Rec."Payment in progress (LCY) FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Net amount (LCY)';
                Editable = false;
                AutoFormatType = 1;
                AutoFormatExpression = Rec."Currency Code";
                ToolTip = 'Specifies the net amount in local currency.';
#if not CLEAN28
                Visible = FeatureEnabled;
#endif
            }
        }
    }
    actions
    {
#if not CLEAN28
#pragma warning disable AL0432
        modify("&Payment Addresses")
        {
            Visible = not FeatureEnabled;
        }
#pragma warning restore AL0432
#endif
        addafter(Attachments)
        {
            action("&Payment Addresses FR")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Payment Addresses';
                Image = Addresses;
                RunObject = Page "Payment Addresses FR";
                RunPageLink = "Account Type" = const(Vendor),
                                  "Account No." = field("No.");
                ToolTip = 'View payment addresses for the vendor.';
#if not CLEAN28
                Visible = FeatureEnabled;
#endif
            }
        }
    }

#if not CLEAN30
    trigger OnOpenPage()
    var
        PaymentFeatureFR: Codeunit "Payment Management Feature FR";
    begin
        FeatureEnabled := PaymentFeatureFR.IsEnabled();
    end;

    var
        FeatureEnabled: Boolean;
#endif
}