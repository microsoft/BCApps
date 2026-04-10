// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

page 7305 "Bin Contents List"
{
    Caption = 'Bin Contents List';
    DataCaptionExpression = Rec.GetCaption();
    Editable = false;
    PageType = List;
    SourceTable = "Bin Content";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Bin Type Code"; Rec."Bin Type Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Block Movement"; Rec."Block Movement")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Bin Ranking"; Rec."Bin Ranking")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = Warehouse;
                }
                field("Fixed"; Rec.Fixed)
                {
                    ApplicationArea = Warehouse;
                }
                field(Dedicated; Rec.Dedicated)
                {
                    ApplicationArea = Warehouse;
                }
                field("Warehouse Class Code"; Rec."Warehouse Class Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field(CalcQtyUOM; Rec.CalcQtyUOM())
                {
                    ApplicationArea = Warehouse;
                    AutoFormatType = 0;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item in the bin that corresponds to the line.';
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the item, in the base unit of measure, are stored in the bin.';
                }
                field(CalcQtyAvailToTakeUOM; Rec.CalcQtyAvailToTakeUOM())
                {
                    ApplicationArea = Warehouse;
                    AutoFormatType = 0;
                    Caption = 'Available Qty. to Take';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is available in the bin.';
                    Visible = false;
                }
                field("Min. Qty."; Rec."Min. Qty.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Max. Qty."; Rec."Max. Qty.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Cross-Dock Bin"; Rec."Cross-Dock Bin")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control3; "Lot Numbers by Bin FactBox")
            {
                ApplicationArea = ItemTracking;
                SubPageLink = "Item No." = field("Item No."),
                              "Variant Code" = field("Variant Code"),
                              "Location Code" = field("Location Code");
                Visible = false;
            }
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

    trigger OnOpenPage()
    begin
        if Initialized then begin
            Rec.FilterGroup(2);
            Rec.SetRange("Location Code", LocationCode);
            Rec.FilterGroup(0);
        end;
    end;

    var
        LocationCode: Code[10];
        Initialized: Boolean;

    procedure Initialize(LocationCode2: Code[10])
    begin
        LocationCode := LocationCode2;
        Initialized := true;
    end;
}

