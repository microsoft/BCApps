codeunit 144002 "SEPA DD Integration Test - CH"
{
    // SEPA CH Direct Debit Test

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryLSV: Codeunit "Library - LSV";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CollectionHasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        CollectionSuccesfullySuggestedMsg: Label 'Collection has been successfully suggested.';
        CountOfRecordsErr: Label 'Total number of %1 records is incorrect.';
        FieldMustHaveValueErr: Label '%1 must have a value in %2';
        FilterRangeErr: Label 'Specify a filter for the %1 field in the %2 table.';
        RecordNotFoundErr: Label '%1 record was not found.';
        RecordWithinFilterNotFoundErr: Label 'The %1 records were not found.';
        UnexpectedMessageDialogErr: Label 'Unexpected message: %1';

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateDirectDebitCollectionFromLSVJournal()
    var
        Customer: Record Customer;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        LSVJnl: Record "LSV Journal";
    begin
        // Pre-Setup
        PrepareLSVSalesDocForCollection(Customer, LSVJnl);
        SpecifyLSVCustomerForCollection(Customer."No.");
        CreateLSVJournalLines(LSVJnl);

        // Setup
        DirectDebitCollection.CreateRecord(Format(LSVJnl."No."), LSVJnl."LSV Bank Code", "Partner Type".FromInteger(LSVJnl."Partner Type"));
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");

        // Exercise
        CODEUNIT.Run(CODEUNIT::"SEPA DD-Prepare Source", DirectDebitCollectionEntry);

        // Verify
        // No errors occur!
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateDirectDebitCollectionEntriesFromLSVJournalLines()
    var
        Customer: Record Customer;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        LSVJnl: Record "LSV Journal";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        // Pre-Setup
        PrepareLSVSalesDocForCollection(Customer, LSVJnl);
        SpecifyLSVCustomerForCollection(Customer."No.");
        CreateLSVJournalLines(LSVJnl);

        // Setup
        CreateMandateForCustomer(SEPADirectDebitMandate, Customer."No.");
        AddMandateIDToLSVJournalLines(LSVJnl."No.", SEPADirectDebitMandate.ID);
        DirectDebitCollection.CreateRecord(Format(LSVJnl."No."), LSVJnl."LSV Bank Code", "Partner Type".FromInteger(LSVJnl."Partner Type"));
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");

        // Exercise
        CODEUNIT.Run(CODEUNIT::"SEPA DD-Prepare Source", DirectDebitCollectionEntry);

        // Verify
        ValidateCountOfDebitCollectionEntries(LSVJnl."No.", DirectDebitCollectionEntry."Direct Debit Collection No.");
        ValidateDirectDebitCollectionEntries(LSVJnl."No.", DirectDebitCollectionEntry."Direct Debit Collection No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectDebitCollectionNotCreated()
    var
        Customer: Record Customer;
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        LSVJnl: Record "LSV Journal";
    begin
        // Pre-Setup
        PrepareLSVSalesDocForCollection(Customer, LSVJnl);

        // Setup
        DirectDebitCollectionEntry.SetRange("Entry No.", LSVJnl."No.");

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"SEPA DD-Prepare Source", DirectDebitCollectionEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(FilterRangeErr, DirectDebitCollectionEntry.FieldCaption("Direct Debit Collection No."), DirectDebitCollectionEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure LaunchXMLPortSEPADirectDebitMissingExportSetup()
    var
        BankAcc: Record "Bank Account";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
    begin
        // Pre-Setup
        PrepareLSVSalesDocForCollection(Customer, LSVJnl);

        // Setup
        SpecifyLSVCustomerForCollection(Customer."No.");
        CreateLSVJournalLines(LSVJnl);

        // Exercise
        asserterror LSVJnl.CreateDirectDebitFile();

        // Verify
        Assert.ExpectedError(StrSubstNo(FieldMustHaveValueErr, BankAcc.FieldCaption("SEPA Direct Debit Exp. Format"), BankAcc.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure LaunchXMLPortSEPADirectDebitMissingFormatOnBankAccount()
    var
        BankAcc: Record "Bank Account";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVBankCode: Code[20];
    begin
        // Pre-Setup
        LSVBankCode := PrepareLSVSalesDocForCollection(Customer, LSVJnl);
        SpecifyLSVCustomerForCollection(Customer."No.");
        CreateLSVJournalLines(LSVJnl);

        // Setup
        BankAcc.Get(LSVBankCode);
        SpecifySEPADirectDebitAsExportFormat(BankAcc);

        // Exercise
        asserterror WriteSEPAFile(LSVJnl);

        // Verify
        Assert.ExpectedError(StrSubstNo(FieldMustHaveValueErr, BankAcc.FieldCaption(IBAN), BankAcc.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure LaunchXMLPortSEPADirectDebitUsingNonEuroCurrency()
    var
        CollBankAcc: Record "Bank Account";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        OurBankAcc: Record "Bank Account";
        PmtJnlExportErrText: Record "Payment Jnl. Export Error Text";
        LSVBankCode: Code[20];
    begin
        // Pre-Setup
        LSVBankCode := PrepareLSVSalesDocForCollection(Customer, LSVJnl);
        SpecifyLSVCustomerForCollection(Customer."No.");
        CreateLSVJournalLines(LSVJnl);

        // Setup
        OurBankAcc.Get(LSVBankCode);
        SpecifyBankAccountDetails(OurBankAcc);
        SpecifySEPADirectDebitAsExportFormat(OurBankAcc);

        CollBankAcc.Get(LSVBankCode);
        SpecifyBankAccountDetails(CollBankAcc);
        SpecifySEPADirectDebitAsExportFormat(CollBankAcc);

        // Exercise
        asserterror WriteSEPAFile(LSVJnl);

        // Post-Exercise
        Assert.ExpectedError(CollectionHasErrorsErr);

        // Verify
        ValidateCollectionErrorsExist(PmtJnlExportErrText, Format(LSVJnl."No."), 1);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteErrorsWhenLSVJournalIsDeleted()
    var
        CollBankAcc: Record "Bank Account";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        OurBankAcc: Record "Bank Account";
        PmtJnlExportErrText: Record "Payment Jnl. Export Error Text";
        LSVBankCode: Code[20];
    begin
        // Pre-Setup
        LSVBankCode := PrepareLSVSalesDocForCollection(Customer, LSVJnl);
        SpecifyLSVCustomerForCollection(Customer."No.");
        CreateLSVJournalLines(LSVJnl);

        // Setup
        OurBankAcc.Get(LSVBankCode);
        SpecifyBankAccountDetails(OurBankAcc);
        SpecifySEPADirectDebitAsExportFormat(OurBankAcc);

        CollBankAcc.Get(LSVBankCode);
        SpecifyBankAccountDetails(CollBankAcc);
        SpecifySEPADirectDebitAsExportFormat(CollBankAcc);

        // Exercise
        asserterror WriteSEPAFile(LSVJnl);

        // Post-Exercise
        Assert.ExpectedError(CollectionHasErrorsErr);
        LSVJnl.Get(LSVJnl."No.");
        LSVJnl.Delete(true);

        // Verify
        asserterror ValidateCollectionErrorsExist(PmtJnlExportErrText, Format(LSVJnl."No."), 1);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestLSVCollectionPicksMandateID()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        LSVJnlLine: Record "LSV Journal Line";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        // Pre-Setup
        PrepareLSVSalesDocForCollection(Customer, LSVJnl);
        CreateMandateForCustomer(SEPADirectDebitMandate, Customer."No.");

        // Setup
        FindCustLedgerEntries(CustLedgEntry, Customer."No.");
        CustLedgEntry.Validate("Direct Debit Mandate ID", SEPADirectDebitMandate.ID);
        CustLedgEntry.Modify(true);

        // Pre-Exercise
        SpecifyLSVCustomerForCollection(Customer."No.");
        Commit();

        // Exercise
        CreateLSVJournalLines(LSVJnl);

        // Verify
        FindLSVJournalLines(LSVJnlLine, LSVJnl."No.");
        ValidateLSVJournalLines(LSVJnlLine, CustLedgEntry);
    end;

    local procedure PrepareLSVSalesDocForCollection(var Customer: Record Customer; var LSVJnl: Record "LSV Journal") LSVBankCode: Code[20]
    var
        ESRSetup: Record "ESR Setup";
        LSVSetup: Record "LSV Setup";
        SalesHeader: Record "Sales Header";
    begin
        LibraryLSV.CreateESRSetup(ESRSetup);
        LSVBankCode := LibraryLSV.CreateLSVSetup(LSVSetup, ESRSetup);
        LibraryLSV.CreateLSVJournal(LSVJnl, LSVSetup);
        LibraryLSV.CreateLSVCustomer(Customer, LSVSetup."LSV Payment Method Code");
        LibraryLSV.CreateLSVCustomerBankAccount(Customer);
        CreateLSVSalesDoc(SalesHeader, Customer."No.");
        PostLSVSalesDoc(SalesHeader);
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

    local procedure CreateMandateForCustomer(var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; CustNo: Code[20])
    var
        CustBankAcc: Record "Customer Bank Account";
    begin
        CustBankAcc.SetRange("Customer No.", CustNo);
        CustBankAcc.FindFirst();
        SEPADirectDebitMandate.Validate("Customer No.", CustNo);
        SEPADirectDebitMandate.Validate("Customer Bank Account Code", CustBankAcc.Code);
        SEPADirectDebitMandate.Insert(true);
    end;

    local procedure AddMandateIDToLSVJournalLines(LSVJnlNo: Integer; MandateID: Text[35])
    var
        LSVJnlLine: Record "LSV Journal Line";
    begin
        LSVJnlLine.SetRange("LSV Journal No.", LSVJnlNo);
        LSVJnlLine.FindSet();

        repeat
            LSVJnlLine.Validate("Direct Debit Mandate ID", MandateID);
            LSVJnlLine.Modify(true);
        until LSVJnlLine.Next() = 0;
    end;

    local procedure ValidateCountOfDebitCollectionEntries(LSVJnlNo: Integer; DirectDebitCollectionNo: Integer)
    var
        DirectDebitCollEntry: Record "Direct Debit Collection Entry";
        LSVJnlLine: Record "LSV Journal Line";
    begin
        LSVJnlLine.SetRange("LSV Journal No.", LSVJnlNo);
        DirectDebitCollEntry.SetRange("Direct Debit Collection No.", DirectDebitCollectionNo);
        Assert.IsFalse(DirectDebitCollEntry.IsEmpty, StrSubstNo(RecordWithinFilterNotFoundErr, DirectDebitCollEntry.TableCaption()));
        Assert.AreEqual(LSVJnlLine.Count, DirectDebitCollEntry.Count, StrSubstNo(CountOfRecordsErr, DirectDebitCollEntry.TableCaption()));
    end;

    local procedure ValidateDirectDebitCollectionEntries(LSVJnlNo: Integer; DirectDebitCollectionNo: Integer)
    var
        DirectDebitCollEntry: Record "Direct Debit Collection Entry";
        LSVJnlLine: Record "LSV Journal Line";
    begin
        LSVJnlLine.SetRange("LSV Journal No.", LSVJnlNo);
        LSVJnlLine.FindSet();

        repeat
            DirectDebitCollEntry.SetRange("Direct Debit Collection No.", DirectDebitCollectionNo);
            DirectDebitCollEntry.SetRange("Entry No.", LSVJnlLine."Line No.");
            DirectDebitCollEntry.SetRange("Customer No.", LSVJnlLine."Customer No.");
            DirectDebitCollEntry.SetRange("Currency Code", LSVJnlLine."Currency Code");
            DirectDebitCollEntry.SetRange("Transfer Amount", LSVJnlLine."Collection Amount");
            DirectDebitCollEntry.SetRange("Applies-to Entry No.", LSVJnlLine."Cust. Ledg. Entry No.");
            DirectDebitCollEntry.SetRange("Applies-to Entry Document No.", LSVJnlLine."Applies-to Doc. No.");
            DirectDebitCollEntry.SetRange("Mandate ID", LSVJnlLine."Direct Debit Mandate ID");
            Assert.IsFalse(DirectDebitCollEntry.IsEmpty, StrSubstNo(RecordWithinFilterNotFoundErr, DirectDebitCollEntry.TableCaption));
        until LSVJnlLine.Next() = 0;
    end;

    local procedure SpecifyBankAccountDetails(var BankAcc: Record "Bank Account")
    begin
        BankAcc.IBAN := LibraryUtility.GenerateGUID();
        BankAcc."SWIFT Code" := LibraryUtility.GenerateGUID();
        BankAcc."Bank Account No." := LibraryUtility.GenerateGUID();
        BankAcc.Modify();
    end;

    local procedure SpecifySEPADirectDebitAsExportFormat(var BankAcc: Record "Bank Account")
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.SetRange("Processing XMLport ID", XMLPORT::"SEPA DD pain.008.001.02");
        BankExportImportSetup.FindFirst();
        BankAcc.Validate("SEPA Direct Debit Exp. Format", BankExportImportSetup.Code);
        BankAcc.Modify(true);
    end;

    local procedure WriteSEPAFile(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.WriteSEPAFile.Invoke();
    end;

    local procedure ValidateCollectionErrorsExist(var PmtJnlExportErrText: Record "Payment Jnl. Export Error Text"; DocNo: Code[20]; JnlLineNo: Integer)
    begin
        PmtJnlExportErrText.SetRange("Journal Template Name", '');
        PmtJnlExportErrText.SetRange("Journal Batch Name", Format(DATABASE::"LSV Journal"));
        PmtJnlExportErrText.SetRange("Document No.", DocNo);
        PmtJnlExportErrText.SetRange("Journal Line No.", JnlLineNo);
        Assert.IsFalse(PmtJnlExportErrText.IsEmpty, RecordWithinFilterNotFoundErr);
    end;

    local procedure FindCustLedgerEntries(var CustLedgEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    begin
        CustLedgEntry.SetRange("Customer No.", CustomerNo);
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.FindSet();
    end;

    local procedure FindLSVJournalLines(var LSVJnlLine: Record "LSV Journal Line"; LSVJnlNo: Integer)
    begin
        LSVJnlLine.SetRange("LSV Journal No.", LSVJnlNo);
        LSVJnlLine.FindSet();
    end;

    local procedure ValidateLSVJournalLines(LSVJnlLine: Record "LSV Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        repeat
            LSVJnlLine.SetRange("Direct Debit Mandate ID", CustLedgEntry."Direct Debit Mandate ID");
            Assert.IsFalse(LSVJnlLine.IsEmpty, StrSubstNo(RecordNotFoundErr, LSVJnlLine.TableCaption()));
        until CustLedgEntry.Next() = 0;
    end;
}

