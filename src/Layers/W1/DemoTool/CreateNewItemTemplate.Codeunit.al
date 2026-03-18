codeunit 122008 "Create New Item Template"
{
    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
        ItemTempl: Record "Item Templ.";
        Item: Record Item;
        CreateUnitofMeasure: Codeunit "Create Unit of Measure";
    begin
        DemoDataSetup.Get();

        InsertTemplate(ItemTempl, ItemCodeTxt, ItemDescTxt);
        InsertPostingInfo(ItemTempl, DemoDataSetup.RetailCode(), DemoDataSetup.GoodsVATCode(), DemoDataSetup.ResaleCode());
        InsertOtherInfo(ItemTempl, Item.Type::Inventory, CreateUnitofMeasure.GetPcsUnitOfMeasureCode());

        InsertTemplate(ItemTempl, ServiceCodeTxt, ServiceDescTxt);
        InsertPostingInfo(ItemTempl, DemoDataSetup.ServicesCode(), DemoDataSetup.GoodsVATCode(), '');
        InsertOtherInfo(ItemTempl, Item.Type::Service, CreateUnitofMeasure.HourCode());
    end;

    var
        ItemCodeTxt: Label 'ITEM', MaxLength = 20;
        ItemDescTxt: Label 'Item', MaxLength = 100;
        ServiceCodeTxt: Label 'SERVICE', MaxLength = 20;
        ServiceDescTxt: Label 'Service', MaxLength = 100;

    local procedure InsertTemplate(var ItemTempl: Record "Item Templ."; Code: Code[20]; Description: Text[100])
    begin
        ItemTempl.Init();
        ItemTempl.Validate(Code, Code);
        ItemTempl.Validate(Description, Description);
        ItemTempl.Insert(true);
    end;

    local procedure InsertPostingInfo(var ItemTempl: Record "Item Templ."; GenProdPostingGr: Code[20]; VATProdPostingGr: Code[20]; InventoryPostingGr: Code[20])
    begin
        ItemTempl.Validate("Gen. Prod. Posting Group", GenProdPostingGr);
        ItemTempl.Validate("VAT Prod. Posting Group", VATProdPostingGr);
        ItemTempl.Validate("Inventory Posting Group", InventoryPostingGr);
        ItemTempl.Modify(true);
    end;

    local procedure InsertOtherInfo(var ItemTempl: Record "Item Templ."; ItemType: Enum "Item Type"; BaseUOMCode: Code[10])
    begin
        ItemTempl.Validate(Type, ItemType);
        ItemTempl.Validate("Base Unit of Measure", BaseUOMCode);
        ItemTempl.Modify(true);
    end;

    procedure GetItemCode(): Code[20]
    begin
        exit(ItemCodeTxt);
    end;
}