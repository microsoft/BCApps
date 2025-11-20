// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;

report 5706 "Create Stockkeeping Unit"
{
    AdditionalSearchTerms = 'create sku';
    ApplicationArea = Warehouse;
    Caption = 'Create Stockkeeping Unit';
    ProcessingOnly = true;
    UsageCategory = Administration;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Inventory Posting Group", "Location Filter", "Variant Filter";

            trigger OnAfterGetRecord()
            var
                ItemVariant: Record "Item Variant";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeItemOnAfterGetRecord(Item, IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                if SaveFilters then begin
                    LocationFilter := GetFilter("Location Filter");
                    VariantFilter := GetFilter("Variant Filter");
                    SaveFilters := false;
                end;
                SetFilter("Location Filter", LocationFilter);
                SetFilter("Variant Filter", VariantFilter);

                Location.SetFilter(Code, GetFilter("Location Filter"));

                OnItemOnAfterGetRecordOnAfterSetLocationFilter(Location, Item);

                if ReplacePreviousSKUs then begin
                    StockkeepingUnit.Reset();
                    StockkeepingUnit.SetRange("Item No.", "No.");
                    if GetFilter("Variant Filter") <> '' then
                        StockkeepingUnit.SetFilter("Variant Code", GetFilter("Variant Filter"));
                    if GetFilter("Location Filter") <> '' then
                        StockkeepingUnit.SetFilter("Location Code", GetFilter("Location Filter"));
                    StockkeepingUnit.DeleteAll();
                end;

                DialogWindow.Update(1, "No.");
                ItemVariant.SetRange("Item No.", "No.");
                ItemVariant.SetFilter(Code, GetFilter("Variant Filter"));
                case true of
                    (SKUCreationMethod = SKUCreationMethod::Location) or
                    ((SKUCreationMethod = SKUCreationMethod::"Location & Variant") and
                     (not ItemVariant.Find('-'))):
                        if Location.Find('-') then
                            repeat
                                DialogWindow.Update(2, Location.Code);
                                SetRange("Location Filter", Location.Code);
                                CreateSKUIfRequired(Item, Location.Code, '');
                            until Location.Next() = 0;
                    (SKUCreationMethod = SKUCreationMethod::Variant) or
                    ((SKUCreationMethod = SKUCreationMethod::"Location & Variant") and
                     (not Location.Find('-'))):
                        if ItemVariant.Find('-') then
                            repeat
                                DialogWindow.Update(3, ItemVariant.Code);
                                SetRange("Variant Filter", ItemVariant.Code);
                                CreateSKUIfRequired(Item, '', ItemVariant.Code);
                            until ItemVariant.Next() = 0;
                    (SKUCreationMethod = SKUCreationMethod::"Location & Variant"):
                        if Location.Find('-') then
                            repeat
                                DialogWindow.Update(2, Location.Code);
                                SetRange("Location Filter", Location.Code);
                                if ItemVariant.Find('-') then
                                    repeat
                                        DialogWindow.Update(3, ItemVariant.Code);
                                        SetRange("Variant Filter", ItemVariant.Code);
                                        CreateSKUIfRequired(Item, Location.Code, ItemVariant.Code);
                                    until ItemVariant.Next() = 0;
                            until Location.Next() = 0;
                end;
            end;

            trigger OnPostDataItem()
            begin
                DialogWindow.Close();
            end;

            trigger OnPreDataItem()
            begin
                OnBeforeItemOnPreDataItem(Item);

                Location.SetRange("Use As In-Transit", false);

                DialogWindow.Open(
                  Text000 +
                  Text001 +
                  Text002);

                SaveFilters := true;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(SKUCreationMethod; SKUCreationMethod)
                    {
                        ApplicationArea = Location;
                        Caption = 'Create Per';
                        ToolTip = 'Specifies if you want to create stockkeeping units per location or per variant or per location combined with variant.';
                    }
                    field(ItemInInventoryOnly; ItemInInventoryOnly)
                    {
                        ApplicationArea = Location;
                        Caption = 'Item In Inventory Only';
                        ToolTip = 'Specifies if you only want the batch job to create stockkeeping units for items that are in your inventory (that is, for items where the value in the Inventory field is above 0).';
                    }
                    field(ReplacePreviousSKUs; ReplacePreviousSKUs)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Replace Previous SKUs';
                        ToolTip = 'Specifies if you want the batch job to replace all previous created stockkeeping units on the items you have included in the batch job.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        DialogWindow: Dialog;
        SaveFilters: Boolean;
        LocationFilter: Code[1024];
        VariantFilter: Code[1024];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Item No.       #1##################\';
        Text001: Label 'Location Code  #2########\';
        Text002: Label 'Variant Code   #3########\';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        Location: Record Location;
        SKUCreationMethod: Enum "SKU Creation Method";
        ItemInInventoryOnly: Boolean;
        ReplacePreviousSKUs: Boolean;

    procedure CreateSKUIfRequired(var Item2: Record Item; LocationCode: Code[10]; VariantCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateSKU(Item2, LocationCode, VariantCode, ItemInInventoryOnly, IsHandled, SKUCreationMethod);
        if IsHandled then
            exit;

        Item2.CalcFields(Inventory);
        if (ItemInInventoryOnly and (Item2.Inventory > 0)) or
           (not ItemInInventoryOnly)
        then
            if not StockkeepingUnit.Get(LocationCode, Item2."No.", VariantCode) then
                CreateSKU(Item2, LocationCode, VariantCode);
    end;


    procedure SetParameters(CreatePerOption: Enum "SKU Creation Method"; NewItemInInventoryOnly: Boolean; NewReplacePreviousSKUs: Boolean)
    begin
        SKUCreationMethod := CreatePerOption;
        ItemInInventoryOnly := NewItemInInventoryOnly;
        ReplacePreviousSKUs := NewReplacePreviousSKUs;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSKU(var Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; ItemInInventoryOnly: Boolean; var IsHandled: Boolean; SKUCreationMethod: Enum "SKU Creation Method")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeStockkeepingUnitInsert(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    begin
    end;

    procedure CreateSKU(var Item2: Record Item; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        StockkeepingUnit.Init();
        StockkeepingUnit."Item No." := Item2."No.";
        StockkeepingUnit."Location Code" := LocationCode;
        StockkeepingUnit."Variant Code" := VariantCode;
        StockkeepingUnit.CopyFromItem(Item2);
        StockkeepingUnit.TransferManufCostsFromItem(Item2);
        StockkeepingUnit."Last Date Modified" := WorkDate();
        StockkeepingUnit."Special Equipment Code" := Item2."Special Equipment Code";
        StockkeepingUnit."Put-away Template Code" := Item2."Put-away Template Code";
        StockkeepingUnit.SetHideValidationDialog(true);
        StockkeepingUnit.Validate("Phys Invt Counting Period Code", Item2."Phys Invt Counting Period Code");
        StockkeepingUnit."Put-away Unit of Measure Code" := Item2."Put-away Unit of Measure Code";
        StockkeepingUnit."Use Cross-Docking" := Item2."Use Cross-Docking";
        OnBeforeStockkeepingUnitInsert(StockkeepingUnit, Item2);
        StockkeepingUnit.Insert(true);

        OnAfterCreateSKU(StockkeepingUnit, Item2);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemOnPreDataItem(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemOnAfterGetRecord(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemOnAfterGetRecordOnAfterSetLocationFilter(var Location: Record Location; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateSKU(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    begin
    end;
}
