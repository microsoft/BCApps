// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Purchases.Document;

pageextension 12112 "WHTPurchInvIT" extends "Purchase Invoice"
{
    actions
    {
        addafter(Approvals)
        {
            action("With&hold Taxes-Soc. Sec.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'With&hold Taxes-Soc. Sec.';
                Image = SocialSecurityTax;
                RunObject = Page "Withh. Taxes-Contribution Card";
#pragma warning disable AL0603
                RunPageLink = "Document Type" = field("Document Type"),
#pragma warning restore AL0603
                              "No." = field("No.");
                ToolTip = 'Show the calculated withholding tax contributions for social security.';

                trigger OnAction()
                begin
                    WithhSocSecTax.CalculateWithholdingTax(Rec, false);
                end;
            }
        }
    }

    var
        WithhSocSecTax: Codeunit "Withholding - Contribution";
}
