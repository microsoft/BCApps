codeunit 163545 "Create Stockk. Unit Templ. CZL"
{
    trigger OnRun()
    begin
        InsertData(CreateItem.GetItemCategoryCode('XCHAIR'), CreateLocation.GetLocationCode('XRED'));
        InsertData(CreateItem.GetItemCategoryCode('XCHAIR'), CreateLocation.GetLocationCode('XGREEN'));
    end;

    var
        CreateItem: Codeunit "Create Item";
        CreateLocation: Codeunit "Create Location";

    procedure InsertData(ItemCategoryCode: Code[20]; LocationCode: Code[10])
    var
        StockkeepingUnitTemplateCZL: Record "Stockkeeping Unit Template CZL";
    begin
        StockkeepingUnitTemplateCZL.Init();
        StockkeepingUnitTemplateCZL."Item Category Code" := ItemCategoryCode;
        StockkeepingUnitTemplateCZL."Location Code" := LocationCode;
        StockkeepingUnitTemplateCZL.Description := StockkeepingUnitTemplateCZL.GetDefaultDescription();
        StockkeepingUnitTemplateCZL.Insert();
    end;

    procedure InsertSKUTemplateData()
    begin
        InsertDataCZL(CreateItem.GetItemCategoryCode('XCHAIR'), CreateLocation.GetLocationCode('XRED'), Enum::"Replenishment System"::Transfer, Enum::"Reordering Policy"::"Maximum Qty.", '');
        InsertDataCZL(CreateItem.GetItemCategoryCode('XCHAIR'), CreateLocation.GetLocationCode('XGREEN'), Enum::"Replenishment System"::Purchase, Enum::"Reordering Policy"::" ", CreateLocation.GetLocationCode('XGREEN'));
    end;

    local procedure InsertDataCZL(ItemCategoryCode: Code[20]; LocationCode: Code[10]; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; TransferFromCode: Code[10])
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        StockkeepingUnitTemplateCZL: Record "Stockkeeping Unit Template CZL";
        StockkeepingUnit: Record "Stockkeeping Unit";
        CreateTemplateHelper: Codeunit "Create Template Helper";
    begin
        CreateTemplateHelper.CreateTemplateHeader(
            ConfigTemplateHeader, GetNextDataTemplateAvailableCode(),
            GetDataTemplateDescription(ItemCategoryCode, LocationCode),
            Database::"Stockkeeping Unit");
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, StockkeepingUnit.FieldNo("Replenishment System"), Format(ReplenishmentSystem));
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, StockkeepingUnit.FieldNo("Reordering Policy"), Format(ReorderingPolicy));
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, StockkeepingUnit.FieldNo("Include Inventory"), Format(true));
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, StockkeepingUnit.FieldNo("Transfer-from Code"), TransferFromCode);

        StockkeepingUnitTemplateCZL.Get(ItemCategoryCode, LocationCode);
        StockkeepingUnitTemplateCZL."Configuration Template Code" := ConfigTemplateHeader.Code;
        StockkeepingUnitTemplateCZL.Modify(false);
    end;

    local procedure GetNextDataTemplateAvailableCode(): Code[10]
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        StockkeepingUnitConfigTemplCode: Code[10];
        StockkeepingUnitConfigTemplCodeTxt: Label 'SKU0000000', MaxLength = 10;
    begin
        if StockkeepingUnitConfigTemplCode = '' then
            StockkeepingUnitConfigTemplCode := StockkeepingUnitConfigTemplCodeTxt;
        repeat
            StockkeepingUnitConfigTemplCode := CopyStr(IncStr(StockkeepingUnitConfigTemplCode), 1, MaxStrLen(ConfigTemplateHeader.Code));
        until not ConfigTemplateHeader.Get(StockkeepingUnitConfigTemplCode);
        exit(StockkeepingUnitConfigTemplCode);
    end;

    local procedure GetDataTemplateDescription(ItemCategoryCode: Code[20]; LocationCode: Code[10]): Text[50]
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        StockkeepingUnitConfigTemplDescTok: Label '%1 %2 %3', Comment = '%1 = Stockkeeping Unit TableCaption, %2 = "Item Category Code", %3 = "Location Code"', Locked = true;
    begin
        exit(CopyStr(StrSubstNo(StockkeepingUnitConfigTemplDescTok, StockkeepingUnit.TableCaption(), ItemCategoryCode, LocationCode), 1, 50));
    end;
}
