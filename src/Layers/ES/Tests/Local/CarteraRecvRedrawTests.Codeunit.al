codeunit 147541 "Cartera Recv. Redraw Tests"
{
    // // [FEATURE] [Cartera] [Redraw]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FileManagement: Codeunit "File Management";
        IsInitialized: Boolean;
        UnexpectedMessageErr: Label 'Unexpected Message.';
        UnexpectedConfirmDialogErr: Label 'Unexpected Confirmation handler appeared.';
        NotPrintedPaymentOrderQuestionMsg: Label 'This %1 has not been printed. Do you want to continue?';
        ReverseEntriesQst: Label 'To reverse these entries, correcting entries will be posted.\Do you want to reverse the entries?';
        SettlementCompletedSuccessfullyMsg: Label '%1 receivable documents totaling %2 have been settled.';
        JournalSuccessfullyPostedMsg: Label 'The journal lines were successfully posted.';
        SuccessfulBillRedrawalMsg: Label '%1 bills have been prepared for redrawal.';
        DocsRejectedMsg: Label '%1 documents have been rejected.';
        PostJournalLinesQst: Label 'Do you want to post the journal lines?';
        BankBillSuccessfullyPostedMsg: Label 'Bank Bill Group %1 was successfully posted for discount.';
        CannotBeReversedErr: Label 'The entry cannot be reversed';
        BillShouldBeMarkedAsRedrawnErr: Label 'Bill is not marked as redrawn';
        RedrawReqPageOption: Option update,verify;

    [Test]
    [HandlerFunctions('PostBillGroupsModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageHandler,RedrawReceivableBillsPageHandler,CarteraJnlModalPageHandler,SettleDocsInPostBillGrModalPageHandler')]
    [Scope('OnPrem')]
    procedure PartialRedrawBillFromClosedBill()
    var
        ClosedBillGroup: Record "Closed Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        BillGroup: Record "Bill Group";
        InvoiceNo: Code[20];
        RedrawAmtToReduce: Decimal;
    begin
        Initialize();

        // Setup
        CreateCarteraCustumer(Customer);
        PaymentTerms.Get(Customer."Payment Terms Code");
        CreatePaymentTermsInstallment(PaymentTerms, 3);
        CreateAndPostInvoice(Customer, InvoiceNo);

        VerifyCarteraDoc(InvoiceNo, PaymentTerms);

        CreateBillGroupForInvoice(BillGroup, InvoiceNo);
        PostBillGroup(BillGroup, PostedBillGroup);
        SettlePostedBillGroup(PostedBillGroup, ClosedBillGroup);

        // Exercise
        RedrawAmtToReduce := 1;
        RedrawFromClosedBillGroup(ClosedBillGroup, RedrawAmtToReduce);

        // Verify
        VerifyRedraw(InvoiceNo, BillGroup, RedrawAmtToReduce);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostBillGroupsModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageHandler,RedrawReceivableBillsPageHandler,CarteraJnlModalPageHandler,SettleDocsInPostBillGrModalPageHandler')]
    [Scope('OnPrem')]
    procedure FullRedrawBillFromClosedBill()
    var
        ClosedBillGroup: Record "Closed Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        BillGroup: Record "Bill Group";
        InvoiceNo: Code[20];
        RedrawAmtToReduce: Decimal;
    begin
        Initialize();

        // Setup
        CreateCarteraCustumer(Customer);
        PaymentTerms.Get(Customer."Payment Terms Code");
        CreatePaymentTermsInstallment(PaymentTerms, 1);
        CreateAndPostInvoice(Customer, InvoiceNo);

        VerifyCarteraDoc(InvoiceNo, PaymentTerms);

        CreateBillGroupForInvoice(BillGroup, InvoiceNo);
        PostBillGroup(BillGroup, PostedBillGroup);
        SettlePostedBillGroup(PostedBillGroup, ClosedBillGroup);

        // Exercise
        RedrawAmtToReduce := 0;
        RedrawFromClosedBillGroup(ClosedBillGroup, RedrawAmtToReduce);

        // Verify
        VerifyRedraw(InvoiceNo, BillGroup, RedrawAmtToReduce);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostBillGroupsModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageHandler,RedrawReceivableBillsPageHandler,CarteraJnlModalPageHandler,RequestDocsModalPageHandler')]
    [Scope('OnPrem')]
    procedure FullRedrawRejectedBillFromClosedBill()
    var
        ClosedBillGroup: Record "Closed Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        BillGroup: Record "Bill Group";
        InvoiceNo: Code[20];
        RedrawAmtToReduce: Decimal;
    begin
        Initialize();

        // Setup
        CreateCarteraCustumer(Customer);
        PaymentTerms.Get(Customer."Payment Terms Code");
        CreatePaymentTermsInstallment(PaymentTerms, 1);
        CreateAndPostInvoice(Customer, InvoiceNo);

        VerifyCarteraDoc(InvoiceNo, PaymentTerms);

        CreateBillGroupForInvoice(BillGroup, InvoiceNo);
        PostBillGroup(BillGroup, PostedBillGroup);
        RejectPostedBillGroup(PostedBillGroup, ClosedBillGroup);

        // Exercise
        RedrawAmtToReduce := 0;
        RedrawFromClosedBillGroup(ClosedBillGroup, RedrawAmtToReduce);

        // Verify
        VerifyRedraw(InvoiceNo, BillGroup, RedrawAmtToReduce);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostBillGroupsModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageHandler,RedrawReceivableBillsPageHandler,CarteraJnlModalPageHandler,RequestDocsModalPageHandler')]
    [Scope('OnPrem')]
    procedure FullRedrawRejectedBillFromClosedReceivablesDocs()
    var
        ClosedBillGroup: Record "Closed Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        BillGroup: Record "Bill Group";
        InvoiceNo: Code[20];
        RedrawAmtToReduce: Decimal;
    begin
        Initialize();

        // Setup
        CreateCarteraCustumer(Customer);
        PaymentTerms.Get(Customer."Payment Terms Code");
        CreatePaymentTermsInstallment(PaymentTerms, 1);
        CreateAndPostInvoice(Customer, InvoiceNo);

        VerifyCarteraDoc(InvoiceNo, PaymentTerms);

        CreateBillGroupForInvoice(BillGroup, InvoiceNo);
        PostBillGroup(BillGroup, PostedBillGroup);
        RejectPostedBillGroup(PostedBillGroup, ClosedBillGroup);

        // Exercise
        RedrawAmtToReduce := 0;
        RedrawFromClosedReceivablesDocs(ClosedBillGroup, RedrawAmtToReduce);

        // Verify
        VerifyRedraw(InvoiceNo, BillGroup, RedrawAmtToReduce);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostBillGroupsModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageHandler,RedrawReceivableBillsPageHandler,CarteraJnlModalPageHandler,SettleDocsInPostBillGrModalPageHandler')]
    [Scope('OnPrem')]
    procedure ReverseBillFromClosedBill()
    var
        ClosedBillGroup: Record "Closed Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        BillGroup: Record "Bill Group";
        InvoiceNo: Code[20];
        RedrawAmtToReduce: Decimal;
    begin
        Initialize();

        // Setup
        CreateCarteraCustumer(Customer);
        PaymentTerms.Get(Customer."Payment Terms Code");
        CreatePaymentTermsInstallment(PaymentTerms, 1);
        CreateAndPostInvoice(Customer, InvoiceNo);

        VerifyCarteraDoc(InvoiceNo, PaymentTerms);

        CreateBillGroupForInvoice(BillGroup, InvoiceNo);
        PostBillGroup(BillGroup, PostedBillGroup);

        SettlePostedBillGroup(PostedBillGroup, ClosedBillGroup);
        RedrawAmtToReduce := 0;
        RedrawFromClosedBillGroup(ClosedBillGroup, RedrawAmtToReduce);

        // Exercise
        LibraryVariableStorage.Enqueue(ReverseEntriesQst);
        asserterror ReverseEntry();
        Assert.ExpectedError(CannotBeReversedErr)
    end;

    [Test]
    [HandlerFunctions('PostBillGroupsModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageHandler,RedrawReceivableBillsPageHandler,CarteraJnlModalPageHandler,SettleDocsInPostBillGrModalPageHandler,BankRiskHandler')]
    [Scope('OnPrem')]
    procedure FullRedrawBillBankRisk()
    var
        ClosedBillGroup: Record "Closed Bill Group";
        PostedBillGroup: Record "Posted Bill Group";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        BillGroup: Record "Bill Group";
        BankAccount: Record "Bank Account";
        InvoiceNo: Code[20];
        RedrawAmtToReduce: Decimal;
    begin
        Initialize();

        // Setup
        CreateCarteraCustumer(Customer);
        PaymentTerms.Get(Customer."Payment Terms Code");
        CreatePaymentTermsInstallment(PaymentTerms, 1);
        CreateAndPostInvoice(Customer, InvoiceNo);

        VerifyCarteraDoc(InvoiceNo, PaymentTerms);

        // Exercise create unposted bank risk
        CreateBillGroupForInvoice(BillGroup, InvoiceNo);

        // Verify unposted bank risk
        BankAccount.SetRange("No.", BillGroup."Bank Account No.");
        REPORT.Run(REPORT::"Bank - Risk", true, false, BankAccount);
        VerifyBankRisk(InvoiceNo, true, false);

        // Verify posted bank risk
        PostBillGroup(BillGroup, PostedBillGroup);

        // Verify posted bank risk
        BankAccount.SetRange("No.", BillGroup."Bank Account No.");
        REPORT.Run(REPORT::"Bank - Risk", true, false, BankAccount);
        VerifyBankRisk(InvoiceNo, false, true);

        // Exercise settle bank risk
        SettlePostedBillGroup(PostedBillGroup, ClosedBillGroup);
        Commit();

        // Verify setttled bank risk
        REPORT.Run(REPORT::"Bank - Risk", true, false, BankAccount);
        VerifyBankRisk(InvoiceNo, false, false);

        // Exercise Redrawn bank risk
        RedrawAmtToReduce := 0;
        RedrawFromClosedBillGroup(ClosedBillGroup, RedrawAmtToReduce);

        // Verify redrawn bank risk
        REPORT.Run(REPORT::"Bank - Risk", true, false, BankAccount);
        VerifyBankRisk(InvoiceNo, false, false);
        VerifyRedraw(InvoiceNo, BillGroup, RedrawAmtToReduce);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,RedrawReceivableBillsPageHandler,CarteraJnlModalPageHandler,RequestDocsModalPageHandler')]
    [Scope('OnPrem')]
    procedure RedrawRejectedCarteraDocFromClosedReceivablesDocs()
    var
        Customer: Record Customer;
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 376737] Redraw an already rejected bill from Closed Receivables Docs
        Initialize();

        // [GIVEN] Posted Cartera Doc
        CreateCarteraCustumer(Customer);
        CreateAndPostInvoice(Customer, InvoiceNo);

        // [GIVEN] Posted Cartera Doc is rejected
        RejectPostedCarteraDoc(InvoiceNo);
        Commit();

        // [WHEN] Redraw Bill from Closed Receivable Docs
        RedrawClosedCarteraDocs(InvoiceNo, 0);

        // [THEN] Closed Cartera Doc is marked as redrawn
        VerifyRedrawInClosedCarteraDoc(InvoiceNo);
    end;

    [Test]
    [HandlerFunctions('RedrawCarteraBillReqPageHandler')]
    [Scope('OnPrem')]
    procedure RedrawReportClearValuesOnReqPage()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        // [SCENARIO 377552] Template Name, Batch Name fields should be cleared when run request page of Redraw Receivable Bills with saved values
        // [FEATURE] [UT] [UI]
        Initialize();
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry.Insert();
        CustLedgerEntry.SetRecFilter();
        Commit();

        // [GIVEN] Template Name and Batch Name are filled in on Request Page with Cartera Journal Batch values
        GetCarteraTemplBatch(TemplateName, BatchName);
        LibraryVariableStorage.Enqueue(RedrawReqPageOption::update);
        LibraryVariableStorage.Enqueue(TemplateName);
        LibraryVariableStorage.Enqueue(BatchName);
        REPORT.RunModal(REPORT::"Redraw Receivable Bills", true, false, CustLedgerEntry);

        // [WHEN] Run Redraw Receivable Bills again
        LibraryVariableStorage.Enqueue(RedrawReqPageOption::verify);
        REPORT.RunModal(REPORT::"Redraw Receivable Bills", true, false, CustLedgerEntry);

        // [THEN] Template Name and Batch Name fields are empty
        // verification is done in RedrawCarteraBillReqPageHandler
    end;

    [Test]
    [HandlerFunctions('CarteraDocumentsActionModalPageHandler,BankRiskSaveAsPDFHandler')]
    [Scope('OnPrem')]
    procedure PrintBankRisk()
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        BillGroup: Record "Bill Group";
        BankAccount: Record "Bank Account";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 333888] Report "Bank - Risk" can be printed without RDLC rendering errors
        Initialize();

        CreateCarteraCustumer(Customer);
        PaymentTerms.Get(Customer."Payment Terms Code");
        CreatePaymentTermsInstallment(PaymentTerms, 1);
        CreateAndPostInvoice(Customer, InvoiceNo);
        CreateBillGroupForInvoice(BillGroup, InvoiceNo);

        // [WHEN] Report "Bank - Risk" is being printed to PDF
        BankAccount.SetRange("No.", BillGroup."Bank Account No.");
        REPORT.Run(REPORT::"Bank - Risk", true, false, BankAccount);
        // [THEN] No RDLC rendering errors
    end;

    [Test]
    [HandlerFunctions('NoticeAssignmentCreditsSaveAsPDFHandler')]
    [Scope('OnPrem')]
    procedure PrintNoticeAssignmentCredits()
    var

    begin
        // [FEATURE] [UT]
        // [SCENARIO 333888] Report "Notice Assignment Credits" can be printed without RDLC rendering errors
        Initialize();

        // [WHEN] Report "Notice Assignment Credits" is being printed to PDF
        Commit();
        REPORT.Run(REPORT::"Notice Assignment Credits");
        // [THEN] No RDLC rendering errors
    end;

    local procedure Initialize()
    var
        CarteraSetup: Record "Cartera Setup";
    begin
        LibraryReportDataset.Reset();
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        CarteraSetup.Get();
        CarteraSetup.Validate("Bills Discount Limit Warnings", false);
        CarteraSetup.Modify(true);

        IsInitialized := true;
    end;

    local procedure CreateCarteraCustumer(var Customer: Record Customer)
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, '');
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
    end;

    local procedure CreateAndPostInvoice(Customer: Record Customer; var DocNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateBillGroupForInvoice(var BillGroup: Record "Bill Group"; InvoiceNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, '');
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Discount);
        LibraryVariableStorage.Enqueue(InvoiceNo);
        AddCarteraDocumentToBillGroup(BillGroup);
        Commit();
    end;

    local procedure PostBillGroup(BillGroup: Record "Bill Group"; var PostedBillGroup: Record "Posted Bill Group")
    var
        POPostAndPrint: Codeunit "BG/PO-Post and Print";
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(NotPrintedPaymentOrderQuestionMsg, BillGroup.TableCaption()));
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(PostJournalLinesQst);
        LibraryVariableStorage.Enqueue(StrSubstNo(JournalSuccessfullyPostedMsg));
        LibraryVariableStorage.Enqueue(StrSubstNo(BankBillSuccessfullyPostedMsg, BillGroup."No."));
        POPostAndPrint.ReceivablePostOnly(BillGroup);

        PostedBillGroup.SetFilter("No.", BillGroup."No.");
        PostedBillGroup.FindFirst();
    end;

    local procedure SettlePostedBillGroup(PostedBillGroup: Record "Posted Bill Group"; var ClosedBillGroup: Record "Closed Bill Group")
    var
        PostedBillGroupsTestPage: TestPage "Posted Bill Groups";
    begin
        PostedBillGroupsTestPage.OpenEdit();
        PostedBillGroupsTestPage.GotoRecord(PostedBillGroup);

        LibraryVariableStorage.Enqueue(
          StrSubstNo(
            SettlementCompletedSuccessfullyMsg, 1, PostedBillGroupsTestPage.Docs."Remaining Amount".AsDecimal()));
        PostedBillGroupsTestPage.Docs."Total Settlement".Invoke();

        ClosedBillGroup.SetRange("No.", PostedBillGroup."No.");
        ClosedBillGroup.FindFirst();
    end;

    local procedure RejectPostedBillGroup(PostedBillGroup: Record "Posted Bill Group"; var ClosedBillGroup: Record "Closed Bill Group")
    var
        PostedBillGroupsTestPage: TestPage "Posted Bill Groups";
    begin
        PostedBillGroupsTestPage.OpenEdit();
        PostedBillGroupsTestPage.GotoRecord(PostedBillGroup);

        LibraryVariableStorage.Enqueue(StrSubstNo(DocsRejectedMsg, 1));
        PostedBillGroupsTestPage.Docs.Reject.Invoke();

        ClosedBillGroup.SetRange("No.", PostedBillGroup."No.");
        ClosedBillGroup.FindFirst();
    end;

    local procedure RejectPostedCarteraDoc(InvoiceNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
        ReceivablesCarteraDocs: TestPage "Receivables Cartera Docs";
    begin
        CarteraDoc.SetRange("Document No.", InvoiceNo);
        CarteraDoc.FindFirst();
        LibraryVariableStorage.Enqueue(StrSubstNo(DocsRejectedMsg, 1));
        ReceivablesCarteraDocs.OpenEdit();
        ReceivablesCarteraDocs.GotoRecord(CarteraDoc);
        ReceivablesCarteraDocs.Reject.Invoke();
    end;

    local procedure RedrawFromClosedBillGroup(ClosedBillGroup: Record "Closed Bill Group"; RedrawAmtToReduce: Decimal)
    var
        ClosedBillGroupsTestPage: TestPage "Closed Bill Groups";
    begin
        ClosedBillGroupsTestPage.OpenEdit();
        ClosedBillGroupsTestPage.GotoRecord(ClosedBillGroup);

        LibraryVariableStorage.Enqueue(ClosedBillGroupsTestPage.Docs."Due Date".AsDate());
        LibraryVariableStorage.Enqueue(RedrawAmtToReduce);
        LibraryVariableStorage.Enqueue(PostJournalLinesQst);
        LibraryVariableStorage.Enqueue(StrSubstNo(JournalSuccessfullyPostedMsg));
        LibraryVariableStorage.Enqueue(StrSubstNo(SuccessfulBillRedrawalMsg, 1));
        ClosedBillGroupsTestPage.Docs.Redraw.Invoke(); // Redraw
    end;

    local procedure RedrawFromClosedReceivablesDocs(ClosedBillGroup: Record "Closed Bill Group"; RedrawAmtToReduce: Decimal)
    var
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
    begin
        ClosedCarteraDoc.SetRange("Bill Gr./Pmt. Order No.", ClosedBillGroup."No.");
        ClosedCarteraDoc.FindFirst();
        RedrawReceivableBills(ClosedCarteraDoc, RedrawAmtToReduce);
    end;

    local procedure RedrawClosedCarteraDocs(DocumentNo: Code[20]; RedrawAmtToReduce: Decimal)
    var
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
    begin
        FindClosedCarteraDocForInvoice(ClosedCarteraDoc, DocumentNo);
        RedrawReceivableBills(ClosedCarteraDoc, RedrawAmtToReduce);
    end;

    local procedure RedrawReceivableBills(var ClosedCarteraDoc: Record "Closed Cartera Doc."; RedrawAmtToReduce: Decimal)
    var
        ReceivableClosedCarteraDocs: TestPage "Receivable Closed Cartera Docs";
    begin
        ReceivableClosedCarteraDocs.OpenEdit();
        ReceivableClosedCarteraDocs.GotoRecord(ClosedCarteraDoc);

        LibraryVariableStorage.Enqueue(ClosedCarteraDoc."Due Date");
        LibraryVariableStorage.Enqueue(RedrawAmtToReduce);
        LibraryVariableStorage.Enqueue(PostJournalLinesQst);
        LibraryVariableStorage.Enqueue(StrSubstNo(JournalSuccessfullyPostedMsg));
        LibraryVariableStorage.Enqueue(StrSubstNo(SuccessfulBillRedrawalMsg, 1));
        ReceivableClosedCarteraDocs.Redraw.Invoke();
    end;

    local procedure ReverseEntry()
    var
        ReversalEntry: Record "Reversal Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessageText: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessageText);
        Assert.AreEqual(Format(ExpectedMessageText), Question, UnexpectedConfirmDialogErr);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessageText: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessageText);
        Assert.AreEqual(ExpectedMessageText, Message, UnexpectedMessageErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CarteraDocumentsActionModalPageHandler(var CarteraDocuments: Page "Cartera Documents"; var Response: Action)
    var
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.FindFirst();

        // From the Cartera Document page, select the record filtered by 'Document No.'
        CarteraDocuments.SetRecord(CarteraDoc);

        Response := ACTION::LookupOK;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RedrawReceivableBillsPageHandler(var RedrawReceivableBillsRequestPage: TestRequestPage "Redraw Receivable Bills")
    var
        ClosedBillDueDate: Variant;
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        LibraryVariableStorage.Dequeue(ClosedBillDueDate);

        GetCarteraTemplBatch(TemplateName, BatchName);

        RedrawReceivableBillsRequestPage.NewDueDate.SetValue(CalcDate('<1D>', ClosedBillDueDate));
        RedrawReceivableBillsRequestPage.NewPmtMethod.SetValue('');
        RedrawReceivableBillsRequestPage.FinanceCharges.SetValue(false);
        RedrawReceivableBillsRequestPage.DiscCollExpenses.SetValue(false);
        RedrawReceivableBillsRequestPage.RejectionExpenses.SetValue(false);
        RedrawReceivableBillsRequestPage.AuxJnlTemplateName.SetValue(TemplateName);
        RedrawReceivableBillsRequestPage.AuxJnlBatchName.SetValue(BatchName);

        RedrawReceivableBillsRequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SettleDocsInPostBillGrModalPageHandler(var SettleDocsInPostBillGr: TestRequestPage "Settle Docs. in Post. Bill Gr.")
    begin
        SettleDocsInPostBillGr.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBillGroupsModalPageHandler(var PostBillGroup: TestRequestPage "Post Bill Group")
    var
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        GetCarteraTemplBatch(TemplateName, BatchName);

        PostBillGroup.TemplName.SetValue(TemplateName);
        PostBillGroup.BatchName.SetValue(BatchName);
        PostBillGroup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CarteraJnlModalPageHandler(var CarteraJournal: TestPage "Cartera Journal")
    var
        RedrawAmtToReduceVariant: Variant;
        RedrawAmtToReduce: Decimal;
    begin
        LibraryVariableStorage.Dequeue(RedrawAmtToReduceVariant);
        RedrawAmtToReduce := RedrawAmtToReduceVariant;

        if RedrawAmtToReduce <> 0 then begin
            CarteraJournal.First();
            CarteraJournal."Credit Amount".SetValue(CarteraJournal."Credit Amount".AsDecimal() - RedrawAmtToReduce);
            CarteraJournal.Next();
            CarteraJournal."Debit Amount".SetValue(CarteraJournal."Debit Amount".AsDecimal() - RedrawAmtToReduce);
        end;
        CarteraJournal.Post.Invoke();
        CarteraJournal.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestDocsModalPageHandler(var RejectDocs: TestRequestPage "Reject Docs.")
    begin
        RejectDocs.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankRiskHandler(var BankRisk: TestRequestPage "Bank - Risk")
    begin
        BankRisk.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure AddCarteraDocumentToBillGroup(BillGroup: Record "Bill Group")
    var
        BillGroups: TestPage "Bill Groups";
    begin
        BillGroups.OpenEdit();
        BillGroups.GotoRecord(BillGroup);

        BillGroups.Docs.Insert.Invoke();

        BillGroups.OK().Invoke();
    end;

    local procedure CreatePaymentTermsInstallment(var PaymentTerms: Record "Payment Terms"; NoOfInstallments: Integer)
    var
        Installment: Record Installment;
        RemPct: Decimal;
        i: Integer;
    begin
        Evaluate(PaymentTerms."Due Date Calculation", '<30D>');
        PaymentTerms.Modify();

        RemPct := 100;
        for i := 1 to NoOfInstallments do begin
            Installment.Init();
            Installment.Validate("Payment Terms Code", PaymentTerms.Code);
            Installment.Validate("Line No.", i);
            Installment.Validate("% of Total", Round(RemPct * 1 / NoOfInstallments));
            Installment.Validate("Gap between Installments", '<30D>');
            Installment.Insert(true);

            NoOfInstallments -= 1;
            RemPct -= Installment."% of Total";
        end;

        Commit();
    end;

    local procedure GetCarteraTemplBatch(var TemplateName: Code[10]; var BatchName: Code[10])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Cartera);
        GenJnlTemplate.SetRange(Recurring, false);
        GenJnlTemplate.FindFirst();

        GenJnlBatch.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlBatch.FindFirst();

        TemplateName := GenJnlTemplate.Name;
        BatchName := GenJnlBatch.Name;
    end;

    local procedure FindClosedCarteraDocForInvoice(var ClosedCarteraDoc: Record "Closed Cartera Doc."; InvoiceNo: Code[20])
    begin
        ClosedCarteraDoc.SetRange("Document No.", InvoiceNo);
        ClosedCarteraDoc.FindFirst();
    end;

    local procedure VerifyCarteraDoc(PostedInvDocNo: Code[20]; PaymentTerms: Record "Payment Terms")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CarteraDoc: Record "Cartera Doc.";
        Installment: Record Installment;
        PaymentDueDate: Date;
    begin
        // Check that the created lines in Cartera Doc is distributed according to the Payment Installment terms
        SalesInvoiceHeader.Get(PostedInvDocNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        CarteraDoc.SetRange("Document No.", PostedInvDocNo);
        CarteraDoc.FindSet();
        // The first line carries the entire VAT Amount
        CarteraDoc."Remaining Amount" -= (SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount);

        Installment.SetRange("Payment Terms Code", PaymentTerms.Code);
        Installment.Find('-');

        PaymentDueDate := SalesInvoiceHeader."Document Date";
        repeat
            PaymentDueDate := CalcDate('<' + Installment."Gap between Installments" + '>', PaymentDueDate);

            Assert.AreEqual(PaymentDueDate, CarteraDoc."Due Date", '');
            Assert.AreEqual(CarteraDoc."Document Type"::Bill, CarteraDoc."Document Type", '');
            Assert.AreEqual(Round(SalesInvoiceHeader.Amount * Installment."% of Total" / 100), CarteraDoc."Remaining Amount", '');

            Installment.Next();
        until CarteraDoc.Next() = 0;
    end;

    local procedure VerifyRedraw(InvoiceNo: Code[20]; BillGroup: Record "Bill Group"; RedrawAmtToReduce: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        TotalChargedAmount: Decimal;
    begin
        VerifyRedrawInClosedCarteraDoc(InvoiceNo);

        BankAccountLedgerEntry.SetRange("Bank Account No.", BillGroup."Bank Account No.");
        BankAccountLedgerEntry.FindSet();
        repeat
            TotalChargedAmount += BankAccountLedgerEntry.Amount;
        until BankAccountLedgerEntry.Next() = 0;

        Assert.AreEqual(RedrawAmtToReduce, TotalChargedAmount, '');
    end;

    local procedure VerifyBankRisk(InvoiceNo: Code[20]; Unposted: Boolean; Posted: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        UnpostedValue: Decimal;
        PostedValue: Decimal;
    begin
        LibraryReportDataset.LoadDataSetFile();
        SalesInvoiceHeader.Get(InvoiceNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        while LibraryReportDataset.GetNextRow() do begin
            if Unposted then
                UnpostedValue := SalesInvoiceHeader."Amount Including VAT";
            if Posted then
                PostedValue := SalesInvoiceHeader."Amount Including VAT";

            LibraryReportDataset.AssertCurrentRowValueEquals('NonPostedDiscAmt', UnpostedValue);
            LibraryReportDataset.AssertCurrentRowValueEquals('BankAcc__Posted_Receiv__Bills_Rmg__Amt__', PostedValue);
        end;
    end;

    local procedure VerifyRedrawInClosedCarteraDoc(InvoiceNo: Code[20])
    var
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
    begin
        FindClosedCarteraDocForInvoice(ClosedCarteraDoc, InvoiceNo);
        Assert.IsTrue(ClosedCarteraDoc.Redrawn, BillShouldBeMarkedAsRedrawnErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RedrawCarteraBillReqPageHandler(var RedrawReceivableBillsPage: TestRequestPage "Redraw Receivable Bills")
    var
        RedrawOptionVar: Variant;
        RedrawOption: Option;
    begin
        LibraryVariableStorage.Dequeue(RedrawOptionVar);
        RedrawOption := RedrawOptionVar;
        case RedrawOption of
            RedrawReqPageOption::update:
                begin
                    RedrawReceivableBillsPage.AuxJnlTemplateName.AssertEquals('');
                    RedrawReceivableBillsPage.AuxJnlBatchName.AssertEquals('');
                    RedrawReceivableBillsPage.AuxJnlTemplateName.SetValue(LibraryVariableStorage.DequeueText());
                    RedrawReceivableBillsPage.AuxJnlBatchName.SetValue(LibraryVariableStorage.DequeueText());
                    RedrawReceivableBillsPage.OK().Invoke(); // requires to save values
                end;
            RedrawReqPageOption::verify:
                begin
                    RedrawReceivableBillsPage.AuxJnlTemplateName.AssertEquals('');
                    RedrawReceivableBillsPage.AuxJnlBatchName.AssertEquals('');
                    RedrawReceivableBillsPage.Cancel().Invoke();
                end;
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankRiskSaveAsPDFHandler(var BankRisk: TestRequestPage "Bank - Risk")
    begin
        BankRisk.SaveAsPdf(FileManagement.ServerTempFileName('.pdf'));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NoticeAssignmentCreditsSaveAsPDFHandler(var NoticeAssignmentCredits: TestRequestPage "Notice Assignment Credits")
    begin
        NoticeAssignmentCredits.SaveAsPdf(FileManagement.ServerTempFileName('.pdf'));
    end;
}

