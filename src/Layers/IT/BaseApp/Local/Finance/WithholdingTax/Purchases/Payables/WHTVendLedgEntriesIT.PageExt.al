// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Purchases.Payables;

pageextension 12113 "WHTVendLedgEntriesIT" extends "Vendor Ledger Entries"
{
    actions
    {
        addafter(ReverseTransaction)
        {
            action(CreateWithHoldTaxEntry)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create WithHold Tax entry';
                Image = NewSparkle;
                ToolTip = 'Generate an entry for withholding tax.';

                trigger OnAction()
                var
                    WithholdingTax: Record "Withholding Tax";
                begin
                    if Rec."Document Type" <> Rec."Document Type"::Payment then
                        Error(Text12100, Rec."Entry No.", Rec."Document Type");
                    WithholdingTax.CheckWithhEntryExist(Rec);
                    WithholdingTax.InsertWithholdTax(Rec);
                end;
            }
        }

        addafter(ReverseTransaction_Promoted)
        {
            actionref(CreateWithHoldTaxEntry_Promoted; CreateWithHoldTaxEntry)
            {
            }
        }
    }

    var
        Text12100: Label 'You cannot create the withhold entry from entry %1 because it''s an %2 Document.';
}
