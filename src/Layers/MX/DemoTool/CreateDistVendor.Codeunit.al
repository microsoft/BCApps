codeunit 118843 "Create Dist. Vendor"
{

    trigger OnRun()
    var
        CreatePostCode: Codeunit "Create Post Code";
    begin
        DemoDataSetup.Get();
        InsertData(
          '60000', XGrassblueLtd, X8OneWay, CreatePostCode.Convert('GB-N12 5XY'), DemoDataSetup."Country/Region Code",
          XGrassblueLtd, XRB, XLondon, DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), 0, XCOD, 1, XWHITE, XCIF, '');
        InsertData(
          '61000', XElectronicsLtd, X354OxfordStreet, CreatePostCode.Convert('GB-N16 34Z'), DemoDataSetup."Country/Region Code",
          XElectronicsLtd, XRB, XLondon, DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), 0, XCOD, 2, XWHITE, XCPT, '');
        InsertData(
          '62000', XWalkerHolland, X116KensingtonRoad, CreatePostCode.Convert('GB-WC1 3DG'), DemoDataSetup."Country/Region Code",
          XWalkerHolland, XRB, XLondon, DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), 0, XCOD, 3, XWHITE, XCFR, '');
    end;

    var
        XGrassblueLtd: Label 'Grassblue Ltd.';
        X8OneWay: Label '8 One Way';
        XLondon: Label 'London';
        XRB: Label 'RB';
        XCOD: Label 'COD';
        XWHITE: Label 'WHITE';
        XCIF: Label 'CIF';
        XCPT: Label 'CPT';
        XCFR: Label 'CFR';
        XElectronicsLtd: Label 'Electronics Ltd.';
        X354OxfordStreet: Label '354 Oxford Street';
        XWalkerHolland: Label 'WalkerHolland';
        X116KensingtonRoad: Label '116 Kensington Road';
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData(No: Code[20]; Name: Text[30]; Address: Text[30]; "Post Code": Text[30]; CountryCode: Code[10]; SearchName: Code[30]; PurchaserCode: Code[10]; RespCenterCode: Code[10]; GenBusPostGrCode: Code[10]; VATBusPostGrCode: Code[10]; CustPostingGroupCode: Code[10]; ApplMethod: Option; PaymentTermCode: Code[10]; Priority: Decimal; LocationCode: Code[10]; ShipMethodCode: Code[10]; CurrencyCode: Code[10])
    var
        Vendor: Record Vendor;
        CreatePostCode: Codeunit "Create Post Code";
    begin
        if CountryCode = DemoDataSetup."Country/Region Code" then
            CountryCode := '';
        Vendor.Init();
        Vendor.Validate("No.", No);
        Vendor.Validate(Name, Name);
        Vendor.Validate(Address, Address);
        Vendor.Validate("Country/Region Code", CountryCode);
        Vendor."Post Code" := CreatePostCode.FindPostCode("Post Code");
        Vendor.City := CreatePostCode.FindCity("Post Code");
        Vendor.Validate("Search Name", SearchName);
        Vendor.Validate("Purchaser Code", PurchaserCode);
        Vendor.Validate("Responsibility Center", RespCenterCode);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostGrCode);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostGrCode);
        Vendor.Validate("Vendor Posting Group", CustPostingGroupCode);
        Vendor.Validate("Application Method", ApplMethod);
        Vendor.Validate("Payment Terms Code", PaymentTermCode);
        Vendor.Validate(Priority, Priority);
        Vendor.Validate("Location Code", LocationCode);
        Vendor.Validate("Shipment Method Code", ShipMethodCode);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Validate(County, CreatePostCode.GetCounty(Vendor."Post Code", Vendor.City));
        Vendor.Insert(true);
    end;
}

