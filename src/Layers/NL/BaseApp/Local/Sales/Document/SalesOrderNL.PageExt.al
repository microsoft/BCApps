// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Extends the Sales Order page with NL-specific telebanking fields.
/// </summary>
pageextension 11465 "Sales Order NL" extends "Sales Order"
{
    layout
    {
        addafter("Customer Posting Group")
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
