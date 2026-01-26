codeunit 101079 "Create Company Information"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData();
        ModifyData();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CompanyInformation: Record "Company Information";
        XCRONUSInternationalLtd: Label 'CRONUS International Ltd.';
        X5TheRing: Label '5 The Ring';
        XWestminster: Label 'Westminster';
        X06666666666: Label '0666-666-6666';
        X06666666660: Label '0666-666-6660';
        X8889999: Label '888-9999';
        XWorldWideBank: Label 'World Wide Bank';
        XBG99999: Label 'BG99999';
        X9999888: Label '99-99-888';
        XGB12CPBK08929965044991: Label 'GB 12 CPBK 08929965044991';
        X9999999: Label '99-99-999';
        XContactNameTxt: Label 'Adam Matteson';
        XCOMPA0007I: Label 'COMPA0007I';
        XDELN03830B: Label 'DELN03830B';
        XA: Label 'A';
        XDL: Label 'DL';
        XU12345ND6789PLC09898: Label 'U12345ND6789PLC09898';
        XTheRing5: Label 'The Ring 5';
        XPatelNagar: Label 'Patel Nagar';
        XNewDelhi: Label 'New Delhi';
        X110001: Label 'IN-110001';
        XIN: Label 'IN';
        XBLU0897580: Label 'BLU0897580';

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
        CompanyInformation."VAT Registration No." := '777777777';

        CompanyInformation.Validate("Ship-to Name", XCRONUSInternationalLtd);
        CompanyInformation.Validate("Ship-to Address", X5TheRing);
        CompanyInformation.Validate("Ship-to Address 2", XWestminster);
        CompanyInformation.Validate("Ship-to Country/Region Code", DemoDataSetup."Country/Region Code");
        CompanyInformation."Ship-to Post Code" := CreatePostCode.FindPostCode(CreatePostCode.Convert('GB-W2 8HG'));
        CompanyInformation."Ship-to City" := CreatePostCode.FindCity(CompanyInformation."Ship-to Post Code");
        CompanyInformation.Picture.Import(DemoDataSetup."Path to Picture Folder" + 'cronus.jpg');

        CompanyInformation.Insert();
    end;

    local procedure ModifyData()
    begin
        if CompanyInformation.get() then begin
            CompanyInformation."P.A.N. No." := XCOMPA0007I;
            CompanyInformation."T.A.N. No." := XBLU0897580;
            CompanyInformation."Deductor Category" := XA;
            CompanyInformation."Ministry Type" := CompanyInformation."Ministry Type"::Regular;
            CompanyInformation."State Code" := XDL;
            CompanyInformation."Registration No." := XU12345ND6789PLC09898;
            CompanyInformation.Address := XTheRing5;
            CompanyInformation."Address 2" := XPatelNagar;
            CompanyInformation.City := XNewDelhi;
            CompanyInformation."Post Code" := X110001;
            CompanyInformation."Country/Region Code" := XIN;
            CompanyInformation."Circle No." := '10';
            CompanyInformation."Ward No." := '70B';
            CompanyInformation."Assessing Officer" := 'James';
            CompanyInformation."Company Status" := CompanyInformation."Company Status"::Government;
            CompanyInformation."Registration No." := 'U12345ND6789PLC09898';
            CompanyInformation."DDO Code" := 'A';
            CompanyInformation."DDO Registration No." := '1212234';
            CompanyInformation."PAO Code" := 'A';
            CompanyInformation."PAO Registration No." := '12121';
            CompanyInformation."Ministry Type" := CompanyInformation."Ministry Type"::Regular;
            CompanyInformation."Ministry Code" := '01';
            CompanyInformation."T.C.A.N. No." := XDELN03830B;
            CompanyInformation."State Code" := 'DL';
            CompanyInformation."GST Registration No." := '07COMPA0007I1Z1';
            CompanyInformation.Modify();
        end;
    end;
}
