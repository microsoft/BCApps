codeunit 161550 "Create Demodata ESR"
{

    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        d.Open(Text11504);
        if PaymentMethod.Get(Text11506) then begin
            PaymentMethod.Code := Text11506;
            PaymentMethod.Description := Text11507;
            PaymentMethod.Modify();
        end else begin
            PaymentMethod.Code := Text11506;
            PaymentMethod.Description := Text11507;
            PaymentMethod.Insert();
        end;

        Clear(PaymentMethod);
        if PaymentMethod.Get(Text11508) then begin
            PaymentMethod.Code := Text11508;
            PaymentMethod.Description := Text11509;
            PaymentMethod.Modify();
        end else begin
            PaymentMethod.Code := Text11508;
            PaymentMethod.Description := Text11509;
            PaymentMethod.Insert();
        end;

        CompanyInfo.Get();
        ESRSetup.Init();
        ESRSetup."Bank Code" := Text11510;
        ESRSetup."ESR System" := ESRSetup."ESR System"::ESR;
        ESRSetup."Bal. Account Type" := ESRSetup."Bal. Account Type"::"G/L Account";
        ESRSetup.Validate("Bal. Account No.", '1020');
        ESRSetup."ESR Filename" := 'c:\cronus.v11';
        ESRSetup.Validate("BESR Customer ID", '68705010000');
        ESRSetup.Validate("ESR Account No.", '01-13980-3');
        ESRSetup."ESR Currency Code" := 'EUR';
        ESRSetup."ESR Member Name 1" := Format(Text11512, -MaxStrLen(ESRSetup."ESR Member Name 1"));
        ESRSetup."ESR Member Name 2" := Format(Text11513, -MaxStrLen(ESRSetup."ESR Member Name 2"));
        ESRSetup."ESR Member Name 3" := Format(Text11514, -MaxStrLen(ESRSetup."ESR Member Name 3"));
        ESRSetup."Beneficiary Text" := Format(Text11515, -MaxStrLen(ESRSetup."Beneficiary Text"));

        ESRSetup.Beneficiary := Format(CompanyInfo.Name, -MaxStrLen(ESRSetup.Beneficiary));
        ESRSetup."Beneficiary 2" := Format(CompanyInfo.Address, -MaxStrLen(ESRSetup."Beneficiary 2"));
        ESRSetup."Beneficiary 3" := Format(CompanyInfo."Post Code" + ' ' + CompanyInfo.City, -MaxStrLen(ESRSetup."Beneficiary 3"));
        ESRSetup."Beneficiary 4" := '';
        ESRSetup."Backup Copy" := false;

        ESRSetup."ESR Payment Method Code" := Format(Text11506, -MaxStrLen(ESRSetup."ESR Payment Method Code"));
        ESRSetup."ESR Main Bank" := true;

        if not ESRSetup.Insert() then
            ESRSetup.Modify();

        ESRSetup.Init();
        ESRSetup."Bank Code" := Text11521;
        ESRSetup."ESR System" := ESRSetup."ESR System"::ESR;
        ESRSetup."Bal. Account Type" := ESRSetup."Bal. Account Type"::"G/L Account";
        ESRSetup.Validate("Bal. Account No.", '1010');
        ESRSetup."ESR Filename" := 'c:\cronus.v11';
        ESRSetup.Validate("BESR Customer ID", '00000000000');
        ESRSetup.Validate("ESR Account No.", '60-9-9');
        ESRSetup."ESR Member Name 1" := Format(CompanyInfo.Name, -MaxStrLen(ESRSetup."ESR Member Name 1"));
        ESRSetup."ESR Member Name 2" := Format(CompanyInfo.Address, -MaxStrLen(ESRSetup."ESR Member Name 2"));
        ESRSetup."ESR Member Name 3" := Format(CompanyInfo."Post Code" + ' ' + CompanyInfo.City, -MaxStrLen(ESRSetup."ESR Member Name 3"));
        ESRSetup."Beneficiary Text" := '';
        ESRSetup.Beneficiary := '';
        ESRSetup."Beneficiary 2" := '';
        ESRSetup."Beneficiary 3" := '';
        ESRSetup."Beneficiary 4" := '';
        ESRSetup."Backup Copy" := false;

        ESRSetup."ESR Payment Method Code" := Format(Text11508, -MaxStrLen(ESRSetup."ESR Payment Method Code"));
        ESRSetup."ESR Main Bank" := false;

        if not ESRSetup.Insert() then
            ESRSetup.Modify();
        DemoDataSetup.Get();
        d.Close();
    end;

    var
        Text11504: Label 'Generate ESR demo data';
        Text11506: Label 'ESR';
        Text11507: Label 'ESR with CS';
        Text11508: Label 'ESR POST';
        Text11509: Label 'ESR with POST';
        Text11510: Label 'NBL';
        Text11512: Label 'Zuger Kantonalbank';
        Text11513: Label 'Bahnhofstrasse 1';
        Text11514: Label '6301 Zug';
        Text11515: Label 'In favor:';
        Text11521: Label 'GIRO';
        ESRSetup: Record "ESR Setup";
        PaymentMethod: Record "Payment Method";
        CompanyInfo: Record "Company Information";
        d: Dialog;
}

