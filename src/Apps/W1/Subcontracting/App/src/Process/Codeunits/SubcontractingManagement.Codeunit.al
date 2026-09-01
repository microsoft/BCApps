// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 99001505 "Subcontracting Management"
{
    var
        SubcManagementSetup: Record "Subc. Management Setup";
        TempGlobalReservationEntry: Record "Reservation Entry" temporary;
        HasSubManagementSetup: Boolean;

    procedure CalcReceiptDateFromProdCompDueDateWithInbWhseHandlingTime(ProdOrderComponent: Record "Prod. Order Component") ReceiptDate: Date
    begin
        GetSubmanagementSetup();
        if not HasSubManagementSetup or (Format(SubcManagementSetup."Subc. Inb. Whse. Handling Time") = '') then
            exit(ProdOrderComponent."Due Date");

        ReceiptDate := CalcDate('-' + Format(SubcManagementSetup."Subc. Inb. Whse. Handling Time"), ProdOrderComponent."Due Date");

        exit(ReceiptDate);
    end;

    procedure ChangeLocation_OnProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; VendorSubcontrLocation: Code[10]; OriginalLocationCode: Code[10]; OriginalBinCode: Code[20])
    begin
        case ProdOrderComponent."Subcontracting Type" of
            "Subcontracting Type"::InventoryByVendor,
            "Subcontracting Type"::Purchase:
                if (VendorSubcontrLocation <> '') and (ProdOrderComponent."Location Code" <> VendorSubcontrLocation) then
                    ProdOrderComponent.Validate("Location Code", VendorSubcontrLocation);

            "Subcontracting Type"::Transfer,
            "Subcontracting Type"::Empty:
                begin
                    if (ProdOrderComponent."Location Code" <> OriginalLocationCode) and (OriginalLocationCode <> '') then begin
                        ProdOrderComponent.Validate("Location Code", OriginalLocationCode);
                        ProdOrderComponent."Orig. Location Code" := '';
                    end;
                    if (ProdOrderComponent."Bin Code" <> OriginalBinCode) and (OriginalBinCode <> '') then begin
                        ProdOrderComponent.Validate("Bin Code", OriginalBinCode);
                        ProdOrderComponent."Orig. Bin Code" := '';
                    end;
                end;
        end;
    end;

    procedure ChangeLocation_OnPlanningComponent(var PlanningComponent: Record "Planning Component"; VendorSubcontrLocation: Code[10]; OriginalLocationCode: Code[10]; OriginalBinCode: Code[20])
    begin
        case PlanningComponent."Subcontracting Type" of
            "Subcontracting Type"::InventoryByVendor,
            "Subcontracting Type"::Purchase:
                if (VendorSubcontrLocation <> '') and (PlanningComponent."Location Code" <> VendorSubcontrLocation) then
                    PlanningComponent.Validate("Location Code", VendorSubcontrLocation);

            "Subcontracting Type"::Transfer,
            "Subcontracting Type"::Empty:
                begin
                    if (PlanningComponent."Location Code" <> OriginalLocationCode) and (OriginalLocationCode <> '') then begin
                        PlanningComponent.Validate("Location Code", OriginalLocationCode);
                        PlanningComponent."Orig. Location Code" := '';
                    end;
                    if (PlanningComponent."Bin Code" <> OriginalBinCode) and (OriginalBinCode <> '') then begin
                        PlanningComponent.Validate("Bin Code", OriginalBinCode);
                        PlanningComponent."Orig. Bin Code" := '';
                    end;
                end;
        end;
    end;

    procedure CheckDirectTransferIsAllowedForTransferHeader(TransferHeader: Record "Transfer Header")
    begin
        TransferHeader.CheckDirectTransferPosting();
    end;

    procedure CreatePurchProvisionRoutingLine(RoutingHeader: Record "Routing Header")
    var
        RoutingLine: Record "Routing Line";
        Vendor: Record Vendor;
        SingleInstanceDictionary: Codeunit "Single Instance Dictionary";
        SubcontractingManagement: Codeunit "Subcontracting Management";
        RoutingLinkCode: Code[10];
        WorkCenterNo: Code[20];
    begin
        GetSubmanagementSetup();
        if HasSubManagementSetup then
            RoutingLinkCode := SubcManagementSetup."Rtng. Link Code Purch. Prov.";

        Vendor.SetLoadFields("Work Center No.");
        if Vendor.Get(SingleInstanceDictionary.GetCode(SubcontractingManagement.GetDictionaryKey_Sub_CreateProdOrderProcess())) then
            WorkCenterNo := Vendor."Work Center No.";

        if WorkCenterNo = '' then
            WorkCenterNo := SubcManagementSetup."Common Work Center No.";

        if WorkCenterNo = '' then
            exit;

        RoutingLine.Init();
        RoutingLine."Routing No." := RoutingHeader."No.";
        RoutingLine."Operation No." := '01';
        RoutingLine.Type := "Capacity Type Routing"::"Work Center";
        RoutingLine.Validate("No.", WorkCenterNo);
        if RoutingLinkCode <> '' then
            RoutingLine."Routing Link Code" := RoutingLinkCode;

        RoutingLine.Insert();
    end;

    procedure DelLocationLinkedComponents(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ShowMsg: Boolean)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ConfirmManagement: Codeunit "Confirm Management";
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
        RoutingLinkUpdConfQst: Label 'If you change the Work Center, you will also change the default location for components with Routing Link Code=%1.\\Do you want to continue anyway?', Comment = '%1=Routing Link Code';
        SuccessfullyUpdatedMsg: Label 'Successfully updated.';
        UpdateIsCancelledErr: Label 'Update cancelled.';
    begin

        ProdOrderComponent.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        if not ProdOrderComponent.IsEmpty() then begin
            ProdOrderComponent.FindSet();
            if ShowMsg then
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(RoutingLinkUpdConfQst, ProdOrderRoutingLine."Routing Link Code"), true) then
                    Error(UpdateIsCancelledErr);

            ProdOrderLine.SetLoadFields("Item No.", "Variant Code", "Location Code");
            ProdOrderLine.Get(ProdOrderRoutingLine.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
            PlanningGetParameters.AtSKU(
              StockkeepingUnit,
              ProdOrderLine."Item No.",
              ProdOrderLine."Variant Code",
              ProdOrderLine."Location Code");
            repeat
                ProdOrderComponent.Validate("Location Code", StockkeepingUnit."Components at Location");
                ProdOrderComponent.Modify();
            until ProdOrderComponent.Next() = 0;

            if ShowMsg then
                Message(SuccessfullyUpdatedMsg);
        end;
    end;

    procedure GetDictionaryKey_Sub_CreateProdOrderProcess(): Text
    begin
        exit('Sub_CreateProdOrderProcess');
    end;

    procedure GetSubcontractor(WorkCenterNo: Code[20]; var Vendor: Record Vendor): Boolean
    var
        WorkCenter: Record "Work Center";
        HasSubcontractor, IsHandled : Boolean;
        WorkCenterVendorDoesntExistErr: Label 'Vendor %1 on Work Center %2 does not exist.',
            Comment = 'Parameter %1 - subcontractor number, %2 - vendor number.';
    begin
        OnBeforeGetSubcontractor(WorkCenterNo, Vendor, HasSubcontractor, IsHandled);//DO NOT DELETE
        if IsHandled then
            exit(HasSubcontractor);

        WorkCenter.SetLoadFields("Subcontractor No.");
        WorkCenter.Get(WorkCenterNo);
        if WorkCenter."Subcontractor No." <> '' then begin
            Vendor.SetLoadFields("Subcontr. Location Code");
            if not Vendor.Get(WorkCenter."Subcontractor No.") then
                Error(WorkCenterVendorDoesntExistErr, WorkCenter."Subcontractor No.", WorkCenter."No.");
            Vendor.TestField("Subcontr. Location Code");
            exit(true);
        end;
        exit(false);
    end;

    procedure HandleCommonWorkCenter(ItemJournalLine: Record "Item Journal Line"): Boolean
    var
    begin
        if ItemJournalLine."Work Center No." = '' then
            exit(false);
        GetSubmanagementSetup();
        if SubcManagementSetup."Common Work Center No." = ItemJournalLine."Work Center No." then
            exit(true);

        exit(false);
    end;

    procedure UpdateSubcontractorPriceForRequisitionLine(var RequisitionLine: Record "Requisition Line")
    begin
        if IsSubcontracting(RequisitionLine."Work Center No.") then
            RequisitionLine.UpdateSubcontractorPrice();
    end;

    procedure UpdateLinkedComponentsAfterRoutingTransfer(var ProdOrderLine: Record "Prod. Order Line"; var RoutingLine: Record "Routing Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        WorkCenter: Record "Work Center";
    begin
        if ProdOrderRoutingLine.Type <> "Capacity Type"::"Work Center" then
            exit;

        if ProdOrderRoutingLine."Routing Link Code" = '' then
            exit;

        WorkCenter.SetLoadFields("Subcontractor No.");
        WorkCenter.Get(RoutingLine."Work Center No.");
        if WorkCenter."Subcontractor No." = '' then
            exit;

        UpdLinkedComponents(ProdOrderRoutingLine, false);
    end;

    procedure TransferReservationEntryFromProdOrderCompToTransferOrder(TransferLine: Record "Transfer Line"; ProdOrderComponent: Record "Prod. Order Component")
    var
        ReservationEntry: Record "Reservation Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
    begin
        TempGlobalReservationEntry.Reset();
        TempGlobalReservationEntry.DeleteAll();

        if not ProdOrderCompReserve.FindReservEntry(ProdOrderComponent, ReservationEntry) then
            exit;

        if ReservationEntry.FindSet() then
            repeat
                TempGlobalReservationEntry := ReservationEntry;
                TempGlobalReservationEntry.Insert();
            until ReservationEntry.Next() = 0;

        TempReservationEntry.Copy(TempGlobalReservationEntry, true);

        ReservationEntry.TransferReservations(
         ReservationEntry,
         TransferLine."Item No.",
         TransferLine."Variant Code",
         TransferLine."Transfer-from Code",
         true,
         0,
         TransferLine."Qty. per Unit of Measure",
         Database::"Transfer Line",
         0,  // Direction::Outbound
         TransferLine."Document No.",
         '',
         0,
         TransferLine."Line No.");
    end;

    procedure CreateReservEntryForTransferReceiptToProdOrderComp(
     TransferLine: Record "Transfer Line";
     ProdOrderComponent: Record "Prod. Order Component")
    var
        Item: Record Item;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        TempGlobalReservationEntry.SetRange("Reservation Status", TempGlobalReservationEntry."Reservation Status"::Reservation);
        if not TempGlobalReservationEntry.FindSet() then
            exit;

        repeat
            if TempGlobalReservationEntry.GetItemTrackingEntryType() <> "Item Tracking Entry Type"::None then
                if Item.Get(TempGlobalReservationEntry."Item No.") then begin
                    TempGlobalReservationEntry."Location Code" := ProdOrderComponent."Location Code";
                    CreateReservEntry.CreateReservEntryFor(
                        Database::"Transfer Line",
                        1,  // Direction::Inbound
                        TransferLine."Document No.",
                        '',
                        TransferLine."Derived From Line No.",
                        TransferLine."Line No.",
                        TransferLine."Qty. per Unit of Measure",
                        Abs(TempGlobalReservationEntry.Quantity),
                        Abs(TempGlobalReservationEntry."Quantity (Base)"),
                        TempGlobalReservationEntry);

                    TempTrackingSpecification.Init();
                    TempTrackingSpecification.SetSource(
                        Database::"Prod. Order Component",
                        ProdOrderComponent.Status.AsInteger(),
                        ProdOrderComponent."Prod. Order No.",
                        ProdOrderComponent."Line No.",
                        '',
                        ProdOrderComponent."Prod. Order Line No.");
                    TempTrackingSpecification."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";
                    TempTrackingSpecification.CopyTrackingFromReservEntry(TempGlobalReservationEntry);

                    CreateReservEntry.CreateReservEntryFrom(TempTrackingSpecification);

                    CreateReservEntry.CreateEntry(
                        TempGlobalReservationEntry."Item No.",
                        TempGlobalReservationEntry."Variant Code",
                        TransferLine."Transfer-to Code",
                        TempGlobalReservationEntry.Description,
                        TransferLine."Receipt Date",
                        ProdOrderComponent."Due Date",
                        0,
                        TempGlobalReservationEntry."Reservation Status");
                end;
        until TempGlobalReservationEntry.Next() = 0;
    end;

    procedure TransferReservationEntryFromPstTransferLineToProdOrderComp(var TransferReceiptLine: Record "Transfer Receipt Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderComponent: Record "Prod. Order Component";
        TempForReservationEntry: Record "Reservation Entry" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
    begin
        if (TransferReceiptLine."Prod. Order No." = '') or (TransferReceiptLine."Operation No." = '') then
            exit;
        if not ProdOrderComponent.Get("Production Order Status"::Released, TransferReceiptLine."Prod. Order No.", TransferReceiptLine."Prod. Order Line No.", TransferReceiptLine."Prod. Order Comp. Line No.") then
            exit;
        ItemLedgerEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Expiration Date", "Lot No.", "Serial No.");
        ItemLedgerEntry.SetRange("Item No.", TransferReceiptLine."Item No.");
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetRange("Document No.", TransferReceiptLine."Document No.");
        ItemLedgerEntry.SetRange("Document Line No.", TransferReceiptLine."Line No.");
        ItemLedgerEntry.SetRange("Location Code", TransferReceiptLine."Transfer-to Code");
        ItemLedgerEntry.SetLoadFields("Serial No.", "Lot No.", "Package No.", "Variant Code", "Location Code", "Qty. per Unit of Measure", Quantity);
        if not ItemLedgerEntry.IsEmpty() then begin
            ItemLedgerEntry.FindSet();
            repeat
                if (ItemLedgerEntry."Lot No." <> '') or (ItemLedgerEntry."Serial No." <> '') or (ItemLedgerEntry."Package No." <> '') then begin
                    if not TempTrackingSpecification.IsEmpty() then
                        TempTrackingSpecification.DeleteAll();
                    TempTrackingSpecification."Source Type" := Database::"Item Ledger Entry";
                    TempTrackingSpecification."Source Subtype" := 0;
                    TempTrackingSpecification."Source ID" := '';
                    TempTrackingSpecification."Source Batch Name" := '';
                    TempTrackingSpecification."Source Prod. Order Line" := 0;
                    TempTrackingSpecification."Source Ref. No." := ItemLedgerEntry."Entry No.";
                    TempTrackingSpecification."Variant Code" := ItemLedgerEntry."Variant Code";
                    TempTrackingSpecification."Location Code" := ItemLedgerEntry."Location Code";
                    TempTrackingSpecification."Serial No." := ItemLedgerEntry."Serial No.";
                    TempTrackingSpecification."Lot No." := ItemLedgerEntry."Lot No.";
                    TempTrackingSpecification."Package No." := ItemLedgerEntry."Package No.";
                    TempTrackingSpecification."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
                    TempTrackingSpecification.Insert();

                    ProdOrderCompReserve.CreateReservationSetFrom(TempTrackingSpecification);
                    TempForReservationEntry.CopyTrackingFromSpec(TempTrackingSpecification);
                    ProdOrderCompReserve.CreateReservation(
                      ProdOrderComponent,
                      ProdOrderComponent.Description,
                      ProdOrderComponent."Due Date",
                      ItemLedgerEntry.Quantity,
                      ItemLedgerEntry.Quantity * ItemLedgerEntry."Qty. per Unit of Measure",
                      TempForReservationEntry);
                end;
            until ItemLedgerEntry.Next() = 0;
        end;
    end;

    procedure UpdateLocationCodeInProdOrderCompAfterDeleteTransferLine(var TransferLine: Record "Transfer Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if ProdOrderComponent.Get("Production Order Status"::Released, TransferLine."Prod. Order No.", TransferLine."Prod. Order Line No.", TransferLine."Prod. Order Comp. Line No.") then
            if ProdOrderComponent."Orig. Location Code" <> '' then begin
                SubcontractingManagement.ChangeLocation_OnProdOrderComponent(ProdOrderComponent, '', ProdOrderComponent."Orig. Location Code", ProdOrderComponent."Orig. Bin Code");
                ProdOrderComponent."Orig. Location Code" := '';
                ProdOrderComponent."Orig. Bin Code" := '';


                ProdOrderComponent.Modify();
            end;
    end;

    procedure UpdateSubcontractingTypeForPlanningComponent(var PlanningComponent: Record "Planning Component")
    var
        PlanningRoutingLine: Record "Planning Routing Line";
        Vendor: Record Vendor;
        OrigLocationCode, VendorSubcontractingLocationCode : Code[10];
        OrigBinCode: Code[20];
    begin
        if PlanningComponent."Routing Link Code" = '' then
            exit;

        PlanningRoutingLine.SetRange("Worksheet Template Name", PlanningComponent."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", PlanningComponent."Worksheet Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", PlanningComponent."Worksheet Line No.");
        PlanningRoutingLine.SetRange("Routing Link Code", PlanningComponent."Routing Link Code");
        PlanningRoutingLine.SetRange(Type, "Capacity Type"::"Work Center");
        if not PlanningRoutingLine.IsEmpty() then begin
            PlanningRoutingLine.SetLoadFields("No.");
            PlanningRoutingLine.FindFirst();

            if not GetSubcontractor(PlanningRoutingLine."No.", Vendor) then
                Clear(Vendor);
            if PlanningComponent."Subcontracting Type" in ["Subcontracting Type"::InventoryByVendor, "Subcontracting Type"::Purchase] then
                VendorSubcontractingLocationCode := Vendor."Subcontr. Location Code";
            OrigLocationCode := PlanningComponent."Orig. Location Code";
            OrigBinCode := PlanningComponent."Orig. Bin Code";

            ChangeLocation_OnPlanningComponent(PlanningComponent, VendorSubcontractingLocationCode, OrigLocationCode, OrigBinCode);

            PlanningComponent.Modify();
        end;
    end;

    procedure UpdateSubcontractingTypeForProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Vendor: Record Vendor;
        ProdOrderCompFound: Boolean;
        OrigLocationCode, VendorSubcontractingLocationCode : Code[10];
        OrigBinCode: Code[20];
        PurchOrderNo: Code[20];
        PurchOrderExistErr: Label 'The currently selected component %1 is already used in Purchase Order %2. Therefore, it is not permitted to change the %3 field.', Comment = '%1=Item No, %2=Purchase Order No, %3=Field Caption';
    begin
        if ProdOrderComponent."Routing Link Code" = '' then
            exit;

        ProdOrderLine.SetLoadFields("Routing Reference No.", "Routing No.");
        ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");

        ProdOrderRoutingLine.SetRange(Status, ProdOrderComponent.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing Link Code", ProdOrderComponent."Routing Link Code");
        ProdOrderRoutingLine.SetLoadFields("Prod. Order No.", Type, "No.");
        if ProdOrderRoutingLine.FindFirst() then begin
            PurchaseLine.SetRange("Document Type", "Purchase Document Type"::Order);
            PurchaseLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
            PurchaseLine.SetLoadFields(SystemId);
            if PurchaseLine.FindSet() then
                repeat
                    if PurchOrderNo <> PurchaseLine."Document No." then begin
                        PurchOrderNo := PurchaseLine."Document No.";
                        PurchaseLine2.SetRange("Document Type", PurchaseLine."Document Type");
                        PurchaseLine2.SetRange("Document No.", PurchaseLine."Document No.");
                        PurchaseLine2.SetRange(Type, "Purchase Line Type"::Item);
                        PurchaseLine2.SetRange("No.", ProdOrderComponent."Item No.");
                        ProdOrderCompFound := not PurchaseLine2.IsEmpty();
                    end;
                until (PurchaseLine.Next() = 0) or ProdOrderCompFound;
            if ProdOrderCompFound then
                Error(PurchOrderExistErr, ProdOrderComponent."Item No.", PurchOrderNo, ProdOrderComponent.FieldCaption(ProdOrderComponent."Subcontracting Type"));

            if ProdOrderRoutingLine.Type = "Capacity Type"::"Work Center" then begin
                if not GetSubcontractor(ProdOrderRoutingLine."No.", Vendor) then
                    Clear(Vendor);

                VendorSubcontractingLocationCode := Vendor."Subcontr. Location Code";
                if ProdOrderComponent."Subcontracting Type" in ["Subcontracting Type"::InventoryByVendor, "Subcontracting Type"::Purchase] = false then
                    Clear(VendorSubcontractingLocationCode);
                OrigLocationCode := ProdOrderComponent."Orig. Location Code";
                OrigBinCode := ProdOrderComponent."Orig. Bin Code";

                ChangeLocation_OnProdOrderComponent(ProdOrderComponent, VendorSubcontractingLocationCode, OrigLocationCode, OrigBinCode);

                ProdOrderComponent.Modify();
            end;
        end;
    end;

    procedure UpdLinkedComponents(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ShowMsg: Boolean)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        Vendor: Record Vendor;
        ConfirmManagement: Codeunit "Confirm Management";
        Subcontracting: Boolean;
        OrigLocationCode, VendorSubcontractingLocationCode : Code[10];
        OrigBinCode: Code[20];
        RoutingLinkUpdConfQst: Label 'If you change the Work Center, you will also change the default location for components with Routing Link Code=%1.\Do you want to continue anyway?', Comment = '%1=Routing Link Code';
        SuccessfullyUpdatedMsg: Label 'Successfully updated.';
        UpdateIsCancelledErr: Label 'The update is canceled.';
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        if ProdOrderComponent.FindSet() then begin
            if ProdOrderRoutingLine.Type = "Capacity Type"::"Work Center" then
                Subcontracting := GetSubcontractor(ProdOrderRoutingLine."No.", Vendor);

            if Subcontracting then begin
                VendorSubcontractingLocationCode := Vendor."Subcontr. Location Code";
                if ShowMsg then
                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(RoutingLinkUpdConfQst, ProdOrderRoutingLine."Routing Link Code"), true) then
                        Error(UpdateIsCancelledErr);
                repeat
                    if ProdOrderComponent."Subcontracting Type" in ["Subcontracting Type"::InventoryByVendor, "Subcontracting Type"::Purchase] = false then
                        Clear(VendorSubcontractingLocationCode);
                    OrigLocationCode := ProdOrderComponent."Orig. Location Code";
                    OrigBinCode := ProdOrderComponent."Orig. Bin Code";

                    ChangeLocation_OnProdOrderComponent(ProdOrderComponent, VendorSubcontractingLocationCode, OrigLocationCode, OrigBinCode);

                    ProdOrderComponent.Modify();
                until ProdOrderComponent.Next() = 0;

                if ShowMsg then
                    Message(SuccessfullyUpdatedMsg);
            end;
        end;
    end;

    /// <summary>
    /// Gets the transfer-from location code based on the setup field "Component at Location".
    /// The location code is retrieved from the purchase line, company information, or manufacturing setup.
    /// </summary>
    /// <returns>The transfer-from location code.</returns>
    procedure GetComponentsLocationCode(PurchaseLine: Record "Purchase Line"): Code[10]
    var
        CompanyInformation: Record "Company Information";
        ManufacturingSetup: Record "Manufacturing Setup";
        ComponentsLocationCode: Code[10];
    begin
        GetSubmanagementSetup();
        SubcManagementSetup.TestField("Component at Location");

        case SubcManagementSetup."Component at Location" of
            "Components at Location"::Purchase:
                begin
                    PurchaseLine.TestField("Location Code");
                    ComponentsLocationCode := PurchaseLine."Location Code";
                end;
            "Components at Location"::Company:
                begin
                    CompanyInformation.SetLoadFields("Location Code");
                    CompanyInformation.Get();
                    CompanyInformation.TestField("Location Code");
                    ComponentsLocationCode := CompanyInformation."Location Code";
                end;
            "Components at Location"::Manufacturing:
                begin
                    ManufacturingSetup.SetLoadFields("Components at Location");
                    ManufacturingSetup.Get();
                    ManufacturingSetup.TestField("Components at Location");
                    ComponentsLocationCode := ManufacturingSetup."Components at Location";
                end;
        end;

        exit(ComponentsLocationCode);
    end;

    local procedure GetSubmanagementSetup()
    begin
        if HasSubManagementSetup then
            exit;
        if SubcManagementSetup.Get() then
            HasSubManagementSetup := true;
    end;

    local procedure IsSubcontracting(WorkCenterNo: Code[20]): Boolean
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetLoadFields("Subcontractor No.");
        if WorkCenter.Get(WorkCenterNo) then
            exit(WorkCenter."Subcontractor No." <> '')
    end;

    [InternalEvent(false, false)]
    local procedure OnBeforeGetSubcontractor(WorkCenterNo: Code[20]; var Vendor: Record Vendor; var HasSubcontractor: Boolean; var IsHandled: Boolean)
    begin
    end;
}
