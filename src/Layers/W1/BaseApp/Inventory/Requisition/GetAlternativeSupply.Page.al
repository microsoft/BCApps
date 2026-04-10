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
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Demand Date"; Rec."Demand Date")
                {
                    ApplicationArea = Basic, Suite;
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
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Needed Quantity"; Rec."Needed Quantity")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Demand Qty. Available"; Rec."Demand Qty. Available")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Available Quantity';
                }
                field("Demand Quantity"; Rec."Demand Quantity")
                {
                    ApplicationArea = Basic, Suite;
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

