codeunit 147533 "Cartera Recv. Factoring"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        CarteraGenJournalTemplate: Record "Gen. Journal Template";
        CarteraGenJournalBatch: Record "Gen. Journal Batch";
        Assert: Codeunit Assert;
        LibraryCarteraCommon: Codeunit "Library - Cartera Common";
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        FactoringCountMismatchErr: Label 'Number of factoring documents does not match %1.', Comment = '%1=TableCaption;%2=FieldCaption';
        BillGroupNotPrintedMsg: Label 'This %1 has not been printed. Do you want to continue?';
        BillGroupSuccessfulPostedMsg: Label 'was successfully posted for factoring collection.';
        PostJnlLinesMsg: Label 'Do you want to post the journal lines?';
        JnlLinesPostedMsg: Label 'The journal lines were successfully posted.';
        BillGroupSuccessfulPostedForDiscountMsg: Label 'was successfully posted for discount.';
        RcvDocSettledMsg: Label 'have been settled.';
        RcvDocPartialSettledMsg: Label 'have been partially settled in Bill Group';
        OneDocumentRejectedMsg: Label '1 documents have been rejected.';
        OnlyBillsCanBeRedrawnErr: Label 'Only bills can be redrawn';
        OnlyInvoicesWithRiskedFactoringCanBeRejectedErr: Label 'Only invoices in Bill Groups marked as Factoring Risked can be rejected';
        LocalCurrencyCode: Code[10];

    [Test]
    [Scope('OnPrem')]
    procedure TestFactoringCarteraDocLCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        TotalAmount: Decimal;
    begin
        Initialize();

        // Setup
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");

        // Exercise
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify
        TotalAmount := LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(Customer."No.", DocumentNo,
            CustLedgerEntry."Document Type"::Invoice);

        VerifyFactoringCarteraDocuments(Customer."No.", DocumentNo, Customer."Payment Method Code", TotalAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFactoringCarteraDocNonLCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        TotalAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(true, false, false);

        // Setup
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, CurrencyCode);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");

        // Exercise
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify
        TotalAmount := LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(Customer."No.", DocumentNo,
            CustLedgerEntry."Document Type"::Invoice);

        VerifyFactoringCarteraDocuments(Customer."No.", DocumentNo, Customer."Payment Method Code", TotalAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestBillGroupWithCollectionAndRisked()
    var
        BillGroup: Record "Bill Group";
    begin
        SetupAndPostBillGroupWithCollectionLCY(BillGroup, BillGroup.Factoring::Risked);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestBillGroupWithCollectionAndUnrisked()
    var
        BillGroup: Record "Bill Group";
    begin
        SetupAndPostBillGroupWithCollectionLCY(BillGroup, BillGroup.Factoring::Unrisked);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,TotalSettleDocsInPostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestFullSettlementWithCollectionAndRiskedLCY()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        // Setup
        SetupAndPostBillGroupWithCollectionLCY(BillGroup, BillGroup.Factoring::Risked);

        // Excercise
        TotalSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup);

        // Verify
        VerifyClosedBillGroup(PostedBillGroup, PostedCarteraDoc);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,ConfirmHandler,MessageHandler,TotalSettleDocsInPostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestFullSettlementWithCollectionAndRiskedNonLCY()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        // Setup
        SetupAndPostBillGroupWithCollectionNonLCY(BillGroup, BillGroup.Factoring::Risked);

        // Excercise
        TotalSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup);

        // Verify
        VerifyClosedBillGroup(PostedBillGroup, PostedCarteraDoc);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,TotalSettleDocsInPostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestFullSettlementWithCollectionAndUnrisked()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        // Setup
        SetupAndPostBillGroupWithCollectionLCY(BillGroup, BillGroup.Factoring::Unrisked);

        // Excercise
        TotalSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup);

        // Verify
        VerifyClosedBillGroup(PostedBillGroup, PostedCarteraDoc);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,PartialSettleDocsInPostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestPartialSettlementWithCollectionAndRisked()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedBillGroup: Record "Closed Bill Group";
        Percentage: Decimal;
    begin
        Percentage := 50;

        // Setup
        SetupAndPostBillGroupWithCollectionLCY(BillGroup, BillGroup.Factoring::Risked);

        // Excercise
        PartialSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup, Percentage);

        // Intermediate verify - bill group is not closed
        Assert.IsFalse(ClosedBillGroup.Get(PostedBillGroup."No."), '');

        // Exercise - post remaining
        PartialSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup, Percentage);

        // Verify
        VerifyClosedBillGroup(PostedBillGroup, PostedCarteraDoc);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,PartialSettleDocsInPostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestPartialSettlementWithCollectionAndUnriskedLCY()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedBillGroup: Record "Closed Bill Group";
        Percentage: Decimal;
    begin
        Percentage := 50;

        // Setup
        SetupAndPostBillGroupWithCollectionLCY(BillGroup, BillGroup.Factoring::Unrisked);

        // Excercise
        PartialSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup, Percentage);

        // Intermediate verify - bill group is not closed
        Assert.IsFalse(ClosedBillGroup.Get(PostedBillGroup."No."), '');

        // Exercise - post remaining
        PartialSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup, Percentage);

        // Verify
        VerifyClosedBillGroup(PostedBillGroup, PostedCarteraDoc);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,ConfirmHandler,MessageHandler,PartialSettleDocsInPostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestPartialSettlementWithCollectionAndUnriskedNonLCY()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedBillGroup: Record "Closed Bill Group";
        Percentage: Decimal;
    begin
        Percentage := 50;

        // Setup
        SetupAndPostBillGroupWithCollectionNonLCY(BillGroup, BillGroup.Factoring::Unrisked);

        // Excercise
        PartialSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup, Percentage);

        // Intermediate verify - bill group is not closed
        Assert.IsFalse(ClosedBillGroup.Get(PostedBillGroup."No."), '');

        // Exercise - post remaining
        PartialSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup, Percentage);

        // Verify
        VerifyClosedBillGroup(PostedBillGroup, PostedCarteraDoc);
    end;

    local procedure RejectionSetupAndPostBillGroupWithCollection(var BillGroup: Record "Bill Group"; Factoring: Option; var TotalAmount: Decimal; var ExpectedVATAmount: Decimal)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        FeeRange: Record "Fee Range";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
        DocumentNo: Code[20];
    begin
        // Setup
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");

        // Remove discounts
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.ModifyAll(SalesLine."Line Discount %", 0, true);
        SalesLine.ModifyAll(SalesLine."Line Discount Amount", 0, true);
        SalesLine.FindFirst();

        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        TotalAmount := LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(Customer."No.", DocumentNo,
            CustLedgerEntry."Document Type"::Invoice);

        ExpectedVATAmount :=
          Round(TotalAmount - TotalAmount * 100 / (VATPostingSetup."VAT %" + 100), LibraryERM.GetAmountRoundingPrecision());

        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateFactoringOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateFeeRange(FeeRange,
          BankAccount."No.", LocalCurrencyCode, FeeRange."Type of Fee"::"Rejection Expenses");
        CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection, Factoring);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        // Exercise
        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption())); // for the confirm handler
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(BillGroupSuccessfulPostedMsg); // for the message handler
        Commit();
        BGPostAndPrint.ReceivablePostOnly(BillGroup);

        // Verify
        VerifyPostedBillGroup(BillGroup, CarteraDoc);
    end;

    local procedure SetupAndPostBillGroupWithCollectionLCY(var BillGroup: Record "Bill Group"; Factoring: Option)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateFactoringOperationFeesForBankAccount(BankAccount);
        CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection, Factoring);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        // Exercise
        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption())); // for the confirm handler
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(BillGroupSuccessfulPostedMsg); // for the message handler
        Commit();
        BGPostAndPrint.ReceivablePostOnly(BillGroup);

        // Verify
        VerifyPostedBillGroup(BillGroup, CarteraDoc);
    end;

    local procedure SetupAndPostBillGroupWithCollectionNonLCY(var BillGroup: Record "Bill Group"; Factoring: Option)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        BillGroupNo: Code[20];
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(true, false, false);

        // Setup
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, CurrencyCode);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCarteraReceivables.CreateBankAccount(BankAccount, CurrencyCode);
        LibraryCarteraReceivables.CreateFactoringOperationFeesForBankAccount(BankAccount);
        BillGroupNo := CreateBillGroupNonLCY(CurrencyCode, BankAccount."No.", BillGroup."Dealing Type"::Collection, Factoring);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroupNo);

        // Pre-Exercise
        BillGroup.Get(BillGroupNo);

        // Exercise
        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption())); // for the confirm handler
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(BillGroupSuccessfulPostedMsg); // for the message handler
        Commit();
        PostBillGroup(BillGroupNo);

        // Verify
        VerifyPostedBillGroup(BillGroup, CarteraDoc);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,PostBillGroupRequestPage,CarteraJnlModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestBillGroupWithDiscountAndRisked()
    var
        BillGroup: Record "Bill Group";
    begin
        SetupAndPostBillGroupWithDiscountLCY(BillGroup, BillGroup.Factoring::Risked);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,PostBillGroupRequestPage,CarteraJnlModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestBillGroupWithDiscountAndUnrisked()
    var
        BillGroup: Record "Bill Group";
    begin
        SetupAndPostBillGroupWithDiscountLCY(BillGroup, BillGroup.Factoring::Unrisked);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,PostBillGroupRequestPage,CarteraJnlModalPageHandler,TotalSettleDocsInPostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestFullSettlementWithDiscountAndRiskedLCY()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        // Setup
        SetupAndPostBillGroupWithDiscountLCY(BillGroup, BillGroup.Factoring::Risked);

        // Excercise
        TotalSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup);

        // Verify
        VerifyClosedBillGroup(PostedBillGroup, PostedCarteraDoc);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,PostBillGroupRequestPage,CarteraJnlModalPageHandler,TotalSettleDocsInPostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestFullSettlementWithDiscountAndUnrisked()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        // Setup
        SetupAndPostBillGroupWithDiscountLCY(BillGroup, BillGroup.Factoring::Unrisked);

        // Excercise
        TotalSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup);

        // Verify
        VerifyClosedBillGroup(PostedBillGroup, PostedCarteraDoc);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,PostBillGroupRequestPage,CarteraJnlModalPageHandler,PartialSettleDocsInPostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestPartialSettlementWithDiscountAndRisked()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedBillGroup: Record "Closed Bill Group";
        Percentage: Decimal;
    begin
        Percentage := 50;

        // Setup
        SetupAndPostBillGroupWithDiscountLCY(BillGroup, BillGroup.Factoring::Unrisked);

        // Excercise
        PartialSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup, Percentage);

        // Intermediate verify - bill group is not closed
        Assert.IsFalse(ClosedBillGroup.Get(PostedBillGroup."No."), '');

        // Exercise - post remaining
        PartialSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup, Percentage);

        // Verify
        VerifyClosedBillGroup(PostedBillGroup, PostedCarteraDoc);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,PostBillGroupRequestPage,CarteraJnlModalPageHandler,PartialSettleDocsInPostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestPartialSettlementWithDiscountAndUnriskedLCY()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedBillGroup: Record "Closed Bill Group";
        Percentage: Decimal;
    begin
        Percentage := 50;

        // Setup
        SetupAndPostBillGroupWithDiscountLCY(BillGroup, BillGroup.Factoring::Unrisked);

        // Excercise
        PartialSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup, Percentage);

        // Intermediate verify - bill group is not closed
        Assert.IsFalse(ClosedBillGroup.Get(PostedBillGroup."No."), '');

        // Exercise - post remaining
        PartialSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup, Percentage);

        // Verify
        VerifyClosedBillGroup(PostedBillGroup, PostedCarteraDoc);
    end;

    local procedure RejectionSetupAndPostBillGroupWithDiscount(var BillGroup: Record "Bill Group"; Factoring: Option; var TotalAmount: Decimal; var ExpectedVATAmount: Decimal; var ExpectedDiscountAmount: Decimal)
    var
        FeeRange: Record "Fee Range";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        BankAccount: Record "Bank Account";
        CustomerRating: Record "Customer Rating";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CarteraDoc: Record "Cartera Doc.";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
        DocumentNo: Code[20];
    begin
        // Setup
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");

        // Remove discounts
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.ModifyAll(SalesLine."Line Discount %", 0, true);
        SalesLine.ModifyAll(SalesLine."Line Discount Amount", 0, true);
        SalesLine.FindFirst();

        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        TotalAmount := LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(Customer."No.", DocumentNo,
            CustLedgerEntry."Document Type"::Invoice);

        ExpectedVATAmount :=
          Round(TotalAmount - TotalAmount * 100 / (VATPostingSetup."VAT %" + 100), LibraryERM.GetAmountRoundingPrecision());

        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerRatingForBank(CustomerRating, BankAccount."No.", LocalCurrencyCode, Customer."No.");
        ExpectedDiscountAmount := CustomerRating."Risk Percentage" * TotalAmount / 100;
        LibraryCarteraReceivables.CreateFactoringOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateFeeRange(FeeRange,
          BankAccount."No.", LocalCurrencyCode, FeeRange."Type of Fee"::"Discount Interests");
        LibraryCarteraReceivables.CreateFeeRange(FeeRange,
          BankAccount."No.", LocalCurrencyCode, FeeRange."Type of Fee"::"Rejection Expenses");
        CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Discount, Factoring);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        // Exercise
        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption())); // for the print confirm handler
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(PostJnlLinesMsg); // for the post confirm handler
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(JnlLinesPostedMsg); // for the first message handler
        LibraryVariableStorage.Enqueue(BillGroupSuccessfulPostedForDiscountMsg); // for the second message handler
        Commit();
        BGPostAndPrint.ReceivablePostOnly(BillGroup);

        // Verify
        VerifyPostedBillGroup(BillGroup, CarteraDoc);
    end;

    local procedure SetupAndPostBillGroupWithDiscountLCY(var BillGroup: Record "Bill Group"; Factoring: Option)
    var
        FeeRange: Record "Fee Range";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        BankAccount: Record "Bank Account";
        CustomerRating: Record "Customer Rating";
        CarteraDoc: Record "Cartera Doc.";
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerRatingForBank(CustomerRating, BankAccount."No.", LocalCurrencyCode, Customer."No.");
        LibraryCarteraReceivables.CreateFactoringOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateFeeRange(FeeRange,
          BankAccount."No.", LocalCurrencyCode, FeeRange."Type of Fee"::"Discount Interests");
        CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Discount, Factoring);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        // Exercise
        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption())); // for the print confirm handler
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(PostJnlLinesMsg); // for the post confirm handler
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(JnlLinesPostedMsg); // for the first message handler
        LibraryVariableStorage.Enqueue(BillGroupSuccessfulPostedForDiscountMsg); // for the second message handler
        Commit();
        BGPostAndPrint.ReceivablePostOnly(BillGroup);

        // Verify
        VerifyPostedBillGroup(BillGroup, CarteraDoc);
    end;

    [Test]
    [HandlerFunctions('ExportBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestFactoringExport()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        BillGroup: Record "Bill Group";
        FileManagement: Codeunit "File Management";
        SuffixValue: Code[3];
        DocumentNo: Code[20];
        FileName: Text;
    begin
        Initialize();

        // Setup
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
        SuffixValue := LibraryCarteraReceivables.CreateSuffixForBankAccount(BankAccount."No.");
        LibraryCarteraReceivables.CreateFactoringOperationFeesForBankAccount(BankAccount);
        CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection, BillGroup.Factoring::Risked);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        // Exercise
        FileName := FileManagement.ServerTempFileName('TXT');
        LibraryVariableStorage.Enqueue(WorkDate()); // for the handlers
        LibraryVariableStorage.Enqueue(SuffixValue);
        RunFactoringExport(BillGroup, FileName);

        // Verify
        VerifyExportBillGroup(CopyStr(FileName, 1, 1024), BankAccount, SuffixValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestRejectUnriskedInvoice()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        PostedBillGroups: TestPage "Posted Bill Groups";
        TotalAmount: Decimal;
        RejectionFeeAmount: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        Initialize();

        // Setup
        RejectionSetupAndPostBillGroupWithCollection(BillGroup, BillGroup.Factoring::Unrisked, TotalAmount, ExpectedVATAmount);
        GetRejectionFeeAmount(BillGroup, TotalAmount, RejectionFeeAmount);

        // Excercise
        OpenPostedBillGroupsAndSelectDocument(PostedBillGroups, PostedBillGroup, PostedCarteraDoc, BillGroup);

        // Verify
        asserterror PostedBillGroups.Docs.Reject.Invoke();
        Assert.ExpectedError(OnlyInvoicesWithRiskedFactoringCanBeRejectedErr);
    end;

    [Test]
    [HandlerFunctions('RejectionVerifyAndPostCarteraJournalHandler,RejectCarteraDocRequestPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestRejectUnsettledInvoiceWithCollectionAndRisked()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        TotalAmount: Decimal;
        RejectionFeeAmount: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        Initialize();

        // Setup
        RejectionSetupAndPostBillGroupWithCollection(BillGroup, BillGroup.Factoring::Risked, TotalAmount, ExpectedVATAmount);
        GetRejectionFeeAmount(BillGroup, TotalAmount, RejectionFeeAmount);

        // Excercise
        RejectPostedDocument(PostedBillGroup, PostedCarteraDoc, BillGroup, TotalAmount, RejectionFeeAmount, false, ExpectedVATAmount, false, 0);

        // Verify
        VerifyClosedBillGroup2(PostedBillGroup, PostedCarteraDoc, TotalAmount, PostedCarteraDoc.Status::Rejected);
        VerifyRejectedInvoiceVATGLEntries(TotalAmount, RejectionFeeAmount, false, ExpectedVATAmount, false, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RejectionVerifyAndPostCarteraJournalHandler,PartialSettleDocsInPostBillGroupRequestPage,RejectCarteraDocRequestPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestRejectInvoicePartialSettlementWithCollectionAndRisked()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedBillGroup: Record "Closed Bill Group";
        Percentage: Decimal;
        TotalAmount: Decimal;
        RejectionFeeAmount: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        Initialize();

        Percentage := 50;

        // Setup
        RejectionSetupAndPostBillGroupWithCollection(BillGroup, BillGroup.Factoring::Risked, TotalAmount, ExpectedVATAmount);

        // Excercise
        PartialSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup, Percentage);

        // Intermediate verify - bill group is not closed
        Assert.IsFalse(ClosedBillGroup.Get(PostedBillGroup."No."), '');

        TotalAmount := TotalAmount * Percentage / 100;
        GetRejectionFeeAmount(BillGroup, TotalAmount, RejectionFeeAmount);
        RejectPostedDocument(PostedBillGroup, PostedCarteraDoc, BillGroup, TotalAmount, RejectionFeeAmount, false, ExpectedVATAmount, false, 0);

        VerifyClosedBillGroup2(PostedBillGroup, PostedCarteraDoc, TotalAmount, PostedCarteraDoc.Status::Rejected);
        VerifyRejectedInvoiceVATGLEntries(TotalAmount, RejectionFeeAmount, false, ExpectedVATAmount, false, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RejectionVerifyAndPostCarteraJournalHandler,RejectCarteraDocRequestPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestRejectUnsettledIvoiceWithCollectionAndUnrealizedVAT()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        TotalAmount: Decimal;
        RejectionFeeAmount: Decimal;
        SalesVATAccount: Code[20];
        PurchaseVATAccount: Code[20];
        ExpectedVATAmount: Decimal;
    begin
        Initialize();

        // Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesVATAccount, PurchaseVATAccount);
        RejectionSetupAndPostBillGroupWithCollection(BillGroup, BillGroup.Factoring::Risked, TotalAmount, ExpectedVATAmount);
        GetRejectionFeeAmount(BillGroup, TotalAmount, RejectionFeeAmount);

        // Excercise
        RejectPostedDocument(PostedBillGroup, PostedCarteraDoc, BillGroup, TotalAmount, RejectionFeeAmount, true, ExpectedVATAmount, false, 0);

        // Verify
        VerifyClosedBillGroup2(PostedBillGroup, PostedCarteraDoc, TotalAmount, PostedCarteraDoc.Status::Rejected);
        VerifyRejectedInvoiceVATGLEntries(TotalAmount, RejectionFeeAmount, true, ExpectedVATAmount, false, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RejectionVerifyAndPostCarteraJournalHandler,PartialSettleDocsInPostBillGroupRequestPage,RejectCarteraDocRequestPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestRejectIvoicePartialSettlementWithCollectionAndUnrealizedVAT()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedBillGroup: Record "Closed Bill Group";
        TotalAmount: Decimal;
        RejectionFeeAmount: Decimal;
        SalesVATAccount: Code[20];
        PurchaseVATAccount: Code[20];
        ExpectedVATAmount: Decimal;
        Percentage: Decimal;
    begin
        Initialize();

        Percentage := 50;

        // Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesVATAccount, PurchaseVATAccount);
        RejectionSetupAndPostBillGroupWithCollection(BillGroup, BillGroup.Factoring::Risked, TotalAmount, ExpectedVATAmount);

        // Excercise
        PartialSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup, Percentage);

        // Intermediate verify - bill group is not closed
        Assert.IsFalse(ClosedBillGroup.Get(PostedBillGroup."No."), '');

        TotalAmount := TotalAmount * Percentage / 100;
        ExpectedVATAmount := ExpectedVATAmount * Percentage / 100;
        GetRejectionFeeAmount(BillGroup, TotalAmount, RejectionFeeAmount);

        RejectPostedDocument(PostedBillGroup, PostedCarteraDoc, BillGroup, TotalAmount, RejectionFeeAmount, true, ExpectedVATAmount, false, 0);

        // Verify
        VerifyClosedBillGroup2(PostedBillGroup, PostedCarteraDoc, TotalAmount, PostedCarteraDoc.Status::Rejected);
        VerifyRejectedInvoiceVATGLEntries(TotalAmount, RejectionFeeAmount, true, ExpectedVATAmount, false, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RejectionVerifyAndPostCarteraJournalHandler,RejectCarteraDocRequestPageHandler,ConfirmHandler,MessageHandler,PostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestRejectUnsettledInvoiceWithDiscountAndRisked()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        TotalAmount: Decimal;
        RejectionFeeAmount: Decimal;
        ExpectedVATAmount: Decimal;
        ExpectedDiscountAmount: Decimal;
    begin
        Initialize();

        // Setup
        RejectionSetupAndPostBillGroupWithDiscount(
          BillGroup, BillGroup.Factoring::Risked, TotalAmount, ExpectedVATAmount, ExpectedDiscountAmount);

        GetRejectionFeeAmount(BillGroup, TotalAmount, RejectionFeeAmount);

        // Excercise
        RejectPostedDocument(
          PostedBillGroup, PostedCarteraDoc, BillGroup, TotalAmount, RejectionFeeAmount, false, ExpectedVATAmount, true, ExpectedDiscountAmount);

        // Verify
        VerifyClosedBillGroup2(PostedBillGroup, PostedCarteraDoc, TotalAmount, PostedCarteraDoc.Status::Rejected);
        VerifyRejectedInvoiceVATGLEntries(TotalAmount, RejectionFeeAmount, false, ExpectedVATAmount, true, ExpectedDiscountAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RejectionVerifyAndPostCarteraJournalHandler,RejectCarteraDocRequestPageHandler,ConfirmHandler,MessageHandler,PostBillGroupRequestPage,PartialSettleDocsInPostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestRejectInvoicePartialSettlementWithDiscoutAndRisked()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedBillGroup: Record "Closed Bill Group";
        Percentage: Decimal;
        TotalAmount: Decimal;
        RejectionFeeAmount: Decimal;
        ExpectedVATAmount: Decimal;
        ExpectedDiscountAmount: Decimal;
    begin
        Initialize();

        Percentage := 50;

        // Setup
        RejectionSetupAndPostBillGroupWithDiscount(
          BillGroup, BillGroup.Factoring::Risked, TotalAmount, ExpectedVATAmount, ExpectedDiscountAmount);

        // Excercise
        PartialSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup, Percentage);
        Assert.IsFalse(ClosedBillGroup.Get(PostedBillGroup."No."), 'Bill group should not be closed');

        TotalAmount := TotalAmount * Percentage / 100;
        ExpectedDiscountAmount := ExpectedDiscountAmount * Percentage / 100;
        GetRejectionFeeAmount(BillGroup, TotalAmount, RejectionFeeAmount);
        RejectPostedDocument(
          PostedBillGroup, PostedCarteraDoc, BillGroup, TotalAmount, RejectionFeeAmount, false, ExpectedVATAmount, true, ExpectedDiscountAmount);

        VerifyClosedBillGroup2(PostedBillGroup, PostedCarteraDoc, TotalAmount, PostedCarteraDoc.Status::Rejected);
        VerifyRejectedInvoiceVATGLEntries(TotalAmount, RejectionFeeAmount, false, ExpectedVATAmount, true, ExpectedDiscountAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RejectionVerifyAndPostCarteraJournalHandler,RejectCarteraDocRequestPageHandler,ConfirmHandler,MessageHandler,PostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestRejectUnsettledIvoiceWithDiscountAndUnrealizedVAT()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        TotalAmount: Decimal;
        RejectionFeeAmount: Decimal;
        SalesVATAccount: Code[20];
        PurchaseVATAccount: Code[20];
        ExpectedVATAmount: Decimal;
        ExpectedDiscountAmount: Decimal;
    begin
        Initialize();

        // Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesVATAccount, PurchaseVATAccount);
        RejectionSetupAndPostBillGroupWithDiscount(
          BillGroup, BillGroup.Factoring::Risked, TotalAmount, ExpectedVATAmount, ExpectedDiscountAmount);
        GetRejectionFeeAmount(BillGroup, TotalAmount, RejectionFeeAmount);

        // Excercise
        RejectPostedDocument(
          PostedBillGroup, PostedCarteraDoc, BillGroup, TotalAmount, RejectionFeeAmount, true, ExpectedVATAmount, true, ExpectedDiscountAmount);

        // Verify
        VerifyClosedBillGroup2(PostedBillGroup, PostedCarteraDoc, TotalAmount, PostedCarteraDoc.Status::Rejected);
        VerifyRejectedInvoiceVATGLEntries(TotalAmount, RejectionFeeAmount, true, ExpectedVATAmount, true, ExpectedDiscountAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RejectionVerifyAndPostCarteraJournalHandler,RejectCarteraDocRequestPageHandler,ConfirmHandler,MessageHandler,PostBillGroupRequestPage,PartialSettleDocsInPostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure TestRejectIvoicePartialSettlementWithDiscountAndUnrealizedVAT()
    var
        BillGroup: Record "Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedBillGroup: Record "Closed Bill Group";
        TotalAmount: Decimal;
        RejectionFeeAmount: Decimal;
        SalesVATAccount: Code[20];
        PurchaseVATAccount: Code[20];
        ExpectedVATAmount: Decimal;
        Percentage: Decimal;
        ExpectedDiscountAmount: Decimal;
    begin
        Initialize();

        Percentage := 50;

        // Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesVATAccount, PurchaseVATAccount);
        RejectionSetupAndPostBillGroupWithDiscount(
          BillGroup, BillGroup.Factoring::Risked, TotalAmount, ExpectedVATAmount, ExpectedDiscountAmount);

        // Excercise
        PartialSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup, Percentage);
        Assert.IsFalse(ClosedBillGroup.Get(PostedBillGroup."No."), 'Bill group should not be closed');

        TotalAmount := TotalAmount * Percentage / 100;
        ExpectedVATAmount := ExpectedVATAmount * Percentage / 100;
        ExpectedDiscountAmount := ExpectedDiscountAmount * Percentage / 100;
        GetRejectionFeeAmount(BillGroup, TotalAmount, RejectionFeeAmount);

        RejectPostedDocument(
          PostedBillGroup, PostedCarteraDoc, BillGroup, TotalAmount, RejectionFeeAmount, true, ExpectedVATAmount, true, ExpectedDiscountAmount);

        // Verify
        VerifyClosedBillGroup2(PostedBillGroup, PostedCarteraDoc, TotalAmount, PostedCarteraDoc.Status::Rejected);
        VerifyRejectedInvoiceVATGLEntries(TotalAmount, RejectionFeeAmount, true, ExpectedVATAmount, true, ExpectedDiscountAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,TotalSettleDocsInPostBillGroupRequestPage')]
    [Scope('OnPrem')]
    procedure CloseBillGroupWithAltCustPostingGroup()
    var
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        Customer: Record Customer;
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 571268] Entry balanced if we settle Invoices to Cartera via Bill Group with Multiple Posting Groups
        Initialize();

        // [GIVEN] Set Multiple Posting group on Sales Receivables Setup
        SetSalesAllowMultiplePostingGroups(true);

        // [GIVEN] Create and post Sales Invoice of Cartera doc
        DocumentNo := PostSalesInvoiceWithCarteraDoc(Customer);

        // [GIVEN] Create and post bill group for Cartera doc
        CreateAndPostBillGroup(BillGroup, CarteraDoc, Customer, DocumentNo);

        // [THEN] Verify the posted bill group
        VerifyPostedBillGroup(BillGroup, CarteraDoc);

        // [WHEN] Close the posted Bill Group by total settlement
        TotalSettlePostedBillGroup(PostedBillGroup, PostedCarteraDoc, BillGroup);

        // [THEN] Verify the closed bill group
        VerifyClosedBillGroup(PostedBillGroup, PostedCarteraDoc);
    end;

    local procedure Initialize()
    var
        CarteraSetup: Record "Cartera Setup";
    begin
        LibraryVariableStorage.Clear();
        LibraryCarteraCommon.RevertUnrealizedVATPostingSetup();
        LocalCurrencyCode := '';

        if IsInitialized then
            exit;

        CarteraSetup.Get();
        CarteraSetup.Validate("Bills Discount Limit Warnings", false);
        CarteraSetup.Modify(true);

        CarteraGenJournalTemplate.SetRange(Type, CarteraGenJournalTemplate.Type::Cartera);
        LibraryERM.FindGenJournalTemplate(CarteraGenJournalTemplate);
        LibraryERM.FindGenJournalBatch(CarteraGenJournalBatch, CarteraGenJournalTemplate.Name);

        IsInitialized := true;
    end;

    local procedure CreateBillGroup(var BillGroup: Record "Bill Group"; BankAccountNo: Code[20]; DealingType: Enum "Cartera Dealing Type"; Factoring: Option)
    begin
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccountNo, DealingType);
        BillGroup.Validate(Factoring, Factoring);
        BillGroup.Modify(true);
    end;

    local procedure CreateBillGroupNonLCY(CurrencyCode: Code[10]; BankAccountNo: Code[20]; DealingType: Enum "Cartera Dealing Type"; Factoring: Option) BillGroupNo: Code[20]
    var
        BillGroups: TestPage "Bill Groups";
    begin
        BillGroups.OpenNew();

        BillGroups."Dealing Type".SetValue(DealingType);
        BillGroups.Factoring.SetValue(Factoring);

        LibraryVariableStorage.Enqueue(CurrencyCode);
        BillGroups."Currency Code".Activate();
        BillGroups."Currency Code".Lookup();

        LibraryVariableStorage.Enqueue(BankAccountNo);
        BillGroups."Bank Account No.".Activate();
        BillGroups."Bank Account No.".Lookup();

        BillGroupNo := BillGroups."No.".Value();

        BillGroups.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CurrenciesPageHandler(var Currencies: TestPage Currencies)
    var
        CurrencyCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrencyCode);
        Currencies.GotoKey(CurrencyCode);
        Currencies.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountSelectionPageHandler(var BankAccountSelection: TestPage "Bank Account Selection")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        BankAccountSelection.GotoKey(BankAccountNo);
        BankAccountSelection.OK().Invoke();
    end;

    local procedure PostBillGroup(BillGroupNo: Code[20])
    var
        BillGroups: TestPage "Bill Groups";
    begin
        BillGroups.OpenEdit();
        BillGroups.GotoKey(BillGroupNo);
        BillGroups.Post.Invoke();
    end;

    local procedure OpenPostedBillGroupsAndSelectDocument(var PostedBillGroups: TestPage "Posted Bill Groups"; var PostedBillGroup: Record "Posted Bill Group"; var PostedCarteraDoc: Record "Posted Cartera Doc."; BillGroup: Record "Bill Group")
    begin
        PostedBillGroup.Get(BillGroup."No.");
        PostedBillGroups.OpenEdit();
        PostedBillGroups.GotoRecord(PostedBillGroup);

        PostedCarteraDoc.SetRange(Type, PostedCarteraDoc.Type::Receivable);
        PostedCarteraDoc.SetRange("Bill Gr./Pmt. Order No.", BillGroup."No.");
        PostedCarteraDoc.FindFirst();

        PostedBillGroups.Docs.GotoRecord(PostedCarteraDoc);
    end;

    local procedure GetOperationFeeAmount(OperationCode: Code[20]; TypeofFee: Option): Decimal
    var
        OperationFee: Record "Operation Fee";
    begin
        OperationFee.SetRange(Code, OperationCode);
        OperationFee.SetRange("Type of Fee", TypeofFee);

        if not OperationFee.FindFirst() then
            exit(0);

        exit(OperationFee."Charge Amt. per Operation");
    end;

    local procedure GetRejectionFeeAmount(BillGroup: Record "Bill Group"; TotalAmount: Decimal; var RejectionFeeAmount: Decimal)
    var
        FeeRange: Record "Fee Range";
    begin
        FeeRange.SetRange(Code, BillGroup."Bank Account No.");
        FeeRange.SetRange("Currency Code", BillGroup."Currency Code");
        FeeRange.SetRange("Type of Fee", FeeRange."Type of Fee"::"Rejection Expenses");
        FeeRange.FindFirst();
        RejectionFeeAmount := TotalAmount * FeeRange."Charge % per Doc." / 100 + FeeRange."Charge Amount per Doc.";
    end;

    local procedure RejectPostedDocument(var PostedBillGroup: Record "Posted Bill Group"; var PostedCarteraDoc: Record "Posted Cartera Doc."; BillGroup: Record "Bill Group"; TotalAmount: Decimal; RejectionFeeAmount: Decimal; HasUnrealizedVAT: Boolean; ExpectedVATAmount: Decimal; IsTypeDiscount: Boolean; ExpectedDiscountAmount: Decimal)
    var
        PostedBillGroups: TestPage "Posted Bill Groups";
    begin
        OpenPostedBillGroupsAndSelectDocument(PostedBillGroups, PostedBillGroup, PostedCarteraDoc, BillGroup);

        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(TotalAmount);
        LibraryVariableStorage.Enqueue(RejectionFeeAmount);
        LibraryVariableStorage.Enqueue(HasUnrealizedVAT);
        LibraryVariableStorage.Enqueue(IsTypeDiscount);

        if HasUnrealizedVAT then
            LibraryVariableStorage.Enqueue(ExpectedVATAmount);

        if IsTypeDiscount then
            LibraryVariableStorage.Enqueue(ExpectedDiscountAmount);

        LibraryVariableStorage.Enqueue(PostJnlLinesMsg);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(JnlLinesPostedMsg);
        LibraryVariableStorage.Enqueue(OneDocumentRejectedMsg);
        PostedBillGroups.Docs.Reject.Invoke();
    end;

    local procedure RunFactoringExport(var BillGroup: Record "Bill Group"; FileName: Text)
    var
        BillGroupExportFactoring: Report "Bill group - Export factoring";
    begin
        Commit();
        BillGroup.SetRange("No.", BillGroup."No.");
        BillGroupExportFactoring.SetTableView(BillGroup);
        BillGroupExportFactoring.SetSilentMode(FileName);
        BillGroupExportFactoring.RunModal();
    end;

    local procedure PostCarteraJnl(var CarteraJournal: TestPage "Cartera Journal")
    begin
        CarteraJournal.Last();
        repeat
            CarteraJournal."Gen. Bus. Posting Group".SetValue('');
            CarteraJournal."Gen. Prod. Posting Group".SetValue('');
            CarteraJournal."Gen. Posting Type".SetValue(' ');
        until not CarteraJournal.Previous();

        CarteraJournal.Post.Invoke();
    end;

    local procedure VerifyFactoringCarteraDocuments(AccountNo: Code[20]; DocumentNo: Code[20]; PaymentMethod: Code[20]; TotalAmount: Decimal)
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        LibraryCarteraReceivables.FindCarteraDocs(CarteraDoc, AccountNo, DocumentNo);

        Assert.AreEqual(1, CarteraDoc.Count,
          StrSubstNo(FactoringCountMismatchErr, CarteraDoc.TableCaption(), '1'));
        Assert.AreEqual(CarteraDoc.Accepted::"Not Required", CarteraDoc.Accepted, 'Accepted field is not correct.');
        Assert.AreEqual(PaymentMethod, CarteraDoc."Payment Method Code", 'Payment method code is not correct');
        Assert.AreEqual(TotalAmount, CarteraDoc."Original Amount", 'Amount is wrong in the factoring document.');
    end;

    local procedure VerifyPostedBillGroup(BillGroup: Record "Bill Group"; CarteraDoc: Record "Cartera Doc.")
    var
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        OperationFee: Record "Operation Fee";
    begin
        // Header
        PostedBillGroup.Get(BillGroup."No.");
        Assert.AreEqual(BillGroup."Bank Account No.", PostedBillGroup."Bank Account No.",
          'Account no. is wrong on the Posted Bill Group.');
        Assert.AreEqual(BillGroup."Dealing Type", PostedBillGroup."Dealing Type",
          'Dealing Type is wrong on the Posted Bill Group.');
        Assert.AreEqual(BillGroup.Factoring, PostedBillGroup.Factoring,
          'Factoring is wrong on the Posted Bill Group.');

        if BillGroup.Factoring = BillGroup.Factoring::Risked then begin
            Assert.AreEqual(GetOperationFeeAmount(BillGroup."Bank Account No.",
                OperationFee."Type of Fee"::"Risked Factoring Expenses "),
              PostedBillGroup."Risked Factoring Exp. Amt.",
              'Risked Factoring Exp. Amt. is wrong on the Posted Bill Group.');
            Assert.AreEqual(0, PostedBillGroup."Unrisked Factoring Exp. Amt.",
              'Unrisked Factoring Exp. Amt. is wrong on the Posted Bill Group.');
        end else begin
            Assert.AreEqual(0, PostedBillGroup."Risked Factoring Exp. Amt.",
              'Risked Factoring Exp. Amt. is wrong on the Posted Bill Group.');
            Assert.AreEqual(GetOperationFeeAmount(BillGroup."Bank Account No.",
                OperationFee."Type of Fee"::"Unrisked Factoring Expenses"),
              PostedBillGroup."Unrisked Factoring Exp. Amt.",
              'Unrisked Factoring Exp. Amt. is wrong on the Posted Bill Group.');
        end;
        Assert.AreEqual(GetOperationFeeAmount(BillGroup."Bank Account No.",
            OperationFee."Type of Fee"::"Discount Interests"),
          PostedBillGroup."Discount Interests Amt.",
          'Discount Interests Amt. is wrong on the Posted Bill Group.');

        // Lines
        PostedCarteraDoc.Get(CarteraDoc.Type, CarteraDoc."Entry No.");
        Assert.AreEqual(CarteraDoc."Document No.", PostedCarteraDoc."Document No.",
          'Document no. is wrong on the Posted Cartera Doc.');
        Assert.AreEqual(CarteraDoc."Document Type", PostedCarteraDoc."Document Type",
          'Document Type is wrong on the Posted Cartera Doc.');
        Assert.AreEqual(CarteraDoc."Payment Method Code", PostedCarteraDoc."Payment Method Code",
          'Payment Method Code is wrong on the Posted Cartera Doc.');
        Assert.AreEqual(CarteraDoc."No.", PostedCarteraDoc."No.",
          'No. is wrong on the Posted Cartera Doc.');
        Assert.AreEqual(CarteraDoc."Remaining Amount", PostedCarteraDoc."Amount for Collection",
          'Amount for Collection is wrong on the Posted Cartera Doc.');
        Assert.AreEqual(CarteraDoc."Remaining Amount", PostedCarteraDoc."Remaining Amount",
          'Remaining Amount for Collection is wrong on the Posted Cartera Doc.');
    end;

    local procedure VerifyClosedBillGroup(PostedBillGroup: Record "Posted Bill Group"; PostedCarteraDoc: Record "Posted Cartera Doc.")
    var
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
    begin
        VerifyClosedBillGroup2(PostedBillGroup, PostedCarteraDoc, 0, ClosedCarteraDoc.Status::Honored);
    end;

    local procedure VerifyClosedBillGroup2(PostedBillGroup: Record "Posted Bill Group"; PostedCarteraDoc: Record "Posted Cartera Doc."; RemainingAmount: Decimal; ClosedDocumentStatus: Enum "Cartera Document Status")
    var
        ClosedBillGroup: Record "Closed Bill Group";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        ClosedBillGroups: TestPage "Closed Bill Groups";
    begin
        // Header
        ClosedBillGroup.Get(PostedBillGroup."No.");
        Assert.AreEqual(PostedBillGroup."Bank Account No.", ClosedBillGroup."Bank Account No.",
          'Account no. is wrong on the Closed Bill Group.');
        Assert.AreEqual(PostedBillGroup."Dealing Type", ClosedBillGroup."Dealing Type",
          'Dealing Type is wrong on the Closed Bill Group.');
        Assert.AreEqual(PostedBillGroup.Factoring, ClosedBillGroup.Factoring,
          'Factoring is wrong on the Closed Bill Group.');

        // Lines
        ClosedCarteraDoc.SetRange(Type, ClosedCarteraDoc.Type::Receivable);
        ClosedCarteraDoc.SetRange("Bill Gr./Pmt. Order No.", ClosedBillGroup."No.");
        ClosedCarteraDoc.FindFirst();

        Assert.AreEqual(PostedCarteraDoc."Document No.", ClosedCarteraDoc."Document No.",
          'Document no. is wrong on the Closed Cartera Doc.');
        Assert.AreEqual(PostedCarteraDoc."Document Type", ClosedCarteraDoc."Document Type",
          'Document Type is wrong on the Closed Cartera Doc.');
        Assert.AreEqual(PostedCarteraDoc."Payment Method Code", ClosedCarteraDoc."Payment Method Code",
          'Payment Method Code is wrong on the Closed Cartera Doc.');
        Assert.AreEqual(PostedCarteraDoc."No.", PostedCarteraDoc."No.",
          'No. is wrong on the Posted Cartera Doc.');
        Assert.AreEqual(PostedCarteraDoc."Amount for Collection", ClosedCarteraDoc."Amount for Collection",
          'Amount for Collection is wrong on the Closed Cartera Doc.');
        Assert.AreEqual(RemainingAmount, ClosedCarteraDoc."Remaining Amount",
          'Remaining Amount for Collection is wrong on the Closed Cartera Doc.');
        Assert.AreEqual(ClosedDocumentStatus, ClosedCarteraDoc.Status,
          'Status is wrong on the Closed Cartera Doc.');

        ClosedBillGroups.OpenEdit();
        ClosedBillGroups.GotoRecord(ClosedBillGroup);
        asserterror ClosedBillGroups.Docs.Redraw.Invoke();
        Assert.ExpectedError(OnlyBillsCanBeRedrawnErr);
        ClosedBillGroups.Close();
    end;

    local procedure VerifyRejectedInvoiceVATGLEntries(TotalAmount: Decimal; RejectionFeeAmount: Decimal; HasUnsettledVAT: Boolean; ExpectedVATAmount: Decimal; IsDealingTypeDiscount: Boolean; ExpectedDiscountAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        GLEntry.SetRange("Transaction No.", GLRegister."No.");

        GLEntry.Find('-');
        Assert.AreNearlyEqual(
          TotalAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(),
          'Total Credit Amount for Total Amount has a wrong value');

        GLEntry.Next();
        Assert.AreNearlyEqual(
          TotalAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(),
          'Total Debit Amount for Total Amount has a wrong value');

        if IsDealingTypeDiscount then begin
            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedDiscountAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(),
              'Total Credit Amount for Discount Amount has a wrong value');

            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedDiscountAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(),
              'Total Debit Amount for Discount Amount has a wrong value');
        end;

        if HasUnsettledVAT then begin
            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedVATAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(),
              'Total Credit Amount for Unsettled VAT Amount has a wrong value');

            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedVATAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(),
              'Total Debit Amount for Unsettled VAT Amount has a wrong value');
        end;

        GLEntry.Next();
        Assert.AreNearlyEqual(
          RejectionFeeAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(),
          'Total Debit Amount for Rejection Fee has a wrong value');

        GLEntry.Next();
        Assert.AreNearlyEqual(
          RejectionFeeAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(),
          'Total Debit Amount for Rejection Fee has a wrong value');
    end;

    local procedure VerifyExportBillGroup(FileName: Text[1024]; BankAccount: Record "Bank Account"; SuffixValue: Code[3])
    var
        CompanyInformation: Record "Company Information";
        Line: Text[1024];
    begin
        Line := LibraryTextFileValidation.ReadLine(FileName, 1);
        CompanyInformation.Get();

        Assert.AreEqual(SuffixValue, CopyStr(LibraryTextFileValidation.ReadValue(Line, 3, 5), 1, 3),
          'Incorrect suffix');
        Assert.AreEqual(PadStr(CompanyInformation.Name, 30, ' '),
          CopyStr(LibraryTextFileValidation.ReadValue(Line, 8, 30), 1, 30),
          StrSubstNo('%1 is wrong.', CompanyInformation.FieldCaption(Name)));

        Line := LibraryTextFileValidation.ReadLine(FileName, 3);

        Assert.AreEqual(BankAccount."CCC Bank No.", CopyStr(LibraryTextFileValidation.ReadValue(Line, 171, 4), 1, 4),
          StrSubstNo('%1 is wrong.', BankAccount.FieldCaption("CCC Bank No.")));
        Assert.AreEqual(BankAccount."CCC Bank Branch No.", CopyStr(LibraryTextFileValidation.ReadValue(Line, 175, 4), 1, 4),
          StrSubstNo('%1 is wrong.', BankAccount.FieldCaption("CCC Bank Branch No.")));
        Assert.AreEqual(BankAccount."CCC Bank Account No.", CopyStr(LibraryTextFileValidation.ReadValue(Line, 179, 10), 1, 10),
          StrSubstNo('%1 is wrong.', BankAccount.FieldCaption("CCC Bank Account No.")));
    end;

    local procedure TotalSettlePostedBillGroup(var PostedBillGroup: Record "Posted Bill Group"; var PostedCarteraDoc: Record "Posted Cartera Doc."; BillGroup: Record "Bill Group")
    var
        PostedBillGroups: TestPage "Posted Bill Groups";
    begin
        PostedCarteraDoc.SetRange(Type, PostedCarteraDoc.Type::Receivable);
        PostedCarteraDoc.SetRange("Bill Gr./Pmt. Order No.", BillGroup."No.");
        PostedCarteraDoc.FindFirst();

        PostedBillGroup.Get(BillGroup."No.");
        PostedBillGroups.OpenEdit();
        PostedBillGroups.GotoRecord(PostedBillGroup);
        LibraryVariableStorage.Enqueue(RcvDocSettledMsg); // for the message handler
        PostedBillGroups.Docs."Total Settlement".Invoke();
    end;

    local procedure PartialSettlePostedBillGroup(var PostedBillGroup: Record "Posted Bill Group"; var PostedCarteraDoc: Record "Posted Cartera Doc."; BillGroup: Record "Bill Group"; PercentageToSettle: Decimal)
    var
        PostedBillGroups: TestPage "Posted Bill Groups";
    begin
        PostedCarteraDoc.SetRange(Type, PostedCarteraDoc.Type::Receivable);
        PostedCarteraDoc.SetRange("Bill Gr./Pmt. Order No.", BillGroup."No.");
        PostedCarteraDoc.FindFirst();

        PostedBillGroup.Get(BillGroup."No.");
        PostedBillGroups.OpenEdit();
        PostedBillGroups.GotoRecord(PostedBillGroup);
        LibraryVariableStorage.Enqueue(PostedCarteraDoc."Amount for Collection" * PercentageToSettle / 100); // for the request page handler
        LibraryVariableStorage.Enqueue(RcvDocPartialSettledMsg); // for the message handler
        PostedBillGroups.Docs."Partial Settlement".Invoke();
    end;

    local procedure SetSalesAllowMultiplePostingGroups(AllowMultiplePostingGroups: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Allow Multiple Posting Groups" := AllowMultiplePostingGroups;
        SalesReceivablesSetup."Check Multiple Posting Groups" := "Posting Group Change Method"::"Alternative Groups";
        SalesReceivablesSetup.Modify();
    end;

    local procedure PostSalesInvoiceWithCarteraDoc(var Customer: Record Customer): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, LocalCurrencyCode);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, "Sales Document Type"::Invoice, Customer."No.", '', 1, '', 0D);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup.Validate("Factoring for Collection Acc.", LibraryERM.CreateGLAccountNo());
        CustomerPostingGroup.Modify();
        LibrarySales.CreateAltCustomerPostingGroup(Customer."Customer Posting Group", CustomerPostingGroup.Code);
        SalesHeader.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        SalesHeader.Modify();

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostBillGroup(var BillGroup: Record "Bill Group"; var CarteraDoc: Record "Cartera Doc."; Customer: Record Customer; DocumentNo: Code[20]);
    var
        BankAccount: Record "Bank Account";
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
    begin
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateFactoringOperationFeesForBankAccount(BankAccount);
        CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection, BillGroup.Factoring::Unrisked);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(BillGroupSuccessfulPostedMsg);
        Commit();
        BGPostAndPrint.ReceivablePostOnly(BillGroup);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        NewReply: Variant;
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        LibraryVariableStorage.Dequeue(NewReply);

        Assert.IsTrue(StrPos(Question, ExpectedMessage) > 0, Question);

        Reply := NewReply;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);

        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBillGroupRequestPage(var PostBillGroup: TestRequestPage "Post Bill Group")
    begin
        PostBillGroup.TemplName.SetValue(CarteraGenJournalTemplate.Name);
        PostBillGroup.BatchName.SetValue(CarteraGenJournalBatch.Name);
        PostBillGroup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CarteraJnlModalPageHandler(var CarteraJournal: TestPage "Cartera Journal")
    begin
        PostCarteraJnl(CarteraJournal);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TotalSettleDocsInPostBillGroupRequestPage(var SettleDocsinPostBillGr: TestRequestPage "Settle Docs. in Post. Bill Gr.")
    begin
        SettleDocsinPostBillGr.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PartialSettleDocsInPostBillGroupRequestPage(var PartialSettlReceivable: TestRequestPage "Partial Settl.- Receivable")
    var
        Amount: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        PartialSettlReceivable.SettledAmount.SetValue(Amount);
        PartialSettlReceivable.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportBillGroupRequestPage(var BillGroupExportfactoring: TestRequestPage "Bill group - Export factoring")
    var
        DeliveryDate: Variant;
        BankSuffix: Variant;
    begin
        LibraryVariableStorage.Dequeue(DeliveryDate);
        LibraryVariableStorage.Dequeue(BankSuffix);
        BillGroupExportfactoring.DeliveryDate.SetValue(DeliveryDate);
        BillGroupExportfactoring.BankSuffix.SetValue(BankSuffix);

        BillGroupExportfactoring.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RejectCarteraDocRequestPageHandler(var RejectDocs: TestRequestPage "Reject Docs.")
    begin
        RejectDocs.IncludeExpenses.SetValue(true);
        RejectDocs.UseJournal.SetValue(true);

        RejectDocs.TemplateName.SetValue(CarteraGenJournalTemplate.Name);
        RejectDocs.BatchName.SetValue(CarteraGenJournalBatch.Name);
        RejectDocs.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RejectionVerifyAndPostCarteraJournalHandler(var CarteraJournal: TestPage "Cartera Journal")
    var
        AmountVariant: Variant;
        RejectionFeeAmountVariant: Variant;
        HasUnrealizedVATVariant: Variant;
        ExpectedVATAmountVariant: Variant;
        IsRejectionVariant: Variant;
        IsDealingTypeDiscountVariant: Variant;
        ExpectedDiscountAmountVariant: Variant;
        Amount: Decimal;
        RejectionFeeAmount: Decimal;
        CreditAmount: Decimal;
        ExpectedVATAmount: Decimal;
        ExpectedDiscountAmount: Decimal;
        HasUnrealizedVAT: Boolean;
        IsRejection: Boolean;
        IsDealingTypeDiscount: Boolean;
    begin
        LibraryVariableStorage.Dequeue(IsRejectionVariant);
        IsRejection := IsRejectionVariant;

        if not IsRejection then begin
            PostCarteraJnl(CarteraJournal);
            exit;
        end;

        LibraryVariableStorage.Dequeue(AmountVariant);
        LibraryVariableStorage.Dequeue(RejectionFeeAmountVariant);
        LibraryVariableStorage.Dequeue(HasUnrealizedVATVariant);
        LibraryVariableStorage.Dequeue(IsDealingTypeDiscountVariant);

        Amount := AmountVariant;
        RejectionFeeAmount := RejectionFeeAmountVariant;
        HasUnrealizedVAT := HasUnrealizedVATVariant;
        IsDealingTypeDiscount := IsDealingTypeDiscountVariant;

        // Go from the last to check that there are only 4 rows present
        CarteraJournal.Last();
        Assert.AreNearlyEqual(
          RejectionFeeAmount, CarteraJournal."Credit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          'Wrong amount on the Rejection Fee line');
        CreditAmount := CarteraJournal."Credit Amount".AsDecimal();

        CarteraJournal.Previous();
        Assert.AreNearlyEqual(
          RejectionFeeAmount, CarteraJournal."Debit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          'Wrong amount on the Rejection Fee line');
        Assert.AreEqual(CreditAmount, CarteraJournal."Debit Amount".AsDecimal(), 'Credit and Debit amounts must match');

        if HasUnrealizedVAT then begin
            LibraryVariableStorage.Dequeue(ExpectedVATAmountVariant);
            ExpectedVATAmount := ExpectedVATAmountVariant;

            CarteraJournal.Previous();
            Assert.AreNearlyEqual(
              ExpectedVATAmount, CarteraJournal."Credit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on the line');

            CarteraJournal.Previous();
            Assert.AreNearlyEqual(
              ExpectedVATAmount, CarteraJournal."Debit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on the line');
        end;

        if IsDealingTypeDiscount then begin
            LibraryVariableStorage.Dequeue(ExpectedDiscountAmountVariant);
            ExpectedDiscountAmount := ExpectedDiscountAmountVariant;

            CarteraJournal.Previous();
            Assert.AreNearlyEqual(
              ExpectedDiscountAmount, CarteraJournal."Credit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
              'Wrong amount on the line');

            CarteraJournal.Previous();
            Assert.AreNearlyEqual(
              ExpectedDiscountAmount, CarteraJournal."Debit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
              'Wrong amount on the line');
        end;

        CarteraJournal.Previous();
        Assert.AreNearlyEqual(
          Amount, CarteraJournal."Credit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on the line');

        CarteraJournal.Previous();
        Assert.AreNearlyEqual(
          Amount, CarteraJournal."Debit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on the line');

        CarteraJournal.Post.Invoke();
    end;
}

