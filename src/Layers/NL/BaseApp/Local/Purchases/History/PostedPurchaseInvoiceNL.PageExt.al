// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

pageextension 11315 PostedPurchaseInvoiceNL extends "Posted Purchase Invoice"
{
    layout
    {
        addafter("Payment Method Code")
        {
            field("Transaction Mode"; Rec."Transaction Mode")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
            field("Bank Account"; Rec."Bank Account")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
        }
    }
}
