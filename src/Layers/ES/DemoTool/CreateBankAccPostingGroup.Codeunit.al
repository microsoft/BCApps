codeunit 101277 "Create Bank Acc. Posting Group"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
            InsertData(XLCY, '992920', '5208001', '6260001', '999250', '6691002', '5208002');
            InsertData(XLCY2, '992920', '5208001', '6260001', '999250', '6691002', '5208002');
            InsertData(XCURRENCIES, '992930', '', '6260001', '', '', '');
            InsertData(XOPERATING, '995310', '5208001', '6260001', '999250', '6691002', '5208002');
        end else begin
            InsertData(XCHECKING, '992920', '5208001', '6260001', '999250', '6691002', '5208002');
            InsertData(XSAVINGS, '992920', '5208001', '6260001', '999250', '6691002', '5208002');
            InsertData(XCASH, '995310', '5208001', '6260001', '999250', '6691002', '5208002');
            InsertData(XOPERATING, '995310', '5208001', '6260001', '999250', '6691002', '5208002');
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        "Bank Acc. Posting Group": Record "Bank Account Posting Group";
        CA: Codeunit "Make Adjustments";
        XLCY: Label 'LCY';
        XLCY2: Label 'LCY2';
        XCURRENCIES: Label 'CURRENCIES';
        XOPERATING: Label 'OPERATING', Comment = 'To be translated.';
        XCHECKING: Label 'CHECKING', Comment = 'To be translated.';
        XSAVINGS: Label 'SAVINGS', Comment = 'To be translated.';
        XCASH: Label 'CASH', Comment = 'To be translated.';

    procedure InsertData("Code": Code[20]; "G/L Account No.": Code[20]; "Liabs. for Disc. Bills Acc.": Code[20]; "Bank Services Acc.": Code[20]; "Disc. Interests Acc.": Code[20]; "Dish. Expenses Acc.": Code[20]; "Liabs. for Factoring Acc.": Code[20])
    begin
        "Bank Acc. Posting Group".Init();
        "Bank Acc. Posting Group".Validate(Code, Code);
        "Bank Acc. Posting Group".Validate("G/L Account No.", CA.Convert("G/L Account No."));
        "Bank Acc. Posting Group".Validate("Liabs. for Disc. Bills Acc.", CA.Convert("Liabs. for Disc. Bills Acc."));
        "Bank Acc. Posting Group".Validate("Bank Services Acc.", CA.Convert("Bank Services Acc."));
        "Bank Acc. Posting Group".Validate("Discount Interest Acc.", CA.Convert("Disc. Interests Acc."));
        "Bank Acc. Posting Group".Validate("Rejection Expenses Acc.", CA.Convert("Dish. Expenses Acc."));
        "Bank Acc. Posting Group".Validate("Liabs. for Factoring Acc.", CA.Convert("Liabs. for Factoring Acc."));
        "Bank Acc. Posting Group".Insert();
    end;
}

