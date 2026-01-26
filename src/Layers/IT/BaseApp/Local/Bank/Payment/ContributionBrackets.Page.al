// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 12108 "Contribution Brackets"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Brackets';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Contribution Bracket";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a contribution bracket code that you want the program to attach to the entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the contribution bracket.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Brackets")
            {
                Caption = '&Brackets';
                Image = Ranges;
                action("Brackets &Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Brackets &Lines';
                    Image = Ranges;
                    RunObject = Page "Contribution Bracket Lines";
                    RunPageLink = Code = field(Code),
                                  "Contribution Type" = field("Contribution Type");
                    ToolTip = 'View the lines.';
                }
            }
        }
    }
}

