codeunit 101933 "Create Config. Templates"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CreateTemplateHelper: Codeunit "Create Template Helper";
        ConfigTemplateManagement: Codeunit "Config. Template Management";

    local procedure Initialize()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        if not ConfigTemplateHeader.IsEmpty() then
            ConfigTemplateHeader.DeleteAll(true);
        DemoDataSetup.Get();
    end;

    procedure CreateMiniTemplates()
    var
        CreateCustomerTemplate: Codeunit "Create Customer Template";
        CreateItemTemplate: Codeunit "Create Item Template";
        CreateVendorTemplate: Codeunit "Create Vendor Template";
        CreateResourceTemplate: Codeunit "Create Resource Template";
    begin
        Initialize();
        CreateCustomerTemplate.InsertMiniAppData();
        CreateItemTemplate.InsertMiniAppData();
        CreateVendorTemplate.InsertMiniAppData();
        CreateResourceTemplate.InsertResourceData();
    end;

    procedure CreateTemplates()
    var
        CreateItemTemplateCU: Codeunit "Create Item Template";
        CreateResourceTemplate: Codeunit "Create Resource Template";
        ConfigTemplateHeaderCode: Code[10];
    begin
        Initialize();
        ConfigTemplateHeaderCode := CreateCustTemplate('10000', DemoDataSetup.DomesticCode());
        CreateTemplateHelper.CreateTemplateSelectionRule(
          DATABASE::Customer, ConfigTemplateHeaderCode, '', 0, 0);

        CreateCustTemplate('31987987', DemoDataSetup.EUCode());
        CreateCustTemplate('01454545', DemoDataSetup.ForeignCode());

        ConfigTemplateHeaderCode := CreateVendTemplate('10000', DemoDataSetup.DomesticCode());
        CreateTemplateHelper.CreateTemplateSelectionRule(
          DATABASE::Vendor, ConfigTemplateHeaderCode, '', 0, 0);

        CreateVendTemplate('31147896', DemoDataSetup.EUCode());
        CreateVendTemplate('01254796', DemoDataSetup.ForeignCode());

        ConfigTemplateHeaderCode := CreateItemTemplate('1896-S', DemoDataSetup.RetailCode());
        CreateTemplateHelper.CreateTemplateSelectionRule(
          DATABASE::Item, ConfigTemplateHeaderCode, '', 0, 0);

        CreateItemTemplate('1900-S', DemoDataSetup.ManufactCode());

        CreateItemTemplateCU.InsertPostingGroupsItemTemplates();

        CreateResourceTemplate.InsertResourceData();
    end;

    local procedure CreateCustTemplate(CustNo: Code[20]; CustPostingGroup: Code[20]): Code[10]
    var
        Cust: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        Cust.Get(CustNo);
        if CustomerPostingGroup.Get(CustPostingGroup) then begin
            Cust."Customer Posting Group" := CustPostingGroup;
            Cust.Modify();
        end;

        CreateTemplateHelper.CreateTemplateHeader(
          ConfigTemplateHeader, ConfigTemplateManagement.GetNextAvailableCode(DATABASE::Customer),
          Cust.TableCaption + ' ' + Cust."Customer Posting Group", DATABASE::Customer);

        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Cust.FieldNo("Customer Posting Group"), Cust."Customer Posting Group");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Cust.FieldNo("Currency Code"), Cust."Currency Code");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Cust.FieldNo("Language Code"), Cust."Language Code");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Cust.FieldNo("Payment Terms Code"), Cust."Payment Terms Code");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Cust.FieldNo("Fin. Charge Terms Code"), Cust."Fin. Charge Terms Code");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Cust.FieldNo("Shipment Method Code"), Cust."Shipment Method Code");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Cust.FieldNo("Payment Method Code"), Cust."Payment Method Code");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Cust.FieldNo("Application Method"), Format(Cust."Application Method"::Manual));
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Cust.FieldNo("Gen. Bus. Posting Group"), Cust."Gen. Bus. Posting Group");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Cust.FieldNo(Reserve), Format(Cust.Reserve::Optional));
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Cust.FieldNo("Shipping Advice"), Format(Cust."Shipping Advice"::Partial));
        case DemoDataSetup."Company Type" of
            DemoDataSetup."Company Type"::VAT:
                CreateTemplateHelper.CreateTemplateLine(
                  ConfigTemplateHeader, Cust.FieldNo("VAT Bus. Posting Group"), Cust."VAT Bus. Posting Group");
            DemoDataSetup."Company Type"::"Sales Tax":
                begin
                    CreateTemplateHelper.CreateTemplateLine(
                      ConfigTemplateHeader, Cust.FieldNo("Tax Area Code"), Cust."Tax Area Code");
                    CreateTemplateHelper.CreateTemplateLine(
                      ConfigTemplateHeader, Cust.FieldNo("Tax Liable"), Format(Cust."Tax Liable"));
                end;
        end;
        exit(ConfigTemplateHeader.Code);
    end;

    local procedure CreateVendTemplate(VendNo: Code[20]; VendPostingGroup: Code[20]): Code[10]
    var
        Vend: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        Vend.Get(VendNo);
        if VendorPostingGroup.Get(VendPostingGroup) then begin
            Vend."Vendor Posting Group" := VendPostingGroup;
            Vend.Modify();
        end;

        CreateTemplateHelper.CreateTemplateHeader(
          ConfigTemplateHeader, ConfigTemplateManagement.GetNextAvailableCode(DATABASE::Vendor),
          Vend.TableCaption + ' ' + Vend."Vendor Posting Group", DATABASE::Vendor);

        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Vend.FieldNo("Vendor Posting Group"), Vend."Vendor Posting Group");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Vend.FieldNo("Currency Code"), Vend."Currency Code");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Vend.FieldNo("Language Code"), Vend."Language Code");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Vend.FieldNo("Payment Terms Code"), Vend."Payment Terms Code");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Vend.FieldNo("Fin. Charge Terms Code"), Vend."Fin. Charge Terms Code");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Vend.FieldNo("Payment Method Code"), Vend."Payment Method Code");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Vend.FieldNo("Application Method"), Format(Vend."Application Method"::Manual));
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Vend.FieldNo("Gen. Bus. Posting Group"), Vend."Gen. Bus. Posting Group");
        case DemoDataSetup."Company Type" of
            DemoDataSetup."Company Type"::VAT:
                CreateTemplateHelper.CreateTemplateLine(
                  ConfigTemplateHeader, Vend.FieldNo("VAT Bus. Posting Group"), Vend."VAT Bus. Posting Group");
            DemoDataSetup."Company Type"::"Sales Tax":
                begin
                    CreateTemplateHelper.CreateTemplateLine(
                      ConfigTemplateHeader, Vend.FieldNo("Tax Area Code"), Vend."Tax Area Code");
                    CreateTemplateHelper.CreateTemplateLine(
                      ConfigTemplateHeader, Vend.FieldNo("Tax Liable"), Format(Vend."Tax Liable"));
                end;
        end;
        exit(ConfigTemplateHeader.Code);
    end;

    local procedure CreateItemTemplate(ItemNo: Code[20]; GenProdPostingGroupCode: Code[10]): Code[10]
    var
        Item: Record Item;
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        Item.Get(ItemNo);
        if GenProductPostingGroup.Get(GenProdPostingGroupCode) then begin
            Item."Gen. Prod. Posting Group" := GenProdPostingGroupCode;
            Item.Modify();
        end;

        CreateTemplateHelper.CreateTemplateHeader(
          ConfigTemplateHeader, ConfigTemplateManagement.GetNextAvailableCode(DATABASE::Item),
          Item.TableCaption + ' ' + Item."Gen. Prod. Posting Group", DATABASE::Item);

        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Item.FieldNo("Inventory Posting Group"), Item."Inventory Posting Group");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Item.FieldNo("Price/Profit Calculation"), Format(Item."Price/Profit Calculation"));
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Item.FieldNo("Costing Method"), Format(Item."Costing Method"::Standard));
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Reorder Point"), '5');
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Item.FieldNo("Gen. Prod. Posting Group"), Item."Gen. Prod. Posting Group");
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Item.FieldNo(Reserve), Format(Item.Reserve));
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Item.FieldNo("Safety Stock Quantity"), '1');
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Item.FieldNo("Flushing Method"), Format(Item."Flushing Method"::Backward));
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Item.FieldNo("Replenishment System"), Format(Item."Replenishment System"::Purchase));
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Item.FieldNo("Reordering Policy"), Format(Item."Reordering Policy"::"Maximum Qty."));
        CreateTemplateHelper.CreateTemplateLine(
          ConfigTemplateHeader, Item.FieldNo("Manufacturing Policy"), Format(Item."Manufacturing Policy"::"Make-to-Order"));
        case DemoDataSetup."Company Type" of
            DemoDataSetup."Company Type"::VAT:
                CreateTemplateHelper.CreateTemplateLine(
                  ConfigTemplateHeader, Item.FieldNo("VAT Prod. Posting Group"), Item."VAT Prod. Posting Group");
            DemoDataSetup."Company Type"::"Sales Tax":
                CreateTemplateHelper.CreateTemplateLine(
                  ConfigTemplateHeader, Item.FieldNo("Tax Group Code"), Item."Tax Group Code");
        end;
        exit(ConfigTemplateHeader.Code);
    end;
}