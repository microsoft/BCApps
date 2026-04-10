namespace System.Integration;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Pricing;

codeunit 6113 "Item Data Migration Facade"
{
    TableNo = "Data Migration Parameters";

    trigger OnRun()
    var
        DataMigrationStatusFacade: Codeunit "Data Migration Status Facade";
        ChartOfAccountsMigrated: Boolean;
    begin
        ChartOfAccountsMigrated := DataMigrationStatusFacade.HasMigratedChartOfAccounts(Rec);
        if Rec.FindSet() then
            repeat
                OnMigrateItem(Rec."Staging Table RecId To Process");
                OnMigrateItemTrackingCode(Rec."Staging Table RecId To Process");
                OnMigrateCostingMethod(Rec."Staging Table RecId To Process"); // needs to be set after item tracking code because of onvalidate trigger check
                OnMigrateItemUnitOfMeasure(Rec."Staging Table RecId To Process");
                OnMigrateItemDiscountGroup(Rec."Staging Table RecId To Process");
                OnMigrateItemSalesLineDiscount(Rec."Staging Table RecId To Process");
                OnMigrateItemPrice(Rec."Staging Table RecId To Process");
                OnMigrateItemTariffNo(Rec."Staging Table RecId To Process");
                OnMigrateItemDimensions(Rec."Staging Table RecId To Process");

                // migrate transactions for this item as long as it is an inventory item
                if GlobalItem.Type = GlobalItem.Type::Inventory then begin
                    OnMigrateItemPostingGroups(Rec."Staging Table RecId To Process", ChartOfAccountsMigrated);
                    OnMigrateInventoryTransactions(Rec."Staging Table RecId To Process", ChartOfAccountsMigrated);
                    ItemJournalLineIsSet := false;
                end;
                ItemIsSet := false;
            until Rec.Next() = 0;
    end;

    var
        GlobalItem: Record Item;
        GlobalItemJournalLine: Record "Item Journal Line";
        DataMigrationFacadeHelper: Codeunit "Data Migration Facade Helper";
        ItemIsSet: Boolean;
        InternalItemNotSetErr: Label 'Internal item is not set. Create it first.';
        ItemJournalLineIsSet: Boolean;
        InternalItemJnlLIneNotSetErr: Label 'Internal item journal line is not set. Create it first.';

    procedure CreateItemIfNeeded(ItemNoToSet: Code[20]; ItemDescriptionToSet: Text[50]; ItemDescription2ToSet: Text[50]; ItemTypeToSet: Option Inventory,Service): Boolean
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNoToSet) then begin
            GlobalItem := Item;
            ItemIsSet := true;
            exit(false);
        end;

        Item.Init();

        Item.Validate("No.", ItemNoToSet);
        Item.Validate(Description, ItemDescriptionToSet);
        Item.Validate("Description 2", ItemDescription2ToSet);
        Item.Validate(Type, ItemTypeToSet);
        Item.Insert(true);

        GlobalItem := Item;
        ItemIsSet := true;
        exit(true);
    end;

    procedure CreateLocationIfNeeded(LocationCode: Code[10]; LocationName: Text[50]): Boolean
    var
        Location: Record Location;
    begin
        if Location.Get(LocationCode) then
            exit(false);

        Location.Init();
        Location.Validate(Code, LocationCode);
        Location.Validate(Name, LocationName);
        Location.Insert(true);

        exit(true);
    end;

    procedure DoesItemExist(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        exit(Item.Get(ItemNo));
    end;

    procedure SetGlobalItem(ItemNo: Code[20]): Boolean
    begin
        ItemIsSet := GlobalItem.Get(ItemNo);
        exit(ItemIsSet);
    end;

    procedure ModifyItem(RunTrigger: Boolean)
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Modify(RunTrigger);
    end;

    procedure CreateSalesLineDiscountIfNeeded(SalesTypeToSet: Option Customer,"Customer Disc. Group","All Customers",Campaign; SalesCodeToSet: Code[20]; TypeToSet: Option Item,"Item Disc. Group"; CodeToSet: Code[20]; LineDiscountPercentToSet: Decimal): Boolean
    var
        SalesLineDiscount: Record "Sales Line Discount";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        if PriceCalculationMgt.IsExtendedPriceCalculationEnabled() then
            exit(
                CreateSalesLineDiscountIfNeeded(
                    SalesDiscTypeToSourceType(SalesTypeToSet), SalesCodeToSet,
                    DiscTypeToAssetType(TypeToSet), CodeToSet, 0, LineDiscountPercentToSet));

        SalesLineDiscount.SetRange("Sales Type", SalesTypeToSet);
        SalesLineDiscount.SetRange("Sales Code", SalesCodeToSet);
        SalesLineDiscount.SetRange(Type, TypeToSet);
        SalesLineDiscount.SetRange(Code, CodeToSet);
        SalesLineDiscount.SetRange("Line Discount %", LineDiscountPercentToSet);

        if SalesLineDiscount.FindFirst() then
            exit(false);

        SalesLineDiscount.Init();
        SalesLineDiscount.Validate("Sales Type", SalesTypeToSet);
        SalesLineDiscount.Validate("Sales Code", SalesCodeToSet);
        SalesLineDiscount.Validate(Type, TypeToSet);
        SalesLineDiscount.Validate(Code, CodeToSet);
        SalesLineDiscount.Validate("Line Discount %", LineDiscountPercentToSet);
        SalesLineDiscount.Insert(true);
        exit(true);
    end;

    local procedure DiscTypeToAssetType(DiscType: Option Item,"Item Disc. Group"): Enum "Price Asset Type";
    begin
        case DiscType of
            DiscType::Item:
                exit(Enum::"Price Asset Type"::Item);
            DiscType::"Item Disc. Group":
                exit(Enum::"Price Asset Type"::"Item Discount Group");
        end;
    end;

    procedure CreateSalesLineDiscountIfNeeded(SourceType: Enum "Price Source Type"; SourceNo: Code[20]; AssetType: Enum "Price Asset Type"; AssetNo: Code[20]; MinimumQuantity: Decimal; LineDiscountPercent: Decimal): Boolean
    var
        PriceListLine: Record "Price List Line";
    begin
        InitSalesPriceListLine(
            PriceListLine, SourceType, SourceNo, '', 0D, AssetType, AssetNo, '', '', MinimumQuantity);
        PriceListLine."Amount Type" := Enum::"Price Amount Type"::Discount;
        PriceListLine."Line Discount %" := LineDiscountPercent;
        if FindPriceListLine(PriceListLine) then
            exit(false);
        InsertPriceListLine(PriceListLine);
        exit(true);
    end;

    procedure CreateCustDiscGroupIfNeeded(CustDiscGroupCodeToSet: Code[20]; DescriptionToSet: Text[50]): Boolean
    var
        CustomerDiscountGroup: Record "Customer Discount Group";
    begin
        if CustomerDiscountGroup.Get(CustDiscGroupCodeToSet) then
            exit(false);

        CustomerDiscountGroup.Init();
        CustomerDiscountGroup.Validate(Code, CustDiscGroupCodeToSet);
        CustomerDiscountGroup.Validate(Description, DescriptionToSet);
        CustomerDiscountGroup.Insert(true);
        exit(true);
    end;

    procedure CreateItemDiscGroupIfNeeded(DiscGroupCodeToSet: Code[20]; DescriptionToSet: Text[50]): Boolean
    var
        ItemDiscountGroup: Record "Item Discount Group";
    begin
        if ItemDiscountGroup.Get(DiscGroupCodeToSet) then
            exit(false);

        ItemDiscountGroup.Init();
        ItemDiscountGroup.Validate(Code, DiscGroupCodeToSet);
        ItemDiscountGroup.Validate(Description, DescriptionToSet);
        ItemDiscountGroup.Insert(true);
        exit(true);
    end;

    procedure CreateSalesPriceIfNeeded(SalesTypeToSet: Option Customer,"Customer Price Group","All Customers",Campaign; SalesCodeToSet: Code[20]; ItemNoToSet: Code[20]; UnitPriceToSet: Decimal; CurrencyCodeToSet: Code[10]; StartingDateToSet: Date; UnitOfMeasureToSet: Code[10]; MinimumQuantityToSet: Decimal; VariantCodeToSet: Code[10]): Boolean
    var
        SalesPrice: Record "Sales Price";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        if PriceCalculationMgt.IsExtendedPriceCalculationEnabled() then
            exit(
                CreateSalesPriceIfNeeded(
                    SalesPriceTypeToSourceType(SalesTypeToSet), SalesCodeToSet, CurrencyCodeToSet, StartingDateToSet,
                    ItemNoToSet, VariantCodeToSet, UnitOfMeasureToSet, MinimumQuantityToSet, UnitPriceToSet));

        if SalesPrice.Get(ItemNoToSet, SalesTypeToSet, SalesCodeToSet, StartingDateToSet, CurrencyCodeToSet,
             VariantCodeToSet, UnitOfMeasureToSet, MinimumQuantityToSet)
        then
            exit(false);
        SalesPrice.Init();

        SalesPrice.Validate("Sales Type", SalesTypeToSet);
        SalesPrice.Validate("Sales Code", SalesCodeToSet);
        SalesPrice.Validate("Item No.", ItemNoToSet);
        SalesPrice.Validate("Starting Date", StartingDateToSet);
        SalesPrice.Validate("Currency Code", DataMigrationFacadeHelper.FixIfLcyCode(CurrencyCodeToSet));
        SalesPrice.Validate("Variant Code", VariantCodeToSet);
        SalesPrice.Validate("Unit of Measure Code", UnitOfMeasureToSet);
        SalesPrice.Validate("Minimum Quantity", MinimumQuantityToSet);
        SalesPrice.Validate("Unit Price", UnitPriceToSet);

        SalesPrice.Insert(true);
        exit(true);
    end;

    local procedure SalesPriceTypeToSourceType(SalesType: Option Customer,"Customer Price Group","All Customers",Campaign): Enum "Price Source Type";
    begin
        case SalesType of
            SalesType::Customer:
                exit(Enum::"Price Source Type"::Customer);
            SalesType::"Customer Price Group":
                exit(Enum::"Price Source Type"::"Customer Price Group");
            SalesType::"All Customers":
                exit(Enum::"Price Source Type"::"All Customers");
            SalesType::Campaign:
                exit(Enum::"Price Source Type"::Campaign);
        end;
    end;

    local procedure SalesDiscTypeToSourceType(SalesType: Option Customer,"Customer Disc. Group","All Customers",Campaign): Enum "Price Source Type";
    begin
        case SalesType of
            SalesType::Customer:
                exit(Enum::"Price Source Type"::Customer);
            SalesType::"Customer Disc. Group":
                exit(Enum::"Price Source Type"::"Customer Disc. Group");
            SalesType::"All Customers":
                exit(Enum::"Price Source Type"::"All Customers");
            SalesType::Campaign:
                exit(Enum::"Price Source Type"::Campaign);
        end;
    end;

    procedure CreateSalesPriceIfNeeded(SourceType: Enum "Price Source Type"; SourceNo: Code[20]; CurrencyCode: Code[10]; StartingDate: Date; AssetNo: Code[20]; VariantCode: Code[10]; UnitOfMeasure: Code[10]; MinimumQuantity: Decimal; UnitPrice: Decimal): Boolean
    var
        PriceListLine: Record "Price List Line";
    begin
        InitSalesPriceListLine(
            PriceListLine, SourceType, SourceNo, CurrencyCode, StartingDate,
            Enum::"Price Asset Type"::Item, AssetNo, VariantCode, UnitOfMeasure, MinimumQuantity);
        PriceListLine."Amount Type" := Enum::"Price Amount Type"::Price;
        PriceListLine."Unit Price" := UnitPrice;
        if FindPriceListLine(PriceListLine) then
            exit(false);
        InsertPriceListLine(PriceListLine);
        exit(true);
    end;

    local procedure InitSalesPriceListLine(var PriceListLine: Record "Price List Line"; SourceType: Enum "Price Source Type"; SourceNo: Code[20]; CurrencyCode: Code[10]; StartingDate: Date; AssetType: Enum "Price Asset Type"; AssetNo: Code[20]; VariantCode: Code[10]; UnitOfMeasure: Code[10]; MinimumQuantity: Decimal)
    begin
        PriceListLine.Init();
        PriceListLine.Validate("Price Type", Enum::"Price Type"::Sale);
        PriceListLine.Validate("Source Type", SourceType);
        PriceListLine.Validate("Source No.", SourceNo);
        PriceListLine.Validate("Currency Code", DataMigrationFacadeHelper.FixIfLcyCode(CurrencyCode));
        PriceListLine.Validate("Starting Date", StartingDate);
        PriceListLine.Validate("Asset Type", AssetType);
        PriceListLine.Validate("Asset No.", AssetNo);
        PriceListLine.Validate("Variant Code", VariantCode);
        PriceListLine.Validate("Unit of Measure Code", UnitOfMeasure);
        PriceListLine.Validate("Minimum Quantity", MinimumQuantity);
        PriceListLine.Status := PriceListLine.Status::Active;
    end;

    local procedure FindPriceListLine(PriceListLine: Record "Price List Line"): Boolean;
    begin
        PriceListLine.SetRange("Source Type", PriceListLine."Source Type");
        PriceListLine.SetRange("Source No.", PriceListLine."Source No.");
        PriceListLine.SetRange("Currency Code", PriceListLine."Currency Code");
        PriceListLine.SetRange("Starting Date", PriceListLine."Starting Date");
        PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type");
        PriceListLine.SetRange("Asset No.", PriceListLine."Asset No.");
        PriceListLine.SetRange("Variant Code", PriceListLine."Variant Code");
        PriceListLine.SetRange("Unit of Measure Code", PriceListLine."Unit of Measure Code");
        PriceListLine.SetRange("Minimum Quantity", PriceListLine."Minimum Quantity");
        exit(not PriceListLine.IsEmpty);
    end;

    local procedure InsertPriceListLine(var PriceListLine: Record "Price List Line")
    var
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
    begin
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.InitLineNo(PriceListLine);
        PriceListLine.Insert(true);
    end;

    procedure CreateTariffNumberIfNeeded(NoToSet: Code[20]; DescriptionToSet: Text[50]; SupplementaryUnitToSet: Boolean): Boolean
    var
        TariffNumber: Record "Tariff Number";
    begin
        if TariffNumber.Get(NoToSet) then
            exit(false);

        TariffNumber.Init();
        TariffNumber.Validate("No.", NoToSet);
        TariffNumber.Validate(Description, DescriptionToSet);
        TariffNumber.Validate("Supplementary Units", SupplementaryUnitToSet);
        TariffNumber.Insert(true);
        exit(true);
    end;

    procedure CreateUnitOfMeasureIfNeeded(CodeToSet: Code[10]; DescriptionToSet: Text[10]): Boolean
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasure.Get(CodeToSet) then
            exit(false);

        UnitOfMeasure.Init();
        UnitOfMeasure.Validate(Code, CodeToSet);
        UnitOfMeasure.Validate(Description, DescriptionToSet);
        UnitOfMeasure.Insert(true);
        exit(true);
    end;

    procedure CreateItemTrackingCodeIfNeeded(CodeToSet: Code[10]; DescriptionToSet: Text[50]; LotSpecificTrackingToSet: Boolean; SNSpecificTrackingToSet: Boolean): Boolean
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if ItemTrackingCode.Get(CodeToSet) then
            exit(false);

        ItemTrackingCode.Init();
        ItemTrackingCode.Validate(Code, CodeToSet);
        ItemTrackingCode.Validate(Description, DescriptionToSet);
        ItemTrackingCode.Validate("Lot Specific Tracking", LotSpecificTrackingToSet);
        ItemTrackingCode.Validate("SN Specific Tracking", SNSpecificTrackingToSet);
        ItemTrackingCode.Insert(true);
        exit(true);
    end;

    procedure CreateInventoryPostingSetupIfNeeded(InventoryPostingGroupCode: Code[20]; InventoryPostingGroupDescription: Text[50]; LocationCode: Code[10]) Created: Boolean
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        if not InventoryPostingGroup.Get(InventoryPostingGroupCode) then begin
            InventoryPostingGroup.Init();
            InventoryPostingGroup.Validate(Code, InventoryPostingGroupCode);
            InventoryPostingGroup.Validate(Description, InventoryPostingGroupDescription);
            InventoryPostingGroup.Insert(true);
            Created := true;
        end;

        if not InventoryPostingSetup.Get(LocationCode, InventoryPostingGroupCode) then begin
            InventoryPostingSetup.Init();
            InventoryPostingSetup.Validate("Location Code", LocationCode);
            InventoryPostingSetup.Validate("Invt. Posting Group Code", InventoryPostingGroup.Code);
            InventoryPostingSetup.Insert(true);
            Created := true;
        end;
    end;

    procedure CreateGeneralProductPostingSetupIfNeeded(GeneralProdPostingGroupCode: Code[20]; GeneralProdPostingGroupDescription: Text[50]; GeneralBusPostingGroupCode: Code[20]) Created: Boolean
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GenProductPostingGroup.Get(GeneralProdPostingGroupCode) then begin
            GenProductPostingGroup.Init();
            GenProductPostingGroup.Validate(Code, GeneralProdPostingGroupCode);
            GenProductPostingGroup.Validate(Description, GeneralProdPostingGroupDescription);
            GenProductPostingGroup.Insert(true);
            Created := true;
        end;

        if not GeneralPostingSetup.Get(GeneralBusPostingGroupCode, GeneralProdPostingGroupCode) then begin
            GeneralPostingSetup.Init();
            GeneralPostingSetup.Validate("Gen. Bus. Posting Group", GeneralBusPostingGroupCode);
            GeneralPostingSetup.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
            GeneralPostingSetup.Insert(true);
            Created := true;
        end;
    end;

    procedure CreateItemJournalBatchIfNeeded(ItemJournalBatchCode: Code[10]; NoSeriesCode: Code[20]; PostingNoSeriesCode: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        TemplateName: Code[10];
    begin
        TemplateName := CreateItemJournalTemplateIfNeeded(ItemJournalBatchCode);
        ItemJournalBatch.SetRange("Journal Template Name", TemplateName);
        ItemJournalBatch.SetRange(Name, ItemJournalBatchCode);
        ItemJournalBatch.SetRange("No. Series", NoSeriesCode);
        ItemJournalBatch.SetRange("Posting No. Series", PostingNoSeriesCode);
        if not ItemJournalBatch.FindFirst() then begin
            ItemJournalBatch.Init();
            ItemJournalBatch.Validate("Journal Template Name", TemplateName);
            ItemJournalBatch.SetupNewBatch();
            ItemJournalBatch.Validate(Name, ItemJournalBatchCode);
            ItemJournalBatch.Validate(Description, ItemJournalBatchCode);
            ItemJournalBatch."No. Series" := NoSeriesCode;
            ItemJournalBatch."Posting No. Series" := PostingNoSeriesCode;
            ItemJournalBatch.Insert(true);
        end;
    end;

    local procedure CreateItemJournalTemplateIfNeeded(ItemJournalBatchCode: Code[10]): Code[10]
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        if not ItemJournalTemplate.FindFirst() then begin
            ItemJournalTemplate.Init();
            ItemJournalTemplate.Validate(Name, ItemJournalBatchCode);
            ItemJournalTemplate.Validate(Type, ItemJournalTemplate.Type::Item);
            ItemJournalTemplate.Validate(Recurring, false);
            ItemJournalTemplate.Insert(true);
        end;
        exit(ItemJournalTemplate.Name);
    end;

    procedure CreateItemJournalLine(ItemJournalBatchCode: Code[10]; DocumentNo: Code[20]; Description: Text[50]; PostingDate: Date; Qty: Decimal; Amount: Decimal; LocationCode: Code[10]; GenProdPostingGroupGode: Code[20])
    var
        ItemJournalLineCurrent: Record "Item Journal Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        LineNum: Integer;
    begin
        ItemJournalBatch.Get(CreateItemJournalTemplateIfNeeded(ItemJournalBatchCode), ItemJournalBatchCode);

        ItemJournalLineCurrent.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLineCurrent.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        if ItemJournalLineCurrent.FindLast() then
            LineNum := ItemJournalLineCurrent."Line No." + 10000
        else
            LineNum := 10000;

        ItemJournalLine.Init();

        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.Validate("Line No.", LineNum);
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Positive Adjmt.");
        ItemJournalLine.Validate("Document No.", DocumentNo);
        ItemJournalLine.Validate("Item No.", GlobalItem."No.");
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate(Description, Description);
        ItemJournalLine.Validate("Document Date", PostingDate);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Validate(Quantity, Qty);
        ItemJournalLine.Validate(Amount, Amount);
        ItemJournalLine.Validate("Gen. Bus. Posting Group", '');
        ItemJournalLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroupGode);
        ItemJournalLine.Insert(true);

        GlobalItemJournalLine := ItemJournalLine;
        ItemJournalLineIsSet := true;
    end;

    procedure SetItemJournalLineItemTracking(SerialNo: Code[50]; LotNo: Code[50])
    begin
        if not ItemJournalLineIsSet then
            Error(InternalItemJnlLIneNotSetErr);

        if (SerialNo <> '') or (LotNo <> '') then
            CreateItemTracking(GlobalItemJournalLine, SerialNo, LotNo);
    end;

    local procedure CreateItemTracking(ItemJournalLine: Record "Item Journal Line"; SerialNo: Code[50]; LotNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        ReservationEntry."Serial No." := SerialNo;
        ReservationEntry."Lot No." := LotNo;
        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Item Journal Line",
          ItemJournalLine."Entry Type".AsInteger(),
          ItemJournalLine."Journal Template Name",
          ItemJournalLine."Journal Batch Name",
          0,
          ItemJournalLine."Line No.",
          ItemJournalLine."Qty. per Unit of Measure",
          Abs(ItemJournalLine.Quantity),
          Abs(ItemJournalLine."Quantity (Base)"),
          ReservationEntry);
        CreateReservEntry.CreateEntry(
          ItemJournalLine."Item No.",
          ItemJournalLine."Variant Code",
          ItemJournalLine."Location Code",
          '', 0D, 0D, 0,
          "Reservation Status"::Prospect);
    end;

    procedure SetItemJournalLineDimension(DimensionCode: Code[20]; DimensionDescription: Text[50]; DimensionValueCode: Code[20]; DimensionValueName: Text[50])
    var
        DataMigrationFacadeHelper: Codeunit "Data Migration Facade Helper";
    begin
        if not ItemJournalLineIsSet then
            Error(InternalItemJnlLIneNotSetErr);

        GlobalItemJournalLine.Validate("Dimension Set ID",
          DataMigrationFacadeHelper.CreateDimensionSetId(GlobalItemJournalLine."Dimension Set ID",
            DimensionCode, DimensionDescription,
            DimensionValueCode, DimensionValueName));
        GlobalItemJournalLine.Modify(true);
    end;

    procedure CreateDefaultDimensionAndRequirementsIfNeeded(DimensionCode: Text[20]; DimensionDescription: Text[50]; DimensionValueCode: Code[20]; DimensionValueName: Text[50])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        DataMigrationFacadeHelper.GetOrCreateDimension(DimensionCode, DimensionDescription, Dimension);
        DataMigrationFacadeHelper.GetOrCreateDimensionValue(Dimension.Code, DimensionValueCode, DimensionValueName, DimensionValue);
        DataMigrationFacadeHelper.CreateOnlyDefaultDimensionIfNeeded(Dimension.Code, DimensionValue.Code, DATABASE::Item, GlobalItem."No.");
    end;

    procedure CreateBOMComponent(ComponentItemNo: Code[20]; Quantity: Decimal; Position: Code[10]; BOMType: Option)
    var
        BOMComponent: Record "BOM Component";
        LineNo: Integer;
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        BOMComponent.SetRange("Parent Item No.", GlobalItem."No.");
        if BOMComponent.FindLast() then
            LineNo := BOMComponent."Line No." + 1000
        else
            LineNo := 1000;

        BOMComponent.Init();
        BOMComponent.Validate("Parent Item No.", GlobalItem."No.");
        BOMComponent.Validate("Line No.", LineNo);
        BOMComponent.Validate(Type, BOMType);
        BOMComponent.Validate("No.", ComponentItemNo);
        BOMComponent.Validate("Quantity per", Quantity);
        BOMComponent.Validate(Position, Position);
        BOMComponent.Insert(true);
    end;

    procedure SetItemTrackingCode(TrackingCodeToSet: Code[10])
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Item Tracking Code", TrackingCodeToSet);
    end;

    procedure SetBaseUnitOfMeasure(BaseUnitOfMeasureToSet: Code[10])
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Base Unit of Measure", BaseUnitOfMeasureToSet);
    end;

    procedure SetPurchUnitOfMeasure(PurchUnitOfMeasureToSet: Code[10])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        if not ItemUnitOfMeasure.Get(GlobalItem."No.", PurchUnitOfMeasureToSet) then begin
            ItemUnitOfMeasure.Init();
            ItemUnitOfMeasure.Validate("Item No.", GlobalItem."No.");
            ItemUnitOfMeasure.Validate(Code, PurchUnitOfMeasureToSet);
            ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", 1);
            ItemUnitOfMeasure.Insert();
        end;

        GlobalItem.Validate("Purch. Unit of Measure", PurchUnitOfMeasureToSet);
    end;

    procedure SetItemDiscGroup(ItemDiscGroupToSet: Code[20])
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Item Disc. Group", ItemDiscGroupToSet);
    end;

    procedure SetTariffNo(TariffNoToSet: Code[20])
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Tariff No.", TariffNoToSet);
    end;

    procedure SetCostingMethod(CostingMethodToSet: Option FIFO,LIFO,Specific,"Average",Standard)
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Costing Method", CostingMethodToSet);
    end;

    procedure SetUnitCost(UnitCostToSet: Decimal)
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Unit Cost", UnitCostToSet);
    end;

    procedure SetStandardCost(StandardCostToSet: Decimal)
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Standard Cost", StandardCostToSet);
    end;

    procedure SetVendorItemNo(VendorItemNoToSet: Text[20])
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Vendor Item No.", VendorItemNoToSet);
    end;

    procedure SetNetWeight(NetWeightToSet: Decimal)
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Net Weight", NetWeightToSet);
    end;

    procedure SetUnitVolume(UnitVolumeToSet: Decimal)
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Unit Volume", UnitVolumeToSet);
    end;

    procedure SetBlocked(BlockedToSet: Boolean)
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate(Blocked, BlockedToSet);
    end;

    procedure SetStockoutWarning(IsStockoutWarning: Boolean)
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        if IsStockoutWarning then
            GlobalItem.Validate("Stockout Warning", GlobalItem."Stockout Warning"::Yes)
        else
            GlobalItem.Validate("Stockout Warning", GlobalItem."Stockout Warning"::No);
    end;

    procedure SetPreventNegativeInventory(IsPreventNegativeInventory: Boolean)
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        if IsPreventNegativeInventory then
            GlobalItem.Validate("Prevent Negative Inventory", GlobalItem."Prevent Negative Inventory"::Yes)
        else
            GlobalItem.Validate("Prevent Negative Inventory", GlobalItem."Prevent Negative Inventory"::No);
    end;

    procedure SetReorderQuantity(ReorderQuantityToSet: Decimal)
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Reorder Quantity", ReorderQuantityToSet);
    end;

    procedure SetAlternativeItemNo(AlternativeItemNoToSet: Code[20])
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Alternative Item No.", AlternativeItemNoToSet);
    end;

    procedure SetVendorNo(VendorNoToSet: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        if not Vendor.Get(VendorNoToSet) then
            exit;

        GlobalItem.Validate("Vendor No.", VendorNoToSet);

        exit(true);
    end;

    procedure SetUnitPrice(UnitPriceToSet: Decimal)
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Unit Price", UnitPriceToSet);
    end;

    procedure SetUnitListPrice(UnitListPriceToSet: Decimal)
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Unit List Price", UnitListPriceToSet);
    end;

    procedure SetLastDateModified(LastDateModifiedToSet: Date)
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Last Date Modified", LastDateModifiedToSet);
    end;

    procedure SetLastModifiedDateTime(LastModifiedDateTimeToSet: DateTime)
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Last DateTime Modified", LastModifiedDateTimeToSet);
    end;

    procedure CreateCustomerPriceGroupIfNeeded(CodeToSet: Code[10]; DescriptionToSet: Text[50]; PriceIncludesVatToSet: Boolean): Code[10]
    begin
        exit(DataMigrationFacadeHelper.CreateCustomerPriceGroupIfNeeded(CodeToSet, DescriptionToSet, PriceIncludesVatToSet));
    end;

    procedure SetInventoryPostingSetupInventoryAccount(InventoryPostingGroupCode: Code[20]; LocationCode: Code[10]; InventoryAccountCode: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        InventoryPostingSetup.Get(LocationCode, InventoryPostingGroupCode);
        InventoryPostingSetup.Validate("Inventory Account", InventoryAccountCode);
        InventoryPostingSetup.Modify(true);
    end;

    procedure SetGeneralPostingSetupInventoryAdjmntAccount(GeneralProdPostingGroupCode: Code[20]; GeneralBusPostingGroupCode: Code[10]; InventoryAdjmntAccountCode: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GeneralBusPostingGroupCode, GeneralProdPostingGroupCode);
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", InventoryAdjmntAccountCode);
        GeneralPostingSetup.Modify(true);
    end;

    procedure SetInventoryPostingGroup(InventoryPostingGroupCode: Code[20]): Boolean
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        if not InventoryPostingGroup.Get(InventoryPostingGroupCode) then
            exit;

        GlobalItem.Validate("Inventory Posting Group", InventoryPostingGroupCode);

        exit(true);
    end;

    procedure SetGeneralProductPostingGroup(GenProductPostingGroupCode: Code[20]): Boolean
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        if not GenProductPostingGroup.Get(GenProductPostingGroupCode) then
            exit;

        GlobalItem.Validate("Gen. Prod. Posting Group", GenProductPostingGroupCode);

        exit(true);
    end;

    procedure SetSearchDescription(SearchDescriptionToSet: Code[50])
    begin
        if not ItemIsSet then
            Error(InternalItemNotSetErr);

        GlobalItem.Validate("Search Description", SearchDescriptionToSet);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateItem(RecordIdToMigrate: RecordID)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateItemPrice(RecordIdToMigrate: RecordID)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateItemSalesLineDiscount(RecordIdToMigrate: RecordID)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateItemTrackingCode(RecordIdToMigrate: RecordID)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateCostingMethod(RecordIdToMigrate: RecordID)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateItemUnitOfMeasure(RecordIdToMigrate: RecordID)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateItemDiscountGroup(RecordIdToMigrate: RecordID)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateItemTariffNo(RecordIdToMigrate: RecordID)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateItemDimensions(RecordIdToMigrate: RecordID)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateItemPostingGroups(RecordIdToMigrate: RecordID; ChartOfAccountsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateInventoryTransactions(RecordIdToMigrate: RecordID; ChartOfAccountsMigrated: Boolean)
    begin
    end;
}

