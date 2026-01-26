codeunit 143023 "Library Bill Group Export N32"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";

    [Scope('OnPrem')]
    procedure EuroAmount(Amount: Decimal): Text[10]
    var
        TextAmount: Text[15];
    begin
        TextAmount := ConvertStr(Format(Amount), ' ', '0');
        if StrPos(TextAmount, ',') = 0 then
            TextAmount := TextAmount + '00'
        else begin
            if StrLen(CopyStr(TextAmount, StrPos(TextAmount, ','), StrLen(TextAmount))) = 2 then
                TextAmount := TextAmount + '0';
            TextAmount := DelChr(TextAmount, '=', ',');
        end;

        if StrPos(TextAmount, '.') = 0 then
            TextAmount := TextAmount
        else
            TextAmount := DelChr(TextAmount, '=', '.');

        while StrLen(TextAmount) < 10 do
            TextAmount := '0' + TextAmount;

        exit(TextAmount);
    end;

    [Scope('OnPrem')]
    procedure ReadBankSuffix(Line: Text[1024]): Code[3]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 38, 6), 1, 3));
    end;

    [Scope('OnPrem')]
    procedure ReadBillGroupAmount(Line: Text[1024]): Text[10]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 76, 10), 1, 10));
    end;

    [Scope('OnPrem')]
    procedure ReadBillGroupBankAccountNo(Line: Text[1024]): Text[10]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 76, 10), 1, 10));
    end;

    [Scope('OnPrem')]
    procedure ReadBillGroupBankBranchNo(Line: Text[1024]): Text[4]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 70, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure ReadBillGroupBankControlDigits(Line: Text[1024]): Text[2]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 74, 2), 1, 2));
    end;

    [Scope('OnPrem')]
    procedure ReadBillGroupBankNo(Line: Text[1024]): Text[4]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 66, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure ReadCarteraDocCustomerBankAccountNo(Line: Text[1024]): Text[10]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 79, 10), 1, 10));
    end;

    [Scope('OnPrem')]
    procedure ReadCarteraDocCustomerBankBranchNo(Line: Text[1024]): Text[4]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 73, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure ReadCarteraDocCustomerBankControlDigits(Line: Text[1024]): Text[2]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 77, 2), 1, 2));
    end;

    [Scope('OnPrem')]
    procedure ReadCarteraDocCustomerBankNo(Line: Text[1024]): Text[4]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 69, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure ReadCarteraDocCustomerName(Line: Text[1024]): Text[40]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 29, 40), 1, 40));
    end;

    [Scope('OnPrem')]
    procedure ReadCarteraDocDueDate(Line: Text[1024]): Text[6]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 112, 6), 1, 6));
    end;

    [Scope('OnPrem')]
    procedure ReadCarteraDocNumber(Line: Text[1024]): Text[10]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 7, 10), 1, 10));
    end;

    [Scope('OnPrem')]
    procedure ReadCompanyVATRegNo(Line: Text[1024]): Text[9]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 29, 9), 1, 9));
    end;

    [Scope('OnPrem')]
    procedure ReadCompanyPostCode(Line: Text[1024]): Text[2]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 32, 2), 1, 2));
    end;

    [Scope('OnPrem')]
    procedure ReadCompanyCity(Line: Text[1024]): Text[20]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 43, 20), 1, 20));
    end;

    [Scope('OnPrem')]
    procedure ReadCustomerCCCBankNo(Line: Text[1024]): Text[4]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 33, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure ReadCustomerCCCBankBranchNo(Line: Text[1024]): Text[4]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 37, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure ReadCustomerCCCControlDigits(Line: Text[1024]): Text[2]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 41, 2), 1, 2));
    end;

    [Scope('OnPrem')]
    procedure ReadCustomerCCCBankAccountNo(Line: Text[1024]): Text[10]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 43, 10), 1, 10));
    end;

    [Scope('OnPrem')]
    procedure ReadCustomerCompanyName(Line: Text[1024]): Text[34]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 53, 34), 1, 34));
    end;

    [Scope('OnPrem')]
    procedure ReadCustomerName(Line: Text[1024]): Text[34]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 87, 34), 1, 34));
    end;

    [Scope('OnPrem')]
    procedure ReadHeaderBankBranchNo(Line: Text[1024]): Text[4]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 56, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure ReadHeaderBankNo(Line: Text[1024]): Text[4]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 52, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure ReadHeaderPostingDate(Line: Text[1024]): Text[6]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 7, 6), 1, 6));
    end;

    [Scope('OnPrem')]
    procedure ReadLineTag(Line: Text[1024]): Text[4]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 1, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure ReadTotalAmount(Line: Text[1024]): Text[10]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 76, 10), 1, 10));
    end;

    [Scope('OnPrem')]
    procedure RunBillGroupExportN32Report(BillGroupNo: Code[20]; FileName: Text)
    var
        BillGroup: Record "Bill Group";
        BillGroupExportN32: Report "Bill group - Export N32";
    begin
        Commit();

        BillGroupExportN32.EnableSilentMode(FileName);

        BillGroup.SetRange("No.", BillGroupNo);
        BillGroupExportN32.SetTableView(BillGroup);

        BillGroupExportN32.RunModal();
    end;
}

