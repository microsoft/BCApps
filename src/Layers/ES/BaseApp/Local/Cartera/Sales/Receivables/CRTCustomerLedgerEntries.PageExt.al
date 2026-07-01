// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

pageextension 7000011 "CRT Customer Ledger Entries" extends "Customer Ledger Entries"
{
    layout
    {
        addafter("Document No.")
        {
            field("Bill No."; Rec."Bill No.")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the bill number related to the customer entry.';
            }
            field("Document Situation"; Rec."Document Situation")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the document location.';
            }
            field("Document Status"; Rec."Document Status")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the status of the document.';
            }
        }
    }
}
