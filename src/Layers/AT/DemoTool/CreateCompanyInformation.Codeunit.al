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
        X5KarlRenner: Label 'Dr. Karl Renner';
        X5Ring3: Label 'Ring 3';
        X8889999: Label '888-9999';
        XWorldWideBank: Label 'World Wide Bank';
        XBG99999: Label 'BG99999';
        X9999888: Label '99-99-888';
        XGB12CPBK08929965044991: Label 'GB 12 CPBK 08929965044991';
        X9999999: Label '99-99-999';
        XContactNameTxt: Label 'Adam Matteson';
        X9999999999: Label '999 / 9 99 99 99';
        X9999999990: Label '999 / 9 99 99 90';
        XAT1010: Label 'AT-1010';
        XAT: Label 'AT';
        XATU12345678: Label 'ATU12345678';

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
        CompanyInformation.Validate(Address, X5KarlRenner);
        CompanyInformation.Validate("Address 2", X5Ring3);
        CompanyInformation.Validate("Country/Region Code", XAT);
        CompanyInformation."Post Code" := CreatePostCode.FindPostCode('AT-1100');
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
        CompanyInformation."VAT Registration No." := XATU12345678;
        CompanyInformation.Validate("Sales Authorized No.", 'VK');
        CompanyInformation.Validate("Purch. Authorized No.", 'EK');
        CompanyInformation.Validate("Registration No.", '123/4567');
        CompanyInformation.Validate("Tax Office Name", 'Finanzamt f. d. 24. Bezirk');
        CompanyInformation.Validate("Tax Office Address", 'Hohe Weide 101');
        CompanyInformation."Tax Office Post Code" := CreatePostCode.FindPostCode(XAT1010);
        CompanyInformation."Tax Office City" := CreatePostCode.FindCity(CompanyInformation."Tax Office Post Code");
        CompanyInformation.Validate("Tax Office Number", '99');

        CompanyInformation.Validate("Ship-to Name", XCRONUSInternationalLtd);
        CompanyInformation.Validate("Ship-to Address", X5KarlRenner);
        CompanyInformation.Validate("Ship-to Address 2", X5Ring3);
        CompanyInformation.Validate("Ship-to Country/Region Code", XAT);
        CompanyInformation."Ship-to Post Code" := CreatePostCode.FindPostCode('AT-1100');
        CompanyInformation."Ship-to City" := CreatePostCode.FindCity(CompanyInformation."Ship-to Post Code");
        CompanyInformation.Picture.Import(DemoDataSetup."Path to Picture Folder" + 'cronus.jpg');

        CompanyInformation.Insert();
    end;
}

