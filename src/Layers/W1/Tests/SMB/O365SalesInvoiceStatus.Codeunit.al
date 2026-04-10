codeunit 138010 "O365 Sales Invoice Status"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SMB] [Sales] [Invoice] [Application]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ConfirmationMsg: Label 'Do you want to post the journal lines?';
        LinesPostedMsg: Label 'The journal lines were successfully posted.';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        isInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Sales Invoice Status");
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Sales Invoice Status");

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        LibraryApplicationArea.EnableFoundationSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Sales Invoice Status");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceUnpaid()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
    begin
        Initialize();
        CreateAndPostSalesInvoice(Customer, Item, 1, SalesHeader, SalesInvHeader);

        // check that invoice is unpaid and remaining amount is the price of one item, because that's what we invoiced
        VerifyPaymentStatusAndRemainingAmount(SalesInvHeader, false, Item."Unit Price");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePaid()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
    begin
        Initialize();
        CreateAndPostSalesInvoice(Customer, Item, 1, SalesHeader, SalesInvHeader);

        // customer paid the full amount of the invoice (1 item) - register it
        RegisterPaymentForInvoice(SalesInvHeader, Item."Unit Price");

        // check that invoice is paid
        VerifyPaymentStatusAndRemainingAmount(SalesInvHeader, true, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePaidInTwoPayments()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
    begin
        Initialize();
        CreateAndPostSalesInvoice(Customer, Item, 2, SalesHeader, SalesInvHeader);

        // first payment, customer pays for only one item, he still has to pay for the other item later
        RegisterPaymentForInvoice(SalesInvHeader, Item."Unit Price");

        // check that invoice is unpaid after first payment the remaining amount is Item."Unit Price", because we sold two items and the customer paid for one
        VerifyPaymentStatusAndRemainingAmount(SalesInvHeader, false, Item."Unit Price");

        // second payment, customer pays the remaining amount
        SalesInvHeader.CalcFields("Remaining Amount");
        RegisterPaymentForInvoice(SalesInvHeader, SalesInvHeader."Remaining Amount");

        // check that invoice is paid
        VerifyPaymentStatusAndRemainingAmount(SalesInvHeader, true, 0);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
    end;

    local procedure CreateItem(var Item: Record Item; VATBusPostingGroup: Code[20])
    begin
        LibrarySmallBusiness.CreateItem(Item);
        // set no VAT on the item
        Item.Validate(
          "VAT Prod. Posting Group", LibrarySmallBusiness.FindVATProdPostingGroupZeroVAT(VATBusPostingGroup));
        // set unit price on the item
        Item."Unit Price" := LibraryRandom.RandDecInDecimalRange(1.0, 1000.0, 2);
        Item.Modify();
    end;

    local procedure CreateSalesInvoice(var Customer: Record Customer; var Item: Record Item; Quantity: Integer; var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, Quantity);
    end;

    local procedure PostSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesInvHeader: Record "Sales Invoice Header")
    var
        SalesInvHeaderNo: Code[20];
    begin
        SalesInvHeaderNo := LibrarySmallBusiness.PostSalesInvoice(SalesHeader);
        SalesInvHeader.Get(SalesInvHeaderNo);
    end;

    local procedure CreateAndPostSalesInvoice(var Customer: Record Customer; var Item: Record Item; Quantity: Integer; var SalesHeader: Record "Sales Header"; var SalesInvHeader: Record "Sales Invoice Header")
    begin
        CreateCustomer(Customer);
        CreateItem(Item, Customer."VAT Bus. Posting Group");
        CreateSalesInvoice(Customer, Item, Quantity, SalesHeader);
        PostSalesInvoice(SalesHeader, SalesInvHeader);
        SalesInvHeader.CalcFields(Closed);
    end;

    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    local procedure RegisterPaymentForInvoice(var SalesInvHeader: Record "Sales Invoice Header"; PaymentAmount: Decimal)
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        PaymentJournal: TestPage "Payment Journal";
    begin
        GenJnlBatch.FindLast();
        PaymentJournal.OpenEdit();
        PaymentJournal."Document No.".SetValue(NoSeries.PeekNextNo(GenJnlBatch."No. Series", SalesInvHeader."Posting Date"));
        PaymentJournal."Account Type".SetValue(GenJnlLine."Account Type"::Customer);
        PaymentJournal."Account No.".SetValue(SalesInvHeader."Sell-to Customer No.");
        PaymentJournal.Amount.SetValue(PaymentAmount * -1);
        PaymentJournal."Applies-to Doc. Type".SetValue(GenJnlLine."Applies-to Doc. Type"::Invoice);
        PaymentJournal.AppliesToDocNo.SetValue(SalesInvHeader."No.");
        LibraryVariableStorage.Enqueue(ConfirmationMsg); // message for the confirm handler
        LibraryVariableStorage.Enqueue(true); // reply for the confirm handler
        LibraryVariableStorage.Enqueue(LinesPostedMsg); // message for the message handler
        PaymentJournal.Post.Invoke();
        PaymentJournal.Close();
        Commit();
    end;

    local procedure VerifyPaymentStatusAndRemainingAmount(SalesInvHeader: Record "Sales Invoice Header"; ExpectedPaymentStatus: Boolean; ExpectedRemainingAmount: Decimal)
    var
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
    begin
        PostedSalesInvoices.OpenView();
        PostedSalesInvoices.GotoRecord(SalesInvHeader);
        PostedSalesInvoices.Closed.AssertEquals(ExpectedPaymentStatus);
        PostedSalesInvoices."Remaining Amount".AssertEquals(ExpectedRemainingAmount);
        PostedSalesInvoices.Close();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
        Answer: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        LibraryVariableStorage.Dequeue(Answer);
        Assert.IsTrue(StrPos(Question, ExpectedMessage) > 0, Question);
        Reply := Answer;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, ' Actual:' + Message);
    end;
}

