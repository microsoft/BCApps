codeunit 137026 "Sales Correct Cr. Memo"
{
    Permissions = TableData "Detailed Cust. Ledg. Entry" = ri;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Cancelled Document] [Credit Memo] [Sales]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        IsInitialized: Boolean;
        BlockedCustomerErr: Label 'You cannot cancel this posted sales credit memo because customer %1 is blocked.', Comment = '%1 = Customer No.';
        AlreadyCancelledErr: Label 'You cannot cancel this posted sales credit memo because it has already been cancelled.';
        NotCorrectiveDocErr: Label 'You cannot cancel this posted sales credit memo because it is not a corrective document.';
        InvtPeriodClosedErr: Label 'You cannot cancel this posted sales credit memo because the inventory period is already closed.';
        PostPeriodClosedErr: Label 'You cannot cancel this posted sales credit memo because it was posted in a posting period that is closed.';
        BlockedItemErr: Label 'You cannot cancel this posted sales credit memo because item %1 %2 is blocked.';
        ItemVariantIsBlockedCancelErr: Label 'You cannot cancel this posted sales credit memo because item variant %1 for item %2 %3 is blocked.', Comment = '%1 - Item Variant Code, %2 = Item No. %3 = Item Description';
        NotCorrDocErr: Label 'You cannot cancel this posted sales invoice because it represents a correction of a credit memo.';
        NotAppliedCorrectlyErr: Label 'You cannot cancel this posted sales credit memo because it is not fully applied to an invoice.';
        CrMemoCancellationTxt: Label 'Cancellation of credit memo %1.', Comment = '%1 = Credit Memo No.';
        IncorrectItemApplicationErr: Label 'Incorrect item application.';
        InvRoundingLineDoesNotExistErr: Label 'Invoice rounding line does not exist.';
        FixedAssetNotPossibleToCreateCreditMemoErr: Label 'You cannot cancel this posted sales invoice because it contains lines of type Fixed Asset.\\Use the Cancel Entries function in the FA Ledger Entries window instead.';
        DirectPostingErr: Label 'G/L account %1 does not allow direct posting.', Comment = '%1 - g/l account no.';
        PostedSalesInvoiceNotCancelledErr: Label 'Posted Sales Invoice %1 not cancelled.', Comment = '%1 = Posted Sales Invoice No.';

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCrMemoIfCustomerIsBlocked()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if "Bill-to Customer No." is blocked

        Initialize();
        // [GIVEN] Posted Credit Memo cancelled Invoice with Customer "X"
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Blocked Customer "X"
        BlockCustomer(SalesCrMemoHeader."Bill-to Customer No.");
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(SalesCrMemoHeader);

        // [THEN] Error message "You cannot cancel this posted sales credit memo because customer X is blocked" is raised
        Assert.ExpectedError(StrSubstNo(BlockedCustomerErr, SalesCrMemoHeader."Bill-to Customer No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCrMemoIfPostingDateNotAllowed()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if "Posting Date" is outside of allowed posting period from General Ledger Setup

        Initialize();
        // [GIVEN] Posted Credit Memo cancelled Invoice with "Posting Date" = 01.01
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);

        // [GIVEN] "Allow Posting From" = 02.01 in General Ledger Setup
        LibraryERM.SetAllowPostingFromTo(SalesCrMemoHeader."Posting Date" + 1, 0D);
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(SalesCrMemoHeader);

        // [THEN] Error message "You cannot cancel this posted sales credit memo because it was posted in a posting period that is closed" is raised
        Assert.ExpectedError(PostPeriodClosedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCrMemoIfAlreadyCancelled()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if it was already cancelled

        Initialize();
        // [GIVEN] Posted Credit Memo cancelled Invoice
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Cancelled and unapplied Posted Credit Memo
        SalesCrMemoHeader.Find();
        CancelCrMemo(SalesCrMemoHeader);
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(SalesCrMemoHeader);

        // [THEN] Error message "You cannot cancel this posted sales credit memo because it has already been cancelled" is raised
        Assert.ExpectedError(AlreadyCancelledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCrMemoIfNotCorrectiveDoc()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if it's not corrective document

        Initialize();
        // [GIVEN] Posted Credit Memo
        PostCrMemo(SalesCrMemoHeader);
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(SalesCrMemoHeader);

        // [THEN] Error message "You cannot cancel this posted sales credit memo because it is not corrective document" is raised
        Assert.ExpectedError(NotCorrectiveDocErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCrMemoIfInvPostPeriodIsClosed()
    var
        InventoryPeriod: Record "Inventory Period";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if Inventory Period is closed

        Initialize();
        // [GIVEN] Posted Credit Memo cancelled Invoice with "Posting Date" = 01.01
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Closed Inventoty Period with "Posting Date" = 31.01
        CreateInvtPeriod(InventoryPeriod);
        Commit();
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(SalesCrMemoHeader);

        // [THEN] Error message "You cannot cancel this posted sales invoice because the inventory period is already closed" is raised
        Assert.ExpectedError(InvtPeriodClosedErr);

        // Tear down
        LibraryLowerPermissions.SetO365Setup();
        InventoryPeriod.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCrMemoIfItemIsBlocked()
    var
        Item: Record Item;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if item is blocked

        Initialize();
        // [GIVEN] Posted Credit Memo cancelled Invoice with Item = "X"
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Blocked Item "X"
        BlockItemOfSalesCrMemo(Item, SalesCrMemoHeader);
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(SalesCrMemoHeader);

        // [THEN] You cannot cancel this posted sales invoice because item X is blocked.
        Assert.ExpectedError(StrSubstNo(BlockedItemErr, Item."No.", Item.Description));
    end;

    [Test]
    procedure CannotCancelCrMemoIfItemVariantIsBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO] It's not possible to cancel Posted Credit Memo if item variant is blocked

        Initialize();
        // [GIVEN] Posted Credit Memo cancelled Invoice with Item Variant = "X"
        PostDocumentWithVariant(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesInvHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesInvHeader.FindLast();
        CancelInvoice(SalesCrMemoHeader, SalesInvHeader);

        // [GIVEN] Blocked Item Variant "X"
        BlockItemVariantOfSalesCrMemo(ItemVariant, SalesCrMemoHeader);
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(SalesCrMemoHeader);

        // [THEN] You cannot cancel this posted sales invoice because item X is blocked.
        Item.Get(ItemVariant."Item No.");
        Assert.ExpectedError(StrSubstNo(ItemVariantIsBlockedCancelErr, ItemVariant.Code, ItemVariant."Item No.", Item.Description));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCorrectiveInvoice()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NewSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel corrective Sales Invoice

        Initialize();
        // [GIVEN] Posted Credit Memo "B1" cancelled Invoice "A1"
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Posted Invoice "A2" cancelled Credit Memo "B1"
        CancelCrMemo(SalesCrMemoHeader);
        LibrarySmallBusiness.FindSalesCorrectiveInvoice(SalesInvHeader, SalesCrMemoHeader);
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Cancel Posted Invoice "A2"
        asserterror CancelInvoice(NewSalesCrMemoHeader, SalesInvHeader);

        // [THEN] Error message "You cannot cancel this posted sales invoice because it is corrective document to credit memo" is raised
        Assert.ExpectedError(NotCorrDocErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoIfInvoiceAppliedPartially()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if invoice applied partially

        Initialize();
        // [GIVEN] Posted unapplied Credit Memo "B" cancelled Invoice "A" with Amount = 100
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);
        UnapplyDocument(CustLedgerEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");
        SalesCrMemoHeader.CalcFields("Amount Including VAT");

        // [GIVEN] Applied Invoice "C" to Credit Memo "B" with Amount = 50
        TurnoffStockoutWarning(); // In order to post additional invoices to credit memo
        PostApplyUnapplyInvoiceToCrMemoWithSpecificAmount(
          SalesCrMemoHeader, Round(SalesCrMemoHeader."Amount Including VAT" / LibraryRandom.RandIntInRange(3, 5)), false);
        Commit();
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Cancel Posted Credi Memo "B" with corrective Invoice "D"
        asserterror CancelCrMemo(SalesCrMemoHeader);

        // [THEN] Error message "You cannot cancel this posted sales credit memo because it is not fully applied to invoice" is raised
        Assert.ExpectedError(NotAppliedCorrectlyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CannotCancelCreditMemoIfDetailedEntryDifferentFromInitialOrApplication()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [UT] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if there are detailed entries applied different from "Initial Entry" and "Application"

        Initialize();
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");
        MockDtldCustLedgEntry(CustLedgerEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::"Realized Gain");
        Commit();
        asserterror CancelCrMemo(SalesCrMemoHeader);
        Assert.ExpectedError(NotAppliedCorrectlyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelCorrectiveCreditMemo()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OrigSalesInvHeader: Record "Sales Invoice Header";
        SalesInvHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO 168492] Corrective Invoice is generated when cancel Corrective Credit Memo

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();
        // [WHEN] Cancel Posted Credit Memo "B"
        CancelCrMemo(SalesCrMemoHeader);

        // [THEN] No Cancelled Document for Posted Invoice "A"
        OrigSalesInvHeader.Get(SalesCrMemoHeader."Applies-to Doc. No.");
        VerifyCancelledDocumentDoesNotExist(OrigSalesInvHeader."No.");

        // [THEN] Posted Invoice "A" is unapplied
        VerifyAmountEqualRemainingAmount(CustLedgerEntry."Document Type"::Invoice, OrigSalesInvHeader."No.");

        // [THEN] Posted Invoice "C" is copied from Posted Credit Memo "B"
        LibrarySmallBusiness.FindSalesCorrectiveInvoice(SalesInvHeader, SalesCrMemoHeader);

        // [THEN] First Sales Invoice Line has blank type and description "Cancellation of Credit Memo B"
        VerifyCancellationDescrInSaleInvLine(SalesInvHeader);

        // [THEN] Cancelled Document exists for Posted Invoice "C" - Posted Credit Memo "B"
        VerifyCrMemoInvCancelledDocument(SalesCrMemoHeader."No.", SalesInvHeader."No.");

        // [THEN] Posted Invoice "C" is applied to Posted Credit Memo "B" ("Remaining Amount" = 0)
        VerifyZeroRemainingAmount(CustLedgerEntry."Document Type"::Invoice, SalesInvHeader."No.");
        VerifyZeroRemainingAmount(CustLedgerEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelCreditMemoAfterUnapplication()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Unapplication]
        // [SCENARIO 168492] Corrective Invoice is generated when unapply corrective credit memo from invoice before the cancellation

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Posted Invoice "A" and Posted Credit Memo "B" are unapplied
        UnapplyDocument(CustLedgerEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");
        Commit();
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Cancel Posted Credit Memo "B"
        CancelCrMemo(SalesCrMemoHeader);

        // [THEN] Posted Invoice "C" that cancelled Posted Credit Memo "B" is generated
        LibrarySmallBusiness.FindSalesCorrectiveInvoice(SalesInvHeader, SalesCrMemoHeader);

        // [THEN] Cancelled Document exists for Posted Invoice "C" - Posted Credit Memo "B"
        VerifyCrMemoInvCancelledDocument(SalesCrMemoHeader."No.", SalesInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelCreditMemoAfterFullyApplyUnapplySingleInvoice()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        NewSalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CancelledDocument: Record "Cancelled Document";
    begin
        // [FEATURE] [Unapplication]
        // [SCENARIO 168492] Corrective Invoice is generated when there is invoice different from original fully applied and unapplied to this credit memo before cancellation
        Initialize();

        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A" with Amount = 100
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);
        CancelledDocument.FindSalesCorrectiveCrMemo(SalesCrMemoHeader."No.");
        UnapplyDocument(CustLedgerEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");

        // [GIVEN] Unapplied Invoice "C" to Credit Memo "B" with Amount = 100
        TurnoffStockoutWarning(); // In order to post additional invoice for credit memo
        PostApplyUnapplyInvoiceToCrMemo(SalesCrMemoHeader);
        FindLastSalesInvHeader(SalesInvHeader, SalesCrMemoHeader."Bill-to Customer No.");
        Commit();
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Cancel Posted Credit Memo "B"
        CancelCrMemo(SalesCrMemoHeader);

        // [THEN] Corrective Invoice "D" is generated
        FindLastSalesInvHeader(NewSalesInvHeader, SalesCrMemoHeader."Bill-to Customer No.");

        // [THEN] Cancelled Document is generated (Invoice = "D", "Credit Memo" = "B")
        VerifyCrMemoInvCancelledDocument(SalesCrMemoHeader."No.", NewSalesInvHeader."No.");

        // [THEN] No Cancelled Document with Invoice = "C"
        Assert.IsFalse(
          CancelledDocument.FindSalesCancelledInvoice(SalesInvHeader."No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelOriginallInvoiceSecondTimeAfterCrMemoCancellation()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NewSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OrigSalesInvHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO 168492] It is possible to cancel original invoice after the corrective credit memo applied to this invoice was cancelled

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);
        OrigSalesInvHeader.Get(SalesCrMemoHeader."Applies-to Doc. No.");
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [GIVEN] cancelled Posted Credit Memo "B"
        CancelCrMemo(SalesCrMemoHeader);

        // [WHEN] Cancel Invoice "A" by Credit Memo "C"
        OrigSalesInvHeader.Find();
        CancelInvoice(NewSalesCrMemoHeader, OrigSalesInvHeader);

        // [THEN] Cancelled Document exists for Posted Invoice "A" - Posted Credit Memo "C"
        VerifyInvCrMemoCancelledDocument(OrigSalesInvHeader."No.", NewSalesCrMemoHeader."No.");

        // [THEN] Posted Credit Memo "C" is applied to Posted Invoice "A" ("Remaining Amount" = 0)
        VerifyZeroRemainingAmount(CustLedgerEntry."Document Type"::Invoice, OrigSalesInvHeader."No.");
        VerifyZeroRemainingAmount(CustLedgerEntry."Document Type"::"Credit Memo", NewSalesCrMemoHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelCreditMemoAfterApplyUnapplyMultipleInvoices()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelledDocument: Record "Cancelled Document";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PartialAmount: Decimal;
    begin
        // [FEATURE] [Unapplication] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when there are other multiple invoices applied and unapplied fully to this credit memo before cancellation

        Initialize();

        // [GIVEN] Posted unapplied Credit Memo "B" cancelled Invoice "A" with Amount = 100
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);
        UnapplyDocument(CustLedgerEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");
        SalesCrMemoHeader.CalcFields("Amount Including VAT");

        // [GIVEN] Unapplied Invoices "C" and "D" to Credit Memo "B" with total Amount = 100
        TurnoffStockoutWarning(); // In order to post additional invoices to credit memo
        PartialAmount := Round(SalesCrMemoHeader."Amount Including VAT" / LibraryRandom.RandIntInRange(3, 5));
        PostApplyUnapplyInvoiceToCrMemoWithSpecificAmount(SalesCrMemoHeader, PartialAmount, true);
        PostApplyUnapplyInvoiceToCrMemoWithSpecificAmount(
          SalesCrMemoHeader, SalesCrMemoHeader."Amount Including VAT" - PartialAmount, true);
        Commit();
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Cancel Posted Credi Memo "B" with corrective Invoice "E"
        CancelCrMemo(SalesCrMemoHeader);

        // [THEN] Cancelled Document for Posted Credit Memo "B" exists
        Assert.IsTrue(
          CancelledDocument.FindSalesCancelledCrMemo(SalesCrMemoHeader."No."), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UI_CancelCorrectiveCreditMemoFromPostedSalesCreditMemosPage()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvHeader: Record "Sales Invoice Header";
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 168492] Action "Cancel Credit Memo" on "Posted Sales Credit Memos" page should cancel current Credit Memo

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Open "Posted Sales Credit Memos" page
        PostedSalesInvoice.Trap();
        PostedSalesCreditMemos.OpenEdit();
        PostedSalesCreditMemos.FILTER.SetFilter("No.", SalesCrMemoHeader."No.");
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Run action "Cancel Credit Memo" on "B"
        PostedSalesCreditMemos.CancelCrMemo.Invoke();

        // [THEN] "cancelled" is Yes on "Posted Credit Memos" page, action Cancel is invisible, action 'Show Invoice' is visible
        PostedSalesCreditMemos.Cancelled.AssertEquals(true);
        Assert.IsFalse(PostedSalesCreditMemos.CancelCrMemo.Visible(), 'CancelCrMemo must be invisible');
        Assert.IsTrue(PostedSalesCreditMemos.ShowInvoice.Visible(), 'ShowInvoice must be visible');

        // [THEN] "Corrective" is Yes on "Posted Invoice" page
        PostedSalesInvoice.Corrective.AssertEquals(true);

        // [THEN] Posted Invoice "C" that cancelled Posted Credit Memo "B" is generated
        LibrarySmallBusiness.FindSalesCorrectiveInvoice(SalesInvHeader, SalesCrMemoHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UI_CancelCorrectiveCreditMemoFromPostedSalesCreditMemoPage()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvHeader: Record "Sales Invoice Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 168492] Action "Cancel Credit Memo" on "Posted Sales Credit Memo" page should cancel current Credit Memo

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemo(SalesCrMemoHeader);

        // [GIVEN] Open "Posted Sales Credit Memo" page
        PostedSalesInvoice.Trap();
        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", SalesCrMemoHeader."No.");
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Run action "Cancel Credit Memo" on "B"
        PostedSalesCreditMemo.CancelCrMemo.Invoke();

        // [THEN] "Cancelled" is Yes on "Posted Credit Memo" page, action Cancel is invisible, action 'Show Invoice' is visible
        PostedSalesCreditMemo.Cancelled.AssertEquals(true);
        Assert.IsFalse(PostedSalesCreditMemo.CancelCrMemo.Visible(), 'CancelCrMemo must be invisible');
        Assert.IsTrue(PostedSalesCreditMemo.ShowInvoice.Visible(), 'ShowInvoice must be visible');

        // [THEN] "Corrective" is Yes on "Posted Invoice" page
        PostedSalesInvoice.Corrective.AssertEquals(true);

        // [THEN] Posted Invoice "C" that cancelled Posted Credit Memo "B" is generated
        LibrarySmallBusiness.FindSalesCorrectiveInvoice(SalesInvHeader, SalesCrMemoHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostApplcationAfterReapplyOnSecondInvoiceCancellation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NewSalesInvHeader: Record "Sales Invoice Header";
        NewSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
        PurchItemLedgEntryNo: array[2] of Integer;
        InvItemLedgEntryNo: array[2] of Integer;
        CrMemoItemLedgEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [SCM] [Cost Application] [Item Application Entry]
        // [SCENARIO 168492] Cost application posted correctly after reapply when cancel Sales Invoice second time

        Initialize();
        // [GIVEN] Positive Adjustment "A1"
        // [GIVEN] Positive Adjustment "A2"
        // [GIVEN] Invoice "I1"
        ItemNo := CreateItemNoWithFIFO();
        CreateDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo);
        PurchItemLedgEntryNo[1] := PostPositiveAdjustment(ItemNo, SalesLine.Quantity);
        PurchItemLedgEntryNo[2] := PostPositiveAdjustment(ItemNo, SalesLine.Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        InvItemLedgEntryNo[1] :=
          FindItemLedgEntryNo(ItemNo, ItemLedgerEntry."Entry Type"::Sale);

        // [GIVEN] Corrective Credit Memo "C1" cancelled Invoice "I1"
        FindLastSalesInvHeader(SalesInvHeader, SalesHeader."Bill-to Customer No.");
        CancelInvoice(SalesCrMemoHeader, SalesInvHeader);
        CrMemoItemLedgEntryNo[1] :=
          FindItemLedgEntryNo(ItemNo, ItemLedgerEntry."Entry Type"::Sale);

        // [GIVEN] Corrective Invoice "I2" cancelled Corrective Credit Memo "C1"
        CancelCrMemo(SalesCrMemoHeader);
        LibrarySmallBusiness.FindSalesCorrectiveInvoice(NewSalesInvHeader, SalesCrMemoHeader);
        InvItemLedgEntryNo[2] :=
          FindItemLedgEntryNo(ItemNo, ItemLedgerEntry."Entry Type"::Sale);
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Cancel Invoice "I1" second time with Corrective Credit Memo "C2"
        CancelInvoice(NewSalesCrMemoHeader, SalesInvHeader);
        CrMemoItemLedgEntryNo[2] :=
          FindItemLedgEntryNo(ItemNo, ItemLedgerEntry."Entry Type"::Sale);

        // [THEN] Positive Adjustment "A2" applied to Invoice "I2"
        VerifyItemApplicationEntry(InvItemLedgEntryNo[2], PurchItemLedgEntryNo[2], InvItemLedgEntryNo[2]);

        // [THEN] Positive Adjustment "A1" applied to Invoice "I1"
        VerifyItemApplicationEntry(InvItemLedgEntryNo[1], PurchItemLedgEntryNo[1], InvItemLedgEntryNo[1]);

        // [THEN] Corrective Credit Memo "C1" is unapplied
        VerifyItemApplicationEntry(CrMemoItemLedgEntryNo[1], CrMemoItemLedgEntryNo[1], 0);

        // [THEN] Corrective Credit Memo "I2" applied to invoice "I1"
        VerifyItemApplicationEntry(CrMemoItemLedgEntryNo[2], CrMemoItemLedgEntryNo[2], InvItemLedgEntryNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectiveInvoiceIsRoundedWhenCancelCrMemo()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Invoice Rounding]
        // [SCENARIO 169199] Corrective Invoice is rounded according to "Inv. Rounding Precision" when cancel Credit Memo

        Initialize();
        // [GIVEN] "Invoice Rounding Precision" is 1.00 in "General Ledger Setup"
        LibraryERM.SetInvRoundingPrecisionLCY(1);

        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemoWithFixedAmount(SalesCrMemoHeader);
        SalesCrMemoHeader.CalcFields("Amount Including VAT");
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Cancel Posted Credit Memo "B" with Corrective Invoice "C"
        CancelCrMemo(SalesCrMemoHeader);

        // [THEN] "Amount Including VAT" of Invoice "C" is 100
        LibrarySmallBusiness.FindSalesCorrectiveInvoice(SalesInvHeader, SalesCrMemoHeader);
        SalesInvHeader.CalcFields("Amount Including VAT");
        SalesInvHeader.TestField("Amount Including VAT", SalesCrMemoHeader."Amount Including VAT");

        // [THEN] Invoice Rounding Line exists in Invoice "C"
        VerifyInvRndLineExistsInSalesInvHeader(SalesInvHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectiveInvoiceFailsIfCancelCrMemoHasBlockedAccount()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Blocked]
        // [SCENARIO] Corrective Credit Memo fails to post if Invoice contains GLAccount, not allowed for direct posting.

        Initialize();
        // [GIVEN] "Invoice Rounding Precision" is 1.00 in "General Ledger Setup"
        LibraryERM.SetInvRoundingPrecisionLCY(1);

        // [GIVEN] Posted Invoice with GLAccounts 'A' and 'B' for 200
        CreateDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup());
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", 99.98);
        SalesLine.Modify(true);
        SalesLine."Line No." += 10000;
        SalesLine.Validate("No.", LibraryERM.CreateGLAccountWithPurchSetup());
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", 99.98);
        SalesLine.Insert(true);
        LibrarySmallBusiness.UpdateInvRoundingAccountWithSalesSetup(
          SalesHeader."Customer Posting Group", SalesHeader."Gen. Bus. Posting Group");
        SalesInvHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] GLAccount 'A' is not allowed for direct posting
        GLAccount.Get(SalesLine."No.");
        GLAccount.Validate("Direct Posting", false);
        GLAccount.Modify();
        Commit();

        // [WHEN] Cancel Invoice
        asserterror CancelInvoice(SalesCrMemoHeader, SalesInvHeader);
        // [THEN] Error message: 'G/L account 'A' does not allow direct posting.'
        Assert.ExpectedError(StrSubstNo(DirectPostingErr, GLAccount."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCorrectiveInvoiceFromPostedSalesCrMemoPage()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Invoice" on page "Posted Sales Credit Memo" open Corrective Invoice when called from canceled Credit Memo

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemoWithFixedAmount(SalesCrMemoHeader);

        // [GIVEN] Canceled Posted Credit Memo "A" with corrective Invoice "C"
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();
        CancelCrMemo(SalesCrMemoHeader);
        LibrarySmallBusiness.FindSalesCorrectiveInvoice(SalesInvHeader, SalesCrMemoHeader);

        // [GIVEN] Opened page "Posted Sales Credit Memo" with Credit Memo "B"
        PostedSalesInvoice.Trap();
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", SalesCrMemoHeader."No.");

        // [WHEN] Run action "Show Canceled/Corrective Invoice"
        PostedSalesCreditMemo.ShowInvoice.Invoke();

        // [THEN] "Posted Sales Invoice" page with Invoice "C" is opened
        PostedSalesInvoice."No.".AssertEquals(SalesInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCorrectiveInvoiceFromPostedSalesCrMemosPage()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Invoice" on page "Posted Sales Credit Memos" open Corrective Invoice when called from canceled Credit Memo

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemoWithFixedAmount(SalesCrMemoHeader);

        // [GIVEN] Canceled Posted Credit Memo "A" with corrective Invoice "C"
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();
        CancelCrMemo(SalesCrMemoHeader);
        LibrarySmallBusiness.FindSalesCorrectiveInvoice(SalesInvHeader, SalesCrMemoHeader);

        // [GIVEN] Opened page "Posted Sales Credit Memos" with Credit Memo "B"
        PostedSalesInvoice.Trap();
        PostedSalesCreditMemos.OpenView();
        PostedSalesCreditMemos.FILTER.SetFilter("No.", SalesCrMemoHeader."No.");

        // [WHEN] Run action "Show Canceled/Corrective Invoice"
        PostedSalesCreditMemos.ShowInvoice.Invoke();

        // [THEN] "Posted Sales Invoice" page with Invoice "C" is opened
        PostedSalesInvoice."No.".AssertEquals(SalesInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCanceledCrMemoFromPostedSalesInvoicePage()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Credit Memo" on page "Posted Sales Invoice" open Canceled Credit Memo when called from corrective Invoice

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemoWithFixedAmount(SalesCrMemoHeader);

        // [GIVEN] Canceled Posted Credit Memo "A" with corrective Invoice "C"
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();
        CancelCrMemo(SalesCrMemoHeader);
        LibrarySmallBusiness.FindSalesCorrectiveInvoice(SalesInvHeader, SalesCrMemoHeader);

        // [GIVEN] Opened page "Posted Sales Invoice" with Invoice "C"
        PostedSalesCreditMemo.Trap();
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", SalesInvHeader."No.");

        // [WHEN] Run action "Show Canceled/Corrective Credit Memo"
        PostedSalesInvoice.ShowCreditMemo.Invoke();

        // [THEN] "Posted Sales Credit Memo" with Credit Memo "B" is opened
        PostedSalesCreditMemo."No.".AssertEquals(SalesCrMemoHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCanceledCrMemoFromPostedSalesInvoicesPage()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Credit Memo" on page "Posted Sales Invoices" open Canceled Credit Memo when called from corrective Invoice

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemoWithFixedAmount(SalesCrMemoHeader);

        // [GIVEN] Canceled Posted Credit Memo "A" with corrective Invoice "C"
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();
        CancelCrMemo(SalesCrMemoHeader);
        LibrarySmallBusiness.FindSalesCorrectiveInvoice(SalesInvHeader, SalesCrMemoHeader);

        // [GIVEN] Opened page "Posted Sales Invoice" with Invoice "C"
        PostedSalesCreditMemo.Trap();
        PostedSalesInvoices.OpenView();
        PostedSalesInvoices.FILTER.SetFilter("No.", SalesInvHeader."No.");

        // [WHEN] Run action "Show Canceled/Corrective Credit Memo"
        PostedSalesInvoices.ShowCreditMemo.Invoke();

        // [THEN] "Posted Sales Credit Memo" page with Credit Memo "B" is opened
        PostedSalesCreditMemo."No.".AssertEquals(SalesCrMemoHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_NotPossibleToCancelRegularSalesCreditMemo()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 172717] It should not be possible to cancel regular Sales Credit Memo

        Initialize();

        // [GIVEN] Posted Sales Credit Memo "X"
        PostCrMemo(SalesCrMemoHeader);
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Cancel Sales Credit Memo "X"
        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.GotoRecord(SalesCrMemoHeader);

        // [THEN] Cancel action cannot be clicked
        Assert.IsFalse(PostedSalesCreditMemo.CancelCrMemo.Visible(), 'User can cancel a non-corrective sales credit memo.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToCorrectInvoiceWithFixedAsset()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        FANo: Code[20];
    begin
        // [FEATURE] [Fixed Asset]
        // [SCENARIO 206572] Stan cannot correct Posted Sales Invoice with Fixed Asset

        Initialize();

        // [GIVEN] Posted Purchase Invoice with Fixed Asset (Acquisition)
        FANo := PostPurchInvWithFixedAsset();

        // [GIVEN] Posted Sales Invoice with Fixed Asset (Disposal)
        PostSalesOrderWithFixedAsset(SalesInvHeader, FANo);

        // [WHEN] Correct Posted Sales Invoice
        asserterror CODEUNIT.Run(CODEUNIT::"Correct PstdSalesInv (Yes/No)", SalesInvHeader);

        // [THEN] Error message "You cannot cancel this posted sales invoice because it contains lines with type = Fixed Asset" is thrown
        Assert.ExpectedError(FixedAssetNotPossibleToCreateCreditMemoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToCancelInvoiceWithFixedAsset()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        FANo: Code[20];
    begin
        // [FEATURE] [Fixed Asset]
        // [SCENARIO 206572] Stan cannot cancel Posted Sales Invoice with Fixed Asset

        Initialize();

        // [GIVEN] Posted Purchase Invoice with Fixed Asset (Acquisition)
        FANo := PostPurchInvWithFixedAsset();

        // [GIVEN] Posted Sales Invoice with Fixed Asset (Disposal)
        PostSalesOrderWithFixedAsset(SalesInvHeader, FANo);

        // [WHEN] Cancel Posted Sales Invoice
        asserterror CancelInvoice(SalesCrMemoHeader, SalesInvHeader);

        // [THEN] Error message "You cannot cancel this posted sales invoice because it contains lines with type = Fixed Asset" is thrown
        Assert.ExpectedError(FixedAssetNotPossibleToCreateCreditMemoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToCreateCorrectiveCreditMemo()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        FANo: Code[20];
    begin
        // [FEATURE] [Corrective Credit Memo] [Fixed Asset]
        // [SCENARIO 206572] Stan cannot create Corrective Sales Credit Memo for Posted Sales Invoice with Fixed Asset

        Initialize();

        // [GIVEN] Posted Purchase Invoice with Fixed Asset (Acquisition)
        FANo := PostPurchInvWithFixedAsset();

        // [GIVEN] Posted Sales Invoice with Fixed Asset (Disposal)
        PostSalesOrderWithFixedAsset(SalesInvHeader, FANo);

        // [WHEN] Create Corrective Sales Credit Memo
        asserterror CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvHeader, SalesHeader);

        // [THEN] Error message "You cannot cancel this posted sales invoice because it contains lines with type = Fixed Asset" is thrown
        Assert.ExpectedError(FixedAssetNotPossibleToCreateCreditMemoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanCancelSalesCrMemoWithServiceItemWhenCOGSAccountIsEmpty()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelPostedSalesCrMemo: Codeunit "Cancel Posted Sales Cr. Memo";
    begin
        // [FEATURE] [Sales] [Credit Memo] [UT]
        // [SCENARIO 322909] Cassie can cancel Posted Sales Credit Memo with Item of Type Service when COGS account is empty in General Posting Setup.
        Initialize();

        CancelInvoiceByCreditMemoWithItemType(SalesCrMemoHeader, Item.Type::Service, GeneralPostingSetup);
        CleanCOGSAccountOnGenPostingSetup(GeneralPostingSetup);
        Commit();

        CancelPostedSalesCrMemo.TestCorrectCrMemoIsAllowed(SalesCrMemoHeader);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanCancelSalesCrMemoWithNonInventoryItemWhenCOGSAccountIsEmpty()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelPostedSalesCrMemo: Codeunit "Cancel Posted Sales Cr. Memo";
    begin
        // [FEATURE] [Sales] [Credit Memo] [UT]
        // [SCENARIO 322909] Cassie can cancel Posted Sales Credit Memo with Item of Type Non-Inventory when COGS account is empty in General Posting Setup.
        Initialize();

        CancelInvoiceByCreditMemoWithItemType(SalesCrMemoHeader, Item.Type::"Non-Inventory", GeneralPostingSetup);
        CleanCOGSAccountOnGenPostingSetup(GeneralPostingSetup);
        Commit();

        CancelPostedSalesCrMemo.TestCorrectCrMemoIsAllowed(SalesCrMemoHeader);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CantCancelSalesCrMemoWithInventoryItemWhenCOGSAccountIsEmpty()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelPostedSalesCrMemo: Codeunit "Cancel Posted Sales Cr. Memo";
    begin
        // [FEATURE] [Sales] [Credit Memo] [UT]
        // [SCENARIO 322909] Cassie can't cancel Posted Sales Credit Memo with Item of Type Inventory when COGS account is empty in General Posting Setup.
        Initialize();

        CancelInvoiceByCreditMemoWithItemType(SalesCrMemoHeader, Item.Type::Inventory, GeneralPostingSetup);
        CleanCOGSAccountOnGenPostingSetup(GeneralPostingSetup);
        Commit();

        asserterror CancelPostedSalesCrMemo.TestCorrectCrMemoIsAllowed(SalesCrMemoHeader);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
            LibraryErrorMessage.GetMissingAccountErrorMessage(
                GeneralPostingSetup.FieldCaption("COGS Account"),
                GeneralPostingSetup));

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure NewCanCancelSalesCrMemoWithNonInventoryItemWhenCOGSAccountIsEmpty()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Resource: Record Resource;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        LibraryResource: Codeunit "Library - Resource";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [SCENARIO 458011] Posted Sales Invoice cannot be canceled if line type = Resource
        Initialize();

        // [GIVEN] Create Resource, create Sales Invoice and post
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryResource.CreateResourceNew(Resource);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Cancel posted sales invoice
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);
        LibrarySmallBusiness.FindSalesCorrectiveCrMemo(SalesCrMemoHeader, SalesInvoiceHeader);
        SalesCrMemoHeader.CalcFields(Corrective);
        SalesInvoiceHeader.CalcFields(Cancelled);

        // [VERIFY] Verify: Posted Sales Invoice cancelled successfuly and related Sales corrective Credit Memo posted
        Assert.AreEqual(
            SalesInvoiceHeader.Cancelled,
            SalesCrMemoHeader.Corrective,
            StrSubstNo(PostedSalesInvoiceNotCancelledErr, SalesInvoiceHeader."No."));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Sales Correct Cr. Memo");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Sales Correct Cr. Memo");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdateFAPostingType();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Sales Correct Cr. Memo");
    end;

    local procedure CancelInvoiceByCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        PostSalesInvoice(SalesInvHeader);
        CancelInvoice(SalesCrMemoHeader, SalesInvHeader);
    end;

    local procedure CancelInvoiceByCreditMemoWithFixedAmount(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        CreateDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, CreateItemNo());
        SalesLine.Validate("Unit Price", 99.98);
        SalesLine.Modify(true);
        LibrarySmallBusiness.UpdateInvRoundingAccountWithSalesSetup(
          SalesHeader."Customer Posting Group", SalesHeader."Gen. Bus. Posting Group");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesInvHeader.FindLast();
        CancelInvoice(SalesCrMemoHeader, SalesInvHeader);
    end;

    local procedure CancelInvoiceByCreditMemoWithItemType(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; ItemType: Enum "Item Type"; var GeneralPostingSetup: Record "General Posting Setup")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, ItemType);
        Item.Validate("Unit Price", LibraryRandom.RandInt(10));
        Item.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CancelInvoice(SalesCrMemoHeader, SalesInvoiceHeader);
    end;

    local procedure PostPurchInvWithFixedAsset() FANo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        FANo := CreateFixedAsset();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FANo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(FANo);
    end;

    local procedure PostSalesInvoice(var SalesInvHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        PostDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesInvHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesInvHeader.FindLast();
    end;

    local procedure PostCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        PostDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        SalesCrMemoHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesCrMemoHeader.FindLast();
    end;

    local procedure PostDocument(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateDocument(SalesHeader, SalesLine, DocType, SalesLine.Type::Item, CreateItemNo());
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PostDocumentWithVariant(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        ItemVariant: Record "Item Variant";
    begin
        CreateDocument(SalesHeader, SalesLine, DocType, SalesLine.Type::Item, CreateItemNo());
        LibraryInventory.CreateItemVariant(ItemVariant, SalesLine."No.");
        SalesLine."Variant Code" := ItemVariant.Code;
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PostSalesOrderWithFixedAsset(var SalesInvHeader: Record "Sales Invoice Header"; FANo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FANo, LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        SalesInvHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, LineType, ItemNo, LibraryRandom.RandInt(100));
    end;

    local procedure CancelInvoice(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesInvHeader: Record "Sales Invoice Header")
    var
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader);
        LibrarySmallBusiness.FindSalesCorrectiveCrMemo(SalesCrMemoHeader, SalesInvHeader);
    end;

    local procedure CancelCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CancelPostedSalesCrMemo: Codeunit "Cancel Posted Sales Cr. Memo";
    begin
        CancelPostedSalesCrMemo.CancelPostedCrMemo(SalesCrMemoHeader);
    end;

    local procedure CleanCOGSAccountOnGenPostingSetup(var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Copy(OldGeneralPostingSetup);
        GeneralPostingSetup.Validate("COGS Account", '');
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateItemNo(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := LibraryRandom.RandDec(100, 2);
        Item.Modify();
        exit(Item."No.");
    end;

    local procedure CreateItemNoWithFIFO(): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItemNo());
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Modify();
        exit(Item."No.");
    end;

    local procedure CreateInvtPeriod(var InventoryPeriod: Record "Inventory Period")
    begin
        InventoryPeriod.Init();
        InventoryPeriod."Ending Date" := CalcDate('<+1D>', WorkDate());
        InventoryPeriod.Closed := true;
        InventoryPeriod.Insert();
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        FASetup.Get();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure MockDtldCustLedgEntry(CustLedgEntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntryNo;
        DetailedCustLedgEntry."Entry Type" := EntryType;
        DetailedCustLedgEntry.Insert();
    end;

    local procedure BlockCustomer(CustNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustNo);
        Customer.Validate(Blocked, Customer.Blocked::Invoice);
        Customer.Modify(true);
    end;

    local procedure BlockItemOfSalesCrMemo(var Item: Record Item; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst();
        Item.Get(SalesCrMemoLine."No.");
        Item.Validate(Blocked, true);
        Item.Modify(true);
    end;

    local procedure BlockItemVariantOfSalesCrMemo(var ItemVariant: Record "Item Variant"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst();
        ItemVariant.Get(SalesCrMemoLine."No.", SalesCrMemoLine."Variant Code");
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);
    end;

    local procedure UnapplyDocument(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, DocType, DocNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure PostApplyUnapplyInvoiceToCrMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.Insert(true);
        CopyDocMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocMgt.CopySalesDoc("Sales Document Type From"::"Posted Credit Memo", SalesCrMemoHeader."No.", SalesHeader);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgEntry, CustLedgEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, true, true));
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure PostApplyUnapplyInvoiceToCrMemoWithSpecificAmount(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; Amount: Decimal; Unapply: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, GenJnlLine."Document Type"::Invoice, GenJnlLine."Account Type"::Customer,
          SalesCrMemoHeader."Bill-to Customer No.", Amount);
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::"Credit Memo");
        GenJnlLine.Validate("Applies-to Doc. No.", SalesCrMemoHeader."No.");
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        if Unapply then begin
            LibraryERM.FindCustomerLedgerEntry(
              CustLedgEntry, CustLedgEntry."Document Type"::Invoice, GenJnlLine."Document No.");
            LibraryERM.UnapplyCustomerLedgerEntry(CustLedgEntry);
        end;
    end;

    local procedure PostPositiveAdjustment(ItemNo: Code[20]; Quantity: Decimal): Integer
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(FindItemLedgEntryNo(ItemNo, ItemLedgerEntry."Entry Type"::"Positive Adjmt."));
    end;

    local procedure RestoreGenPostingSetup(OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(OldGeneralPostingSetup."Gen. Bus. Posting Group", OldGeneralPostingSetup."Gen. Prod. Posting Group");
        GeneralPostingSetup."COGS Account" := OldGeneralPostingSetup."COGS Account";
        GeneralPostingSetup.Modify();
    end;

    local procedure TurnoffStockoutWarning()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure FindLastSalesInvHeader(var SalesInvHeader: Record "Sales Invoice Header"; CustNo: Code[20])
    begin
        SalesInvHeader.SetRange("Bill-to Customer No.", CustNo);
        SalesInvHeader.FindLast();
    end;

    local procedure FindItemLedgEntryNo(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"): Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Entry Type", EntryType);
        ItemLedgEntry.FindLast();
        exit(ItemLedgEntry."Entry No.");
    end;

    local procedure VerifyAmountEqualRemainingAmount(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, DocType, DocNo);
        CustLedgEntry.CalcFields(Amount, "Remaining Amount");
        CustLedgEntry.TestField("Remaining Amount", CustLedgEntry.Amount);
    end;

    local procedure VerifyZeroRemainingAmount(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, DocType, DocNo);
        CustLedgEntry.CalcFields("Remaining Amount");
        CustLedgEntry.TestField("Remaining Amount", 0);
    end;

    local procedure VerifyCancellationDescrInSaleInvLine(SalesInvHeader: Record "Sales Invoice Header")
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.FindFirst();
        SalesInvLine.SetRange(Type, SalesInvLine.Type::" ");
        SalesInvLine.TestField(Description, StrSubstNo(CrMemoCancellationTxt, SalesInvHeader."Applies-to Doc. No."));
    end;

    local procedure VerifyInvCrMemoCancelledDocument(InvNo: Code[20]; CrMemoNo: Code[20])
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        CancelledDocument.Get(DATABASE::"Sales Invoice Header", InvNo);
        CancelledDocument.TestField("Cancelled By Doc. No.", CrMemoNo);
    end;

    local procedure VerifyCrMemoInvCancelledDocument(CrMemoNo: Code[20]; InvNo: Code[20])
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        CancelledDocument.Get(DATABASE::"Sales Cr.Memo Header", CrMemoNo);
        CancelledDocument.TestField("Cancelled By Doc. No.", InvNo);
    end;

    local procedure VerifyCancelledDocumentDoesNotExist(InvNo: Code[20])
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        Assert.IsFalse(CancelledDocument.FindSalesCorrectiveCrMemo(InvNo), '');
    end;

    local procedure VerifyItemApplicationEntry(ItemLedgEntryNo: Integer; InbndItemLedgEntryNo: Integer; OutbndItemLedgEntryNo: Integer)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", InbndItemLedgEntryNo);
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", OutbndItemLedgEntryNo);
        Assert.IsFalse(ItemApplicationEntry.IsEmpty, IncorrectItemApplicationErr);
    end;

    local procedure VerifyInvRndLineExistsInSalesInvHeader(SalesInvHeader: Record "Sales Invoice Header")
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        SalesInvLine.SetRange("No.", SalesInvHeader."No.");
        SalesInvLine.SetRange(Type, SalesInvLine.Type::"G/L Account");
        SalesInvLine.SetRange("No.",
          LibrarySales.GetInvRoundingAccountOfCustPostGroup(SalesInvHeader."Customer Posting Group"));
        Assert.IsFalse(SalesInvLine.IsEmpty, InvRoundingLineDoesNotExistErr);
    end;

    [ModalPageHandler]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

