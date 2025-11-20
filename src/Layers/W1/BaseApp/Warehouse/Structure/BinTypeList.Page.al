// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

page 7307 "Bin Type List"
{
    Caption = 'Bin Type List';
    Editable = false;
    PageType = List;
    SourceTable = "Bin Type";

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
                    ToolTip = 'Specifies a unique code for the bin type.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the bin type.';
                }
                field(Receive; Rec.Receive)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies to use the bin for items that have just arrived at the warehouse.';
                }
                field(Ship; Rec.Ship)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies to use the bin for items that are about to be shipped out of the warehouse.';
                }
                field("Put Away"; Rec."Put Away")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies to use the bin for items that are being put away, such as receipts and internal put-always.';
                }
                field(Pick; Rec.Pick)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies to use the bin for items that can be picked for shipment, internal picks, and production.';
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

