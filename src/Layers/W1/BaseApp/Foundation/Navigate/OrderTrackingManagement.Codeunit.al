// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 99000778 OrderTrackingManagement
{
    Permissions = TableData "Sales Line" = r,
                  TableData "Purchase Line" = r,
                  TableData "Order Tracking Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Counting records...';
        Text003: Label 'CURRENT LINE';
        Text004: Label 'CANCELLATION';
        Text005: Label 'NON-PEGGED ';
        Text006: Label 'SHIPMENT';
        Text007: Label 'RECEIPT';
        Text008: Label 'There are no order tracking entries for this line.';
        Text009: Label 'The order tracking entries for this line have a date conflict.';
#pragma warning restore AA0074
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        ItemLedgEntry3: Record "Item Ledger Entry";
#if not CLEAN25
        SalesLine: Record "Sales Line";
#endif
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        ReqLine: Record "Requisition Line";
#if not CLEAN25
        ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line";
        ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component";
        AsmHeader: Record Microsoft.Assembly.Document."Assembly Header";
        AsmLine: Record Microsoft.Assembly.Document."Assembly Line";
#endif
        PlanningComponent: Record "Planning Component";
#if not CLEAN25
        ServLine: Record Microsoft.Service.Document."Service Line";
        JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line";
#endif
        ReservEntry: Record "Reservation Entry";
        TempReservEntryList: Record "Reservation Entry" temporary;
        TempOrderTrackingEntry: Record "Order Tracking Entry" temporary;
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        CaptionText: Text;
        Type: Option " ",Sales,"Req. Line",Purchase,"Item Jnl","BOM Jnl","Item Ledg. Entry","Prod. Order Line","Prod. Order Comp.","Planning Line","Planning Comp.",Transfer,"Service Order";
        ID: Code[20];
        BatchName: Code[20];
        Subtype: Integer;
        ProdOrderLineNo: Integer;
        RefNo: Integer;
        EntryNo: Integer;
        MultipleSummedUpQty: Decimal;
        SearchUp: Boolean;
        IsPlanning: Boolean;
        DateWarning: Boolean;
        SearchUpIsSet: Boolean;
        MultipleItemLedgEntries: Boolean;

    procedure IsSearchUp(): Boolean
    begin
        exit(SearchUp);
    end;

    procedure GetCaption(): Text
    begin
        exit(CaptionText);
    end;

#if not CLEAN25
    [Obsolete('Replaced by SetSourceLine()', '25.0')]
    procedure SetSalesLine(var CurrentSalesLine: Record "Sales Line")
    var
        SaleShptLine: Record Microsoft.Sales.History."Sales Shipment Line";
    begin
        CurrentSalesLine.TestField(Type, CurrentSalesLine.Type::Item);
        SalesLine := CurrentSalesLine;
        ReservEntry."Source Type" := DATABASE::"Sales Line";

        ReservEntry.InitSortingAndFilters(false);
        SalesLine.SetReservationFilters(ReservEntry);
        CaptionText := SalesLine.GetSourceCaption();

        if CurrentSalesLine."Qty. Shipped (Base)" <> 0 then begin
            SaleShptLine.SetCurrentKey("Order No.", "Order Line No.");
            SaleShptLine.SetRange("Order No.", CurrentSalesLine."Document No.");
            SaleShptLine.SetRange("Order Line No.", CurrentSalesLine."Line No.");
            if SaleShptLine.Find('-') then
                repeat
                    if ItemLedgEntry2.Get(SaleShptLine."Item Shpt. Entry No.") then
                        ItemLedgEntry2.Mark(true);
                until SaleShptLine.Next() = 0;
        end;
    end;
#endif

    procedure SetReqLine(var CurrentReqLine: Record "Requisition Line")
    begin
        ReqLine := CurrentReqLine;
        ReservEntry.InitSortingAndFilters(false);
        ReqLine.SetReservationFilters(ReservEntry);
        CaptionText := ReqLine.GetSourceCaption();

        IsPlanning := ReqLine."Planning Line Origin" <> ReqLine."Planning Line Origin"::" ";
    end;

#if not CLEAN25
    [Obsolete('Replaced by SetSourceLine()', '25.0')]
    procedure SetPurchLine(var CurrentPurchLine: Record "Purchase Line")
    var
        PurchRcptLine: Record Microsoft.Purchases.History."Purch. Rcpt. Line";
    begin
        CurrentPurchLine.TestField(Type, CurrentPurchLine.Type::Item);
        PurchLine := CurrentPurchLine;

        ReservEntry.InitSortingAndFilters(false);
        PurchLine.SetReservationFilters(ReservEntry);
        CaptionText := PurchLine.GetSourceCaption();

        if CurrentPurchLine."Qty. Received (Base)" <> 0 then begin
            PurchRcptLine.SetCurrentKey("Order No.", "Order Line No.");
            PurchRcptLine.SetRange("Order No.", CurrentPurchLine."Document No.");
            PurchRcptLine.SetRange("Order Line No.", CurrentPurchLine."Line No.");
            if PurchRcptLine.Find('-') then
                repeat
                    if ItemLedgEntry2.Get(PurchRcptLine."Item Rcpt. Entry No.") then
                        ItemLedgEntry2.Mark(true);
                until PurchRcptLine.Next() = 0;
        end;
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by SetSourceLine()', '25.0')]
    procedure SetProdOrderLine(var CurrentProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
        ProdOrderLine := CurrentProdOrderLine;

        ReservEntry.InitSortingAndFilters(false);
        ProdOrderLine.SetReservationFilters(ReservEntry);
        CaptionText := ProdOrderLine.GetSourceCaption();

        if CurrentProdOrderLine."Finished Quantity" <> 0 then begin
            ItemLedgEntry2.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
            ItemLedgEntry2.SetRange("Order Type", ItemLedgEntry2."Order Type"::Production);
            ItemLedgEntry2.SetRange("Order No.", CurrentProdOrderLine."Prod. Order No.");
            ItemLedgEntry2.SetRange("Order Line No.", CurrentProdOrderLine."Line No.");
            ItemLedgEntry2.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Output);
            ItemLedgEntry2.SetRange("Item No.", CurrentProdOrderLine."Item No.");

            if ItemLedgEntry2.Find('-') then
                repeat
                    ItemLedgEntry2.Mark(true);
                until ItemLedgEntry2.Next() = 0;
        end;
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by SetSourceLine()', '25.0')]
    procedure SetProdOrderComp(var CurrentProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        ProdOrderComp := CurrentProdOrderComp;

        ReservEntry.InitSortingAndFilters(false);
        ProdOrderComp.SetReservationFilters(ReservEntry);
        CaptionText := ProdOrderComp.GetSourceCaption();

        if (CurrentProdOrderComp."Remaining Quantity" <> CurrentProdOrderComp."Expected Quantity") and
           (CurrentProdOrderComp.Status in
            [CurrentProdOrderComp.Status::Released, CurrentProdOrderComp.Status::Finished])
        then begin
            ProdOrderLine.Get(
              CurrentProdOrderComp.Status,
              CurrentProdOrderComp."Prod. Order No.",
              CurrentProdOrderComp."Prod. Order Line No.");

            ItemLedgEntry2.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
            ItemLedgEntry2.SetRange("Order Type", ItemLedgEntry2."Order Type"::Production);
            ItemLedgEntry2.SetRange("Order No.", CurrentProdOrderComp."Prod. Order No.");
            ItemLedgEntry2.SetRange("Order Line No.", CurrentProdOrderComp."Prod. Order Line No.");
            ItemLedgEntry2.SetRange("Prod. Order Comp. Line No.", CurrentProdOrderComp."Line No.");
            ItemLedgEntry2.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Consumption);
            ItemLedgEntry2.SetRange("Item No.", CurrentProdOrderComp."Item No.");
            if ItemLedgEntry2.Find('-') then
                repeat
                    ItemLedgEntry2.Mark(true);
                until ItemLedgEntry2.Next() = 0;
        end;
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by SetSourceLine()', '25.0')]
    procedure SetAsmHeader(var CurrentAsmHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
        AsmHeader := CurrentAsmHeader;

        ReservEntry.InitSortingAndFilters(false);
        AsmHeader.SetReservationFilters(ReservEntry);
        CaptionText := AsmHeader.GetSourceCaption();

        if CurrentAsmHeader."Assembled Quantity (Base)" <> 0 then begin
            ItemLedgEntry2.SetCurrentKey("Order Type", "Order No.");
            ItemLedgEntry2.SetRange("Order Type", ItemLedgEntry2."Order Type"::Assembly);
            ItemLedgEntry2.SetRange("Order No.", CurrentAsmHeader."No.");
            ItemLedgEntry2.SetRange("Order Line No.", 0);
            if ItemLedgEntry2.Find('-') then
                repeat
                    ItemLedgEntry2.Mark(true);
                until ItemLedgEntry2.Next() = 0;
        end;
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by SetSourceLine()', '25.0')]
    procedure SetAsmLine(var CurrentAsmLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
        AsmLine := CurrentAsmLine;

        ReservEntry.InitSortingAndFilters(false);
        AsmLine.SetReservationFilters(ReservEntry);
        CaptionText := AsmLine.GetSourceCaption();

        if CurrentAsmLine."Consumed Quantity (Base)" <> 0 then begin
            ItemLedgEntry2.SetCurrentKey("Order Type", "Order No.");
            ItemLedgEntry2.SetRange("Order Type", ItemLedgEntry."Order Type"::Assembly);
            ItemLedgEntry2.SetRange("Order No.", CurrentAsmLine."No.");
            ItemLedgEntry2.SetRange("Order Line No.", CurrentAsmLine."Line No.");
            if ItemLedgEntry2.Find('-') then
                repeat
                    ItemLedgEntry2.Mark(true);
                until ItemLedgEntry2.Next() = 0;
        end;
    end;
#endif

    procedure SetPlanningComponent(var CurrentPlanningComponent: Record "Planning Component")
    begin
        PlanningComponent := CurrentPlanningComponent;

        ReservEntry.InitSortingAndFilters(false);
        PlanningComponent.SetReservationFilters(ReservEntry);
        CaptionText := PlanningComponent.GetSourceCaption();
        IsPlanning := true;
    end;

    procedure SetItemLedgEntry(var CurrentItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemLedgEntry := CurrentItemLedgEntry;

        ReservEntry.InitSortingAndFilters(false);
        ItemLedgEntry.SetReservationFilters(ReservEntry);
        CaptionText := ItemLedgEntry.GetSourceCaption();
        ItemLedgEntry2 := ItemLedgEntry;
        ItemLedgEntry2.Mark(true);
    end;

    procedure SetMultipleItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer)
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        // Used from posted shipment and receipt with item tracking.

        ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry, SourceType, SourceSubtype, SourceID,
          SourceBatchName, SourceProdOrderLine, SourceRefNo, 0);

        TempItemLedgEntry.SetFilter("Remaining Quantity", '<>%1', 0);
        if not TempItemLedgEntry.FindSet() then;

        ReservEntry.InitSortingAndFilters(false);
        TempItemLedgEntry.SetReservationFilters(ReservEntry);
        CaptionText := TempItemLedgEntry.GetSourceCaption();

        repeat
            ItemLedgEntry2 := TempItemLedgEntry;
            ItemLedgEntry2.Mark(true);
            MultipleSummedUpQty += TempItemLedgEntry."Remaining Quantity";
        until TempItemLedgEntry.Next() = 0;

        MultipleItemLedgEntries := (TempItemLedgEntry.Count > 1);
    end;

#if not CLEAN25
    [Obsolete('Replaced by SetSourceLine()', '25.0')]
    procedure SetServLine(var CurrentServLine: Record Microsoft.Service.Document."Service Line")
    var
        ServShptLine: Record Microsoft.Service.History."Service Shipment Line";
    begin
        CurrentServLine.TestField(Type, CurrentServLine.Type::Item);
        ServLine := CurrentServLine;
        ReservEntry."Source Type" := DATABASE::Microsoft.Service.Document."Service Line";

        ReservEntry.InitSortingAndFilters(false);
        ServLine.SetReservationFilters(ReservEntry);
        CaptionText := ServLine.GetSourceCaption();

        if CurrentServLine."Qty. Shipped (Base)" <> 0 then begin
            ServShptLine.SetCurrentKey("Order No.", "Order Line No.");
            ServShptLine.SetRange("Order No.", CurrentServLine."Document No.");
            ServShptLine.SetRange("Order Line No.", CurrentServLine."Line No.");
            if ServShptLine.Find('-') then
                repeat
                    if ItemLedgEntry2.Get(ServShptLine."Item Shpt. Entry No.") then
                        ItemLedgEntry2.Mark(true);
                until ServShptLine.Next() = 0;
        end;
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by SetSourceLine()', '25.0')]
    procedure SetJobPlanningLine(var CurrentJobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line")
    var
        JobUsageLink: Record Microsoft.Projects.Project.Job."Job Usage Link";
        JobLedgEntry: Record Microsoft.Projects.Project.Ledger."Job Ledger Entry";
    begin
        CurrentJobPlanningLine.TestField(Type, CurrentJobPlanningLine.Type::Item);
        JobPlanningLine := CurrentJobPlanningLine;
        ReservEntry."Source Type" := DATABASE::Microsoft.Projects.Project.Planning."Job Planning Line";

        ReservEntry.InitSortingAndFilters(false);
        JobPlanningLine.SetReservationFilters(ReservEntry);
        CaptionText := JobPlanningLine.GetSourceCaption();

        if CurrentJobPlanningLine."Qty. Posted" <> 0 then begin
            JobUsageLink.SetRange("Job No.", CurrentJobPlanningLine."Job No.");
            JobUsageLink.SetRange("Job Task No.", CurrentJobPlanningLine."Job Task No.");
            JobUsageLink.SetRange("Line No.", CurrentJobPlanningLine."Line No.");
            if JobUsageLink.Find('-') then
                repeat
                    JobLedgEntry.Get(JobUsageLink."Entry No.");
                    if ItemLedgEntry2.Get(JobLedgEntry."Ledger Entry No.") then
                        ItemLedgEntry2.Mark(true);
                until JobUsageLink.Next() = 0;
        end;
    end;
#endif

    procedure SetSourceRecord(var SourceRecordVar: Variant)
    begin
        OnSetSourceRecord(SourceRecordVar, ReservEntry, CaptionText, ItemLedgEntry2);
#if not CLEAN25
        OnAfterSetSoucreRecord(SourceRecordVar, ReservEntry, CaptionText, ItemLedgEntry2);
#endif
    end;

    procedure TrackedQuantity(): Decimal
    var
        FilterReservEntry: Record "Reservation Entry";
        QtyTracked1: Decimal;
        QtyTracked2: Decimal;
    begin
        if MultipleItemLedgEntries then
            exit(MultipleSummedUpQty);
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation,
          ReservEntry."Reservation Status"::Tracking);
        if ReservEntry.Find('-') then
            repeat
                QtyTracked1 += ReservEntry."Quantity (Base)";
            until ReservEntry.Next() = 0;
        if IsPlanning then
            if DerivePlanningFilter(ReservEntry, FilterReservEntry) then begin
                FilterReservEntry.SetRange("Reservation Status", FilterReservEntry."Reservation Status"::Reservation,
                  FilterReservEntry."Reservation Status"::Tracking);
                if FilterReservEntry.Find('-') then
                    repeat
                        QtyTracked2 += FilterReservEntry."Quantity (Base)";
                    until FilterReservEntry.Next() = 0;
                exit((QtyTracked1 + QtyTracked2) * CreateReservEntry.SignFactor(FilterReservEntry));
            end;
        exit(QtyTracked1 * CreateReservEntry.SignFactor(ReservEntry));
    end;

    procedure FindRecord(Which: Text[250]; var OrderTrackingEntry2: Record "Order Tracking Entry"): Boolean
    begin
        TempOrderTrackingEntry := OrderTrackingEntry2;
        if not TempOrderTrackingEntry.Find(Which) then
            exit(false);
        OrderTrackingEntry2 := TempOrderTrackingEntry;
        exit(true);
    end;

    procedure GetNextRecord(Steps: Integer; var OrderTrackingEntry2: Record "Order Tracking Entry") CurrentSteps: Integer
    begin
        TempOrderTrackingEntry := OrderTrackingEntry2;
        CurrentSteps := TempOrderTrackingEntry.Next(Steps);
        if CurrentSteps <> 0 then
            OrderTrackingEntry2 := TempOrderTrackingEntry;
        exit(CurrentSteps);
    end;

    procedure FindRecords(): Boolean
    begin
        exit(FindRecordsInner(false));
    end;

    procedure FindRecordsWithoutMessage(): Boolean
    begin
        exit(FindRecordsInner(true));
    end;

    local procedure FindRecordsInner(SuppressMessages: Boolean) TrackingExists: Boolean
    var
        Window: Dialog;
    begin
        OnBeforeFindRecordsInner(SuppressMessages);

        TempReservEntryList.DeleteAll();
        TempOrderTrackingEntry.DeleteAll();
        EntryNo := 1;

        if not SuppressMessages then
            Window.Open(Text000);
        TempOrderTrackingEntry.Init();
        TempOrderTrackingEntry."Entry No." := 0;
        DrillOrdersUp(ReservEntry, 1);
        ItemLedgEntry2.SetCurrentKey("Entry No.");
        ItemLedgEntry2.MarkedOnly(true);
        if ItemLedgEntry2.Find('-') then
            repeat
                InsertItemLedgTrackEntry(1, ItemLedgEntry2, ItemLedgEntry2."Remaining Quantity", ItemLedgEntry2);
            until ItemLedgEntry2.Next() = 0;
        TrackingExists := TempOrderTrackingEntry.Find('-');
        if not TrackingExists and not SuppressMessages then
            Message(Text008);
        if DateWarning and not SuppressMessages then
            Message(Text009);
        if not SuppressMessages then
            Window.Close();

        exit(TrackingExists);
    end;

    local procedure DrillOrdersUp(var ReservEntry: Record "Reservation Entry"; Level: Integer)
    var
        FilterReservEntry: Record "Reservation Entry";
        ContinueDrillUp: Boolean;
        IncludePlanningFilter: Boolean;
    begin
        if Level > 20 then
            exit;

        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation,
          ReservEntry."Reservation Status"::Tracking);

        if ReservEntry.Find('-') then begin
            if Level = 1 then
                if not SearchUpIsSet then begin
                    SearchUp := not ReservEntry.Positive;
                    SearchUpIsSet := true;
                end;

            repeat
                ProcessReservEntry(ReservEntry, FilterReservEntry, ContinueDrillUp, IncludePlanningFilter, Level);
            until ReservEntry.Next() = 0;
        end;

        if Level = 1 then
            if DerivePlanningFilter(ReservEntry, FilterReservEntry) then begin
                if not SearchUpIsSet then begin
                    SearchUp := not FilterReservEntry.Positive;
                    SearchUpIsSet := true;
                end;
                DrillOrdersUp(FilterReservEntry, Level);
            end;

        OnAfterDrillOrdersUp(TempOrderTrackingEntry, ReservEntry, Level, EntryNo, SearchUp, SearchUpIsSet);
    end;

    local procedure ProcessReservEntry(var ReservEntry: Record "Reservation Entry"; var FilterReservEntry: Record "Reservation Entry"; var ContinueDrillUp: Boolean; var IncludePlanningFilter: Boolean; Level: Integer)
    var
        ReservEntry2: Record "Reservation Entry";
        ReservEntry3: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessReservEntry(ReservEntry, FilterReservEntry, ContinueDrillUp, IncludePlanningFilter, Level, IsHandled);
        if IsHandled then
            exit;

        ReservEntry3.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
        InsertOrderTrackingEntry(ReservEntry, ReservEntry3, Level);
        case ReservEntry3."Source Type" of
            DATABASE::"Item Ledger Entry":
                begin
                    ItemLedgEntry3.Get(ReservEntry3."Source Ref. No.");
                    DrillItemLedgEntries(Level + 1, ItemLedgEntry3);
                end;
            DATABASE::"Planning Component":
                begin
                    FiltersForTrackingFromComponents(ReservEntry3, ReservEntry2);
                    DrillOrdersUp(ReservEntry2, Level + 1);
                    if DerivePlanningFilter(ReservEntry3, FilterReservEntry) then
                        DrillOrdersUp(FilterReservEntry, Level + 1);
                end;
            DATABASE::"Requisition Line":
                begin
                    FiltersForTrackingFromReqLine(ReservEntry3, ReservEntry2, SearchUp);
                    DrillOrdersUp(ReservEntry2, Level + 1);
                    if DerivePlanningFilter(ReservEntry3, FilterReservEntry) then
                        DrillOrdersUp(FilterReservEntry, Level + 1);
                end;
            DATABASE::"Transfer Line":
                begin
                    FiltersForTrackingFromTransfer(ReservEntry3, ReservEntry2, SearchUp);
                    DrillOrdersUp(ReservEntry2, Level + 1);
                    if DerivePlanningFilter(ReservEntry3, FilterReservEntry) then
                        DrillOrdersUp(FilterReservEntry, Level + 1);
                end;
            else begin
                OnDrillOrdersUpCaseElse(ReservEntry3, ReservEntry2, SearchUp, ContinueDrillUp, IncludePlanningFilter);
                if ContinueDrillUp then
                    DrillOrdersUp(ReservEntry2, Level + 1);
                if IncludePlanningFilter then
                    if DerivePlanningFilter(ReservEntry3, FilterReservEntry) then
                        DrillOrdersUp(FilterReservEntry, Level + 1);
            end;
        end;
    end;

    local procedure FiltersForTrackingFromComponents(FromReservationEntry: Record "Reservation Entry"; var ToReservationEntry: Record "Reservation Entry")
    begin
        ToReservationEntry.Reset();
        ToReservationEntry.SetSourceFilter(DATABASE::"Requisition Line", 0, FromReservationEntry."Source ID", FromReservationEntry."Source Prod. Order Line", true);
        ToReservationEntry.SetSourceFilter(FromReservationEntry."Source Batch Name", 0);
    end;

    local procedure FiltersForTrackingFromReqLine(FromReservationEntry: Record "Reservation Entry"; var ToReservationEntry: Record "Reservation Entry"; IsSearchUp: Boolean)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        ToReservationEntry.Reset();
        RequisitionLine.Get(FromReservationEntry."Source ID", FromReservationEntry."Source Batch Name", FromReservationEntry."Source Ref. No.");
        if RequisitionLine."Replenishment System" = RequisitionLine."Replenishment System"::Transfer then begin
            if IsSearchUp then
                ToReservationEntry.SetSourceFilter(DATABASE::"Requisition Line", 1, FromReservationEntry."Source ID", FromReservationEntry."Source Ref. No.", true)
            else
                ToReservationEntry.SetSourceFilter(DATABASE::"Requisition Line", 0, FromReservationEntry."Source ID", FromReservationEntry."Source Ref. No.", true);
            ToReservationEntry.SetSourceFilter(FromReservationEntry."Source Batch Name", 0);
        end else begin
            ToReservationEntry.SetSourceFilter(DATABASE::"Planning Component", 0, FromReservationEntry."Source ID", -1, true);
            ToReservationEntry.SetSourceFilter(FromReservationEntry."Source Batch Name", FromReservationEntry."Source Ref. No.");
        end;
    end;

    local procedure FiltersForTrackingFromTransfer(FromReservationEntry: Record "Reservation Entry"; var ToReservationEntry: Record "Reservation Entry"; IsSearchUp: Boolean)
    begin
        ToReservationEntry.Reset();
        if IsSearchUp then
            ToReservationEntry.SetSourceFilter(FromReservationEntry."Source Type", 0, FromReservationEntry."Source ID", FromReservationEntry."Source Ref. No.", true)
        else
            ToReservationEntry.SetSourceFilter(FromReservationEntry."Source Type", 1, FromReservationEntry."Source ID", FromReservationEntry."Source Ref. No.", true);
        ToReservationEntry.SetRange("Source Batch Name", FromReservationEntry."Source Batch Name");
    end;

    local procedure DrillItemLedgEntries(Level: Integer; ItemLedgEntry4: Record "Item Ledger Entry")
    var
        ItemLedgEntry5: Record "Item Ledger Entry";
        ItemLedgEntry6: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        SignFactor: Integer;
    begin
        if Level > 20 then
            exit;

        if ItemLedgEntry4.Positive then begin
            ItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Outbound Item Entry No.");
            ItemApplnEntry.SetRange("Inbound Item Entry No.", ItemLedgEntry4."Entry No.");
            ItemApplnEntry.SetFilter("Outbound Item Entry No.", '<>0');
            ItemApplnEntry.SetRange("Item Ledger Entry No.");
        end else begin
            ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
            ItemApplnEntry.SetRange("Outbound Item Entry No.", ItemLedgEntry4."Entry No.");
            ItemApplnEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry4."Entry No.");
            ItemApplnEntry.SetRange("Inbound Item Entry No.");
        end;
        if ItemApplnEntry.Find('-') then
            repeat
                if ItemLedgEntry4.Positive then begin
                    SignFactor := -1;
                    ItemLedgEntry5.Get(ItemApplnEntry."Outbound Item Entry No.")
                end else begin
                    SignFactor := 1;
                    ItemLedgEntry5.Get(ItemApplnEntry."Inbound Item Entry No.");
                end;
                if SearchUp = ItemLedgEntry5.Positive then begin
                    InsertItemLedgTrackEntry(Level, ItemLedgEntry5, ItemApplnEntry.Quantity * SignFactor, ItemLedgEntry4);
                    if (ItemLedgEntry5."Order Type" = ItemLedgEntry5."Order Type"::Production) and
                       (ItemLedgEntry5."Order No." <> '')
                    then begin
                        ItemLedgEntry6.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
                        ItemLedgEntry6.SetRange("Source Type", ItemLedgEntry4."Source Type"::Item);
                        if ItemLedgEntry5."Entry Type" = ItemLedgEntry5."Entry Type"::Consumption then
                            ItemLedgEntry6.SetRange("Entry Type", ItemLedgEntry4."Entry Type"::Output)
                        else
                            ItemLedgEntry6.SetRange("Entry Type", ItemLedgEntry4."Entry Type"::Consumption);
                        if not SearchUp then
                            ItemLedgEntry6.SetRange("Item No.", ItemLedgEntry5."Source No.")
                        else
                            ItemLedgEntry6.SetRange("Item No.", ItemLedgEntry5."Item No.");
                        ItemLedgEntry6.SetRange("Order Type", ItemLedgEntry6."Order Type"::Production);
                        ItemLedgEntry6.SetRange("Order No.", ItemLedgEntry5."Order No.");
                        if ItemLedgEntry6.Find('-') then
                            repeat
                                InsertItemLedgTrackEntry(Level + 1, ItemLedgEntry6, ItemLedgEntry6.Quantity, ItemLedgEntry4);
                                DrillItemLedgEntries(Level + 1, ItemLedgEntry6);
                            until ItemLedgEntry6.Next() = 0;
                    end;
                end;
            until ItemApplnEntry.Next() = 0;

        if (ItemLedgEntry4."Order Type" = ItemLedgEntry4."Order Type"::Production) and (ItemLedgEntry4."Order No." <> '') then begin
            ItemLedgEntry6.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
            ItemLedgEntry6.SetRange("Source Type", ItemLedgEntry4."Source Type"::Item);
            if ItemLedgEntry5."Entry Type" = ItemLedgEntry5."Entry Type"::Consumption then
                ItemLedgEntry6.SetRange("Entry Type", ItemLedgEntry4."Entry Type"::Output)
            else
                ItemLedgEntry6.SetRange("Entry Type", ItemLedgEntry4."Entry Type"::Consumption);
            ItemLedgEntry6.SetRange("Order Type", ItemLedgEntry6."Order Type"::Production);
            ItemLedgEntry6.SetRange("Order No.", ItemLedgEntry5."Order No.");
            if not SearchUp then
                ItemLedgEntry6.SetRange("Item No.", ItemLedgEntry5."Source No.")
            else
                ItemLedgEntry6.SetRange("Item No.", ItemLedgEntry5."Item No.");
            if ItemLedgEntry6.Find('-') then
                repeat
                    if ItemLedgEntry4."Entry No." <> ItemLedgEntry6."Entry No." then begin
                        InsertItemLedgTrackEntry(Level + 1, ItemLedgEntry6, ItemLedgEntry6.Quantity, ItemLedgEntry4);
                        DrillItemLedgEntries(Level + 1, ItemLedgEntry6);
                    end;
                until ItemLedgEntry6.Next() = 0;
        end;
    end;

    local procedure InsertOrderTrackingEntry(var ReservEntry: Record "Reservation Entry"; var ReservEntry2: Record "Reservation Entry"; Level: Integer)
    begin
        TempReservEntryList := ReservEntry;
        TempReservEntryList.Positive := false;
        if not TempReservEntryList.Insert() then
            exit;

        TempOrderTrackingEntry.Reset();
        TempOrderTrackingEntry.Init();

        TempOrderTrackingEntry.Level := Level;
        TempOrderTrackingEntry."For Type" := ReservEntry."Source Type";
        TempOrderTrackingEntry."For Subtype" := ReservEntry."Source Subtype";
        TempOrderTrackingEntry."For ID" := ReservEntry."Source ID";
        TempOrderTrackingEntry."For Batch Name" := ReservEntry."Source Batch Name";
        TempOrderTrackingEntry."For Prod. Order Line" := ReservEntry."Source Prod. Order Line";
        TempOrderTrackingEntry."For Ref. No." := ReservEntry."Source Ref. No.";

        TempOrderTrackingEntry."From Type" := ReservEntry2."Source Type";
        TempOrderTrackingEntry."From Subtype" := ReservEntry2."Source Subtype";
        TempOrderTrackingEntry."From ID" := ReservEntry2."Source ID";
        TempOrderTrackingEntry."From Batch Name" := ReservEntry2."Source Batch Name";
        TempOrderTrackingEntry."From Prod. Order Line" := ReservEntry2."Source Prod. Order Line";
        TempOrderTrackingEntry."From Ref. No." := ReservEntry2."Source Ref. No.";

        if ReservEntry."Expected Receipt Date" > ReservEntry."Shipment Date" then begin
            TempOrderTrackingEntry.Warning := true;
            DateWarning := true;
        end;

        OnInsertOrderTrackingEntryOnBeforeOrderTrackingEntryExists(TempOrderTrackingEntry, ReservEntry, ReservEntry2);

        if OrderTrackingEntryExists() then begin
            TempOrderTrackingEntry.Quantity += ReservEntry."Quantity (Base)";
            TempOrderTrackingEntry.Modify();
            exit;
        end;

        TempOrderTrackingEntry."Entry No." := EntryNo;
        TempOrderTrackingEntry."Demanded by" := ReservEngineMgt.CreateForText(ReservEntry);
        TempOrderTrackingEntry."Supplied by" := ReservEngineMgt.CreateFromText(ReservEntry);
        TempOrderTrackingEntry."Item No." := ReservEntry."Item No.";
        TempOrderTrackingEntry."Shipment Date" := ReservEntry."Shipment Date";
        TempOrderTrackingEntry."Expected Receipt Date" := ReservEntry."Expected Receipt Date";
        if MultipleItemLedgEntries then
            TempOrderTrackingEntry.Quantity := MultipleSummedUpQty
        else
            TempOrderTrackingEntry.Quantity := ReservEntry."Quantity (Base)";

        if SearchUp then
            TempOrderTrackingEntry.Name := TempOrderTrackingEntry."Supplied by"
        else
            TempOrderTrackingEntry.Name := TempOrderTrackingEntry."Demanded by";

        if Level = 1 then
            if SearchUp then
                TempOrderTrackingEntry."Demanded by" := Text003
            else
                TempOrderTrackingEntry."Supplied by" := Text003;

        Type := TempOrderTrackingEntry."For Type";
        Subtype := TempOrderTrackingEntry."For Subtype";
        ID := TempOrderTrackingEntry."For ID";
        BatchName := TempOrderTrackingEntry."For Batch Name";
        ProdOrderLineNo := TempOrderTrackingEntry."For Prod. Order Line";
        RefNo := TempOrderTrackingEntry."For Ref. No.";

        case Type of
            DATABASE::"Purchase Line":
                if PurchLine.Get(Subtype, ID, RefNo) then begin
                    TempOrderTrackingEntry."Starting Date" := PurchLine."Expected Receipt Date";
                    TempOrderTrackingEntry."Ending Date" := PurchLine."Expected Receipt Date";
                end;
            DATABASE::"Requisition Line":
                if ReqLine.Get(ID, BatchName, RefNo) then begin
                    TempOrderTrackingEntry."Starting Date" := ReqLine."Due Date";
                    TempOrderTrackingEntry."Ending Date" := ReqLine."Due Date";
                end;
            DATABASE::"Item Journal Line":
                if ItemJnlLine.Get(ID, BatchName, RefNo) then begin
                    TempOrderTrackingEntry."Starting Date" := ItemJnlLine."Posting Date";
                    TempOrderTrackingEntry."Ending Date" := ItemJnlLine."Posting Date";
                end;
            DATABASE::"Item Ledger Entry":
                if ItemLedgEntry.Get(RefNo) then begin
                    TempOrderTrackingEntry."Starting Date" := WorkDate();
                    TempOrderTrackingEntry."Ending Date" := WorkDate();
                end;
            DATABASE::"Planning Component":
                if PlanningComponent.Get(ID, BatchName, ProdOrderLineNo, RefNo) then begin
                    TempOrderTrackingEntry."Starting Date" := PlanningComponent."Due Date";
                    if ReqLine.Get(ID, BatchName, ProdOrderLineNo) then
                        TempOrderTrackingEntry."Ending Date" := ReqLine."Ending Date";
                end;
            else
                OnInsertOrderTrackingEntry(TempOrderTrackingEntry, Type, Subtype, ID, RefNo, BatchName, ProdOrderLineNo);
        end;

        if TempOrderTrackingEntry."From Type" = DATABASE::"Requisition Line" then
            if ReqLine.Get(
                 TempOrderTrackingEntry."From ID", TempOrderTrackingEntry."From Batch Name", TempOrderTrackingEntry."From Ref. No.")
            then
                if ReqLine."Action Message" = ReqLine."Action Message"::Cancel then
                    TempOrderTrackingEntry.Name := Text004;

        OnInsertOrderTrackingEntryOnBeforeTempOrderTrackingEntryInsert(TempOrderTrackingEntry, ReservEntry, ReservEntry2);
        TempOrderTrackingEntry.Insert();
        EntryNo := EntryNo + 1;

        OnAfterInsertTrackingEntry(TempOrderTrackingEntry, DateWarning);
    end;

    local procedure InsertItemLedgTrackEntry(Level: Integer; ToItemLedgEntry: Record "Item Ledger Entry"; TrackQuantity: Decimal; FromItemLedgEntry: Record "Item Ledger Entry")
    var
        PeggingText: Text[30];
    begin
        if TrackQuantity = 0 then
            exit;
        TempOrderTrackingEntry.Reset();
        TempOrderTrackingEntry.Init();
        TempOrderTrackingEntry."Entry No." := EntryNo;
        if SearchUp then begin
            TempOrderTrackingEntry."Demanded by" :=
              StrSubstNo(
                '%1 %2', FromItemLedgEntry.TableCaption(), FromItemLedgEntry."Entry No.");
            TempOrderTrackingEntry."Supplied by" :=
              StrSubstNo(
                '%1 %2', ToItemLedgEntry.TableCaption(), ToItemLedgEntry."Entry No.");
        end else begin
            TempOrderTrackingEntry."Supplied by" :=
              StrSubstNo(
                '%1 %2', FromItemLedgEntry.TableCaption(), FromItemLedgEntry."Entry No.");
            TempOrderTrackingEntry."Demanded by" :=
              StrSubstNo(
                '%1 %2', ToItemLedgEntry.TableCaption(), ToItemLedgEntry."Entry No.");
        end;

        if Level = 1 then begin
            if ToItemLedgEntry."Entry No." = FromItemLedgEntry."Entry No." then
                PeggingText := Text005
            else
                PeggingText := '';

            if SearchUp then
                TempOrderTrackingEntry."Demanded by" := PeggingText + Text006
            else
                TempOrderTrackingEntry."Supplied by" := PeggingText + Text007;
        end;

        TempOrderTrackingEntry."Item No." := ToItemLedgEntry."Item No.";
        TempOrderTrackingEntry.Quantity := TrackQuantity;
        TempOrderTrackingEntry.Level := Level;

        TempOrderTrackingEntry."For Type" := DATABASE::"Item Ledger Entry";
        TempOrderTrackingEntry."For Ref. No." := FromItemLedgEntry."Entry No.";
        TempOrderTrackingEntry."From Type" := DATABASE::"Item Ledger Entry";
        TempOrderTrackingEntry."From Ref. No." := ToItemLedgEntry."Entry No.";

        if SearchUp then
            TempOrderTrackingEntry.Name := TempOrderTrackingEntry."Supplied by"
        else
            TempOrderTrackingEntry.Name := TempOrderTrackingEntry."Demanded by";

        Type := TempOrderTrackingEntry."For Type";
        RefNo := ToItemLedgEntry."Entry No.";

        TempOrderTrackingEntry."Starting Date" := 0D;
        TempOrderTrackingEntry."Ending Date" := 0D;

        OnBeforeTempOrderTrackingEntryInsert(TempOrderTrackingEntry, ToItemLedgEntry, FromItemLedgEntry);
        TempOrderTrackingEntry.Insert();
        EntryNo := EntryNo + 1;
    end;

    local procedure OrderTrackingEntryExists(): Boolean
    var
        OrderTrackingEntry2: Record "Order Tracking Entry";
    begin
        OrderTrackingEntry2 := TempOrderTrackingEntry;

        TempOrderTrackingEntry.SetRange(Level, TempOrderTrackingEntry.Level);
        TempOrderTrackingEntry.SetRange("For Type", TempOrderTrackingEntry."For Type");
        TempOrderTrackingEntry.SetRange("For Subtype", TempOrderTrackingEntry."For Subtype");
        TempOrderTrackingEntry.SetRange("For ID", TempOrderTrackingEntry."For ID");
        TempOrderTrackingEntry.SetRange("For Batch Name", TempOrderTrackingEntry."For Batch Name");
        TempOrderTrackingEntry.SetRange("For Prod. Order Line", TempOrderTrackingEntry."For Prod. Order Line");
        TempOrderTrackingEntry.SetRange("For Ref. No.", TempOrderTrackingEntry."For Ref. No.");

        TempOrderTrackingEntry.SetRange("From Type", TempOrderTrackingEntry."From Type");
        TempOrderTrackingEntry.SetRange("From Subtype", TempOrderTrackingEntry."From Subtype");
        TempOrderTrackingEntry.SetRange("From ID", TempOrderTrackingEntry."From ID");
        TempOrderTrackingEntry.SetRange("From Batch Name", TempOrderTrackingEntry."From Batch Name");
        TempOrderTrackingEntry.SetRange("From Prod. Order Line", TempOrderTrackingEntry."From Prod. Order Line");
        TempOrderTrackingEntry.SetRange("From Ref. No.", TempOrderTrackingEntry."From Ref. No.");

        OnOrderTrackingEntryExistsOnBeforeFindTrackingEntry(TempOrderTrackingEntry);

        if TempOrderTrackingEntry.Find('-') then begin
            TempOrderTrackingEntry.Reset();
            exit(true);
        end;
        TempOrderTrackingEntry.Reset();
        TempOrderTrackingEntry := OrderTrackingEntry2;
        exit(false);
    end;

    procedure DerivePlanningFilter(var FromReservEntry: Record "Reservation Entry"; var ToReservEntry: Record "Reservation Entry") OK: Boolean
    var
        FilterReqLine: Record "Requisition Line";
        FilterPlanningComponent: Record "Planning Component";
    begin
        OK := false;
        ToReservEntry.SetRange("Source Type", DATABASE::"Planning Component");
        if FromReservEntry.GetFilter("Source Type") = ToReservEntry.GetFilter("Source Type") then begin
            Evaluate(FilterPlanningComponent."Line No.", FromReservEntry.GetFilter("Source Ref. No."));
            Evaluate(FilterPlanningComponent."Worksheet Line No.", FromReservEntry.GetFilter("Source Prod. Order Line"));

            if not FilterPlanningComponent.Get(
                    FromReservEntry.GetRangeMin("Source ID"), FromReservEntry.GetRangeMin("Source Batch Name"),
                    FilterPlanningComponent."Worksheet Line No.", FilterPlanningComponent."Line No.")
            then
                exit(false);

            OnDerivePlanningFilterOnSetToReservationFilter(ToReservEntry, FilterPlanningComponent);
            ToReservEntry.SetRange("Source Prod. Order Line", FilterPlanningComponent."Ref. Order Line No.");
            OK := ToReservEntry.Find('-');
        end else begin
            ToReservEntry.SetRange("Source Type", DATABASE::"Requisition Line");
            if FromReservEntry.GetFilter("Source Type") = ToReservEntry.GetFilter("Source Type") then begin
                Evaluate(FilterReqLine."Line No.", FromReservEntry.GetFilter("Source Ref. No."));
                if not FilterReqLine.Get(FromReservEntry.GetRangeMin("Source ID"),
                        FromReservEntry.GetRangeMin("Source Batch Name"), FilterReqLine."Line No.")
                then
                    exit(false);
                if FilterReqLine."Action Message".AsInteger() > FilterReqLine."Action Message"::New.AsInteger() then
                    case FilterReqLine."Ref. Order Type" of
                        FilterReqLine."Ref. Order Type"::Purchase:
                            begin
                                ToReservEntry.SetSourceFilter(DATABASE::"Purchase Line", 1, FilterReqLine."Ref. Order No.", FilterReqLine."Ref. Line No.", true);
                                OK := ToReservEntry.Find('-');
                            end;
                        FilterReqLine."Ref. Order Type"::Transfer:
                            begin
                                ToReservEntry.SetSourceFilter(DATABASE::"Transfer Line", 1, FilterReqLine."Ref. Order No.", FilterReqLine."Ref. Line No.", true);
                                ToReservEntry.SetRange("Source Prod. Order Line", 0);
                                OK := ToReservEntry.Find('-');
                            end;
                        else
                            OnDerivePlanningFilterOnSetRequisitionLineFilters(ToReservEntry, FilterReqLine, OK);
                    end;
            end else
                OnDerivePlanningFilterOnCheckReservationSourceTypeElse(FromReservEntry, ToReservEntry, OK);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTrackingEntry(var OrderTrackingEntry: Record "Order Tracking Entry"; var DateWarning: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event with corrected name OnSetSourceRecord', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSoucreRecord(var SourceRecordVar: Variant; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text; var ItemLedgerEntry2: Record "Item Ledger Entry")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnSetSourceRecord(var SourceRecordVar: Variant; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text; var ItemLedgerEntry2: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessReservEntry(var ReservEntry: Record "Reservation Entry"; var FilterReservEntry: Record "Reservation Entry"; var ContinueDrillUp: Boolean; var IncludePlanningFilter: Boolean; Level: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempOrderTrackingEntryInsert(var TempOrderTrackingEntry: Record "Order Tracking Entry" temporary; ToItemLedgerEntry: Record "Item Ledger Entry"; FromItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillOrdersUpCaseElse(var ReservationEntry3: Record "Reservation Entry"; var ReservationEntry2: Record "Reservation Entry"; SearchUp: Boolean; var ContinueDrillUp: Boolean; var IncludePlanningFilter: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOrderTrackingEntry(var OrderTrackingEntry: Record "Order Tracking Entry"; Type: Option; Subtype: Integer; ID: Code[20]; RefNo: Integer; BatchName: Code[20]; ProdOrderLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOrderTrackingEntryOnBeforeTempOrderTrackingEntryInsert(var TempOrderTrackingEntry: Record "Order Tracking Entry"; var ReservEntry: Record "Reservation Entry"; var ReservEntry2: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecordsInner(var SuppressMessages: Boolean)
    begin
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSetSourceLine(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnDerivePlanningFilterOnSetToReservationFilter(var ToReservEntry: Record "Reservation Entry"; FilterPlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDerivePlanningFilterOnSetRequisitionLineFilters(var ToReservEntry: Record "Reservation Entry"; FilterReqLine: Record "Requisition Line"; var OK: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOrderTrackingEntryExistsOnBeforeFindTrackingEntry(var TempOrderTrackingEntry: Record "Order Tracking Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDerivePlanningFilterOnCheckReservationSourceTypeElse(var FromReservationEntry: Record "Reservation Entry"; var ToReservationEntry: Record "Reservation Entry"; var IsOK: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDrillOrdersUp(var TempOrderTrackingEntry: Record "Order Tracking Entry" temporary; var ReservationEntry: Record "Reservation Entry"; Level: Integer; var EntryNo: Integer; var SearchUp: Boolean; var SearchUpIsSet: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOrderTrackingEntryOnBeforeOrderTrackingEntryExists(var TempOrderTrackingEntry: Record "Order Tracking Entry" temporary; ReservationEntry: Record "Reservation Entry"; ReservationEntry2: Record "Reservation Entry")
    begin
    end;
}
