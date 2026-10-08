// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Archive;

pageextension 99000762 "Mfg. PurchQuoteArchiveSubform" extends "Purchase Quote Archive Subform"
{
    layout
    {
        addafter("Job Line Disc. Amount (LCY)")
        {
            field("Prod. Order No."; Rec."Prod. Order No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the related production order.';
                Visible = false;
            }
        }
    }
}