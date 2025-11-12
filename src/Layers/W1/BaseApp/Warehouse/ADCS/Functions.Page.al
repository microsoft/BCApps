// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

page 7704 Functions
{
    ApplicationArea = ADCS;
    Caption = 'Miniform Functions Group';
    Editable = false;
    PageType = List;
    SourceTable = "Miniform Function Group";
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
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the code that represents the function used on the handheld device.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies a short description of what the function is or how it functions.';
                }
                field(KeyDef; Rec.KeyDef)
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the key that will trigger the function.';
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

