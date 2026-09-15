// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 5530 "Calc. Item Availability"
{

    trigger OnRun()
    begin
    end;

    var
        TempInvtEventBuf: Record "Inventory Event Buffer" temporary;
        EntryNo: Integer;
        TableNotSupportedErr: Label 'Table %1 is not supported by the ShowDocument function.', Comment = '%1 = table name';

    procedure CalcNewInvtEventBuf(var Item: Record Item; ForecastName: Code[10]; IncludeBlanketOrders: Boolean; ExcludeForecastBefore: Date; IncludePlan: Boolean)
    begin
        if Item.Type <> Item.Type::Inventory then
            exit;
        TempInvtEventBuf.Reset();
        TempInvtEventBuf.DeleteAll();

        GetDocumentEntries(TempInvtEventBuf, Item);
        if (ForecastName <> '') or IncludeBlanketOrders or IncludePlan then
            GetAnticipatedDemand(TempInvtEventBuf, Item, ForecastName, ExcludeForecastBefore, IncludeBlanketOrders);
        if IncludePlan then
            GetPlanningEntries(TempInvtEventBuf, Item);
    end;

    procedure GetInvEventBuffer(var RequestInvtEventBuf: Record "Inventory Event Buffer")
    begin
        TempInvtEventBuf.Reset();
        TempInvtEventBuf.SetCurrentKey("Availability Date", Type);
        if TempInvtEventBuf.Find('-') then
            repeat
                RequestInvtEventBuf := TempInvtEventBuf;
                RequestInvtEventBuf.Insert();
            until TempInvtEventBuf.Next() = 0;
    end;

    procedure GetDocumentEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item)
    begin
        OnBeforeGetDocumentEntries(InvtEventBuf, Item);

        TryGetSalesOrdersDemandEntries(InvtEventBuf, Item);
        TryGetPurchRetOrderDemandEntries(InvtEventBuf, Item);
        TryGetTransOrderDemandEntries(InvtEventBuf, Item);
        TryGetQtyOnInventory(InvtEventBuf, Item);
        TryGetPurchOrderSupplyEntries(InvtEventBuf, Item);
        TryGetSalesRetOrderSupplyEntries(InvtEventBuf, Item);
        TryGetTransferOrderSupplyEntries(InvtEventBuf, Item);

        OnAfterGetDocumentEntries(InvtEventBuf, Item, EntryNo);
    end;

    local procedure GetAnticipatedDemand(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; ForecastName: Code[10]; ExcludeForecastBefore: Date; IncludeBlanketOrders: Boolean)
    begin
        if ForecastName <> '' then
            GetRemainingForecast(InvtEventBuf, Item, ForecastName, ExcludeForecastBefore);
        if IncludeBlanketOrders then
            GetBlanketSalesOrders(InvtEventBuf, Item);

        OnAfterGetAnticipatedDemand(InvtEventBuf, Item, ForecastName, ExcludeForecastBefore, IncludeBlanketOrders, EntryNo);
    end;

    local procedure GetPlanningEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item)
    begin
        GetPlanningLines(InvtEventBuf, Item);
        GetPlanningComponents(InvtEventBuf, Item);
        GetPlanningTransDemand(InvtEventBuf, Item);
    end;

    local procedure TryGetQtyOnInventory(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        FilterItemLedgEntry: Record "Item Ledger Entry";
        IncludeLocation: Boolean;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeTryGetQtyOnInventory(InvtEventBuf, Item, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not ItemLedgEntry.ReadPermission then
            exit(false);

        if ItemLedgEntry.FindLinesWithItemToPlan(Item, false) then begin
            FilterItemLedgEntry.Copy(ItemLedgEntry);
            repeat
                if ItemLedgEntry."Location Code" = '' then
                    IncludeLocation := true
                else
                    IncludeLocation := not IsInTransitLocation(ItemLedgEntry."Location Code");

                ItemLedgEntry.SetRange("Variant Code", ItemLedgEntry."Variant Code");
                ItemLedgEntry.SetRange("Location Code", ItemLedgEntry."Location Code");

                if IncludeLocation then begin
                    ItemLedgEntry.CalcSums("Remaining Quantity");
                    if ItemLedgEntry."Remaining Quantity" <> 0 then begin
                        InvtEventBuf.TransferInventoryQty(ItemLedgEntry);
                        OnTryGetQtyOnInventoryOnBeforeInsertEntry(InvtEventBuf, ItemLedgEntry);
                        InsertEntry(InvtEventBuf);
                    end;
                end;

                ItemLedgEntry.Find('+');
                ItemLedgEntry.CopyFilters(FilterItemLedgEntry);
            until ItemLedgEntry.Next() = 0;
        end;

        exit(true);
    end;

    local procedure TryGetPurchOrderSupplyEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        PurchaseLine: Record "Purchase Line";
        PurchAvailabilityMgt: Codeunit "Purch. Availability Mgt.";
        IsHandled: Boolean;
    begin
        if not PurchaseLine.ReadPermission then
            exit(false);

        if PurchaseLine.FindLinesWithItemToPlan(Item, "Purchase Document Type"::Order) then
            repeat
                IsHandled := false;
                OnTryGetPurchOrderSupplyEntriesOnBeforeInsertEntry(PurchaseLine, IsHandled);
                if not IsHandled then begin
                    PurchAvailabilityMgt.TransferFromPurchase(InvtEventBuf, PurchaseLine);
                    InsertEntry(InvtEventBuf);
                end;
            until PurchaseLine.Next() = 0;

        exit(true);
    end;

    local procedure TryGetSalesRetOrderSupplyEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesLine: Record "Sales Line";
        SalesAvailabilityMgt: Codeunit "Sales Availability Mgt.";
    begin
        if not SalesLine.ReadPermission then
            exit(false);

        if SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::"Return Order") then
            repeat
                SalesAvailabilityMgt.TransferFromSalesReturn(InvtEventBuf, SalesLine);
                InsertEntry(InvtEventBuf);
            until SalesLine.Next() = 0;

        exit(true);
    end;

    local procedure TryGetTransferOrderSupplyEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        TransLine: Record "Transfer Line";
        TransferAvailabilityMgt: Codeunit "Transfer Availability Mgt.";
    begin
        if not TransLine.ReadPermission then
            exit(false);

        if TransLine.FindLinesWithItemToPlan(Item, true, false) then
            repeat
                TransferAvailabilityMgt.TransferFromInboundTransOrder(InvtEventBuf, TransLine);
                InsertEntry(InvtEventBuf);
            until TransLine.Next() = 0;

        exit(true)
    end;

    local procedure TryGetSalesOrdersDemandEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesLine: Record "Sales Line";
        SalesAvailabilityMgt: Codeunit "Sales Availability Mgt.";
    begin
        if not SalesLine.ReadPermission then
            exit(false);

        if SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::Order) then
            repeat
                SalesAvailabilityMgt.TransferFromSales(InvtEventBuf, SalesLine);
                InsertEntry(InvtEventBuf);
            until SalesLine.Next() = 0;

        exit(true);
    end;

    local procedure TryGetPurchRetOrderDemandEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        PurchLine: Record "Purchase Line";
        PurchAvailabilityMgt: Codeunit "Purch. Availability Mgt.";
    begin
        if not PurchLine.ReadPermission then
            exit(false);

        if PurchLine.FindLinesWithItemToPlan(Item, PurchLine."Document Type"::"Return Order") then
            repeat
                PurchAvailabilityMgt.TransferFromPurchReturn(InvtEventBuf, PurchLine);
                InsertEntry(InvtEventBuf);
            until PurchLine.Next() = 0;

        exit(true);
    end;

    local procedure TryGetTransOrderDemandEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item): Boolean
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        TransLine: Record "Transfer Line";
        TransferAvailabilityMgt: Codeunit "Transfer Availability Mgt.";
    begin
        if not TransLine.ReadPermission then
            exit(false);

        if TransLine.FindLinesWithItemToPlan(Item, false, false) then
            repeat
                TransferAvailabilityMgt.TransferFromOutboundTransOrder(InvtEventBuf, TransLine);
                InsertEntry(InvtEventBuf);
            until TransLine.Next() = 0;

        exit(true);
    end;

    local procedure GetRemainingForecast(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; ForecastName: Code[10]; ExcludeForecastBefore: Date)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        InventorySetup: Record "Inventory Setup";
        ProdForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry";
        ProdForecastEntry2: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry";
        CopyOfInvtEventBuf: Record "Inventory Event Buffer";
        FromDate: Date;
        ToDate: Date;
        ForecastPeriodEndDate: Date;
        RemainingForecastQty: Decimal;
        ModuleLoop: Integer;
        ReplenishmentLocation: Code[10];
        LocationMandatory: Boolean;
        Module: Boolean;
    begin
        // Include Forecast consumption
        CopyOfInvtEventBuf.Copy(InvtEventBuf);
        if Format(Item."Date Filter") <> '' then begin
            FromDate := Item.GetRangeMin("Date Filter");
            ToDate := Item.GetRangeMax("Date Filter");
        end;
        if FromDate = 0D then
            FromDate := WorkDate();
        if ToDate = 0D then
            ToDate := DMY2Date(30, 12, 9999);

        InventorySetup.Get();
        if not InventorySetup."Use Forecast on Locations" then begin
            if not FindReplishmentLocation(ReplenishmentLocation, Item, LocationMandatory) then
                ReplenishmentLocation := InventorySetup.GetComponentsAtLocation();
            if LocationMandatory and
               (ReplenishmentLocation = '')
            then
                exit;

            ProdForecastEntry.SetCurrentKey(
              "Production Forecast Name", "Item No.", "Component Forecast", "Forecast Date", "Location Code");
        end else
            ProdForecastEntry.SetCurrentKey(
              "Production Forecast Name", "Item No.", "Location Code", "Forecast Date", "Component Forecast");

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Entry No.");

        ProdForecastEntry.SetRange("Production Forecast Name", ForecastName);
        ProdForecastEntry.SetRange("Forecast Date", ExcludeForecastBefore, ToDate);
        ProdForecastEntry.SetRange("Item No.", Item."No.");

        ProdForecastEntry2.Copy(ProdForecastEntry);
        Item.CopyFilter("Location Filter", ProdForecastEntry2."Location Code");
        Item.CopyFilter("Variant Filter", ProdForecastEntry2."Variant Code");
        OnGetRemainingForecastOnBeforeLoopOnAfterSetItemFilters(Item, ProdForecastEntry, ProdForecastEntry2);

        for ModuleLoop := 1 to 2 do begin
            Module := ModuleLoop = 2;
            ProdForecastEntry.SetRange("Component Forecast", Module);
            ProdForecastEntry2.SetRange("Component Forecast", Module);
            if ProdForecastEntry2.FindSet() then
                repeat
                    if InventorySetup."Use Forecast on Locations" then begin
                        ProdForecastEntry2.SetRange("Location Code", ProdForecastEntry2."Location Code");
                        ItemLedgEntry.SetRange("Location Code", ProdForecastEntry2."Location Code");
                        InvtEventBuf.SetRange("Location Code", ProdForecastEntry2."Location Code");
                    end else begin
                        Item.CopyFilter("Location Filter", ProdForecastEntry2."Location Code");
                        Item.CopyFilter("Location Filter", ItemLedgEntry."Location Code");
                        Item.CopyFilter("Location Filter", InvtEventBuf."Location Code");
                    end;
                    if InventorySetup."Use Forecast on Variants" then begin
                        ProdForecastEntry2.SetRange("Variant Code", ProdForecastEntry2."Variant Code");
                        ItemLedgEntry.SetRange("Variant Code", ProdForecastEntry2."Variant Code");
                        InvtEventBuf.SetRange("Variant Code", ProdForecastEntry2."Variant Code");
                    end else begin
                        Item.CopyFilter("Variant Filter", ProdForecastEntry2."Variant Code");
                        Item.CopyFilter("Variant Filter", ItemLedgEntry."Variant Code");
                        Item.CopyFilter("Variant Filter", InvtEventBuf."Variant Code");
                    end;
                    ProdForecastEntry2.FindLast();
                    ProdForecastEntry2.CopyFilter("Location Code", ProdForecastEntry."Location Code");
                    ProdForecastEntry2.CopyFilter("Variant Code", ProdForecastEntry."Variant Code");
                    Item.CopyFilter("Location Filter", ProdForecastEntry2."Location Code");
                    Item.CopyFilter("Variant Filter", ProdForecastEntry2."Variant Code");
                    OnGetRemainingForecastOnAfterSetItemFilters(Item, ProdForecastEntry);

                    if ForecastExist(ProdForecastEntry, ExcludeForecastBefore, FromDate, ToDate) then
                        repeat
                            ProdForecastEntry.SetRange("Forecast Date", ProdForecastEntry."Forecast Date");
                            ProdForecastEntry.Find('+');
                            OnGetRemainingForecastOnBeforeCalcForecastQuantityBase(ProdForecastEntry);
                            ProdForecastEntry.CalcSums("Forecast Quantity (Base)");
                            RemainingForecastQty := ProdForecastEntry."Forecast Quantity (Base)";
                            ForecastPeriodEndDate := FindForecastPeriodEndDate(ProdForecastEntry, ToDate);

                            ItemLedgEntry.SetRange("Item No.", Item."No.");
                            ItemLedgEntry.SetRange(Positive, false);
                            ItemLedgEntry.SetRange(Open);
                            ItemLedgEntry.SetRange(
                              "Posting Date", ProdForecastEntry."Forecast Date", ForecastPeriodEndDate);
                            Item.CopyFilter("Variant Filter", ItemLedgEntry."Variant Code");
                            if Module then begin
                                ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Consumption);
                                if ItemLedgEntry.FindSet() then
                                    repeat
                                        RemainingForecastQty += ItemLedgEntry.Quantity;
                                    until ItemLedgEntry.Next() = 0;
                            end else begin
                                ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Sale);
                                if ItemLedgEntry.FindSet() then begin
                                    repeat
                                        if not ItemLedgEntry."Derived from Blanket Order" then
                                            RemainingForecastQty += ItemLedgEntry.Quantity;
                                    until ItemLedgEntry.Next() = 0;
                                    // Undo shipment shall neutralize consumption from sales
                                    RemainingForecastQty += AjustForUndoneShipments(ItemLedgEntry);
                                end;
                            end;

                            InvtEventBuf.SetRange("Item No.", ProdForecastEntry."Item No.");
                            InvtEventBuf.SetRange(
                              "Availability Date", ProdForecastEntry."Forecast Date", ForecastPeriodEndDate);
                            if Module then
                                InvtEventBuf.SetFilter(Type, '%1|%2', InvtEventBuf.Type::Component, InvtEventBuf.Type::"Assembly Component")
                            else
                                InvtEventBuf.SetFilter(Type, '%1|%2', InvtEventBuf.Type::Sale, InvtEventBuf.Type::Service);
                            OnGetRemainingForecastOAfterInvtEventBufSetFilters(InvtEventBuf, ProdForecastEntry);
                            if InvtEventBuf.Find('-') then
                                repeat
                                    if not (InvtEventBuf.Positive or InvtEventBuf."Derived from Blanket Order")
                                    then
                                        RemainingForecastQty += InvtEventBuf."Remaining Quantity (Base)";
                                until (InvtEventBuf.Next() = 0) or (RemainingForecastQty < 0);

                            if RemainingForecastQty < 0 then
                                RemainingForecastQty := 0;

                            InvtEventBuf.TransferFromForecast(
                                ProdForecastEntry, RemainingForecastQty,
                                InventorySetup."Use Forecast on Locations", InventorySetup."Use Forecast on Variants");
                            InsertEntry(InvtEventBuf);
                            OnGetRemainingForecastOAfterInsertEntry(InvtEventBuf, Item, ProdForecastEntry);

                            ProdForecastEntry.SetRange("Forecast Date", ExcludeForecastBefore, ToDate);
                        until ProdForecastEntry.Next() = 0;
                until ProdForecastEntry2.Next() = 0;
        end;
        InvtEventBuf.Copy(CopyOfInvtEventBuf);
    end;

    local procedure GetBlanketSalesOrders(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item)
    var
        BlanketSalesLine: Record "Sales Line";
        CopyOfInvtEventBuf: Record "Inventory Event Buffer";
        SalesAvailabilityMgt: Codeunit "Sales Availability Mgt.";
        QtyReleased: Decimal;
    begin
        CopyOfInvtEventBuf.Copy(InvtEventBuf);

        if BlanketSalesLine.FindLinesWithItemToPlan(Item, BlanketSalesLine."Document Type"::"Blanket Order") then
            repeat
                InvtEventBuf.SetRange(Type, InvtEventBuf.Type::Sale);
                InvtEventBuf.SetRange("Derived from Blanket Order", true);
                InvtEventBuf.SetRange("Ref. Order No.", BlanketSalesLine."Document No.");
                InvtEventBuf.SetRange("Ref. Order Line No.", BlanketSalesLine."Line No.");
                if InvtEventBuf.Find('-') then
                    repeat
                        QtyReleased -= InvtEventBuf."Remaining Quantity (Base)";
                        OnGetBlanketSalesOrdersOnAfterAdjustQtyReleasedFromInvtEventBuf(InvtEventBuf);
                    until InvtEventBuf.Next() = 0;
                BlanketSalesLine.SetRange("Document No.", BlanketSalesLine."Document No.");
                BlanketSalesLine.SetRange("Line No.", BlanketSalesLine."Line No.");
                repeat
                    if BlanketSalesLine."Outstanding Qty. (Base)" > QtyReleased then begin
                        SalesAvailabilityMgt.TransferFromSalesBlanketOrder(InvtEventBuf, BlanketSalesLine, BlanketSalesLine."Outstanding Qty. (Base)" - QtyReleased);
                        OnGetBlanketSalesOrdersOnAfterTransferFromSalesBlanketOrder(BlanketSalesLine, InvtEventBuf);
                        InsertEntry(InvtEventBuf);
                        QtyReleased := 0;
                    end else
                        QtyReleased -= BlanketSalesLine."Outstanding Qty. (Base)";
                    OnGetBlanketSalesOrdersOnAfterAssignQtyReleased(BlanketSalesLine, QtyReleased);
                until BlanketSalesLine.Next() = 0;
                BlanketSalesLine.SetRange("Document No.");
                BlanketSalesLine.SetRange("Line No.");
            until BlanketSalesLine.Next() = 0;

        InvtEventBuf.Copy(CopyOfInvtEventBuf);
    end;

    local procedure GetPlanningLines(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item)
    var
        ReqLine: Record "Requisition Line";
        ReqLineAvailabilityMgt: Codeunit "Req. Line Availability Mgt.";
        RecRef: RecordRef;
    begin
        // Planning suggestions
        ReqLine.SetRange(Type, ReqLine.Type::Item);
        ReqLine.SetRange("No.", Item."No.");
        ReqLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        ReqLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        OnGetPlanningLinesOnAfterReqLineSetFilters(ReqLine, Item);
        if ReqLine.FindSet() then
            repeat
                RecRef.GetTable(ReqLine);
                case ReqLine."Action Message" of
                    ReqLine."Action Message"::New:
                        begin
                            ReqLineAvailabilityMgt.TransferFromReqLine(InvtEventBuf, ReqLine, ReqLine."Location Code", ReqLine."Due Date", ReqLine."Quantity (Base)", RecRef.RecordId);
                            InsertEntry(InvtEventBuf);
                        end;
                    ReqLine."Action Message"::"Change Qty.":
                        begin
                            ReqLineAvailabilityMgt.TransferFromReqLine(InvtEventBuf, ReqLine, ReqLine."Location Code", ReqLine."Due Date", -ReqLine.GetOriginalQtyBase(), RecRef.RecordId);
                            InsertEntry(InvtEventBuf);

                            ReqLineAvailabilityMgt.TransferFromReqLine(InvtEventBuf, ReqLine, ReqLine."Location Code", ReqLine."Due Date", ReqLine."Quantity (Base)", RecRef.RecordId);
                            InsertEntry(InvtEventBuf);
                        end;
                    ReqLine."Action Message"::Reschedule:
                        begin
                            ReqLineAvailabilityMgt.TransferFromReqLine(InvtEventBuf, ReqLine, ReqLine."Location Code", ReqLine."Original Due Date", -ReqLine."Quantity (Base)", RecRef.RecordId);
                            InsertEntry(InvtEventBuf);

                            ReqLineAvailabilityMgt.TransferFromReqLine(InvtEventBuf, ReqLine, ReqLine."Location Code", ReqLine."Due Date", ReqLine."Quantity (Base)", RecRef.RecordId);
                            InsertEntry(InvtEventBuf);
                        end;
                    ReqLine."Action Message"::"Resched. & Chg. Qty.":
                        begin
                            ReqLineAvailabilityMgt.TransferFromReqLine(InvtEventBuf, ReqLine, ReqLine."Location Code", ReqLine."Original Due Date", -ReqLine.GetOriginalQtyBase(), RecRef.RecordId);
                            InsertEntry(InvtEventBuf);

                            ReqLineAvailabilityMgt.TransferFromReqLine(InvtEventBuf, ReqLine, ReqLine."Location Code", ReqLine."Due Date", ReqLine."Quantity (Base)", RecRef.RecordId);
                            InsertEntry(InvtEventBuf);
                        end;
                    ReqLine."Action Message"::Cancel:
                        begin
                            ReqLineAvailabilityMgt.TransferFromReqLine(InvtEventBuf, ReqLine, ReqLine."Location Code", ReqLine."Due Date", -ReqLine.GetOriginalQtyBase(), RecRef.RecordId);
                            InsertEntry(InvtEventBuf);
                        end;
                end;
            until ReqLine.Next() = 0;

        OnAfterGetPlanningLines(InvtEventBuf, Item, ReqLine, RecRef);
    end;

    local procedure GetPlanningComponents(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item)
    var
        PlanningComp: Record "Planning Component";
        CopyOfInvtEventBuf: Record "Inventory Event Buffer";
        CameFromInvtEventBuf: Record "Inventory Event Buffer";
        ReqLineAvailabilityMgt: Codeunit "Req. Line Availability Mgt.";
        ParentActionMessage: Enum "Action Message Type";
    begin
        // Neutralize Prod. Orders Components as they might be replaced by planning components
        CopyOfInvtEventBuf.Copy(InvtEventBuf);
        InvtEventBuf.SetRange(Type, InvtEventBuf.Type::Component);
        InvtEventBuf.SetRange("Action Message", InvtEventBuf."Action Message"::" ");
        if InvtEventBuf.Find('-') then
            repeat
                CameFromInvtEventBuf.Copy(InvtEventBuf);
                if ParentIsInPlanning(InvtEventBuf, ParentActionMessage) then begin
                    InvtEventBuf.PlanRevertEntry(InvtEventBuf, ParentActionMessage);
                    InsertEntry(InvtEventBuf);
                end;
                InvtEventBuf.Copy(CameFromInvtEventBuf);
            until InvtEventBuf.Next() = 0;
        InvtEventBuf.Copy(CopyOfInvtEventBuf);

        // Insert possible replacements
        if PlanningComp.FindLinesWithItemToPlan(Item) then
            repeat
                ReqLineAvailabilityMgt.TransferFromPlanProdComp(InvtEventBuf, PlanningComp);
                InsertEntry(InvtEventBuf);
            until PlanningComp.Next() = 0;
    end;

    local procedure GetPlanningTransDemand(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item)
    var
        TransferReqLine: Record "Requisition Line";
        TransferLine: Record "Transfer Line";
        TransferAvailabilityMgt: Codeunit "Transfer Availability Mgt.";
        ReqLineAvailabilityMgt: Codeunit "Req. Line Availability Mgt.";
    begin
        TransferReqLine.SetCurrentKey("Replenishment System", Type, "No.", "Variant Code", "Transfer-from Code", "Transfer Shipment Date");
        TransferReqLine.SetRange("Replenishment System", TransferReqLine."Replenishment System"::Transfer);
        TransferReqLine.SetRange(Type, TransferReqLine.Type::Item);
        TransferReqLine.SetRange("No.", Item."No.");
        Item.CopyFilter("Location Filter", TransferReqLine."Transfer-from Code");
        Item.CopyFilter("Variant Filter", TransferReqLine."Variant Code");
        Item.CopyFilter("Date Filter", TransferReqLine."Transfer Shipment Date");
        OnGetPlanningTransDemandOnAfterTransferReqLineSetFilters(TransferReqLine, Item);
        if TransferReqLine.FindSet() then
            repeat
                if TransferReqLine."Action Message" <> TransferReqLine."Action Message"::New then begin
                    // Neutralize demand from the related document
                    FindTransDemandToReplace(TransferReqLine, TransferLine);
                    TransferAvailabilityMgt.TransferFromOutboundTransOrder(InvtEventBuf, TransferLine);
                    InvtEventBuf.PlanRevertEntry(InvtEventBuf, TransferReqLine."Action Message");
                    InsertEntry(InvtEventBuf);
                end;
                ReqLineAvailabilityMgt.TransferFromReqLineTransDemand(InvtEventBuf, TransferReqLine);
                InsertEntry(InvtEventBuf);
            until TransferReqLine.Next() = 0;
    end;

    procedure InsertEntry(var NewInvtEventBuffer: Record "Inventory Event Buffer")
    begin
        NewInvtEventBuffer."Entry No." := NextEntryNo();
        NewInvtEventBuffer.Insert();
    end;

    procedure NextEntryNo(): Integer
    begin
        EntryNo += 1;
        exit(EntryNo);
    end;

    local procedure FindForecastPeriodEndDate(var ProdForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry"; ToDate: Date): Date
    var
        NextProdForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry";
        NextForecastExist: Boolean;
    begin
        NextProdForecastEntry.Copy(ProdForecastEntry);
        NextProdForecastEntry.SetRange("Forecast Date", ProdForecastEntry."Forecast Date" + 1, ToDate);
        if NextProdForecastEntry.FindSet() then
            repeat
                NextProdForecastEntry.SetRange("Forecast Date", NextProdForecastEntry."Forecast Date");
                NextProdForecastEntry.CalcSums("Forecast Quantity (Base)");
                if NextProdForecastEntry."Forecast Quantity (Base)" = 0 then begin
                    NextProdForecastEntry.SetRange("Forecast Date", NextProdForecastEntry."Forecast Date" + 1, ToDate);
                    if NextProdForecastEntry.Next() = 0 then
                        NextProdForecastEntry."Forecast Date" := ToDate + 1;
                end else
                    NextForecastExist := true;
            until (NextProdForecastEntry."Forecast Date" = ToDate + 1) or NextForecastExist
        else
            NextProdForecastEntry."Forecast Date" := ToDate + 1;
        exit(NextProdForecastEntry."Forecast Date" - 1);
    end;

    local procedure AjustForUndoneShipments(var ItemLedgEntry: Record "Item Ledger Entry") AdjustQty: Decimal
    var
        CorItemLedgEntry: Record "Item Ledger Entry";
    begin
        CorItemLedgEntry.Copy(ItemLedgEntry);
        CorItemLedgEntry.SetRange(Positive, true);
        CorItemLedgEntry.SetRange(Correction, true);
        if CorItemLedgEntry.FindSet() then
            repeat
                if not CorItemLedgEntry."Derived from Blanket Order" then
                    AdjustQty += CorItemLedgEntry.Quantity;
            until CorItemLedgEntry.Next() = 0;
        ItemLedgEntry.SetRange(Correction);
    end;

    local procedure ParentIsInPlanning(InvtEventBuf: Record "Inventory Event Buffer"; var ParentActionMessage: Enum "Action Message Type") Result: Boolean
    begin
        OnParentIsInPlanning(InvtEventBuf, ParentActionMessage, Result);
    end;

    local procedure FindTransDemandToReplace(ReqLine: Record "Requisition Line"; var TransLine: Record "Transfer Line")
    begin
        TransLine.Get(ReqLine."Ref. Order No.", ReqLine."Ref. Line No.");
    end;

    local procedure FindReplishmentLocation(var ReplenishmentLocation: Code[10]; var Item: Record Item; var LocationMandatory: Boolean): Boolean
    var
        SKU: Record "Stockkeeping Unit";
        InvtSetup: Record "Inventory Setup";
    begin
        InvtSetup.Get();
        LocationMandatory := InvtSetup."Location Mandatory";

        ReplenishmentLocation := '';
        SKU.SetCurrentKey("Item No.", "Location Code", "Variant Code");
        SKU.SetRange("Item No.", Item."No.");
        Item.CopyFilter("Location Filter", SKU."Location Code");
        Item.CopyFilter("Variant Filter", SKU."Variant Code");
        SKU.SetRange("Replenishment System", Item."Replenishment System"::Purchase, Item."Replenishment System"::"Prod. Order");
        SKU.SetFilter("Reordering Policy", '<>%1', SKU."Reordering Policy"::" ");
        if SKU.Find('-') then
            if SKU.Next() = 0 then
                ReplenishmentLocation := SKU."Location Code";
        exit(ReplenishmentLocation <> '');
    end;

    local procedure IsInTransitLocation(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
    begin
        if Location.Get(LocationCode) then
            exit(Location."Use As In-Transit");
        exit(false);
    end;

    local procedure ForecastExist(var ProdForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry"; ExcludeForecastBefore: Date; FromDate: Date; ToDate: Date): Boolean
    var
        ForecastExist: Boolean;
    begin
        ProdForecastEntry.SetRange("Forecast Date", ExcludeForecastBefore, FromDate);
        if ProdForecastEntry.Find('+') then
            repeat
                ProdForecastEntry.SetRange("Forecast Date", ProdForecastEntry."Forecast Date");
                ProdForecastEntry.CalcSums("Forecast Quantity (Base)");
                if ProdForecastEntry."Forecast Quantity (Base)" <> 0 then
                    ForecastExist := true
                else
                    ProdForecastEntry.SetRange("Forecast Date", ExcludeForecastBefore, ProdForecastEntry."Forecast Date" - 1);
            until (not ProdForecastEntry.Find('+')) or ForecastExist;

        if not ForecastExist then begin
            if ExcludeForecastBefore > FromDate then
                ProdForecastEntry.SetRange("Forecast Date", ExcludeForecastBefore, ToDate)
            else
                ProdForecastEntry.SetRange("Forecast Date", FromDate + 1, ToDate);
            if ProdForecastEntry.Find('-') then
                repeat
                    ProdForecastEntry.SetRange("Forecast Date", ProdForecastEntry."Forecast Date");
                    ProdForecastEntry.CalcSums("Forecast Quantity (Base)");
                    if ProdForecastEntry."Forecast Quantity (Base)" <> 0 then
                        ForecastExist := true
                    else
                        ProdForecastEntry.SetRange("Forecast Date", ProdForecastEntry."Forecast Date" + 1, ToDate);
                until (not ProdForecastEntry.Find('-')) or ForecastExist
        end;
        exit(ForecastExist);
    end;

    procedure GetSourceReferences(FromRecordID: RecordID; TransferDirection: Enum "Transfer Direction"; var SourceType: Integer; var SourceSubtype: Integer; var SourceID: Code[20]; var SourceBatchName: Code[10]; var SourceProdOrderLine: Integer; var SourceRefNo: Integer): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        TransLine: Record "Transfer Line";
        PlngComp: Record "Planning Component";
        ProdForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry";
        ReqLine: Record "Requisition Line";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        SourceType := 0;
        SourceSubtype := 0;
        SourceID := '';
        SourceBatchName := '';
        SourceProdOrderLine := 0;
        SourceRefNo := 0;

        RecRef := FromRecordID.GetRecord();

        case FromRecordID.TableNo of
            Database::"Item Ledger Entry":
                begin
                    RecRef.SetTable(ItemLedgEntry);
                    SourceType := Database::"Item Ledger Entry";
                    SourceRefNo := ItemLedgEntry."Entry No.";
                end;
            Database::"Sales Line":
                begin
                    RecRef.SetTable(SalesLine);
                    SourceType := Database::"Sales Line";
                    SourceSubtype := SalesLine."Document Type".AsInteger();
                    SourceID := SalesLine."Document No.";
                    SourceRefNo := SalesLine."Line No.";
                end;
            Database::"Purchase Line":
                begin
                    RecRef.SetTable(PurchLine);
                    SourceType := Database::"Purchase Line";
                    SourceSubtype := PurchLine."Document Type".AsInteger();
                    SourceID := PurchLine."Document No.";
                    SourceRefNo := PurchLine."Line No.";
                end;
            Database::"Transfer Line":
                begin
                    RecRef.SetTable(TransLine);
                    SourceType := Database::"Transfer Line";
                    SourceSubtype := TransferDirection.AsInteger();
                    TransLine.Get(TransLine."Document No.", TransLine."Line No.");
                    SourceID := TransLine."Document No.";
                    SourceProdOrderLine := TransLine."Derived From Line No.";
                    SourceRefNo := TransLine."Line No.";
                end;
            Database::"Planning Component":
                begin
                    RecRef.SetTable(PlngComp);
                    SourceType := Database::"Planning Component";
                    SourceID := PlngComp."Worksheet Template Name";
                    SourceBatchName := PlngComp."Worksheet Batch Name";
                    SourceProdOrderLine := PlngComp."Worksheet Line No.";
                    SourceRefNo := PlngComp."Line No.";
                end;
            Database::"Requisition Line":
                begin
                    RecRef.SetTable(ReqLine);
                    SourceType := Database::"Requisition Line";
                    SourceSubtype := TransferDirection.AsInteger();
                    SourceID := ReqLine."Worksheet Template Name";
                    SourceBatchName := ReqLine."Journal Batch Name";
                    SourceRefNo := ReqLine."Line No.";
                end;
            Database::Microsoft.Manufacturing.Forecast."Production Forecast Entry":
                begin
                    RecRef.SetTable(ProdForecastEntry);
                    SourceType := Database::Microsoft.Manufacturing.Forecast."Production Forecast Entry";
                    SourceRefNo := ProdForecastEntry."Entry No.";
                end;
            else begin
                IsHandled := false;
                OnAfterGetSourceReferences(
                  FromRecordID, TransferDirection, SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo,
                  IsHandled, RecRef);
                if not IsHandled then
                    exit(false);
            end;
        end;
        exit(true);
    end;

    procedure ShowDocument(RecordID: RecordID)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ReturnShptHeader: Record "Return Shipment Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        TransferHeader: Record "Transfer Header";
        TransShptHeader: Record "Transfer Shipment Header";
        TransRcptHeader: Record "Transfer Receipt Header";
        ProdForecastName: Record Microsoft.Manufacturing.Forecast."Production Forecast Name";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        DemandForecastCard: Page Microsoft.Manufacturing.Forecast."Demand Forecast Card";
        PlanningWorksheet: Page "Planning Worksheet";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        if Format(RecordID) = '' then
            exit;

        RecRef := RecordID.GetRecord();

        OnBeforeShowDocument(RecRef);

        case RecordID.TableNo of
            Database::"Item Ledger Entry":
                begin
                    RecRef.SetTable(ItemLedgEntry);
                    ItemLedgEntry.Get(ItemLedgEntry."Entry No.");
                    ItemLedgEntry.SetRange("Item No.", ItemLedgEntry."Item No.");
                    if ItemLedgEntry."Location Code" <> '' then
                        ItemLedgEntry.SetRange("Location Code", ItemLedgEntry."Location Code");
                    if ItemLedgEntry."Variant Code" <> '' then
                        ItemLedgEntry.SetRange("Variant Code", ItemLedgEntry."Variant Code");
                    PAGE.RunModal(Page::"Item Ledger Entries", ItemLedgEntry);
                end;
            Database::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    RunSalesHeaderPage(SalesHeader);
                end;
            Database::"Sales Shipment Header":
                begin
                    RecRef.SetTable(SalesShptHeader);
                    IsHandled := false;
                    OnBeforeShowSalesShipmentHeader(SalesShptHeader, IsHandled);
                    if not IsHandled then
                        PAGE.RunModal(Page::"Posted Sales Shipment", SalesShptHeader);
                end;
            Database::"Sales Invoice Header":
                begin
                    RecRef.SetTable(SalesInvHeader);
                    IsHandled := false;
                    OnBeforeShowSalesInvoiceHeader(SalesInvHeader, IsHandled);
                    if not IsHandled then
                        PAGE.RunModal(Page::"Posted Sales Invoice", SalesInvHeader);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    RecRef.SetTable(SalesCrMemoHeader);
                    IsHandled := false;
                    OnBeforeShowSalesCrMemoHeader(SalesCrMemoHeader, IsHandled);
                    if not IsHandled then
                        PAGE.RunModal(Page::"Posted Sales Credit Memo", SalesCrMemoHeader);
                end;
            Database::"Purchase Header":
                begin
                    RecRef.SetTable(PurchHeader);
                    RunPurchHeaderPage(PurchHeader);
                end;
            Database::"Purch. Rcpt. Header":
                begin
                    RecRef.SetTable(PurchRcptHeader);
                    IsHandled := false;
                    OnBeforeShowPurchRcptHeader(PurchRcptHeader, IsHandled);
                    if not IsHandled then
                        PAGE.RunModal(Page::"Posted Purchase Receipt", PurchRcptHeader);
                end;
            Database::"Purch. Inv. Header":
                begin
                    RecRef.SetTable(PurchInvHeader);
                    IsHandled := false;
                    OnBeforeShowPurchInvHeader(PurchInvHeader, IsHandled);
                    if not IsHandled then
                        PAGE.RunModal(Page::"Posted Purchase Invoice", PurchInvHeader);
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    RecRef.SetTable(PurchCrMemoHdr);
                    IsHandled := false;
                    OnBeforeShowPurchCrMemoHdr(PurchCrMemoHdr, IsHandled);
                    if not IsHandled then
                        PAGE.RunModal(Page::"Posted Purchase Credit Memo", PurchCrMemoHdr);
                end;
            Database::"Return Shipment Header":
                begin
                    RecRef.SetTable(ReturnShptHeader);
                    IsHandled := false;
                    OnBeforeShowReturnShptHeader(ReturnShptHeader, IsHandled);
                    if not IsHandled then
                        PAGE.RunModal(Page::"Posted Return Shipment", ReturnShptHeader);
                end;
            Database::"Return Receipt Header":
                begin
                    RecRef.SetTable(ReturnRcptHeader);
                    IsHandled := false;
                    OnBeforeShowReturnRcptHeader(ReturnRcptHeader, IsHandled);
                    if not IsHandled then
                        PAGE.RunModal(Page::"Posted Return Receipt", ReturnRcptHeader);
                end;
            Database::"Transfer Header":
                begin
                    RecRef.SetTable(TransferHeader);
                    PAGE.RunModal(Page::"Transfer Order", TransferHeader);
                end;
            Database::"Transfer Shipment Header":
                begin
                    RecRef.SetTable(TransShptHeader);
                    PAGE.RunModal(Page::"Posted Transfer Shipment", TransShptHeader);
                end;
            Database::"Transfer Receipt Header":
                begin
                    RecRef.SetTable(TransRcptHeader);
                    PAGE.RunModal(Page::"Posted Transfer Receipt", TransRcptHeader);
                end;
            Database::Microsoft.Manufacturing.Forecast."Production Forecast Name":
                begin
                    RecRef.SetTable(ProdForecastName);
                    DemandForecastCard.SetRecord(ProdForecastName);
                    DemandForecastCard.RunModal();
                end;
            Database::"Requisition Line":
                begin
                    RecRef.SetTable(RequisitionLine);
                    ReqWkshTemplate.Get(RequisitionLine."Worksheet Template Name");
                    ReqWkshTemplate.TestField("Page ID");
                    if (ReqWkshTemplate.Type = ReqWkshTemplate.Type::Planning) and (ReqWkshTemplate."Page ID" = Page::"Planning Worksheet") then begin
                        PlanningWorksheet.SetTableView(RequisitionLine);
                        PlanningWorksheet.SetRecord(RequisitionLine);
                        PlanningWorksheet.CallFromItemAvailabilityByEvent(true);
                        PlanningWorksheet.RunModal();
                    end else
                        PAGE.RunModal(ReqWkshTemplate."Page ID", RequisitionLine);
                end;
            Database::"Planning Component":
                begin
                    RecRef.SetTable(PlanningComponent);
                    RequisitionLine.Get(
                      PlanningComponent."Worksheet Template Name", PlanningComponent."Worksheet Batch Name",
                      PlanningComponent."Worksheet Line No.");
                    PlanningWorksheet.SetTableView(RequisitionLine);
                    PlanningWorksheet.SetRecord(RequisitionLine);
                    PlanningWorksheet.Run();
                    PlanningWorksheet.OpenPlanningComponent(PlanningComponent);
                end;
            else begin
                IsHandled := false;
                OnAfterShowDocument(RecordID, IsHandled, RecRef);
                if not IsHandled then
                    Error(TableNotSupportedErr, RecordID.TableNo);
            end;
        end;
    end;

    local procedure RunSalesHeaderPage(var SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunSalesHeaderPage(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                PAGE.RunModal(Page::"Sales Order", SalesHeader);
            SalesHeader."Document Type"::Invoice:
                PAGE.RunModal(Page::"Sales Invoice", SalesHeader);
            SalesHeader."Document Type"::"Credit Memo":
                PAGE.RunModal(Page::"Sales Credit Memo", SalesHeader);
            SalesHeader."Document Type"::"Blanket Order":
                PAGE.RunModal(Page::"Blanket Sales Order", SalesHeader);
            SalesHeader."Document Type"::"Return Order":
                PAGE.RunModal(Page::"Sales Return Order", SalesHeader);
        end;
    end;

    local procedure RunPurchHeaderPage(var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunPurchHeaderPage(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        case PurchHeader."Document Type" of
            PurchHeader."Document Type"::Order:
                PAGE.RunModal(Page::"Purchase Order", PurchHeader);
            PurchHeader."Document Type"::Invoice:
                PAGE.RunModal(Page::"Purchase Invoice", PurchHeader);
            PurchHeader."Document Type"::"Credit Memo":
                PAGE.RunModal(Page::"Purchase Credit Memo", PurchHeader);
            PurchHeader."Document Type"::"Blanket Order":
                PAGE.RunModal(Page::"Blanket Purchase Order", PurchHeader);
            PurchHeader."Document Type"::"Return Order":
                PAGE.RunModal(Page::"Purchase Return Order", PurchHeader);
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetDocumentEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; var CurrEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDocumentEntries(var InventoryEventBuffer: Record "Inventory Event Buffer"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAnticipatedDemand(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; ForecastName: Code[10]; ExcludeForecastBefore: Date; IncludeBlanketOrders: Boolean; EntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPlanningLines(var InvtEventBuf: Record "Inventory Event Buffer"; Item: Record "Item"; ReqLine: Record "Requisition Line"; FromRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSourceReferences(FromRecordID: RecordID; TransferDirection: Enum "Transfer Direction"; var SourceType: Integer; var SourceSubtype: Integer; var SourceID: Code[20]; var SourceBatchName: Code[10]; var SourceProdOrderLine: Integer; var SourceRefNo: Integer; var IsHandled: Boolean; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDocument(RecordID: RecordID; var IsHandled: Boolean; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunSalesHeaderPage(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPurchHeaderPage(var PurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeRunProductionOrderPage(var ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var IsHandled: Boolean)
    begin
        OnBeforeRunProductionOrderPage(ProductionOrder, IsHandled);
    end;

    [Obsolete('Moved to codeunit ProdOrderAvailabilityMgt', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunProductionOrderPage(var ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTryGetQtyOnInventory(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; var Result: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBlanketSalesOrdersOnAfterAssignQtyReleased(BlanketSalesLine: Record "Sales Line"; QtyReleased: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBlanketSalesOrdersOnAfterTransferFromSalesBlanketOrder(BlanketSalesLine: Record "Sales Line"; var InventoryEventBuffer: Record "Inventory Event Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBlanketSalesOrdersOnAfterAdjustQtyReleasedFromInvtEventBuf(InventoryEventBuffer: Record "Inventory Event Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPlanningLinesOnAfterReqLineSetFilters(var ReqLine: record "Requisition Line"; var Item: record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRemainingForecastOnAfterSetItemFilters(var Item: Record Item; ProductionForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRemainingForecastOAfterInvtEventBufSetFilters(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProductionForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRemainingForecastOAfterInsertEntry(var InventoryEventBuffer: Record "Inventory Event Buffer"; var Item: Record Item; ProductionForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRemainingForecastOnBeforeCalcForecastQuantityBase(var ProductionForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRemainingForecastOnBeforeLoopOnAfterSetItemFilters(var Item: Record Item; ProductionForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry"; ProductionForecastEntry2: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTryGetQtyOnInventoryOnBeforeInsertEntry(var InvtEventBuf: Record "Inventory Event Buffer"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDocument(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSalesShipmentHeader(SalesShptHeader: Record "Sales Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSalesInvoiceHeader(SalesInvHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSalesCrMemoHeader(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPurchRcptHeader(PurchRcptHeader: Record "Purch. Rcpt. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPurchInvHeader(PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPurchCrMemoHdr(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReturnRcptHeader(ReturnRcptHeader: Record "Return Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReturnShptHeader(ReturnShptHeader: Record "Return Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTryGetPurchOrderSupplyEntriesOnBeforeInsertEntry(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPlanningTransDemandOnAfterTransferReqLineSetFilters(var RequisitionLine: Record "Requisition Line"; var Item: Record Item)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnParentIsInPlanningOnAfterReqLineSetFilters(var RequisitionLine: Record "Requisition Line"; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnParentIsInPlanningOnAfterReqLineSetFilters(RequisitionLine, ProdOrderComp);
    end;

    [Obsolete('Moved to codeunit ProdOrderAvailabilityMgt', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnParentIsInPlanningOnAfterReqLineSetFilters(var RequisitionLine: Record "Requisition Line"; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnParentIsInPlanning(InvtEventBuf: Record "Inventory Event Buffer"; var ParentActionMessage: Enum "Action Message Type"; var Result: Boolean)
    begin
    end;
}

