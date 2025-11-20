// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

page 469 "Tax Area List"
{
    ApplicationArea = SalesTax;
    Caption = 'Tax Areas';
    CardPageID = "Tax Area";
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Tax Area";
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
                    ToolTip = 'Specifies the code you want to assign to this tax area. You can enter up to 20 characters, both numbers and letters. It is a good idea to enter a code that is easy to remember.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies a description of the tax area. If you use a number as the tax code, you might want to describe the tax area in this field.';
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
    }
}

