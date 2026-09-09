// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

pageextension 11316 PostedPurchaseCrMemoNL extends "Posted Purchase Credit Memo"
{
    layout
    {
        addafter("Applies-to Doc. No.")
        {
            field("Transaction Mode"; Rec."Transaction Mode")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                    ToolTip = 'Specifies the transaction mode used in telebanking.';
            }
            field("Bank Account"; Rec."Bank Account")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                    ToolTip = 'Specifies the vendor''s bank account used for payments and collections through telebanking.';
            }
        }
    }
}
