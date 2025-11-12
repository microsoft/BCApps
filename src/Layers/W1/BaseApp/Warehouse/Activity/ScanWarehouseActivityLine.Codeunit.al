// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
codeunit 7388 "Scan Warehouse Activity Line"
{
    var
        BarcodeDoesNotMatchErr: Label 'Scanned barcode does not match with the defined %1 in the line.', Comment = '%1 - Serial No. or Lot No. or Package No. or GTIN/Item Reference';
        BarcodeNotFoundErr: Label 'Barcode not found. Please try again or enter the value manually.';


    internal procedure CheckAndSetBarcode(var WarehouseActivityLine: Record "Warehouse Activity Line"; Barcode: Text; var NeedsRefresh: Boolean; var AllLinesAreDone: Boolean)
    begin
        if Barcode = '' then
            exit;

        if not ValidateBarcode(WarehouseActivityLine, Barcode) then
            Error(BarcodeNotFoundErr)
        else
            if WarehouseActivityLine."Qty. Outstanding" = WarehouseActivityLine."Qty. to Handle" then
                if not GetNextUnfullfilledLine(WarehouseActivityLine) then
                    AllLinesAreDone := true
                else
                    NeedsRefresh := true;
    end;

    internal procedure ValidateBarcode(var WarehouseActivityLine: Record "Warehouse Activity Line"; Barcode: Text): Boolean
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        xWarehouseActivityLine: Record "Warehouse Activity Line";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        // If value matches GTIN/Item Reference associated with item/variant or SN/Lot/Package defined in the Pick line,
        // Then update Qty to Handle (+1) and set appropriate fields.

        // Is GTIN number
        if IsGTIN(WarehouseActivityLine, Barcode) then begin
            WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine."Qty. to Handle" + 1);
            WarehouseActivityLine.Modify(true);
            exit(true);
        end;

        // Is Item reference number
        if IsItemReference(WarehouseActivityLine, Barcode) then begin
            WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine."Qty. to Handle" + 1);
            WarehouseActivityLine.Modify(true);
            exit(true);
        end;

        ItemTrackingManagement.GetWhseItemTrkgSetup(WarehouseActivityLine."Item No.", ItemTrackingSetup);
        // Is Serial No.
        if IsSerialNo(WarehouseActivityLine, ItemTrackingSetup, Barcode) then begin
            xWarehouseActivityLine := WarehouseActivityLine;

            // If Serial No. is already defined in the line
            if WarehouseActivityLine."Serial No." <> '' then begin
                if WarehouseActivityLine."Serial No." <> Barcode then //  and not same as the scanned barcode, then throw error.
                    Error(BarcodeDoesNotMatchErr, WarehouseActivityLine.FieldCaption("Serial No."));
            end else // If Serial No. is not defined in the line, then validate it.
                WarehouseActivityLine.Validate("Serial No.", Barcode);

            WarehouseActivityLine.CopyItemTrackingToRelatedLine(xWarehouseActivityLine, WarehouseActivityLine.FieldNo("Serial No."));
            if WarehouseActivityLine."Qty. to Handle" < WarehouseActivityLine."Qty. Outstanding" then
                WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine."Qty. to Handle" + 1);
            WarehouseActivityLine.Modify(true);
            exit(true);
        end;

        // Is Lot No.
        if IsLotNo(WarehouseActivityLine, ItemTrackingSetup, Barcode) then begin
            xWarehouseActivityLine := WarehouseActivityLine;

            // If Lot No. is already defined in the line
            if WarehouseActivityLine."Lot No." <> '' then begin
                if WarehouseActivityLine."Lot No." <> Barcode then //  and not same as the scanned barcode, then throw error.
                    Error(BarcodeDoesNotMatchErr, WarehouseActivityLine.FieldCaption("Lot No."));
            end else
                WarehouseActivityLine.Validate("Lot No.", Barcode);

            WarehouseActivityLine.CopyItemTrackingToRelatedLine(xWarehouseActivityLine, WarehouseActivityLine.FieldNo("Lot No."));
            if WarehouseActivityLine."Qty. to Handle" < WarehouseActivityLine."Qty. Outstanding" then
                WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine."Qty. to Handle" + 1);
            WarehouseActivityLine.Modify(true);
            exit(true);
        end;

        // Is Package No.
        if IsPackageNo(WarehouseActivityLine, ItemTrackingSetup, Barcode) then begin
            xWarehouseActivityLine := WarehouseActivityLine;

            // If Package No. is already defined in the line
            if WarehouseActivityLine."Package No." <> '' then begin
                if WarehouseActivityLine."Package No." <> Barcode then //  and not same as the scanned barcode, then throw error.
                    Error(BarcodeDoesNotMatchErr, WarehouseActivityLine.FieldCaption("Package No."));
            end else
                WarehouseActivityLine.Validate("Package No.", Barcode);
            WarehouseActivityLine.CopyItemTrackingToRelatedLine(xWarehouseActivityLine, WarehouseActivityLine.FieldNo("Package No."));
            if WarehouseActivityLine."Qty. to Handle" < WarehouseActivityLine."Qty. Outstanding" then
                WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine."Qty. to Handle" + 1);
            WarehouseActivityLine.Modify(true);

            exit(true);
        end;
    end;

    internal procedure UnfullfilledLineExists(var WarehouseActivityLine: Record "Warehouse Activity Line"): Boolean
    var
        RemainingWarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        RemainingWarehouseActivityLine.CopyFilters(WarehouseActivityLine);
        RemainingWarehouseActivityLine.CalcSums("Qty. Outstanding", "Qty. to Handle");
        if RemainingWarehouseActivityLine."Qty. Outstanding" <> RemainingWarehouseActivityLine."Qty. to Handle" then
            exit(true);
    end;

    local procedure IsGTIN(var WarehouseActivityLine: Record "Warehouse Activity Line"; Barcode: Text): Boolean
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", WarehouseActivityLine."Item No.");
        Item.SetRange(GTIN, Barcode);
        exit(not Item.IsEmpty());
    end;

    local procedure IsItemReference(var WarehouseActivityLine: Record "Warehouse Activity Line"; Barcode: Text): Boolean
    var
        ItemReference: Record "Item Reference";
    begin
        ItemReference.SetRange("Reference No.", Barcode);
        ItemReference.SetRange("Item No.", WarehouseActivityLine."Item No.");
        ItemReference.SetRange("Variant Code", WarehouseActivityLine."Variant Code");
        ItemReference.SetRange("Unit of Measure", WarehouseActivityLine."Unit of Measure Code");
        exit(not ItemReference.IsEmpty());
    end;

    local procedure IsSerialNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemTrackingSetup: Record "Item Tracking Setup"; Barcode: Text): Boolean
    var
        LotNosByBinCode: Query "Lot Numbers by Bin";
    begin
        if ItemTrackingSetup."Serial No. Required" then begin
            LotNosByBinCode.SetRange(Item_No, WarehouseActivityLine."Item No.");
            LotNosByBinCode.SetRange(Variant_Code, WarehouseActivityLine."Variant Code");
            LotNosByBinCode.SetRange(Location_Code, WarehouseActivityLine."Location Code");
            LotNosByBinCode.SetRange(Serial_No, Barcode);
            LotNosByBinCode.Open();
            exit(LotNosByBinCode.Read());
        end;
    end;

    local procedure IsLotNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemTrackingSetup: Record "Item Tracking Setup"; Barcode: Text): Boolean
    var
        LotNosByBinCode: Query "Lot Numbers by Bin";
    begin
        if ItemTrackingSetup."Lot No. Required" then begin
            LotNosByBinCode.SetRange(Item_No, WarehouseActivityLine."Item No.");
            LotNosByBinCode.SetRange(Variant_Code, WarehouseActivityLine."Variant Code");
            LotNosByBinCode.SetRange(Location_Code, WarehouseActivityLine."Location Code");
            LotNosByBinCode.SetRange(Lot_No, Barcode);
            LotNosByBinCode.Open();
            exit(LotNosByBinCode.Read());
        end;
    end;

    local procedure IsPackageNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemTrackingSetup: Record "Item Tracking Setup"; Barcode: Text): Boolean
    var
        LotNosByBinCode: Query "Lot Numbers by Bin";
    begin
        if ItemTrackingSetup."Package No. Required" then begin
            LotNosByBinCode.SetRange(Item_No, WarehouseActivityLine."Item No.");
            LotNosByBinCode.SetRange(Variant_Code, WarehouseActivityLine."Variant Code");
            LotNosByBinCode.SetRange(Location_Code, WarehouseActivityLine."Location Code");
            LotNosByBinCode.SetRange(Package_No, Barcode);
            LotNosByBinCode.Open();
            exit(LotNosByBinCode.Read());
        end;
    end;

    local procedure GetNextUnfullfilledLine(var WarehouseActivityLine: Record "Warehouse Activity Line"): Boolean
    begin
        if not UnfullfilledLineExists(WarehouseActivityLine) then
            exit(false);

        while WarehouseActivityLine.Next() <> 0 do // Scan till end of the record set
            if WarehouseActivityLine."Qty. Outstanding" <> WarehouseActivityLine."Qty. to Handle" then
                exit(true);

        // Did not find any unfulfilled line from the point it started to check to the end of the set
        if WarehouseActivityLine.FindSet() then begin
            if WarehouseActivityLine."Qty. Outstanding" <> WarehouseActivityLine."Qty. to Handle" then
                exit(true);

            // Start the search from top again
            while WarehouseActivityLine.Next() <> 0 do // Scan till end of the record set
                if WarehouseActivityLine."Qty. Outstanding" <> WarehouseActivityLine."Qty. to Handle" then
                    exit(true);
        end;
        exit(false);
    end;
}