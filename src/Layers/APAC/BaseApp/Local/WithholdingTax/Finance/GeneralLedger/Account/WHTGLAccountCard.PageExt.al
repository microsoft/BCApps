// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Account;

pageextension 28000 WHTGLAccountCard extends "G/L Account Card"
{
    layout
    {
        addafter("Default IC Partner G/L Acc. No")
        {
            field("WHT Business Posting Group"; Rec."WHT Business Posting Group")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies a WHT business posting group.';
            }
            field("WHT Product Posting Group"; Rec."WHT Product Posting Group")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies a WHT Product posting group.';
            }
        }
    }

    actions
    {
        addafter("G/L Register")
        {
            action("WHT Posting Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Posting Setup';
                Image = VATPostingSetup;
                RunObject = Page "WHT Posting Setup";
                ToolTip = 'Open the WHT Posting Setup page.';
                Promoted = true;
                PromotedCategory = Process;
            }
        }
    }
}
