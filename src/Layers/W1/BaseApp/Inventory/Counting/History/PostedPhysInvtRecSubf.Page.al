// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.History;

page 5889 "Posted Phys. Invt. Rec. Subf."
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    Editable = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Pstd. Phys. Invt. Record Line";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Quantity (Base) of the table physical inventory recording line.';
                    Visible = false;
                }
                field("Date Recorded"; Rec."Date Recorded")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Time Recorded"; Rec."Time Recorded")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Person Recorded"; Rec."Person Recorded")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

