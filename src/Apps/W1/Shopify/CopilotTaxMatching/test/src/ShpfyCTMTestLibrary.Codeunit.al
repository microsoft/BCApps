namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;
using Microsoft.Inventory.Item;
using System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

codeunit 30491 "Shpfy CTM Test Library"
{
    Access = Internal;

    var
        AITTestContext: Codeunit "AIT Test Context";
        ShopCodeTok: Label 'CTMTEST', Locked = true;

    internal procedure GetInput(): Codeunit "Test Input Json"
    begin
        exit(AITTestContext.GetInput());
    end;

    internal procedure GetTestSetup(): Codeunit "Test Input Json"
    var
        TestSetup: Codeunit "Test Input Json";
    begin
        TestSetup := AITTestContext.GetTestSetup();
        if TestSetup.AsJsonToken().IsObject() then
            exit(TestSetup);

        // If test_setup is a string reference to external YAML, resolve it
        TestSetup.Initialize(GetTestSetupFromResource(TestSetup.ValueAsText()));
        exit(TestSetup);
    end;

    local procedure GetTestSetupFromResource(SetupFileName: Text): JsonToken
    var
        ResInStream: InStream;
        SetupAsText: Text;
        JsonObj: JsonObject;
        JsonTok: JsonToken;
    begin
        NavApp.GetResource('CompanyData/' + SetupFileName, ResInStream, TextEncoding::UTF8);
        ResInStream.Read(SetupAsText);
        JsonObj.ReadFromYaml(SetupAsText);
        JsonObj.Get('test_setup', JsonTok);
        exit(JsonTok);
    end;

    internal procedure SetupShop(ShopSettings: Codeunit "Test Input Json"): Record "Shpfy Shop"
    var
        Shop: Record "Shpfy Shop";
        ShopCodeText: Text;
        ElementExists: Boolean;
    begin
        ShopSettings.ElementExists('shopCode', ElementExists);
        if ElementExists then
            ShopCodeText := ShopSettings.Element('shopCode').ValueAsText()
        else
            ShopCodeText := ShopCodeTok;

        if Shop.Get(ShopCodeText) then begin
            ApplyShopSettings(Shop, ShopSettings);
            Shop.Modify();
        end else begin
            Shop.Init();
            Shop.Code := CopyStr(ShopCodeText, 1, MaxStrLen(Shop.Code));
            ShopSettings.ElementExists('shopifyUrl', ElementExists);
            if ElementExists then
                Shop."Shopify URL" := CopyStr(ShopSettings.Element('shopifyUrl').ValueAsText(), 1, MaxStrLen(Shop."Shopify URL"))
            else
                Shop."Shopify URL" := 'https://ctm-test.myshopify.com';
            ApplyShopSettings(Shop, ShopSettings);
            Shop.Insert();
        end;

        exit(Shop);
    end;

    local procedure ApplyShopSettings(var Shop: Record "Shpfy Shop"; ShopSettings: Codeunit "Test Input Json")
    var
        ElementExists: Boolean;
    begin
        ShopSettings.ElementExists('copilotTaxMatchingEnabled', ElementExists);
        if ElementExists then
            Shop."Copilot Tax Matching Enabled" := ShopSettings.Element('copilotTaxMatchingEnabled').ValueAsBoolean();

        ShopSettings.ElementExists('autoCreateTaxJurisdictions', ElementExists);
        if ElementExists then
            Shop."Auto Create Tax Jurisdictions" := ShopSettings.Element('autoCreateTaxJurisdictions').ValueAsBoolean();

        ShopSettings.ElementExists('autoCreateTaxAreas', ElementExists);
        if ElementExists then
            Shop."Auto Create Tax Areas" := ShopSettings.Element('autoCreateTaxAreas').ValueAsBoolean();

        ShopSettings.ElementExists('taxAreaNamingPattern', ElementExists);
        if ElementExists then
            Shop."Tax Area Naming Pattern" := CopyStr(ShopSettings.Element('taxAreaNamingPattern').ValueAsText(), 1, MaxStrLen(Shop."Tax Area Naming Pattern"));
    end;

    internal procedure SetupTaxJurisdictions(SetupInput: Codeunit "Test Input Json")
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        JurisdictionsArray: Codeunit "Test Input Json";
        JurisdictionInput: Codeunit "Test Input Json";
        ElementExists: Boolean;
        i: Integer;
    begin
        JurisdictionsArray := SetupInput.ElementExists('taxJurisdictions', ElementExists);
        if not ElementExists then
            exit;

        for i := 0 to JurisdictionsArray.GetElementCount() - 1 do begin
            JurisdictionInput := JurisdictionsArray.ElementAt(i);

            TaxJurisdiction.Init();
            TaxJurisdiction.Code := CopyStr(JurisdictionInput.Element('Code').ValueAsText(), 1, MaxStrLen(TaxJurisdiction.Code));
            if not TaxJurisdiction.Get(TaxJurisdiction.Code) then begin
                JurisdictionInput.ElementExists('Description', ElementExists);
                if ElementExists then
                    TaxJurisdiction.Description := CopyStr(JurisdictionInput.Element('Description').ValueAsText(), 1, MaxStrLen(TaxJurisdiction.Description));

                JurisdictionInput.ElementExists('Country/Region Code', ElementExists);
                if ElementExists then
                    Evaluate(TaxJurisdiction."Country/Region", JurisdictionInput.Element('Country/Region Code').ValueAsText());

                TaxJurisdiction.Insert(true);
            end;
        end;
    end;

    internal procedure SetupOrder(SetupInput: Codeunit "Test Input Json"; Shop: Record "Shpfy Shop"): Record "Shpfy Order Header"
    var
        OrderHeader: Record "Shpfy Order Header";
        AddressInput: Codeunit "Test Input Json";
        OrderLinesArray: Codeunit "Test Input Json";
        ElementExists: Boolean;
    begin
        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := GetNextOrderId();
        OrderHeader."Shop Code" := Shop.Code;

        AddressInput := SetupInput.Element('orderAddress');
        OrderHeader."Ship-to Country/Region Code" := CopyStr(AddressInput.Element('countryRegionCode').ValueAsText(), 1, MaxStrLen(OrderHeader."Ship-to Country/Region Code"));

        AddressInput.ElementExists('county', ElementExists);
        if ElementExists then
            OrderHeader."Ship-to County" := CopyStr(AddressInput.Element('county').ValueAsText(), 1, MaxStrLen(OrderHeader."Ship-to County"));

        AddressInput.ElementExists('city', ElementExists);
        if ElementExists then
            OrderHeader."Ship-to City" := CopyStr(AddressInput.Element('city').ValueAsText(), 1, MaxStrLen(OrderHeader."Ship-to City"));

        SetupInput.ElementExists('documentDate', ElementExists);
        if ElementExists then
            Evaluate(OrderHeader."Document Date", SetupInput.Element('documentDate').ValueAsText());

        SetupInput.ElementExists('existingTaxAreaCode', ElementExists);
        if ElementExists then
            OrderHeader."Tax Area Code" := CopyStr(SetupInput.Element('existingTaxAreaCode').ValueAsText(), 1, MaxStrLen(OrderHeader."Tax Area Code"));

        SetupInput.ElementExists('taxExempt', ElementExists);
        if ElementExists then
            OrderHeader."Tax Exempt" := SetupInput.Element('taxExempt').ValueAsBoolean();

        OrderHeader.Insert();

        // Create order lines and tax lines
        SetupInput.ElementExists('orderLines', ElementExists);
        if ElementExists then begin
            OrderLinesArray := SetupInput.Element('orderLines');
            CreateOrderLinesFromInput(OrderHeader, OrderLinesArray);
        end;

        exit(OrderHeader);
    end;

    local procedure CreateOrderLinesFromInput(OrderHeader: Record "Shpfy Order Header"; OrderLinesArray: Codeunit "Test Input Json")
    var
        OrderLine: Record "Shpfy Order Line";
        TaxLine: Record "Shpfy Order Tax Line";
        LineInput: Codeunit "Test Input Json";
        TaxLinesArray: Codeunit "Test Input Json";
        TaxLineInput: Codeunit "Test Input Json";
        ElementExists: Boolean;
        i: Integer;
        j: Integer;
        LineId: BigInteger;
        ItemNo: Code[20];
        TaxGroupCode: Code[20];
    begin
        for i := 0 to OrderLinesArray.GetElementCount() - 1 do begin
            LineInput := OrderLinesArray.ElementAt(i);
            Evaluate(LineId, LineInput.Element('lineId').ValueAsText());

            OrderLine.Init();
            OrderLine."Shopify Order Id" := OrderHeader."Shopify Order Id";
            OrderLine."Line Id" := LineId;

            LineInput.ElementExists('itemNo', ElementExists);
            if ElementExists then begin
                ItemNo := CopyStr(LineInput.Element('itemNo').ValueAsText(), 1, MaxStrLen(ItemNo));
                if ItemNo <> '' then begin
                    OrderLine."Item No." := ItemNo;

                    LineInput.ElementExists('taxGroupCode', ElementExists);
                    if ElementExists then
                        TaxGroupCode := CopyStr(LineInput.Element('taxGroupCode').ValueAsText(), 1, MaxStrLen(TaxGroupCode));

                    EnsureItem(ItemNo, TaxGroupCode);
                end;
            end;

            OrderLine.Insert();

            // Create tax lines
            LineInput.ElementExists('taxLines', ElementExists);
            if ElementExists then begin
                TaxLinesArray := LineInput.Element('taxLines');
                for j := 0 to TaxLinesArray.GetElementCount() - 1 do begin
                    TaxLineInput := TaxLinesArray.ElementAt(j);

                    TaxLine.Init();
                    TaxLine."Parent Id" := LineId;
                    Evaluate(TaxLine."Line No.", TaxLineInput.Element('lineNo').ValueAsText());
                    TaxLine.Title := CopyStr(TaxLineInput.Element('title').ValueAsText(), 1, MaxStrLen(TaxLine.Title));
                    TaxLine."Rate %" := TaxLineInput.Element('ratePct').ValueAsDecimal();
                    TaxLine."Channel Liable" := TaxLineInput.Element('channelLiable').ValueAsBoolean();
                    TaxLine.Insert();
                end;
            end;
        end;
    end;

    local procedure EnsureItem(ItemNo: Code[20]; TaxGroupCode: Code[20])
    var
        Item: Record Item;
        TaxGroup: Record "Tax Group";
    begin
        if Item.Get(ItemNo) then
            exit;

        // Ensure tax group exists
        if (TaxGroupCode <> '') and not TaxGroup.Get(TaxGroupCode) then begin
            TaxGroup.Init();
            TaxGroup.Code := TaxGroupCode;
            TaxGroup.Description := TaxGroupCode;
            TaxGroup.Insert(true);
        end;

        Item.Init();
        Item."No." := ItemNo;
        Item.Description := ItemNo;
        Item."Tax Group Code" := TaxGroupCode;
        Item.Insert(true);
    end;

    internal procedure SetupExistingTaxAreas(AreasArray: Codeunit "Test Input Json")
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        AreaInput: Codeunit "Test Input Json";
        JurisdictionsArray: Codeunit "Test Input Json";
        AreaCode: Code[20];
        JurisdictionCode: Code[10];
        i: Integer;
        j: Integer;
        CalcOrder: Integer;
    begin
        for i := 0 to AreasArray.GetElementCount() - 1 do begin
            AreaInput := AreasArray.ElementAt(i);
            AreaCode := CopyStr(AreaInput.Element('Code').ValueAsText(), 1, MaxStrLen(AreaCode));

            if not TaxArea.Get(AreaCode) then begin
                TaxArea.Init();
                TaxArea.Code := AreaCode;
                TaxArea.Description := CopyStr(AreaInput.Element('Description').ValueAsText(), 1, MaxStrLen(TaxArea.Description));
                TaxArea.Insert(true);
            end;

            JurisdictionsArray := AreaInput.Element('jurisdictions');
            CalcOrder := 0;
            for j := 0 to JurisdictionsArray.GetElementCount() - 1 do begin
                CalcOrder += 1;
                JurisdictionCode := CopyStr(JurisdictionsArray.ElementAt(j).ValueAsText(), 1, MaxStrLen(JurisdictionCode));

                EnsureJurisdictionExists(JurisdictionCode);

                TaxAreaLine.Init();
                TaxAreaLine."Tax Area" := AreaCode;
                TaxAreaLine."Tax Jurisdiction Code" := JurisdictionCode;
                TaxAreaLine."Calculation Order" := CalcOrder;
                if not TaxAreaLine.Find() then
                    TaxAreaLine.Insert(true);
            end;
        end;
    end;

    local procedure EnsureJurisdictionExists(JurisdictionCode: Code[10])
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        if TaxJurisdiction.Get(JurisdictionCode) then
            exit;

        TaxJurisdiction.Init();
        TaxJurisdiction.Code := JurisdictionCode;
        TaxJurisdiction.Description := JurisdictionCode;
        TaxJurisdiction.Insert(true);
    end;

    internal procedure SetupExistingTaxDetails(DetailsArray: Codeunit "Test Input Json")
    var
        TaxDetail: Record "Tax Detail";
        DetailInput: Codeunit "Test Input Json";
        ElementExists: Boolean;
        i: Integer;
    begin
        for i := 0 to DetailsArray.GetElementCount() - 1 do begin
            DetailInput := DetailsArray.ElementAt(i);

            TaxDetail.Init();
            TaxDetail."Tax Jurisdiction Code" := CopyStr(DetailInput.Element('Tax Jurisdiction Code').ValueAsText(), 1, MaxStrLen(TaxDetail."Tax Jurisdiction Code"));
            TaxDetail."Tax Group Code" := CopyStr(DetailInput.Element('Tax Group Code').ValueAsText(), 1, MaxStrLen(TaxDetail."Tax Group Code"));
            TaxDetail."Tax Below Maximum" := DetailInput.Element('Tax Below Maximum').ValueAsDecimal();

            DetailInput.ElementExists('Effective Date', ElementExists);
            if ElementExists then
                Evaluate(TaxDetail."Effective Date", DetailInput.Element('Effective Date').ValueAsText());

            TaxDetail."Tax Type" := TaxDetail."Tax Type"::"Sales and Use Tax";
            TaxDetail.Insert(true);
        end;
    end;

    internal procedure CleanupTestData()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
        TaxLine: Record "Shpfy Order Tax Line";
        Shop: Record "Shpfy Shop";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        TaxGroup: Record "Tax Group";
        Item: Record Item;
    begin
        TaxLine.DeleteAll();
        OrderLine.DeleteAll();
        OrderHeader.DeleteAll();
        Shop.SetRange(Code, ShopCodeTok);
        Shop.DeleteAll();
        TaxAreaLine.DeleteAll();
        TaxArea.DeleteAll();
        TaxDetail.DeleteAll();
        TaxJurisdiction.DeleteAll();
        TaxGroup.DeleteAll();
        Item.DeleteAll();
    end;

    local procedure GetNextOrderId(): BigInteger
    begin
        NextOrderId += 1;
        exit(900000000 + NextOrderId);
    end;

    var
        NextOrderId: BigInteger;
}
