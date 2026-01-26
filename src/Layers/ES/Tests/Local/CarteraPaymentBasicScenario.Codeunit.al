codeunit 147500 "Cartera Payment Basic Scenario"
{
    // // [FEATURE] [Cartera] [Purchase]
    // Cartera Payments basic end to end scenario.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraCommon: Codeunit "Library - Cartera Common";
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        PaymentOrderNotPrintedQst: Label 'This %1 has not been printed. Do you want to continue?';
        PaymentOrderSuccessfullyPostedMsg: Label 'The %1 %2 was successfully posted.', Comment = '%1=Table,%2=Field';
        RecordNotFoundErr: Label '%1 was not found.';
        SettlementCompletedSuccessfullyMsg: Label '%1 documents totaling %2 have been settled.';
        SuccessfulBillRedrawMsg: Label '%1 bills have been redrawn.';
        LocalCurrencyCode: Code[10];
        PaymentMethodCodeModifyErr: Label 'For Cartera-based bills and invoices, you cannot change the Payment Method Code to this value.';
        CheckBillSituationOrderErr: Label '%1 cannot be applied because it is included in a payment order. To apply the document, remove it from the payment order and try again.', Comment = '%1 - document type and number';
        CheckBillSituationPostedOrderErr: Label '%1 cannot be applied because it is included in a posted payment order.', Comment = '%1 - document type and number';
        PostDocumentAppliedToBillInGroupErr: Label 'A grouped document cannot be settled from a journal.\Remove Document %1/1 from Group/Pmt. Order %2 and try again.';
        DocumentNoMustBeBlankErr: Label 'Document No. must be blank.';
        UnbalancedGLAccountErr: Label 'G/L Account %1 is not balanced', Comment = '%1 = G/L Account No.';

    [Test]
    [HandlerFunctions('CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageVerifyHandler')]
    [Scope('OnPrem')]
    procedure AnalysisOfPostedPaymentOrder()
    var
        BankAccount: Record "Bank Account";
        PaymentOrder: Record "Payment Order";
        PostedPaymentOrder: Record "Posted Payment Order";
        Vendor: Record Vendor;
        PostedPaymentOrdersAnalysisTestPage: TestPage "Post. Payment Orders Analysis";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode);

        // Exercise
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", DocumentNo);
        PostPaymentOrderLCY(PaymentOrder);

        PostedPaymentOrder.SetFilter("No.", PaymentOrder."No.");
        PostedPaymentOrder.FindFirst();

        PostedPaymentOrdersAnalysisTestPage.OpenEdit();
        PostedPaymentOrdersAnalysisTestPage.GotoRecord(PostedPaymentOrder);

        // Validate
        PostedPaymentOrdersAnalysisTestPage.NoHonored.AssertEquals(0);
        PostedPaymentOrdersAnalysisTestPage.NoOpen.AssertEquals(1);
        PostedPaymentOrdersAnalysisTestPage.HonoredAmt.AssertEquals(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCarteraDocumentLCY()
    var
        Vendor: Record Vendor;
        CarteraDoc: Record "Cartera Doc.";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);

        // Exercise
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // Verify
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Account No.", Vendor."No.");
        CarteraDoc.FindFirst();

        PurchInvHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchInvHeader.FindFirst();
        PurchInvHeader.CalcFields("Amount Including VAT");
        PurchInvHeader.TestField("Amount Including VAT", CarteraDoc."Remaining Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCarteraDocumentNonLCY()
    var
        Vendor: Record Vendor;
        CarteraDoc: Record "Cartera Doc.";
        PurchInvHeader: Record "Purch. Inv. Header";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(false, false, true);

        // Setup
        PrepareVendorRelatedRecords(Vendor, CurrencyCode);

        // Exercise
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // Verify
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Account No.", Vendor."No.");
        CarteraDoc.FindFirst();
        CarteraDoc.TestField("Currency Code", CurrencyCode);

        PurchInvHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchInvHeader.FindFirst();
        PurchInvHeader.CalcFields("Amount Including VAT");
        PurchInvHeader.TestField("Amount Including VAT", CarteraDoc."Remaining Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeModificationCreateBills()
    var
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        DocumentNo: Code[20];
        BillNo: Code[20];
    begin
        // [SCENARIO 384336] Payment Method is updated for Invoice Cartera Document
        Initialize();

        // [GIVEN] Vendor with Cartera Payment Method "P1" where Invoice to Cartera = Yes
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);

        // [GIVEN] Cartera Document is posted for the Vendor
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // [GIVEN] Cartera Payment Document "P2" with Invoice to Cartera = No
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, true, false);

        // [WHEN] Modify Payment Method Code to "P2"
        BillNo := UpdateVendLedgEntryPaymentCode(DocumentNo, Vendor."No.", PaymentMethod.Code, true);

        // [THEN] Cartera Document has Payment Method = "P2"
        VerifyCarteraDocPaymentMethod(DocumentNo, Vendor."No.", PaymentMethod.Code, BillNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeModification()
    var
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 384336] Payment Method is not updated for Invoice Cartera Document
        Initialize();

        // [GIVEN] Vendor with Cartera Payment Method "P1" where Invoice to Cartera = Yes
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);

        // [GIVEN] Cartera Document is posted for the Vendor
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // [GIVEN] Cartera Payment Method with Invoice to Cartera = Yes
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, false);

        // [WHEN] Modify Payment Method Code to "P2"
        asserterror UpdateVendLedgEntryPaymentCode(DocumentNo, Vendor."No.", PaymentMethod.Code, true);

        // [THEN] Error appears
        Assert.ExpectedError(PaymentMethodCodeModifyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtMethodCodeModificationInvoicesToCartera()
    var
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 384336] Payment Method is not updated for Invoice Cartera Document
        Initialize();

        // [GIVEN] Vendor with Cartera Payment Method "P1" where Create Bills = No
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, true);
        LibraryCarteraPayables.CreateCarteraVendor(Vendor, '', PaymentMethod.Code);

        // [GIVEN] Cartera Document is posted for the Vendor
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Cartera Payment Method "P2"
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, false);

        // [WHEN] Modify Payment Method Code to "P2".
        asserterror UpdateVendLedgEntryPaymentCode(DocumentNo, Vendor."No.", PaymentMethod.Code, false);

        // [THEN] Error apprears
        Assert.ExpectedError(PaymentMethodCodeModifyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtMethodCodeModificationInvoicesToCarteraInvoice()
    var
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 384336] Payment Method is updated for Invoice Cartera Document
        Initialize();

        // [GIVEN] Vendor with Cartera Payment Method "P1" where Create Bills = No
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, true);
        LibraryCarteraPayables.CreateCarteraVendor(Vendor, '', PaymentMethod.Code);

        // [GIVEN] Cartera Document is posted for the Vendor
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Cartera Payment Method "P2"
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, true);

        // [WHEN] Modify Payment Method Code to "P2"
        UpdateVendLedgEntryPaymentCode(DocumentNo, Vendor."No.", PaymentMethod.Code, false);

        // [THEN] Cartera Document has Payment Method = "P2"
        VerifyCarteraDocInvoicePaymentMethod(DocumentNo, Vendor."No.", PaymentMethod.Code);
    end;

    [Test]
    [HandlerFunctions('SettleDocsInPostedPOModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageVerifyHandler,VendorDuePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PayDifferentDocumentsToDifferentVendorsLCY()
    var
        BankAccount: Record "Bank Account";
        InvoicesToCarteraPaymentMethod: Record "Payment Method";
        PaymentOrder: Record "Payment Order";
        VendorRelatedToBill: Record Vendor;
        VendorRelatedToInvoice: Record Vendor;
        InvoiceDocumentNo: Code[20];
        BillDocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        PrepareVendorRelatedRecords(VendorRelatedToBill, LocalCurrencyCode);
        PrepareVendorRelatedRecords(VendorRelatedToInvoice, LocalCurrencyCode);

        LibraryCarteraPayables.CreateInvoiceToCarteraPaymentMethod(InvoicesToCarteraPaymentMethod);
        InvoiceDocumentNo :=
          LibraryCarteraPayables.CreateCarteraPayableDocumentWithPaymentMethod(
            VendorRelatedToInvoice."No.", InvoicesToCarteraPaymentMethod.Code);
        BillDocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(VendorRelatedToBill);

        // Exercise
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode);
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", InvoiceDocumentNo);
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", BillDocumentNo);

        // Validate
        CheckIfCarteraDocExists(BillDocumentNo, PaymentOrder."No.");
        CheckIfCarteraDocExists(InvoiceDocumentNo, PaymentOrder."No.");
        Commit();

        RunAndVerifyVendorDuePaymentsReport(BillDocumentNo, VendorRelatedToBill."No.");
        RunAndVerifyVendorDuePaymentsReport(InvoiceDocumentNo, VendorRelatedToInvoice."No.");

        PostPaymentOrderLCY(PaymentOrder);
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrder."No.", BillDocumentNo);
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrder."No.", InvoiceDocumentNo);

        LibraryCarteraPayables.CheckIfCarteraDocIsClosed(PaymentOrder."No.");
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,SettleDocsInPostedPOModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageVerifyHandler,VendorDuePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PayDifferentDocumentsToDifferentVendorsNonLCY()
    var
        BankAccount: Record "Bank Account";
        InvoicesToCarteraPaymentMethod: Record "Payment Method";
        PaymentOrder: Record "Payment Order";
        VendorRelatedToBill: Record Vendor;
        VendorRelatedToInvoice: Record Vendor;
        CurrencyCode: Code[10];
        BillDocumentNo: Code[20];
        InvoiceDocumentNo: Code[20];
        PaymentOrderNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(false, false, true);

        // Setup
        PrepareVendorRelatedRecords(VendorRelatedToBill, CurrencyCode);
        PrepareVendorRelatedRecords(VendorRelatedToInvoice, CurrencyCode);

        LibraryCarteraPayables.CreateInvoiceToCarteraPaymentMethod(InvoicesToCarteraPaymentMethod);
        InvoiceDocumentNo :=
          LibraryCarteraPayables.CreateCarteraPayableDocumentWithPaymentMethod(
            VendorRelatedToInvoice."No.", InvoicesToCarteraPaymentMethod.Code);
        BillDocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(VendorRelatedToBill);

        // Exercise
        LibraryCarteraPayables.CreateBankAccount(BankAccount, CurrencyCode);
        PaymentOrderNo := CreatePaymentOrder(CurrencyCode, BankAccount."No.");
        AddCarteraDocumentToPaymentOrder(PaymentOrderNo, InvoiceDocumentNo);
        AddCarteraDocumentToPaymentOrder(PaymentOrderNo, BillDocumentNo);

        // Validate
        CheckIfCarteraDocExists(BillDocumentNo, PaymentOrderNo);
        CheckIfCarteraDocExists(InvoiceDocumentNo, PaymentOrderNo);
        Commit();

        RunAndVerifyVendorDuePaymentsReport(BillDocumentNo, VendorRelatedToBill."No.");
        RunAndVerifyVendorDuePaymentsReport(InvoiceDocumentNo, VendorRelatedToInvoice."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentOrderNotPrintedQst, PaymentOrder.TableCaption()));
        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentOrderSuccessfullyPostedMsg, PaymentOrder.TableCaption(), PaymentOrderNo));
        PostPaymentOrderFromPage(PaymentOrderNo);

        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrderNo, BillDocumentNo);
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrderNo, InvoiceDocumentNo);

        LibraryCarteraPayables.CheckIfCarteraDocIsClosed(PaymentOrderNo);
    end;

    [Test]
    [HandlerFunctions('SettleDocsInPostedPOModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageVerifyHandler')]
    [Scope('OnPrem')]
    procedure PayDifferentDocumentsToTheSameVendor()
    var
        BankAccount: Record "Bank Account";
        InvoicesToCarteraPaymentMethod: Record "Payment Method";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        InvoiceDocumentNo: Code[20];
        BillDocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.CreateInvoiceToCarteraPaymentMethod(InvoicesToCarteraPaymentMethod);
        InvoiceDocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocumentWithPaymentMethod(
            Vendor."No.", InvoicesToCarteraPaymentMethod.Code);
        BillDocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // Exercise
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode);
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", InvoiceDocumentNo);
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", BillDocumentNo);

        // Validate
        CheckIfCarteraDocExists(BillDocumentNo, PaymentOrder."No.");
        CheckIfCarteraDocExists(InvoiceDocumentNo, PaymentOrder."No.");

        PostPaymentOrderLCY(PaymentOrder);
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrder."No.", BillDocumentNo);
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrder."No.", InvoiceDocumentNo);

        LibraryCarteraPayables.CheckIfCarteraDocIsClosed(PaymentOrder."No.");
    end;

    [Test]
    [HandlerFunctions('SettleDocsInPostedPOModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageVerifyHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentOrderToCarteraVendorEndToEndLCY()
    var
        BankAccount: Record "Bank Account";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // Exercise - Create a Payment Order
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode);
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", DocumentNo);

        // Exercise - Adjust Due Date
        AdjustDueDate(DocumentNo, PaymentOrder."No.");

        // Exercise - Post and Settle
        PostPaymentOrderLCY(PaymentOrder);
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrder."No.", DocumentNo);

        // Verify
        LibraryCarteraPayables.CheckIfCarteraDocIsClosed(PaymentOrder."No.");
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,SettleDocsInPostedPOModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageVerifyHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentOrderToCarteraVendorEndToEndNonLCY()
    var
        BankAccount: Record "Bank Account";
        ClosedPaymentOrder: Record "Closed Payment Order";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        PaymentOrderNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(false, false, true);

        // Setup
        PrepareVendorRelatedRecords(Vendor, CurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // Exercise - Create a Payment Order
        LibraryCarteraPayables.CreateBankAccount(BankAccount, CurrencyCode);
        PaymentOrderNo := CreatePaymentOrder(CurrencyCode, BankAccount."No.");
        AddCarteraDocumentToPaymentOrder(PaymentOrderNo, DocumentNo);

        // Exercise - Adjust Due Date
        AdjustDueDate(DocumentNo, PaymentOrderNo);

        // Exercise - Post and Settle
        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentOrderNotPrintedQst, PaymentOrder.TableCaption()));
        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentOrderSuccessfullyPostedMsg, PaymentOrder.TableCaption(), PaymentOrderNo));
        PostPaymentOrderFromPage(PaymentOrderNo);
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrderNo, DocumentNo);

        // Verify
        LibraryCarteraPayables.CheckIfCarteraDocIsClosed(PaymentOrderNo);

        // Cleanup
        ClosedPaymentOrder.Get(PaymentOrderNo);
        ClosedPaymentOrder.Delete(true);
    end;

    [Test]
    [HandlerFunctions('SettleDocsInPostedPOModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageVerifyHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentOrderToCarteraVendorEndToEndLCYFromList()
    var
        BankAccount: Record "Bank Account";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        ClosedPaymentOrder: Record "Closed Payment Order";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // Exercise - Create a Payment Order
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode);
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", DocumentNo);

        // Exercise - Adjust Due Date
        AdjustDueDate(DocumentNo, PaymentOrder."No.");

        // Exercise - Post and Settle
        PaymentOrder.Validate("Export Electronic Payment", true);
        PaymentOrder.Validate("Elect. Pmts Exported", true);
        PaymentOrder.Modify(true);
        Commit();

        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentOrderNotPrintedQst, PaymentOrder.TableCaption()));
        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentOrderSuccessfullyPostedMsg, PaymentOrder.TableCaption(), PaymentOrder."No."));

        PostPaymentOrderFromList(PaymentOrder."No.");
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrder."No.", DocumentNo);

        // Verify
        LibraryCarteraPayables.CheckIfCarteraDocIsClosed(PaymentOrder."No.");

        // Cleanup
        ClosedPaymentOrder.Get(PaymentOrder."No.");
        ClosedPaymentOrder.Delete(true);
    end;

    [Test]
    [HandlerFunctions('SettleDocsInPostedPOModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageVerifyHandler')]
    [Scope('OnPrem')]
    procedure TestRemovingTheDocumentFromPaymentOrder()
    var
        BankAccount: Record "Bank Account";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // Exercise - Create a Payment Order
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode);
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", DocumentNo);

        // Excercise
        RemoveCarteraDocumentFromPaymentOrder(PaymentOrder."No.");

        // Verify
        VerifyCarteraDocumentRemovedFromPaymentOrder(PaymentOrder."No.");

        // Verify - add the same row again and test that you can post
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", DocumentNo);

        // Exercise - Adjust Due Date
        AdjustDueDate(DocumentNo, PaymentOrder."No.");

        // Exercise - Post and Settle
        PostPaymentOrderLCY(PaymentOrder);
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrder."No.", DocumentNo);

        // Verify
        LibraryCarteraPayables.CheckIfCarteraDocIsClosed(PaymentOrder."No.");
    end;

    [Test]
    [HandlerFunctions('SettleDocsInPostedPOModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageVerifyHandler,RedrawPayableBillsPageHandler')]
    [Scope('OnPrem')]
    procedure RedrawBillFromClosedPaymentOrderLCY()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        ClosedPaymentOrder: Record "Closed Payment Order";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        ClosedPaymentOrderTestPage: TestPage "Closed Payment Orders";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // Exercise
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode);
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", DocumentNo);
        CarteraDoc.FindFirst();
        PostPaymentOrderLCY(PaymentOrder);
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrder."No.", DocumentNo);

        ClosedPaymentOrder.SetRange("No.", PaymentOrder."No.");
        ClosedPaymentOrder.FindFirst();

        ClosedPaymentOrderTestPage.OpenEdit();
        ClosedPaymentOrderTestPage.GotoRecord(ClosedPaymentOrder);

        LibraryVariableStorage.Enqueue(ClosedPaymentOrderTestPage.Docs."Due Date".AsDate());
        LibraryVariableStorage.Enqueue(StrSubstNo(SuccessfulBillRedrawMsg, 1));
        ClosedPaymentOrderTestPage.Docs.Redraw.Invoke();

        // Verify
        ClosedCarteraDoc.SetRange("Document No.", DocumentNo);
        ClosedCarteraDoc.FindFirst();
        ClosedCarteraDoc.TestField(Redrawn, true);

        VerifyBankLedgerEntriesAmountSumEqualsZero(PaymentOrder."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,SettleDocsInPostedPOModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageVerifyHandler,RedrawPayableBillsPageHandler')]
    [Scope('OnPrem')]
    procedure RedrawBillFromClosedPaymentOrderNonLCY()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        ClosedPaymentOrder: Record "Closed Payment Order";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        ClosedPaymentOrderTestPage: TestPage "Closed Payment Orders";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        PaymentOrderNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(false, false, true);

        // Setup
        PrepareVendorRelatedRecords(Vendor, CurrencyCode);
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // Exercise
        LibraryCarteraPayables.CreateBankAccount(BankAccount, CurrencyCode);
        PaymentOrderNo := CreatePaymentOrder(CurrencyCode, BankAccount."No.");
        AddCarteraDocumentToPaymentOrder(PaymentOrderNo, DocumentNo);
        CarteraDoc.FindFirst();

        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentOrderNotPrintedQst, PaymentOrder.TableCaption()));
        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentOrderSuccessfullyPostedMsg, PaymentOrder.TableCaption(), PaymentOrderNo));
        PostPaymentOrderFromPage(PaymentOrderNo);
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrderNo, DocumentNo);

        ClosedPaymentOrder.SetRange("No.", PaymentOrderNo);
        ClosedPaymentOrder.FindFirst();

        ClosedPaymentOrderTestPage.OpenEdit();
        ClosedPaymentOrderTestPage.GotoRecord(ClosedPaymentOrder);

        LibraryVariableStorage.Enqueue(ClosedPaymentOrderTestPage.Docs."Due Date".AsDate());
        LibraryVariableStorage.Enqueue(StrSubstNo(SuccessfulBillRedrawMsg, 1));
        ClosedPaymentOrderTestPage.Docs.Redraw.Invoke();

        // Verify
        ClosedCarteraDoc.SetRange("Document No.", DocumentNo);
        ClosedCarteraDoc.FindFirst();
        ClosedCarteraDoc.TestField(Redrawn, true);

        VerifyBankLedgerEntriesAmountSumEqualsZero(BankAccount."No.");
    end;

    [Test]
    [HandlerFunctions('SettleDocsInPostedPOModalPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandlerYes,MessageVerifyHandler,RedrawPayableBillsPageHandler')]
    [Scope('OnPrem')]
    procedure RedrawBillFromPostedPaymentOrder()
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        PaymentOrder: Record "Payment Order";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        PostedPaymentOrder: Record "Posted Payment Order";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        PostedPaymentOrderTestPage: TestPage "Posted Payment Orders";
        DocumentNo1: Code[20];
        DocumentNo2: Code[20];
        ExtDocNo: Code[35];
    begin
        // [SCENARIO] Redraw one Bill from Posted Payment Order
        Initialize();

        // [GIVEN] 2 Cartera Bills where 1st document has "External Document No." = "ExtNo1"
        PrepareVendorRelatedRecords(Vendor, LocalCurrencyCode);
        DocumentNo1 := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);
        DocumentNo2 := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo1);
        ExtDocNo := VendorLedgerEntry."External Document No.";

        // [GIVEN] Cartera Payment Order settled and posted for both bills
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, LocalCurrencyCode);
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", DocumentNo1);
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", DocumentNo2);

        CarteraDoc.FindFirst();
        PostPaymentOrderLCY(PaymentOrder);
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrder."No.", DocumentNo1);

        PostedCarteraDoc.SetFilter("Document No.", DocumentNo1);
        PostedCarteraDoc.FindFirst();

        PostedPaymentOrder.SetFilter("No.", PaymentOrder."No.");
        PostedPaymentOrder.FindFirst();

        PostedPaymentOrderTestPage.OpenEdit();
        PostedPaymentOrderTestPage.GotoRecord(PostedPaymentOrder);

        // [WHEN] Redraw 1st Cartera Bill
        PostedPaymentOrderTestPage.Docs.GotoRecord(PostedCarteraDoc);
        LibraryVariableStorage.Enqueue(PostedPaymentOrderTestPage.Docs."Due Date".AsDate());
        LibraryVariableStorage.Enqueue(StrSubstNo(SuccessfulBillRedrawMsg, 1));
        PostedPaymentOrderTestPage.Docs.Redraw.Invoke();

        // [THEN] Bank Ledger Entries balance is reversed to 0
        VerifyBankLedgerEntriesAmountSumEqualsZero(PaymentOrder."Bank Account No.");
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrder."No.", DocumentNo2);

        // [THEN] Payable Payable Doc has marked as Redrawn
        ClosedCarteraDoc.SetRange("Document No.", DocumentNo1);
        ClosedCarteraDoc.FindFirst();
        ClosedCarteraDoc.TestField(Redrawn, true);

        // [THEN] 1st Cartera Bill is opened and "External Document No." = "ExtNo1" (TFS 381929)
        VendorLedgerEntry.SetRange("Document Status", VendorLedgerEntry."Document Status"::Open);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Bill, DocumentNo1);
        VendorLedgerEntry.TestField("External Document No.", ExtDocNo);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentOrderPurchInvCurrencyFactorModified()
    var
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        Currency: Record Currency;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Payment Order] [Currency]
        // [SCENARIO 374792] Post Payment Order for Purch. Invoice with FCY and modified Currency Factor
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" defined for WORKDATE
        Currency.Get(LibraryCarteraCommon.CreateCarteraCurrency(false, false, true));

        // [GIVEN] Posted Purchase Invoice with Amount = 100 with Currency Factor = "Y" (> "X")
        PrepareVendorRelatedRecords(Vendor, Currency.Code);
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        PurchaseHeader.Validate(
          "Currency Factor", LibraryRandom.RandDecInDecimalRange(PurchaseHeader."Currency Factor", 100, 2));
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Payment Order for Posted Purchase Invoice
        CreatePaymentOrderAndAddDocument(PaymentOrder, Currency.Code, PurchaseHeader."Posting Date", DocumentNo);

        // [WHEN] Post Payment Order
        LibraryCarteraPayables.PostCarteraPaymentOrder(PaymentOrder);

        // [THEN] G/L Entry for Payment Order with Amount = 100 * "Y" exist
        VerifyPaymentOrderGLEntryExists(PaymentOrder."No.", Vendor."Vendor Posting Group", PaymentOrder."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentOrderPurchInvDiffDatesExchRates()
    var
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Payment Order] [Currency]
        // [SCENARIO 374792] Post Payment Order for Purch. Invoice with FCY and different Exch. Rates between Posting Date
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" defined for Date = "Date1"
        Currency.Get(LibraryCarteraCommon.CreateCarteraCurrency(false, false, true));

        // [GIVEN] Posted Purchase Invoice with Amount = 100 with Currency Factor = X
        PrepareVendorRelatedRecords(Vendor, Currency.Code);
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Currency Factor = "Y" for Date = "Date2"(Invoice Posting Date + 1)
        CreateExchangeRate(Currency.Code, PurchaseHeader."Posting Date", PurchaseHeader."Posting Date" + 1);

        // [GIVEN] Payment Order with Posting Date = "Date2" for Posted Purchase Invoice
        CreatePaymentOrderAndAddDocument(PaymentOrder, Currency.Code, PurchaseHeader."Posting Date" + 1, DocumentNo);

        // [WHEN] Post Payment Order
        LibraryCarteraPayables.PostCarteraPaymentOrder(PaymentOrder);

        // [THEN] G/L Entry with Amount = 100 * "X"
        VerifyPaymentOrderGLEntryExists(PaymentOrder."No.", Vendor."Vendor Posting Group", PaymentOrder."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentOrderGenJournalLineCurrencyFactorModified()
    var
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Payment Order] [Currency]
        // [SCENARIO 374792] Post Payment Order for Gen. Journal Line of "Bill" Type with FCY and modified Currency Factor
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" defined for WORKDATE
        Currency.Get(LibraryCarteraCommon.CreateCarteraCurrency(false, false, true));
        PrepareVendorRelatedRecords(Vendor, Currency.Code);

        // [GIVEN] Posted Gen. Journal Line with Amount = 100 with Currency Factor = "Y" (> "X")
        CreateCarteraJournalLine(GenJournalLine, Vendor."No.", Currency.Code);
        GenJournalLine.Validate(
          "Currency Factor", LibraryRandom.RandDecInDecimalRange(GenJournalLine."Currency Factor", 100, 2));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment Order for Posted Gen. Journal Line
        CreatePaymentOrderAndAddDocument(PaymentOrder, Currency.Code, GenJournalLine."Posting Date", GenJournalLine."Document No.");

        // [WHEN] Post Payment Order
        LibraryCarteraPayables.PostCarteraPaymentOrder(PaymentOrder);

        // [THEN] G/L Entry for Payment Order with Amount = 100 * "Y" exist
        VerifyPaymentOrderGLEntryExists(PaymentOrder."No.", Vendor."Vendor Posting Group", PaymentOrder."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentOrderGenJournaLineDiffDatesExchRates()
    var
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Payment Order] [Currency]
        // [SCENARIO 374792] Post Payment Order for Gen. Journal Line of "Bill" Type with FCY and different Exch. Rates between Posting Date
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" defined for Date = "Date1"
        Currency.Get(LibraryCarteraCommon.CreateCarteraCurrency(false, false, true));
        PrepareVendorRelatedRecords(Vendor, Currency.Code);

        // [GIVEN] Posted Gen. Journal Line with Amount = 100 with Currency Factor = "X"
        CreateCarteraJournalLine(GenJournalLine, Vendor."No.", Currency.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Currency Factor = "Y" for Date = "Date2"(Invoice Posting Date + 1)
        CreateExchangeRate(Currency.Code, GenJournalLine."Posting Date", GenJournalLine."Posting Date" + 1);

        // [GIVEN] Payment Order with Posting Date = "Date2" for Posted Gen. Journal Line
        CreatePaymentOrderAndAddDocument(PaymentOrder, Currency.Code, GenJournalLine."Posting Date" + 1, GenJournalLine."Document No.");

        // [WHEN] Post Payment Order
        LibraryCarteraPayables.PostCarteraPaymentOrder(PaymentOrder);

        // [THEN] G/L Entry with Amount = 100 * "X"
        VerifyPaymentOrderGLEntryExists(PaymentOrder."No.", Vendor."Vendor Posting Group", PaymentOrder."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandler,MessageHandler,SettleDocsInPostedPOModalPageHandler')]
    [Scope('OnPrem')]
    procedure SettleInvoiceAfterPaymentOrderSameRateAndExchRateAdjustment()
    var
        Vendor: Record Vendor;
        PaymentOrder: Record "Payment Order";
        CurrencyCode: Code[10];
        PostingDate: array[4] of Date;
        CurrencyExchRate: array[4] of Decimal;
        SettleAmount: Decimal;
        AmtInv: Decimal;
        AmtPay: Decimal;
        AmtBank: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates]
        // [SCENARIO 375918] Purchase Invoice, Payment Order, Adjust Exch.Rate, new Exch.Rate, Settle Invoice
        Initialize();

        // [GIVEN] Currency with Currency Factor on Date1 (1.0487), Date3 (1.223), Date4 (1.0788)
        CurrencyCode := CreateCurrencyForPaymentOrder();
        SetScenarioRatesDates(CurrencyExchRate, PostingDate);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[1], CurrencyExchRate[1], CurrencyExchRate[1]);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[3], CurrencyExchRate[3], CurrencyExchRate[3]);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[4], CurrencyExchRate[4], CurrencyExchRate[4]);

        // [GIVEN] Payment Order on Date2 < PostingDate < Date3 for posted Purchase Invoice on Date1 with Amount = 5000.00
        CreateAndPostPaymentOrderFromInvoice(Vendor, PaymentOrder, SettleAmount, CurrencyCode, PostingDate[1], PostingDate[2] + 1);

        // [GIVEN] Run Adjust Exchange Rates on Date3
        RunExchRateAdjustment(CurrencyCode, PostingDate[3]);
        Commit();

        // [WHEN] Run TotalSettlement on Date4
        RunSettleDocInPostedPO(PaymentOrder."No.", PostingDate[4]);

        // [THEN] 'Realized Gain Acc.' in Payment G/L Entry = -133.03 (5000/1.0788 - 5000/1.0487)
        // [THEN] 'Invoices in  Pmt. Ord. Acc.' in Payment G/L Entry = 4088.31 (5000/1.223)
        // [THEN] Bank's 'G/L Account No.' in Payment G/L Entry = -4634.78 (-5000/1.0788)
        AmtInv := Round(SettleAmount / CurrencyExchRate[1]);
        AmtPay := Round(SettleAmount / CurrencyExchRate[1]);
        AmtBank := Round(SettleAmount / CurrencyExchRate[4]);
        VerifyPostedRealizedGainOnPayment(PaymentOrder."No.", CurrencyCode, AmtBank - AmtInv);
        VerifySettleGLEntries(
          PaymentOrder."No.", Vendor."Vendor Posting Group", PaymentOrder."Bank Account No.", AmtPay, -AmtBank);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandler,MessageHandler,SettleDocsInPostedPOModalPageHandler')]
    [Scope('OnPrem')]
    procedure SettleInvoiceAfterPaymentOrderSameRateAndTwoExchRateAdjustments()
    var
        Vendor: Record Vendor;
        PaymentOrder: Record "Payment Order";
        CurrencyCode: Code[10];
        PostingDate: array[4] of Date;
        CurrencyExchRate: array[4] of Decimal;
        SettleAmount: Decimal;
        AmtInv: Decimal;
        AmtBank: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates]
        // [SCENARIO 375918] Purchase Invoice, Payment Order, Adjust Exch.Rate, Adjust Exch.Rate, Settle Invoice
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" on Date1 (1.0487), Date3 (1.223), Date4 (1.0788)
        CurrencyCode := CreateCurrencyForPaymentOrder();
        SetScenarioRatesDates(CurrencyExchRate, PostingDate);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[1], CurrencyExchRate[1], CurrencyExchRate[1]);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[3], CurrencyExchRate[3], CurrencyExchRate[3]);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[4], CurrencyExchRate[4], CurrencyExchRate[4]);

        // [GIVEN] Payment Order on Date2 < PostingDate < Date3 for posted Purchase Invoice on Date1 with Amount = 5000.00
        CreateAndPostPaymentOrderFromInvoice(Vendor, PaymentOrder, SettleAmount, CurrencyCode, PostingDate[1], PostingDate[2] + 1);

        // [GIVEN] Run Adjust Exchange Rates twice: on Date3 and Date4
        RunExchRateAdjustment(CurrencyCode, PostingDate[3]);
        RunExchRateAdjustment(CurrencyCode, PostingDate[4]);
        Commit();

        // [WHEN] Run TotalSettlement on Date4
        RunSettleDocInPostedPO(PaymentOrder."No.", PostingDate[4]);

        // [THEN] 'Realized Gain Acc.' in Payment G/L Entry = -133.03 (5000/1.0788 - 5000/1.0487)
        // [THEN] 'Invoices in  Pmt. Ord. Acc.' in Payment G/L Entry = 4634.78 (5000/1.0788)
        // [THEN] Bank's 'G/L Account No.' in Payment G/L Entry = -4634.78 (-5000/1.0788)
        AmtInv := Round(SettleAmount / CurrencyExchRate[1]);
        AmtBank := Round(SettleAmount / CurrencyExchRate[4]);
        VerifyPostedRealizedGainOnPayment(PaymentOrder."No.", CurrencyCode, AmtBank - AmtInv);
        VerifySettleGLEntries(
          PaymentOrder."No.", Vendor."Vendor Posting Group", PaymentOrder."Bank Account No.", AmtInv, -AmtBank);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandler,MessageHandler,SettleDocsInPostedPOModalPageHandler')]
    [Scope('OnPrem')]
    procedure SettleInvoiceAfterPaymentOrderDiffRateAndExchRateAdjustment()
    var
        Vendor: Record Vendor;
        PaymentOrder: Record "Payment Order";
        CurrencyCode: Code[10];
        PostingDate: array[4] of Date;
        CurrencyExchRate: array[4] of Decimal;
        SettleAmount: Decimal;
        AmtInv: Decimal;
        AmtPay: Decimal;
        AmtBank: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates]
        // [SCENARIO 375918] Purchase Invoice, new Exch.Rate, Payment Order, Adjust Exch.Rate, new Exch.Rate, Settle Invoice
        Initialize();

        // [GIVEN] Currency with Currency Factor on Date1 (1.0487), Date2 (1.112), Date3 (1.223), Date4 (1.0788)
        CreateCurrencyWithExchRates(CurrencyCode, PostingDate, CurrencyExchRate);

        // [GIVEN] Payment Order on Date2 < PostingDate < Date3 for posted Purchase Invoice on Date1 with Amount = 5000.00
        CreateAndPostPaymentOrderFromInvoice(Vendor, PaymentOrder, SettleAmount, CurrencyCode, PostingDate[1], PostingDate[2] + 1);

        // [GIVEN] Run Adjust Exchange Rates on Date3
        RunExchRateAdjustment(CurrencyCode, PostingDate[3]);
        Commit();

        // [WHEN] Run TotalSettlement on Date4
        RunSettleDocInPostedPO(PaymentOrder."No.", PostingDate[4]);

        // [THEN] 'Realized Gain Acc.' in Payment G/L Entry = -133.03 (5000/1.0788 - 5000/1.0487)
        // [THEN] 'Invoices in  Pmt. Ord. Acc.' in Payment G/L Entry = 4634.78 (5000/1.0788)
        // [THEN] Bank's 'G/L Account No.' in Payment G/L Entry = -4634.78 (-5000/1.0788)
        AmtInv := Round(SettleAmount / CurrencyExchRate[1]);
        AmtPay := Round(SettleAmount / CurrencyExchRate[1]);
        AmtBank := Round(SettleAmount / CurrencyExchRate[4]);
        VerifyPostedRealizedGainOnPayment(PaymentOrder."No.", CurrencyCode, AmtBank - AmtInv);
        VerifySettleGLEntries(
          PaymentOrder."No.", Vendor."Vendor Posting Group", PaymentOrder."Bank Account No.", AmtPay, -AmtBank);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandler,MessageHandler,SettleDocsInPostedPOModalPageHandler')]
    [Scope('OnPrem')]
    procedure SettleInvoiceAfterPaymentOrderDiffRateAndTwoExchRateAdjustments()
    var
        Vendor: Record Vendor;
        PaymentOrder: Record "Payment Order";
        CurrencyCode: Code[10];
        PostingDate: array[4] of Date;
        CurrencyExchRate: array[4] of Decimal;
        SettleAmount: Decimal;
        AmtInv: Decimal;
        AmtPay: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates]
        // [SCENARIO 375918] Purchase Invoice, new Exch.Rate, Payment Order, Adjust Exch.Rate, Adjust Exch.Rate, Settle Invoice
        Initialize();

        // [GIVEN] Currency with Currency Factor on Date1 (1.0487), Date2 (1.112), Date3 (1.223), Date4 (1.0788)
        CreateCurrencyWithExchRates(CurrencyCode, PostingDate, CurrencyExchRate);

        // [GIVEN] Payment Order on Date2 < PostingDate < Date3 for posted Purchase Invoice on Date1 with Amount = 5000.00
        CreateAndPostPaymentOrderFromInvoice(Vendor, PaymentOrder, SettleAmount, CurrencyCode, PostingDate[1], PostingDate[2] + 1);

        // [GIVEN] Run Adjust Exchange Rates twice: on Date3 and Date4
        RunExchRateAdjustment(CurrencyCode, PostingDate[3]);
        RunExchRateAdjustment(CurrencyCode, PostingDate[4]);
        Commit();

        // [WHEN] Run TotalSettlement on Date4
        RunSettleDocInPostedPO(PaymentOrder."No.", PostingDate[4]);

        // [THEN] 'Realized Gain Acc.' in Payment G/L Entry = -679.50 (5000/1.223 - 5000/1.0487)
        // [THEN] 'Invoices in  Pmt. Ord. Acc.' in Payment G/L Entry = 4088.31 (5000/1.223)
        // [THEN] Bank's 'G/L Account No.' in Payment G/L Entry = -4088.31 (-5000/1.223)
        AmtInv := Round(SettleAmount / CurrencyExchRate[1]);
        AmtPay := Round(SettleAmount / CurrencyExchRate[4]);
        VerifyPostedRealizedGainOnPayment(PaymentOrder."No.", CurrencyCode, AmtPay - AmtInv);
        VerifySettleGLEntries(
          PaymentOrder."No.", Vendor."Vendor Posting Group", PaymentOrder."Bank Account No.", AmtInv, -AmtPay);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandler,MessageHandler,SettleDocsInPostedPOModalPageHandler')]
    [Scope('OnPrem')]
    procedure SettleInvoiceAfterPaymentOrderDiffRateAndExchangeRateAdjustment()
    var
        Vendor: Record Vendor;
        PaymentOrder: Record "Payment Order";
        CurrencyCode: Code[10];
        PostingDate: array[4] of Date;
        CurrencyExchRate: array[4] of Decimal;
        SettleAmount: Decimal;
        AmtInv: Decimal;
        AmtPay: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates]
        // [SCENARIO 375918] Purchase Invoice, new Exch.Rate, Payment Order, Adjust Exch.Rate, Settle Invoice
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" on Date1 (1.0487), Date2 (1.112), Date3 (1.223)
        CurrencyCode := CreateCurrencyForPaymentOrder();
        SetScenarioRatesDates(CurrencyExchRate, PostingDate);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[1], CurrencyExchRate[1], CurrencyExchRate[1]);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[2], CurrencyExchRate[2], CurrencyExchRate[2]);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[3], CurrencyExchRate[3], CurrencyExchRate[3]);

        // [GIVEN] Payment Order on Date2 < PostingDate < Date3 for posted Purchase Invoice on Date1 with Amount = 5000.00
        CreateAndPostPaymentOrderFromInvoice(Vendor, PaymentOrder, SettleAmount, CurrencyCode, PostingDate[1], PostingDate[2] + 1);

        // [GIVEN] Run Adjust Exchange Rates on Date3
        RunExchRateAdjustment(CurrencyCode, PostingDate[3]);
        Commit();

        // [WHEN] Run TotalSettlement on Date4
        RunSettleDocInPostedPO(PaymentOrder."No.", PostingDate[4]);

        // [THEN] 'Realized Gain Acc.' in Payment G/L Entry = -679.50 (5000/1.223 - 5000/1.0487)
        // [THEN] 'Invoices in  Pmt. Ord. Acc.' in Payment G/L Entry = 4088.31 (5000/1.223)
        // [THEN] Bank's 'G/L Account No.' in Payment G/L Entry = -4088.31 (-5000/1.223)
        AmtInv := Round(SettleAmount / CurrencyExchRate[1]);
        AmtPay := Round(SettleAmount / CurrencyExchRate[3]);
        VerifyPostedRealizedGainOnPayment(PaymentOrder."No.", CurrencyCode, AmtPay - AmtInv);
        VerifySettleGLEntries(
          PaymentOrder."No.", Vendor."Vendor Posting Group", PaymentOrder."Bank Account No.", AmtInv, -AmtPay);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandler,MessageHandler,SettleDocsInPostedPOModalPageHandler')]
    [Scope('OnPrem')]
    procedure SettleInvoiceAfterAdjustmentAndPaymentOrderAndTwoExchRateAdjustments()
    var
        Vendor: Record Vendor;
        PaymentOrder: Record "Payment Order";
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        PostingDate: array[4] of Date;
        CurrencyExchRate: array[4] of Decimal;
        SettleAmount: Decimal;
        AmtInv: Decimal;
        AmtPay: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates]
        // [SCENARIO 375918] Purchase Invoice, Adjust Exch.Rate, Payment Order, Adjust Exch.Rate, Adjust Exch.Rate, Settle Invoice
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" on Date1 (1.0487), Date2 (1.112), Date3 (1.223), Date4 (1.0788)
        CreateCurrencyWithExchRates(CurrencyCode, PostingDate, CurrencyExchRate);

        // [GIVEN] Posted Purchase Invoice on Date1 with Amount = 5000.00
        CreateAndPostInvoiceWOutVAT(Vendor, SettleAmount, InvoiceNo, PostingDate[1], CurrencyCode);

        // [GIVEN] Run Adjust Exchange Rates on Date2
        RunExchRateAdjustment(CurrencyCode, PostingDate[2]);

        // [GIVEN] Create Payment Order on Date2 < PostingDate < Date3
        CreateAndPostPaymentOrder(PaymentOrder, CurrencyCode, PostingDate[2] + 1, InvoiceNo);

        // [GIVEN] Run Adjust Exchange Rates twice: on Date3 and Date4
        RunExchRateAdjustment(CurrencyCode, PostingDate[3]);
        RunExchRateAdjustment(CurrencyCode, PostingDate[4]);
        Commit();

        // [WHEN] Run TotalSettlement on Date4
        RunSettleDocInPostedPO(PaymentOrder."No.", PostingDate[4]);

        // [THEN] 'Realized Gain Acc.' in Payment G/L Entry = -133.03 (5000/1.0788 - 5000/1.0487)
        // [THEN] 'Invoices in  Pmt. Ord. Acc.' in Payment G/L Entry = 4634.78 (5000/1.0788)
        // [THEN] Bank's 'G/L Account No.' in Payment G/L Entry = -4634.78 (-5000/1.0788)
        AmtInv := Round(SettleAmount / CurrencyExchRate[1]);
        AmtPay := Round(SettleAmount / CurrencyExchRate[4]);
        VerifyPostedRealizedGainOnPayment(PaymentOrder."No.", CurrencyCode, AmtPay - AmtInv);
        VerifySettleGLEntries(
          PaymentOrder."No.", Vendor."Vendor Posting Group", PaymentOrder."Bank Account No.", AmtInv, -AmtPay);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,CarteraDocumentsActionModalPageHandler,SettleDocsInPostedPOModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementOfPostedPmtOrderWhenPurchInvWithLatestDateAndDiffRates()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLEntry: Record "G/L Entry";
        POPostAndPrint: Codeunit "BG/PO-Post and Print";
        DocumentNo: Code[20];
        PaymentPostingDate: Date;
        PaymentExchRate: Decimal;
    begin
        // [FEATURE] [Payment Order] [Currency]
        // [SCENARIO 380643] Total Settlement of Posted Payment Order for Purch. Invoice with latest date and different currency factor
        Initialize();

        // [GIVEN] Currency with Exchange Rate defined for 10.01.16, 15.01.16
        Currency.Get(LibraryCarteraCommon.CreateCarteraCurrency(false, false, true));
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();
        PaymentPostingDate := CurrencyExchangeRate."Starting Date" - LibraryRandom.RandInt(5);
        PaymentExchRate := CurrencyExchangeRate."Exchange Rate Amount" / 2;
        LibraryERM.CreateExchangeRate(
          Currency.Code, PaymentPostingDate, PaymentExchRate, PaymentExchRate);

        // [GIVEN] Posted Purchase Invoice on 15.01.16
        PrepareVendorRelatedRecords(Vendor, Currency.Code);
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Posted Payment Order for Posted Purchase Invoice on 10.01.16
        CreatePaymentOrderAndAddDocument(PaymentOrder, Currency.Code, PaymentPostingDate, DocumentNo);
        POPostAndPrint.PayablePostOnly(PaymentOrder);

        // [WHEN] Run Total Settlement on 10.01.16
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrder."No.", DocumentNo);

        // [THEN] G/L Entry for Payment Order is created
        VerifyPaymentOrderGLEntryExists(PaymentOrder."No.", Vendor."Vendor Posting Group", PaymentOrder."Amount (LCY)");
        // [THEN] G/L Entry for "Realized Losses Acc." has "Posting Date" of Payment Order 10.01.16
        FindGLEntryByDocNoGLAccNo(GLEntry, PaymentOrder."No.", Currency."Realized Losses Acc.");
        Assert.RecordCount(GLEntry, 1);
        GLEntry.TestField("Posting Date", PaymentOrder."Posting Date");

        // [THEN] Two G/L Entry posted with G/L Account "Bill in Payment Order" for total settlement (one for Payment Order, one for currency exchange difference)
        // TFS 381601: "Bill in Payment Order" G/L Account used when settle Posted Payment Order with difference currency exchange rates
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        FindGLEntryByDocNoGLAccNo(GLEntry, PaymentOrder."No.", VendorPostingGroup."Bills in Payment Order Acc.");
        Assert.RecordCount(GLEntry, 2);
    end;

    [Test]
    [HandlerFunctions('CarteraDocumentsActionModalPageHandler,ConfirmHandler,MessageHandler,SettleDocsInPostedPOModalPageHandler')]
    [Scope('OnPrem')]
    procedure SettlePostedFCYPaymentOrderExchRateAdjustment()
    var
        PaymentOrder: Record "Payment Order";
        VendorPostingGroupCode: Code[20];
        PostingDate: array[3] of Date;
        AmtPay: Decimal;
    begin
        // [SCENARIO 294053] Settle posted payment order in FCY for different exchange rates
        Initialize();

        // [GIVEN] Dates: D1 = WorkDate(), D2 = WorkDate() + 1, D3 = WorkDate() + 2
        PostingDate[1] := WorkDate();
        PostingDate[2] := WorkDate() + 1;
        PostingDate[3] := WorkDate() + 2;
        // [GIVEN] Currency (CURR) with exchange rate on D1
        // [GIVEN] Posted Purchase Invoice (PPI) in CURR on D1
        // [GIVEN] Posted Payment Order (PPO) in CURR on D3
        CreatePostedPaymentOrderFCY(PaymentOrder, VendorPostingGroupCode, PostingDate);

        // [GIVEN] Dequeue the Inv value
        AmtPay := LibraryVariableStorage.DequeueDecimal();

        // [GIVEN] New exchange rate on D2
        // [GIVEN] Adjusted PPI on D2
        LibraryERM.CreateExchangeRate(PaymentOrder."Currency Code", PostingDate[2], 0.09, 0.09);
        RunExchRateAdjustment(PaymentOrder."Currency Code", PostingDate[2]);
        // [GIVEN] New exchange rate on D3
        LibraryERM.CreateExchangeRate(PaymentOrder."Currency Code", PostingDate[3], 0.08, 0.08);
        // [WHEN] Settle PPO on D3
        LibraryVariableStorage.Enqueue(PostingDate[3]);
        Commit();
        SettlePostedPaymentOrder(PaymentOrder."No.");
        // [THEN] PPO is settled
        VerifySettleGLEntries(
          PaymentOrder."No.", VendorPostingGroupCode, PaymentOrder."Bank Account No.",
          Round(AmtPay), -12500);
    end;

    [Test]
    [HandlerFunctions('PaymentOrderListingRequestPageHandler')]
    procedure PrintReportPaymentOrderListingAsPDF()
    var
        PaymentOrderListing: Report "Payment Order Listing";
        PDFFileName: Text;
    begin
        Initialize();
        // [WHEN] Run report 'Payment Order Listing'
        PaymentOrderListing.RunModal();

        // [THEN] Report is printed as PDF
        PDFFileName := LibraryVariableStorage.DequeueText();
        Assert.IsTrue(File.Exists(PDFFileName), 'PDF file does not exist');
    end;

    [Test]
    procedure CheckBillSituation_UT_OpenPaymentOrder()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 363341] TAB 25 "Vendor Ledger Entry".CheckBillSituation() throws an error in case of
        // [SCENARIO 363341] existing open cartera document (payment order) related to current ledger entry
        MockVendLedgEntry(VendorLedgerEntry);
        MockCarteraDoc("Cartera Document Type"::Payable, VendorLedgerEntry."Entry No.", LibraryUtility.GenerateGUID());

        asserterror VendorLedgerEntry.CheckBillSituation();

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CheckBillSituationOrderErr, VendorLedgerEntry.Description));
    end;

    [Test]
    procedure CheckBillSituation_UT_PostedPaymentOrder()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 363341] TAB 25 "Vendor Ledger Entry".CheckBillSituation() throws an error in case of
        // [SCENARIO 363341] existing posted cartera document (posted payment order) related to current ledger entry
        MockVendLedgEntry(VendorLedgerEntry);
        MockPostedCarteraDoc(PostedCarteraDoc.Type::Payable, VendorLedgerEntry."Entry No.", LibraryUtility.GenerateGUID());

        asserterror VendorLedgerEntry.CheckBillSituation();

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CheckBillSituationPostedOrderErr, VendorLedgerEntry.Description));
    end;

    [Test]
    [HandlerFunctions('CarteraDocumentsModalHandler')]
    procedure InsertCarteraDocForAppliedVendorEntryErrors()
    var
        Vendor: Record Vendor;
        GenJournalTemplate: Record "Gen. Journal Template";
        CarteraDoc: Record "Cartera Doc.";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentOrders: TestPage "Payment Orders";
        DocumentNo: Code[20];
    begin
        Initialize();
        CarteraDoc.DeleteAll();
        // [GIVEN] Posted purchase invoice with Cartera Doc created
        PrepareVendorRelatedRecords(Vendor, '');
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);
        // [GIVEN] A Gen. Journal Line
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", 0);
        // [GIVEN] The line is set it's Applies-to Doc. No
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify();
        // [WHEN] Attempting toinsert a PaymentOrder line
        PaymentOrders.OpenNew();
        LibraryVariableStorage.Enqueue(DocumentNo);
        // [THEN] It should fail
        Assert.IsFalse(TryToInsertPaymentOrder(PaymentOrders), 'Inserting the applied line should fail');
    end;

    [Test]
    procedure CrMemoTryApplyInvoiceAlreadyIncludedIntoPaymentOrder()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PaymentOrder: Record "Payment Order";
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 363341] An error occurs trying apply the invoice already included into payment order
        Initialize();

        // [GIVEN] Posted purchase invocie "X" with automatically created bill
        PrepareVendorRelatedRecords(Vendor, '');
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);
        // [GIVEN] Payment order with added document "X"
        CreatePaymentOrderAndAddToCarteraDocument(PaymentOrder, CarteraDoc, Vendor."No.", DocumentNo);
        // [GIVEN] Purchase credit memo
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");

        // [WHEN] Try validate purchase credit memo "Applies-to Doc. No." = "X"
        asserterror PurchaseHeader.Validate("Applies-to Doc. No.", DocumentNo);

        // [THEN] An error occurs: "Bill X cannot be applied, since it is included in a payment order. Remove it from its payment order and try again."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CheckBillSituationOrderErr, CarteraDoc.Description));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure CrMemoTryApplyInvoiceAlreadyIncludedIntoPostedPaymentOrder()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PaymentOrder: Record "Payment Order";
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 363341] An error occurs trying apply the invoice already included into posted payment order
        Initialize();

        // [GIVEN] Posted purchase invocie "X" with automatically created bill
        PrepareVendorRelatedRecords(Vendor, '');
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);
        // [GIVEN] Posted payment order with added document "X"
        CreatePaymentOrderAndAddToCarteraDocument(PaymentOrder, CarteraDoc, Vendor."No.", DocumentNo);
        PostPaymentOrderLCY(PaymentOrder);
        // [GIVEN] Purchase credit memo
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");

        // [WHEN] Try validate purchase credit memo "Applies-to Doc. No." = "X"
        asserterror PurchaseHeader.Validate("Applies-to Doc. No.", DocumentNo);

        // [THEN] An error occurs: "Bill X cannot be applied since it is included in a posted payment order."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CheckBillSituationPostedOrderErr, CarteraDoc.Description));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCrMemoAppliedToInvoiceIncludedintoPaymentOrder()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PaymentOrder: Record "Payment Order";
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 367139] An error occurs trying to posted credit memo applied to the bill already included into payment order
        Initialize();

        // [GIVEN] Posted purchase invoice with automatically created bill
        PrepareVendorRelatedRecords(Vendor, '');
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // [GIVEN] Purchase credit memo applied to posted bill
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        ApplyHeaderToBill(PurchaseHeader, DocumentNo, '1');

        // [GIVEN] Add bill to Payment order
        CreatePaymentOrderAndAddToCarteraDocument(PaymentOrder, CarteraDoc, Vendor."No.", DocumentNo);

        // [WHEN] Try to post the credit memo
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] An error occurs: "A grouped document cannot be settled from a journal."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(PostDocumentAppliedToBillInGroupErr, DocumentNo, PaymentOrder."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostCrMemAppliedToInvoiceIncludedintoPostedPaymentOrder()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PaymentOrder: Record "Payment Order";
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 367139] An error occurs trying to posted credit memo applied to the bill already included into posted payment order
        Initialize();

        // [GIVEN] Posted purchase invoice with automatically created bill
        PrepareVendorRelatedRecords(Vendor, '');
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // [GIVEN] Purchase credit memo applied to posted bill
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        ApplyHeaderToBill(PurchaseHeader, DocumentNo, '1');

        // [GIVEN] Add bill to Payment order and post it
        CreatePaymentOrderAndAddToCarteraDocument(PaymentOrder, CarteraDoc, Vendor."No.", DocumentNo);
        PostPaymentOrderLCY(PaymentOrder);

        // [WHEN] Try to post the credit memo
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] An error occurs: "A grouped document cannot be settled from a journal."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(PostDocumentAppliedToBillInGroupErr, DocumentNo, PaymentOrder."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtMethodCodeModificationInvToCarteraInvoiceDocSituationIsBlank()
    var
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 384336] Payment Method is updated for Invoice Cartera Document
        Initialize();

        // [GIVEN] Vendor with Cartera Payment Method "P1" where Create Bills = No
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, true);
        LibraryCarteraPayables.CreateCarteraVendor(Vendor, '', PaymentMethod.Code);

        // [GIVEN] Cartera Document is posted for the Vendor
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Vendor Ledger Entry with Document Situation = " "
        UpdateVendorLedgerEntryDocumentSituation(DocumentNo, Vendor."No.", VendorLedgerEntry."Document Situation"::" ");

        // [GIVEN] Cartera Payment Method "P2"
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, true, false);

        // [WHEN] Modify Payment Method Code to "P2".
        UpdateVendLedgEntryPaymentCode(DocumentNo, Vendor."No.", PaymentMethod.Code, false);

        // [THEN] Cartera Document has Payment Method = "P2"
        VerifyCarteraDocInvoicePaymentMethod(DocumentNo, Vendor."No.", PaymentMethod.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtMethodCodeModificationInvToCarteraInvoiceDocSituationIsNotBlank()
    var
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 384336] Payment Method is updated for Invoice Cartera Document
        Initialize();

        // [GIVEN] Vendor with Cartera Payment Method "P1" where Create Bills = No
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, true);
        LibraryCarteraPayables.CreateCarteraVendor(Vendor, '', PaymentMethod.Code);

        // [GIVEN] Cartera Document is posted for the Vendor
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Vendor Ledger Entry with Document Situation <> " "
        UpdateVendorLedgerEntryDocumentSituation(DocumentNo, Vendor."No.", VendorLedgerEntry."Document Situation"::Cartera);

        // [GIVEN] Cartera Payment Method "P2"
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, true, false);

        // [WHEN] Modify Payment Method Code to "P2"
        asserterror UpdateVendLedgEntryPaymentCode(DocumentNo, Vendor."No.", PaymentMethod.Code, false);

        // [THEN] Error apprears
        Assert.ExpectedError(PaymentMethodCodeModifyErr);
    end;

    [Test]
    [HandlerFunctions('CarteraDocumentsModalHandler')]
    [Scope('OnPrem')]
    procedure BlockedVendorCarteraDocsAreNotShownForSelectionInPaymentOrder()
    var
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        PaymentOrders: TestPage "Payment Orders";
    begin
        // [SCENARIO 489966] Cartera Docs having blocked Vendors are not shown for selection when stan runs Insert action from Payment Order.
        Initialize();

        // [GIVEN] Create a Vendor.
        PrepareVendorRelatedRecords(Vendor, '');

        // [GIVEN] Create a Cartera Doc.
        DocumentNo := LibraryCarteraPayables.CreateCarteraPayableDocument(Vendor);

        // [GIVEN] Validate Blocked in Vendor.
        Vendor.Validate(Blocked, Vendor.Blocked::All);
        Vendor.Modify(true);

        // [GIVEN] Create a Payment Order.
        PaymentOrders.OpenNew();
        LibraryVariableStorage.Enqueue(DocumentNo);

        // [WHEN] Run Insert action in Payment Order.
        TryToInsertPaymentOrder(PaymentOrders);

        // [VERIFY] No Cartera Doc is inserted in Payment Order.
        Assert.AreNotEqual(DocumentNo, Format(PaymentOrders.Docs."Document No."), DocumentNoMustBeBlankErr);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,CarteraDocumentsActionModalPageHandler,SettleDocsInPostedPOModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLShouldBalancedOnSettlingPaymentOrderWithExchangeRateDifference()
    var
        Currency: Record Currency;
        PaymentOrder: Record "Payment Order";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        POPostAndPrint: Codeunit "BG/PO-Post and Print";
        DocumentNo: Code[20];
        CurrencyExchRate: array[2] of Decimal;
        PostingDate: array[2] of Date;
        DocumentNoFilter: Text[100];
    begin
        // [SCENARIO 557342] On settling the Payment Order in foreign currency with different exchange rates, the amount posted in the G/L Account should be balanced.
        Initialize();

        // [GIVEN] Create a Currency with "Payment Order" enabled.
        Currency.Get(LibraryCarteraCommon.CreateCarteraCurrency(false, false, true));

        // [GIVEN] Set CurrencyExchRate and PostingDate.
        SetDateAndCurrencyExchangefactor(CurrencyExchRate, PostingDate);

        // [GIVEN] Set two exchange rate for the Currency.
        LibraryERM.CreateExchangeRate(Currency.Code, PostingDate[1], CurrencyExchRate[1], CurrencyExchRate[1]);
        LibraryERM.CreateExchangeRate(Currency.Code, PostingDate[2], CurrencyExchRate[2], CurrencyExchRate[2]);

        // [GIVEN] Create Vendor, Vendor Posting Group, Payment Method and Bank Account.
        CreateCarteraVendorAndRelatedRecord(Vendor, Currency.Code);

        // [GIVEN] Create and post a Purchase Invoice on "Posting Date" = PostingDate[1].
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create and post Payment Order on "Posting Date" = PostingDate[2].
        CreatePaymentOrderAndAddDocument(PaymentOrder, Currency.Code, PostingDate[2], DocumentNo);
        POPostAndPrint.PayablePostOnly(PaymentOrder);

        // [WHEN] Run the Total Settlement on "Posting Date" = PostingDate[2].
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrder."No.", DocumentNo);

        // [THEN] Verify the Amount posted in Payable Accounts are balanced.
        DocumentNoFilter := DocumentNo + '|' + PaymentOrder."No.";
        VerifyGLIsBalanced(Vendor."Vendor Posting Group", DocumentNoFilter);
    end;

    [Test]
    [HandlerFunctions('CarteraDocumentsActionModalPageHandler,ConfirmHandler,MessageHandler,SettleDocsInPostedPOModalPageHandler')]
    procedure CheckBalancedEntriesWhenSettlingInvoicesToCarteraViaPaymentOrderWithMultiplePostingGroups()
    var
        PaymentOrder: Record "Payment Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 566709] Check balanced entries when settling invoices to Cartera via payment order with multiple posting groups.
        Initialize();

        // [GIVEN] Allowed multiple vendor posting groups
        SetPurchAllowMultiplePostingGroups(true);

        // [GIVEN] Created Multiple Vendor Posting Groups.
        VendorPostingGroup2 := CreateMultipleVendorPostingGroups(VendorPostingGroup);

        // [GIVEN] Created Vendor for Allow Multiple Posting Groups
        CreateVendorWithAllowMultiplePostingGroups(Vendor, VendorPostingGroup.Code);

        // [GIVEN] Create Purchase invoices for a vendor with multiple posting groups
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Invoice, Vendor."No.", '', 1, '', 0D);

        // [GIVEN] Modify Vendor Posting Group on Purchase Invoice
        PurchaseHeader.Validate("Vendor Posting Group", VendorPostingGroup2.Code);
        PurchaseHeader.Modify(true);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);

        // [WHEN] Exercise: Posting purchase Document.
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create Payment Order.
        CreatePaymentOrder(PaymentOrder);

        // [GIVEN] Add the Posted invoice to Cartera & Post the Payment Order.
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", InvoiceNo);
        LibraryCarteraPayables.PostCarteraPaymentOrder(PaymentOrder);
        Commit();

        // [WHEN] Total settlement was invoke from from Posted Payment Order.
        TotalSettlementOnItemInPostedPaymentOrder(PaymentOrder."No.", InvoiceNo);
        LibraryVariableStorage.DequeueText();

        // [THEN] Verify "Invoices in  Pmt. Ord. Acc." GL was settled.
        VerifyGLAccInvoicesInPmtOrdAcc(VendorPostingGroup2.Code, PaymentOrder."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,CarteraDocumentsActionModalPageHandler,SettleDocsInPostedPOModalPageHandler2')]
    procedure CheckSettleMoreThanOneBillViaPaymentOrderWithMultiplePostingGroups()
    var
        GLEntry: Record "G/L Entry";
        PaymentMethod: Record "Payment Method";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        VendorPostingGroup: array[2] of Record "Vendor Posting Group";
        InvoiceNo: array[3] of Code[20];
    begin
        // [SCENARIO 575303] Verify that in the GL entry, the 'Bills in Payment Order Acc' account is taken from the alternative vendor posting group
        // When settlement more than one bill via a payment order involving multiple posting groups.
        Initialize();

        // [GIVEN] Allowed multiple vendor posting groups
        SetPurchAllowMultiplePostingGroups(true);

        // [GIVEN] Created Multiple Vendor Posting Groups.
        CreateVendorPostingGroupWithBillsPaymentOrderAcc(VendorPostingGroup[1]);
        CreateVendorPostingGroupWithBillsPaymentOrderAcc(VendorPostingGroup[2]);

        // [GIVEN] Set an alternative vendor posting group.
        LibraryPurchase.CreateAltVendorPostingGroup(VendorPostingGroup[1].Code, VendorPostingGroup[2].Code);
        LibraryPurchase.CreateAltVendorPostingGroup(VendorPostingGroup[2].Code, VendorPostingGroup[1].Code);

        // [GIVEN] Created Vendor for Allow Multiple Posting Groups
        CreateVendorWithAllowMultiplePostingGroups(Vendor, VendorPostingGroup[1].Code);

        // [GIVEN] Set Cartera Payment Method in Vendor.
        SetCarteraPaymentMethodInVendor(Vendor, PaymentMethod);

        // [GIVEN] Create Purchase invoices for a vendor and post.
        InvoiceNo[1] := CreateAndPostPurchaseInvoice(Vendor, '', Vendor."Payment Method Code");

        // [GIVEN] Create Purchase invoices for a vendor and post with alternative posting groups
        InvoiceNo[2] := CreateAndPostPurchaseInvoice(
            Vendor, VendorPostingGroup[2].Code, Vendor."Payment Method Code");
        InvoiceNo[3] := CreateAndPostPurchaseInvoice(Vendor, VendorPostingGroup[2].Code, '');

        // [GIVEN] Create Payment Order.
        CreatePaymentOrder(PaymentOrder);

        // [GIVEN] Add  cartera bill documnet in payment order.
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", InvoiceNo[1]);
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", InvoiceNo[2]);

        // [GIVEN] Post cartera payment order.
        LibraryCarteraPayables.PostCarteraPaymentOrder(PaymentOrder);

        // [WHEN] Total settlement on Posted Payment Order.
        TotalSettlementOnPaymentOrderFromPostedPaymentOrdersSelect(PaymentOrder."No.");

        // [THEN] Verify in the GL entry, the 'Bills in Payment Order Acc' account should be taken from the alternative vendor posting group.
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        FindGLEntryByDocNoGLAccNo(GLEntry, PaymentOrder."No.", VendorPostingGroup[2]."Bills in Payment Order Acc.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountListPageHandler,CarteraDocumentsActionModalPageHandler,ConfirmHandler,MessageHandler,SettleDocsInPostedPOModalPageHandler')]
    [Scope('OnPrem')]
    procedure SettleInvoiceAfterPaymentOrderWithDiffRateAndExchRateAdjustment()
    var
        Vendor: Record Vendor;
        PaymentOrder: Record "Payment Order";
        CurrencyCode: Code[10];
        PostingDate: array[4] of Date;
        CurrencyExchRate: array[4] of Decimal;
        SettleAmount: Decimal;
        AmtInv: Decimal;
        AmtPay: Decimal;
        AmtBank: Decimal;
    begin
        // [SCENARIO 573478] Adjust Exchange Rate work as expected in case of Posting/Settlement of a Payment Order in Currencies
        Initialize();

        // [GIVEN] Create Currency with Currency Factors
        CurrencyCode := CreateCurrencyForPaymentOrder();

        // [GIVEN] Set Exchange Rates and Posting Dates
        SetScenarioRatesDates(CurrencyExchRate, PostingDate);

        // [GIVEN] Create different Exchange Rates for the Currency
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[1], CurrencyExchRate[1], CurrencyExchRate[1]);
        //LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[3], CurrencyExchRate[3], CurrencyExchRate[3]);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[4], CurrencyExchRate[4], CurrencyExchRate[4]);

        // [GIVEN] Create Invoice and Payment Order, then post Payment Order 
        CreateAndPostPaymentOrderFromInvoice(Vendor, PaymentOrder, SettleAmount, CurrencyCode, PostingDate[1], PostingDate[2] + 1);

        // [GIVEN] Run Adjust Exchange Rates on Date3
        RunExchRateAdjustment(CurrencyCode, PostingDate[3]);
        Commit();

        // [WHEN] Run TotalSettlement on Date4
        RunSettleDocInPostedPO(PaymentOrder."No.", PostingDate[4]);

        // [THEN] Verify that the Payment Order is settled
        AmtInv := Round(SettleAmount / CurrencyExchRate[1]);
        AmtPay := Round(SettleAmount / CurrencyExchRate[1]);
        AmtBank := Round(SettleAmount / CurrencyExchRate[4]);

        // [THEN] Verify that the G/L Entries for Realized gain loss  created correctly
        VerifyPostedRealizedGainOnPayment(PaymentOrder."No.", CurrencyCode, AmtBank - AmtInv);

        // [THEN] Verify that the G/L Entries for Payment Order and Bank Account are created correctly
        VerifySettleGLEntries(PaymentOrder."No.", Vendor."Vendor Posting Group", PaymentOrder."Bank Account No.", AmtPay, -AmtBank);
    end;

    local procedure Initialize()
    begin
        LibraryReportDataset.Reset();
        LibraryVariableStorage.Clear();
        LocalCurrencyCode := '';
    end;

    local procedure CheckIfCarteraDocExists(DocumentNo: Code[20]; PaymentOrderNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", PaymentOrderNo);
        Assert.IsFalse(CarteraDoc.IsEmpty, StrSubstNo(RecordNotFoundErr, CarteraDoc.TableCaption()));
    end;

    local procedure FindGLEntryByDocNoGLAccNo(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure PostPaymentOrderLCY(var PaymentOrder: Record "Payment Order")
    begin
        PaymentOrder.Validate("Export Electronic Payment", true);
        PaymentOrder.Validate("Elect. Pmts Exported", true);
        PaymentOrder.Modify(true);
        Commit();

        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentOrderNotPrintedQst, PaymentOrder.TableCaption()));
        LibraryVariableStorage.Enqueue(StrSubstNo(PaymentOrderSuccessfullyPostedMsg, PaymentOrder.TableCaption(), PaymentOrder."No."));
        LibraryCarteraPayables.PostCarteraPaymentOrder(PaymentOrder);
    end;

    local procedure TotalSettlementOnItemInPostedPaymentOrder(PostedPaymentOrderNo: Code[20]; ItemNo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        PostedPaymentOrder: Record "Posted Payment Order";
        PostedPaymentOrderTestPage: TestPage "Posted Payment Orders";
    begin
        PostedPaymentOrder.Get(PostedPaymentOrderNo);

        PostedPaymentOrderTestPage.OpenEdit();
        PostedPaymentOrderTestPage.GotoRecord(PostedPaymentOrder);

        PostedCarteraDoc.SetFilter("Document No.", ItemNo);
        PostedCarteraDoc.FindFirst();

        PostedPaymentOrderTestPage.Docs.GotoRecord(PostedCarteraDoc);
        LibraryVariableStorage.Enqueue(PostedPaymentOrder."Posting Date");
        LibraryVariableStorage.Enqueue(
          StrSubstNo(SettlementCompletedSuccessfullyMsg, 1, PostedPaymentOrderTestPage.Docs."Remaining Amount".AsDecimal()));
        PostedPaymentOrderTestPage.Docs.TotalSettlement.Invoke();
    end;

    local procedure AddCarteraDocumentToPaymentOrder(PaymentOrderNo: Code[20]; DocumentNo: Code[20])
    var
        PaymentOrders: TestPage "Payment Orders";
    begin
        LibraryVariableStorage.Enqueue(DocumentNo); // for CarteraDocumentsActionModalPageHandler

        // Open the PaymentOrder page pointing to the created Payment Order record
        PaymentOrders.OpenEdit();
        PaymentOrders.GotoKey(PaymentOrderNo);

        // Insert a Payable Cartera Document using the Page Part 'Docs'
        PaymentOrders.Docs.Insert.Invoke();

        // Save the changes, as the cartera document has been added to the Payment Order
        PaymentOrders.OK().Invoke();
    end;

    local procedure ApplyHeaderToBill(var PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20]; BillNo: Code[20])
    begin
        PurchaseHeader.Validate("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::Bill);
        PurchaseHeader.Validate("Applies-to Doc. No.", DocumentNo);
        PurchaseHeader.Validate("Applies-to Bill No.", BillNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateVendLedgEntryPaymentCode(DocumentNo: Code[20]; VendorNo: Code[20]; PaymentMethodCode: Code[20]; IsBill: Boolean): Code[20]
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgerEntry.SetRange("Document No.", DocumentNo);
        VendLedgerEntry.SetRange("Vendor No.", VendorNo);
        if IsBill then
            VendLedgerEntry.SetFilter("Bill No.", '<>%1', '');
        VendLedgerEntry.FindFirst();
        VendLedgerEntry.Validate("Payment Method Code", PaymentMethodCode);
        VendLedgerEntry.Modify(true);
        exit(VendLedgerEntry."Bill No.");
    end;

    local procedure PostPaymentOrderFromPage(PaymentOrderNo: Code[20])
    var
        PaymentOrders: TestPage "Payment Orders";
    begin
        PaymentOrders.OpenEdit();
        PaymentOrders.GotoKey(PaymentOrderNo);
        PaymentOrders.Post.Invoke();
    end;

    local procedure PostPaymentOrderFromList(PaymentOrderNo: Code[20])
    var
        PaymentOrdersList: TestPage "Payment Orders List";
    begin
        PaymentOrdersList.OpenView();
        PaymentOrdersList.GotoKey(PaymentOrderNo);
        PaymentOrdersList.Post.Invoke();
    end;

    local procedure PrepareVendorRelatedRecords(var Vendor: Record Vendor; CurrencyCode: Code[10])
    begin
        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, CurrencyCode);
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, CurrencyCode);
    end;

    local procedure RemoveCarteraDocumentFromPaymentOrder(PaymentOrderNo: Code[20])
    var
        PaymentOrder: Record "Payment Order";
        PaymentOrdersTestPage: TestPage "Payment Orders";
    begin
        PaymentOrder.SetRange("No.", PaymentOrderNo);
        PaymentOrder.FindFirst();

        PaymentOrdersTestPage.OpenEdit();
        PaymentOrdersTestPage.GotoRecord(PaymentOrder);
        PaymentOrdersTestPage.Docs.Remove.Invoke();
        PaymentOrdersTestPage.OK().Invoke();
    end;

    local procedure VerifyBankLedgerEntriesAmountSumEqualsZero(BankAccountNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        TotalChargedAmount: Decimal;
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.FindSet();

        repeat
            TotalChargedAmount := TotalChargedAmount + BankAccountLedgerEntry.Amount;
        until BankAccountLedgerEntry.Next() = 0;

        Assert.AreEqual(
          0, TotalChargedAmount, 'Ledger entries in bank related to the post-close-redraw operations of the bill != 0.');
    end;

    local procedure VerifyCarteraDocPaymentMethod(DocumentNo: Code[20]; VendorNo: Code[20]; PaymentMethodCode: Code[20]; BillNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Account No.", VendorNo);
        CarteraDoc.SetRange("No.", BillNo);
        CarteraDoc.FindFirst();
        CarteraDoc.TestField("Payment Method Code", PaymentMethodCode);
    end;

    local procedure VerifyCarteraDocInvoicePaymentMethod(DocumentNo: Code[20]; VendorNo: Code[20]; PaymentMethodCode: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Account No.", VendorNo);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Invoice);
        CarteraDoc.FindFirst();
        CarteraDoc.TestField("Payment Method Code", PaymentMethodCode);
    end;

    local procedure VerifyCarteraDocumentRemovedFromPaymentOrder(BillGroupNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.Init();
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", BillGroupNo);
        Assert.RecordIsEmpty(CarteraDoc);
    end;

    local procedure VerifyPaymentOrderGLEntryExists(DocumentNo: Code[20]; VendorPostingGroupCode: Code[20]; VerifyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);

        FindGLEntryByDocNoGLAccNo(GLEntry, DocumentNo, VendorPostingGroup."Bills Account");
        Assert.AreEqual(VerifyAmount, GLEntry.Amount, GLEntry.FieldCaption(Amount));

        FindGLEntryByDocNoGLAccNo(GLEntry, DocumentNo, VendorPostingGroup."Bills in Payment Order Acc.");
        Assert.AreEqual(-VerifyAmount, GLEntry.Amount, GLEntry.FieldCaption(Amount));
    end;

    local procedure RunAndVerifyVendorDuePaymentsReport(DocumentNo: Code[20]; VendorNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorDuePayments: Report "Vendor - Due Payments";
        DueDate: Variant;
        RemainingAmount: Variant;
        VendorNoInReport: Variant;
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.FindFirst();

        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Due Date", CarteraDoc."Due Date");
        VendorLedgerEntry.FindFirst();

        VendorDuePayments.SetTableView(VendorLedgerEntry);
        VendorDuePayments.RunModal();
        Clear(VendorDuePayments);

        LibraryReportDataset.LoadDataSetFile();

        Assert.AreEqual(1, LibraryReportDataset.RowCount(), '');

        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.GetElementValueInCurrentRow('Vendor_Ledger_Entry__Vendor_No__', VendorNoInReport);
        Assert.AreEqual(VendorNoInReport, VendorNo, '');

        LibraryReportDataset.GetElementValueInCurrentRow('Vendor_Ledger_Entry__Remaining_Amount_', RemainingAmount);
        Assert.AreEqual(RemainingAmount, 0 - CarteraDoc."Remaining Amount", '');

        LibraryReportDataset.GetElementValueInCurrentRow('Vendor_Ledger_Entry__Due_Date_', DueDate);
        Assert.AreEqual(DueDate, Format(CarteraDoc."Due Date"), '');
    end;

    local procedure RunExchRateAdjustment(CurrencyCode: Code[10]; PostingDate: Date)
    begin
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, PostingDate, PostingDate);
    end;

    local procedure RunSettleDocInPostedPO(PaymentOrderNo: Code[20]; PostingDate: Date)
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        LibraryVariableStorage.Enqueue(PostingDate); // for SettleDocsInPostedPOModalPageHandler
        PostedCarteraDoc.SetRange("Bill Gr./Pmt. Order No.", PaymentOrderNo);
        PostedCarteraDoc.FindFirst();
        PostedCarteraDoc.SetRecFilter();
        REPORT.RunModal(REPORT::"Settle Docs. in Posted PO", true, false, PostedCarteraDoc);
    end;

    local procedure SetScenarioRatesDates(var ExchRate: array[4] of Decimal; var PostDate: array[4] of Date)
    var
        i: Integer;
    begin
        ExchRate[1] := 1.0487;
        ExchRate[2] := 1.112;
        ExchRate[3] := 1.223;
        ExchRate[4] := 1.0788;

        for i := 1 to ArrayLen(PostDate) do
            PostDate[i] := WorkDate() + (i - 1) * 2;
    end;

    local procedure CreateCarteraJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; CurrencyCode: Code[10])
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryCarteraPayables.CreateBankAccount(BankAccount, CurrencyCode);
        LibraryCarteraPayables.CreateCarteraJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Bill, GenJournalLine."Account Type"::Vendor,
          VendorNo, GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.", -LibraryRandom.RandInt(100));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Bill No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
    end;

    local procedure CreateExchangeRate(CurrencyCode: Code[10]; Date1: Date; Date2: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExchRateAdjust: Integer;
    begin
        LibraryERM.FindExchRate(CurrencyExchangeRate, CurrencyCode, Date1);
        ExchRateAdjust := LibraryRandom.RandInt(5);
        LibraryERM.CreateExchangeRate(
          CurrencyCode, Date2,
          CurrencyExchangeRate."Exchange Rate Amount" + ExchRateAdjust,
          CurrencyExchangeRate."Adjustment Exch. Rate Amount" + ExchRateAdjust);
    end;

    local procedure CreatePaymentOrder(CurrencyCode: Code[10]; BankAccountNo: Code[20]) PaymentOrderNo: Code[20]
    var
        PaymentOrders: TestPage "Payment Orders";
    begin
        PaymentOrders.OpenNew();

        LibraryVariableStorage.Enqueue(CurrencyCode);
        PaymentOrders."Currency Code".Activate();
        PaymentOrders."Currency Code".Lookup();

        LibraryVariableStorage.Enqueue(BankAccountNo);
        PaymentOrders."Bank Account No.".Activate();
        PaymentOrders."Bank Account No.".Lookup();

        PaymentOrderNo := PaymentOrders."No.".Value();

        PaymentOrders.OK().Invoke();
    end;

    local procedure CreatePaymentOrderAndAddDocument(var PaymentOrder: Record "Payment Order"; CurrencyCode: Code[10]; PostingDate: Date; DocumentNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryCarteraPayables.CreateBankAccount(BankAccount, CurrencyCode);
        PaymentOrder.Get(CreatePaymentOrder(CurrencyCode, BankAccount."No."));
        PaymentOrder.Validate("Posting Date", PostingDate);
        PaymentOrder.Modify(true);
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", DocumentNo);
        PaymentOrder.CalcFields("Amount (LCY)", Amount);
    end;

    local procedure CreateAndPostPaymentOrder(var PaymentOrder: Record "Payment Order"; CurrencyCode: Code[10]; PostingDate: Date; DocumentNo: Code[20])
    begin
        CreatePaymentOrderAndAddDocument(PaymentOrder, CurrencyCode, PostingDate, DocumentNo);
        LibraryCarteraPayables.PostCarteraPaymentOrder(PaymentOrder);
    end;

    local procedure CreateAndPostPaymentOrderFromInvoice(var Vendor: Record Vendor; var PaymentOrder: Record "Payment Order"; var SettleAmount: Decimal; CurrencyCode: Code[10]; InvoicePostingDate: Date; POPostingDate: Date)
    var
        InvoiceNo: Code[20];
    begin
        CreateAndPostInvoiceWOutVAT(Vendor, SettleAmount, InvoiceNo, InvoicePostingDate, CurrencyCode);
        CreateAndPostPaymentOrder(PaymentOrder, CurrencyCode, POPostingDate, InvoiceNo);
    end;

    local procedure CreateCurrencyForPaymentOrder(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        Currency.Validate("Unrealized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Unrealized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Invoice Rounding Precision", Currency."Amount Rounding Precision");
        Currency.Validate("Payment Orders", true);
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyWithExchRates(var CurrencyCode: Code[10]; var PostingDate: array[4] of Date; var CurrencyExchRate: array[4] of Decimal)
    var
        i: Integer;
    begin
        CurrencyCode := CreateCurrencyForPaymentOrder();
        SetScenarioRatesDates(CurrencyExchRate, PostingDate);
        for i := 1 to ArrayLen(PostingDate) do
            LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[i], CurrencyExchRate[i], CurrencyExchRate[i]);
    end;

    local procedure CreateAndPostInvoiceWOutVAT(var Vendor: Record Vendor; var SettleAmount: Decimal; var InvoiceNo: Code[20]; PostingDate: Date; CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccNo: Code[20];
    begin
        LibraryCarteraPayables.CreateCarteraVendorUseInvoicesToCarteraPayment(Vendor, CurrencyCode);
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Modify(true);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        GLAccNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Posting Date", PostingDate);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
        SettleAmount := PurchaseLine.Amount;
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePostedPaymentOrderFCY(var PaymentOrder: Record "Payment Order"; var VendorPostingGroupCode: Code[20]; PostingDate: array[3] of Date)
    var
        BankAccount: Record "Bank Account";
        PaymentMethod: Record "Payment Method";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(false, false, true);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[1], 0.1, 0.1);

        PrepareVendorRelatedRecords(Vendor, CurrencyCode);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        VendorPostingGroupCode := Vendor."Vendor Posting Group";
        PaymentMethod.Get(Vendor."Payment Method Code");
        PaymentMethod.Validate("Create Bills", false);
        PaymentMethod.Validate("Invoices to Cartera", true);
        PaymentMethod.Validate("Bill Type", PaymentMethod."Bill Type"::" ");
        PaymentMethod.Modify(true);

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "), 1);
        PurchaseLine.Validate("Direct Unit Cost", 1000);
        PurchaseLine.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, CurrencyCode);
        PaymentOrder.Validate("Posting Date", PostingDate[3]);
        PaymentOrder.Validate("Export Electronic Payment", false);
        PaymentOrder.Modify(true);
        AddCarteraDocumentToPaymentOrder(PaymentOrder."No.", DocumentNo);
        PaymentOrder.CalcFields("Amount (LCY)");
        LibraryVariableStorage.Enqueue(PaymentOrder."Amount (LCY)");
        LibraryCarteraPayables.PostCarteraPaymentOrder(PaymentOrder);
    end;

    local procedure CreatePaymentOrderAndAddToCarteraDocument(var PaymentOrder: Record "Payment Order"; var CarteraDoc: Record "Cartera Doc."; VendorNo: Code[20]; DocumentNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, '');
        LibraryCarteraPayables.AddPaymentOrderToCarteraDocument(CarteraDoc, DocumentNo, VendorNo, PaymentOrder."No.");
    end;

    local procedure MockVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FIELDNO("Entry No."));
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry.Description := LibraryUtility.GenerateGUID();
        VendorLedgerEntry.Insert();
    end;

    local procedure MockCarteraDoc(Type: Enum "Cartera Document Type"; EntryNo: Integer; BGPONo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.Type := Type;
        CarteraDoc."Entry No." := EntryNo;
        CarteraDoc."Bill Gr./Pmt. Order No." := BGPONo;
        CarteraDoc.Insert();
    end;

    local procedure MockPostedCarteraDoc(Type: Enum "Cartera Document Type"; EntryNo: Integer; BGPONo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        PostedCarteraDoc.Type := Type;
        PostedCarteraDoc."Entry No." := EntryNo;
        PostedCarteraDoc."Bill Gr./Pmt. Order No." := BGPONo;
        PostedCarteraDoc.Insert();
    end;

    local procedure AdjustDueDate(DocumentNo: Code[20]; PaymentOrderNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", PaymentOrderNo);
        CarteraDoc.FindFirst();
        CarteraDoc.Validate("Due Date", CalcDate('<1M>', WorkDate()));
        CarteraDoc.Modify(true);
    end;

    local procedure UpdateVendorLedgerEntryDocumentSituation(DocumentNo: Code[20]; VendorNo: Code[20]; DocumentSituation: Enum "ES Document Situation")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry."Document Situation" := DocumentSituation;
        VendorLedgerEntry.Modify();
    end;


    local procedure VerifyPostedRealizedGainOnPayment(DocumentNo: Code[20]; CurrencyCode: Code[10]; GainLossAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", DocumentNo);

        Currency.Get(CurrencyCode);
        GLEntry.SetRange("G/L Account No.", Currency."Realized Gains Acc.");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, GainLossAmt);
    end;

    local procedure VerifySettleGLEntries(DocumentNo: Code[20]; VendorPostingGroupCode: Code[20]; BankAccNo: Code[20]; PayAmt: Decimal; BankAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", DocumentNo);

        VendorPostingGroup.Get(VendorPostingGroupCode);
        VerifyGLAccAmountGLEntries(GLEntry, VendorPostingGroup."Invoices in  Pmt. Ord. Acc.", PayAmt);

        BankAccount.Get(BankAccNo);
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
        VerifyGLAccAmountGLEntries(GLEntry, BankAccountPostingGroup."G/L Account No.", BankAmt);
    end;

    local procedure VerifyGLAccAmountGLEntries(var GLEntry: Record "G/L Entry"; GlAccountNo: Code[20]; GLAmount: Decimal)
    begin
        GLEntry.SetRange("G/L Account No.", GlAccountNo);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, GLAmount);
    end;

    local procedure SettlePostedPaymentOrder(PaymentOrderNo: Code[20])
    var
        PostedPaymentOrder: Record "Posted Payment Order";
        PostedPaymentOrders: TestPage "Posted Payment Orders";
    begin
        PostedPaymentOrder.SetRange("No.", PaymentOrderNo);
        PostedPaymentOrder.FindFirst();
        PostedPaymentOrders.OpenEdit();
        PostedPaymentOrders.GotoRecord(PostedPaymentOrder);
        PostedPaymentOrders.Docs.TotalSettlement.Invoke();
    end;

    local procedure SetDateAndCurrencyExchangefactor(var ExchRate: array[2] of Decimal; var PostDate: array[2] of Date)
    begin
        ExchRate[1] := 1.0943;
        ExchRate[2] := 1.0958;
        PostDate[1] := WorkDate();
        PostDate[2] := CalcDate('<2M>', WorkDate());
    end;

    local procedure CreateCarteraVendorAndRelatedRecord(var Vendor: Record Vendor; CurrencyCode: Code[10])
    begin
        LibraryCarteraPayables.CreateCarteraVendorUseInvoicesToCarteraPayment(Vendor, CurrencyCode);
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, CurrencyCode);
    end;

    local procedure VerifyGLIsBalanced(VendorPostingGroupCode: Code[20]; DocumentNoFilter: Text[100])
    var
        GLEntry: Record "G/L Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        GLEntry.SetRange("Document No.", DocumentNoFilter);

        GLEntry.SetRange("G/L Account No.", VendorPostingGroup."Payables Account");
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(0, GLEntry.Amount, StrSubstNo(UnbalancedGLAccountErr, GLEntry."G/L Account No."));

        GLEntry.SetRange("G/L Account No.", VendorPostingGroup."Invoices in  Pmt. Ord. Acc.");
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(0, GLEntry.Amount, StrSubstNo(UnbalancedGLAccountErr, GLEntry."G/L Account No."));
    end;

    local procedure SetPurchAllowMultiplePostingGroups(AllowMultiplePostingGroups: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Allow Multiple Posting Groups", AllowMultiplePostingGroups);
        PurchasesPayablesSetup.Validate("Check Multiple Posting Groups", "Posting Group Change Method"::"Alternative Groups");
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure CreateMultipleVendorPostingGroups(var VendorPostingGroup: Record "Vendor Posting Group"): Record "Vendor Posting Group"
    var
        VendorPostingGroup2: Record "Vendor Posting Group";
    begin
        // Crete First Vendor Posting Group
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        VendorPostingGroup.Validate("Invoices in  Pmt. Ord. Acc.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        VendorPostingGroup.Validate("Bills in Payment Order Acc.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        VendorPostingGroup.Modify(true);

        // Crete Second Vendor Posting Group
        VendorPostingGroup2.Init();
        VendorPostingGroup2.TransferFields(VendorPostingGroup, false);
        VendorPostingGroup2.Validate(
            Code, LibraryUtility.GenerateRandomCode(VendorPostingGroup2.FieldNo(Code),
            Database::"Vendor Posting Group"));
        VendorPostingGroup2.Validate("Payables Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        VendorPostingGroup2.Validate("Invoices in  Pmt. Ord. Acc.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        VendorPostingGroup2.Insert(true);

        // Set Alternative vendor posting group to each other.
        LibraryPurchase.CreateAltVendorPostingGroup(VendorPostingGroup.Code, VendorPostingGroup2.Code);
        LibraryPurchase.CreateAltVendorPostingGroup(VendorPostingGroup2.Code, VendorPostingGroup.Code);

        exit(VendorPostingGroup2);
    end;

    local procedure CreateVendorWithAllowMultiplePostingGroups(var Vendor: Record Vendor; VendorPostingGroup: Code[20])
    var
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("VAT distribution", PaymentTerms."VAT distribution"::Proportional);
        PaymentTerms.Validate("Max. No. of Days till Due Date", 31);
        PaymentTerms.Modify(true);
        LibraryCarteraPayables.CreateMultipleInstallments(PaymentTerms.Code, 1);

        FindPaymentMethod(PaymentMethod);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Allow Multiple Posting Groups", true);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
    end;

    local procedure FindPaymentMethod(var PaymentMethod: Record "Payment Method")
    begin
        PaymentMethod.SetRange("Create Bills", false);
        PaymentMethod.SetRange("Bill Type", PaymentMethod."Bill Type"::Transfer);
        PaymentMethod.SetRange("Invoices to Cartera", true);
        PaymentMethod.SetRange("Bal. Account No.", '');
        PaymentMethod.FindFirst();
    end;

    local procedure CreatePaymentOrder(var PaymentOrder: Record "Payment Order")
    begin
        PaymentOrder."No." := LibraryUtility.GenerateGUID();
        PaymentOrder."Bank Account No." := FindBankAccount();
        PaymentOrder.Insert(true);
    end;

    local procedure FindBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.FindBankAccount(BankAccount);

        exit(BankAccount."No.");
    end;

    local procedure VerifyGLAccInvoicesInPmtOrdAcc(VendorPostingGroupCode: Code[20]; DocumentNoFilter: Text[100])
    var
        GLEntry: Record "G/L Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        GLEntry.SetRange("Document No.", DocumentNoFilter);
        GLEntry.SetRange("G/L Account No.", VendorPostingGroup."Invoices in  Pmt. Ord. Acc.");
        GLEntry.CalcSums(Amount);

        Assert.AreEqual(0, GLEntry.Amount, StrSubstNo(UnbalancedGLAccountErr, GLEntry."G/L Account No."));
    end;

    local procedure CreateVendorPostingGroupWithBillsPaymentOrderAcc(var VendorPostingGroup: Record "Vendor Posting Group")
    begin
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        VendorPostingGroup.Validate("Bills in Payment Order Acc.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        VendorPostingGroup.Modify(true);
    end;

    local procedure SetCarteraPaymentMethodInVendor(var Vendor: Record Vendor; var PaymentMethod: Record "Payment Method")
    begin
        LibraryCarteraReceivables.CreateBillToCarteraPaymentMethod(PaymentMethod);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
    end;

    local procedure TotalSettlementOnPaymentOrderFromPostedPaymentOrdersSelect(PostedPaymentOrderNo: Code[20])
    var
        PostedPaymentOrder: Record "Posted Payment Order";
        PostedPaymentOrdersSelect: TestPage "Posted Payment Orders Select.";
    begin
        PostedPaymentOrder.Get(PostedPaymentOrderNo);

        PostedPaymentOrdersSelect.OpenEdit();
        PostedPaymentOrdersSelect.GotoRecord(PostedPaymentOrder);
        PostedPaymentOrdersSelect.BatchSettlement.Invoke();
        PostedPaymentOrdersSelect.Close();
    end;

    local procedure CreateAndPostPurchaseInvoice(Vendor: Record Vendor; PostingGroup: Code[20]; PaymentMethodCode: Code[20]): Code[20]
    var
        PaymentMethod: Record "Payment Method";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InvoiceNo: Code[20];
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Invoice, Vendor."No.", '', 1, '', 0D);
        if PostingGroup <> '' then
            PurchaseHeader.Validate("Vendor Posting Group", PostingGroup);
        if PaymentMethodCode = '' then begin
            LibraryERM.CreatePaymentMethod(PaymentMethod);
            PurchaseHeader.Validate("Payment Method Code", PaymentMethod.Code);
        end;
        PurchaseHeader.Modify(true);

        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Modify(true);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        exit(InvoiceNo);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageVerifyHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message)
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CarteraDocumentsActionModalPageHandler(var CarteraDocuments: Page "Cartera Documents"; var Response: Action)
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange("Document No.", LibraryVariableStorage.DequeueText());
        CarteraDoc.FindLast();

        // From the Cartera Document page, select the record filtered by 'Document No.'
        CarteraDocuments.SetRecord(CarteraDoc);

        Response := ACTION::LookupOK;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RedrawPayableBillsPageHandler(var RedrawPayableBillsTestRequestPage: TestRequestPage "Redraw Payable Bills")
    begin
        RedrawPayableBillsTestRequestPage.NewDueDate.SetValue(CalcDate('<1D>', LibraryVariableStorage.DequeueDate()));
        RedrawPayableBillsTestRequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SettleDocsInPostedPOModalPageHandler(var SettleDocsInPostedPOModalPageHandler: TestRequestPage "Settle Docs. in Posted PO")
    begin
        SettleDocsInPostedPOModalPageHandler.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        SettleDocsInPostedPOModalPageHandler.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorDuePaymentsRequestPageHandler(var VendorDuePaymentsRequestPage: TestRequestPage "Vendor - Due Payments")
    begin
        VendorDuePaymentsRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
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
    procedure BankAccountListPageHandler(var BankAccountList: TestPage "Bank Account List")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        BankAccountList.GotoKey(BankAccountNo);
        BankAccountList.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure PaymentOrderListingRequestPageHandler(var PaymentOrderListing: TestRequestPage "Payment Order Listing")
    var
        PDFFileName: Text;
    begin
        PDFFileName := LibraryReportDataset.GetFileName() + '.pdf';
        LibraryVariableStorage.Enqueue(PDFFileName);
        PaymentOrderListing.SaveAsPdf(PDFFileName);
    end;

    [TryFunction]
    local procedure TryToInsertPaymentOrder(PaymentOrders: TestPage "Payment Orders")
    begin
        PaymentOrders.Docs.Insert.Invoke();
    end;

    [ModalPageHandler]
    procedure CarteraDocumentsModalHandler(var CarteraDocuments: TestPage "Cartera Documents")
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange("Document No.", LibraryVariableStorage.DequeueText());
        CarteraDoc.FindFirst();
        if CarteraDocuments.First() then
            repeat
                if CarteraDocuments."Document No.".Value = CarteraDoc."Document No." then begin
                    CarteraDocuments.OK().Invoke();
                    exit;
                end;
            until CarteraDocuments.Next();
    end;

    [RequestPageHandler]
    procedure SettleDocsInPostedPOModalPageHandler2(var BatchSettlPostedPOs: TestRequestPage "Batch Settl. Posted POs")
    begin
        BatchSettlPostedPOs.PostingDate.SetValue(WorkDate());
        BatchSettlPostedPOs.OK().Invoke();
    end;
}
