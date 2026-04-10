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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ADCS;
                }
                field(KeyDef; Rec.KeyDef)
                {
                    ApplicationArea = ADCS;
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

