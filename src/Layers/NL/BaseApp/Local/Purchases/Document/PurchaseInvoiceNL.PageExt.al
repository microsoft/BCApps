// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

pageextension 11308 PurchaseInvoiceNL extends "Purchase Invoice"
{
    layout
    {
        addafter("Payment Method Code")
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Bank Account Code"; Rec."Bank Account Code")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
