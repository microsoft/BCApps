// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InternalDocument;

using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

page 7355 "Internal Put-away Subform"
{
    Caption = 'Lines';
    DelayedInsert = true;
    InsertAllowed = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Whse. Internal Put-away Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;

                    trigger OnValidate()
                    begin
                        ItemNoOnAfterValidate();
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field("From Zone Code"; Rec."From Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("From Bin Code"; Rec."From Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;

                    trigger OnValidate()
                    begin
                        FromBinCodeOnAfterValidate();
                    end;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. (Base)"; Rec."Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that should be put away, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Outstanding"; Rec."Qty. Outstanding")
                {
                    ApplicationArea = Warehouse;
                    Visible = true;
                }
                field("Qty. Put Away"; Rec."Qty. Put Away")
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. Put Away (Base)"; Rec."Qty. Put Away (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the line that is registered as put away, in the base unit of measure.';
                    Visible = false;
                }
                field("Put-away Qty."; Rec."Put-away Qty.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Put-away Qty. (Base)"; Rec."Put-away Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity in the put-away instructions assigned to be put away, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Outstanding (Base)"; Rec."Qty. Outstanding (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that still needs to be handled, expressed in the base unit of measure.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Warehouse;

                    trigger OnValidate()
                    begin
                        DueDateOnAfterValidate();
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Bin Contents List")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents List';
                    Image = BinContent;
                    ToolTip = 'View the contents of the selected bin and the parameters that define how items are routed through the bin.';

                    trigger OnAction()
                    begin
                        ShowBinContents();
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine(xRec);
    end;

    var
        SortMethod: Option " ",Item,"Shelf/Bin No.","Due Date";

    local procedure ShowBinContents()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.ShowBinContents(Rec."Location Code", Rec."Item No.", Rec."Variant Code", Rec."From Bin Code");
    end;

    procedure PutAwayCreate()
    var
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        ReleaseWhseInternalPutAway: Codeunit "Whse. Int. Put-away Release";
    begin
        WhseInternalPutAwayLine.Copy(Rec);
        WhseInternalPutAwayHeader.Get(Rec."No.");
        if WhseInternalPutAwayHeader.Status = WhseInternalPutAwayHeader.Status::Open then
            ReleaseWhseInternalPutAway.Release(WhseInternalPutAwayHeader);
        Rec.CreatePutAwayDoc(WhseInternalPutAwayLine);
    end;

    local procedure GetActualSortMethod(): Enum "Warehouse Internal Sorting Method"
    var
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
    begin
        if WhseInternalPutAwayHeader.Get(Rec."No.") then
            exit(WhseInternalPutAwayHeader."Sorting Method");

        exit("Warehouse Internal Sorting Method"::None);
    end;

    local procedure ItemNoOnAfterValidate()
    begin
        if GetActualSortMethod().AsInteger() = SortMethod::Item then
            CurrPage.Update();
    end;

    local procedure FromBinCodeOnAfterValidate()
    begin
        if GetActualSortMethod().AsInteger() = SortMethod::"Shelf/Bin No." then
            CurrPage.Update();
    end;

    local procedure DueDateOnAfterValidate()
    begin
        if GetActualSortMethod().AsInteger() = SortMethod::"Due Date" then
            CurrPage.Update();
    end;
}

