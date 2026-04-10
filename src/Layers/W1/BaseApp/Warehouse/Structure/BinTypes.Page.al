// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

page 7306 "Bin Types"
{
    ApplicationArea = Warehouse;
    Caption = 'Bin Types';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Bin Type";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Warehouse;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field(Receive; Rec.Receive)
                {
                    ApplicationArea = Warehouse;
                }
                field(Ship; Rec.Ship)
                {
                    ApplicationArea = Warehouse;
                }
                field("Put Away"; Rec."Put Away")
                {
                    ApplicationArea = Warehouse;
                }
                field(Pick; Rec.Pick)
                {
                    ApplicationArea = Warehouse;
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

