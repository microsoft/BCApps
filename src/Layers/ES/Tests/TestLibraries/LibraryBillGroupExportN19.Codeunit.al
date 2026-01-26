codeunit 143021 "Library Bill Group Export N19"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";

    [Scope('OnPrem')]
    procedure ReadBankSuffix(Line: Text[1024]): Code[3]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 14, 3), 1, 3));
    end;

    [Scope('OnPrem')]
    procedure ReadBillGroupBankAccountNo(Line: Text[1024]): Text[10]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 79, 10), 1, 10));
    end;

    [Scope('OnPrem')]
    procedure ReadBillGroupBankBranchNo(Line: Text[1024]): Text[4]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 73, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure ReadBillGroupBankControlDigits(Line: Text[1024]): Text[2]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 77, 2), 1, 2));
    end;

    [Scope('OnPrem')]
    procedure ReadBillGroupBankNo(Line: Text[1024]): Text[4]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 69, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure ReadBillGroupCompanyName(Line: Text[1024]): Text[40]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 29, 40), 1, 40));
    end;

    [Scope('OnPrem')]
    procedure ReadBillGroupDueDate(Line: Text[1024]): Text[6]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 23, 6), 1, 6));
    end;

    [Scope('OnPrem')]
    procedure ReadBillGroupPostingDate(Line: Text[1024]): Text[6]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 17, 6), 1, 6));
    end;

    [Scope('OnPrem')]
    procedure ReadCarteraDocAmount(Line: Text[1024]): Text[10]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 89, 10), 1, 10));
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
    procedure ReadCarteraDocNumber(Line: Text[1024]): Text[10]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 105, 10), 1, 10));
    end;

    [Scope('OnPrem')]
    procedure ReadCompanyVATRegNo(Line: Text[1024]): Text[9]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 5, 9), 1, 9));
    end;

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
    procedure ReadHeaderBankBranchNo(Line: Text[1024]): Text[4]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 93, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure ReadHeaderBankNo(Line: Text[1024]): Text[4]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 89, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure ReadHeaderCompanyName(Line: Text[1024]): Text[40]
    begin
        exit(ReadCarteraDocCustomerName(Line));
    end;

    [Scope('OnPrem')]
    procedure ReadHeaderPostingDate(Line: Text[1024]): Text[6]
    begin
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 17, 6), 1, 6));
    end;

    [Scope('OnPrem')]
    procedure ReadLineTag(Line: Text[1024]) LineTag: Integer
    var
        LineTagAsText: Text[1024];
    begin
        LineTagAsText := CopyStr(LibraryTextFileValidation.ReadValue(Line, 1, 4), 1, 4);
        Evaluate(LineTag, LineTagAsText);
    end;

    [Scope('OnPrem')]
    procedure RunBillGroupExportN19Report(BillGroupNo: Code[20]; FileName: Text)
    var
        BillGroup: Record "Bill Group";
        BillGroupExportN19: Report "Bill group - Export N19";
    begin
        Commit();
        BillGroupExportN19.EnableSilentMode(FileName);

        BillGroup.SetRange("No.", BillGroupNo);
        BillGroupExportN19.SetTableView(BillGroup);

        BillGroupExportN19.RunModal();
    end;
}

