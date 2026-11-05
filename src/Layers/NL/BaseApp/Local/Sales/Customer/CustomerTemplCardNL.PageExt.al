// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

/// <summary>
/// Extends the Customer Templ. Card page with NL-specific telebanking fields.
/// </summary>
pageextension 11464 "Customer Templ. Card NL" extends "Customer Templ. Card"
{
    layout
    {
        addafter("Block Payment Tolerance")
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the transaction mode commonly used in telebanking for customers created from this template.';
            }
        }
    }
}
