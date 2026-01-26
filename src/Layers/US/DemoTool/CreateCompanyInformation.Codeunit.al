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
        XCRONUSInternationalLtd: Label 'CRONUS USA, Inc.';
        XCRONUSMiniInternationalLtdTxt: Label 'CRONUS', Comment = 'Should be localized. E.g. In DK should be CRONUS Danmark.';
        X5TheRing: Label '7122 South Ashford Street';
        XWestminster: Label 'Westminster';
        X06666666666: Label '+1 425 555 0100';
        X06666666660: Label '+1 425 555 0101';
        X8889999: Label '888-9999';
        XWorldWideBank: Label 'World Wide Bank';
        XBG99999: Label 'BG99999';
        X9999888: Label '99-99-888';
        XGB12CPBK08929965044991: Label 'GB 12 CPBK 08929965044991';
        X9999999: Label '99-99-999';
        XContactNameTxt: Label 'Adam Matteson';

    procedure InsertData()
    var
        CreatePostCode: Codeunit "Create Post Code";
        CreateTaxAreas: Codeunit "Create Tax Areas";
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
        CompanyInformation.County := CreatePostCode.GetCounty(CompanyInformation."Post Code", CompanyInformation.City);
        CompanyInformation.Validate("Contact Person", XContactNameTxt);
        CompanyInformation.Validate("Phone No.", X06666666666);
        CompanyInformation.Validate("Fax No.", X06666666660);
        CompanyInformation.Validate("Giro No.", X8889999);
        CompanyInformation.Validate("Bank Name", XWorldWideBank);
        CompanyInformation.Validate("Bank Branch No.", XBG99999);
        CompanyInformation.Validate("Bank Account No.", X9999888);
        CompanyInformation.Validate(IBAN, XGB12CPBK08929965044991);
        CompanyInformation.Validate("Payment Routing No.", X9999999);
        CompanyInformation."System Indicator Style" := CompanyInformation."System Indicator Style"::Standard;
        CompanyInformation."System Indicator" := CompanyInformation."System Indicator"::None;

        CompanyInformation.Validate("Ship-to Name", XCRONUSInternationalLtd);
        CompanyInformation.Validate("Ship-to Address", X5TheRing);
        CompanyInformation.Validate("Ship-to Address 2", XWestminster);
        CompanyInformation.Validate("Ship-to Country/Region Code", DemoDataSetup."Country/Region Code");
        CompanyInformation."Ship-to Post Code" := CreatePostCode.FindPostCode(CreatePostCode.Convert('GB-W2 8HG'));
        CompanyInformation."Ship-to City" := CreatePostCode.FindCity(CompanyInformation."Ship-to Post Code");

        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Evaluation then
            CompanyInformation."Tax Area Code" := CreateTaxAreas.GetAtlantaGACode();

        CompanyInformation.Picture.Import(DemoDataSetup."Path to Picture Folder" + 'cronus.jpg');

        CompanyInformation.Insert();
    end;

    procedure InsertMiniAppData()
    begin
        if CompanyInformation.Get() then
            CompanyInformation.Delete();

        CompanyInformation.Init();
        CompanyInformation.Validate("Primary Key", '');
        CompanyInformation.Validate(Name, XCRONUSMiniInternationalLtdTxt);

        CompanyInformation.Insert();
    end;
}

