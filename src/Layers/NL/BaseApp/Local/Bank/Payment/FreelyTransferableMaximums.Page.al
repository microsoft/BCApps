// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 11406 "Freely Transferable Maximums"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Freely Transferable Maximums';
    PageType = List;
    SourceTable = "Freely Transferable Maximum";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1000000)
            {
                ShowCaption = false;
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the country/region that the freely transferable maximum applies to.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code that the freely transferable maximum applies to.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum amount that can be transferred without reason given.';
                }
            }
        }
    }

    actions
    {
    }
}

