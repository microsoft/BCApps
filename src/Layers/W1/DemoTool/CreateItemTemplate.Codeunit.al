codeunit 101997 "Create Item Template"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        xItemDescrTxt: Label 'Item', Comment = 'Translate.';
        Item: Record Item;
        xItemNoVATDescrTxt: Label 'Item No VAT', Comment = 'Translate.';
        xServiceDescTxt: Label 'Service', Comment = 'Translate.';
        xServiceNoVATDescTxt: Label 'Service No VAT', Comment = 'Translate.';
        xBaseUOMPCSTxt: Label 'PCS', Comment = 'translate';
        xBaseUOMHourTxt: Label 'Hour', Comment = 'translate';
        CreateTemplateHelper: Codeunit "Create Template Helper";
        XOfficefurniture: Label 'Office furniture';
        XMiscellaneous: Label 'Miscellaneous';
        InventoryConditionTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Table27">VERSION(1) SORTING(Field1) where(Field10=1(0))</DataItem></DataItems></ReportParameters>', Locked = true;
        ServiceConditionTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Table27">VERSION(1) SORTING(Field1) where(Field10=1(1))</DataItem></DataItems></ReportParameters>', Locked = true;

    procedure InsertMiniAppData()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        CreateTemplateHelper: Codeunit "Create Template Helper";
    begin
        DemoDataSetup.Get();
        // Item template
        InsertTemplateHeader(ConfigTemplateHeader, xItemDescrTxt);
        InsertTemplateLines(ConfigTemplateHeader, Format(Item.Type::Inventory), xBaseUOMPCSTxt, DemoDataSetup.RetailCode(), DemoDataSetup.GoodsVATCode(), DemoDataSetup.ResaleCode());
        InsertPricingInfo(ConfigTemplateHeader, false);

        CreateTemplateHelper.CreateTemplateSelectionRule(
          DATABASE::Item, ConfigTemplateHeader.Code, InventoryConditionTxt, 0, 0);
        // Item template No VAT
        InsertTemplateHeader(ConfigTemplateHeader, xItemNoVATDescrTxt);
        InsertTemplateLines(ConfigTemplateHeader, Format(Item.Type::Inventory), xBaseUOMPCSTxt, DemoDataSetup.NoVATCode(), DemoDataSetup.NoVATCode(), DemoDataSetup.ResaleCode());
        InsertPricingInfo(ConfigTemplateHeader, false);
        // Service template
        InsertTemplateHeader(ConfigTemplateHeader, xServiceDescTxt);
        InsertTemplateLines(ConfigTemplateHeader, Format(Item.Type::Service), xBaseUOMHourTxt, DemoDataSetup.ServicesCode(), DemoDataSetup.GoodsVATCode(), '');
        InsertPricingInfo(ConfigTemplateHeader, false);

        CreateTemplateHelper.CreateTemplateSelectionRule(
          DATABASE::Item, ConfigTemplateHeader.Code, ServiceConditionTxt, 0, 0);
        // Service No VAT template
        InsertTemplateHeader(ConfigTemplateHeader, xServiceNoVATDescTxt);
        InsertTemplateLines(ConfigTemplateHeader, Format(Item.Type::Service), xBaseUOMHourTxt, DemoDataSetup.NoVATCode(), DemoDataSetup.NoVATCode(), '');
        InsertPricingInfo(ConfigTemplateHeader, false);
        // Freight template
        InsertTemplateHeader(ConfigTemplateHeader, DemoDataSetup.FreightCode());
        InsertTemplateLines(ConfigTemplateHeader, Format(Item.Type::Service), xBaseUOMHourTxt, DemoDataSetup.FreightCode(), DemoDataSetup.GoodsVATCode(), '');
        InsertPricingInfo(ConfigTemplateHeader, false);

        InsertPostingGroupsItemTemplates();
    end;

    local procedure InsertTemplateHeader(var ConfigTemplateHeader: Record "Config. Template Header"; Description: Text[50])
    var
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        CreateTemplateHelper.CreateTemplateHeader(
          ConfigTemplateHeader, ConfigTemplateManagement.GetNextAvailableCode(DATABASE::Item), Description, DATABASE::Item);
    end;

    local procedure InsertTemplateLines(var ConfigTemplateHeader: Record "Config. Template Header"; Type: Text[50]; UOM: Code[20]; GenProdGroup: Code[20]; VATProdGroup: Code[20]; InventoryGroup: Code[20])
    begin
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo(Type), Format(Type));
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Base Unit of Measure"), UOM);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Gen. Prod. Posting Group"), GenProdGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("VAT Prod. Posting Group"), VATProdGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Inventory Posting Group"), InventoryGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Allow Invoice Disc."), Format(true));
        if Type = Format(Item.Type::Service) then
            CreateTemplateHelper.CreateTemplateLine(
              ConfigTemplateHeader, Item.FieldNo("Costing Method"), Format(Item."Costing Method"::FIFO));
    end;

    local procedure InsertPricingInfo(var ConfigTemplateHeader: Record "Config. Template Header"; PriceWithVAT: Boolean)
    begin
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Price Includes VAT"), Format(PriceWithVAT));
    end;

    procedure InsertPostingGroupsItemTemplates()
    var
        NonstockItem: Record "Nonstock Item";
        CreateNewItemTemplate: Codeunit "Create New Item Template";
        DefInventoryPostingGroup: Code[20];
        FurnitureTemplateCode: Code[10];
    begin
        DemoDataSetup.Get();
        if (DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Evaluation) or
           (DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Standard)
        then
            DefInventoryPostingGroup := DemoDataSetup.ResaleCode()
        else
            DefInventoryPostingGroup := DemoDataSetup.FinishedCode();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            FurnitureTemplateCode :=
              InsertItemTemplateData(XOfficefurniture, DemoDataSetup.RetailCode(), DefInventoryPostingGroup, '', DemoDataSetup.NoVATCode());
            InsertItemTemplateData(XMiscellaneous, DemoDataSetup.RetailCode(), DefInventoryPostingGroup, '', DemoDataSetup.NoVATCode());
        end else begin
            FurnitureTemplateCode := InsertItemTemplateData(XOfficefurniture, DemoDataSetup.RetailCode(), DefInventoryPostingGroup, '', '');
            InsertItemTemplateData(XMiscellaneous, DemoDataSetup.RetailCode(), DefInventoryPostingGroup, '', '');
        end;

        if NonstockItem.FindSet() then
            repeat
                NonstockItem.Validate("Item Templ. Code", CreateNewItemTemplate.GetItemCode());
                NonstockItem.Modify();
            until NonstockItem.Next() = 0;
    end;

    procedure InsertItemTemplateData(TemplateName: Text[50]; GenProdPostingGroup: Code[20]; InventoryPostingGroup: Code[20]; TaxGroupCode: Code[20]; VATProdPostingGroup: Code[20]) TemplateCode: Code[10]
    var
        Item: Record Item;
        ConfigTemplateHeader: Record "Config. Template Header";
        CreateTemplateHelper: Codeunit "Create Template Helper";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        TemplateCode := ConfigTemplateManagement.GetNextAvailableCode(DATABASE::Item);
        CreateTemplateHelper.CreateTemplateHeader(
          ConfigTemplateHeader, TemplateCode, TemplateName, DATABASE::Item);

        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Gen. Prod. Posting Group"), GenProdPostingGroup);
        if VATProdPostingGroup <> '' then
            CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("VAT Prod. Posting Group"), VATProdPostingGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Inventory Posting Group"), InventoryPostingGroup);
        if TaxGroupCode <> '' then
            CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Tax Group Code"), TaxGroupCode);
    end;
}