// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Extends the Sales Invoice page with NL-specific telebanking fields.
/// </summary>
pageextension 11466 "Sales Invoice NL" extends "Sales Invoice"
{
    layout
    {
        addafter("Direct Debit Mandate ID")
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
