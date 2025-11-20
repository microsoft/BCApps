// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Worksheet;
using System.Utilities;

report 5757 "Items with Negative Inventory"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/ItemswithNegativeInventory.rdlc';
    Caption = 'Items with Negative Inventory';
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Output; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; CompanyProperty.DisplayName())
            {
            }
            column(LocationCode; StrSubstNo('%1: %2', TempItemLedgerEntry.FieldCaption("Location Code"), LocationToCheckCode))
            {
            }
            column(ItemLedgEntryBufferItemNo; TempItemLedgerEntry."Item No.")
            {
            }
            column(ItemLedgEntryBufferRemainQty; TempItemLedgerEntry."Remaining Quantity")
            {
                DecimalPlaces = 0 : 5;
            }
            column(ItemLedgEntryBufferPackageNo; TempItemLedgerEntry."Package No.")
            {
            }
            column(ItemLedgEntryBufferLotNo; TempItemLedgerEntry."Lot No.")
            {
            }
            column(ItemLedgEntryBufferSerialNo; TempItemLedgerEntry."Serial No.")
            {
            }
            column(ItemLedgEntryBufferUOMCode; TempItemLedgerEntry."Unit of Measure Code")
            {
            }
            column(ItemLedgEntryBufferDesc; TempItemLedgerEntry.Description)
            {
            }
            column(ItemLedgEntryBufferVariantCode; TempItemLedgerEntry."Variant Code")
            {
            }
            column(Check_on_Negative_InventoryCaption; Items_with_Negative_InventoryLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(ItemLedgEntryBufferRemainQtyCaption; ItemLedgerEntryBufferRemainQtyCaption)
            {
            }
            column(ItemLedgEntryBufferPackageNoCaption; ItemLedgerEntryBufferPackageNoCaption)
            {
            }
            column(ItemLedgEntryBufferLotNoCaption; ItemLedgerEntryBufferLotNoCaption)
            {
            }
            column(ItemLedgEntryBufferSerialNoCaption; ItemLedgerEntryBufferSerialNoCaption)
            {
            }
            column(ItemLedgEntryBufferUOMCodeCaption; ItemLedgerEntryBufferUOMCodeCaption)
            {
            }
            column(ItemLedgEntryBufferDescCaption; ItemLedgerEntryBufferDescCaption)
            {
            }
            column(ItemLedgEntryBufferVariantCodeCaption; ItemLedgerEntryBufferVariantCodeCaption)
            {
            }
            column(ItemLedgEntryBufferItemNoCaption; ItemLedgerEntryBufferItemNoCaption)
            {
            }

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
                ItemVariant: Record "Item Variant";
            begin
                if TempItemLedgerEntryCounter = 0 then
                    TempItemLedgerEntry.Description := NoNegativeInventoryLbl
                else begin
                    if Number = 1 then
                        TempItemLedgerEntry.Find('-')
                    else
                        TempItemLedgerEntry.Next();

                    if TempItemLedgerEntry.Description = '' then
                        if TempItemLedgerEntry."Variant Code" <> '' then begin
                            ItemVariant.SetLoadFields(Description);
                            ItemVariant.Get(TempItemLedgerEntry."Item No.", TempItemLedgerEntry."Variant Code");
                            TempItemLedgerEntry.Description := ItemVariant.Description;
                        end else begin
                            Item.SetLoadFields(Description);
                            Item.Get(TempItemLedgerEntry."Item No.");
                            TempItemLedgerEntry.Description := Item.Description;
                        end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                TempItemLedgerEntry.SetCurrentKey("Item No.", "Location Code", Open, "Variant Code", "Unit of Measure Code", "Lot No.", "Package No.", "Serial No.");

                TempItemLedgerEntryCounter := TempItemLedgerEntry.Count();
                if TempItemLedgerEntryCounter = 0 then
                    SetRange(Number, 1)
                else
                    SetRange(Number, 1, TempItemLedgerEntryCounter);

                ItemLedgerEntryBufferRemainQtyCaption := TempItemLedgerEntry.FieldCaption(Quantity);
                ItemLedgerEntryBufferLotNoCaption := TempItemLedgerEntry.FieldCaption("Lot No.");
                ItemLedgerEntryBufferPackageNoCaption := TempItemLedgerEntry.FieldCaption("Package No.");
                ItemLedgerEntryBufferSerialNoCaption := TempItemLedgerEntry.FieldCaption("Serial No.");
                ItemLedgerEntryBufferUOMCodeCaption := TempItemLedgerEntry.FieldCaption("Unit of Measure Code");
                ItemLedgerEntryBufferDescCaption := TempItemLedgerEntry.FieldCaption("Description");
                ItemLedgerEntryBufferVariantCodeCaption := TempItemLedgerEntry.FieldCaption("Variant Code");
                ItemLedgerEntryBufferItemNoCaption := TempItemLedgerEntry.FieldCaption("Item No.");
            end;
        }
        dataitem(ErrorLoop; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(ErrorTextNumber; ErrorText[Number])
            {
            }
            column(ErrorTextNumberCaption; ErrorTextNumberCaptionLbl)
            {
            }

            trigger OnPostDataItem()
            begin
                ErrorCounter := 0;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, ErrorCounter);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(LocationCode; LocationToCheckCode)
                    {
                        ApplicationArea = Location;
                        Caption = 'Location Code';
                        ShowMandatory = true;
                        ToolTip = 'Specifies the location for items with negative inventory.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            Location: Record Location;
                        begin
                            if LocationToCheckCode <> '' then
                                Location.Code := LocationToCheckCode;
                            if Page.RunModal(0, Location) = Action::LookupOK then
                                LocationToCheckCode := Location.Code;
                        end;

                        trigger OnValidate()
                        var
                            Location: Record Location;
                        begin
                            Location.SetLoadFields(Code);
                            Location.Get(LocationToCheckCode);
                        end;
                    }
                }
            }
        }
    }

    trigger OnPreReport()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        GroupedItemLedgerEntries: Query "Grouped Item Ledger Entries";
        LastItemNoUsed: Code[20];
    begin
        if LocationToCheckCode = '' then
            Error(NoLocationCodeErr);

        Window.Open(StrSubstNo(ProcessingTxt, ItemLedgerEntry.FieldCaption("Location Code"), LocationToCheckCode) + ItemNoInProgressTxt);
        LastItemNoUsed := '';

        GroupedItemLedgerEntries.SetRange(Location_Code, LocationToCheckCode);
        GroupedItemLedgerEntries.Open();
        while GroupedItemLedgerEntries.Read() do begin
            if LastItemNoUsed <> GroupedItemLedgerEntries.Item_No then begin
                Window.Update(100, GroupedItemLedgerEntries.Item_No);
                LastItemNoUsed := GroupedItemLedgerEntries.Item_No;
            end;

            if GroupedItemLedgerEntries.Remaining_Quantity < 0 then begin
                ItemLedgerEntry.SetCurrentKey("Item No.", "Location Code", Open, "Variant Code", "Unit of Measure Code", "Lot No.", "Package No.", "Serial No.");
                ItemLedgerEntry.SetRange("Location Code", GroupedItemLedgerEntries.Location_Code);
                ItemLedgerEntry.SetRange(Open, true);
                ItemLedgerEntry.SetFilter("Item No.", GroupedItemLedgerEntries.Item_No);
                ItemLedgerEntry.SetFilter("Variant Code", GroupedItemLedgerEntries.Variant_Code);
                ItemLedgerEntry.SetFilter("Unit of Measure Code", GroupedItemLedgerEntries.Unit_of_Measure_Code);
                ItemLedgerEntry.SetFilter("Lot No.", GroupedItemLedgerEntries.Lot_No_);
                ItemLedgerEntry.SetFilter("Package No.", GroupedItemLedgerEntries.Package_No_);
                ItemLedgerEntry.SetFilter("Serial No.", GroupedItemLedgerEntries.Serial_No_);
                if ItemLedgerEntry.FindFirst() then begin
                    TempItemLedgerEntry := ItemLedgerEntry;
                    TempItemLedgerEntry."Remaining Quantity" := GroupedItemLedgerEntries.Remaining_Quantity;
                    TempItemLedgerEntry.Insert();
                end;
            end;
        end;

        Window.Close();

        CheckForErrors();
    end;

    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        LocationToCheckCode: Code[10];
        Window: Dialog;
        TempItemLedgerEntryCounter: Integer;
        ErrorCounter: Integer;
        ErrorText: array[5] of Text[250];
        ItemLedgerEntryBufferRemainQtyCaption: Text;
        ItemLedgerEntryBufferPackageNoCaption: Text;
        ItemLedgerEntryBufferLotNoCaption: Text;
        ItemLedgerEntryBufferSerialNoCaption: Text;
        ItemLedgerEntryBufferUOMCodeCaption: Text;
        ItemLedgerEntryBufferDescCaption: Text;
        ItemLedgerEntryBufferVariantCodeCaption: Text;
        ItemLedgerEntryBufferItemNoCaption: Text;
        NoLocationCodeErr: Label 'Enter a location code.';
        ProcessingTxt: Label 'Checking %1 %2 for negative inventory...\\', Comment = '%1: Location Code caption, %2: Location Code value';
        ItemNoInProgressTxt: Label 'Processing item number #100##################.', Comment = '#100 - Item No.';
        NoNegativeInventoryLbl: Label 'No negative inventory was found.';
        Items_with_Negative_InventoryLbl: Label 'Items with Negative Inventory';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ErrorTextNumberCaptionLbl: Label 'Error!';
        WarehouseDocumentExistsLbl: Label 'A %1 exists for %2 %3. It must be either posted or deleted before running the Create Whse. Location batch job.', Comment = '%1: Table caption, %2: Location Code caption, %3: Location Code value';
        WarehouseActivityHeaderExistsLbl: Label 'A %1 exists for %2 %3. It must be either registered or deleted before running the Create Whse. Location batch job.', Comment = '%1: Warehouse Activity Type, %2: Location Code caption, %3: Location Code value';
        WhseWorksheetLineExistsLbl: Label 'A %1 exists for %2 %3. It must be deleted before running the Create Whse. Location batch job.', Comment = '%1: Table caption, %2: Location Code caption, %3: Location Code value';

    local procedure CheckForErrors()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        ErrorCounter := 0;
        WarehouseReceiptHeader.SetRange("Location Code", LocationToCheckCode);
        if not WarehouseReceiptHeader.IsEmpty() then
            AddError(
              StrSubstNo(
                WarehouseDocumentExistsLbl,
                WarehouseReceiptHeader.TableCaption(),
                WarehouseReceiptHeader.FieldCaption("Location Code"),
                LocationToCheckCode));

        WarehouseShipmentHeader.SetRange("Location Code", LocationToCheckCode);
        if not WarehouseShipmentHeader.IsEmpty() then
            AddError(
              StrSubstNo(
                WarehouseDocumentExistsLbl,
                WarehouseShipmentHeader.TableCaption(),
                WarehouseShipmentHeader.FieldCaption("Location Code"),
                LocationToCheckCode));

        WarehouseActivityHeader.SetRange("Location Code", LocationToCheckCode);
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Put-away");
        if not WarehouseActivityHeader.IsEmpty() then
            AddError(
              StrSubstNo(
                WarehouseActivityHeaderExistsLbl,
                WarehouseActivityHeader.Type,
                WarehouseActivityHeader.FieldCaption("Location Code"),
                LocationToCheckCode));

        WarehouseActivityHeader.SetRange("Location Code", LocationToCheckCode);
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Pick");
        if not WarehouseActivityHeader.IsEmpty() then
            AddError(
              StrSubstNo(
                WarehouseActivityHeaderExistsLbl,
                WarehouseActivityHeader.Type,
                WarehouseActivityHeader.FieldCaption("Location Code"),
                LocationToCheckCode));

        WhseWorksheetLine.SetRange("Location Code", LocationToCheckCode);
        if not WhseWorksheetLine.IsEmpty() then
            AddError(
              StrSubstNo(
                WhseWorksheetLineExistsLbl,
                WhseWorksheetLine.TableCaption(),
                WhseWorksheetLine.FieldCaption("Location Code"),
                LocationToCheckCode));
    end;

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    procedure InitializeRequest(NewLocCode: Code[10])
    begin
        LocationToCheckCode := NewLocCode;
    end;
}

