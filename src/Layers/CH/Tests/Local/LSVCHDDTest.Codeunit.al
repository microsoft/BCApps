codeunit 144001 "LSV CH DD Test"
{
    // // [FEATURE] [LSV]
    // 
    // LSV CH Direct Debit Tests
    // 
    //   1. CreateLSVDirectDebitLines
    //   2. LaunchLSVWriteDirectDebitFile
    //   3. LaunchWriteLSVFile
    //   4. Try to import DD File with rejected lines.
    // 
    // TFS ID = 91091
    // Covers Test cases:
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                       TFS ID
    // ---------------------------------------------------------------------------------------------------
    // LaunchLSVImportDirectDebitFile                                                            91091

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryLSV: Codeunit "Library - LSV";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CollectionSuccesfullySuggestedMsg: Label 'Collection has been successfully suggested.';
        RecordNotFoundErr: Label '%1 record was not found.';
        UnexpectedMessageDialogErr: Label 'Unexpected message: %1';

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateLSVDirectDebitLines()
    var
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        LSVJnl: Record "LSV Journal";
        LSVJnlLine: Record "LSV Journal Line";
    begin
        // [FEATURE] [LSV Journal] [Payment Method Code]

        // [GIVEN] Two Sales Documents are posted: one with empty Payment Method Code, second - LSV
        PrepareLSVSalesDocForCollection(Customer, LSVJnl);

        // [WHEN] Create LSV Journal and Journal Lines
        SpecifyLSVCustomerForCollection(Customer."No.");
        CreateLSVJournalLines(LSVJnl);

        // [WHEN] LSV Journal and Lines are based only on Sales document with LSV Payment Method
        FindCustLedgerEntries(CustLedgEntry, Customer."No.");
        CheckCustLedgerEntriesAreOnHold(CustLedgEntry);
        FindLSVJournalLines(LSVJnlLine, LSVJnl."No.");
        ValidateLSVJournalLines(LSVJnlLine, CustLedgEntry);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVCloseCollectionReqPageHandler,MessageHandler,WriteLSVDirectDebitFileReqPageHandler,WriteFileConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure LaunchLSVWriteDirectDebitFile()
    var
        LSVJnl: Record "LSV Journal";
        LSVBankCode: Code[20];
    begin
        // Setup
        LSVBankCode := PrepareLaunchLSVWriteDirectDebitFile(LSVJnl);

        // Exercise
        WriteLSVDirectDebitFile(LSVJnl);

        // Verify
        ValidateLSVFileIsCreated(LSVBankCode);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVCloseCollectionReqPageHandler,MessageHandler,WriteLSVFileReqPageHandler,WriteFileConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure LaunchWriteLSVFile()
    var
        LSVJnl: Record "LSV Journal";
        LSVBankCode: Code[20];
    begin
        // Setup
        LSVBankCode := PrepareLaunchLSVWriteDirectDebitFile(LSVJnl);

        // Exercise
        WriteLSVFile(LSVJnl);

        // Verify
        ValidateLSVFileIsCreated(LSVBankCode);
    end;

    local procedure PrepareLaunchLSVWriteDirectDebitFile(var LSVJnl: Record "LSV Journal") LSVBankCode: Code[20]
    var
        Customer: Record Customer;
    begin
        LSVBankCode := PrepareLSVSalesDocForCollection(Customer, LSVJnl);
        SpecifyLSVCustomerForCollection(Customer."No.");
        CreateLSVJournalLines(LSVJnl);
        CloseLSVJournal(LSVJnl);
    end;

    local procedure PrepareLSVSalesDocForCollection(var Customer: Record Customer; var LSVJnl: Record "LSV Journal") LSVBankCode: Code[20]
    var
        ESRSetup: Record "ESR Setup";
        LSVSetup: Record "LSV Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryLSV.CreateESRSetup(ESRSetup);
        LSVBankCode := LibraryLSV.CreateLSVSetup(LSVSetup, ESRSetup);
        LSVSetup."Bal. Account Type" := LSVSetup."Bal. Account Type"::"G/L Account";
        GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        LibraryERM.FindGLAccount(GLAccount);
        LSVSetup."Bal. Account No." := GLAccount."No.";
        LSVSetup.Modify();
        LibraryLSV.CreateLSVJournal(LSVJnl, LSVSetup);
        LibraryLSV.CreateLSVCustomer(Customer, '');
        CreatePostLSVSalesDocs(Customer."No.", 1);
        Customer."Payment Method Code" := LSVSetup."LSV Payment Method Code";
        Customer.Modify();
        LibraryLSV.CreateLSVCustomerBankAccount(Customer);
        CreatePostLSVSalesDocs(Customer."No.", 1);
    end;

    local procedure CreateLSVSalesDoc(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.FindItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure PostLSVSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePostLSVSalesDocs(CustomerNo: Code[20]; NoOfDocs: Integer)
    var
        SalesHeader: Record "Sales Header";
        i: Integer;
    begin
        for i := 1 to NoOfDocs do begin
            CreateLSVSalesDoc(SalesHeader, CustomerNo);
            PostLSVSalesDoc(SalesHeader);
        end;
    end;

    local procedure SpecifyLSVCustomerForCollection(CustomerNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(CustomerNo);
    end;

    local procedure CreateLSVJournalLines(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.LSVSuggestCollection.Invoke();
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

    local procedure RetrieveLSVCustomerForCollection() CustomerNo: Code[20]
    var
        CustomerNoAsVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNoAsVar);
        Evaluate(CustomerNo, CustomerNoAsVar);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure LSVJournalLinesCreatedMessageHandler(Message: Text[1024])
    begin
        Assert.AreNotEqual(0, StrPos(Message, CollectionSuccesfullySuggestedMsg), StrSubstNo(UnexpectedMessageDialogErr, Message));
    end;

    local procedure FindCustLedgerEntries(var CustLedgEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    begin
        CustLedgEntry.SetRange("Customer No.", CustomerNo);
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetFilter("Payment Method Code", '<>%1', '');
        CustLedgEntry.FindLast();
    end;

    local procedure CheckCustLedgerEntriesAreOnHold(CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        repeat
            Assert.AreEqual(CustLedgEntry."On Hold", 'LSV', CustLedgEntry.FieldCaption("On Hold"));
            Assert.AreEqual(CustLedgEntry.Open, true, CustLedgEntry.FieldCaption(Open));
        until CustLedgEntry.Next() = 0;
    end;

    local procedure FindLSVJournalLines(var LSVJnlLine: Record "LSV Journal Line"; LSVJnlNo: Integer)
    begin
        LSVJnlLine.SetRange("LSV Journal No.", LSVJnlNo);
        LSVJnlLine.FindSet();
    end;

    local procedure ValidateLSVJournalLines(LSVJnlLine: Record "LSV Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry")
    var
        LSVJournal: Record "LSV Journal";
    begin
        repeat
            LSVJnlLine.SetRange("Customer No.", CustLedgEntry."Customer No.");
            LSVJnlLine.SetRange("Currency Code", CustLedgEntry."Currency Code");
            LSVJnlLine.SetRange("Applies-to Doc. No.", CustLedgEntry."Document No.");
            LSVJnlLine.SetRange("Cust. Ledg. Entry No.", CustLedgEntry."Entry No.");
            CustLedgEntry.CalcFields(Amount);
            LSVJnlLine.SetRange("Remaining Amount", CustLedgEntry.Amount);
            Assert.IsFalse(LSVJnlLine.IsEmpty, StrSubstNo(RecordNotFoundErr, LSVJnlLine.TableCaption));
        until CustLedgEntry.Next() = 0;

        LSVJournal.Get(LSVJnlLine."LSV Journal No.");
        LSVJournal.CalcFields("No. Of Entries Plus");
        LSVJournal.TestField("No. Of Entries Plus", 1);
    end;

    local procedure CloseLSVJournal(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.LSVCloseCollection.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LSVCloseCollectionReqPageHandler(var LSVCloseCollection: TestRequestPage "LSV Close Collection")
    begin
        LSVCloseCollection.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure WriteLSVDirectDebitFile(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.WriteDebitDirectFile.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WriteLSVDirectDebitFileReqPageHandler(var LSVWriteDebitDirectFile: TestRequestPage "LSV Write DebitDirect File")
    begin
        LSVWriteDebitDirectFile.OK().Invoke();
    end;

    local procedure WriteLSVFile(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.WriteLSVFile.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WriteLSVFileReqPageHandler(var WriteLSVFile: TestRequestPage "Write LSV File")
    begin
        WriteLSVFile.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LSVSetupListModalPageHandler(var LSVSetupListModalPage: TestPage "LSV Setup List")
    var
        BankCodeVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankCodeVar);
        LSVSetupListModalPage.GotoKey(BankCodeVar);
        LSVSetupListModalPage.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure WriteFileConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure ValidateLSVFileIsCreated(LSVBankCode: Code[20])
    var
        LSVJnl: Record "LSV Journal";
    begin
        LSVJnl.SetRange("LSV Bank Code", LSVBankCode);
        LSVJnl.FindFirst();
        Assert.AreEqual(LSVJnl."Collection Completed On", Today, LSVJnl.FieldCaption("Collection Completed On"));
        Assert.AreEqual(LSVJnl."Collection Completed By", UserId, LSVJnl.FieldCaption("Collection Completed By"));
        Assert.AreEqual(LSVJnl."File Written On", Today, LSVJnl.FieldCaption("File Written On"));
        Assert.AreEqual(LSVJnl."LSV Status", LSVJnl."LSV Status"::"File Created", LSVJnl.FieldCaption("LSV Status"));
    end;
}

