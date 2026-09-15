codeunit 118842 "Create Dist. Customer"
{

    trigger OnRun()
    var
        CreatePostCode: Codeunit "Create Post Code";
    begin
        DemoDataSetup.Get();
        InsertData(
          '60000', XBlanemarkHifiShop, X28BakerStreet, CreatePostCode.Convert('GB-W1 3AL'), DemoDataSetup."Country/Region Code",
          XBlanemarkHifiShop, XOF, XLondon, DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), 0, X1M8D, DemoDataSetup.DomesticCode(), X1POINT5DOM, XWHITE);
        InsertData(
          '61000', XFairwaySound, X159Fairway, CreatePostCode.Convert('GB-W2 8HG'), DemoDataSetup."Country/Region Code",
          XFairwaySound, XJO, XLondon, DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), 0, X1M8D, DemoDataSetup.DomesticCode(), X1POINT5DOM, XWHITE);
        InsertData(
          '62000', XTheDeviceShop, X273BasinStreet, CreatePostCode.Convert('GB-N16 34Z'), DemoDataSetup."Country/Region Code",
          XTheDeviceShop, XJO, XLondon, DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), 0, X14Days, DemoDataSetup.DomesticCode(), X1POINT5DOM, XWHITE);

        ModifyData('60000', true, 1, 0, XEXW, 'DHL');
        ModifyData('61000', true, 1, 1, XEXW, 'FEDEX');
        ModifyData('62000', true, 1, 0, XEXW, 'UPS');
    end;

    var
        XBlanemarkHifiShop: Label 'Blanemark Hifi Shop';
        X28BakerStreet: Label '28 Baker Street';
        XLondon: Label 'London';
        XOF: Label 'OF';
        XFairwaySound: Label 'Fairway Sound';
        X159Fairway: Label '159 Fairway';
        XJO: Label 'JO';
        X1POINT5DOM: Label '1.5 DOM.';
        XWHITE: Label 'WHITE';
        XTheDeviceShop: Label 'The Device Shop';
        X273BasinStreet: Label '273 Basin Street';
        X14Days: Label '14 Days';
        X1M8D: Label '1M(8D)';
        XEXW: Label 'EXW';
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData(No: Code[20]; Name: Text[30]; Address: Text[30]; "Post Code": Text[30]; CountryCode: Code[10]; SearchName: Code[30]; SalesPersonCode: Code[10]; RespCenterCode: Code[10]; GenBusPostGrCode: Code[10]; VATBusPostGrCode: Code[10]; CustPostingGroupCode: Code[10]; ApplMethod: Option; PaymentTermCode: Code[10]; ReminderTermsCode: Code[10]; FinChargeTerms: Code[10]; LocationCode: Code[10])
    var
        Customer: Record Customer;
        CreatePostCode: Codeunit "Create Post Code";
    begin
        if CountryCode = DemoDataSetup."Country/Region Code" then
            CountryCode := '';
        Customer.Init();
        Customer.Validate("No.", No);
        Customer.Validate(Name, Name);
        Customer.Validate(Address, Address);
        Customer.Validate("Country/Region Code", CountryCode);
        Customer."Post Code" := CreatePostCode.FindPostCode("Post Code");
        Customer.City := CreatePostCode.FindCity("Post Code");
        Customer.Validate("Search Name", SearchName);
        Customer.Validate("Salesperson Code", SalesPersonCode);
        Customer.Validate("Responsibility Center", RespCenterCode);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostGrCode);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostGrCode);
        Customer.Validate("Customer Posting Group", CustPostingGroupCode);
        Customer.Validate("Application Method", ApplMethod);
        Customer.Validate("Payment Terms Code", PaymentTermCode);
        Customer.Validate("Reminder Terms Code", ReminderTermsCode);
        Customer.Validate("Fin. Charge Terms Code", FinChargeTerms);
        Customer.Validate("Location Code", LocationCode);
        Customer.Validate(County, CreatePostCode.GetCounty(Customer."Post Code", Customer.City));
        Customer.Insert(true);
    end;

    procedure ModifyData(No: Code[20]; CombShipment: Boolean; Reserve: Option; ShippingAdvice: Option; ShipMethodCode: Code[10]; ShipAgentCode: Code[10])
    var
        Customer: Record Customer;
    begin
        Customer.Get(No);
        Customer.Validate("Combine Shipments", CombShipment);
        Customer.Validate(Reserve, Reserve);
        Customer.Validate("Shipping Advice", ShippingAdvice);
        Customer.Validate("Shipment Method Code", ShipMethodCode);
        Customer.Validate("Shipping Agent Code", ShipAgentCode);
        Customer.Modify(true);
    end;
}

