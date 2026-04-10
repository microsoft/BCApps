// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

page 7304 "Bin Content"
{
    Caption = 'Bin Content';
    DataCaptionExpression = Rec.GetCaption();
    DelayedInsert = true;
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
                }
                field("Fixed"; Rec.Fixed)
                {
                    ApplicationArea = Warehouse;
                }
                field(Default; Rec.Default)
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
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
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
                }
                field("Pick Quantity (Base)"; Rec."Pick Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the item, in the base unit of measure, will be picked from the bin.';
                    Visible = false;
                }
                field("ATO Components Pick Qty (Base)"; Rec."ATO Components Pick Qty (Base)")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many assemble-to-order units are picked for assembly.';
                    Visible = false;
                }
                field("Negative Adjmt. Qty. (Base)"; Rec."Negative Adjmt. Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many item units, in the base unit of measure, will be posted on journal lines as negative quantities.';
                    Visible = false;
                }
                field("Put-away Quantity (Base)"; Rec."Put-away Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the item, in the base unit of measure, will be put away in the bin.';
                    Visible = false;
                }
                field("Positive Adjmt. Qty. (Base)"; Rec."Positive Adjmt. Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many item units, in the base unit of measure, will be posted on journal lines as positive quantities.';
                    Visible = false;
                }
                field(CalcQtyAvailToTakeUOM; Rec.CalcQtyAvailToTakeUOM())
                {
                    ApplicationArea = Warehouse;
                    AutoFormatType = 0;
                    Caption = 'Available Qty. to Take';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is available in the bin.';
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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if xRec."Location Code" <> '' then
            Rec."Location Code" := xRec."Location Code";
        if xRec."Unit of Measure Code" <> '' then
            Rec."Unit of Measure Code" := xRec."Unit of Measure Code";
        if xRec."Qty. per Unit of Measure" > 1 then
            Rec."Qty. per Unit of Measure" := xRec."Qty. per Unit of Measure";
        Rec.SetUpNewLine();
    end;
}

