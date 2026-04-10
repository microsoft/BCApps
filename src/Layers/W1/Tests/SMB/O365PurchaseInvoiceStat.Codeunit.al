codeunit 138021 "O365 Purchase Invoice Stat."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SMB] [Purchase] [Invoice] [Application]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        ConfirmationMsg: Label 'Do you want to post the journal lines?';
        LinesPostedMsg: Label 'The journal lines were successfully posted.';

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Purchase Invoice Stat.");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Purchase Invoice Stat.");

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchasesPayablesSetup.Modify(true);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Purchase Invoice Stat.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceUnpaid()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        Quantity: Decimal;
    begin
        Initialize();

        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseInvoice(Vendor, Item, Quantity, PurchaseHeader, PurchInvHeader);

        // check that invoice is unpaid and remaining amount is the price of one item, because that's what we invoiced
        VerifyPaymentStatusAndRemainingAmount(PurchInvHeader, false, Quantity * Item."Last Direct Cost");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoicePaid()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        Quantity: Decimal;
    begin
        Initialize();

        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseInvoice(Vendor, Item, Quantity, PurchaseHeader, PurchInvHeader);

        // Vendor paid the full amount of the invoice  - register it
        RegisterPaymentForInvoice(PurchInvHeader, Quantity * Item."Last Direct Cost");

        // check that invoice is paid
        VerifyPaymentStatusAndRemainingAmount(PurchInvHeader, true, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoicePaidInTwoPayments()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        Quantity: Decimal;
    begin
        Initialize();

        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseInvoice(Vendor, Item, 2 * Quantity, PurchaseHeader, PurchInvHeader);

        // first payment, Vendor pays for only one item, he still has to pay for the other item later
        RegisterPaymentForInvoice(PurchInvHeader, Quantity * Item."Last Direct Cost");

        // check that invoice is unpaid after first payment the remaining amount is Item."Last Direct Cost", because we sold two items and the Vendor paid for one
        VerifyPaymentStatusAndRemainingAmount(PurchInvHeader, false, Quantity * Item."Last Direct Cost");

        // second payment, Vendor pays the remaining amount
        PurchInvHeader.CalcFields("Remaining Amount");
        RegisterPaymentForInvoice(PurchInvHeader, PurchInvHeader."Remaining Amount");

        // check that invoice is paid
        VerifyPaymentStatusAndRemainingAmount(PurchInvHeader, true, 0);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibrarySmallBusiness.CreateVendor(Vendor);
    end;

    local procedure CreateItem(var Item: Record Item; VATBusPostingGroupCode: Code[20])
    begin
        LibrarySmallBusiness.CreateItem(Item);
        // set no VAT on the item
        Item.Validate("VAT Prod. Posting Group",
          LibrarySmallBusiness.FindVATProdPostingGroupZeroVAT(VATBusPostingGroupCode));
        // set cost on the item
        Item."Last Direct Cost" := LibraryRandom.RandDecInDecimalRange(1.0, 1000.0, 2);
        Item.Modify();
    end;

    local procedure CreatePurchaseInvoice(var Vendor: Record Vendor; var Item: Record Item; Quantity: Decimal; var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(PurchaseHeader, Vendor);
        LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, Quantity);
    end;

    local procedure PostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchInvHeaderNo: Code[20];
    begin
        PurchInvHeaderNo := LibrarySmallBusiness.PostPurchaseInvoice(PurchaseHeader);
        PurchInvHeader.Get(PurchInvHeaderNo);
    end;

    local procedure CreateAndPostPurchaseInvoice(var Vendor: Record Vendor; var Item: Record Item; Quantity: Decimal; var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        CreateVendor(Vendor);
        CreateItem(Item, Vendor."VAT Bus. Posting Group");
        CreatePurchaseInvoice(Vendor, Item, Quantity, PurchaseHeader);
        PostPurchaseInvoice(PurchaseHeader, PurchInvHeader);
        PurchInvHeader.CalcFields(Closed);
    end;

    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    local procedure RegisterPaymentForInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; PaymentAmount: Decimal)
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        PaymentJournal: TestPage "Payment Journal";
    begin
        GenJnlBatch.FindLast();

        PaymentJournal.OpenEdit();
        PaymentJournal."Document No.".SetValue(NoSeries.PeekNextNo(GenJnlBatch."No. Series", PurchInvHeader."Posting Date"));
        PaymentJournal."Account Type".SetValue(GenJnlLine."Account Type"::Vendor);
        PaymentJournal."Account No.".SetValue(PurchInvHeader."Buy-from Vendor No.");
        PaymentJournal.Amount.SetValue(PaymentAmount);
        PaymentJournal."Applies-to Doc. Type".SetValue(GenJnlLine."Applies-to Doc. Type"::Invoice);
        PaymentJournal.AppliesToDocNo.SetValue(PurchInvHeader."No.");

        LibraryVariableStorage.Enqueue(ConfirmationMsg);
        // message for the confirm handler
        LibraryVariableStorage.Enqueue(true);
        // reply for the confirm handler
        LibraryVariableStorage.Enqueue(LinesPostedMsg);
        // message for the message handler
        PaymentJournal.Post.Invoke();

        PaymentJournal.Close();

        Commit();
    end;

    local procedure VerifyPaymentStatusAndRemainingAmount(PurchInvHeader: Record "Purch. Inv. Header"; ExpectedPaymentStatus: Boolean; ExpectedRemainingAmount: Decimal)
    var
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
    begin
        PostedPurchaseInvoices.OpenView();
        PostedPurchaseInvoices.GotoRecord(PurchInvHeader);
        PostedPurchaseInvoices.Closed.AssertEquals(ExpectedPaymentStatus);
        PostedPurchaseInvoices."Remaining Amount".AssertEquals(ExpectedRemainingAmount);
        PostedPurchaseInvoices.Close();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;
}

