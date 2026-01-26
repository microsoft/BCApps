codeunit 101079 "Create Company Information"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CompanyInformation: Record "Company Information";
        XCRONUSInternationalLtd: Label 'CRONUS International Ltd.';
        X5TheRing: Label '5 The Ring';
        XWestminster: Label 'Westminster';
        X8889999: Label '888-9999';
        XWorldWideBank: Label 'World Wide Bank';
        XBG99999: Label 'BG99999';
        X9999888: Label '99-99-888';
        XGB12CPBK08929965044991: Label 'GB 12 CPBK 08929965044991';
        X9999999: Label '99-99-999';
        XContactNameTxt: Label 'Adam Matteson';
        X9999999999: Label '999 / 9 99 99 99';
        X9999999990: Label '999 / 9 99 99 90';
        XKATHERINEHULL: Label 'KATHERINE HULL';

    procedure InsertData()
    var
        CreatePostCode: Codeunit "Create Post Code";
    begin
        if CompanyInformation.Get() then
            CompanyInformation.Delete();

        CompanyInformation.Init();
        CompanyInformation."Demo Company" := true;
        CompanyInformation.Validate("Primary Key", '');
        CompanyInformation.Validate(Name, XCRONUSInternationalLtd);
        CompanyInformation.Validate(Address, X5TheRing);
        CompanyInformation.Validate("Address 2", XWestminster);
        CompanyInformation.Validate("Country/Region Code", DemoDataSetup."Country/Region Code");
        CompanyInformation."Post Code" := CreatePostCode.FindPostCode(CreatePostCode.Convert('GB-W2 8HG'));
        CompanyInformation.City := CreatePostCode.FindCity(CompanyInformation."Post Code");
        CompanyInformation.Validate("Contact Person", XContactNameTxt);
        CompanyInformation.Validate("Phone No.", X9999999999);
        CompanyInformation.Validate("Fax No.", X9999999990);
        CompanyInformation.Validate("Giro No.", X8889999);
        CompanyInformation.Validate("Bank Name", XWorldWideBank);
        CompanyInformation.Validate("Bank Branch No.", XBG99999);
        CompanyInformation.Validate("Bank Account No.", X9999888);
        CompanyInformation.Validate(IBAN, XGB12CPBK08929965044991);
        CompanyInformation.Validate("Payment Routing No.", X9999999);
        CompanyInformation."System Indicator Style" := CompanyInformation."System Indicator Style"::Standard;
        CompanyInformation."System Indicator" := CompanyInformation."System Indicator"::None;
        CompanyInformation."VAT Registration No." := '777777777';
        CompanyInformation.Validate(Area, '02');
        CompanyInformation.Validate("Place of Dispatcher", '1');
        CompanyInformation.Validate("Place of Receiver", '1');
        CompanyInformation.Validate("Sales Authorized No.", 'XYZ123');
        CompanyInformation.Validate("Purch. Authorized No.", 'ABC987');
        CompanyInformation.Validate("Registration No.", '11/222/33333');
        CompanyInformation.Validate("VAT Representative", XKATHERINEHULL);
        CompanyInformation.Validate("Tax Office Name", 'Finanzamt Hamburg Mitte');
        CompanyInformation.Validate("Tax Office Address", 'Hohe Weide 101');
        CompanyInformation."Tax Office Post Code" := CreatePostCode.FindPostCode('DE-22417');
        CompanyInformation."Tax Office City" := CreatePostCode.FindCity(CompanyInformation."Tax Office Post Code");
        CompanyInformation.Validate("Tax Office Area", CompanyInformation."Tax Office Area"::Hamburg);
        CompanyInformation."Tax Office Number" := '2710';

        CompanyInformation.Validate("Ship-to Name", XCRONUSInternationalLtd);
        CompanyInformation.Validate("Ship-to Address", X5TheRing);
        CompanyInformation.Validate("Ship-to Address 2", XWestminster);
        CompanyInformation.Validate("Ship-to Country/Region Code", DemoDataSetup."Country/Region Code");
        CompanyInformation."Ship-to Post Code" := CreatePostCode.FindPostCode(CreatePostCode.Convert('GB-W2 8HG'));
        CompanyInformation."Ship-to City" := CreatePostCode.FindCity(CompanyInformation."Ship-to Post Code");
        CompanyInformation.Picture.Import(DemoDataSetup."Path to Picture Folder" + 'cronus.jpg');

        CompanyInformation.Insert();
    end;
}

