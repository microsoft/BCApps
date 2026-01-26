// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

page 10601 "Settled VAT Periods"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Settled VAT Periods';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Settled VAT Period";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1080000)
            {
                ShowCaption = false;
                field(Year; Rec.Year)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year of the closed VAT Period.';
                }
                field("Period No."; Rec."Period No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period of the closed VAT Period.';
                }
                field("Settlement Date"; Rec."Settlement Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the VAT settlement was made.';
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the VAT Period is closed for posting or not. A checkmark indicates that the period is closed.';
                }
            }
        }
    }

    actions
    {
    }
}

