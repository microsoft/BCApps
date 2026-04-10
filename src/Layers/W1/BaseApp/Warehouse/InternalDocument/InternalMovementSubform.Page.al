// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InternalDocument;

using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

page 7398 "Internal Movement Subform"
{
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Internal Movement Line";

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
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("From Bin Code"; Rec."From Bin Code")
                {
                    ApplicationArea = Warehouse;

                    trigger OnValidate()
                    begin
                        FromBinCodeOnAfterValidate();
                    end;
                }
                field("To Bin Code"; Rec."To Bin Code")
                {
                    ApplicationArea = Warehouse;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. (Base)"; Rec."Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of units to be moved.';
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
                        ShowBinContent();
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
                        OpenItemTrackingLinesForm();
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

    local procedure GetActualSortMethod(): Enum "Warehouse Internal Sorting Method"
    var
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        if InternalMovementHeader.Get(Rec."No.") then
            exit(InternalMovementHeader."Sorting Method");
    end;

    local procedure ShowBinContent()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.ShowBinContents(Rec."Location Code", Rec."Item No.", Rec."Variant Code", Rec."From Bin Code");
    end;

    local procedure OpenItemTrackingLinesForm()
    begin
        Rec.OpenItemTrackingLines();
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

