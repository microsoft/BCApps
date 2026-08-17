codeunit 135302 "Corr. Credit Memo Notifcation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Corrective Credit Memo] [Notification] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        InvoicePartiallyPaidMsg: Label 'Invoice %1 is partially paid or credited. The corrective credit memo may not be fully closed by the invoice.', Comment = '%1 - invoice no.';
        InvoiceClosedMsg: Label 'Invoice %1 is closed. The corrective credit memo will not be applied to the invoice.', Comment = '%1 - invoice no.';

    [Test]
    [HandlerFunctions('SkipSalesNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T100_CreditMemoOnPartiallyPaidSalesInvoiceCardSkip()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        ExpectedRemAmount: Decimal;
        ExpectedNotificationMsg: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] 'Skip' notification action does not create corrective credit memo for partially paid invoice from invoice card page.
        Initialize();
        // [GIVEN] posted Invoice, of amount 300
        PostSalesInvoice(SalesInvoiceHeader);
        // [GIVEN] Invoice is partially applied to Payment of 100, so "Remaining Amount" is 200
        ApplyPaymentToSalesInvoice(SalesInvoiceHeader, -GetSalesInvoiceRemainingAmount(SalesInvoiceHeader) div 3);
        ExpectedRemAmount := GetSalesInvoiceRemainingAmount(SalesInvoiceHeader);
        // [GIVEN] Open "Posted Sales Invoice" page
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", SalesInvoiceHeader."No.");
        // [GIVEN] Run "Create Corrective Credit Memo" action
        PostedSalesInvoice.CreateCreditMemo.Invoke();

        // [WHEN] Pick 'Skip' action in notification: "Invoice is partially paid. |Show Entries|Skip|Create|"
        ExpectedNotificationMsg := StrSubstNo(InvoicePartiallyPaidMsg, SalesInvoiceHeader."No.");
        Assert.ExpectedMessage(ExpectedNotificationMsg, LibraryVariableStorage.DequeueText()); // from SkipNotificationHandler
        Assert.AreEqual(SalesInvoiceHeader."No.", LibraryVariableStorage.DequeueText(), 'notification No.');

        // [THEN] Notification is recalled
        Assert.AreEqual(SalesInvoiceHeader."No.", LibraryVariableStorage.DequeueText(), 'recall No.'); // from RecallNotificationHandler
        // [THEN] Invoice page is still open
        PostedSalesInvoice.Close();
        // [THEN] Invoice's "Remaining Amount" is 200
        Assert.AreEqual(ExpectedRemAmount, GetSalesInvoiceRemainingAmount(SalesInvoiceHeader), 'Remaining Amount is changed');

        LibraryVariableStorage.AssertEmpty();
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CreateSalesNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T101_CreditMemoOnPartiallyPaidSalesInvoiceCardCreate()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ExpectedNotificationMsg: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] 'Create Anyway' notification action does create corrective credit memo for partially paid invoice from invoice card page.
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] posted Invoice '101033', of amount 300
        PostSalesInvoice(SalesInvoiceHeader);
        // [GIVEN] Invoice is partially applied to Payment of 100
        ApplyPaymentToSalesInvoice(SalesInvoiceHeader, -GetSalesInvoiceRemainingAmount(SalesInvoiceHeader) div 3);
        // [GIVEN] Open "Posted Sales Invoice" page
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", SalesInvoiceHeader."No.");
        // [GIVEN] Run "Create Corrective Credit Memo" action
        SalesCreditMemo.Trap();
        PostedSalesInvoice.CreateCreditMemo.Invoke();

        // [WHEN] Pick 'Create' action in Notification: "Invoice is partially paid. |Show Entries|Skip|Create|"
        ExpectedNotificationMsg := StrSubstNo(InvoicePartiallyPaidMsg, SalesInvoiceHeader."No.");
        Assert.ExpectedMessage(ExpectedNotificationMsg, LibraryVariableStorage.DequeueText()); // from CreateNotificationHandler
        Assert.AreEqual(Format(SalesInvoiceHeader."No."), LibraryVariableStorage.DequeueText(), 'notification No.');

        // [THEN] Credit memo page is open, where "Applies-to Doc. No." is '101033', the first line contains 'Invoice 101033'
        SalesCreditMemo."Applies-to Doc. No.".AssertEquals(SalesInvoiceHeader."No.");
        Assert.ExpectedMessage(SalesInvoiceHeader."No.", SalesCreditMemo.SalesLines.Description.Value);
        SalesCreditMemo.Close();
        // [THEN] Notification is recalled
        Assert.AreEqual(SalesInvoiceHeader."No.", LibraryVariableStorage.DequeueText(), 'recall No.'); // from RecallNotificationHandler
        // [THEN] Invoice page is open
        PostedSalesInvoice.Close();

        LibraryVariableStorage.AssertEmpty();
        LibraryERM.SetEnableDataCheck(true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ShowEntriesSalesNotificationHandler,AppliedSalesEntriesModalHandler')]
    [Scope('OnPrem')]
    procedure T110_CreditMemoOnPartiallyPaidSalesInvoiceListShowEntries()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
        ExpectedNotificationMsg: Text;
        PaymentDocNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] 'Show Entries' notification action opens "Applied Entries" page for partially paid invoice from invoices list page.
        Initialize();
        // [GIVEN] posted Invoice '101033'
        PostSalesInvoice(SalesInvoiceHeader);
        // [GIVEN] Invoice is partially paid by two Payments
        PaymentDocNo[1] := ApplyPaymentToSalesInvoice(SalesInvoiceHeader, -GetSalesInvoiceRemainingAmount(SalesInvoiceHeader) div 3);
        PaymentDocNo[2] := ApplyPaymentToSalesInvoice(SalesInvoiceHeader, -GetSalesInvoiceRemainingAmount(SalesInvoiceHeader) div 2);
        Assert.AreNotEqual(PaymentDocNo[1], PaymentDocNo[2], 'Payment document numbers must be different');
        // [GIVEN] Open "Posted Sales Invoices" page
        PostedSalesInvoices.OpenView();
        PostedSalesInvoices.FILTER.SetFilter("No.", SalesInvoiceHeader."No.");
        // [GIVEN] Run "Create Corrective Credit Memo" action
        PostedSalesInvoices.CreateCreditMemo.Invoke();

        // [WHEN] Pick 'Show Entries' action in notification: "Invoice is closed. |Show Entries|Skip|Create|"
        ExpectedNotificationMsg := StrSubstNo(InvoicePartiallyPaidMsg, SalesInvoiceHeader."No.");
        Assert.ExpectedMessage(ExpectedNotificationMsg, LibraryVariableStorage.DequeueText());
        Assert.AreEqual(Format(SalesInvoiceHeader."No."), LibraryVariableStorage.DequeueText(), 'notification No.'); // from ShowEntriesNotificationHandler

        // [THEN] Applied Customer Entries page is open, where are 2 payment entries applied to Invoice '101033'.
        Assert.ExpectedMessage(SalesInvoiceHeader."No.", LibraryVariableStorage.DequeueText()); // from AppliedSalesEntriesModalHandler
        Assert.AreEqual(PaymentDocNo[1], LibraryVariableStorage.DequeueText(), 'payment docNo #1');
        Assert.AreEqual(PaymentDocNo[2], LibraryVariableStorage.DequeueText(), 'payment docNo #2');

        LibraryVariableStorage.AssertEmpty();
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CreateSalesNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T111_CreditMemoOnClosedSalesInvoiceListCreate()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ExpectedNotificationMsg: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] 'Create Anyway' notification action does create corrective credit memo for closed invoice from invoices list page.
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] posted Invoice '101033'
        PostSalesInvoice(SalesInvoiceHeader);
        // [GIVEN] Invoice is closed by Payment
        ApplyPaymentToSalesInvoice(SalesInvoiceHeader, -GetSalesInvoiceRemainingAmount(SalesInvoiceHeader));
        // [GIVEN] Open "Posted Sales Invoices" page
        PostedSalesInvoices.OpenView();
        PostedSalesInvoices.FILTER.SetFilter("No.", SalesInvoiceHeader."No.");
        // [GIVEN] Run "Create Corrective Credit Memo" action
        SalesCreditMemo.Trap();
        PostedSalesInvoices.CreateCreditMemo.Invoke();

        // [WHEN] Pick 'Create' action in notification: "Invoice is closed. |Show Entries|Skip|Create|"
        ExpectedNotificationMsg := StrSubstNo(InvoiceClosedMsg, SalesInvoiceHeader."No.");
        Assert.ExpectedMessage(ExpectedNotificationMsg, LibraryVariableStorage.DequeueText()); // from CreateNotificationHandler
        Assert.AreEqual(Format(SalesInvoiceHeader."No."), LibraryVariableStorage.DequeueText(), 'notification No.');

        // [THEN] Credit memo page is open, where "Applies-to Doc. No." is <blank>, the first line contains 'Invoice 101033'
        SalesCreditMemo."Applies-to Doc. No.".AssertEquals('');
        Assert.ExpectedMessage(SalesInvoiceHeader."No.", SalesCreditMemo.SalesLines.Description.Value);
        SalesCreditMemo.Close();
        // [THEN] Invoice's "Remaining Amount" is 0
        Assert.AreEqual(0, GetSalesInvoiceRemainingAmount(SalesInvoiceHeader), 'Remaining Amount is changed');
        // [THEN] Notification is recalled
        Assert.AreEqual(SalesInvoiceHeader."No.", LibraryVariableStorage.DequeueText(), 'recall No.'); // from RecallNotificationHandler
        // [THEN] Invoices list page is open
        PostedSalesInvoices.Close();

        LibraryVariableStorage.AssertEmpty();
        LibraryERM.SetEnableDataCheck(true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SkipPurchNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T200_CreditMemoOnPartiallyPaidPurchInvoiceCardSkip()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        ExpectedRemAmount: Decimal;
        ExpectedNotificationMsg: Text;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] 'Skip' notification action does not create corrective credit memo for partially paid invoice from invoice card page.
        Initialize();
        // [GIVEN] posted Invoice, of amount 300
        PostPurchInvoice(PurchInvHeader);
        // [GIVEN] Invoice is partially applied to Payment of 100, so "Remaining Amount" is 200
        ApplyPaymentToPurchInvoice(PurchInvHeader, GetPurchInvoiceRemainingAmount(PurchInvHeader) div 3);
        ExpectedRemAmount := GetPurchInvoiceRemainingAmount(PurchInvHeader);
        // [GIVEN] Open "Posted Purchase Invoice" page
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.FILTER.SetFilter("No.", PurchInvHeader."No.");
        // [GIVEN] Run "Create Corrective Credit Memo" action
        PostedPurchaseInvoice.CreateCreditMemo.Invoke();

        // [WHEN] Pick 'Skip' action in notification: "Invoice is partially paid. |Show Entries|Skip|Create|"
        ExpectedNotificationMsg := StrSubstNo(InvoicePartiallyPaidMsg, PurchInvHeader."No.");
        Assert.ExpectedMessage(ExpectedNotificationMsg, LibraryVariableStorage.DequeueText()); // from SkipNotificationHandler
        Assert.AreEqual(PurchInvHeader."No.", LibraryVariableStorage.DequeueText(), 'notification No.');

        // [THEN] Notification is recalled
        Assert.AreEqual(PurchInvHeader."No.", LibraryVariableStorage.DequeueText(), 'recall No.'); // from RecallNotificationHandler
        // [THEN] Invoice page is still open
        PostedPurchaseInvoice.Close();
        // [THEN] Invoice's "Remaining Amount" is 200
        Assert.AreEqual(ExpectedRemAmount, GetPurchInvoiceRemainingAmount(PurchInvHeader), 'Remaining Amount is changed');

        LibraryVariableStorage.AssertEmpty();
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ShowEntriesPurchNotificationHandler,AppliedPurchEntriesModalHandler')]
    [Scope('OnPrem')]
    procedure T210_CreditMemoOnPartiallyPaidPurchInvoiceListShowEntries()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
        ExpectedNotificationMsg: Text;
        PaymentDocNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] 'Show Entries' notification action opens "Applied Entries" page for partially paid invoice from invoices list page.
        Initialize();
        // [GIVEN] posted Invoice '101033'
        PostPurchInvoice(PurchInvHeader);
        // [GIVEN] Invoice is partially paid by two Payments
        PaymentDocNo[1] := ApplyPaymentToPurchInvoice(PurchInvHeader, GetPurchInvoiceRemainingAmount(PurchInvHeader) div 3);
        PaymentDocNo[2] := ApplyPaymentToPurchInvoice(PurchInvHeader, GetPurchInvoiceRemainingAmount(PurchInvHeader) div 2);
        Assert.AreNotEqual(PaymentDocNo[1], PaymentDocNo[2], 'Payment document numbers must be different');
        // [GIVEN] Open "Posted Purchase Invoices" page
        PostedPurchaseInvoices.OpenView();
        PostedPurchaseInvoices.FILTER.SetFilter("No.", PurchInvHeader."No.");
        // [GIVEN] Run "Create Corrective Credit Memo" action
        PostedPurchaseInvoices.CreateCreditMemo.Invoke();

        // [WHEN] Pick 'Show Entries' action in notification: "Invoice is closed. |Show Entries|Skip|Create|"
        ExpectedNotificationMsg := StrSubstNo(InvoicePartiallyPaidMsg, PurchInvHeader."No.");
        Assert.ExpectedMessage(ExpectedNotificationMsg, LibraryVariableStorage.DequeueText());
        Assert.AreEqual(Format(PurchInvHeader."No."), LibraryVariableStorage.DequeueText(), 'notification No.'); // from ShowEntriesNotificationHandler

        // [THEN] Applied Customer Entries page is open, where are 2 payment entries applied to Invoice '101033'.
        Assert.ExpectedMessage(PurchInvHeader."No.", LibraryVariableStorage.DequeueText()); // from AppliedPurchEntriesModalHandler
        Assert.AreEqual(PaymentDocNo[1], LibraryVariableStorage.DequeueText(), 'payment docNo #1');
        Assert.AreEqual(PaymentDocNo[2], LibraryVariableStorage.DequeueText(), 'payment docNo #2');

        LibraryVariableStorage.AssertEmpty();
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CreateSalesNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoOnPartiallyCreditedSalesInvoiceCardCreate()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        ReasonCode: Record "Reason Code";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ExpectedNotificationMsg: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 364099] When invoice already has a corrective credit memo for partial quantity creating a second corrective credit memo for remaining quantity is possible
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] posted Invoice '101033', with quantity = 10
        LibrarySales.CreateSalesInvoice(SalesHeader);
        ModifyQuantityForSalesHeader(SalesHeader, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Posted sales invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Invoke CreateCreditMemoCopyDocument for posted sales invoice
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeader);

        // [GIVEN] Credit Memo has a reason code
        LibraryERM.CreateReasonCode(ReasonCode);
        SalesHeader.Validate("Reason Code", ReasonCode.Code);
        SalesHeader.Modify(true);

        // [GIVEN] Quantity on Corrective credit memo equals 1
        ModifyQuantityForSalesHeader(SalesHeader, LibraryRandom.RandIntInRange(1, 9));

        // [GIVEN] First corrective credit memo was posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Open "Posted Sales Invoice" page for original Invoice
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", SalesInvoiceHeader."No.");

        // [GIVEN] Run "Create Corrective Credit Memo" action again
        SalesCreditMemo.Trap();
        PostedSalesInvoice.CreateCreditMemo.Invoke();

        // [WHEN] Pick 'Create' action in Notification: "Invoice is partially paid or credited. |Show Entries|Skip|Create|"
        ExpectedNotificationMsg := StrSubstNo(InvoicePartiallyPaidMsg, SalesInvoiceHeader."No.");
        Assert.ExpectedMessage(ExpectedNotificationMsg, LibraryVariableStorage.DequeueText()); // from CreateNotificationHandler
        Assert.AreEqual(Format(SalesInvoiceHeader."No."), LibraryVariableStorage.DequeueText(), 'notification No.');

        // [THEN] Credit Memo is created. Credit memo page is open, where "Applies-to Doc. No." is '101033'
        SalesCreditMemo."Applies-to Doc. No.".AssertEquals(SalesInvoiceHeader."No.");

        // [THEN] First line on the Credit Memo contains 'Invoice 101033'
        Assert.ExpectedMessage(SalesInvoiceHeader."No.", SalesCreditMemo.SalesLines.Description.Value);
        SalesCreditMemo.Close();

        // [THEN] Notification is recalled
        Assert.AreEqual(SalesInvoiceHeader."No.", LibraryVariableStorage.DequeueText(), 'recall No.'); // from RecallNotificationHandler

        // Clean-up open pages and notifications
        PostedSalesInvoice.Close();
        LibraryVariableStorage.AssertEmpty();
        LibraryERM.SetEnableDataCheck(true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Corr. Credit Memo Notifcation");

        LibraryVariableStorage.Clear();
    end;

    local procedure ApplyPaymentToInvoice(InvoiceNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PaymentAmount: Decimal): Code[20]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), PaymentAmount);
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure ApplyPaymentToPurchInvoice(PurchInvHeader: Record "Purch. Inv. Header"; PaymentAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(ApplyPaymentToInvoice(PurchInvHeader."No.", GenJournalLine."Account Type"::Vendor, PurchInvHeader."Buy-from Vendor No.", PaymentAmount));
    end;

    local procedure ApplyPaymentToSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"; PaymentAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(ApplyPaymentToInvoice(SalesInvoiceHeader."No.", GenJournalLine."Account Type"::Customer, SalesInvoiceHeader."Sell-to Customer No.", PaymentAmount));
    end;

    local procedure GetPurchInvoiceRemainingAmount(var PurchInvHeader: Record "Purch. Inv. Header"): Decimal
    begin
        PurchInvHeader.CalcFields("Remaining Amount");
        exit(PurchInvHeader."Remaining Amount");
    end;

    local procedure GetSalesInvoiceRemainingAmount(var SalesInvoiceHeader: Record "Sales Invoice Header"): Decimal
    begin
        SalesInvoiceHeader.CalcFields("Remaining Amount");
        exit(SalesInvoiceHeader."Remaining Amount");
    end;

    local procedure PostPurchInvoice(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure ModifyQuantityForSalesHeader(SalesHeader: Record "Sales Header"; NewQuantity: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetFilter(Quantity, '<>0');
        SalesLine.FindFirst();
        SalesLine.Validate(Quantity, NewQuantity);
        SalesLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AppliedPurchEntriesModalHandler(var AppliedVendorEntries: TestPage "Applied Vendor Entries")
    begin
        // Expecting 2 applied entries
        LibraryVariableStorage.Enqueue(AppliedVendorEntries.Caption);
        Assert.IsTrue(AppliedVendorEntries.First(), 'no applied entries found');
        LibraryVariableStorage.Enqueue(AppliedVendorEntries."Document No.".Value);
        Assert.IsTrue(AppliedVendorEntries.Next(), 'less that 2 applied entries found');
        LibraryVariableStorage.Enqueue(AppliedVendorEntries."Document No.".Value);
        Assert.IsFalse(AppliedVendorEntries.Next(), 'more that 2 applied entries found');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AppliedSalesEntriesModalHandler(var AppliedCustomerEntries: TestPage "Applied Customer Entries")
    begin
        // Expecting 2 applied entries
        LibraryVariableStorage.Enqueue(AppliedCustomerEntries.Caption);
        Assert.IsTrue(AppliedCustomerEntries.First(), 'no applied entries found');
        LibraryVariableStorage.Enqueue(AppliedCustomerEntries."Document No.".Value);
        Assert.IsTrue(AppliedCustomerEntries.Next(), 'less that 2 applied entries found');
        LibraryVariableStorage.Enqueue(AppliedCustomerEntries."Document No.".Value);
        Assert.IsFalse(AppliedCustomerEntries.Next(), 'more that 2 applied entries found');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SkipPurchNotificationHandler(var Notification: Notification): Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
        LibraryVariableStorage.Enqueue(Notification.GetData(PurchInvHeader.FieldName("No.")));
        CorrectPostedPurchInvoice.SkipCorrectiveCreditMemo(Notification); // simulate 'Skip' action
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SkipSalesNotificationHandler(var Notification: Notification): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
        LibraryVariableStorage.Enqueue(Notification.GetData(SalesInvoiceHeader.FieldName("No.")));
        CorrectPostedSalesInvoice.SkipCorrectiveCreditMemo(Notification); // simulate 'Skip' action
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure CreatePurchNotificationHandler(var Notification: Notification): Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
        LibraryVariableStorage.Enqueue(Notification.GetData(PurchInvHeader.FieldName("No.")));
        CorrectPostedPurchInvoice.CreateCorrectiveCreditMemo(Notification); // simulate 'Create' action
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure CreateSalesNotificationHandler(var Notification: Notification): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
        LibraryVariableStorage.Enqueue(Notification.GetData(SalesInvoiceHeader.FieldName("No.")));
        CorrectPostedSalesInvoice.CreateCorrectiveCreditMemo(Notification); // simulate 'Create' action
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ShowEntriesPurchNotificationHandler(var Notification: Notification): Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
        LibraryVariableStorage.Enqueue(Notification.GetData(PurchInvHeader.FieldName("No.")));
        CorrectPostedPurchInvoice.ShowAppliedEntries(Notification); // simulate 'Show Entries' action
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ShowEntriesSalesNotificationHandler(var Notification: Notification): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
        LibraryVariableStorage.Enqueue(Notification.GetData(SalesInvoiceHeader.FieldName("No.")));
        CorrectPostedSalesInvoice.ShowAppliedEntries(Notification); // simulate 'Show Entries' action
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        LibraryVariableStorage.Enqueue(Notification.GetData(SalesInvoiceHeader.FieldName("No.")));
    end;
}

