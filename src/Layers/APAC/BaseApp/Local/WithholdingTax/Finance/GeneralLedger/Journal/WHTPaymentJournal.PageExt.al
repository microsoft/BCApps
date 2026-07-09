// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Journal;

pageextension 28001 WHTPaymentJournal extends "Payment Journal"
{
    layout
    {
        addafter(Description)
        {
            field("WHT Business Posting Group"; Rec."WHT Business Posting Group")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies that the WHT Business Posting Group will be assigned to this field based on the Account Type and Account No. selected.';
                Visible = false;
            }
            field("WHT Product Posting Group"; Rec."WHT Product Posting Group")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the WHT product posting group you want to use for your journal transactions.';
                Visible = false;
            }
        }
        addafter("Posting Group")
        {
            field("WHT Payment"; Rec."WHT Payment")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies during manual calculation of WHT that the cash receipt is only for WHT and no VAT calculation shall be done for this transaction.';
                Visible = false;
            }
            field("Skip WHT"; Rec."Skip WHT")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies that this field can be checked if we want to skip the WHT Calculation for a particular journal transaction.';
                Visible = false;
            }
        }
    }

    actions
    {
        addafter("Void &All Checks")
        {
            action("Print WHT Certificate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print WHT Certificate';
                Image = PrintVAT;
                ToolTip = 'Print the withholding tax certificate.';

                trigger OnAction()
                begin
                    WHTManagement.PreprintingWHT(Rec);
                end;
            }
        }
    }

    var
        WHTManagement: Codeunit WHTManagement;
}
