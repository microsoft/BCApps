// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

/// <summary>
/// Page 1229 "Payment File Error Details" displays detailed information about payment export errors.
/// This page provides comprehensive error information including error text, additional details, and support URLs.
/// </summary>
/// <remarks>
/// Source table: Payment Jnl. Export Error Text. Used as a card part to show
/// detailed error information when users drill down from payment error lists.
/// </remarks>
page 1229 "Payment File Error Details"
{
    Caption = 'Payment File Error Details';
    Editable = false;
    PageType = CardPart;
    SourceTable = "Payment Jnl. Export Error Text";

    layout
    {
        area(content)
        {
            field("Error Text"; Rec."Error Text")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Additional Information"; Rec."Additional Information")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Support URL"; Rec."Support URL")
            {
                ApplicationArea = Basic, Suite;
                ExtendedDatatype = URL;
            }
        }
    }

    actions
    {
    }
}

