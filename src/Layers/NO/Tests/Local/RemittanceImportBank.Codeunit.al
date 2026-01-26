codeunit 144133 "Remittance - Import Bank"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Remittance] [Import Payment Order] [Bank]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRemittance: Codeunit "Library - Remittance";
        FileMgt: Codeunit "File Management";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryDimension: Codeunit "Library - Dimension";
        IsInitialized: Boolean;
        PadCharacter: Text;
        ConfirmToImportTheLines: Boolean;
        SelectNoToImportTheLines: Boolean;
        BankRecordSize: Integer;
        NoteWithControlReturnFilesAreReadMsg: Label 'Note:\With Control, return files are read in advance to check if the import can be made.\Return data is not imported to %1.';

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfirmHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure ImporttBankFileDomestic()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        FilePath: Text;
        Amount: Decimal;
        BatchName: Code[10];
        ExtDocumentNo: Code[35];
        OldDate: Date;
    begin
        // [FEATURE] [Domestic Account]
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);
        ExtDocumentNo := GenJournalLine."External Document No.";

        UpdateSetupForBank(GenJournalLine, RemittanceAgreement, RemittanceAccount, NoSeriesLine, Vendor, BatchName, Amount);
        FilePath := GenerateBankRemittancePaymentFileDomestic(true); // TRUE=Correct format
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // Excercise
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines);

        // Verify
        VerifyImportedLinesDomestic(
          BatchName, GenJournalLine."Journal Template Name", ExtDocumentNo, WorkDate(), NoSeriesLine, Vendor."No.",
          RemittanceAccount."Account No.", Amount);
        VerifyWaitingJournalStatusIsSent();
        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfirmHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure ImportBankFileInternational()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        FilePath: Text;
        Amount: Decimal;
        Commission: Decimal;
        Rounding: Decimal;
        BatchName: Code[10];
        ExtDocumentNo: Code[35];
        OldDate: Date;
    begin
        // [FEATURE] [Foreign Account]
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, false);
        ExtDocumentNo := GenJournalLine."External Document No.";

        Commission := 1.23;
        Rounding := 0.01;
        UpdateSetupForBank(GenJournalLine, RemittanceAgreement, RemittanceAccount, NoSeriesLine, Vendor, BatchName, Amount);
        FilePath := GenerateBankRemittancePaymentFileInternational(true, Commission); // TRUE=Correct format
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // Excercise
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines);

        // Verify
        VerifyImportedLinesInternational(
          BatchName,
          GenJournalLine."Journal Template Name",
          ExtDocumentNo,
          WorkDate(),
          NoSeriesLine,
          Vendor."No.",
          RemittanceAccount, Amount, Commission, Rounding);

        VerifyWaitingJournalStatusIsSent();
        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfirmHandler,PaymentOrderSettlStatusHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure SpecifyingJournalTemplateNameImportsToSpecifiedJournalAndShowsSettlementDialog()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        ImportGenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        FilePath: Text;
        Amount: Decimal;
        BatchName: Code[10];
        ExtDocumentNo: Code[35];
        OldDate: Date;
    begin
        // [FEATURE] [Domestic Account]
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);
        ExtDocumentNo := GenJournalLine."External Document No.";

        LibraryRemittance.CreatePaymentGenJournalBatch(ImportGenJournalBatch, false);

        UpdateSetupForBank(GenJournalLine, RemittanceAgreement, RemittanceAccount, NoSeriesLine, Vendor, BatchName, Amount);
        RemittanceAccount.Validate("Return Journal Template Name", ImportGenJournalBatch."Journal Template Name");
        RemittanceAccount.Validate("Return Journal Name", ImportGenJournalBatch.Name);
        RemittanceAccount.Modify(true);

        FilePath := GenerateBankRemittancePaymentFileDomestic(true); // TRUE=Correct format
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // Excercise
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines);

        // Verify
        VerifyImportedLinesDomestic(
          ImportGenJournalBatch.Name, GenJournalLine."Journal Template Name", ExtDocumentNo, WorkDate(), NoSeriesLine, Vendor."No.",
          RemittanceAccount."Account No.", Amount);
        VerifyWaitingJournalStatusIsSent();
        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,ImportRemittancePaymentOrderRequestPageHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure ImportingBankFileWithoutClosingLineRaisesError()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        FilePath: Text;
        Amount: Decimal;
        BatchName: Code[10];
        OldDate: Date;
    begin
        // [FEATURE] [Domestic Account]
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);

        UpdateSetupForBank(GenJournalLine, RemittanceAgreement, RemittanceAccount, NoSeriesLine, Vendor, BatchName, Amount);
        FilePath := GenerateBankRemittancePaymentFileDomestic(false); // FALSE=No closing record
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // Excercise
        asserterror ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines);
        Assert.ExpectedError('Return file is not complete. System cannot find closing transaction (PAYFOR99) in return file');

        VerifyNoLinesAreImported(BatchName, GenJournalLine."Journal Template Name");

        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,ImportRemittancePaymentOrderRequestPageHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure SelectingNoAfterPaymentIsImportedReversesTheEntries()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        FilePath: Text;
        Amount: Decimal;
        BatchName: Code[10];
        OldDate: Date;
    begin
        // [FEATURE] [Domestic Account]
        OldDate := UpdateWorkdate(Today);
        Initialize();

        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);

        UpdateSetupForBank(GenJournalLine, RemittanceAgreement, RemittanceAccount, NoSeriesLine, Vendor, BatchName, Amount);
        FilePath := GenerateBankRemittancePaymentFileDomestic(false); // FALSE=No closing record
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // Excercise
        asserterror ImportRemittancePaymentOrderFile(BatchName, SelectNoToImportTheLines);
        Assert.ExpectedError('Import is cancelled');

        VerifyNoLinesAreImported(BatchName, GenJournalLine."Journal Template Name");

        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfirmHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure ImportingFileWithControlBatchRevertsTheEntries()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        FilePath: Text;
        Amount: Decimal;
        BatchName: Code[10];
        OldDate: Date;
    begin
        // [FEATURE] [Domestic Account]
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);

        UpdateSetupForBank(GenJournalLine, RemittanceAgreement, RemittanceAccount, NoSeriesLine, Vendor, BatchName, Amount);
        FilePath := GenerateBankRemittancePaymentFileDomestic(true); // TRUE=Correct format
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // Excercise
        asserterror ImportRemittancePaymentOrderFileControlBatch(BatchName);
        Assert.ExpectedError('Import of return data is cancelled');

        VerifyNoLinesAreImported(BatchName, GenJournalLine."Journal Template Name");

        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceMessageHandler,RemittanceExportBankHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportingFileWithDimensions()
    var
        RemittanceAccount: Record "Remittance Account";
        BatchName: Code[10];
        DimSetID: Integer;
    begin
        // [FEATURE] [Dimensions]
        // [SCENARIO 257147] The Dimensions should be copied to Gen. Journal Line from Waiting Journal Line after importing return file
        Initialize();

        // [GIVEN] Return File with record with dimensions
        GenerateBankRemittanceEntriesWithDimensions(RemittanceAccount, BatchName, DimSetID);

        // [WHEN] Import return file
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines);

        // [THEN] Gen. Journal Line contains dimensions
        VerifyGenJournaLineDimensionSetID(RemittanceAccount, DimSetID);
    end;

    local procedure Initialize()
    var
        WaitingJournal: Record "Waiting Journal";
        ReturnFileSetup: Record "Return File Setup";
    begin
        LibraryVariableStorage.Clear();
        WaitingJournal.DeleteAll();
        ReturnFileSetup.DeleteAll();
        LibraryERMCountryData.UpdateLocalData();

        if IsInitialized then
            exit;

        PadCharacter := ' ';
        BankRecordSize := 320;

        ConfirmToImportTheLines := true;
        SelectNoToImportTheLines := false;

        IsInitialized := true;
    end;

    local procedure GetWaitingJournal(var WaitingJournal: Record "Waiting Journal")
    begin
        Clear(WaitingJournal);
        Assert.AreEqual(1, WaitingJournal.Count, 'Wrong number of lines found in waiting journal');
        WaitingJournal.FindFirst();
    end;

    local procedure ClearAllGenJournalLines(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.DeleteAll(true);
    end;

    local procedure ImportRemittancePaymentOrderFileControlBatch(GenJournalBatchName: Code[20])
    begin
        InvokeImportRemittancePaymentOrderFile(GenJournalBatchName, true, true);
    end;

    local procedure ImportRemittancePaymentOrderFile(GenJournalBatchName: Code[20]; ConfirmTheImport: Boolean)
    begin
        InvokeImportRemittancePaymentOrderFile(GenJournalBatchName, ConfirmTheImport, false);
    end;

    local procedure InvokeImportRemittancePaymentOrderFile(GenJournalBatchName: Code[20]; ConfirmTheImport: Boolean; UseControlBatch: Boolean)
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);

        LibraryVariableStorage.Enqueue(UseControlBatch);
        if UseControlBatch then
            LibraryVariableStorage.Enqueue(StrSubstNo(NoteWithControlReturnFilesAreReadMsg, PRODUCTNAME.Full()));
        LibraryVariableStorage.Enqueue(ConfirmTheImport);
        if not UseControlBatch then
            LibraryVariableStorage.Enqueue(NoteWithControlReturnFilesAreReadMsg);
        // ImportPaymentOrder action
        PaymentJournal.ImportReturnData.Invoke();
    end;

    local procedure GenerateBankRemittancePaymentFileDomestic(WriteClosingLine: Boolean): Text
    var
        WaitingJournal: Record "Waiting Journal";
        BankPaymentFile: File;
        BankPaymentOutputStream: OutStream;
        ServerFileName: Text;
    begin
        GetWaitingJournal(WaitingJournal);

        ServerFileName := FileMgt.ServerTempFileName('txt');
        BankPaymentFile.Create(ServerFileName);
        BankPaymentFile.CreateOutStream(BankPaymentOutputStream);

        WriteBankRecord(GenerateBankRemittanceBatchStartRecord(), BankPaymentOutputStream);
        WriteBankRecord(GenerateBankRemittanceTransferRecordDomestic(WorkDate(), ''), BankPaymentOutputStream);
        WriteBankRecord(GenerateInvoiceRecordDomestic(Format(WaitingJournal.Reference), ''), BankPaymentOutputStream);

        if WriteClosingLine then
            WriteBankRecord(GenerateBankRemittanceBatchEndRecord(), BankPaymentOutputStream);

        BankPaymentFile.Close();
    end;

    [Normal]
    local procedure GenerateBankRemittancePaymentFileInternational(WriteClosingLine: Boolean; Commission: Decimal): Text
    var
        WaitingJournal: Record "Waiting Journal";
        BankPaymentFile: File;
        BankPaymentOutputStream: OutStream;
        ServeFileName: Text;
    begin
        GetWaitingJournal(WaitingJournal);

        ServeFileName := FileMgt.ServerTempFileName('txt');
        BankPaymentFile.Create(ServeFileName);
        BankPaymentFile.CreateOutStream(BankPaymentOutputStream);

        WriteBankRecord(GenerateBankRemittanceBatchStartRecord(), BankPaymentOutputStream);
        WriteBankRecord(
          GenerateBankRemittanceTransferRecordInternational(
            '',
            WaitingJournal."Currency Code",
            WaitingJournal."Currency Factor",
            '123456',
            '123456789012',
            WorkDate(),
            Commission,
            ''),
          BankPaymentOutputStream);

        WriteBankRecord(GeneratePayeeRecord(), BankPaymentOutputStream);

        WriteBankRecord(GenerateInvoiceRecordInternational(Format(WaitingJournal.Reference), ''), BankPaymentOutputStream);

        if WriteClosingLine then
            WriteBankRecord(GenerateBankRemittanceBatchEndRecord(), BankPaymentOutputStream);

        BankPaymentFile.Close();
    end;

    [Normal]
    local procedure WriteBankRecord("Record": Text; OutputStream: OutStream)
    var
        SubRecordNo: Integer;
    begin
        Record := PadStr(Record, BankRecordSize, PadCharacter);
        for SubRecordNo := 0 to 3 do begin
            OutputStream.WriteText(CopyStr(Record, (SubRecordNo * 80) + 1, 80));
            OutputStream.WriteText();
        end;
    end;

    [Normal]
    local procedure GenerateBankRemittanceHeader(): Text
    begin
        // Id=AH, fileversion=2, return code=02 (Batch contains processed payments)
        exit(PadStr('AH202', 40, PadCharacter));
    end;

    local procedure GenerateBankRemittanceBatchStartRecord(): Text
    var
        "Record": Text;
    begin
        Record := GenerateBankRemittanceHeader() + 'BETFOR00';
        Record := PadStr(Record, BankRecordSize, PadCharacter);
        exit(Record);
    end;

    [Normal]
    local procedure FormatDate(Date: Date): Text
    begin
        exit(Format(Date, 0, '<Year,2><Filler Character,0><Month,2><Filler Character,0><Day,2><Filler Character,0>'));
    end;

    [Normal]
    local procedure GenerateBankRemittanceTransferRecordDomestic(ValueDate: Date; CancelCause: Text[1]): Text
    var
        "Record": Text;
    begin
        Record := GenerateBankRemittanceHeader();
        Record := Record + 'BETFOR21';
        Record := PadStr(Record, 288, PadCharacter) + FormatDate(ValueDate);
        Record := PadStr(Record, 300, PadCharacter) + CancelCause;
        exit(Record);
    end;

    local procedure GenerateBankRemittanceTransferRecordInternational(PaymentCurrency: Text; InvoiceCurrency: Text; ExchangeRate: Decimal; ExecRef1: Text; ExecRef2: Text; ValueDate: Date; Comission: Decimal; CancelCause: Text): Text
    var
        "Record": Text;
    begin
        Record := GenerateBankRemittanceHeader();
        Record := Record + 'BETFOR01';
        Record := PadStr(Record, 116, PadCharacter) + PadStr(PaymentCurrency, 3, PadCharacter);
        Record := Record + PadStr(InvoiceCurrency, 3, PadCharacter);
        Record := PadStr(Record, 190, PadCharacter);
        Record := Record +
          ConvertStr(
            Format(ExchangeRate, 7, '<integer>') +
            CopyStr(
              Format(
                Round(ExchangeRate, 0.0001, '<'),
                0, '<decimal,5><filler,0>'),
              2, 4),
            ' ', '0');
        Record := Record + PadStr(ExecRef2, 12, PadCharacter);
        Record := PadStr(Record, 251, PadCharacter) + PadStr(ExecRef1, 6, PadCharacter);
        Record := PadStr(Record, 265, PadCharacter) + FormatDate(ValueDate);
        Record := Record +
          ConvertStr(
            Format(Comission, 7, '<integer>') +
            CopyStr(
              Format(
                Round(Comission, 0.01, '<'),
                0, '<decimal,3><filler,0>'),
              2, 2),
            ' ', '0');
        Record := PadStr(Record, 292, PadCharacter) + CancelCause;
        exit(Record);
    end;

    [Normal]
    local procedure GeneratePayeeRecord(): Text
    var
        "Record": Text;
    begin
        Record := GenerateBankRemittanceHeader();
        Record := Record + 'BETFOR03';
        exit(Record);
    end;

    [Normal]
    local procedure GenerateInvoiceRecordDomestic(OwnRef: Text; CancelCause: Text): Text
    var
        "Record": Text;
    begin
        Record := GenerateBankRemittanceHeader();
        Record := Record + 'BETFOR23';
        Record := PadStr(Record, 227, PadCharacter) + OwnRef;
        Record := PadStr(Record, 296, PadCharacter) + PadStr(CancelCause, 1, PadCharacter);
        exit(Record);
    end;

    [Normal]
    local procedure GenerateInvoiceRecordInternational(OwnRef: Text; CancelCause: Text): Text
    var
        "Record": Text;
    begin
        Record := GenerateBankRemittanceHeader();
        Record := Record + 'BETFOR04';
        Record := PadStr(Record, 115, PadCharacter) + OwnRef;
        Record := PadStr(Record, 233, PadCharacter) + PadStr(CancelCause, 1, PadCharacter);
        exit(Record);
    end;

    [Normal]
    local procedure GenerateBankRemittanceBatchEndRecord(): Text
    var
        "Record": Text;
    begin
        Record := GenerateBankRemittanceHeader() + 'BETFOR99';
        exit(Record);
    end;

    local procedure GenerateBankRemittanceEntriesWithDimensions(var RemittanceAccount: Record "Remittance Account"; var BatchName: Code[10]; var DimSetID: Integer)
    var
        RemittanceAgreement: Record "Remittance Agreement";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        DimensionValue: Record "Dimension Value";
        FilePath: Text;
        Amount: Decimal;
    begin
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank", RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine);

        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimSetID :=
          LibraryDimension.CreateDimSet(GenJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
        GenJournalLine.Validate("Dimension Set ID", DimSetID);
        GenJournalLine.Modify(true);

        UpdateSetupForBank(GenJournalLine, RemittanceAgreement, RemittanceAccount, NoSeriesLine, Vendor, BatchName, Amount);
        FilePath := GenerateBankRemittancePaymentFileDomestic(true);
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);
    end;

    local procedure UpdateSetupForBank(var GenJournalLine: Record "Gen. Journal Line"; var RemittanceAgreement: Record "Remittance Agreement"; var RemittanceAccount: Record "Remittance Account"; var NoSeriesLine: Record "No. Series Line"; Vendor: Record Vendor; var BatchName: Code[10]; var Amount: Decimal)
    var
        NoSeries: Record "No. Series";
        GenJournalBatch: Record "Gen. Journal Batch";
        FilePath: Text;
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        RemittanceAccount.Validate("Document No. Series", NoSeries.Code);
        RemittanceAccount.Modify(true);

        // We have to Export first, not possible to mock, too many dependencies
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);
        FilePath := LibraryRemittance.ExecuteRemittanceExportPaymentFile(
            LibraryVariableStorage,
            RemittanceAgreement,
            RemittanceAccount,
            Vendor,
            GenJournalLine,
            BatchName);

        // Generate the Bank Payment file
        // Suprisingly report is ignoring amount from the file
        // We are also summing the values but there is no check on the sum
        Amount := GenJournalLine.Amount;

        // Clear all lines, it must be blank before import
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", BatchName);
        ClearAllGenJournalLines(GenJournalBatch);
    end;

    local procedure UpdateWorkdate(NewDate: Date) OldDate: Date
    begin
        OldDate := WorkDate();
        WorkDate := NewDate;
        if Date2DWY(NewDate, 1) in [6, 7] then // "Posting Date" and "Pmt. Discount Date" compared works date in CU 15000001
            WorkDate := WorkDate() + 2;
    end;

    local procedure VerifyImportedLinesDomestic(BatchName: Code[10]; TemplateName: Code[10]; DocumentNo: Code[35]; PostingDate: Date; NoSeriesLine: Record "No. Series Line"; VendorAccountNo: Code[20]; RemittanceAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        Assert.AreEqual(2, GenJournalLine.Count, 'Number of imported lines not correct');
        GenJournalLine.Find('-');

        VerifyPaymentLine(GenJournalLine, PostingDate, NoSeriesLine, VendorAccountNo, Amount, DocumentNo);

        GenJournalLine.Next();

        VerifyBalancingLine(GenJournalLine, PostingDate, NoSeriesLine, RemittanceAccountNo, -Amount);
    end;

    [Normal]
    local procedure VerifyImportedLinesInternational(BatchName: Code[10]; TemplateName: Code[10]; DocumentNo: Code[35]; PostingDate: Date; NoSeriesLine: Record "No. Series Line"; VendorAccountNo: Code[20]; RemittanceAccount: Record "Remittance Account"; Amount: Decimal; Commission: Decimal; Rounding: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        Assert.AreEqual(4, GenJournalLine.Count, 'Number of imported lines not correct');
        GenJournalLine.Find('-');

        VerifyPaymentLine(GenJournalLine, PostingDate, NoSeriesLine, VendorAccountNo, Amount, DocumentNo);

        GenJournalLine.Next();

        VerifyCommissionLine(GenJournalLine, PostingDate, NoSeriesLine, RemittanceAccount."Charge Account No.", Commission);

        GenJournalLine.Next();

        VerifyBalancingLine(GenJournalLine, PostingDate, NoSeriesLine, RemittanceAccount."Account No.", -(Amount + Commission));

        GenJournalLine.Next();

        VerifyRoundingLine(GenJournalLine, PostingDate, NoSeriesLine, RemittanceAccount."Round off/Divergence Acc. No.", Rounding);
    end;

    local procedure VerifyNoLinesAreImported(BatchName: Code[10]; TemplateName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        Assert.AreEqual(0, GenJournalLine.Count, 'There should be no lines created');
    end;

    local procedure VerifyPaymentLine(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; NoSeriesLine: Record "No. Series Line"; AccountNo: Code[20]; Amount: Decimal; DocumentNo: Code[35])
    begin
        VerifyGenJournalLine(GenJournalLine, PostingDate, NoSeriesLine, AccountNo, Amount);

        Assert.AreEqual(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type", 'Document Type was set to wrong value');
        Assert.AreEqual(DocumentNo, GenJournalLine."External Document No.", 'External document no was set to a wrong value');
        Assert.AreEqual(
          GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Account Type",
          'Account type was not set to a correct value');
        Assert.AreEqual(DocumentNo, GenJournalLine."Applies-to Doc. No.", 'Applies-to Doc. No. was not set to a correct value');
        Assert.AreEqual(true, GenJournalLine.IsApplied(), 'IsApplied was not set to a correct value');
        Assert.AreEqual(
          GenJournalLine."Applies-to Doc. Type"::Invoice, GenJournalLine."Applies-to Doc. Type",
          'Applies-to Doc. Type was not set to correct value');
    end;

    local procedure VerifyBalancingLine(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; NoSeriesLine: Record "No. Series Line"; AccountNo: Code[20]; Amount: Decimal)
    begin
        VerifyGenJournalLine(GenJournalLine, PostingDate, NoSeriesLine, AccountNo, Amount);

        Assert.AreEqual(GenJournalLine."Document Type"::" ", GenJournalLine."Document Type", 'Document Type should be blank');
        Assert.AreEqual('', GenJournalLine."External Document No.", 'External document No. should be blank');
        Assert.AreEqual(
          GenJournalLine."Account Type"::"Bank Account",
          GenJournalLine."Account Type",
          'Account type was not set to a correct value');
        Assert.AreEqual('', GenJournalLine."Applies-to Doc. No.", 'Applies-to Doc. No. should be blank');
        Assert.AreEqual(false, GenJournalLine.IsApplied(), 'IsApplied was not set to a correct value');
        Assert.AreEqual(
          GenJournalLine."Applies-to Doc. Type"::" ", GenJournalLine."Applies-to Doc. Type",
          'Applies-to Doc. Type was not set to correct value');
    end;

    [Normal]
    local procedure VerifyCommissionLine(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; NoSeriesLine: Record "No. Series Line"; AccountNo: Code[20]; Amount: Decimal)
    begin
        VerifyGenJournalLine(GenJournalLine, PostingDate, NoSeriesLine, AccountNo, Amount);

        Assert.AreEqual(GenJournalLine."Document Type"::" ", GenJournalLine."Document Type", 'Document Type should be blank');
        Assert.AreEqual('', GenJournalLine."External Document No.", 'External document No. should be blank');
        Assert.AreEqual(
          GenJournalLine."Account Type"::"G/L Account",
          GenJournalLine."Account Type",
          'Account type was not set to a correct value');
        Assert.AreEqual('', GenJournalLine."Applies-to Doc. No.", 'Applies-to Doc. No. should be blank');
    end;

    [Normal]
    local procedure VerifyRoundingLine(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; NoSeriesLine: Record "No. Series Line"; AccountNo: Code[20]; Amount: Decimal)
    begin
        VerifyGenJournalLine(GenJournalLine, PostingDate, NoSeriesLine, AccountNo, Amount);

        Assert.AreEqual(GenJournalLine."Document Type"::" ", GenJournalLine."Document Type", 'Document Type should be blank');
        Assert.AreEqual('', GenJournalLine."External Document No.", 'External document No. should be blank');
        Assert.AreEqual(
          GenJournalLine."Account Type"::"G/L Account",
          GenJournalLine."Account Type",
          'Account type was not set to a correct value');
        Assert.AreEqual('', GenJournalLine."Applies-to Doc. No.", 'Applies-to Doc. No. should be blank');
    end;

    [Normal]
    local procedure VerifyGenJournalLine(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; NoSeriesLine: Record "No. Series Line"; AccountNo: Code[20]; Amount: Decimal)
    begin
        Assert.AreEqual(PostingDate, GenJournalLine."Posting Date", 'Posting date was not set to a correct value');
        Assert.AreEqual(NoSeriesLine."Starting No.", GenJournalLine."Document No.", 'Wrong document no. was set to the line');
        Assert.AreEqual(AccountNo, GenJournalLine."Account No.", 'Account no was not set to a correct value');
        Assert.AreEqual(Amount, GenJournalLine.Amount, 'Amount was not set to a correct value');
        Assert.AreEqual(false, GenJournalLine."Has Payment Export Error", 'Has payment export error was not set to correct value');
    end;

    local procedure VerifyWaitingJournalStatusIsSent()
    var
        WaitingJournal: Record "Waiting Journal";
    begin
        GetWaitingJournal(WaitingJournal);
        Assert.AreEqual(
          WaitingJournal."Remittance Status"::Sent, WaitingJournal."Remittance Status", 'Waiting Journal must have status of Sent');
    end;

    local procedure VerifyGenJournaLineDimensionSetID(RemittanceAccount: Record "Remittance Account"; DimSetID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFilter("Remittance Account Code", RemittanceAccount.Code);
        GenJournalLine.SetFilter("Remittance Agreement Code", RemittanceAccount."Remittance Agreement Code");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Dimension Set ID", DimSetID);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ImportRemittancePaymentOrderRequestPageHandler(var RemPaymentOrderImport: TestRequestPage "Rem. payment order - import")
    var
        IsControlBatch: Variant;
    begin
        LibraryVariableStorage.Dequeue(IsControlBatch);

        // Control108003 is Control Batch filed
        RemPaymentOrderImport.ControlBatch.SetValue(IsControlBatch);
        RemPaymentOrderImport.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentOrderSettlStatusHandler(var PaymentOrderSettlStatus: TestPage "Payment Order - Settl. Status")
    begin
        // Page is not testable
        PaymentOrderSettlStatus.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RemittanceExportBankHandler(var RemittanceExportBank: TestRequestPage "Remittance - export (bank)")
    var
        RemittanceAgreementCode: Variant;
        FileName: Variant;
    begin
        LibraryVariableStorage.Dequeue(RemittanceAgreementCode);
        RemittanceExportBank.RemAgreementCode.Value := RemittanceAgreementCode;
        LibraryVariableStorage.Dequeue(FileName);
        RemittanceExportBank.CurrentFilename.Value := FileName;
        RemittanceExportBank.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ImportPaymentsConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        Answer: Variant;
    begin
        LibraryVariableStorage.Dequeue(Answer);
        Reply := Answer;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure RemittanceMessageHandler(Message: Text)
    var
        v: Variant;
        Expected: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(v);
        Expected := v;
        Assert.AreEqual(Expected, Message, 'Wrong Message');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestRemittancePaymentsHandler(var SuggestRemittancePayments: TestRequestPage "Suggest Remittance Payments")
    var
        VendorNo: Variant;
        RemittanceAccountCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(RemittanceAccountCode);
        LibraryVariableStorage.Dequeue(VendorNo);
        SuggestRemittancePayments.LastPaymentDate.SetValue(WorkDate());
        SuggestRemittancePayments.Vendor.SetFilter("No.", VendorNo);
        SuggestRemittancePayments.Vendor.SetFilter("Remittance Account Code", RemittanceAccountCode);
        SuggestRemittancePayments.OK().Invoke();
    end;
}

