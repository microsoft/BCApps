// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

pageextension 7000110 "CRTApplyVendorEntries" extends "Apply Vendor Entries"
{
    layout
    {
        addafter("Document No.")
        {
            field("Bill No."; Rec."Bill No.")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the bill number related to the vendor ledger entry.';
            }
            field("Document Status"; Rec."Document Status")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the status of the document.';
            }
            field("Document Situation"; Rec."Document Situation")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the document location.';
            }
        }
    }
}
