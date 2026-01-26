codeunit 101277 "Create Bank Acc. Posting Group"
{
    //   // GB replace LCY with DemoDataSetup."Currency Code"


    trigger OnRun()
    var
        CreateGLAccount: Codeunit "Create G/L Account";
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
            InsertData(DemoDataSetup."Currency Code", '992920');
            InsertData(DemoDataSetup."Currency Code" + '2', '992940');
            InsertData(XCURRENCIES, '992930');
            InsertData(XOPERATING, '995310');
        end else begin
            InsertData(XCHECKING, CreateGLAccount.BusinessaccountOperatingDomestic());
            InsertData(XSAVINGS, CreateGLAccount.Otherbankaccounts());
            InsertData(XCASH, CreateGLAccount.PettyCash());
            InsertData(XOPERATING, CreateGLAccount.PettyCash());
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        "Bank Acc. Posting Group": Record "Bank Account Posting Group";
        CA: Codeunit "Make Adjustments";
        XCURRENCIES: Label 'CURRENCIES';
        XOPERATING: Label 'OPERATING', Comment = 'To be translated.';
        XCHECKING: Label 'CHECKING', Comment = 'To be translated.';
        XSAVINGS: Label 'SAVINGS', Comment = 'To be translated.';
        XCASH: Label 'CASH', Comment = 'To be translated.';

    procedure InsertData("Code": Code[20]; "G/L Account No.": Code[20])
    begin
        "Bank Acc. Posting Group".Init();
        "Bank Acc. Posting Group".Validate(Code, Code);
        "Bank Acc. Posting Group".Validate("G/L Account No.", CA.Convert("G/L Account No."));
        "Bank Acc. Posting Group".Insert();
    end;
}

