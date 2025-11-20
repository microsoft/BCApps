// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Ledger;
using Microsoft.Warehouse.Structure;

page 6500 "Item Tracking Summary"
{
    Caption = 'Item Tracking Summary';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Entry Summary";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the lot number for which availability is presented in the Item Tracking Summary window.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the serial number for which availability is presented in the Item Tracking Summary window.';
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the package number for which availability is presented in the Item Tracking Summary window.';
                }
                field("Warranty Date"; Rec."Warranty Date")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the warranty expiration date, if any, of the item carrying the item tracking number.';
                    Visible = false;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the expiration date, if any, of the item carrying the item tracking number.';
                    Visible = false;
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                    ApplicationArea = ItemTracking;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the item in inventory.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntries(Rec.FieldNo("Total Quantity"));
                    end;
                }
                field("Total Requested Quantity"; Rec."Total Requested Quantity")
                {
                    ApplicationArea = ItemTracking;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the serial, lot or package number that is requested in all documents.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntries(Rec.FieldNo("Total Requested Quantity"));
                    end;
                }
                field("Current Pending Quantity"; Rec."Current Pending Quantity")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the quantity from the item tracking line that is selected on the document but not yet committed to the database.';
                }
                field("Total Available Quantity"; Rec."Total Available Quantity")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the quantity available for the user to request, in entries of the type on the line.';
                }
                field("Current Reserved Quantity"; Rec."Current Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of items in the entry that are reserved for the line that the Reservation window is opened from.';
                    Visible = false;
                }
                field("Total Reserved Quantity"; Rec."Total Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the relevant item that is reserved on documents or entries of the type on the line.';
                    Visible = false;
                }
                field("Bin Content"; Rec."Bin Content")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item in the bin specified in the document line.';
                    Visible = BinContentVisible;

                    trigger OnDrillDown()
                    begin
                        DrillDownBinContent(Rec.FieldNo("Bin Content"));
                        OnAfterDrillDownBinContent(TempReservationEntry);
                    end;
                }
                field("Selected Quantity"; Rec."Selected Quantity")
                {
                    ApplicationArea = ItemTracking;
                    Editable = SelectedQuantityEditable;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies the quantity of each serial, lot or package number that you want to use to fulfill the demand for the transaction.';
                    Visible = SelectedQuantityVisible;

                    trigger OnValidate()
                    begin
                        SelectedQuantityOnAfterValidate();
                    end;
                }
            }
            group(Control50)
            {
                ShowCaption = false;
                fixed(Control1901775901)
                {
                    ShowCaption = false;
                    group(Selectable)
                    {
                        Caption = 'Selectable';
                        Visible = MaxQuantity1Visible;
                        field(MaxQuantity1; MaxQuantity)
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Selectable';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the value from the Undefined field on the Item Tracking Lines window. This value indicates how much can be selected.';
                        }
                    }
                    group(Selected)
                    {
                        Caption = 'Selected';
                        Visible = Selected1Visible;
                        field(Selected1; SelectedQuantity)
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Selected';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the sum of the quantity that you have selected. It Specifies a total of the quantities in the Selected Quantity fields.';
                        }
                    }
                    group(Undefined)
                    {
                        Caption = 'Undefined';
                        Visible = Undefined1Visible;
                        field(Undefined1; MaxQuantity - SelectedQuantity)
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Caption = 'Undefined';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the difference between the quantity that can be selected for the document line, and the quantity selected in this window.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateIfFiltersHaveChanged();
    end;

    trigger OnInit()
    begin
        Undefined1Visible := true;
        Selected1Visible := true;
        MaxQuantity1Visible := true;
        BinContentVisible := true;
    end;

    trigger OnOpenPage()
    begin
        UpdateSelectedQuantity();

        BinContentVisible := CurrBinCode <> '';
    end;

    var
        CurrItemTrackingCode: Record "Item Tracking Code";
        xFilterRec: Record "Entry Summary";
        ItemTrackingDataCollection: Codeunit "Item Tracking Data Collection";
        MaxQuantity: Decimal;
        QtyRoundingPrecisionBase: Decimal;
        SelectedQuantity: Decimal;
        CurrBinCode: Code[20];

    protected var
        TempReservationEntry: Record "Reservation Entry" temporary;
        SelectedQuantityVisible: Boolean;
        BinContentVisible: Boolean;
        MaxQuantity1Visible: Boolean;
        Selected1Visible: Boolean;
        Undefined1Visible: Boolean;
        SelectedQuantityEditable: Boolean;

    procedure SetSources(var ReservEntry: Record "Reservation Entry"; var EntrySummary: Record "Entry Summary")
    var
        xEntrySummary: Record "Entry Summary";
    begin
        TempReservationEntry.Reset();
        TempReservationEntry.DeleteAll();
        if ReservEntry.Find('-') then
            repeat
                TempReservationEntry := ReservEntry;
                TempReservationEntry.Insert();
            until ReservEntry.Next() = 0;

        xEntrySummary.Copy(Rec);
        OnSetSourcesOnAfterxEntrySummarySetview(xEntrySummary, TempReservationEntry);

        Rec.Reset();
        Rec.DeleteAll();
        if EntrySummary.FindSet() then
            repeat
                if EntrySummary.HasQuantity() then begin
                    Rec := EntrySummary;
                    Rec.Insert();
                end;
            until EntrySummary.Next() = 0;
        Rec.SetView(xEntrySummary.GetView());
        UpdateSelectedQuantity();
        if Rec.Get(xEntrySummary."Entry No.") then;
    end;

    procedure SetSelectionMode(SelectionMode: Boolean)
    begin
        SelectedQuantityVisible := SelectionMode;
        SelectedQuantityEditable := SelectionMode;
        MaxQuantity1Visible := SelectionMode;
        Selected1Visible := SelectionMode;
        Undefined1Visible := SelectionMode;
    end;

    procedure SetMaxQuantity(MaxQty: Decimal)
    begin
        MaxQuantity := MaxQty;
    end;

    procedure SetQtyRoundingPrecision(QRoundingPrecisionBase: Decimal)
    begin
        QtyRoundingPrecisionBase := QRoundingPrecisionBase;
    end;

    procedure SetCurrentBinAndItemTrkgCode(BinCode: Code[20]; ItemTrackingCode: Record "Item Tracking Code")
    begin
        ItemTrackingDataCollection.SetCurrentBinAndItemTrkgCode(BinCode, ItemTrackingCode);
        BinContentVisible := BinCode <> '';
        CurrBinCode := BinCode;
        CurrItemTrackingCode := ItemTrackingCode;
        OnAfterSetCurrentBinAndItemTrkgCode(CurrBinCode, CurrItemTrackingCode, BinContentVisible, Rec, TempReservationEntry);
    end;

    procedure AutoSelectTrackingNo()
    var
        AvailableQty: Decimal;
        SelectedQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoSelectTrackingNo(Rec, MaxQuantity, IsHandled);
        if IsHandled then
            exit;

        if MaxQuantity = 0 then
            exit;

        SelectedQty := MaxQuantity;
        if Rec.FindSet() then
            repeat
                Rec."Qty. Rounding Precision (Base)" := QtyRoundingPrecisionBase;

                AvailableQty := Rec."Total Available Quantity";
                if Rec."Bin Active" then
                    AvailableQty := MinValueAbs(Rec.QtyAvailableToSelectFromBin(), Rec."Total Available Quantity");

                AvailableQty -= Rec."Non-specific Reserved Qty.";

                if AvailableQty > 0 then begin
                    Rec."Selected Quantity" := MinValueAbs(AvailableQty, SelectedQty);
                    SelectedQty -= Rec."Selected Quantity";
                    Rec.Modify();
                end;
            until (Rec.Next() = 0) or (SelectedQty <= 0);
    end;

    local procedure MinValueAbs(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Abs(Value1) < Abs(Value2) then
            exit(Value1);

        exit(Value2);
    end;

    local procedure UpdateSelectedQuantity()
    var
        xEntrySummary: Record "Entry Summary";
    begin
        if not SelectedQuantityVisible then
            exit;
        if Rec.Modify() then; // Ensure that changes to current rec are included in CALCSUMS
        xEntrySummary := Rec;
        Rec.CalcSums("Selected Quantity");
        SelectedQuantity := Rec."Selected Quantity";
        Rec := xEntrySummary;

        OnAfterUpdateSelectedQuantity(Rec, SelectedQuantity);
    end;

    procedure GetSelected(var EntrySummary: Record "Entry Summary")
    begin
        EntrySummary.Reset();
        EntrySummary.DeleteAll();
        Rec.SetFilter("Selected Quantity", '<>%1', 0);
        if Rec.FindSet() then
            repeat
                EntrySummary := Rec;
                EntrySummary.Insert();
            until Rec.Next() = 0;
    end;

    protected procedure DrillDownEntries(FieldNumber: Integer)
    var
        TempReservEntry2: Record "Reservation Entry" temporary;
    begin
        TempReservationEntry.Reset();
        TempReservationEntry.SetCurrentKey(
          "Item No.", "Source Type", "Source Subtype", "Reservation Status",
          "Location Code", "Variant Code", "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");

        TempReservationEntry.SetTrackingFilterFromEntrySummaryIfNotBlank(Rec);
        OnDrillDownEntriesOnAfterTempReservEntrySetFilters(TempReservationEntry, Rec);

        case FieldNumber of
            Rec.FieldNo("Total Quantity"):
                begin
                    // An Item Ledger Entry will in itself be represented with a surplus TempReservEntry. Order tracking
                    // and reservations against Item Ledger Entries are therefore kept out, as these quantities would
                    // otherwise be represented twice in the drill down.

                    TempReservationEntry.SetRange(Positive, true);
                    TempReservEntry2.Copy(TempReservationEntry);  // Copy key
                    if TempReservationEntry.FindSet() then
                        repeat
                            TempReservEntry2 := TempReservationEntry;
                            if TempReservationEntry."Source Type" = DATABASE::"Item Ledger Entry" then begin
                                if TempReservationEntry."Reservation Status" = TempReservationEntry."Reservation Status"::Surplus then
                                    TempReservEntry2.Insert();
                            end else
                                TempReservEntry2.Insert();
                        until TempReservationEntry.Next() = 0;
                    TempReservEntry2.Ascending(false);
                    PAGE.RunModal(PAGE::"Avail. - Item Tracking Lines", TempReservEntry2);
                end;
            Rec.FieldNo("Total Requested Quantity"):
                begin
                    TempReservationEntry.SetRange(Positive, false);
                    TempReservationEntry.Ascending(false);
                    PAGE.RunModal(PAGE::"Avail. - Item Tracking Lines", TempReservationEntry);
                end;
        end;

        OnAfterDrillDownEntries(TempReservationEntry);
    end;

    protected procedure DrillDownBinContent(FieldNumber: Integer)
    var
        BinContent: Record "Bin Content";
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        if CurrBinCode = '' then
            exit;
        TempReservationEntry.Reset();
        if not TempReservationEntry.FindFirst() then
            exit;

        CurrItemTrackingCode.TestField(Code);

        BinContent.SetRange("Location Code", TempReservationEntry."Location Code");
        BinContent.SetRange("Item No.", TempReservationEntry."Item No.");
        BinContent.SetRange("Variant Code", TempReservationEntry."Variant Code");
        ItemTrackingSetup.CopyTrackingFromItemTrackingCodeWarehouseTracking(CurrItemTrackingCode);
        ItemTrackingSetup.CopyTrackingFromEntrySummary(Rec);
        BinContent.SetTrackingFilterFromItemTrackingSetupIfWhseRequiredIfNotBlank(ItemTrackingSetup);

        if FieldNumber = Rec.FieldNo("Bin Content") then
            BinContent.SetRange("Bin Code", CurrBinCode);

        OnDrillDownBinContentOnAfterBinContentSetFilters(BinContent, Rec);
        PAGE.RunModal(PAGE::"Bin Content", BinContent);
    end;

    local procedure UpdateIfFiltersHaveChanged()
    begin
        // In order to update Selected Quantity when filters have been changed on the form.
        if Rec.GetFilters() = xFilterRec.GetFilters() then
            exit;

        UpdateSelectedQuantity();
        xFilterRec.Copy(Rec);
    end;

    protected procedure SelectedQuantityOnAfterValidate()
    begin
        UpdateSelectedQuantity();
        CurrPage.Update();
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCurrentBinAndItemTrkgCode(var CurrBinCode: Code[20]; var CurrItemTrackingCode: Record "Item Tracking Code"; var BinContentVisible: Boolean; var EntrySummary: Record "Entry Summary"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSelectedQuantity(var EntrySummary: Record "Entry Summary"; var SelectedQuantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoSelectTrackingNo(var EntrySummary: Record "Entry Summary"; var MaxQuantity: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownBinContentOnAfterBinContentSetFilters(var BinContent: Record "Bin Content"; EntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownEntriesOnAfterTempReservEntrySetFilters(var TempReservEntry: Record "Reservation Entry" temporary; EntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetSourcesOnAfterxEntrySummarySetview(var xEntrySummary: Record "Entry Summary"; TempReservEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDrillDownEntries(TempReservationEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDrillDownBinContent(TempReservationEntry: Record "Reservation Entry" temporary)
    begin
    end;
}
