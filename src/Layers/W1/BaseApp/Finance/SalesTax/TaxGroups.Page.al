// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

page 467 "Tax Groups"
{
    ApplicationArea = SalesTax;
    Caption = 'Tax Groups';
    PageType = List;
    SourceTable = "Tax Group";
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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code you want to assign to this tax group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the tax group. For example, if the tax group code is ALCOHOL, you could enter the description Alcoholic beverages.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Group")
            {
                Caption = '&Group';
                Image = Group;
                action(Details)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Details';
                    Image = View;
                    RunObject = Page "Tax Details";
                    RunPageLink = "Tax Group Code" = field(Code);
                    ToolTip = 'View tax-detail entries. A tax-detail entry includes all of the information that is used to calculate the amount of tax to be charged.';
                }
            }
        }
    }
}

