codeunit 143011 "Library - PO - Export N34.1"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        Line: Text[1024];

    [Scope('OnPrem')]
    procedure GetBankAccNo(FileName: Text[1024]): Text[4]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 1);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 44, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure GetTransferTypeHeader(FileName: Text[1024]): Text
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 5);
        exit(LibraryTextFileValidation.ReadValue(Line, 2, 1));
    end;

    [Scope('OnPrem')]
    procedure GetTransferTypeTrailer(FileName: Text[1024]): Text
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 8);
        exit(LibraryTextFileValidation.ReadValue(Line, 61, 1));
    end;

    [Scope('OnPrem')]
    procedure GetVendorBankAccNo(FileName: Text[1024]): Text[4]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 6);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 44, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure GetVendorNo(FileName: Text[1024]): Code[6]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 7);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 32, 6), 1, 6));
    end;

    [Scope('OnPrem')]
    procedure GetDocType(FileName: Text[1024]): Text[2]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 6);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 3, 2), 1, 2));
    end;

    [Scope('OnPrem')]
    procedure GetPartialExportedAmount(FileName: Text[1024]): Text[12]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 6);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 32, 12), 1, 12));
    end;

    [Scope('OnPrem')]
    procedure GetExportedInterimAmount(FileName: Text[1024]): Text[12]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 8);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 32, 12), 1, 12));
    end;

    [Scope('OnPrem')]
    procedure GetExportedTotalAmount(FileName: Text[1024]): Text[12]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 9);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 32, 12), 1, 12));
    end;

    [Scope('OnPrem')]
    procedure GetElectMgtFormatForAmount(Amount: Decimal) AmountFormat: Text[12]
    begin
        while Amount <> Round(Amount, 1) do
            Amount := Amount * 10;

        AmountFormat := Format(Amount, 0, 1);
        while StrLen(AmountFormat) < 12 do
            AmountFormat := '0' + AmountFormat;
    end;

    [Scope('OnPrem')]
    procedure RunPOExportN341Report(PaymentOrderNo: Code[20]): Text[1024]
    var
        PaymentOrder: Record "Payment Order";
        POExportN341: Report "PO - Export N34.1";
        FileMgt: Codeunit "File Management";
        FileName: Text[1024];
    begin
        Commit();
        FileName := CopyStr(FileMgt.ServerTempFileName('txt'), 1, 1024);
        POExportN341.EnableSilentMode(FileName);

        PaymentOrder.SetRange("No.", PaymentOrderNo);
        POExportN341.SetTableView(PaymentOrder);
        POExportN341.RunModal();

        exit(FileName);
    end;
}

