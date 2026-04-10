codeunit 101079 "Create Company Information"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData();
        InsertLegal();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CompanyInformation: Record "Company Information";
        CA: Codeunit "Make Adjustments";
        XCRONUSInternationalLtd: Label 'CRONUS International Ltd.';
        X5TheRing: Label '5 The Ring';
        XGB12CPBK08929965044991: Label 'GB 12 CPBK 08929965044991';
        X9999999: Label '99-99-999';
        XContactNameTxt: Label 'Adam Matteson';
        XCitibank: Label 'Citibank';
        XMoscow: Label 'Moscow';
        XEH: Label 'EH';
        XEsterHenderson: Label 'Ester Henderson';
        XOF: Label 'OF';
        XOtisFalls: Label 'Otis Falls';
        XRU: Label 'RU';
        XTrade: Label 'Trade';
        XLEGAL: Label 'LEGAL';

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
        CompanyInformation.Validate("Address 2", '');
        CompanyInformation.Validate("Country/Region Code", XRU);
        CompanyInformation."Post Code" := CreatePostCode.FindPostCode(CreatePostCode.Convert('GB-W2 8HG'));
        CompanyInformation.City := CreatePostCode.FindCity(CompanyInformation."Post Code");
        CompanyInformation.Validate("Contact Person", XContactNameTxt);
        CompanyInformation.Validate("Phone No.", '(7 495) 7251000');
        CompanyInformation.Validate("Fax No.", '(7 495) 7251001');
        CompanyInformation.Validate("Giro No.", '');
        CompanyInformation.Validate("Bank Name", XCitibank);
        CompanyInformation.Validate("Bank Branch No.", '');
        CompanyInformation.Validate("Bank Account No.", '40702810700700700001');
        CompanyInformation.Validate(IBAN, XGB12CPBK08929965044991);
        CompanyInformation.Validate("Payment Routing No.", X9999999);
        CompanyInformation."System Indicator Style" := CompanyInformation."System Indicator Style"::Standard;
        CompanyInformation."System Indicator" := CompanyInformation."System Indicator"::None;
        CompanyInformation."VAT Registration No." := '7709319150';
        CompanyInformation."Registration Date" := CA.AdjustDate(19010101D);
        CompanyInformation."Principal Activity" := XTrade;
        CompanyInformation."Primary Activity" := XTrade;
        CompanyInformation."Pension Fund Registration No." := '123-456-789101';
        CompanyInformation."OKPO Code" := '55190105';
        CompanyInformation."OKVED Code" := '65.23.3';
        CompanyInformation."Bank Corresp. Account No." := '30101810300000000202';
        CompanyInformation."Bank BIC" := '044525202';
        CompanyInformation."KPP Code" := '770901001';
        CompanyInformation."OKATO Code" := '45286575000';
        CompanyInformation."Bank City" := XMoscow;
        if not DemoDataSetup."Skip creation of master data" then begin
            CompanyInformation."Director No." := XOF;
            CompanyInformation."Director Name" := XOtisFalls;
            CompanyInformation."Accountant No." := XEH;
            CompanyInformation."Accountant Name" := XEsterHenderson;
            CompanyInformation."HR Manager No." := XEH;
        end;

        CompanyInformation.Validate("Ship-to Name", XCRONUSInternationalLtd);
        CompanyInformation.Validate("Ship-to Address", X5TheRing);
        CompanyInformation.Validate("Ship-to Address 2", '');
        CompanyInformation.Validate("Ship-to Country/Region Code", XRU);
        CompanyInformation."Ship-to Post Code" := CreatePostCode.FindPostCode(CreatePostCode.Convert('GB-W2 8HG'));
        CompanyInformation."Ship-to City" := CreatePostCode.FindCity(CompanyInformation."Ship-to Post Code");
        CompanyInformation.Picture.Import(DemoDataSetup."Path to Picture Folder" + 'cronus.jpg');

        CompanyInformation.Insert();
    end;

    procedure InsertLegal()
    var
        "Company Address": Record "Company Address";
    begin
        CompanyInformation.Get();
        "Company Address".Init();
        "Company Address".Code := XLEGAL;
        "Company Address"."Language Code" := 'RUS';
        "Company Address".Name := CompanyInformation.Name;
        "Company Address"."Name 2" := CompanyInformation."Name 2";
        "Company Address".Address := CompanyInformation.Address;
        "Company Address"."Address 2" := CompanyInformation."Address 2";
        "Company Address".City := CompanyInformation.City;
        "Company Address"."Phone No." := CompanyInformation."Phone No.";
        "Company Address"."Telex No." := CompanyInformation."Telex No.";
        "Company Address"."Registration No." := CompanyInformation."Registration No.";
        "Company Address"."Region Code" := CompanyInformation."Region Code";
        "Company Address".Street := CompanyInformation.Street;
        "Company Address".House := CompanyInformation.House;
        "Company Address".Building := CompanyInformation.Building;
        "Company Address".Apartment := CompanyInformation.Apartment;
        "Company Address"."Address Type" := "Company Address"."Address Type"::Legal;
        "Company Address"."Country/Region Code" := CompanyInformation."Country/Region Code";
        "Company Address"."Fax No." := CompanyInformation."Fax No.";
        "Company Address"."Post Code" := CompanyInformation."Post Code";
        "Company Address".County := CompanyInformation.County;
        "Company Address"."E-Mail" := CompanyInformation."E-Mail";
        "Company Address"."Home Page" := CompanyInformation."Home Page";
        "Company Address".OKPO := CompanyInformation."OKPO Code";
        "Company Address".KPP := CompanyInformation."KPP Code";
        "Company Address"."Director Phone No." := CompanyInformation."Phone No.";
        "Company Address"."Accountant Phone No." := CompanyInformation."Phone No.";
        "Company Address".Insert();
    end;
}

