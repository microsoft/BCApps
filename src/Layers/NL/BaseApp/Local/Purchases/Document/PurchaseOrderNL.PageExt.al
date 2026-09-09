// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

pageextension 11309 PurchaseOrderNL extends "Purchase Order"
{
    layout
    {
        addafter("Payment Method Code")
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction mode used in telebanking.';
            }
            field("Bank Account Code"; Rec."Bank Account Code")
            {
                ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s bank account that is used for payments and collections through telebanking.';
            }
        }
    }
}
