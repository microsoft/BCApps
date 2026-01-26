codeunit 144040 "Test LSV DD Payment Export"
{
    // // [FEATURE] [LSV] [Report]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryERM: Codeunit "Library - ERM";
        LibraryLSV: Codeunit "Library - LSV";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        FieldMustHaveValueErr: Label '%1 must have a value in %2';
        ConfirmCreateFileQst: Label 'Do you want to write the LSV file for journal %1?';
        LSVSetupDeleteErr: Label 'You cannot delete %1 there are entries in table %2.';
        IDSizeErr: Label '%1 must have 5 characters.';
        MissingCustBankAccErr: Label 'No valid LSV %1 for customer %2.';
        DeleteLSVJnlErr: Label 'You can only delete LSV Journal entries with Status edit or finished.';
        DeleteLSVJnlLineErr: Label 'Delete not allowed because File has already been created.';
        MissingGiroErr: Label 'Post account is not defined for customer %1';
        CloseCollectionMsg: Label 'The collection has been successfully prepared';
        ModifyPostingDateQst: Label 'Do you want to modify the field';
        ReopenCollectionQst: Label 'Reopen Collection, are you sure?';
        CombinePerCustErr: Label 'If you are working with automated processing confirmations by importing DebitDirect files you must not check field Combine by Customer.';
        UnexpDialogErr: Label 'Unexpected dialog - %1.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        DebitAuthorizationENUTxt: Label 'I hereby authorize my bank to deduct debits <b>in %1</b> from the above-listed creditor directly from my account until the authorization is revoked.';
        DebitAuthorizationCHTxt: Label 'Hiermit ermächtige ich meine Bank bis auf Widerruf, die ihr von obigem Zahlungsempfänger vorgelegten Lastschriften <b>in %1</b> meinem Konto zu belasten.';
        DebitAuthorizationFRTxt: Label 'Par la présente j''autorise ma banque, sous reserve de révocation, à débiter sur mon compte les recouvrements directs <b>en %1</b> émis par le bénéficiaire ci-dessus.';
        DebitAuthorizationITTxt: Label 'Con la presente autorizzo la mia banca revocabilmente ad addebitare sul mio conto gli avvisi di addebito <b>in %1</b> emessi dal beneficiario summenzionato.';

    [Test]
    [Scope('OnPrem')]
    procedure CheckLSVSetupSenderInfo()
    var
        LSVSetup: Record "LSV Setup";
    begin
        Initialize();

        // Setup.
        LSVSetup.Init();
        SetupCompanyInformation(LSVSetup);
        LSVSetup.Validate("LSV File Folder", '');
        LSVSetup.Insert(true);

        // Verify.
        VerifyLSVSetup(LSVSetup);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckLSVSetupOtherInfo()
    var
        BankAccount: Record "Bank Account";
        PostCode: Record "Post Code";
        Customer: Record Customer;
        LSVSetup: Record "LSV Setup";
        Path: Text[250];
        CustomerID: Text[10];
    begin
        Initialize();

        // Setup.
        Path := CreateGuid();
        CustomerID := CopyStr(LibraryUtility.GenerateRandomText(5), 1, 10);
        LibrarySales.CreateCustomer(Customer);

        PostCode.Init();
        PostCode.Validate(Code, LibraryUtility.GenerateRandomText(MaxStrLen(LSVSetup."LSV Sender Post Code")));
        PostCode.Insert(true);

        LibraryERM.CreateBankAccount(BankAccount);

        LSVSetup.Init();
        LSVSetup.Validate("Bank Code", BankAccount."No.");
        LSVSetup.Validate("LSV Customer ID", CustomerID);
        LSVSetup.Validate("LSV Sender Name",
          LibraryUtility.GenerateRandomCode(LSVSetup.FieldNo("LSV Sender Name"), DATABASE::"LSV Setup"));
        LSVSetup.Validate("LSV Sender ID", CustomerID);
        LSVSetup.Validate("LSV Sender Post Code", CopyStr(PostCode.Code, 1, MaxStrLen(LSVSetup."LSV Sender Post Code")));
        LSVSetup.Validate("LSV Bank Post Code", PostCode.Code);
        LSVSetup.Validate("LSV File Folder", CopyStr(Path, 1, MaxStrLen(LSVSetup."LSV File Folder")));
        LSVSetup.Validate("LSV Filename", '');
        LSVSetup.Validate("Computer Bureau Post Code", PostCode.Code);
        LSVSetup.Validate("DebitDirect Customerno.",
          CopyStr(Customer."No.", 1, MaxStrLen(LSVSetup."DebitDirect Customerno.")));
        LSVSetup.Validate("Backup Folder", Path);
        LSVSetup.Validate("DebitDirect Import Filename", CreateGuid());
        LSVSetup.Validate("Yellownet Home Page", CreateGuid());
        LSVSetup.Insert(true);

        // Verify.
        LSVSetup.TestField("LSV Customer ID", CustomerID);
        LSVSetup.TestField("LSV Sender ID", CustomerID);
        LSVSetup.TestField("LSV Sender City", PostCode.City);
        LSVSetup.TestField("LSV Bank City", PostCode.City);
        LSVSetup.TestField("Computer Bureau City", PostCode.City);
        LSVSetup.TestField("Backup Folder", Path);
        LSVSetup.TestField("LSV File Folder", Path + '\');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLSVSetupCustomerIDSizeError()
    var
        LSVSetup: Record "LSV Setup";
    begin
        Initialize();

        // Setup.
        LSVSetup.Init();

        // Exercise.
        asserterror LSVSetup.Validate("LSV Customer ID", LibraryUtility.GenerateRandomText(4));

        // Verify.
        Assert.ExpectedError(StrSubstNo(IDSizeErr, LSVSetup.FieldCaption("LSV Customer ID")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLSVSetupSenderIDSizeError()
    var
        LSVSetup: Record "LSV Setup";
    begin
        Initialize();

        // Setup.
        LSVSetup.Init();

        // Exercise.
        asserterror LSVSetup.Validate("LSV Sender ID", LibraryUtility.GenerateRandomText(4));

        // Verify.
        Assert.ExpectedError(StrSubstNo(IDSizeErr, LSVSetup.FieldCaption("LSV Customer ID")));
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure CheckLSVSetupOnDelete()
    var
        Customer: Record Customer;
        LSVSetup: Record "LSV Setup";
        LSVJnl: Record "LSV Journal";
    begin
        Initialize();

        // Setup.
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);

        // Exercise.
        asserterror LSVSetup.Delete(true);

        // Verify.
        Assert.ExpectedError(StrSubstNo(LSVSetupDeleteErr, LSVSetup."Bank Code", LSVJnl.TableName));
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler,LSVCloseCollectionReqPageHandler,WriteLSVFileReqPageHandler,CreateFileConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateLSVFileCustBankAccountHasNoIBANOrBankAccNo()
    var
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLinesFromLSVJournalList(LSVJnl);

        CustomerBankAccount.SetRange("Customer No.", Customer."No.");
        CustomerBankAccount.FindFirst();
        CustomerBankAccount.Validate(IBAN, '');
        CustomerBankAccount.Modify(true);

        // Exercise.
        Commit();
        asserterror RunWriteLSVFile(LSVJnl, false);

        // Verify
        Assert.ExpectedError(StrSubstNo(FieldMustHaveValueErr, CustomerBankAccount.FieldCaption(IBAN), CustomerBankAccount.TableName));
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler,LSVCloseCollectionReqPageHandler,WriteLSVFileReqPageHandler,CreateFileConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateLSVFileNoCustBankAccount()
    var
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLinesFromLSVJournalList(LSVJnl);

        CustomerBankAccount.SetRange("Customer No.", Customer."No.");
        CustomerBankAccount.DeleteAll(true);

        // Exercise.
        Commit();
        asserterror RunWriteLSVFile(LSVJnl, false);

        // Verify
        Assert.ExpectedError(StrSubstNo(MissingCustBankAccErr, 'bank was found', Customer."No."));
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler,LSVCloseCollectionReqPageHandler,WriteLSVFileReqPageHandler,CreateFileConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateLSVFileMultipleCustBankAccount()
    var
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLinesFromLSVJournalList(LSVJnl);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        // Exercise.
        Commit();
        asserterror RunWriteLSVFile(LSVJnl, false);

        // Verify
        Assert.ExpectedError(StrSubstNo(MissingCustBankAccErr, 'bank was found', Customer."No."));
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestLSVCollection()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        LSVJnlLine: Record "LSV Journal Line";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");

        // Exercise
        SuggestLSVJournalLines(LSVJnl);

        // Verify
        VerifyLSVJnl(LSVJnl."LSV Status"::Edit,
          FindCustLedgerEntries(CustLedgEntry, Customer."No."), CustLedgEntry.Count, '', LSVJnl);
        FindLSVJournalLines(LSVJnlLine, LSVJnl."No.");
        VerifyLSVJournalLines(LSVJnlLine, CustLedgEntry);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler,LSVCloseCollectionReqPageHandler,WriteLSVFileReqPageHandler,CreateFileConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DeleteLSVJournal()
    var
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLinesFromLSVJournalList(LSVJnl);
        RunWriteLSVFile(LSVJnl, false);

        // Exercise.
        asserterror LSVJnl.Delete(true);

        // Verify.
        Assert.ExpectedError(DeleteLSVJnlErr);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler,LSVCloseCollectionReqPageHandler,WriteLSVFileReqPageHandler,CreateFileConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DeleteLSVJournalLine()
    var
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        LSVJnlLine: Record "LSV Journal Line";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLinesFromLSVJournalList(LSVJnl);
        RunWriteLSVFile(LSVJnl, false);

        // Exercise.
        FindLSVJournalLines(LSVJnlLine, LSVJnl."No.");
        asserterror LSVJnlLine.DeleteAll(true);

        // Verify.
        Assert.ExpectedError(DeleteLSVJnlLineErr);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler,LSVCloseCollectionReqPageHandler,WriteLSVFileReqPageHandler,CreateFileConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeLSVJournalLineStatus()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        LSVJnlLine: Record "LSV Journal Line";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        FindCustLedgerEntries(CustLedgEntry, Customer."No.");
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLinesFromLSVJournalList(LSVJnl);
        RunWriteLSVFile(LSVJnl, false);

        // Exercise.
        FindLSVJournalLines(LSVJnlLine, LSVJnl."No.");
        repeat
            LSVJnlLine.Validate("LSV Status", LSVJnlLine."LSV Status"::Rejected);
        until LSVJnlLine.Next() = 0;
        LSVJnlLine.Modify(true);

        // Verify.
        CustLedgEntry.SetRange("LSV No.", LSVJnl."No.");
        Assert.IsTrue(CustLedgEntry.IsEmpty, 'Lsv Jnl No should be removed.');
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SuggestLSVCollectionWithCreditMemoAndDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        LSVJnlLine: Record "LSV Journal Line";
        CollectionAmount: Decimal;
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        CollectionAmount := FindCustLedgerEntries(CustLedgEntry, Customer."No.");
        SpecifyLSVCustomerForCollection(Customer."No.");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", CustLedgEntry."Document No.", true, true);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("No.", '<>%1', '');
        SalesLine.FindFirst();
        SalesLine.Validate("Line Amount", LibraryRandom.RandDec(SalesLine."Line Amount", 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        SuggestLSVJournalLines(LSVJnl);

        // Verify
        VerifyLSVJnl(LSVJnl."LSV Status"::Edit, CollectionAmount, CustLedgEntry.Count, '', LSVJnl);
        FindLSVJournalLines(LSVJnlLine, LSVJnl."No.");
        VerifyLSVJournalLines(LSVJnlLine, CustLedgEntry);
    end;

    [Test]
    [HandlerFunctions('CustLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure CreateLSVCollectionWithManualLines()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        CollectionAmount: Decimal;
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        Commit();

        // Exercise.
        FindCustLedgerEntries(CustLedgEntry, Customer."No.");
        CollectionAmount := CreateLSVCollection(CustLedgEntry, LSVJnl, LSVSetup);

        // Verify
        VerifyLSVJnl(LSVJnl."LSV Status"::Edit, CollectionAmount, CustLedgEntry.Count, '', LSVJnl);
    end;

    [Test]
    [HandlerFunctions('CustLedgerEntriesPageHandler,LSVCloseCollectionReqPageHandler,ConfirmHandler,CloseCollectionMsgHandler')]
    [Scope('OnPrem')]
    procedure CloseLSVCollectionWithManualLines()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        CollectionAmount: Decimal;
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        FindCustLedgerEntries(CustLedgEntry, Customer."No.");
        CollectionAmount := CreateLSVCollection(CustLedgEntry, LSVJnl, LSVSetup);

        // Exercise.
        CollectLSVJournalLinesFromLSVJournalList(LSVJnl);

        // Verify
        VerifyLSVJnl(LSVJnl."LSV Status"::Released, CollectionAmount, CustLedgEntry.Count, '', LSVJnl);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler,LSVCloseCollectionReqPageHandler,WriteDDFileReqPageHandler,CreateFileConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateDDFileFromLSVJournalNoCustBankAccount()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLinesFromLSVJournalList(LSVJnl);
        CustomerBankAccount.SetRange("Customer No.", Customer."No.");
        CustomerBankAccount.DeleteAll(true);

        // Exercise.
        Commit();
        asserterror WriteDDFile(LSVJnl, false);

        // Verify.
        Assert.ExpectedError(StrSubstNo(MissingCustBankAccErr, 'bank found', Customer."No."));
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler,LSVCloseCollectionReqPageHandler,WriteDDFileReqPageHandler,CreateFileConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateDDFileFromLSVJournalMultipleCustBankAccount()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLinesFromLSVJournalList(LSVJnl);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        // Exercise.
        Commit();
        asserterror WriteDDFile(LSVJnl, false);

        // Verify.
        Assert.ExpectedError(StrSubstNo(MissingCustBankAccErr, 'bank found', Customer."No."));
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler,LSVCloseCollectionReqPageHandler,WriteDDFileReqPageHandler,CreateFileConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateDDFileFromLSVJournalNoGIROForCustBankAccount()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLinesFromLSVJournalList(LSVJnl);
        CustomerBankAccount.SetRange("Customer No.", Customer."No.");
        CustomerBankAccount.FindFirst();
        CustomerBankAccount.Validate("Giro Account No.", '');
        CustomerBankAccount.Modify(true);

        // Exercise.
        Commit();
        asserterror WriteDDFile(LSVJnl, false);

        // Verify.
        Assert.ExpectedError(StrSubstNo(MissingGiroErr, Customer."No."));
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler,LSVCloseCollectionReqPageHandler,WriteDDFileReqPageHandler,CreateFileConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateDDFileWithCombinePerCustomerError()
    var
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLinesFromLSVJournalList(LSVJnl);

        // Exercise.
        Commit();
        asserterror WriteDDFile(LSVJnl, true);

        // Verify.
        Assert.ExpectedError(CombinePerCustErr);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler,LSVCloseCollectionReqPageHandler,WriteLSVFileReqPageHandler,CreateFileConfirmHandlerTrue,LSVCollectionOrderReqPageHandler')]
    [Scope('OnPrem')]
    procedure LSVCollectionOrder()
    var
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        LSVJournalList: TestPage "LSV Journal List";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);
        CollectLSVJournalLinesFromLSVJournalList(LSVJnl);
        RunWriteLSVFile(LSVJnl, false);

        // Exercise
        LSVJournalList.OpenView();
        LSVJournalList.GotoRecord(LSVJnl);
        LSVJournalList."LSV &Collection Order".Invoke();

        // Verify
        VerifyLSVCollectionOrderReport(LSVJnl, LSVSetup);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVCollectionAdviceReqPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LSVCollectionAdvice()
    var
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        LSVJournalList: TestPage "LSV Journal List";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);

        // Exercise
        LSVJournalList.OpenView();
        LSVJournalList.GotoRecord(LSVJnl);
        LSVJournalList."LSV Collection &Advice".Invoke();

        // Verify
        VerifyLSVCollectionAdviceReport(LSVJnl);
    end;

    [Test]
    [HandlerFunctions('LSVCustomerbankListReqPageHandler')]
    [Scope('OnPrem')]
    procedure LSVCustomerbankList()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        LibraryLSV.CreateLSVCustomerBankAccount(Customer);
        Customer.Delete();

        // Exercise
        Commit();
        CustomerBankAccount.SetRange("Customer No.", Customer."No.");
        REPORT.Run(REPORT::"LSV Customerbank List", true, true, CustomerBankAccount);

        // Verify
        VerifyLSVCustomerbankListReport(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('XmlLSVCollectionAuthorisationReqPageHandler')]
    [Scope('OnPrem')]
    procedure LSVCollectionAuthorisationXMLOutput()
    var
        Customer: Record Customer;
        LSVSetup: Record "LSV Setup";
    begin
        // [SCENARIO] Run "LSV Collection Authorization" report

        // [GIVEN] LSV Setup where "LSV Customer ID" = "Customer 1" and "LSV Currency Code" = "CC 1"
        Initialize();

        CreateLSVSetupAndCustomer(LSVSetup, Customer);
        LibraryVariableStorage.Enqueue(LSVSetup."Bank Code");

        // [WHEN] Run report "LSV Collection Authorization"
        Commit();
        REPORT.Run(REPORT::"LSV Collection Authorisation", true, false, Customer);

        // [THEN] DataSet."LSVCustID_LsvSetup" = "Customer 1"
        // [THEN] DataSet."LSVCurrCode_LsvSetup" = "CC 1"
        VerifyLSVCollectionAuthReportXML(Customer, LSVSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExcelLSVCollectionAuthorisationReqPageHandler')]
    [Scope('OnPrem')]
    procedure LSVCollectionAuthorisationExcelOutput()
    var
        Customer: Record Customer;
        LSVSetup: Record "LSV Setup";
    begin
        // [FEATURE] [Excel]
        // [SCENARIO] Export "LSV Collection Authorization" report as Excel

        // [GIVEN] LSV Setup where "LSV Customer ID" = "Customer 1" and "LSV Currency Code" = "CC 1"
        Initialize();

        CreateLSVSetupAndCustomer(LSVSetup, Customer);
        LibraryVariableStorage.Enqueue(LSVSetup."Bank Code");

        // [WHEN] Export "LSV Collection Authorization" report as Excel
        Commit();
        REPORT.Run(REPORT::"LSV Collection Authorisation", true, false, Customer);

        // [THEN] Excel."B1" cell = "Customer 1"
        // [THEN] Excel."AF1" cell = "CC 1"
        VerifyLSVCollectionAuthReportExcel(Customer, LSVSetup);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVCollectionJournalReqPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LSVCollectionJournal()
    var
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        LSVJournalList: TestPage "LSV Journal List";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);

        // Exercise
        LSVJournalList.OpenView();
        LSVJournalList.GotoRecord(LSVJnl);
        LSVJournalList."P&rint Journal".Invoke();

        // Verify
        VerifyLSVCollectionJournalReport(LSVJnl);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,MessageHandler,ModifyPostingDateModalPageHandler,ModifyPostingDateConfirmHandler')]
    [Scope('OnPrem')]
    procedure ModifyPostingDate()
    var
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        LSVJournalList: TestPage "LSV Journal List";
        NewDate: Date;
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLines(LSVJnl);

        // Exercise
        NewDate := LSVJnl."Credit Date" + LibraryRandom.RandInt(10);
        LibraryVariableStorage.Enqueue(NewDate);
        LSVJournalList.OpenView();
        LSVJournalList.GotoRecord(LSVJnl);
        LSVJournalList."Modify &Posting Date".Invoke();

        // Verify.
        LSVJnl.Find();
        LSVJnl.TestField("Credit Date", NewDate);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler,LSVCloseCollectionReqPageHandler,ReopenCollectionConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReopenCollection()
    var
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVSetup: Record "LSV Setup";
        LSVJournalList: TestPage "LSV Journal List";
    begin
        Initialize();

        // Setup
        PrepareLSVSalesDocsForCollection(Customer, LSVJnl, LSVSetup, '');
        SpecifyLSVCustomerForCollection(Customer."No.");
        SuggestLSVJournalLinesFromLSVJournal(LSVJnl);
        CollectLSVJournalLinesFromLSVJournal(LSVJnl);

        // Exercise
        LSVJournalList.OpenView();
        LSVJournalList.GotoRecord(LSVJnl);
        LSVJournalList."LSV Re&open Collection".Invoke();

        // Verify
        LSVJnl.Find();
        LSVJnl.TestField("LSV Status", LSVJnl."LSV Status"::Edit);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        Clear(LibraryReportValidation);

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Company Information");

        IsInitialized := true;
    end;

    local procedure SetupCompanyInformation(LSVSetup: Record "LSV Setup")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(LSVSetup."LSV Sender Name")));
        CompanyInformation.Validate("Name 2", LibraryUtility.GenerateRandomText(MaxStrLen(LSVSetup."LSV Sender Name 2")));
        CompanyInformation.Validate(Address, LibraryUtility.GenerateRandomText(MaxStrLen(LSVSetup."LSV Sender Address")));
        CompanyInformation.Validate(City, LibraryUtility.GenerateRandomText(MaxStrLen(LSVSetup."LSV Sender City")));
        CompanyInformation.Validate("Post Code", LibraryUtility.GenerateRandomText(MaxStrLen(LSVSetup."LSV Sender Post Code")));
        CompanyInformation.Validate("Bank Branch No.", LibraryUtility.GenerateRandomText(MaxStrLen(LSVSetup."LSV Sender Clearing")));
        CompanyInformation.Validate("Bank Account No.", LibraryUtility.GenerateRandomText(MaxStrLen(LSVSetup."LSV Credit on Account No.")));
        CompanyInformation.Modify(true);
    end;

    local procedure PrepareLSVSalesDocsForCollection(var Customer: Record Customer; var LSVJnl: Record "LSV Journal"; var LSVSetup: Record "LSV Setup"; CurrencyCode: Code[10])
    var
        ESRSetup: Record "ESR Setup";
        SalesHeader: Record "Sales Header";
    begin
        LibraryLSV.CreateESRSetup(ESRSetup);
        LibraryLSV.CreateLSVSetup(LSVSetup, ESRSetup);
        if CurrencyCode <> '' then begin
            LSVSetup.Validate("LSV Currency Code", CurrencyCode);
            LSVSetup.Modify(true);
        end;

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

    local procedure SpecifyLSVCustomerForCollection(CustomerNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(CustomerNo);
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

    local procedure SuggestLSVJournalLinesFromLSVJournal(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
        LSVJournal: TestPage "LSV Journal";
    begin
        Commit();
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJournal.Trap();
        LSVJnlList."LSV Journal Line".Invoke();
        LSVJournal."LSV Suggest Collection".Invoke();
    end;

    local procedure CollectLSVJournalLinesFromLSVJournalList(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        Commit();
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.LSVCloseCollection.Invoke();
    end;

    local procedure CollectLSVJournalLinesFromLSVJournal(var LSVJnl: Record "LSV Journal")
    var
        LSVJournal: TestPage "LSV Journal";
        LSVJnlList: TestPage "LSV Journal List";
    begin
        Commit();
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJournal.Trap();
        LSVJnlList."LSV Journal Line".Invoke();
        LSVJournal."&Close Collection".Invoke();
    end;

    local procedure CreateLSVCollection(var CustLedgerEntry: Record "Cust. Ledger Entry"; var LSVJnl: Record "LSV Journal"; LSVSetup: Record "LSV Setup") CollectionAmount: Decimal
    var
        LSVJournal: TestPage "LSV Journal";
        LSVJournalList: TestPage "LSV Journal List";
    begin
        LibraryLSV.CreateLSVJournal(LSVJnl, LSVSetup);
        LSVJournalList.OpenView();
        LSVJournalList.GotoRecord(LSVJnl);
        LSVJournal.Trap();
        LSVJournalList."LSV Journal Line".Invoke();
        CustLedgerEntry.FindSet();
        repeat
            LSVJournal.New();
            LSVJournal."Customer No.".SetValue(CustLedgerEntry."Customer No.");
            LSVJournal."Applies-to Doc. No.".Lookup();
            LSVJournal."Cust. Ledg. Entry No.".Lookup();
            LSVJournal."Cust. Ledg. Entry No.".SetValue(CustLedgerEntry."Entry No.");
            LSVJournal."Applies-to Doc. No.".SetValue(CustLedgerEntry."Document No.");
            LSVJournal."Collection Amount".SetValue(
              LibraryRandom.RandDecInDecimalRange(1,
                CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible", 2));
            CollectionAmount += LSVJournal."Collection Amount".AsDecimal();
            LSVJournal.Next();
        until CustLedgerEntry.Next() = 0;
        LSVJournal.Close();
        LSVJournalList.Close();

        exit(CollectionAmount);
    end;

    local procedure CreateLSVSetupAndCustomer(var LSVSetup: Record "LSV Setup"; var Customer: Record Customer)
    var
        ESRSetup: Record "ESR Setup";
    begin
        LSVSetup.DeleteAll();
        LibraryLSV.CreateESRSetup(ESRSetup);
        LibraryLSV.CreateLSVSetup(LSVSetup, ESRSetup);
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();
    end;

    local procedure RetrieveLSVCustomerForCollection() CustomerNo: Code[20]
    var
        CustomerNoAsVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNoAsVar);
        Evaluate(CustomerNo, CustomerNoAsVar);
    end;

    local procedure RunWriteLSVFile(var LSVJournal: Record "LSV Journal"; TestSending: Boolean)
    begin
        LibraryVariableStorage.Enqueue(TestSending);
        LibraryVariableStorage.Enqueue(ConfirmCreateFileQst);
        WriteLSVFile(LSVJournal);
        LSVJournal.Find();
    end;

    local procedure WriteLSVFile(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.WriteLSVFile.Invoke();
    end;

    local procedure WriteDDFile(var LSVJnl: Record "LSV Journal"; CombinePerCust: Boolean)
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        LibraryVariableStorage.Enqueue(CombinePerCust);
        LibraryVariableStorage.Enqueue(ConfirmCreateFileQst);
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.WriteDebitDirectFile.Invoke();
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
        LSVJnlLine.SetRange("LSV Journal No.", LSVJnlNo);
        LSVJnlLine.FindSet();
    end;

    local procedure VerifyLSVJournalLines(var LSVJnlLine: Record "LSV Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry.FindSet();
        repeat
            LSVJnlLine.SetRange("Customer No.", CustLedgEntry."Customer No.");
            LSVJnlLine.SetRange("Collection Amount",
              CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible");
            LSVJnlLine.SetRange("Currency Code", CustLedgEntry."Currency Code");
            LSVJnlLine.SetRange("Applies-to Doc. No.", CustLedgEntry."Document No.");
            LSVJnlLine.SetRange("Cust. Ledg. Entry No.", CustLedgEntry."Entry No.");
            LSVJnlLine.SetRange("Remaining Amount", CustLedgEntry."Remaining Amount");
            LSVJnlLine.SetRange("Pmt. Discount", CustLedgEntry."Remaining Pmt. Disc. Possible");
            LSVJnlLine.SetRange("Direct Debit Mandate ID", CustLedgEntry."Direct Debit Mandate ID");
            Assert.AreEqual(1, LSVJnlLine.Count, 'Unexpected LSV journal lines.');
            LSVJnlLine.FindFirst();
            LSVJnlLine.TestField("LSV Status", LSVJnlLine."LSV Status"::Open);
        until CustLedgEntry.Next() = 0;
    end;

    local procedure VerifyLSVSetup(LSVSetup: Record "LSV Setup")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();

        LSVSetup.TestField("LSV Sender Name", CompanyInformation.Name);
        LSVSetup.TestField("LSV Sender Name 2", CompanyInformation."Name 2");
        LSVSetup.TestField("LSV Sender Address", CompanyInformation.Address);
        LSVSetup.TestField("LSV Sender Post Code", CompanyInformation."Post Code");
        LSVSetup.TestField("LSV Sender City", CompanyInformation.City);
        LSVSetup.TestField("LSV Credit on Account No.", CompanyInformation."Bank Account No.");
        LSVSetup.TestField("LSV Sender Clearing", CopyStr(CompanyInformation."Bank Branch No.", 1,
            MaxStrLen(LSVSetup."LSV Sender Clearing")));
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

    local procedure VerifyLSVCollectionOrderReport(LSVJnl: Record "LSV Journal"; LSVSetup: Record "LSV Setup")
    begin
        LSVJnl.CalcFields("Amount Plus");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_LSVJnl', LSVJnl."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('AmtPlus_LSVJnl', LSVJnl."Amount Plus");
        LibraryReportDataset.AssertCurrentRowValueEquals('CreditDate_LSVJnl', Format(LSVJnl."Credit Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('LsvSetupLSVSenderIBAN', LSVSetup."LSV Sender IBAN");
        LibraryReportDataset.AssertCurrentRowValueEquals('LsvSetupLSVCustID', LSVSetup."LSV Customer ID");
        LibraryReportDataset.AssertCurrentRowValueEquals('LsvSetupLSVSenderID', LSVSetup."LSV Sender ID");
        LibraryReportDataset.AssertCurrentRowValueEquals('LsvSetupLSVSenderCity',
          LSVSetup."LSV Sender City" + ', ' + Format(LSVJnl."Credit Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('LsvSetupLSVCurrCode', LSVSetup."LSV Currency Code");
    end;

    local procedure VerifyLSVCollectionAdviceReport(LSVJnl: Record "LSV Journal")
    var
        LSVJnlLine: Record "LSV Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryReportDataset.LoadDataSetFile();
        FindLSVJournalLines(LSVJnlLine, LSVJnl."No.");
        repeat
            CustLedgerEntry.Get(LSVJnlLine."Cust. Ledg. Entry No.");
            CustLedgerEntry.CalcFields("Remaining Amount");
            LibraryReportDataset.SetRange('EntryNo_CustLedgerEntry', LSVJnlLine."Cust. Ledg. Entry No.");
            Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be one line per ledger entry.');
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('No_Customer', CustLedgerEntry."Customer No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('PostingDateFormatted', Format(CustLedgerEntry."Posting Date"));
            LibraryReportDataset.AssertCurrentRowValueEquals('Description_CustLedgerEntry', CustLedgerEntry.Description);
            LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo_CustLedgerEntry', CustLedgerEntry."Document No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('CollectionAmt', LSVJnlLine."Collection Amount");
            LibraryReportDataset.AssertCurrentRowValueEquals('Amount_CustLedgerEntry', CustLedgerEntry."Remaining Amount");
            LibraryReportDataset.AssertCurrentRowValueEquals('OriginalPmtDiscPossible', CustLedgerEntry."Original Pmt. Disc. Possible");
            LibraryReportDataset.AssertCurrentRowValueEquals('LsvJourCurrencyCode', LSVJnl."Currency Code");
        until LSVJnlLine.Next() = 0;
    end;

    local procedure VerifyLSVCustomerbankListReport(CustomerNo: Code[20])
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount.SetRange("Customer No.", CustomerNo);
        CustomerBankAccount.FindFirst();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Code_CustBankAcct', CustomerBankAccount.Code);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CustNo_CustBankAcct', CustomerNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('BankBranchNo_CustBankAcct', CustomerBankAccount."Bank Branch No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('GiroAccountNo_CustBankAcct', CustomerBankAccount."Giro Account No.");
    end;

    local procedure VerifyLSVCollectionAuthReportXML(Customer: Record Customer; LSVSetup: Record "LSV Setup")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('No_Cust', Customer.Name);
        LibraryReportDataset.AssertCurrentRowValueEquals('LSVCustID_LsvSetup', LSVSetup."LSV Customer ID");
        LibraryReportDataset.AssertCurrentRowValueEquals('Adr1', Customer.Name);
        LibraryReportDataset.AssertCurrentRowValueEquals('LSVCurrCode_LsvSetup', LSVSetup."LSV Currency Code");

        LibraryReportDataset.AssertCurrentRowValueEquals('CompanyAdr1', CompanyInformation.Name);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'DebitAuthorizationENUText', StrSubstNo(DebitAuthorizationENUTxt, LSVSetup."LSV Currency Code"));
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'DebitAuthorizationCHText', StrSubstNo(DebitAuthorizationCHTxt, LSVSetup."LSV Currency Code"));
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'DebitAuthorizationFRText', StrSubstNo(DebitAuthorizationFRTxt, LSVSetup."LSV Currency Code"));
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'DebitAuthorizationITText', StrSubstNo(DebitAuthorizationITTxt, LSVSetup."LSV Currency Code"));
    end;

    local procedure VerifyLSVCollectionAuthReportExcel(Customer: Record Customer; LSVSetup: Record "LSV Setup")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();

        LibraryReportValidation.OpenFile();
        LibraryReportValidation.VerifyCellValueByRef('E', 1, 1, LSVSetup."LSV Customer ID");
        LibraryReportValidation.VerifyCellValueByRef('C', 6, 1, CompanyInformation.Name);
        LibraryReportValidation.VerifyCellValueByRef('AK', 6, 1, Customer.Name);
        LibraryReportValidation.VerifyCellValueByRef('CJ', 1, 1, LSVSetup."LSV Currency Code");
    end;

    local procedure VerifyLSVCollectionJournalReport(LSVJnl: Record "LSV Journal")
    var
        LSVJnlLine: Record "LSV Journal Line";
    begin
        LibraryReportDataset.LoadDataSetFile();
        FindLSVJournalLines(LSVJnlLine, LSVJnl."No.");
        repeat
            LibraryReportDataset.SetRange('LSVJnlNo_LSVJnlLine', LSVJnl."No.");
            LibraryReportDataset.SetRange('LineNo_LSVJnlLine', LSVJnlLine."Line No.");
            Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be one line per journal line.');
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('CustNo_LSVJnlLine', LSVJnlLine."Customer No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('AppliesToDocNo_LSVJnlLine', LSVJnlLine."Applies-to Doc. No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('CollectionAmt_LSVJnlLine', LSVJnlLine."Collection Amount");
            LibraryReportDataset.AssertCurrentRowValueEquals('LSVCurrCode_LsvSetup', LSVJnl."Currency Code");
        until LSVJnlLine.Next() = 0;
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
    var
        TestSending: Variant;
    begin
        LibraryVariableStorage.Dequeue(TestSending);
        WriteLSVFile.TestSending.SetValue(TestSending);
        WriteLSVFile.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WriteDDFileReqPageHandler(var LSVWriteDebitDirectFile: TestRequestPage "LSV Write DebitDirect File")
    var
        CombinePerCust: Variant;
    begin
        LibraryVariableStorage.Dequeue(CombinePerCust);
        LSVWriteDebitDirectFile.Combine.SetValue(CombinePerCust);
        LSVWriteDebitDirectFile.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LSVCollectionOrderReqPageHandler(var LSVCollectionOrder: TestRequestPage "LSV Collection Order")
    begin
        LSVCollectionOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LSVCollectionAdviceReqPageHandler(var LSVCollectionAdvice: TestRequestPage "LSV Collection Advice")
    begin
        LSVCollectionAdvice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LSVCustomerbankListReqPageHandler(var LSVCustomerbankList: TestRequestPage "LSV Customerbank List")
    begin
        LSVCustomerbankList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure XmlLSVCollectionAuthorisationReqPageHandler(var LSVCollectionAuthorisation: TestRequestPage "LSV Collection Authorisation")
    begin
        LSVCollectionAuthorisation."LsvSetup.""Bank Code""".SetValue(LibraryVariableStorage.DequeueText());
        LSVCollectionAuthorisation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExcelLSVCollectionAuthorisationReqPageHandler(var LSVCollectionAuthorisation: TestRequestPage "LSV Collection Authorisation")
    var
        FileManagement: Codeunit "File Management";
    begin
        LibraryReportValidation.SetFullFileName(FileManagement.ServerTempFileName('xlsx'));
        LSVCollectionAuthorisation."LsvSetup.""Bank Code""".SetValue(LibraryVariableStorage.DequeueText());
        LSVCollectionAuthorisation.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LSVCollectionJournalReqPageHandler(var LSVCollectionJournal: TestRequestPage "LSV Collection Journal")
    begin
        LSVCollectionJournal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CreateFileConfirmHandlerTrue(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(UpperCase(LibraryVariableStorage.DequeueText()), UpperCase(Question));
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CreateFileConfirmHandlerFalse(Question: Text; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(UpperCase(Question), UpperCase(ConfirmCreateFileQst)) > 0, StrSubstNo(UnexpDialogErr, Question));
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure LSVJournalLinesCreatedMessageHandler(Message: Text)
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustLedgerEntriesPageHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        CustomerLedgerEntries.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CloseCollectionMsgHandler(Message: Text)
    begin
        Assert.IsTrue(StrPos(Message, CloseCollectionMsg) > 0, StrSubstNo(UnexpDialogErr, Message));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ModifyPostingDateConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, ModifyPostingDateQst) > 0, StrSubstNo(UnexpDialogErr, Question));
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModifyPostingDateModalPageHandler(var ModifyPostingDayInput: TestPage "Modify Posting Day Input")
    var
        NewDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(NewDate);
        ModifyPostingDayInput.NewPostingDate.SetValue(NewDate);
        ModifyPostingDayInput.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ReopenCollectionConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        case true of
            StrPos(UpperCase(Question), UpperCase(ConfirmCreateFileQst)) > 0:
                Reply := true;
            StrPos(Question, ReopenCollectionQst) > 0:
                Reply := true;
            else
                Assert.Fail(Question);
        end;
    end;
}

