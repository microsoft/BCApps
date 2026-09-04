// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using System.Utilities;

codeunit 6534 "Item Tracking Code Change Mgt."
{
    #region Item Tracking Code Change Checks

    internal procedure ShouldUseAdvancedValidation(
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PreviousItemTrackingCode: Record "Item Tracking Code"): Boolean
    begin
        if ItemTrackingCode.IsSpecificTrackingChanged(PreviousItemTrackingCode) then
            if ItemLedgerEntriesExist(Item."No.") then
                exit(true);

        if ItemTrackingCode.IsWarehouseTrackingChanged(PreviousItemTrackingCode) then
            if WarehouseEntriesExist(Item."No.") then
                exit(true);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    internal procedure ValidateItemTrackingCodeChangeAdvanced(
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PreviousItemTrackingCode: Record "Item Tracking Code")
    begin
        TestNoExpirationCalculation(Item);
        TestCostIsAdjustedAndPostedToGL(Item);
        TestNoOpenItemLedgerEntries(Item);
        TestNoItemLedgerEntriesOnChangeDate(Item);
        TestNoReservationEntriesOrTrackingSpecifications(Item);
        TestNoDocumentLinesPreventingTrackingCodeChange(Item);
        TestNoJournalOrPlanningLines(Item);
        TestNoOutstandingWarehouseQuantity(Item);
        TestNoWarehouseDocumentsOrActivities(Item);
        TestNoServiceItems(Item);

        if HasCollectedErrors() then begin
            ShowCollectedErrors();
            exit;
        end;

        LogItemTrackingCodeChange(Item."No.", PreviousItemTrackingCode.Code, ItemTrackingCode.Code);
    end;

    local procedure ShowCollectedErrors()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        ErrorMessageMgt.CollectErrors(TempErrorMessage);
        TempErrorMessage.ShowErrorMessages(true);
    end;

    local procedure TestNoExpirationCalculation(Item: Record Item)
    var
        EmptyDateFormula: DateFormula;
    begin
        Item.TestField("Expiration Calculation", EmptyDateFormula, ErrorInfo.Create('', true));
    end;

    local procedure TestCostIsAdjustedAndPostedToGL(Item: Record Item)
    begin
        Item.TestField("Cost is Adjusted", true, ErrorInfo.Create('', true));
        Item.CalcFields("Cost is Posted to G/L");
        Item.TestField("Cost is Posted to G/L", true, ErrorInfo.Create('', true));
    end;

    local procedure TestNoOpenItemLedgerEntries(Item: Record Item)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.", Open);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange(Open, true);
        if not ItemLedgerEntry.IsEmpty() then
            CollectError(
                StrSubstNo(
                    OpenItemLedgerEntriesExistErr,
                    Item.FieldCaption("Item Tracking Code"), Item."No."));
    end;

    local procedure TestNoItemLedgerEntriesOnChangeDate(Item: Record Item)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.", "Posting Date");
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Posting Date", WorkDate());
        if not ItemLedgerEntry.IsEmpty() then
            CollectError(StrSubstNo(ItemLedgerEntriesOnChangeDateErr, Item."No.", WorkDate()));
    end;

    local procedure TestNoReservationEntriesOrTrackingSpecifications(Item: Record Item)
    var
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
    begin
        ReservationEntry.SetCurrentKey("Item No.");
        ReservationEntry.SetRange("Item No.", Item."No.");
        if not ReservationEntry.IsEmpty() then
            CollectRecordsExistError(Item, ReservationEntry.TableCaption());

        TrackingSpecification.SetRange("Item No.", Item."No.");
        if not TrackingSpecification.IsEmpty() then
            CollectRecordsExistError(Item, TrackingSpecification.TableCaption());
    end;

    local procedure TestNoDocumentLinesPreventingTrackingCodeChange(Item: Record Item)
    begin
        CheckSalesDocuments(Item);
        CheckPurchaseDocuments(Item);
        CheckTransferDocuments(Item);
        CheckServiceDocuments(Item);
        CheckProjectDocuments(Item);
        CheckProductionDocuments(Item);
        CheckAssemblyDocuments(Item);
    end;

    local procedure CheckSalesDocuments(Item: Record Item)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetCurrentKey(Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Document Type", "Shipment Date");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", Item."No.");
        SalesLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
        if not SalesLine.IsEmpty() then
            CollectRecordsExistError(Item, SalesLine.TableCaption());

        SalesLine.SetRange("Qty. Shipped Not Invoiced");
        SalesLine.SetFilter("Return Qty. Rcd. Not Invd.", '<>0');
        if not SalesLine.IsEmpty() then
            CollectRecordsExistError(Item, SalesLine.TableCaption());
    end;

    local procedure CheckPurchaseDocuments(Item: Record Item)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetCurrentKey("Document Type", Type, "No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
        if not PurchaseLine.IsEmpty() then
            CollectRecordsExistError(Item, PurchaseLine.TableCaption());

        PurchaseLine.SetRange("Qty. Rcd. Not Invoiced");
        PurchaseLine.SetFilter("Return Qty. Shipped Not Invd.", '<>0');
        if not PurchaseLine.IsEmpty() then
            CollectRecordsExistError(Item, PurchaseLine.TableCaption());
    end;

    local procedure CheckTransferDocuments(Item: Record Item)
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetCurrentKey("Item No.");
        TransferLine.SetRange("Item No.", Item."No.");
        TransferLine.SetFilter("Outstanding Qty. (Base)", '<>0');
        if not TransferLine.IsEmpty() then
            CollectRecordsExistError(Item, TransferLine.TableCaption());
    end;

    local procedure CheckServiceDocuments(Item: Record Item)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetCurrentKey(Type, "No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetRange("No.", Item."No.");
        ServiceLine.SetFilter("Outstanding Qty. (Base)", '<>0');
        if not ServiceLine.IsEmpty() then
            CollectRecordsExistError(Item, ServiceLine.TableCaption());

        ServiceItemLine.SetRange("Item No.", Item."No.");
        if not ServiceItemLine.IsEmpty() then
            CollectRecordsExistError(Item, ServiceItemLine.TableCaption());
    end;

    local procedure CheckProjectDocuments(Item: Record Item)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetCurrentKey(Type, "No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.SetRange("No.", Item."No.");
        JobPlanningLine.SetFilter("Remaining Qty. (Base)", '<>0');
        if not JobPlanningLine.IsEmpty() then
            CollectRecordsExistError(Item, JobPlanningLine.TableCaption());
    end;

    local procedure CheckProductionDocuments(Item: Record Item)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetCurrentKey(Status, "Item No.");
        ProdOrderLine.SetFilter(Status, '..%1', ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.SetFilter("Remaining Qty. (Base)", '<>0');
        if not ProdOrderLine.IsEmpty() then
            CollectRecordsExistError(Item, ProdOrderLine.TableCaption());

        ProdOrderComponent.SetCurrentKey(Status, "Item No.");
        ProdOrderComponent.SetFilter(Status, '..%1', ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Item No.", Item."No.");
        ProdOrderComponent.SetFilter("Remaining Qty. (Base)", '<>0');
        if not ProdOrderComponent.IsEmpty() then
            CollectRecordsExistError(Item, ProdOrderComponent.TableCaption());
    end;

    local procedure CheckAssemblyDocuments(Item: Record Item)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyHeader.SetCurrentKey("Document Type", "Item No.");
        AssemblyHeader.SetRange("Item No.", Item."No.");
        AssemblyHeader.SetFilter("Remaining Quantity (Base)", '<>0');
        if not AssemblyHeader.IsEmpty() then
            CollectRecordsExistError(Item, AssemblyHeader.TableCaption());

        AssemblyLine.SetCurrentKey(Type, "No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.SetRange("No.", Item."No.");
        AssemblyLine.SetFilter("Remaining Quantity (Base)", '<>0');
        if not AssemblyLine.IsEmpty() then
            CollectRecordsExistError(Item, AssemblyLine.TableCaption());
    end;

    local procedure TestNoJournalOrPlanningLines(Item: Record Item)
    begin
        CheckItemJournals(Item);
        CheckWarehouseJournals(Item);
        CheckProjectJournals(Item);
        CheckPhysicalInventory(Item);
        CheckRequisitionLines(Item);
    end;

    local procedure CheckItemJournals(Item: Record Item)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetCurrentKey("Item No.");
        ItemJournalLine.SetRange("Item No.", Item."No.");
        if not ItemJournalLine.IsEmpty() then
            CollectRecordsExistError(Item, ItemJournalLine.TableCaption());
    end;

    local procedure CheckWarehouseJournals(Item: Record Item)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        WarehouseJournalLine.SetCurrentKey("Item No.");
        WarehouseJournalLine.SetRange("Item No.", Item."No.");
        if not WarehouseJournalLine.IsEmpty() then
            CollectRecordsExistError(Item, WarehouseJournalLine.TableCaption());
    end;

    local procedure CheckProjectJournals(Item: Record Item)
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        JobJournalLine.SetCurrentKey(Type, "No.");
        JobJournalLine.SetRange(Type, JobJournalLine.Type::Item);
        JobJournalLine.SetRange("No.", Item."No.");
        if not JobJournalLine.IsEmpty() then
            CollectRecordsExistError(Item, JobJournalLine.TableCaption());
    end;

    local procedure CheckPhysicalInventory(Item: Record Item)
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        PhysInvtOrderLine.SetRange("Item No.", Item."No.");
        if not PhysInvtOrderLine.IsEmpty() then
            CollectRecordsExistError(Item, PhysInvtOrderLine.TableCaption());
    end;

    local procedure CheckRequisitionLines(Item: Record Item)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetCurrentKey(Type, "No.");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        if not RequisitionLine.IsEmpty() then
            CollectRecordsExistError(Item, RequisitionLine.TableCaption());
    end;

    local procedure TestNoOutstandingWarehouseQuantity(Item: Record Item)
    var
        BinContent: Record "Bin Content";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetCurrentKey("Item No.");
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.CalcSums("Qty. (Base)");
        if WarehouseEntry."Qty. (Base)" <> 0 then
            CollectRecordsExistError(Item, WarehouseEntry.TableCaption());

        BinContent.SetCurrentKey("Item No.");
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.SetFilter("Quantity (Base)", '<>0');
        if not BinContent.IsEmpty() then
            CollectRecordsExistError(Item, BinContent.TableCaption());
    end;

    local procedure TestNoWarehouseDocumentsOrActivities(Item: Record Item)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseReceiptLine.SetCurrentKey("Item No.");
        WarehouseReceiptLine.SetRange("Item No.", Item."No.");
        WarehouseReceiptLine.SetFilter("Qty. Outstanding (Base)", '<>0');
        if not WarehouseReceiptLine.IsEmpty() then
            CollectRecordsExistError(Item, WarehouseReceiptLine.TableCaption());

        WarehouseShipmentLine.SetCurrentKey("Item No.");
        WarehouseShipmentLine.SetRange("Item No.", Item."No.");
        WarehouseShipmentLine.SetFilter("Qty. Outstanding (Base)", '<>0');
        if not WarehouseShipmentLine.IsEmpty() then
            CollectRecordsExistError(Item, WarehouseShipmentLine.TableCaption());

        WarehouseActivityLine.SetCurrentKey("Item No.");
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetFilter("Qty. Outstanding (Base)", '<>0');
        if not WarehouseActivityLine.IsEmpty() then
            CollectRecordsExistError(Item, WarehouseActivityLine.TableCaption());
    end;

    local procedure TestNoServiceItems(Item: Record Item)
    var
        ServiceItem: Record "Service Item";
    begin
        ServiceItem.SetCurrentKey("Item No.");
        ServiceItem.SetRange("Item No.", Item."No.");
        if not ServiceItem.IsEmpty() then
            CollectRecordsExistError(Item, ServiceItem.TableCaption());
    end;

    local procedure CollectRecordsExistError(Item: Record Item; RecordCaption: Text)
    begin
        CollectError(StrSubstNo(RecordsExistErr, Item.FieldCaption("Item Tracking Code"), Item."No.", RecordCaption));
    end;

    local procedure CollectError(ErrorMessage: Text)
    begin
        Error(ErrorInfo.Create(ErrorMessage, true));
    end;

    local procedure ItemLedgerEntriesExist(ItemNo: Code[20]): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        exit(not ItemLedgerEntry.IsEmpty());
    end;

    local procedure WarehouseEntriesExist(ItemNo: Code[20]): Boolean
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetCurrentKey("Item No.");
        WarehouseEntry.SetRange("Item No.", ItemNo);
        exit(not WarehouseEntry.IsEmpty());
    end;

    #endregion

    local procedure LogItemTrackingCodeChange(ItemNo: Code[20]; PreviousItemTrackingCode: Code[10]; NewItemTrackingCode: Code[10])
    var
        ItemTrackingCodeChangeLog: Record "Item Tracking Code Change Log";
    begin
        ItemTrackingCodeChangeLog.Init();
        ItemTrackingCodeChangeLog.Validate("Item No.", ItemNo);
        ItemTrackingCodeChangeLog.Validate("Change Date", WorkDate());
        ItemTrackingCodeChangeLog.Validate("Previous Item Tracking Code", PreviousItemTrackingCode);
        ItemTrackingCodeChangeLog.Validate("New Item Tracking Code", NewItemTrackingCode);
        ItemTrackingCodeChangeLog.Insert(true);
    end;

    local procedure HasTrackingCodeChanges(ItemNo: Code[20]; PostingDate: Date): Boolean
    var
        ItemTrackingCodeChangeLog: Record "Item Tracking Code Change Log";
    begin
        ItemTrackingCodeChangeLog.SetRange("Item No.", ItemNo);
        ItemTrackingCodeChangeLog.SetFilter("Change Date", '>%1', PostingDate);
        exit(not ItemTrackingCodeChangeLog.IsEmpty());
    end;

    internal procedure IsLinkedApplicationAcrossTrackingPeriods(ItemNo: Code[20]; ItemLedgerEntryNo: Integer): Boolean
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if ItemLedgerEntryNo = 0 then
            exit(false);
        if not ItemLedgerEntry.Get(ItemLedgerEntryNo) then
            exit(false);
        if ItemLedgerEntry."Item No." <> ItemNo then
            exit(false);
        if not HasTrackingCodeChanges(ItemNo, ItemLedgerEntry."Posting Date") then
            exit(false);

        Item.Get(ItemNo);
        exit(GetTrackingCodeAtPosting(ItemLedgerEntry) <> Item."Item Tracking Code");
    end;

    local procedure GetTrackingCodeAtPosting(ItemLedgerEntry: Record "Item Ledger Entry"): Code[10]
    var
        Item: Record Item;
        ItemTrackingCodeChangeLog: Record "Item Tracking Code Change Log";
    begin
        Item.Get(ItemLedgerEntry."Item No.");
        ItemTrackingCodeChangeLog.SetCurrentKey("Item No.", "Change Date");
        ItemTrackingCodeChangeLog.SetRange("Item No.", ItemLedgerEntry."Item No.");
        ItemTrackingCodeChangeLog.SetFilter("Change Date", '>%1', ItemLedgerEntry."Posting Date");

        if ItemTrackingCodeChangeLog.FindFirst() then
            exit(ItemTrackingCodeChangeLog."Previous Item Tracking Code");

        exit(Item."Item Tracking Code");
    end;

    var
        ItemLedgerEntriesOnChangeDateErr: Label 'You cannot change the Item Tracking Code for item %1 because item ledger entries exist with Posting Date %2.', Comment = '%1 = Item No., %2 = posting date';
        OpenItemLedgerEntriesExistErr: Label 'You cannot change %1 for item %2 because one or more open item ledger entries exist.', Comment = '%1 = Item Tracking Code field caption, %2 = Item No.';
        RecordsExistErr: Label 'You cannot change %1 for item %2 because one or more %3 records exist.', Comment = '%1 = Item Tracking Code field caption, %2 = Item No., %3 = table caption';
}
