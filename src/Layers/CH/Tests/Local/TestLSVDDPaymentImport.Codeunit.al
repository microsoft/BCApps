codeunit 144044 "Test LSV DD Payment Import"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryERM: Codeunit "Library - ERM";
        LibraryLSV: Codeunit "Library - LSV";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        WrongCurrErr: Label 'Only EUR and CHF can be collected.';

    [Normal]
    local procedure ImportDDFileCreditNoRejection(TransactionCode: Text; RejectionCode: Text; LSVStatus: Option; RejectionReason: Option; LSVJnlStatus: Option; BalLineCount: Integer; CurrencyCode: Code[10])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        LSVMgt: Codeunit LSVMgt;
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, CurrencyCode, LSVSetup."Bal. Account Type"::"G/L Account");
        LibraryVariableStorage.Enqueue(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLines(LSVJnl);
        WriteDDFile(LSVJnl);
        CreateDDGenJournal(GenJournalLine);

        // Exercise
        LibraryVariableStorage.Enqueue(LSVSetup."Bank Code");
        PrepareDDFileForRead(TransactionCode, RejectionCode);
        LSVMgt.ImportDebitDirectFile(GenJournalLine);

        // Verify.
        LSVJnl.Find();
        LSVJnl.CalcFields("Amount Plus");
        VerifyLSVJnl(LSVJnlStatus, FindCustLedgerEntries(CustLedgerEntry, Customer."No."), CustLedgerEntry.Count, CurrencyCode, LSVJnl);
        VerifyLSVJournalLines(CustLedgerEntry, LSVJnl, LSVStatus, RejectionReason);
        VerifyGenJournalLines(GenJournalLine, LSVJnl);
        VerifyBalancingGenJournalLine(GenJournalLine, LSVJnl, LSVSetup, LSVJnl."Amount Plus", BalLineCount);
        VerifyBackup(LSVSetup);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,MessageHandler,LSVCloseCollectionReqPageHandler,WriteDDFileReqPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportDDFileNoRejectionFCYNonEUR()
    var
        LSVJournalLine: Record "LSV Journal Line";
        LSVJournal: Record "LSV Journal";
    begin
        asserterror
          ImportDDFileCreditNoRejection('81', '00', LSVJournalLine."LSV Status"::"Closed by Import File",
            LSVJournalLine."DD Rejection Reason"::" ", LSVJournal."LSV Status"::Finished, 1,
            LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2)));
        Assert.ExpectedError(WrongCurrErr);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,MessageHandler,LSVCloseCollectionReqPageHandler,WriteLSVFileReqPageHandler,ConfirmHandler,LSVJournalListModalPageHandler')]
    [Scope('OnPrem')]
    procedure GetLSVLinesWithCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVJnlLine: Record "LSV Journal Line";
        LSVSetup: Record "LSV Setup";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '', LSVSetup."Bal. Account Type"::"G/L Account");

        // Create apply and post credit memo.
        FindCustLedgerEntries(CustLedgerEntry, Customer."No.");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", CustLedgerEntry."Document No.", true, true);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("No.", '<>%1', '');
        SalesLine.FindFirst();
        SalesLine.Validate("Line Amount", LibraryRandom.RandDec(SalesLine."Line Amount", 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Create LSV file.
        LibraryVariableStorage.Enqueue(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLines(LSVJnl);
        WriteLSVFile(LSVJnl);

        // Exercise
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal."&Get from LSV Journal".Invoke();

        // Verify.
        CashReceiptJournal.FILTER.SetFilter("Applies-to Doc. Type", Format(CustLedgerEntry."Document Type"));
        CashReceiptJournal.FILTER.SetFilter("Applies-to Doc. No.", CustLedgerEntry."Document No.");
        CashReceiptJournal.First();
        CustLedgerEntry.CalcFields("Remaining Amount");
        CashReceiptJournal.Amount.AssertEquals(CustLedgerEntry."Remaining Pmt. Disc. Possible" - CustLedgerEntry."Remaining Amount");

        LSVJnl.Find();
        VerifyLSVJnl(LSVJnl."LSV Status"::Finished, FindCustLedgerEntries(CustLedgerEntry, Customer."No."),
          CustLedgerEntry.Count, '', LSVJnl);
        FindLSVJournalLines(LSVJnlLine, LSVJnl."No.");
        CustLedgerEntry.FindSet();
        repeat
            VerifyLSVJournalLine(CustLedgerEntry, LSVJnlLine."LSV Status"::"Transferred to Pmt. Journal",
              LSVJnlLine."DD Rejection Reason"::" ");
        until CustLedgerEntry.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,MessageHandler,LSVCloseCollectionReqPageHandler,WriteLSVFileReqPageHandler,ConfirmHandler,LSVJournalListModalPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteImportedLinesResetsStatus()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVJnlLine: Record "LSV Journal Line";
        LSVSetup: Record "LSV Setup";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        Initialize();

        // Setup
        GenJournalLine.DeleteAll();
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '', LSVSetup."Bal. Account Type"::"G/L Account");
        LibraryVariableStorage.Enqueue(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLines(LSVJnl);
        WriteLSVFile(LSVJnl);
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal."&Get from LSV Journal".Invoke();

        // Exercise.
        GenJournalLine.DeleteAll(true);

        // Verify.
        LSVJnl.Find();
        VerifyLSVJnl(LSVJnl."LSV Status"::"File Created", FindCustLedgerEntries(CustLedgerEntry, Customer."No."),
          CustLedgerEntry.Count, '', LSVJnl);
        FindLSVJournalLines(LSVJnlLine, LSVJnl."No.");
        CustLedgerEntry.FindSet();
        repeat
            VerifyLSVJournalLine(CustLedgerEntry, LSVJnlLine."LSV Status"::Open, LSVJnlLine."DD Rejection Reason"::" ");
        until CustLedgerEntry.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,MessageHandler,LSVCloseCollectionReqPageHandler,WriteLSVFileReqPageHandler,ConfirmHandler,LSVJournalListModalPageHandler,ESRJournalReqPageHandler')]
    [Scope('OnPrem')]
    procedure PrintESRJournal()
    var
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '', LSVSetup."Bal. Account Type"::"G/L Account");
        LibraryVariableStorage.Enqueue(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLines(LSVJnl);
        WriteLSVFile(LSVJnl);
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal."&Get from LSV Journal".Invoke();

        // Exercise
        Commit();
        CashReceiptJournal."Print ESR Journal".Invoke();

        // Verify.
        VerifyESRJournal(LSVJnl);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test LSV DD Payment Import");
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test LSV DD Payment Import");

        GeneralLedgerSetup.Get();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test LSV DD Payment Import");
    end;

    local procedure SetupLSVForDirectDebit(var LSVSetup: Record "LSV Setup"; CurrencyCode: Code[10]; BalAccType: Option)
    var
        ESRSetup: Record "ESR Setup";
        BankAccount: Record "Bank Account";
        GLAccount: Record "G/L Account";
    begin
        LibraryLSV.CreateESRSetup(ESRSetup);
        LibraryLSV.CreateLSVSetup(LSVSetup, ESRSetup);
        if CurrencyCode <> '' then
            LSVSetup.Validate("LSV Currency Code", CurrencyCode);

        LSVSetup.Validate("Bal. Account Type", BalAccType);
        case BalAccType of
            LSVSetup."Bal. Account Type"::"G/L Account":
                begin
                    LibraryERM.CreateGLAccount(GLAccount);
                    LSVSetup.Validate("Bal. Account No.", GLAccount."No.");
                end;
            LSVSetup."Bal. Account Type"::"Bank Account":
                begin
                    LibraryERM.CreateBankAccount(BankAccount);
                    LSVSetup.Validate("Bal. Account No.", BankAccount."No.");
                end;
        end;

        LSVSetup.Validate("DebitDirect Import Filename", TemporaryPath + LSVSetup."LSV Filename");
        LSVSetup.Validate("Backup Folder", TemporaryPath);
        LSVSetup.Validate("Backup Copy", true);
        LSVSetup.Modify(true);
    end;

    local procedure SetupESRForLSV(LSVSetup: Record "LSV Setup")
    var
        ESRSetup: Record "ESR Setup";
    begin
        ESRSetup.Get(LSVSetup."ESR Bank Code");
        ESRSetup.Validate("ESR Filename",
          CopyStr(LSVSetup."LSV File Folder" + LSVSetup."LSV Filename", 1, MaxStrLen(ESRSetup."ESR Filename")));
        ESRSetup.Validate("Bal. Account Type", LSVSetup."Bal. Account Type");
        ESRSetup.Validate("Bal. Account No.", LSVSetup."Bal. Account No.");
        ESRSetup.Modify(true);
    end;

    local procedure PrepareLSVSalesDocsForCollection(var Customer: Record Customer; var LSVJnl: Record "LSV Journal"; var LSVSetup: Record "LSV Setup"; CurrencyCode: Code[10]; BalAccType: Option)
    var
        SalesHeader: Record "Sales Header";
    begin
        SetupLSVForDirectDebit(LSVSetup, CurrencyCode, BalAccType);
        SetupESRForLSV(LSVSetup);
        LibraryLSV.CreateLSVJournal(LSVJnl, LSVSetup);
        LibraryLSV.CreateLSVCustomer(Customer, LSVSetup."LSV Payment Method Code");
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        LibraryLSV.CreateLSVCustomerBankAccount(Customer);
        CreateLSVSalesDoc(SalesHeader, Customer."No.", SalesHeader."Document Type"::Invoice);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateLSVSalesDoc(SalesHeader, Customer."No.", SalesHeader."Document Type"::Invoice);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateLSVSalesDoc(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; DocType: Enum "Sales Document Type")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.FindItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustomerNo);
        SalesHeader.Validate("Payment Discount %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Validate("Due Date", WorkDate());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure SuggestLSVJournalLines(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        Commit();
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.LSVSuggestCollection.Invoke();
    end;

    local procedure CollectLSVJournalLines(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        Commit();
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.LSVCloseCollection.Invoke();
    end;

    local procedure CreateDDGenJournal(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", '', 0);
        GenJournalLine.Delete();
    end;

    local procedure RetrieveLSVCustomerForCollection() CustomerNo: Code[20]
    var
        CustomerNoAsVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNoAsVar);
        Evaluate(CustomerNo, CustomerNoAsVar);
    end;

    local procedure WriteLSVFile(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.WriteLSVFile.Invoke();
    end;

    local procedure WriteDDFile(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.WriteDebitDirectFile.Invoke();
    end;

    local procedure PrepareDDFileForRead(TransactionCode: Text; RejectionCode: Text)
    var
        FileMgt: Codeunit "File Management";
        DDFile: File;
        OutStream: OutStream;
        Line: Text[1024];
        NextLine: Text[1024];
        InputFileName: Text[1024];
        OutputFileName: Text;
        LineNo: Integer;
    begin
        OutputFileName := FileMgt.ServerTempFileName('');
        DDFile.TextMode(true);
        DDFile.WriteMode(true);
        DDFile.Create(OutputFileName);
        DDFile.CreateOutStream(OutStream);

        // First payment is always processed.
        Line := LibraryTextFileValidation.ReadLine(InputFileName, 2);
        Line := InsStr(DelStr(Line, 36, 2), '81', 36);
        Line := InsStr(DelStr(Line, 543, 2), '00', 543);
        DDFile.Write(Line);

        // Subsequent payments get the requested transaction / rejection codes.
        LineNo := 3;
        Line := LibraryTextFileValidation.ReadLine(InputFileName, LineNo);
        repeat
            LineNo += 1;
            NextLine := LibraryTextFileValidation.ReadLine(InputFileName, LineNo);
            if NextLine <> '' then begin
                Line := InsStr(DelStr(Line, 36, 2), TransactionCode, 36);
                Line := InsStr(DelStr(Line, 543, 2), RejectionCode, 543);
            end;
            DDFile.Write(Line);
            Line := NextLine;
        until NextLine = '';

        DDFile.Close();
    end;

    local procedure FindCustLedgerEntries(var CustLedgEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]) CollectionAmount: Decimal
    begin
        CustLedgEntry.SetAutoCalcFields("Remaining Amt. (LCY)", "Amount (LCY)", "Remaining Amount");
        CustLedgEntry.SetRange("Customer No.", CustomerNo);
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.FindSet();
        repeat
            CollectionAmount += CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";
        until CustLedgEntry.Next() = 0;
    end;

    local procedure FindLSVJournalLines(var LSVJnlLine: Record "LSV Journal Line"; LSVJnlNo: Integer)
    begin
        LSVJnlLine.Reset();
        LSVJnlLine.SetRange("LSV Journal No.", LSVJnlNo);
        LSVJnlLine.FindSet();
    end;

    local procedure FindGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; TemplateGenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", TemplateGenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", TemplateGenJournalLine."Journal Batch Name");
        GenJournalLine.FindSet();
    end;

    local procedure VerifyLSVJournalLines(var CustLedgEntry: Record "Cust. Ledger Entry"; LSVJnl: Record "LSV Journal"; ExpStatus: Option; DDRejReason: Option)
    var
        LSVJnlLine: Record "LSV Journal Line";
    begin
        FindLSVJournalLines(LSVJnlLine, LSVJnl."No.");

        CustLedgEntry.FindSet();
        VerifyLSVJournalLine(CustLedgEntry, LSVJnlLine."LSV Status"::"Closed by Import File", LSVJnlLine."DD Rejection Reason"::" ");

        while CustLedgEntry.Next() <> 0 do
            VerifyLSVJournalLine(CustLedgEntry, ExpStatus, DDRejReason);
    end;

    local procedure VerifyLSVJournalLine(CustLedgEntry: Record "Cust. Ledger Entry"; ExpStatus: Option; DDRejReason: Option)
    var
        LSVJnlLine: Record "LSV Journal Line";
    begin
        LSVJnlLine.SetRange("Cust. Ledg. Entry No.", CustLedgEntry."Entry No.");
        Assert.AreEqual(1, LSVJnlLine.Count, 'Unexpected lsv jnl lines.');
        LSVJnlLine.FindFirst();

        LSVJnlLine.TestField("Customer No.", CustLedgEntry."Customer No.");
        LSVJnlLine.TestField("Collection Amount",
          CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible");
        LSVJnlLine.TestField("Currency Code", CustLedgEntry."Currency Code");
        LSVJnlLine.TestField("Cust. Ledg. Entry No.", CustLedgEntry."Entry No.");
        LSVJnlLine.TestField("Remaining Amount", CustLedgEntry."Remaining Amount");
        LSVJnlLine.TestField("Pmt. Discount", CustLedgEntry."Remaining Pmt. Disc. Possible");
        LSVJnlLine.TestField("Direct Debit Mandate ID", CustLedgEntry."Direct Debit Mandate ID");
        LSVJnlLine.TestField("LSV Status", ExpStatus);
        LSVJnlLine.TestField("DD Rejection Reason", DDRejReason);
    end;

    local procedure VerifyGenJournalLines(TemplateGenJournalLine: Record "Gen. Journal Line"; LSVJnl: Record "LSV Journal")
    var
        LSVJournalLine: Record "LSV Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FindLSVJournalLines(LSVJournalLine, LSVJnl."No.");
        FindGenJournalLines(GenJournalLine, TemplateGenJournalLine);

        LSVJournalLine.SetRange("DD Rejection Reason", LSVJournalLine."DD Rejection Reason"::" ");
        Assert.AreEqual(LSVJournalLine.Count + 1, GenJournalLine.Count, 'Unexpected gen. journal lines.');
        LSVJournalLine.FindSet();
        repeat
            VerifyGenJournalLine(GenJournalLine, LSVJnl, LSVJournalLine, GenJournalLine."Document Type"::Payment, 1);
        until LSVJournalLine.Next() = 0;

        LSVJournalLine.SetRange("DD Rejection Reason", LSVJournalLine."DD Rejection Reason"::"Customer protestation");
        if LSVJournalLine.FindSet() then
            repeat
                VerifyGenJournalLine(GenJournalLine, LSVJnl, LSVJournalLine, GenJournalLine."Document Type"::Refund, 1);
            until LSVJournalLine.Next() = 0;

        LSVJournalLine.SetRange("DD Rejection Reason",
          LSVJournalLine."DD Rejection Reason"::"Customer account number and address do not match",
          LSVJournalLine."DD Rejection Reason"::"Postal account number non-existent");
        if LSVJournalLine.FindSet() then
            repeat
                VerifyGenJournalLine(GenJournalLine, LSVJnl, LSVJournalLine, GenJournalLine."Document Type"::Payment, 0);
            until LSVJournalLine.Next() = 0;
    end;

    local procedure VerifyGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; LSVJnl: Record "LSV Journal"; LSVJnlLine: Record "LSV Journal Line"; ExpDocumentType: Enum "Gen. Journal Document Type"; ExpCount: Integer)
    begin
        GenJournalLine.SetRange("Posting Date", LSVJnl."Credit Date");
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.SetRange("Account No.", LSVJnlLine."Customer No.");
        GenJournalLine.SetRange("Document Type", ExpDocumentType);
        if ExpDocumentType = GenJournalLine."Document Type"::Payment then
            GenJournalLine.SetRange(Amount, -LSVJnlLine."Collection Amount")
        else
            GenJournalLine.SetRange(Amount, LSVJnlLine."Collection Amount");
        GenJournalLine.SetRange("Currency Code", GeneralLedgerSetup.GetCurrencyCode(LSVJnl."Currency Code"));
        if LSVJnlLine."DD Rejection Reason" <> LSVJnlLine."DD Rejection Reason"::"Customer protestation" then
            GenJournalLine.SetRange("Applies-to Doc. No.", LSVJnlLine."Applies-to Doc. No.")
        else
            GenJournalLine.SetRange("Applies-to Doc. No.");

        Assert.AreEqual(ExpCount, GenJournalLine.Count, GenJournalLine.GetFilters);
    end;

    local procedure VerifyBalancingGenJournalLine(TemplateGenJournalLine: Record "Gen. Journal Line"; LSVJnl: Record "LSV Journal"; LSVSetup: Record "LSV Setup"; ExpBalAmt: Decimal; ExpCount: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FindGenJournalLines(GenJournalLine, TemplateGenJournalLine);

        GenJournalLine.SetRange("Posting Date", LSVJnl."Credit Date");
        case LSVSetup."Bal. Account Type" of
            LSVSetup."Bal. Account Type"::"G/L Account":
                GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
            LSVSetup."Bal. Account Type"::"Bank Account":
                GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"Bank Account");
        end;
        GenJournalLine.SetRange("Account No.", LSVSetup."Bal. Account No.");
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Source Code", 'ESR');
        Assert.AreEqual(ExpCount, GenJournalLine.Count, 'Unexpected balancing gen. journal line.');
        if GenJournalLine.FindFirst() then
            GenJournalLine.TestField(Amount, ExpBalAmt);
    end;

    local procedure VerifyLSVJnl(ExpStatus: Option; ExpAmount: Decimal; ExpCount: Integer; ExpCurrencyCode: Code[10]; LSVJnl: Record "LSV Journal")
    var
        GeneralMgt: Codeunit GeneralMgt;
    begin
        LSVJnl.Find();
        LSVJnl.CalcFields("No. Of Entries Plus", "Amount Plus");
        LSVJnl.TestField("LSV Status", ExpStatus);
        LSVJnl.TestField("No. Of Entries Plus", ExpCount);
        LSVJnl.TestField("Amount Plus", ExpAmount);
        LSVJnl.TestField("Currency Code", GeneralMgt.CheckCurrency(ExpCurrencyCode));
    end;

    local procedure VerifyBackup(LSVSetup: Record "LSV Setup")
    begin
        LSVSetup.Find();
        Assert.IsTrue(Exists(LSVSetup."Backup Folder" + 'DD' + LSVSetup."Last Backup No." + '.BAK'),
          'No backup was created in' + LSVSetup."Backup Folder" + 'DD' + LSVSetup."Last Backup No." + '.BAK');
        Erase(LSVSetup."Backup Folder" + 'DD' + LSVSetup."Last Backup No." + '.BAK');
    end;

    local procedure VerifyESRJournal(LSVJnl: Record "LSV Journal")
    var
        LSVJournalLine: Record "LSV Journal Line";
    begin
        LibraryReportDataset.LoadDataSetFile();
        FindLSVJournalLines(LSVJournalLine, LSVJnl."No.");
        repeat
            LibraryReportDataset.SetRange('AppliestoDocNo_GenJournalLine', LSVJournalLine."Applies-to Doc. No.");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('AccountNo_GenJournalLine', LSVJournalLine."Customer No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('Customer_Name', LSVJournalLine.Name);
            LibraryReportDataset.AssertCurrentRowValueEquals('Amount', LSVJournalLine."Collection Amount");
            LibraryReportDataset.AssertCurrentRowValueEquals('CashDeductAmt', LSVJournalLine."Pmt. Discount");
        until LSVJournalLine.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LSVSuggestCollectionReqPageHandler(var LSVSuggestCollection: TestRequestPage "LSV Suggest Collection")
    begin
        LSVSuggestCollection.FromDueDate.SetValue(WorkDate());
        LSVSuggestCollection.ToDueDate.SetValue(WorkDate());
        LSVSuggestCollection.Customer.SetFilter("No.", RetrieveLSVCustomerForCollection());
        LSVSuggestCollection.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LSVCloseCollectionReqPageHandler(var LSVCloseCollection: TestRequestPage "LSV Close Collection")
    begin
        LSVCloseCollection.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WriteLSVFileReqPageHandler(var WriteLSVFile: TestRequestPage "Write LSV File")
    begin
        WriteLSVFile.TestSending.SetValue(false);
        WriteLSVFile.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WriteDDFileReqPageHandler(var LSVWriteDebitDirectFile: TestRequestPage "LSV Write DebitDirect File")
    begin
        LSVWriteDebitDirectFile.Combine.SetValue(false);
        LSVWriteDebitDirectFile.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LSVSetupListModalPageHandler(var LSVSetupList: TestPage "LSV Setup List")
    var
        LSVSetupCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(LSVSetupCode);
        LSVSetupList.FILTER.SetFilter("Bank Code", LSVSetupCode);
        LSVSetupList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LSVJournalListModalPageHandler(var LSVJournalList: TestPage "LSV Journal List")
    begin
        LSVJournalList.Last();
        LSVJournalList.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ESRJournalReqPageHandler(var CustomerESRJournal: TestRequestPage "Customer ESR Journal")
    begin
        CustomerESRJournal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

