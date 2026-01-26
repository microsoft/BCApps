codeunit 101277 "Create Bank Acc. Posting Group"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
            InsertData(XLCY, '992920');
            InsertData(XLCY2, '992940');
            InsertData(XCURRENCIES, '992930');
            InsertData(XOPERATING, '995310');
            InsertData(CreateCashDeskCZP.GetCashDeskCode('XCD01'), '992910'); // NAVCZ
        end else begin
            // NAVCZ
            InsertData(XCASHDESK, '992910');
            InsertData(XCREDIT, '995310');
            // NAVCZ
        end;

        // NAVCZ
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Evaluation then begin
            InsertData(XNBL, '992920');
            InsertData(XWWB, '992930');
        end;
        // NAVCZ
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        "Bank Acc. Posting Group": Record "Bank Account Posting Group";
        CreateCashDeskCZP: Codeunit "Create Cash Desk CZP";
        CA: Codeunit "Make Adjustments";
        XLCY: Label 'LCY';
        XLCY2: Label 'LCY2';
        XCURRENCIES: Label 'CURRENCIES';
        XOPERATING: Label 'OPERATING', Comment = 'To be translated.';
        XWWB: Label 'WWB', Comment = 'To be translated.';
        XNBL: Label 'NBL', Comment = 'To be translated.';
        XCASHDESK: Label 'CASHDESK', Comment = 'To be translated.';
        XCREDIT: Label 'CREDIT', Comment = 'To be translated.';

    procedure InsertData("Code": Code[20]; "G/L Account No.": Code[20])
    begin
        "Bank Acc. Posting Group".Init();
        "Bank Acc. Posting Group".Validate(Code, Code);
        "Bank Acc. Posting Group".Validate("G/L Account No.", CA.Convert("G/L Account No."));
        "Bank Acc. Posting Group".Insert();
    end;

    procedure GetBankAccPostingGroup(BankAccPostingGroup: Text): Code[20]
    begin
        case UpperCase(BankAccPostingGroup) of
            'XLCY':
                exit(XLCY);
            'XLCY2':
                exit(XLCY2);
            'XCURRENCIES':
                exit(XCURRENCIES);
            'XOPERATING':
                exit(XOPERATING);
            'XWWB':
                exit(XWWB);
            'XNBL':
                exit(XNBL);
            'XCASHDESK':
                exit(XCASHDESK);
            'XCREDIT':
                exit(XCREDIT);
        end
    end;
}
