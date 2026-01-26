codeunit 144131 "Remittance - Import BBS"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Remittance] [Import Payment Order] [BBS]
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
        BBSPaymentFilePrefixTxt: Label 'NY', Comment = 'Constant prefix that identifies payment file as BBS';
        PadCharacter: Text;
        BBSDataRecipient: Text[8];
        ConfirmToImportTheLines: Boolean;
        SelectNoToImportTheLines: Boolean;
        NoteWithControlReturnFilesAreReadMsg: Label 'Note:\With Control, return files are read in advance to check if the import can be made.\Return data is not imported to %1.';
        WrongBalAccNoErr: Label 'Bal. Account No. was set to a wrong value.';

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBBSHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfrimHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure ImportCorrectBBSPaymentFile()
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
        // [SCENARIO 260205] Import BBS file with Payment balancing Gen. Journal lines created
        Initialize();

        // [GIVEN] BBS Remittance for vendor's invoice
        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::BBS,
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);
        ExtDocumentNo := GenJournalLine."External Document No.";

        UpdateSetupForBBS(GenJournalLine, RemittanceAgreement, RemittanceAccount, NoSeriesLine, Vendor, BatchName, Amount);
        FilePath := GenerateCorrectBBSRemittancePaymentFile(Amount, BBSDataRecipient);
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // [WHEN] Import Payment Order BBS file
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines);

        // [THEN] Waiting Journal has status Sent
        // [THEN] Balancing line has "Document Type" = Payment
        VerifyBBSImportedLines(
          BatchName, GenJournalLine."Journal Template Name", ExtDocumentNo, WorkDate(), NoSeriesLine, Vendor."No.",
          RemittanceAccount."Account No.", Amount,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Payment);
        VerifyWaitingJournalStatusIsSent();
        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBBSHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfrimHandler,PaymentOrderSettlStatusHandler,RemittanceMessageHandler')]
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
        // [SCENARIO 260205] Import BBS file with blank balancing Gen. Journal lines created
        Initialize();

        // [GIVEN] BBS Remittance for vendor's credit memo
        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::BBS,
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);
        ExtDocumentNo := GenJournalLine."External Document No.";

        LibraryRemittance.CreatePaymentGenJournalBatch(ImportGenJournalBatch, false);

        UpdateSetupForBBS(GenJournalLine, RemittanceAgreement, RemittanceAccount, NoSeriesLine, Vendor, BatchName, Amount);
        RemittanceAccount.Validate("Return Journal Template Name", ImportGenJournalBatch."Journal Template Name");
        RemittanceAccount.Validate("Return Journal Name", ImportGenJournalBatch.Name);
        RemittanceAccount.Modify(true);

        UpdateCrMemoDocTypeOnWaitingJournal(GenJournalLine."Account No.", GenJournalLine."Document No.");

        FilePath := GenerateCorrectBBSRemittancePaymentFile(Amount, BBSDataRecipient);
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // [WHEN] Import Payment Order BBS file
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines);

        // [THEN] Waiting Journal has status Sent
        // [THEN] Balancing line has blank "Document Type"
        VerifyBBSImportedLines(
          ImportGenJournalBatch.Name, GenJournalLine."Journal Template Name", ExtDocumentNo, WorkDate(), NoSeriesLine, Vendor."No.",
          RemittanceAccount."Account No.", Amount,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::" ");
        VerifyWaitingJournalStatusIsSent();
        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBBSHandler,ImportRemittancePaymentOrderRequestPageHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure ImportingBBSFileWithoutClosingLineRaisesError()
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
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::BBS,
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);

        UpdateSetupForBBS(GenJournalLine, RemittanceAgreement, RemittanceAccount, NoSeriesLine, Vendor, BatchName, Amount);
        FilePath := CreateBBSPaymentFileWithoutClosingLine(Amount, BBSDataRecipient);
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // Excercise
        asserterror ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines);
        Assert.ExpectedError('Cannot find closing record for shipment (Recordtype 89) in the return file');

        VerifyNoLinesAreImported(BatchName, GenJournalLine."Journal Template Name");

        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBBSHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfrimHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure SelectingNoAfterPaymentIsImportedRemovesAllImportedEntries()
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
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::BBS,
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);

        UpdateSetupForBBS(GenJournalLine, RemittanceAgreement, RemittanceAccount, NoSeriesLine, Vendor, BatchName, Amount);
        FilePath := GenerateCorrectBBSRemittancePaymentFile(Amount, BBSDataRecipient);
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // Excercise
        asserterror ImportRemittancePaymentOrderFile(BatchName, SelectNoToImportTheLines);
        Assert.ExpectedError('Import is cancelled');

        VerifyNoLinesAreImported(BatchName, GenJournalLine."Journal Template Name");

        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBBSHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfrimHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure ImportingFileWithControlBatchDoesntCreateEntriesInJournal()
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
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::BBS,
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);

        UpdateSetupForBBS(GenJournalLine, RemittanceAgreement, RemittanceAccount, NoSeriesLine, Vendor, BatchName, Amount);
        FilePath := GenerateCorrectBBSRemittancePaymentFile(Amount, BBSDataRecipient);
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // Excercise
        asserterror ImportRemittancePaymentOrderFileControlBatch(BatchName);
        Assert.ExpectedError('Import of return data is cancelled');

        VerifyNoLinesAreImported(BatchName, GenJournalLine."Journal Template Name");

        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceMessageHandler,RemittanceExportBBSHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfrimHandler')]
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

        BBSDataRecipient := '12345678'; // Must be of lenght 8

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

    local procedure GenerateCorrectBBSRemittancePaymentFile(Amount: Decimal; DataRecipient: Text[8]): Text
    begin
        exit(GenerateBBSRemittancePaymentFile(Amount, DataRecipient, true));
    end;

    local procedure CreateBBSPaymentFileWithoutClosingLine(Amount: Decimal; DataRecipient: Text[8]): Text
    begin
        exit(GenerateBBSRemittancePaymentFile(Amount, DataRecipient, false));
    end;

    local procedure GenerateBBSRemittancePaymentFile(Amount: Decimal; DataRecipient: Text[8]; WriteClosingLine: Boolean): Text
    var
        WaitingJournal: Record "Waiting Journal";
        BBSPaymentFile: File;
        BBSPaymentOutputStream: OutStream;
        ServerFileName: Text;
    begin
        GetWaitingJournal(WaitingJournal);

        ServerFileName := FileMgt.ServerTempFileName('txt');
        BBSPaymentFile.Create(ServerFileName);
        BBSPaymentFile.CreateOutStream(BBSPaymentOutputStream);

        BBSPaymentOutputStream.WriteText(GenerateBBSRemittanceStartRecordShipmentLine('1234567', DataRecipient));
        BBSPaymentOutputStream.WriteText();

        BBSPaymentOutputStream.WriteText(GenerateBBSRemittanceStartRecordPaymentOrderLine('1234567'));
        BBSPaymentOutputStream.WriteText();

        BBSPaymentOutputStream.WriteText(
          GenerateBBSRemittanceTransactionRecordAmountEntry1Line('1234567', WorkDate(), Amount));
        BBSPaymentOutputStream.WriteText();

        BBSPaymentOutputStream.WriteText(GenerateBBSRemittanceTransactionRecordAmountEntry2Line(WaitingJournal."BBS Referance"));
        BBSPaymentOutputStream.WriteText();

        BBSPaymentOutputStream.WriteText(GenerateBBSRemittanceEndPaymentOrderLine());
        BBSPaymentOutputStream.WriteText();

        if WriteClosingLine then begin
            BBSPaymentOutputStream.WriteText(GenerateBBSRemittanceEndShipmentLine());
            BBSPaymentOutputStream.WriteText();
        end;

        BBSPaymentFile.Close();
    end;

    local procedure GenerateBBSRemittanceStartRecordShipmentLine(ShipmentNo: Text[7]; DataRecipient: Text[8]): Text
    var
        PaymentLine: Text;
        RecordType: Text[2];
    begin
        // Only values that product is parsing are written others are replaced by blank characters
        RecordType := '10';

        if DataRecipient = '' then
            DataRecipient := PadStr('', 8, PadCharacter);

        PaymentLine :=
          GenerateBBSLineStartPrefix(RecordType) +
          PadStr('', 8, PadCharacter) +
          ShipmentNo +
          DataRecipient +
          PadStr('', 48, PadCharacter);

        exit(PaymentLine);
    end;

    local procedure GenerateBBSRemittanceStartRecordPaymentOrderLine(PaymentOrderNo: Text[7]): Text
    var
        PaymentLine: Text;
        RecordType: Text[2];
    begin
        RecordType := '20';

        PaymentLine :=
          GenerateBBSLineStartPrefix(RecordType) +
          PadStr('', 9, PadCharacter) +
          PaymentOrderNo +
          PadStr('', 54, PadCharacter);

        exit(PaymentLine);
    end;

    local procedure GenerateBBSRemittanceTransactionRecordAmountEntry1Line(TransactionNo: Text[7]; TransactionBBSDate: Date; Amount: Decimal): Text
    var
        PaymentLine: Text;
        RecordType: Text[2];
        TransactionBBSDateText: Text[6];
        TransactionAmountText: Text[17];
    begin
        RecordType := '30';
        TransactionBBSDateText := Format(TransactionBBSDate, 6, 5);
        TransactionAmountText := Format(Amount);

        AddZerosToBeginningOfString(TransactionAmountText, 17);
        if StrPos(TransactionAmountText, '-') > 0 then begin
            TransactionAmountText := ConvertStr(TransactionAmountText, '-', '0');
            TransactionAmountText[1] := '-';
        end;

        PaymentLine :=
          GenerateBBSLineStartPrefix(RecordType) +
          TransactionNo +
          TransactionBBSDateText +
          TransactionAmountText +
          PadStr('', 34, PadCharacter);

        exit(PaymentLine);
    end;

    local procedure GenerateBBSRemittanceTransactionRecordAmountEntry2Line(TransOwnref: Integer): Text
    var
        PaymentLine: Text;
        RecordType: Text[2];
        TransOwnrefText: Text[25];
    begin
        RecordType := '31';

        TransOwnrefText := Format(TransOwnref);
        AddZerosToBeginningOfString(TransOwnrefText, 25);

        PaymentLine :=
          GenerateBBSLineStartPrefix(RecordType) +
          PadStr('', 17, PadCharacter) +
          TransOwnrefText +
          PadStr('', 29, PadCharacter);

        exit(PaymentLine);
    end;

    local procedure GenerateBBSRemittanceEndPaymentOrderLine(): Text
    var
        PaymentLine: Text;
        RecordType: Text[2];
    begin
        RecordType := '88';
        PaymentLine := GenerateBBSLineStartPrefix(RecordType);
        exit(PaymentLine);
    end;

    local procedure GenerateBBSRemittanceEndShipmentLine(): Text
    var
        PaymentLine: Text;
        RecordType: Text[2];
    begin
        RecordType := '89';
        PaymentLine := GenerateBBSLineStartPrefix(RecordType);
        exit(PaymentLine);
    end;

    local procedure GenerateBBSLineStartPrefix(RecordType: Text[2]): Text
    var
        PaymentLine: Text;
    begin
        PaymentLine :=
          BBSPaymentFilePrefixTxt +
          PadStr('', 4, PadCharacter) +
          RecordType;

        exit(PaymentLine);
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
          RemittanceAgreement."Payment System"::BBS,
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);

        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimSetID := LibraryDimension.CreateDimSet(
            GenJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
        GenJournalLine.Validate("Dimension Set ID", DimSetID);
        GenJournalLine.Modify(true);

        UpdateSetupForBBS(GenJournalLine, RemittanceAgreement, RemittanceAccount, NoSeriesLine, Vendor, BatchName, Amount);
        FilePath := GenerateCorrectBBSRemittancePaymentFile(Amount, BBSDataRecipient);
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);
    end;

    local procedure AddZerosToBeginningOfString(var StringToModify: Text; ExpectedLength: Integer)
    begin
        StringToModify := PadStr('', ExpectedLength - StrLen(StringToModify), '0') + StringToModify;
    end;

    local procedure UpdateSetupForBBS(var GenJournalLine: Record "Gen. Journal Line"; var RemittanceAgreement: Record "Remittance Agreement"; var RemittanceAccount: Record "Remittance Account"; var NoSeriesLine: Record "No. Series Line"; Vendor: Record Vendor; var BatchName: Code[10]; var Amount: Decimal)
    var
        NoSeries: Record "No. Series";
        GenJournalBatch: Record "Gen. Journal Batch";
        FilePath: Text;
    begin
        RemittanceAgreement.Validate("BBS Customer Unit ID", BBSDataRecipient);
        RemittanceAgreement.Modify(true);

        LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        RemittanceAccount.Validate("Document No. Series", NoSeries.Code);
        RemittanceAccount.Modify(true);

        // We have to Export first, not possible to mock, too many dependencies
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);
        FilePath :=
          LibraryRemittance.ExecuteRemittanceExportPaymentFile(
            LibraryVariableStorage, RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, BatchName);

        // Generate the BBS Payment file
        // Suprisingly report is ignoring amount from the file
        // We are also summing the values but there is no check on the sum
        Amount := GenJournalLine.Amount;

        // Clear all lines, it must be blank before import
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", BatchName);
        ClearAllGenJournalLines(GenJournalBatch);
    end;

    local procedure UpdateCrMemoDocTypeOnWaitingJournal(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        WaitingJournal: Record "Waiting Journal";
    begin
        WaitingJournal.SetRange("Account No.", VendorNo);
        WaitingJournal.SetRange("Document No.", DocumentNo);
        WaitingJournal.FindFirst();
        WaitingJournal.Validate("Document Type", WaitingJournal."Document Type"::"Credit Memo");
        WaitingJournal.Modify(true);
    end;

    local procedure VerifyBBSImportedLines(BatchName: Code[10]; TemplateName: Code[10]; DocumentNo: Code[35]; PostingDate: Date; NoSeriesLine: Record "No. Series Line"; VendorAccountNo: Code[20]; RemittanceAccountNo: Code[20]; Amount: Decimal; PaymentDocType: Enum "Gen. Journal Document Type"; BalanceDocType: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        Assert.AreEqual(2, GenJournalLine.Count, 'There should be only a payment line and a balancing line');
        GenJournalLine.Find('-');

        VerifyPaymentLine(GenJournalLine, PostingDate, NoSeriesLine, VendorAccountNo, Amount, DocumentNo, PaymentDocType);
        GenJournalLine.Next();

        VerifyBalancingLine(GenJournalLine, PostingDate, NoSeriesLine, RemittanceAccountNo, -Amount, BalanceDocType);
    end;

    local procedure VerifyNoLinesAreImported(BatchName: Code[10]; TemplateName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        Assert.AreEqual(0, GenJournalLine.Count, 'There should be no lines created');
    end;

    local procedure VerifyPaymentLine(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; NoSeriesLine: Record "No. Series Line"; AccountNo: Code[20]; Amount: Decimal; DocumentNo: Code[35]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        Assert.AreEqual(PostingDate, GenJournalLine."Posting Date", 'Posting date was not set to a correct value');
        Assert.AreEqual(DocumentType, GenJournalLine."Document Type", 'Document Type was set to wrong value');
        Assert.AreEqual(NoSeriesLine."Starting No.", GenJournalLine."Document No.", 'Wrong document no. was set to the line');
        Assert.AreEqual(DocumentNo, GenJournalLine."External Document No.", 'External document no was set to a wrong value');
        Assert.AreEqual(
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Account Type", 'Account type was not set to a correct value');
        Assert.AreEqual(AccountNo, GenJournalLine."Account No.", 'Account no was not set to a correct value');
        Assert.AreEqual(Amount, GenJournalLine.Amount, 'Amount was not set to a correct value');
        Assert.AreEqual(
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account Type",
          'Bal. Account type is set to a wrong value');
        Assert.AreEqual('', GenJournalLine."Bal. Account No.", WrongBalAccNoErr);
        Assert.AreEqual(
          GenJournalLine."Applies-to Doc. Type"::Invoice, GenJournalLine."Applies-to Doc. Type",
          'Applies-to Date was not set to correct value');
        Assert.AreEqual(DocumentNo, GenJournalLine."Applies-to Doc. No.", 'Applies-to Doc. No. was not set to a correct value');
        Assert.AreEqual(false, GenJournalLine."Has Payment Export Error", 'Has payment export error was not set to correct value');
        Assert.AreEqual(true, GenJournalLine.IsApplied(), 'IsApplied was not set to a correct value');
    end;

    local procedure VerifyBalancingLine(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; NoSeriesLine: Record "No. Series Line"; AccountNo: Code[20]; Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    begin
        Assert.AreEqual(PostingDate, GenJournalLine."Posting Date", 'Posting date was not set to a correct value');
        Assert.AreEqual(DocumentType, GenJournalLine."Document Type", 'Document Type should be blank');
        Assert.AreEqual(NoSeriesLine."Starting No.", GenJournalLine."Document No.", 'Wrong document no. was set to the line');
        Assert.AreEqual('', GenJournalLine."External Document No.", 'External document No. should be blank');
        Assert.AreEqual(
          GenJournalLine."Account Type"::"Bank Account", GenJournalLine."Account Type", 'Account type was not set to a correct value');
        Assert.AreEqual(AccountNo, GenJournalLine."Account No.", 'Account no was not set to a correct value');
        Assert.AreEqual(Amount, GenJournalLine.Amount, 'Amount was not set to a correct value');
        Assert.AreEqual(
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account Type",
          'Bal. Account type is set to a wrong value');
        Assert.AreEqual(
          GenJournalLine."Applies-to Doc. Type"::" ", GenJournalLine."Applies-to Doc. Type",
          'Applies-to Date was not set to correct value');
        Assert.AreEqual('', GenJournalLine."Applies-to Doc. No.", 'Applies-to Doc. No. should be blank');
        Assert.AreEqual(false, GenJournalLine."Has Payment Export Error", 'Has payment export error was not set to correct value');
        Assert.AreEqual(false, GenJournalLine.IsApplied(), 'IsApplied was not set to a correct value');
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

    local procedure UpdateWorkdate(NewDate: Date) OldDate: Date
    begin
        OldDate := WorkDate();
        WorkDate := NewDate;
        if Date2DWY(NewDate, 1) in [6, 7] then // "Posting Date" and "Pmt. Discount Date" compared works date in CU 15000001
            WorkDate := WorkDate() + 2;
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
    procedure RemittanceExportBBSHandler(var RemittanceExportBBS: TestRequestPage "Remittance - export (BBS)")
    var
        RemittanceAgreementCode: Variant;
        FileName: Variant;
    begin
        LibraryVariableStorage.Dequeue(RemittanceAgreementCode);
        RemittanceExportBBS.RemAgreementCode.Value := RemittanceAgreementCode;
        LibraryVariableStorage.Dequeue(FileName);
        RemittanceExportBBS.CurrentFilename.Value := FileName;
        RemittanceExportBBS.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ImportPaymentsConfrimHandler(Question: Text[1024]; var Reply: Boolean)
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

