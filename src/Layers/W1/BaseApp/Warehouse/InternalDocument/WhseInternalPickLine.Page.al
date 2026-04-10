// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InternalDocument;

using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

page 7358 "Whse. Internal Pick Line"
{
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Whse. Internal Pick Line";

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
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Visible = false;
                }
                field("To Zone Code"; Rec."To Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("To Bin Code"; Rec."To Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ToBinCodeOnAfterValidate();
                    end;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ShelfNoOnAfterValidate();
                    end;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. (Base)"; Rec."Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that should be picked, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Outstanding"; Rec."Qty. Outstanding")
                {
                    ApplicationArea = Warehouse;
                    Visible = true;
                }
                field("Qty. Outstanding (Base)"; Rec."Qty. Outstanding (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that still needs to be handled, in the base unit of measure.';
                    Visible = false;
                }
                field("Pick Qty."; Rec."Pick Qty.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Pick Qty. (Base)"; Rec."Pick Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item in pick instructions assigned to be picked for the line, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Picked"; Rec."Qty. Picked")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Qty. Picked (Base)"; Rec."Qty. Picked (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the line that is registered as picked, in the base unit of measure.';
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
        SortMethod: Enum "Warehouse Internal Sorting Method";

    local procedure ShowBinContents()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.ShowBinContents(Rec."Location Code", Rec."Item No.", Rec."Variant Code", '');
    end;

    procedure PickCreate()
    var
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        ReleaseWhseInternalPick: Codeunit "Whse. Internal Pick Release";
    begin
        WhseInternalPickLine.Copy(Rec);
        WhseInternalPickHeader.Get(WhseInternalPickLine."No.");
        if WhseInternalPickHeader.Status = WhseInternalPickHeader.Status::Open then
            ReleaseWhseInternalPick.Release(WhseInternalPickHeader);
        Rec.CreatePickDoc(WhseInternalPickLine, WhseInternalPickHeader);
    end;

    local procedure GetActualSortMethod(): Enum "Warehouse Internal Sorting Method"
    var
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
    begin
        if WhseInternalPickHeader.Get(Rec."No.") then
            exit(WhseInternalPickHeader."Sorting Method");

        exit(WhseInternalPickHeader."Sorting Method"::None);
    end;

    local procedure ItemNoOnAfterValidate()
    begin
        if GetActualSortMethod() = SortMethod::Item then
            CurrPage.Update();
    end;

    local procedure ToBinCodeOnAfterValidate()
    begin
        if GetActualSortMethod() = SortMethod::"Shelf or Bin" then
            CurrPage.Update();
    end;

    local procedure ShelfNoOnAfterValidate()
    begin
        if GetActualSortMethod() = SortMethod::"Shelf or Bin" then
            CurrPage.Update();
    end;

    local procedure DueDateOnAfterValidate()
    begin
        if GetActualSortMethod() = SortMethod::"Due Date" then
            CurrPage.Update();
    end;
}

