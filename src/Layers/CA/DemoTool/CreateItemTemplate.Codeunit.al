codeunit 101997 "Create Item Template"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        xItemDescrTxt: Label 'Item', Comment = 'Translate.';
        Item: Record Item;
        xItemNoTaxDescrTxt: Label 'Item No Sales Tax', Comment = 'Translate.';
        xServiceDescTxt: Label 'Service', Comment = 'Translate.';
        xServiceNoTaxDescTxt: Label 'Service No Sales Tax', Comment = 'Translate.';
        xBaseUOMPCSTxt: Label 'PCS', Comment = 'translate';
        xBaseUOMHourTxt: Label 'Hour', Comment = 'translate';
        CreateTemplateHelper: Codeunit "Create Template Helper";
        XOfficefurniture: Label 'Office furniture';
        XMiscellaneous: Label 'Miscellaneous';
        InventoryConditionTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Table27">VERSION(1) SORTING(Field1) where(Field10=1(0))</DataItem></DataItems></ReportParameters>', Locked = true;
        ServiceConditionTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Table27">VERSION(1) SORTING(Field1) where(Field10=1(1))</DataItem></DataItems></ReportParameters>', Locked = true;
        NONTAXABLETok: Label 'NONTAXABLE';
        TAXABLETok: Label 'TAXABLE';

    procedure InsertMiniAppData()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        CreateTemplateHelper: Codeunit "Create Template Helper";
    begin
        DemoDataSetup.Get();
        // Item template
        InsertTemplateHeader(ConfigTemplateHeader, xItemDescrTxt);
        InsertTemplateLines(ConfigTemplateHeader, Format(Item.Type::Inventory), xBaseUOMPCSTxt, DemoDataSetup.RetailCode(), TAXABLETok, DemoDataSetup.ResaleCode());

        CreateTemplateHelper.CreateTemplateSelectionRule(
          DATABASE::Item, ConfigTemplateHeader.Code, InventoryConditionTxt, 0, 0);
        // Item template No Tax
        InsertTemplateHeader(ConfigTemplateHeader, xItemNoTaxDescrTxt);
        InsertTemplateLines(ConfigTemplateHeader, Format(Item.Type::Inventory), xBaseUOMPCSTxt, DemoDataSetup.NoVATCode(), NONTAXABLETok, DemoDataSetup.ResaleCode());
        // Service template
        InsertTemplateHeader(ConfigTemplateHeader, xServiceDescTxt);
        InsertTemplateLines(ConfigTemplateHeader, Format(Item.Type::Service), xBaseUOMHourTxt, DemoDataSetup.ServicesCode(), TAXABLETok, '');

        CreateTemplateHelper.CreateTemplateSelectionRule(
          DATABASE::Item, ConfigTemplateHeader.Code, ServiceConditionTxt, 0, 0);
        // Service No Tax template
        InsertTemplateHeader(ConfigTemplateHeader, xServiceNoTaxDescTxt);
        InsertTemplateLines(ConfigTemplateHeader, Format(Item.Type::Service), xBaseUOMHourTxt, DemoDataSetup.ServicesCode(), NONTAXABLETok, '');
        InsertPostingGroupsItemTemplates();
    end;

    local procedure InsertTemplateHeader(var ConfigTemplateHeader: Record "Config. Template Header"; Description: Text[50])
    var
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        CreateTemplateHelper.CreateTemplateHeader(
          ConfigTemplateHeader, ConfigTemplateManagement.GetNextAvailableCode(DATABASE::Item), Description, DATABASE::Item);
    end;

    local procedure InsertTemplateLines(var ConfigTemplateHeader: Record "Config. Template Header"; Type: Text[50]; UOM: Code[20]; GenProdGroup: Code[20]; TaxGroup: Code[20]; InventoryGroup: Code[20])
    begin
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo(Type), Format(Type));
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Base Unit of Measure"), UOM);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Gen. Prod. Posting Group"), GenProdGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Tax Group Code"), TaxGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Inventory Posting Group"), InventoryGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Allow Invoice Disc."), Format(true));
        if Type = Format(Item.Type::Service) then
            CreateTemplateHelper.CreateTemplateLine(
              ConfigTemplateHeader, Item.FieldNo("Costing Method"), Format(Item."Costing Method"::FIFO));
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
        InsertItemTemplateData(XMiscellaneous, DemoDataSetup.RetailCode(), DefInventoryPostingGroup, '', '');
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Evaluation then begin
            FurnitureTemplateCode := InsertItemTemplateData(XOfficefurniture, DemoDataSetup.RetailCode(), DefInventoryPostingGroup, '', '');
            if not NonstockItem.IsEmpty() then
                NonstockItem.ModifyAll("Item Templ. Code", CreateNewItemTemplate.GetItemCode());
        end;
    end;

    procedure InsertItemTemplateData(TemplateName: Text[50]; GenProdPostingGroup: Code[20]; InventoryPostingGroup: Code[20]; TaxGroupCode: Code[10]; VATProdPostingGroup: Code[20]) TemplateCode: Code[10]
    var
        Item: Record Item;
        ConfigTemplateHeader: Record "Config. Template Header";
        CreateTemplateHelper: Codeunit "Create Template Helper";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        TemplateCode := ConfigTemplateManagement.GetNextAvailableCode(DATABASE::Item);
        CreateTemplateHelper.CreateTemplateHeader(
          ConfigTemplateHeader, TemplateCode, TemplateName, DATABASE::Item);

        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo(Type), Format(Item.Type::Inventory));
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Base Unit of Measure"), xBaseUOMPCSTxt);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Gen. Prod. Posting Group"), GenProdPostingGroup);
        if VATProdPostingGroup <> '' then
            CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("VAT Prod. Posting Group"), VATProdPostingGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Inventory Posting Group"), InventoryPostingGroup);
        if TaxGroupCode <> '' then
            CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Tax Group Code"), TaxGroupCode);
    end;
}