// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Extends the Sales Quote page with NL-specific telebanking fields.
/// </summary>
pageextension 11468 "Sales Quote NL" extends "Sales Quote"
{
    layout
    {
        addafter("Payment Terms Code")
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the transaction mode used in telebanking.';
            }
            field("Bank Account Code"; Rec."Bank Account Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the customer''s bank account that is used for payments and collections through telebanking.';
            }
        }
    }
}
