// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Assembly.History;
using Microsoft.Inventory.Item;
using Microsoft.Sales.History;

codeunit 935 "Asm. Item Tracking Mgt."
{
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnGetItemTrackingSetupOnSetSerialNoRequired', '', false, false)]
    local procedure OnGetItemTrackingSetupOnSetSerialNoRequired(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code"; EntryType: Enum "Item Ledger Entry Type"; Inbound: Boolean)
    begin
        case EntryType of
            EntryType::"Assembly Consumption", EntryType::"Assembly Output":
                if Inbound then
                    ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Assembly Inbound Tracking"
                else
                    ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Assembly Outbound Tracking";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnGetItemTrackingSetupOnSetLotNoRequired', '', false, false)]
    local procedure OnGetItemTrackingSetupOnSetLotNoRequired(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code"; EntryType: Enum "Item Ledger Entry Type"; Inbound: Boolean)
    begin
        case EntryType of
            EntryType::"Assembly Consumption", EntryType::"Assembly Output":
                if Inbound then
                    ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Assembly Inbound Tracking"
                else
                    ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Assembly Outbound Tracking";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnGetItemTrackingSetupOnSetPackageNoRequired', '', false, false)]
    local procedure OnGetItemTrackingSetupOnSetPackageNoRequired(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code"; EntryType: Enum "Item Ledger Entry Type"; Inbound: Boolean)
    begin
        case EntryType of
            EntryType::"Assembly Consumption", EntryType::"Assembly Output":
                if Inbound then
                    ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Assembly Inb. Tracking"
                else
                    ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Assembly Out. Tracking";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnAfterIsResEntryReservedAgainstInventory', '', false, false)]
    local procedure OnAfterIsResEntryReservedAgainstInventory(ReservationEntry: Record "Reservation Entry"; var Result: Boolean)
    begin
        Result := IsResEntryReservedAgainstATO(ReservationEntry);
    end;

    local procedure IsResEntryReservedAgainstATO(ReservationEntry: Record "Reservation Entry"): Boolean
    var
        ReservationEntry2: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
        AssembleToOrderLink: Record "Assemble-to-Order Link";
    begin
        if (ReservationEntry."Source Type" <> Database::"Sales Line") or
           (ReservationEntry."Source Subtype" <> SalesLine."Document Type"::Order.AsInteger()) or
           (not SalesLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.")) or
           (not AssembleToOrderLink.AsmExistsForSalesLine(SalesLine))
        then
            exit(false);

        ReservationEntry2.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
        if (ReservationEntry2."Source Type" <> Database::"Assembly Header") or
           (ReservationEntry2."Source Subtype" <> AssembleToOrderLink."Assembly Document Type".AsInteger()) or
           (ReservationEntry2."Source ID" <> AssembleToOrderLink."Assembly Document No.")
        then
            exit(false);

        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnSynchronizeWhseActivItemTrkgAssembly', '', false, false)]
    local procedure OnSynchronizeWhseActivItemTrkgAssembly(var WhseActivLine: Record "Warehouse Activity Line"; var ToRowID: Text[250])
    var
        ATOSalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
    begin
        ATOSalesLine.Get(WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Line No.");
        ATOSalesLine.AsmToOrderExists(AsmHeader);
        ToRowID :=
            ItemTrackingMgt.ComposeRowID(Database::"Assembly Header", AsmHeader."Document Type".AsInteger(), AsmHeader."No.", '', 0, 0);
    end;

    // Item Tracking Code

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Code", 'OnValidateSNSpecificTrackingOnAfterSet', '', false, false)]
    local procedure OnValidateSNSpecificTrackingOnAfterSet(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        ItemTrackingCode."SN Assembly Inbound Tracking" := true;
        ItemTrackingCode."SN Assembly Outbound Tracking" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Code", 'OnValidateLotSpecificTrackingOnAfterSet', '', false, false)]
    local procedure OnValidateLotSpecificTrackingOnAfterSet(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        ItemTrackingCode."Lot Assembly Inbound Tracking" := true;
        ItemTrackingCode."Lot Assembly Outbound Tracking" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Code", 'OnValidatePackageSpecificTrackingOnAfterSet', '', false, false)]
    local procedure OnValidatePackageSpecificTrackingOnAfterSet(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        ItemTrackingCode."Package Assembly Inb. Tracking" := true;
        ItemTrackingCode."Package Assembly Out. Tracking" := true;
    end;

    // Report Carry Out Reservation
    [EventSubscriber(ObjectType::Report, Report::"Carry Out Reservation", 'OnCarryOutReservationOtherDemandType', '', false, false)]
    local procedure OnCarryOutReservationOtherDemandType(var ReservationWkshLine: Record "Reservation Wksh. Line"; DemandType: Enum "Reservation Demand Type")
    begin
        case DemandType of
            DemandType::"Assembly Components":
                ReservationWkshLine.SetRange("Source Type", Database::"Assembly Line");
        end;
    end;

    // Codeunit "Item Tracing Mgt."

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracing Mgt.", 'OnInsertRecordOnBeforeSetDescription', '', false, false)]
    local procedure OnInsertRecordOnBeforeSetDescription(var TempTrackEntry: Record "Item Tracing Buffer"; var RecRef: RecordRef; var Description2: Text[100])
    begin
        if RecRef.Get(TempTrackEntry."Record Identifier") then
            case RecRef.Number of
                Database::"Posted Assembly Header":
                    Description2 := StrSubstNo('%1 %2', TempTrackEntry."Entry Type", TempTrackEntry."Document No.");
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracing Mgt.", 'OnAfterSetRecordID', '', false, false)]
    local procedure OnAfterSetRecordID(var TrackingEntry: Record "Item Tracing Buffer"; RecRef: RecordRef)
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        case TrackingEntry."Entry Type" of
            TrackingEntry."Entry Type"::"Assembly Consumption",
            TrackingEntry."Entry Type"::"Assembly Output":
                if PostedAssemblyHeader.Get(TrackingEntry."Document No.") then begin
                    RecRef.GetTable(PostedAssemblyHeader);
                    TrackingEntry."Record Identifier" := RecRef.RecordId;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracing Mgt.", 'OnShowDocument', '', false, false)]
    local procedure OnShowDocument(RecRef: RecordRef; RecID: RecordId)
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        case RecID.TableNo of
            Database::"Posted Assembly Line",
            Database::"Posted Assembly Header":
                begin
                    RecRef.SetTable(PostedAssemblyHeader);
                    PAGE.RunModal(PAGE::"Posted Assembly Order", PostedAssemblyHeader);
                end;
        end;
    end;

    // Page Item Tracking Lines

    [EventSubscriber(ObjectType::Page, Page::"Item Tracking Lines", 'OnSetSourceSpecOnCollectTrackingData', '', false, false)]
    local procedure OnSetSourceSpecOnCollectTrackingData(var TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary; ExcludePostedEntries: Boolean; CurrentSignFactor: Integer; var SourceQuantity: Decimal; var sender: Page "Item Tracking Lines")
    begin
        if not ExcludePostedEntries then
            if (TrackingSpecification."Source Type" = Database::"Assembly Line") or
               (TrackingSpecification."Source Type" = Database::"Assembly Header")
            then
                CollectPostedAssemblyEntries(TrackingSpecification, TempTrackingSpecification, CurrentSignFactor, SourceQuantity, sender);
    end;

    local procedure CollectPostedAssemblyEntries(TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary; CurrentSignFactor: Integer; SourceQuantity: Decimal; var sender: Page "Item Tracking Lines")
    var
        ItemEntryRelation: Record "Item Entry Relation";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CurrentQtyBase: Decimal;
        MaxQtyBase: Decimal;
    begin
        // Used for collecting information about posted Assembly Lines from the created Item Ledger Entries.
        if (TrackingSpecification."Source Type" <> Database::"Assembly Line") and
           (TrackingSpecification."Source Type" <> Database::"Assembly Header")
        then
            exit;

        TempTrackingSpecification.CalcSums("Quantity (Base)");
        CurrentQtyBase := TempTrackingSpecification."Quantity (Base)";
        MaxQtyBase := CurrentSignFactor * SourceQuantity;
        if CurrentQtyBase = MaxQtyBase then
            exit;

        ItemEntryRelation.SetCurrentKey("Order No.", "Order Line No.");
        ItemEntryRelation.SetRange("Order No.", TrackingSpecification."Source ID");
        ItemEntryRelation.SetRange("Order Line No.", TrackingSpecification."Source Ref. No.");
        if TrackingSpecification."Source Type" = Database::"Assembly Line" then
            ItemEntryRelation.SetRange("Source Type", Database::"Posted Assembly Line")
        else
            ItemEntryRelation.SetRange("Source Type", Database::"Posted Assembly Header");

        if ItemEntryRelation.Find('-') then
            repeat
                ItemLedgerEntry.Get(ItemEntryRelation."Item Entry No.");
                TempTrackingSpecification := TrackingSpecification;
                TempTrackingSpecification."Entry No." := ItemLedgerEntry."Entry No.";
                TempTrackingSpecification."Item No." := ItemLedgerEntry."Item No.";
                TempTrackingSpecification.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
                TempTrackingSpecification."Quantity (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Handled (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Invoiced (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
                TempTrackingSpecification.InitQtyToShip();

                CurrentQtyBase += TempTrackingSpecification."Quantity (Base)";

                sender.RunOnBeforeCollectTempTrackingSpecificationInsert(TempTrackingSpecification, ItemLedgerEntry, TrackingSpecification);
                TempTrackingSpecification.Insert();
            until ItemEntryRelation.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Tracking Lines", 'OnCheckItemTrackingLineIsBoundForBarcodeScanning', '', false, false)]
    local procedure OnCheckItemTrackingLineISBoundForBarcodeScanning(var TrackingSpecification: Record "Tracking Specification"; var Result: Boolean; IsHandled: Boolean)
    begin
        if TrackingSpecification."Source Type" = Database::"Assembly Line" then begin
            if TrackingSpecification."Source Subtype" in [Enum::"Assembly Document Type"::Order.AsInteger(), Enum::"Assembly Document Type"::Quote.AsInteger(), Enum::"Assembly Document Type"::"Blanket Order".AsInteger()] then
                Result := TrackingSpecification."Quantity (Base)" < 0
            else
                Result := false;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Doc. Management", 'OnRetrieveTrackingSalesShipmentForAssembly', '', false, false)]
    local procedure OnRetrieveTrackingSalesShipmentForAssembly(SalesShipmentLine: Record "Sales Shipment Line"; var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; sender: Codeunit "Item Tracking Doc. Management")
    var
        PostedAsmHeader: Record "Posted Assembly Header";
        PostedAsmLine: Record "Posted Assembly Line";
        Descr: Text[100];
    begin
        if SalesShipmentLine.AsmToShipmentExists(PostedAsmHeader) then begin
            PostedAsmLine.SetRange("Document No.", PostedAsmHeader."No.");
            if PostedAsmLine.FindSet() then
                repeat
                    Descr := PostedAsmLine.Description;
                    sender.FindShptRcptEntries(
                        TempTrackingSpecBuffer,
                        Database::"Posted Assembly Line", 0, PostedAsmLine."Document No.", '', 0, PostedAsmLine."Line No.", Descr);
                until PostedAsmLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Doc. Management", 'OnAfterTableSignFactor', '', false, false)]
    local procedure OnAfterTableSignFactor(TableNo: Integer; var Sign: Integer);
    begin
        if TableNo = Database::"Posted Assembly Line" then
            Sign := -1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", OnCheckIsSNSpecificTracking, '', false, false)]
    local procedure OnCheckIsSNSpecificTracking(ItemTrackingCode: Record "Item Tracking Code"; var SNSepecificTracking: Boolean)
    begin
        if SNSepecificTracking then
            exit;

        SNSepecificTracking := ItemTrackingCode."SN Assembly Inbound Tracking" or ItemTrackingCode."SN Assembly Outbound Tracking";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", OnCheckIsLotSpecificTracking, '', false, false)]
    local procedure OnCheckIsLotSpecificTracking(ItemTrackingCode: Record "Item Tracking Code"; var LotSepecificTracking: Boolean)
    begin
        if LotSepecificTracking then
            exit;

        LotSepecificTracking := ItemTrackingCode."Lot Assembly Inbound Tracking" or ItemTrackingCode."Lot Assembly Outbound Tracking";
    end;
}