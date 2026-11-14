// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

/// <summary>
/// Extends the Posted Sales Invoice page with NL-specific telebanking fields.
/// </summary>
pageextension 11471 "Posted Sales Invoice NL" extends "Posted Sales Invoice"
{
    layout
    {
        addafter("Location Code")
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
                ToolTip = 'Specifies the customer''s bank account used for payments and collections through telebanking.';
            }
        }
    }
}
