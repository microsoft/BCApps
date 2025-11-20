// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

page 5524 "Get Alternative Supply"
{
    Caption = 'Get Alternative Supply';
    DataCaptionFields = "No.", Description;
    Editable = false;
    PageType = Worksheet;
    SourceTable = "Requisition Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a code for an inventory location where the items that are being ordered will be registered.';
                }
                field("Demand Date"; Rec."Demand Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the demanded date of the demand that the planning line represents.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("No.2"; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies text that describes the entry.';
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';
                }
                field("Needed Quantity"; Rec."Needed Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the demand quantity that is not available and must be ordered to meet the demand represented on the planning line.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    Visible = false;
                }
                field("Demand Qty. Available"; Rec."Demand Qty. Available")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Available Quantity';
                    ToolTip = 'Specifies how many of the demand quantity are available.';
                }
                field("Demand Quantity"; Rec."Demand Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity on the demand that the planning line represents.';
                    Visible = false;
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

