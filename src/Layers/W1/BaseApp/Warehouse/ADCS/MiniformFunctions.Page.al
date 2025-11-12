// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

page 7705 "Miniform Functions"
{
    Caption = 'Miniform Functions';
    PageType = List;
    SourceTable = "Miniform Function";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Miniform Code"; Rec."Miniform Code")
                {
                    ApplicationArea = ADCS;
                    Editable = false;
                    ToolTip = 'Specifies the miniform that has a function assigned to it.';
                    Visible = false;
                }
                field("Function Code"; Rec."Function Code")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the code of the function that is assigned to the miniform.';
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

