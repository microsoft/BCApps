// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

/// <summary>
/// Displays and manages date-effective interest rates for finance charge terms.
/// </summary>
page 572 "Finance Charge Interest Rates"
{
    Caption = 'Finance Charge Interest Rates';
    PageType = List;
    SourceTable = "Finance Charge Interest Rate";

    layout
    {
        area(content)
        {
            repeater(Control4)
            {
                ShowCaption = false;
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Interest Rate"; Rec."Interest Rate")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Interest Period (Days)"; Rec."Interest Period (Days)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of days in the interest period.';
                }
            }
        }
    }

    actions
    {
    }
}

