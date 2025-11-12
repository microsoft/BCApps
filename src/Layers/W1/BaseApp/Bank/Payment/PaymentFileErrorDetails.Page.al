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
                ToolTip = 'Specifies the error that is shown in the Payment Journal window in case payment lines cannot be exported.';
            }
            field("Additional Information"; Rec."Additional Information")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies more information that may help you resolve the error.';
            }
            field("Support URL"; Rec."Support URL")
            {
                ApplicationArea = Basic, Suite;
                ExtendedDatatype = URL;
                ToolTip = 'Specifies a web page containing information that may help you resolve the error.';
            }
        }
    }

    actions
    {
    }
}

