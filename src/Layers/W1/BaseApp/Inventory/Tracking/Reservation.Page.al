// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

page 498 Reservation
{
    Caption = 'Reservation';
    DataCaptionExpression = CaptionText;
    DeleteAllowed = false;
    PageType = Worksheet;
    SourceTable = "Entry Summary";
    SourceTableTemporary = true;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ItemNo; ReservEntry."Item No.")
                {
                    ApplicationArea = Reservation;
                    Caption = 'Item No.';
                    Editable = false;
                    ToolTip = 'Specifies the item number of the item that the reservation is for.';
                }
#pragma warning disable AA0100
                field("ReservEntry.""Shipment Date"""; ReservEntry."Shipment Date")
#pragma warning restore AA0100
                {
                    ApplicationArea = Reservation;
                    Caption = 'Shipment Date';
                    Editable = false;
                    ToolTip = 'Specifies the shipment date, expected receipt date, or posting date for the reservation.';
                }
                field("ReservEntry.Description"; ReservEntry.Description)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the reservation in the window.';
                }
                field(QtyToReserveBase; QtyToReserveBase)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Quantity to Reserve';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the item that must be reserved for the line.';
                }
                field(QtyReservedBase; QtyReservedBase)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item reserved for the line.';
                }
                field(UnreservedQuantity; QtyToReserveBase - QtyReservedBase)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Unreserved Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the difference between the Quantity to Reserve field and the Reserved Quantity field.';
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Summary Type"; Rec."Summary Type")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies which type of line or entry is summarized in the entry summary.';
                }
                field("Total Quantity"; ReservMgt.FormatQty(Rec."Total Quantity"))
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    Caption = 'Total Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the item in inventory.';

                    trigger OnDrillDown()
                    begin
                        DrillDownTotalQuantity();
                    end;
                }
                field(TotalReservedQuantity; ReservMgt.FormatQty(Rec."Total Reserved Quantity"))
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    Caption = 'Total Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the item that is reserved on documents or entries.';

                    trigger OnDrillDown()
                    begin
                        DrillDownReservedQuantity();
                    end;
                }
                field(QtyAllocatedInWarehouse; ReservMgt.FormatQty(Rec."Qty. Alloc. in Warehouse"))
                {
                    ApplicationArea = Warehouse;
                    BlankZero = true;
                    Caption = 'Qty. Allocated in Warehouse';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is allocated to activities in the warehouse.';
                }
#pragma warning disable AA0100
                field("ReservMgt.FormatQty(""Res. Qty. on Picks & Shipmts."")"; ReservMgt.FormatQty(Rec."Res. Qty. on Picks & Shipmts."))
#pragma warning restore AA0100
                {
                    ApplicationArea = Warehouse;
                    BlankZero = true;
                    Caption = 'Reserved Qty. on Picks and Shipments';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the sum of the overlap quantities.';
                    Visible = false;
                }
                field(TotalAvailableQuantity; ReservMgt.FormatQty(Rec."Total Available Quantity"))
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    Caption = 'Total Available Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity that is available for the user to reserve from entries of the type.';
                }
                field("Non-specific Reserved Qty."; Rec."Non-specific Reserved Qty.")
                {
                    ApplicationArea = Reservation;
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is reserved but does not have specific item tracking numbers in the reservation.';
                    Visible = false;
                }
                field("Current Reserved Quantity"; ReservMgt.FormatQty(ReservedThisLine(Rec)))
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    Caption = 'Current Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many items in the entry are reserved for the line opened in the Reservation window.';

                    trigger OnDrillDown()
                    begin
                        DrillDownReservedThisLine();
                    end;
                }
            }
            label(NoteText)
            {
                ApplicationArea = Reservation;
                CaptionClass = Format(StrSubstNo(Text009, NonSpecificQty, Rec.FieldCaption("Total Reserved Quantity")));
                Editable = false;
                MultiLine = true;
                Visible = NoteTextVisible;
            }
            group(Filters)
            {
                Caption = 'Filters';
#pragma warning disable AA0100
                field("ReservEntry.""Variant Code"""; ReservEntry."Variant Code")
#pragma warning restore AA0100
                {
                    ApplicationArea = Reservation;
                    Caption = 'Variant Code';
                    Editable = false;
                    ToolTip = 'Specifies the variant code for the reservation.';
                }
#pragma warning disable AA0100
                field("ReservEntry.""Location Code"""; ReservEntry."Location Code")
#pragma warning restore AA0100
                {
                    ApplicationArea = Reservation;
                    Caption = 'Location Code';
                    Editable = false;
                    ToolTip = 'Specifies the location code for the reservation.';
                }
#pragma warning disable AA0100
                field("ReservEntry.""Serial No."""; ReservEntry."Serial No.")
#pragma warning restore AA0100
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Serial No.';
                    Editable = false;
                    ToolTip = 'Specifies the serial number for an item in the reservation.';
                }
#pragma warning disable AA0100
                field("ReservEntry.""Lot No."""; ReservEntry."Lot No.")
#pragma warning restore AA0100
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot No.';
                    Editable = false;
                    ToolTip = 'Specifies the lot number for the reservation.';
                }
                field("Reserv. Package No."; ReservEntry."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Package No.';
                    Editable = false;
                    ToolTip = 'Specifies the package number for the reservation.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(AvailableToReserve)
                {
                    ApplicationArea = Reservation;
                    Caption = '&Available to Reserve';
                    Image = ItemReservation;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the quantities on documents or in inventory that are available to reserve for the item on the line. The two actions, Auto Reserve and Reserve from Current Line make reservations from the quantities in this view.';

                    trigger OnAction()
                    begin
                        DrillDownTotalQuantity();
                    end;
                }
                action("&Reservation Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = '&Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View all reservations that are made for the item, either manually or automatically.';

                    trigger OnAction()
                    begin
                        DrillDownReservedThisLine();
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Auto Reserve")
                {
                    ApplicationArea = Reservation;
                    Caption = '&Auto Reserve';
                    Image = AutoReserve;
                    ToolTip = 'Automatically reserve the first available quantity for the item on the line. ';

                    trigger OnAction()
                    begin
                        AutoReserve();
                    end;
                }
                action("Reserve from Current Line")
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve from Current Line';
                    Image = LineReserve;
                    Scope = Repeater;
                    ToolTip = 'Open the view of quantities available to reserve and select which to reserve.';

                    trigger OnAction()
                    var
                        RemainingQtyToReserveBase: Decimal;
                        QtyReservedBefore: Decimal;
                        RemainingQtyToReserve: Decimal;
                    begin
                        RemainingQtyToReserveBase := QtyToReserveBase - QtyReservedBase;
                        if RemainingQtyToReserveBase = 0 then
                            Error(Text000);
                        QtyReservedBefore := QtyReservedBase;
                        if HandleItemTracking then
                            ReservMgt.SetItemTrackingHandling(2);
                        RemainingQtyToReserve := QtyToReserve - QtyReserved;
                        ReservMgt.AutoReserveOneLine(
                          Rec."Entry No.", RemainingQtyToReserve, RemainingQtyToReserveBase, ReservEntry.Description,
                          ReservEntry."Shipment Date");
                        UpdateReservFrom();
                        if QtyReservedBefore = QtyReservedBase then
                            Error(Text002);

                        OnAfterReserveFromCurrentLine(ReservEntry);
                    end;
                }
                action(CancelReservationCurrentLine)
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = '&Cancel Reservation from Current Line';
                    Image = Cancel;
                    ToolTip = 'Cancel the selected reservation entry.';
                    Scope = Repeater;
                    trigger OnAction()
                    var
                        ReservEntry3: Record "Reservation Entry";
                        RecordsFound: Boolean;
                    begin
                        if not Confirm(Text003, false, Rec."Summary Type") then
                            exit;
                        Clear(ReservEntry2);
                        ReservEntry2 := ReservEntry;
                        ReservEntry2.SetPointerFilter();
                        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
                        ReservEntry2.SetRange("Disallow Cancellation", false);
                        if ReservEntry2.FindSet() then
                            repeat
                                ReservEntry3.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive);
                                if RelatesToSummEntry(ReservEntry3, Rec) then begin
                                    ReservEngineMgt.CancelReservation(ReservEntry2);
                                    RecordsFound := true;
                                end;
                            until ReservEntry2.Next() = 0;

                        if RecordsFound then
                            UpdateReservFrom()
                        else
                            Error(Text005);

                        OnAfterCancelReservationCurrentLine(ReservEntry);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Reserve from Current Line_Promoted"; "Reserve from Current Line")
                {
                }
                actionref("Auto Reserve_Promoted"; "Auto Reserve")
                {
                }
                actionref(CancelReservationCurrentLine_Promoted; CancelReservationCurrentLine)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(AvailableToReserve_Promoted; AvailableToReserve)
                {
                }
                actionref("&Reservation Entries_Promoted"; "&Reservation Entries")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        FormIsOpen := true;
    end;

    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        UOMMgt: Codeunit "Unit of Measure Management";
        SourceRecRef: RecordRef;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        QtyReserved: Decimal;
        QtyReservedBase: Decimal;
        ItemTrackingQtyToReserve: Decimal;
        ItemTrackingQtyToReserveBase: Decimal;
        NonSpecificQty: Decimal;
        CaptionText: Text;
        FullAutoReservation: Boolean;
        FormIsOpen: Boolean;
        HandleItemTracking: Boolean;
        NoteTextVisible: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Fully reserved.';
        Text001: Label 'Full automatic Reservation is not possible.\Reserve manually.';
        Text002: Label 'There is nothing available to reserve.';
#pragma warning disable AA0470
        Text003: Label 'Do you want to cancel all reservations in the %1?';
#pragma warning restore AA0470
        Text005: Label 'There are no reservations to cancel.';
        Text008: Label 'Action canceled.';
#pragma warning disable AA0470
        Text009: Label '%1 of the %2 are nonspecific and may be available.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ReservConfirmQst: Label 'Do you want to reserve specific tracking numbers?';

    procedure SetReservSource(CurrentRecordVar: Variant)
    begin
        SourceRecRef.GetTable(CurrentRecordVar);
        SetReservSource(SourceRecRef, Enum::"Transfer Direction"::Outbound);
    end;

    procedure SetReservSource(CurrentRecordVar: Variant; Direction: Enum "Transfer Direction")
    begin
        SourceRecRef.GetTable(CurrentRecordVar);
        SetReservSource(SourceRecRef, Direction);
    end;

    procedure SetReservSource(CurrentSourceRecRef: RecordRef; Direction: Enum "Transfer Direction")
    begin
        SourceRecRef := CurrentSourceRecRef;

        OnSetReservSource(SourceRecRef, ReservEntry, CaptionText, Direction.AsInteger());

        UpdateReservFrom();

        // Invoke events for compatibility with 15.X, to be removed after obsoleting events below
#if not CLEAN25
        case SourceRecRef.Number of
            Database::Microsoft.Sales.Document."Sales Line":
                OnAfterSetSalesLine(Rec, ReservEntry);
            Database::Microsoft.Inventory.Requisition."Requisition Line":
                OnAfterSetReqLine(Rec, ReservEntry);
            Database::Microsoft.Purchases.Document."Purchase Line":
                OnAfterSetPurchLine(Rec, ReservEntry);
            Database::Microsoft.Inventory.Journal."Item Journal Line":
                OnAfterSetItemJnlLine(Rec, ReservEntry);
            Database::Microsoft.Manufacturing.Document."Prod. Order Line":
                OnAfterSetProdOrderLine(Rec, ReservEntry);
            Database::Microsoft.Manufacturing.Document."Prod. Order Component":
                OnAfterSetProdOrderComponent(Rec, ReservEntry);
            Database::Microsoft.Assembly.Document."Assembly Header":
                OnAfterSetAssemblyHeader(Rec, ReservEntry);
            Database::Microsoft.Assembly.Document."Assembly Line":
                OnAfterSetAssemblyLine(Rec, ReservEntry);
            Database::Microsoft.Inventory.Planning."Planning Component":
                OnAfterSetPlanningComponent(Rec, ReservEntry);
            Database::Microsoft.Service.Document."Service Line":
                OnAfterSetServiceLine(Rec, ReservEntry);
            Database::Microsoft.Projects.Project.Planning."Job Planning Line":
                OnAfterSetJobPlanningLine(Rec, ReservEntry);
            Database::Microsoft.Inventory.Transfer."Transfer Line":
                OnAfterSetTransLine(Rec, ReservEntry);
        end;
#endif
    end;

    procedure SetReservEntry(ReservEntry2: Record "Reservation Entry")
    begin
        ReservEntry := ReservEntry2;
        UpdateReservMgt();
    end;

    procedure FilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        FilterReservEntry.SetRange("Item No.", ReservEntry."Item No.");

        OnFilterReservEntry(FilterReservEntry, ReservEntrySummary);

        OnFilterReservEntryOnAfterFilterSource(FilterReservEntry, ReservEntrySummary, ReservEntry);

        FilterReservEntry.SetRange("Reservation Status", FilterReservEntry."Reservation Status"::Reservation);
        FilterReservEntry.SetRange("Location Code", ReservEntry."Location Code");
        FilterReservEntry.SetRange("Variant Code", ReservEntry."Variant Code");
        if ReservEntry.TrackingExists() then
            FilterReservEntry.SetTrackingFilterFromReservEntry(ReservEntry);
        FilterReservEntry.SetRange(Positive, ReservMgt.IsPositive());
    end;

    local procedure RelatesToSummEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary"): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnAfterRelatesToSummEntry(ReservEntrySummary, FilterReservEntry, IsHandled);
        exit(IsHandled);
    end;

    procedure UpdateReservFrom()
    var
        EntrySummary: Record "Entry Summary";
        QtyPerUOM: Decimal;
        QtyReservedIT: Decimal;
    begin
        if not FormIsOpen then
            GetSerialLotNo(ItemTrackingQtyToReserve, ItemTrackingQtyToReserveBase);

        OnGetQtyPerUOMFromSourceRecRef(
            SourceRecRef, QtyPerUOM, QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, ReservEntry);

        OnAfterGetQtyPerUOMFromSource(ReservEntry, QtyPerUOM);

        UpdateReservMgt();
        ReservMgt.UpdateStatistics(Rec, ReservEntry."Shipment Date", HandleItemTracking);

        if HandleItemTracking then begin
            EntrySummary := Rec;
            QtyReservedBase := 0;
            if Rec.FindSet() then
                repeat
                    QtyReservedBase += ReservedThisLine(Rec);
                until Rec.Next() = 0;
            QtyReservedIT := Round(QtyReservedBase / QtyPerUOM, UOMMgt.QtyRndPrecision());
            if Abs(QtyReserved - QtyReservedIT) > UOMMgt.QtyRndPrecision() then
                QtyReserved := QtyReservedIT;
            QtyToReserveBase := ItemTrackingQtyToReserveBase;
            if Abs(ItemTrackingQtyToReserve - QtyToReserve) > UOMMgt.QtyRndPrecision() then
                QtyToReserve := ItemTrackingQtyToReserve;
            Rec := EntrySummary;
        end;

        UpdateNonSpecific(); // Late Binding

        OnAfterUpdateReservFrom(Rec);

        if FormIsOpen then
            CurrPage.Update();
    end;

    local procedure UpdateReservMgt()
    begin
        Clear(ReservMgt);
        ReservMgt.SetReservSource(SourceRecRef, Enum::"Transfer Direction".FromInteger(ReservEntry."Source Subtype"));
        OnUpdateReservMgt(ReservEntry, ReservMgt);
        ReservMgt.SetTrackingFromReservEntry(ReservEntry);
    end;

    protected procedure DrillDownTotalQuantity()
    var
        Location: Record Location;
        AvailableItemTrackingLines: Page "Avail. - Item Tracking Lines";
    begin
        if HandleItemTracking and (Rec."Entry No." <> 1) then begin
            Clear(AvailableItemTrackingLines);
            AvailableItemTrackingLines.SetItemTrackingLine(
                Rec."Table ID", Rec."Source Subtype", ReservEntry, ReservMgt.IsPositive(), ReservEntry."Shipment Date");
            AvailableItemTrackingLines.RunModal();
            exit;
        end;

        ReservEntry2 := ReservEntry;
        if not Location.Get(ReservEntry2."Location Code") then
            Clear(Location);

        OnDrillDownTotalQuantity(SourceRecRef, Rec, ReservEntry2, Location, QtyToReserveBase - QtyReservedBase);

        UpdateReservFrom();
    end;

    protected procedure DrillDownReservedQuantity()
    begin
        ReservEntry2.Reset();

        ReservEntry2.SetCurrentKey(
          "Item No.", "Source Type", "Source Subtype", "Reservation Status", "Location Code", "Variant Code",
          "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");

        FilterReservEntry(ReservEntry2, Rec);
        PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry2);

        UpdateReservFrom();
    end;

    protected procedure DrillDownReservedThisLine()
    var
        ReservEntry3: Record "Reservation Entry";
        TrackingMatch: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDrillDownReservedThisLine(Rec, ReservEntry, ReservEntry2, IsHandled);
        if IsHandled then
            exit;

        Clear(ReservEntry2);

        ReservEntry2.SetCurrentKey(
          "Item No.", "Source Type", "Source Subtype", "Reservation Status", "Location Code", "Variant Code",
          "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");

        FilterReservEntry(ReservEntry2, Rec);
        if ReservEntry2.Find('-') then
            repeat
                ReservEntry3.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive);

                if ReservEntry.TrackingExists() then
                    TrackingMatch := ReservEntry3.HasSameTracking(ReservEntry)
                else
                    TrackingMatch := true;

                ReservEntry2.Mark(
                  ReservEntry3.HasSamePointer(ReservEntry) and
                  ((TrackingMatch and HandleItemTracking) or not HandleItemTracking));
            until ReservEntry2.Next() = 0;

        ReservEntry2.MarkedOnly(true);
        PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry2);

        UpdateReservFrom();
    end;

    procedure ReservedThisLine(ReservSummEntry2: Record "Entry Summary" temporary) ReservedQuantity: Decimal
    var
        ReservEntry3: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReservedThisLine(Rec, ReservEntry, ReservEntry2, ReservSummEntry2, ReservedQuantity, IsHandled);
        if IsHandled then
            exit;

        Clear(ReservEntry2);

        ReservEntry2.SetCurrentKey(
          "Item No.", "Source Type", "Source Subtype", "Reservation Status", "Location Code", "Variant Code",
          "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");
        ReservedQuantity := 0;

        FilterReservEntry(ReservEntry2, ReservSummEntry2);
        if ReservEntry2.Find('-') then
            repeat
                ReservEntry3.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive);
                if ReservEntry3.HasSamePointer(ReservEntry) and
                   ((ReservEntry3.HasSameTracking(ReservEntry) and HandleItemTracking) or not HandleItemTracking)
                then
                    ReservedQuantity += ReservEntry2."Quantity (Base)" * CreateReservEntry.SignFactor(ReservEntry2);
            until ReservEntry2.Next() = 0;

        exit(ReservedQuantity);
    end;

    local procedure GetSerialLotNo(var ItemTrackingQtyToReserve: Decimal; var ItemTrackingQtyToReserveBase: Decimal)
    var
        Item: Record Item;
        ReservEntry2: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SignFactor: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSerialLotNo(ReservEntry, ItemTrackingQtyToReserve, ItemTrackingQtyToReserveBase, IsHandled);
        if IsHandled then
            exit;

        Item.Get(ReservEntry."Item No.");
        if Item."Item Tracking Code" = '' then
            exit;
        ReservEntry2 := ReservEntry;
        ReservEntry2.SetPointerFilter();
        ItemTrackingMgt.SumUpItemTracking(ReservEntry2, TempTrackingSpecification, true, true);

        if TempTrackingSpecification.Find('-') then begin
            if not Confirm(StrSubstNo(ReservConfirmQst, true)) then
                exit;
            repeat
                TempReservEntry.TransferFields(TempTrackingSpecification);
                TempReservEntry.Insert();
            until TempTrackingSpecification.Next() = 0;

            if PAGE.RunModal(PAGE::"Item Tracking List", TempReservEntry) = ACTION::LookupOK then begin
                ReservEntry.CopyTrackingFromReservEntry(TempReservEntry);
                OnGetSerialLotNoOnAfterSetTrackingFields(ReservEntry, TempReservEntry);
                CaptionText += StrSubstNo(ReservConfirmQst, ReservEntry.GetTrackingText());
                SignFactor := CreateReservEntry.SignFactor(TempReservEntry);
                ItemTrackingQtyToReserveBase := TempReservEntry."Quantity (Base)" * SignFactor;
                ItemTrackingQtyToReserve :=
                  Round(ItemTrackingQtyToReserveBase / TempReservEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                HandleItemTracking := true;
            end else
                Error(Text008);
        end;
    end;

    local procedure UpdateNonSpecific()
    begin
        Rec.SetFilter("Non-specific Reserved Qty.", '>%1', 0);
        NoteTextVisible := not Rec.IsEmpty();
        NonSpecificQty := Rec."Non-specific Reserved Qty.";
        Rec.SetRange("Non-specific Reserved Qty.");
    end;

    procedure AutoReserve()
    var
        IsHandled: Boolean;
    begin
        OnBeforeAutoReserve(
            ReservEntry, FullAutoReservation, QtyToReserve, QtyReserved, QtyToReserveBase, QtyReservedBase, IsHandled);
        if not IsHandled then begin
            if Abs(QtyToReserveBase) - Abs(QtyReservedBase) = 0 then
                Error(Text000);
            ReservMgt.AutoReserve(
                FullAutoReservation, ReservEntry.Description,
                ReservEntry."Shipment Date", QtyToReserve - QtyReserved, QtyToReserveBase - QtyReservedBase);
        end;

        if not FullAutoReservation then
            Message(Text001);
        UpdateReservFrom();

        OnAfterAutoReserve(ReservEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoReserve(ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCancelReservationCurrentLine(ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetQtyPerUOMFromSource(ReservationEntry: Record "Reservation Entry"; var QtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelatesToSummEntry(FromEntrySummary: Record "Entry Summary"; var FilterReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReserveFromCurrentLine(ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateReservFrom(var EntrySummary: Record "Entry Summary")
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event in codeunit SalesLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event in codeunit ReqLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReqLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event in codeunit PurchLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPurchLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event in codeunit TransferLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTransLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event in codeunit ServiceLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetServiceLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event in codeunit ProdOrderLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProdOrderLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event in codeunit ProdOrderCompReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProdOrderComponent(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event in codeunit ItemJnlLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemJnlLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event in codeunit JobPlanningLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetJobPlanningLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event in codeunit AssemblyHeaderReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAssemblyHeader(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event in codeunit AssemblyLineReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAssemblyLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event in codeunit PlngComponentReserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPlanningComponent(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserve(ReservEntry: Record "Reservation Entry"; var FullAutoReservation: Boolean; QtyToReserve: Decimal; QtyReserved: Decimal; QtyToReserveBase: Decimal; QtyReservedBase: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSerialLotNo(ReservEntry: Record "Reservation Entry"; var ItemTrackingQtyToReserve: Decimal; var ItemTrackingQtyToReserveBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownTotalQuantity(SourceRecRef: RecordRef; EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFilterReservEntryOnAfterFilterSource(var ReservationEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSerialLotNoOnAfterSetTrackingFields(var ReservationEntry: Record "Reservation Entry"; TempReservationEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetReservSource(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text; Direction: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateReservMgt(var ReservationEntry: Record "Reservation Entry"; var ReservationManagement: Codeunit "Reservation Management")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDrillDownReservedThisLine(var EntrySummary: Record "Entry Summary"; var ReservEntry: Record "Reservation Entry"; var ReservEntry2: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeReservedThisLine(var EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry"; ReservEntry2: Record "Reservation Entry"; TempReservSummEntry2: Record "Entry Summary" temporary; var ReservedQuantity: Decimal; var IsHandled: Boolean)
    begin
    end;
}

