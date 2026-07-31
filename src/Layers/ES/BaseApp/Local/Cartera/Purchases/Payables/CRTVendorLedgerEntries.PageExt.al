// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

pageextension 7000189 "CRTVendorLedgerEntries" extends "Vendor Ledger Entries"
{
    layout
    {
        addafter("Invoice Received Date")
        {
            field("Autodocument No."; Rec."Autodocument No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'This field is used internally.';
            }
        }
        addafter("Document No.")
        {
            field("Bill No."; Rec."Bill No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the bill number related to the vendor ledger entry.';
            }
            field("Document Situation"; Rec."Document Situation")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the document location.';
            }
            field("Document Status"; Rec."Document Status")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the status of the document.';
            }
        }
    }
}
