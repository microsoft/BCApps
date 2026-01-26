codeunit 143000 "Library - NL Localization"
{
    // Library containing functions specific to NL Localization objects, hence meant to be kept at NL Branch Only.


    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    procedure CreateCBGStatement(var CBGStatement: Record "CBG Statement"; JournalTemplateName: Code[10])
    begin
        CBGStatement.Init();
        CBGStatement.Validate("Journal Template Name", JournalTemplateName);
        CBGStatement.Insert(true);
    end;

    procedure CreateCBGStatementLine(var CBGStatementLine: Record "CBG Statement Line"; JournalTemplateName: Code[10]; No: Integer; StatementType: Option; StatementNo: Code[20]; AccountType: Option; AccountNo: Code[20]; Debit: Decimal; Credit: Decimal)
    var
        RecRef: RecordRef;
    begin
        CBGStatementLine.Init();
        CBGStatementLine.Validate("Journal Template Name", JournalTemplateName);
        CBGStatementLine.Validate("No.", No);
        RecRef.GetTable(CBGStatementLine);
        CBGStatementLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, CBGStatementLine.FieldNo("Line No.")));
        CBGStatementLine.Insert(true);
        CBGStatementLine.Validate("Statement Type", StatementType);
        CBGStatementLine.Validate("Statement No.", StatementNo);
        CBGStatementLine.Validate(Date, WorkDate());
        CBGStatementLine.Validate("Account Type", AccountType);
        CBGStatementLine.Validate("Account No.", AccountNo);
        CBGStatementLine.Validate(Debit, Debit);
        CBGStatementLine.Validate(Credit, Credit);
        CBGStatementLine.Modify(true);
    end;

    procedure CreateElecTaxDeclarationHeader(var ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header"; DeclarationType: Option)
    begin
        ElecTaxDeclarationHeader.Init();
        ElecTaxDeclarationHeader.Validate("Declaration Type", DeclarationType);
        ElecTaxDeclarationHeader.Insert(true);
    end;

    procedure CreateExportProtocol(var ExportProtocol: Record "Export Protocol")
    begin
        ExportProtocol.Init();
        ExportProtocol.Validate(Code, LibraryUtility.GenerateGUID());
        ExportProtocol.Insert(true);
    end;

    procedure CreateFreelyTransferableMaximum(CountryRegionCode: Code[10]; CurrencyCode: Code[10])
    var
        FreelyTransferableMaximum: Record "Freely Transferable Maximum";
    begin
        FreelyTransferableMaximum.Init();
        FreelyTransferableMaximum.Validate("Country/Region Code", CountryRegionCode);
        FreelyTransferableMaximum.Validate("Currency Code", CurrencyCode);
        FreelyTransferableMaximum.Insert(true);
    end;

    procedure CheckAndCreateFreelyTransferableMaximum(CountryRegionCode: Code[10]; CurrencyCode: Code[10])
    var
        FreelyTransferableMaximum: Record "Freely Transferable Maximum";
    begin
        if not FreelyTransferableMaximum.Get(CountryRegionCode, CurrencyCode) then
            CreateFreelyTransferableMaximum(CountryRegionCode, CurrencyCode);
    end;

    procedure CreateTransactionMode(var TransactionMode: Record "Transaction Mode"; AccountType: Option)
    begin
        TransactionMode.Init();
        TransactionMode.Validate("Account Type", AccountType);
        TransactionMode.Validate(Code, LibraryUtility.GenerateRandomCode(TransactionMode.FieldNo(Code), DATABASE::"Transaction Mode"));
        TransactionMode.Insert(true);
    end;

    procedure VerifyPaymentHistoryChecksum(BankAccountNo: Code[20]; GenerateChecksum: Boolean; ExportProtocolCode: Code[20])
    var
        PaymentHistory: Record "Payment History";
        Assert: Codeunit Assert;
    begin
        FindPaymentHistory(BankAccountNo, PaymentHistory, ExportProtocolCode);
        If GenerateChecksum then
            Assert.IsTrue(PaymentHistory.Checksum <> '', 'Cheksum field is filled in in the Payment History')
        else
            Assert.IsTrue(PaymentHistory.Checksum = '', 'Cheksum field is not filled in in the Payment History');
    end;

    procedure VerifyExportedFileChecksum(BankAccountNo: Code[20]; AppendChecksum: Boolean)
    var
        PaymentHistory: Record "Payment History";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        Assert: Codeunit Assert;
        FileContent: BigText;
        TextPosition: Integer;
    begin
        PaymentHistory.SetRange("Our Bank", BankAccountNo);
        PaymentHistory.FindFirst();

        LibraryTextFileValidation.ReadTextFile(PaymentHistory."File on Disk", FileContent);

        TextPosition := FileContent.TextPos(PaymentHistory.Checksum);
        If AppendChecksum then
            Assert.IsTrue(TextPosition > 1, 'The exported file doesn''t contain checksum')
        else
            Assert.IsTrue(TextPosition = 0, 'The exported file contains checksum')

    end;

    procedure SetupExportProtocolChecksum(var ExportProtocol: Record "Export Protocol"; GenerateChecksum: Boolean; AppendChecksumToFile: Boolean)
    begin
        ExportProtocol.Validate("Append Checksum to File", AppendChecksumToFile);
        ExportProtocol.Validate("Generate Checksum", GenerateChecksum);
        ExportProtocol.Modify(true);
    end;

    procedure FindPaymentHistory(BankAccountNo: Code[20]; var PaymentHistory: Record "Payment History"; ExportProtocolCode: Code[20])
    begin
        PaymentHistory.SetRange("Export Protocol", ExportProtocolCode);
        PaymentHistory.SetRange("Our Bank", BankAccountNo);
        PaymentHistory.FindLast();
    end;
}

