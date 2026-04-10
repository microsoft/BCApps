// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Inventory.Item;
using Microsoft.Warehouse.Structure;

report 7314 "Whse. Change Unit of Measure"
{
    Caption = 'Whse. Change Unit of Measure';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        InsertAllowed = false;
        SourceTable = "Warehouse Activity Line";

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Action Type"; Rec."Action Type")
                    {
                        ApplicationArea = Warehouse;
                        Editable = false;
                        ToolTip = 'Specifies if you want to change the unit of measure on a Take line or on a Place line.';
                    }
                    field("Qty. to Handle"; Rec."Qty. to Handle")
                    {
                        ApplicationArea = Warehouse;
                        Editable = false;
                        ToolTip = 'Specifies how many units to handle in this warehouse activity.';
                    }
                    group(From)
                    {
                        Caption = 'From';
                        field("Unit of Measure Code"; Rec."Unit of Measure Code")
                        {
                            ApplicationArea = Warehouse;
                            Editable = false;
                            ToolTip = 'Specifies for a warehouse activity line, such as a warehouse pick, which unit of measure you want.';
                        }
                    }
                    group("To")
                    {
                        Caption = 'To';
                        field(UnitOfMeasureCode; UOMCode)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Unit of Measure Code';
                            TableRelation = "Item Unit of Measure".Code;
                            ToolTip = 'Specifies the unit of measure for a warehouse activity line.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                ItemUOM.Reset();
                                ItemUOM.FilterGroup(2);
                                ItemUOM.SetRange("Item No.", Rec."Item No.");
                                ItemUOM.FilterGroup(0);
                                ItemUOM.Code := WarehouseActivityLine."Unit of Measure Code";
                                if PAGE.RunModal(0, ItemUOM) = ACTION::LookupOK then begin
                                    Text := ItemUOM.Code;
                                    exit(true);
                                end;
                            end;

                            trigger OnValidate()
                            begin
                                ItemUOM.Get(Rec."Item No.", UOMCode);
                                WarehouseActivityLine."Qty. per Unit of Measure" := ItemUOM."Qty. per Unit of Measure";
                                WarehouseActivityLine."Unit of Measure Code" := ItemUOM.Code;
                                CheckUOM();
                                UOMCode := ItemUOM.Code;
                            end;
                        }
                    }
                    field("WarehouseActivityLine.Quantity"; WarehouseActivityLine.Quantity)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Quantity';
                        DecimalPlaces = 0 : 5;
                        Editable = false;
                        ToolTip = 'Specifies the quantity that corresponds to the warehouse activity line.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnAfterGetRecord()
        begin
            UOMCode := Rec."Unit of Measure Code";
            WarehouseActivityLine.Quantity := Rec."Qty. to Handle";
            WarehouseActivityLine."Qty. (Base)" := Rec."Qty. to Handle (Base)";
        end;

        trigger OnOpenPage()
        begin
            Rec.Copy(WarehouseActivityLine);
            Rec.Get(Rec."Activity Type", Rec."No.", Rec."Line No.");
            Rec.SetRecFilter();
            Rec.TestField("Bin Code");
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if CloseAction = ACTION::OK then
                if UOMCode <> Rec."Unit of Measure Code" then
                    ChangeUOM2 := true;
        end;
    }

    labels
    {
    }

    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        BinContent: Record "Bin Content";
        ItemUOM: Record "Item Unit of Measure";
        UOMCode: Code[10];
        QtyAvailBase: Decimal;
        QtyChangeBase: Decimal;
        ChangeUOM2: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'The %1 %2 exceeds the Quantity available to pick %3 of the %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure DefWhseActLine(WhseActLine2: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine.Copy(WhseActLine2);
    end;

    local procedure CheckUOM()
    begin
        Clear(BinContent);
        QtyChangeBase := 0;
        QtyAvailBase := 0;
        if Rec."Serial No." <> '' then
            WarehouseActivityLine.TestField("Qty. per Unit of Measure", 1);
        BinContent."Qty. per Unit of Measure" := WarehouseActivityLine."Qty. per Unit of Measure";

        QtyChangeBase := Rec."Qty. to Handle (Base)";
        if Rec."Action Type" = Rec."Action Type"::Take then
            if BinContent.Get(
                 Rec."Location Code", Rec."Bin Code", Rec."Item No.",
                 Rec."Variant Code", WarehouseActivityLine."Unit of Measure Code")
            then begin
                QtyChangeBase := Rec."Qty. to Handle (Base)";
                if Rec."Activity Type" in [Rec."Activity Type"::Pick, Rec."Activity Type"::"Invt. Pick", Rec."Activity Type"::"Invt. Movement"] then
                    QtyAvailBase := BinContent.CalcQtyAvailToPick(0)
                else
                    QtyAvailBase := BinContent.CalcQtyAvailToTake(0);
                if QtyAvailBase < QtyChangeBase then
                    Error(Text001, Rec.FieldCaption("Qty. (Base)"), QtyChangeBase, BinContent.TableCaption(), Rec.FieldCaption("Bin Code"))
            end else
                Error(Text001, Rec.FieldCaption("Qty. (Base)"), QtyChangeBase, BinContent.TableCaption(), Rec.FieldCaption("Bin Code"));

        if BinContent."Qty. per Unit of Measure" = WarehouseActivityLine."Qty. per Unit of Measure" then begin
            WarehouseActivityLine.Validate("Unit of Measure Code");
            WarehouseActivityLine.Validate(Quantity, Rec."Qty. to Handle (Base)" / WarehouseActivityLine."Qty. per Unit of Measure");
        end else begin
            WarehouseActivityLine.Validate("Unit of Measure Code");
            WarehouseActivityLine."Qty. per Unit of Measure" := BinContent."Qty. per Unit of Measure";
            WarehouseActivityLine.Validate(Quantity, Rec."Qty. to Handle (Base)" / BinContent."Qty. per Unit of Measure");
            WarehouseActivityLine.Validate("Qty. Outstanding");
            WarehouseActivityLine.Validate("Qty. to Handle");
        end;
    end;

    procedure ChangeUOMCode(var WhseActLine: Record "Warehouse Activity Line") ChangeUOM: Boolean
    begin
        WhseActLine := WarehouseActivityLine;
        ChangeUOM := ChangeUOM2;
    end;
}

