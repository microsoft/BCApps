// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

page 548 "Dimension List"
{
    Caption = 'Dimension List';
    Editable = false;
    PageType = List;
    SourceTable = Dimension;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the dimension.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension code you enter in the Code field.';
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

    trigger OnAfterGetRecord()
    begin
        Rec.Name := Rec.GetMLName(GlobalLanguage);
    end;
}

