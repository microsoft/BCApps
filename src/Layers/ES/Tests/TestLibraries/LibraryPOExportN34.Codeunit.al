codeunit 143012 "Library - PO - Export N34"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        Line: Text[1024];

    [Scope('OnPrem')]
    procedure GetBankAccNo(FileName: Text[1024]): Text[10]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 1);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 50, 10), 1, 10));
    end;

    [Scope('OnPrem')]
    procedure GetBankControlDigits(FileName: Text[1024]): Text[2]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 1);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 64, 2), 1, 2));
    end;

    [Scope('OnPrem')]
    procedure GetBankNo(FileName: Text[1024]): Text[4]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 1);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 42, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure GetCompanyName(FileName: Text[1024]): Text[30]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 2);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 30, 36), 1, 30));
    end;

    [Scope('OnPrem')]
    procedure GetTotalDocAmount(FileName: Text[1024]): Text[12]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 7);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 30, 12), 1, 12));
    end;

    [Scope('OnPrem')]
    procedure GetEuroAmountN34Report(Amount: Decimal): Text[12]
    var
        PaymentOrderExportN34: Report "Payment order - Export N34";
    begin
        exit(PaymentOrderExportN34.EuroAmount(Amount));
    end;

    [Scope('OnPrem')]
    procedure GetVendorNo(FileName: Text[1024]): Code[10]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 6);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 30, 36), 1, 10));
    end;

    [Scope('OnPrem')]
    procedure GetVendorBankNo(FileName: Text[1024]): Text[4]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 5);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 42, 4), 1, 4));
    end;

    [Scope('OnPrem')]
    procedure GetVendorBankAccNo(FileName: Text[1024]): Text[10]
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 5);
        exit(CopyStr(LibraryTextFileValidation.ReadValue(Line, 50, 10), 1, 10));
    end;

    [Scope('OnPrem')]
    procedure RunPOExportN34Report(PaymentOrderNo: Code[20]): Text[1024]
    var
        PaymentOrder: Record "Payment Order";
        PaymentOrderExportN34: Report "Payment order - Export N34";
        FileMgt: Codeunit "File Management";
        FileName: Text[1024];
    begin
        Commit();
        FileName := CopyStr(FileMgt.ServerTempFileName('txt'), 1, 1024);
        PaymentOrderExportN34.EnableSilentMode(FileName);

        PaymentOrder.SetRange("No.", PaymentOrderNo);
        PaymentOrderExportN34.SetTableView(PaymentOrder);
        PaymentOrderExportN34.RunModal();

        exit(FileName);
    end;
}

