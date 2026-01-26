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
        XCronusItaliaSpA: Label 'CRONUS Italia S.p.A.';
        XWorldWideBank: Label 'World Wide Bank';
        XBG99999: Label 'BG99999';
        XGB12CPBK08929965044991: Label 'GB 12 CPBK 08929965044991';
        XContactNameTxt: Label 'Adam Matteson';
        XVATRegNumber: Label '28051977200';
        XPiazzaDuomo1: Label 'Piazza Duomo, 1';
        XMilano: Label 'Milano';
        XxLND: Label 'LND';
        XxCRONUS: Label 'CRONUS';

    procedure InsertData()
    var
        CreatePostCode: Codeunit "Create Post Code";
    begin
        if CompanyInformation.Get() then
            CompanyInformation.Delete();

        CompanyInformation.Init();
        CompanyInformation."Demo Company" := true;
        CompanyInformation.Validate("Primary Key", '');
        CompanyInformation.Validate(Name, XCronusItaliaSpA);
        CompanyInformation.Validate(Address, XPiazzaDuomo1);
        CompanyInformation.Validate("Address 2", XMilano);
        CompanyInformation.Validate("Country/Region Code", DemoDataSetup."Country/Region Code");
        CompanyInformation."Post Code" := CreatePostCode.FindPostCode(CreatePostCode.Convert('GB-W2 8HG'));
        CompanyInformation.City := CreatePostCode.FindCity(CompanyInformation."Post Code");
        CompanyInformation.Validate("Contact Person", XContactNameTxt);
        CompanyInformation.Validate("Phone No.", '+39-02-660-6666');
        CompanyInformation.Validate("Fax No.", '+39-02-660-6660');
        CompanyInformation.Validate("Giro No.", '888-9999');
        CompanyInformation.Validate("Bank Name", XWorldWideBank);
        CompanyInformation.Validate("Bank Branch No.", XBG99999);
        CompanyInformation.Validate("Bank Account No.", '9999888');
        CompanyInformation.Validate(IBAN, XGB12CPBK08929965044991);
        CompanyInformation.Validate("Payment Routing No.", '99-99-999');
        CompanyInformation."System Indicator Style" := CompanyInformation."System Indicator Style"::Standard;
        CompanyInformation."System Indicator" := CompanyInformation."System Indicator"::None;

        CompanyInformation.Validate("Ship-to Name", XCronusItaliaSpA);
        CompanyInformation.Validate("Ship-to Address", XPiazzaDuomo1);
        CompanyInformation.Validate("Ship-to Address 2", XMilano);
        CompanyInformation.Validate("Ship-to Country/Region Code", DemoDataSetup."Country/Region Code");
        CompanyInformation."Ship-to Post Code" := CreatePostCode.FindPostCode(CreatePostCode.Convert('GB-W2 8HG'));
        CompanyInformation."Ship-to City" := CreatePostCode.FindCity(CompanyInformation."Ship-to Post Code");
        // BEGIN IT
        CompanyInformation.Validate("SIA Code", '12345');
        CompanyInformation.Validate("Authority County", XxLND);
        CompanyInformation.Validate("Autoriz. No.", '56701');
        CompanyInformation.Validate("Autoriz. Date", 20020101D);
        CompanyInformation.Validate("Signature on Bill", XxCRONUS);
        CompanyInformation."VAT Registration No." := XVATRegNumber;
        // END IT

        CompanyInformation.Picture.Import(DemoDataSetup."Path to Picture Folder" + 'cronus.jpg');

        CompanyInformation.Insert();
    end;

    procedure InsertMiniAppData()
    begin
        if CompanyInformation.Get() then
            CompanyInformation.Delete();

        CompanyInformation.Init();
        CompanyInformation.Validate("Primary Key", '');
        DemoDataSetup.Get();
        CompanyInformation.Validate("Country/Region Code", DemoDataSetup."Country/Region Code");
        CompanyInformation.Insert();
    end;
}

