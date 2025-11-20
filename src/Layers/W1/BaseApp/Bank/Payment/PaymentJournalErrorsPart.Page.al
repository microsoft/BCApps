// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

/// <summary>
/// Page 1228 "Payment Journal Errors Part" displays payment export errors as a list part.
/// This page shows error messages related to payment journal export operations and allows drill-down into error details.
/// </summary>
/// <remarks>
/// Source table: Payment Jnl. Export Error Text. Used as a part page to display
/// payment export errors within other pages such as payment journals.
/// </remarks>
page 1228 "Payment Journal Errors Part"
{
    Caption = 'Payment Journal Errors Part';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Payment Jnl. Export Error Text";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Error Text"; Rec."Error Text")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    ToolTip = 'Specifies the error that is shown in the Payment Journal window in case payment lines cannot be exported.';

                    trigger OnDrillDown()
                    begin
                        PAGE.RunModal(PAGE::"Payment File Error Details", Rec);
                    end;
                }
            }
        }
    }

    actions
    {
    }
}

