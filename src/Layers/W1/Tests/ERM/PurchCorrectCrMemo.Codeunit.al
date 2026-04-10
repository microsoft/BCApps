codeunit 137028 "Purch. Correct Cr. Memo"
{
    Permissions = tabledata "Detailed Vendor Ledg. Entry" = rim;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Cancelled Document] [Credit Memo] [Purchase]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        IsInitialized: Boolean;
        BlockedVendorErr: Label 'You cannot cancel this posted purchase credit memo because vendor %1 is blocked.', Comment = '%1 = Customer No.';
        AlreadyCancelledErr: Label 'You cannot cancel this posted purchase credit memo because it has already been cancelled.';
        NotCorrectiveDocErr: Label 'You cannot cancel this posted purchase credit memo because it is not a corrective document.';
        InvtPeriodClosedErr: Label 'You cannot cancel this posted purchase credit memo because the inventory period is already closed.';
        PostPeriodClosedErr: Label 'You cannot cancel this posted purchase credit memo because it was posted in a posting period that is closed.';
        BlockedItemErr: Label 'You cannot cancel this posted purchase credit memo because item %1 %2 is blocked.';
        NotCorrDocErr: Label 'You cannot cancel this posted purchase invoice because it represents a correction of a credit memo.';
        NotAppliedCorrectlyErr: Label 'You cannot cancel this posted purchase credit memo because it is not fully applied to an invoice.';
        CrMemoCancellationTxt: Label 'Cancellation of credit memo %1.', Comment = '%1 = Credit Memo No.';
        IncorrectItemApplicationErr: Label 'Incorrect item application.';
        InvRoundingLineDoesNotExistErr: Label 'Invoice rounding line does not exist.';
        DirectPostingErr: Label 'G/L account %1 does not allow direct posting.', Comment = '%1 - g/l account no.';

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCrMemoIfVendorIsBlocked()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if "Pay-To Vendor No." is blocked

        Initialize();
        // [GIVEN] Posted Credit Memo cancelled Invoice with Vendor "X"
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Blocked Vendor "X"
        BlockVendor(PurchCrMemoHdr."Pay-to Vendor No.");
        LibraryLowerPermissions.SetPurchDocsPost();

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(PurchCrMemoHdr);

        // [THEN] Error message "You cannot cancel this posted purchase credit memo because Vendor X is blocked" is raised
        Assert.ExpectedError(StrSubstNo(BlockedVendorErr, PurchCrMemoHdr."Pay-to Vendor No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCrMemoIfVendorIsPrivacyBlocked()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if "Pay-To Vendor No." is blocked

        Initialize();
        // [GIVEN] Posted Credit Memo cancelled Invoice with Vendor "X"
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Privacy Blocked Vendor "X"
        Vendor.Get(PurchCrMemoHdr."Pay-to Vendor No.");
        Vendor.Validate("Privacy Blocked", true);
        Vendor.Modify(true);
        LibraryLowerPermissions.SetPurchDocsPost();

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(PurchCrMemoHdr);

        // [THEN] Error message "You cannot cancel this posted purchase credit memo because Vendor X is blocked" is raised
        Assert.ExpectedError(StrSubstNo(BlockedVendorErr, PurchCrMemoHdr."Pay-to Vendor No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCrMemoIfPostingDateNotAllowed()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if "Posting Date" is outside of allowed posting period from General Ledger Setup

        Initialize();
        // [GIVEN] Posted Credit Memo cancelled Invoice with "Posting Date" = 01.01
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);

        // [GIVEN] "Allow Posting From" = 02.01 in General Ledger Setup
        LibraryERM.SetAllowPostingFromTo(PurchCrMemoHdr."Posting Date" + 1, 0D);
        LibraryLowerPermissions.SetPurchDocsPost();

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(PurchCrMemoHdr);

        // [THEN] Error message "You cannot cancel this posted purchase credit memo because it was posted in a posting period that is closed" is raised
        Assert.ExpectedError(PostPeriodClosedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCrMemoIfAlreadyCancelled()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if it was already cancelled

        Initialize();
        // [GIVEN] Posted Credit Memo cancelled Invoice
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Cancelled and unapplied Posted Credit Memo
        PurchCrMemoHdr.Find();
        CancelCrMemo(PurchCrMemoHdr);
        LibraryLowerPermissions.SetPurchDocsPost();

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(PurchCrMemoHdr);

        // [THEN] Error message "You cannot cancel this posted purchase credit memo because it has already been cancelled" is raised
        Assert.ExpectedError(AlreadyCancelledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCrMemoIfNotCorrectiveDoc()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if it's not corrective document

        Initialize();
        // [GIVEN] Posted Credit Memo
        PostCrMemo(PurchCrMemoHdr);
        LibraryLowerPermissions.SetPurchDocsPost();

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(PurchCrMemoHdr);

        // [THEN] Error message "You cannot cancel this posted purchase credit memo because it is not corrective document" is raised
        Assert.ExpectedError(NotCorrectiveDocErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCrMemoIfInvPostPeriodIsClosed()
    var
        InventoryPeriod: Record "Inventory Period";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if Inventory Period is closed

        Initialize();
        // [GIVEN] Posted Credit Memo cancelled Invoice with "Posting Date" = 01.01
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Closed Inventoty Period with "Posting Date" = 31.01
        CreateInvtPeriod(InventoryPeriod);
        Commit();
        LibraryLowerPermissions.SetPurchDocsPost();

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(PurchCrMemoHdr);

        // [THEN] Error message "You cannot cancel this posted purchase invoice because the inventory period is already closed" is raised
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
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if item is blocked

        Initialize();
        // [GIVEN] Posted Credit Memo cancelled Invoice with Item = "X"
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Blocked Item "X"
        BlockItemOfPurchCrMemo(Item, PurchCrMemoHdr);
        LibraryLowerPermissions.SetPurchDocsPost();

        // [WHEN] Cancel Posted Credit Memo
        asserterror CancelCrMemo(PurchCrMemoHdr);

        // [THEN] You cannot cancel this posted purchase invoice because item X is blocked.
        Assert.ExpectedError(StrSubstNo(BlockedItemErr, Item."No.", Item.Description));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCorrectiveInvoice()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        NewPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel corrective Purchase Invoice

        Initialize();
        // [GIVEN] Posted Credit Memo "B1" cancelled Invoice "A1"
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Posted Invoice "A2" cancelled Credit Memo "B1"
        CancelCrMemo(PurchCrMemoHdr);
        LibrarySmallBusiness.FindPurchCorrectiveInvoice(PurchInvHeader, PurchCrMemoHdr);
        LibraryLowerPermissions.SetPurchDocsPost();

        // [WHEN] Cancel Posted Invoice "A2"
        asserterror CancelInvoice(NewPurchCrMemoHdr, PurchInvHeader);

        // [THEN] Error message "You cannot cancel this posted purchase invoice because it is corrective document to credit memo" is raised
        Assert.ExpectedError(NotCorrDocErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCancelCreditMemoIfInvoiceAppliedPartially()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if invoice applied partially

        Initialize();
        // [GIVEN] Posted unapplied Credit Memo "B" cancelled Invoice "A" with Amount = 100
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);
        UnapplyDocument(VendLedgEntry."Document Type"::"Credit Memo", PurchCrMemoHdr."No.");
        PurchCrMemoHdr.CalcFields("Amount Including VAT");

        // [GIVEN] Applied Invoice "C" to Credit Memo "B" with Amount = 50
        PostApplyUnapplyInvoiceToCrMemoWithSpecificAmount(
          PurchCrMemoHdr, -Round(PurchCrMemoHdr."Amount Including VAT" / LibraryRandom.RandIntInRange(3, 5)), false);
        Commit();
        LibraryLowerPermissions.SetPurchDocsPost();

        // [WHEN] Cancel Posted Credi Memo "B" with corrective Invoice "D"
        asserterror CancelCrMemo(PurchCrMemoHdr);

        // [THEN] Error message "You cannot cancel this posted purchase credit memo because it is not fully applied to invoice" is raised
        Assert.ExpectedError(NotAppliedCorrectlyErr);
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure UT_CannotCancelCreditMemoIfDetailedEntryDifferentFromInitialOrApplication()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // [FEATURE] [UT] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo if there are detailed entries applied different from "Initial Entry" and "Application"

        Initialize();
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::"Credit Memo", PurchCrMemoHdr."No.");
        MockDtldVendLedgEntry(VendLedgEntry."Entry No.", DetailedVendLedgEntry."Entry Type"::"Realized Gain");
        Commit();
        asserterror CancelCrMemo(PurchCrMemoHdr);
        Assert.ExpectedError(NotAppliedCorrectlyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelPurchCrMemoWithGLAccInLine()
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        PostedPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PostedPurchInvoiceHeader: Record "Purch. Inv. Header";
    begin
        // [SCENARIO] Bug 444060 Check of General Posting Setup in CancelPostedPurchCrMemo
        Initialize();

        // [GIVEN] A G/L Account 
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());

        // [GIVEN] A General Business Posting Group and a General Posting Setup using that group
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GenPostingSetup, GenBusPostingGroup.Code, GLAccount."Gen. Prod. Posting Group");
        GenPostingSetup.SuggestSetupAccounts();

        // [GIVEN] The General Posting Setup has no value for Purchase
        GenPostingSetup."Purch. Account" := '';
        GenPostingSetup.Modify();

        // [GIVEN] A vendor with the given General Business Posting Group
        LibrarySmallBusiness.CreateVendor(Vendor);

        // [GIVEN] A purchase invoice is posted for this Vendor specifying a G/L account in the line
        CreateAndPostGlAccPurchInv(PostedPurchInvoiceHeader, Vendor."No.", GLAccount);

        // [GIVEN] The invoice is corrected 
        CancelInvoice(PostedPurchCrMemoHeader, PostedPurchInvoiceHeader);

        // [WHEN] The related Posted Purchase Credit Memo is cancelled
        CancelCrMemo(PostedPurchCrMemoHeader);

        // [THEN] No errors occur on cancelling
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelCorrectiveCreditMemo()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        OrigPurchInvHeader: Record "Purch. Inv. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 168492] Corrective Invoice is generated when cancel Corrective Credit Memo

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJobs();
        // [WHEN] Cancel Posted Credit Memo "B"
        CancelCrMemo(PurchCrMemoHdr);

        // [THEN] No Cancelled Document for Posted Invoice "A"
        OrigPurchInvHeader.Get(PurchCrMemoHdr."Applies-to Doc. No.");
        VerifyCancelledDocumentDoesNotExist(OrigPurchInvHeader."No.");

        // [THEN] Posted Invoice "A" is unapplied
        VerifyAmountEqualRemainingAmount(VendLedgEntry."Document Type"::Invoice, OrigPurchInvHeader."No.");

        // [THEN] Posted Invoice "C" is copied from Posted Credit Memo "B"
        LibrarySmallBusiness.FindPurchCorrectiveInvoice(PurchInvHeader, PurchCrMemoHdr);

        // [THEN] First purchase Invoice Line has blank type and description "Cancellation of Credit Memo B"
        VerifyCancellationDescrInSaleInvLine(PurchInvHeader);

        // [THEN] Cancelled Document exists for Posted Invoice "C" - Posted Credit Memo "B"
        VerifyCrMemoInvCancelledDocument(PurchCrMemoHdr."No.", PurchInvHeader."No.");

        // [THEN] Posted Invoice "C" is applied to Posted Credit Memo "B" ("Remaining Amount" = 0)
        VerifyZeroRemainingAmount(VendLedgEntry."Document Type"::Invoice, PurchInvHeader."No.");
        VerifyZeroRemainingAmount(VendLedgEntry."Document Type"::"Credit Memo", PurchCrMemoHdr."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelCreditMemoAfterUnapplication()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Unapplication]
        // [SCENARIO 168492] Corrective Invoice is generated when unapply corrective credit memo from invoice before the cancellation

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Posted Invoice "A" and Posted Credit Memo "B" are unapplied
        UnapplyDocument(VendLedgEntry."Document Type"::"Credit Memo", PurchCrMemoHdr."No.");
        Commit();
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Cancel Posted Credit Memo "B"
        CancelCrMemo(PurchCrMemoHdr);

        // [THEN] Posted Invoice "C" that cancelled Posted Credit Memo "B" is generated
        LibrarySmallBusiness.FindPurchCorrectiveInvoice(PurchInvHeader, PurchCrMemoHdr);

        // [THEN] Cancelled Document exists for Posted Invoice "C" - Posted Credit Memo "B"
        VerifyCrMemoInvCancelledDocument(PurchCrMemoHdr."No.", PurchInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelCreditMemoAfterFullyApplyUnapplySingleInvoice()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        NewPurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CancelledDocument: Record "Cancelled Document";
    begin
        // [FEATURE] [Unapplication]
        // [SCENARIO 168492] Corrective Invoice is generated when there is invoice different from original fully applied and unapplied to this credit memo before cancellation
        Initialize();

        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A" with Amount = 100
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);
        CancelledDocument.FindPurchCorrectiveCrMemo(PurchCrMemoHdr."No.");
        UnapplyDocument(VendLedgEntry."Document Type"::"Credit Memo", PurchCrMemoHdr."No.");

        // [GIVEN] Unapplied Invoice "C" to Credit Memo "B" with Amount = 100
        PostApplyUnapplyInvoiceToCrMemo(PurchCrMemoHdr);
        FindLastPurchInvHeader(PurchInvHeader, PurchCrMemoHdr."Pay-to Vendor No.");
        Commit();
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Cancel Posted Credit Memo "B"
        CancelCrMemo(PurchCrMemoHdr);

        // [THEN] Corrective Invoice "D" is generated
        FindLastPurchInvHeader(NewPurchInvHeader, PurchCrMemoHdr."Pay-to Vendor No.");

        // [THEN] Cancelled Document is generated (Invoice = "D", "Credit Memo" = "B")
        VerifyCrMemoInvCancelledDocument(PurchCrMemoHdr."No.", NewPurchInvHeader."No.");

        // [THEN] No Cancelled Document with Invoice = "C"
        Assert.IsFalse(
          CancelledDocument.FindPurchCancelledInvoice(PurchInvHeader."No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelOriginallInvoiceSecondTimeAfterCrMemoCancellation()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        NewPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        OrigPurchInvHeader: Record "Purch. Inv. Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 168492] It is possible to cancel original invoice after the corrective credit memo applied to this invoice was cancelled

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);
        OrigPurchInvHeader.Get(PurchCrMemoHdr."Applies-to Doc. No.");
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [GIVEN] cancelled Posted Credit Memo "B"
        CancelCrMemo(PurchCrMemoHdr);

        // [WHEN] Cancel Invoice "A" by Credit Memo "C"
        OrigPurchInvHeader.Find();
        CancelInvoice(NewPurchCrMemoHdr, OrigPurchInvHeader);

        // [THEN] Cancelled Document exists for Posted Invoice "A" - Posted Credit Memo "C"
        VerifyInvCrMemoCancelledDocument(OrigPurchInvHeader."No.", NewPurchCrMemoHdr."No.");

        // [THEN] Posted Credit Memo "C" is applied to Posted Invoice "A" ("Remaining Amount" = 0)
        VerifyZeroRemainingAmount(VendLedgEntry."Document Type"::Invoice, OrigPurchInvHeader."No.");
        VerifyZeroRemainingAmount(VendLedgEntry."Document Type"::"Credit Memo", NewPurchCrMemoHdr."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelCreditMemoAfterApplyUnapplyMultipleInvoices()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CancelledDocument: Record "Cancelled Document";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PartialAmount: Decimal;
    begin
        // [FEATURE] [Unapplication] [Cancellation Not Allowed]
        // [SCENARIO 168492] It's not possible to cancel Posted Credit Memo when there are other multiple invoices applied and unapplied fully to this credit memo before cancellation

        Initialize();

        // [GIVEN] Posted unapplied Credit Memo "B" cancelled Invoice "A" with Amount = 100
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);
        UnapplyDocument(VendLedgEntry."Document Type"::"Credit Memo", PurchCrMemoHdr."No.");
        PurchCrMemoHdr.CalcFields("Amount Including VAT");

        // [GIVEN] Unapplied Invoices "C" and "D" to Credit Memo "B" with total Amount = 100
        PartialAmount := Round(PurchCrMemoHdr."Amount Including VAT" / LibraryRandom.RandIntInRange(3, 5));
        PostApplyUnapplyInvoiceToCrMemoWithSpecificAmount(PurchCrMemoHdr, -PartialAmount, true);
        PostApplyUnapplyInvoiceToCrMemoWithSpecificAmount(
          PurchCrMemoHdr, -PurchCrMemoHdr."Amount Including VAT" + PartialAmount, true);
        Commit();
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Cancel Posted Credi Memo "B" with corrective Invoice "E"
        CancelCrMemo(PurchCrMemoHdr);

        // [THEN] Cancelled Document for Posted Credit Memo "B" exists
        Assert.IsTrue(
          CancelledDocument.FindPurchCancelledCrMemo(PurchCrMemoHdr."No."), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UI_CancelCorrectiveCreditMemoFromPostedPurchCreditMemosPage()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchCreditMemos: TestPage "Posted Purchase Credit Memos";
        PostedPurchInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 168492] Action "Cancel Credit Memo" on "Posted Purchase Credit Memos" page should cancel current Credit Memo

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Open "Posted Purchase Credit Memos" page
        PostedPurchInvoice.Trap();
        PostedPurchCreditMemos.OpenEdit();
        PostedPurchCreditMemos.FILTER.SetFilter("No.", PurchCrMemoHdr."No.");
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Run action "Cancel Credit Memo" on "B"
        PostedPurchCreditMemos.CancelCrMemo.Invoke();

        // [THEN] "cancelled" is Yes on "Posted Credit Memos" page, action Cancel is invisible, action 'Show Invoice' is visible
        PostedPurchCreditMemos.Cancelled.AssertEquals(true);
        Assert.IsFalse(PostedPurchCreditMemos.CancelCrMemo.Visible(), 'CancelCrMemo must be invisible');
        Assert.IsTrue(PostedPurchCreditMemos.ShowInvoice.Visible(), 'ShowInvoice must be visible');

        // [THEN] "Corrective" is Yes on "Posted Invoice" page
        PostedPurchInvoice.Corrective.AssertEquals(true);

        // [THEN] Posted Invoice "C" that cancelled Posted Credit Memo "B" is generated
        LibrarySmallBusiness.FindPurchCorrectiveInvoice(PurchInvHeader, PurchCrMemoHdr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UI_CancelCorrectiveCreditMemoFromPostedPurchCreditMemoPage()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchCreditMemo: TestPage "Posted Purchase Credit Memo";
        PostedPurchInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 168492] Action "Cancel Credit Memo" on "Posted Purchase Credit Memo" page should cancel current Credit Memo

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemo(PurchCrMemoHdr);

        // [GIVEN] Open "Posted Purchase Credit Memo" page
        PostedPurchInvoice.Trap();
        PostedPurchCreditMemo.OpenEdit();
        PostedPurchCreditMemo.FILTER.SetFilter("No.", PurchCrMemoHdr."No.");
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Run action "Cancel Credit Memo" on "B"
        PostedPurchCreditMemo.CancelCrMemo.Invoke();

        // [THEN] "cancelled" is Yes on "Posted Credit Memo" page, action Cancel is invisible, action 'Show Invoice' is visible
        PostedPurchCreditMemo.Cancelled.AssertEquals(true);
        Assert.IsFalse(PostedPurchCreditMemo.CancelCrMemo.Visible(), 'CancelCrMemo must be invisible');
        Assert.IsTrue(PostedPurchCreditMemo.ShowInvoice.Visible(), 'ShowInvoice must be visible');

        // [THEN] "Corrective" is Yes on "Posted Invoice" page
        PostedPurchInvoice.Corrective.AssertEquals(true);

        // [THEN] Posted Invoice "C" that cancelled Posted Credit Memo "B" is generated
        LibrarySmallBusiness.FindPurchCorrectiveInvoice(PurchInvHeader, PurchCrMemoHdr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostApplicationAfterReapplyOnSecondInvoiceCancellation()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        NewPurchInvHeader: Record "Purch. Inv. Header";
        NewPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ItemNo: Code[20];
        InvItemLedgEntryNo: array[2] of Integer;
        CrMemoItemLedgEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [SCM] [Cost Application] [Item Application Entry]
        // [SCENARIO 168492] Cost application posted correctly after reapply when cancel Purchase Invoice second time

        Initialize();
        // [GIVEN] Positive Adjustment "A1"
        // [GIVEN] Positive Adjustment "A2"
        // [GIVEN] Invoice "I1"
        ItemNo := CreateItemNoWithFIFO();
        CreateDocument(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, PurchLine.Type::Item, ItemNo);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        InvItemLedgEntryNo[1] := FindItemLedgEntryNo(ItemNo);

        // [GIVEN] Corrective Credit Memo "C1" cancelled Invoice "I1"
        FindLastPurchInvHeader(PurchInvHeader, PurchHeader."Pay-to Vendor No.");
        CancelInvoice(PurchCrMemoHdr, PurchInvHeader);
        CrMemoItemLedgEntryNo[1] := FindItemLedgEntryNo(ItemNo);

        // [GIVEN] Corrective Invoice "I2" cancelled Corrective Credit Memo "C1"
        CancelCrMemo(PurchCrMemoHdr);
        LibrarySmallBusiness.FindPurchCorrectiveInvoice(NewPurchInvHeader, PurchCrMemoHdr);
        InvItemLedgEntryNo[2] := FindItemLedgEntryNo(ItemNo);
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Cancel Invoice "I1" second time with Corrective Credit Memo "C2"
        CancelInvoice(NewPurchCrMemoHdr, PurchInvHeader);
        CrMemoItemLedgEntryNo[2] := FindItemLedgEntryNo(ItemNo);

        // [THEN] Corrective Credit Memo "I2" applied to invoice "I1"
        VerifyItemApplicationEntry(CrMemoItemLedgEntryNo[2], InvItemLedgEntryNo[1], CrMemoItemLedgEntryNo[2]);
        // [THEN] Corrective Credit Memo "I1" applied to invoice "I2"
        VerifyItemApplicationEntry(CrMemoItemLedgEntryNo[1], InvItemLedgEntryNo[2], CrMemoItemLedgEntryNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectiveInvoiceIsRoundedWhenCancelCrMemo()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [Invoice Rounding]
        // [SCENARIO 169199] Corrective Invoice is rounded according to "Inv. Rounding Precision" when cancel Credit Memo

        Initialize();
        // [GIVEN] "Invoice Rounding Precision" is 1.00 in "General Ledger Setup"
        LibraryERM.SetInvRoundingPrecisionLCY(1);

        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemoWithFixedAmount(PurchCrMemoHdr);
        PurchCrMemoHdr.CalcFields("Amount Including VAT");
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJobs();

        // [WHEN] Cancel Posted Credit Memo "B" with Corrective Invoice "C"
        CancelCrMemo(PurchCrMemoHdr);

        // [THEN] "Amount Including VAT" of Invoice "C" is 100
        LibrarySmallBusiness.FindPurchCorrectiveInvoice(PurchInvHeader, PurchCrMemoHdr);
        PurchInvHeader.CalcFields("Amount Including VAT");
        PurchInvHeader.TestField("Amount Including VAT", PurchCrMemoHdr."Amount Including VAT");

        // [THEN] Invoice Rounding Line exists in Invoice "C"
        VerifyInvRndLineExistsInPurchInvHeader(PurchInvHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectiveInvoiceFailsIfCancelCrMemoHasBlockedAccount()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Blocked]
        // [SCENARIO] Corrective Credit Memo fails to post if Invoice contains GLAccount, not allowed for direct posting.

        Initialize();
        // [GIVEN] "Invoice Rounding Precision" is 1.00 in "General Ledger Setup"
        LibraryERM.SetInvRoundingPrecisionLCY(1);

        // [GIVEN] Posted Invoice with GLAccounts 'A' and 'B' for 200
        CreateDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup());
        PurchaseLine.Validate(Quantity, 1);
        PurchaseLine.Validate("Direct Unit Cost", 99.98);
        PurchaseLine.Modify(true);
        PurchaseLine."Line No." += 10000;
        PurchaseLine.Validate("No.", LibraryERM.CreateGLAccountWithPurchSetup());
        PurchaseLine.Validate(Quantity, 1);
        PurchaseLine.Validate("Direct Unit Cost", 99.98);
        PurchaseLine.Insert(true);
        LibrarySmallBusiness.UpdateInvRoundingAccountWithPurchSetup(
          PurchaseHeader."Vendor Posting Group", PurchaseHeader."Gen. Bus. Posting Group");
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] GLAccount 'A' is not allowed for direct posting
        GLAccount.Get(PurchaseLine."No.");
        GLAccount.Validate("Direct Posting", false);
        GLAccount.Modify();
        Commit();

        // [WHEN] Cancel Invoice
        asserterror CancelInvoice(PurchCrMemoHdr, PurchInvHeader);
        // [THEN] Error message: 'G/L account 'A' does not allow direct posting.'
        Assert.ExpectedError(StrSubstNo(DirectPostingErr, GLAccount."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCorrectiveInvoiceFromPostedPurchCrMemoPage()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Invoice" on page "Posted Purchase Credit Memo" open Corrective Invoice when called from canceled Credit Memo

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemoWithFixedAmount(PurchCrMemoHdr);

        // [GIVEN] Canceled Posted Credit Memo "A" with corrective Invoice "C"
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJobs();
        CancelCrMemo(PurchCrMemoHdr);
        LibrarySmallBusiness.FindPurchCorrectiveInvoice(PurchInvHeader, PurchCrMemoHdr);

        // [GIVEN] Opened page "Posted Purchase Credit Memo" with Credit Memo "B"
        PostedPurchaseInvoice.Trap();
        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.FILTER.SetFilter("No.", PurchCrMemoHdr."No.");

        // [WHEN] Run action "Show Canceled/Corrective Invoice"
        PostedPurchaseCreditMemo.ShowInvoice.Invoke();

        // [THEN] "Posted Purchase Invoice" page with Invoice "C" is opened
        PostedPurchaseInvoice."No.".AssertEquals(PurchInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCorrectiveInvoiceFromPostedPurchCrMemosPage()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedPurchaseCreditMemos: TestPage "Posted Purchase Credit Memos";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Invoice" on page "Posted Purchase Credit Memos" open Corrective Invoice when called from canceled Credit Memo

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemoWithFixedAmount(PurchCrMemoHdr);

        // [GIVEN] Canceled Posted Credit Memo "A" with corrective Invoice "C"
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJobs();
        CancelCrMemo(PurchCrMemoHdr);
        LibrarySmallBusiness.FindPurchCorrectiveInvoice(PurchInvHeader, PurchCrMemoHdr);

        // [GIVEN] Opened page "Posted Purchase Credit Memos" with Credit Memo "B"
        PostedPurchaseInvoice.Trap();
        PostedPurchaseCreditMemos.OpenView();
        PostedPurchaseCreditMemos.FILTER.SetFilter("No.", PurchCrMemoHdr."No.");

        // [WHEN] Run action "Show Canceled/Corrective Invoice"
        PostedPurchaseCreditMemos.ShowInvoice.Invoke();

        // [THEN] "Posted Purchase Invoice" page with Invoice "C" is opened
        PostedPurchaseInvoice."No.".AssertEquals(PurchInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCanceledCrMemoFromPostedPurchInvoicePage()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Credit Memo" on page "Posted Purchase Invoice" open Canceled Credit Memo when called from corrective Invoice

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemoWithFixedAmount(PurchCrMemoHdr);

        // [GIVEN] Canceled Posted Credit Memo "A" with corrective Invoice "C"
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJobs();
        CancelCrMemo(PurchCrMemoHdr);
        LibrarySmallBusiness.FindPurchCorrectiveInvoice(PurchInvHeader, PurchCrMemoHdr);

        // [GIVEN] Opened page "Posted Purchase Invoice" with Invoice "C"
        PostedPurchaseCreditMemo.Trap();
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.FILTER.SetFilter("No.", PurchInvHeader."No.");

        // [WHEN] Run action "Show Canceled/Corrective Credit Memo"
        PostedPurchaseInvoice.ShowCreditMemo.Invoke();

        // [THEN] "Posted Purchase Credit Memo" with Credit Memo "B" is opened
        PostedPurchaseCreditMemo."No.".AssertEquals(PurchCrMemoHdr."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCanceledCrMemoFromPostedPurchInvoicesPage()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Credit Memo" on page "Posted Purchase Invoices" open Canceled Credit Memo when called from corrective Invoice

        Initialize();
        // [GIVEN] Posted Credit Memo "B" cancelled Invoice "A"
        CancelInvoiceByCreditMemoWithFixedAmount(PurchCrMemoHdr);

        // [GIVEN] Canceled Posted Credit Memo "A" with corrective Invoice "C"
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJobs();
        CancelCrMemo(PurchCrMemoHdr);
        LibrarySmallBusiness.FindPurchCorrectiveInvoice(PurchInvHeader, PurchCrMemoHdr);

        // [GIVEN] Opened page "Posted Purchase Invoice" with Invoice "C"
        PostedPurchaseCreditMemo.Trap();
        PostedPurchaseInvoices.OpenView();
        PostedPurchaseInvoices.FILTER.SetFilter("No.", PurchInvHeader."No.");

        // [WHEN] Run action "Show Canceled/Corrective Credit Memo"
        PostedPurchaseInvoices.ShowCreditMemo.Invoke();

        // [THEN] "Posted Purchase Credit Memo" page with Credit Memo "B" is opened
        PostedPurchaseCreditMemo."No.".AssertEquals(PurchCrMemoHdr."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_NotPossibleToCancelRegularPurchCreditMemo()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 172717] It should not be possible to cancel regular Purchase Credit Memo

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo "X"
        PostCrMemo(PurchCrMemoHdr);
        LibraryLowerPermissions.SetPurchDocsPost();

        // [WHEN] Cancel Purchase Credit Memo "X"
        PostedPurchCreditMemo.OpenEdit();
        PostedPurchCreditMemo.GotoRecord(PurchCrMemoHdr);

        // [THEN] Cancel action cannot be clicked
        Assert.IsFalse(PostedPurchCreditMemo.CancelCrMemo.Visible(), 'User can cancel a non-corrective purchase credit memo.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanCancelPurchaseCrMemoWithServiceItemWhenCOGSAccountIsEmpty()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CancelPostedPurchCrMemo: Codeunit "Cancel Posted Purch. Cr. Memo";
    begin
        // [FEATURE] [Purchase] [Credit Memo] [UT]
        // [SCENARIO 322909] Cassie can cancel Posted Purchase Credit Memo with Item of Type Service when COGS account is empty in General Posting Setup.
        Initialize();

        CancelInvoiceByCreditMemoWithItemType(PurchCrMemoHdr, Item.Type::Service, GeneralPostingSetup);
        CleanCOGSAccountOnGenPostingSetup(GeneralPostingSetup);
        Commit();

        CancelPostedPurchCrMemo.TestCorrectCrMemoIsAllowed(PurchCrMemoHdr);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanCancelPurchaseCrMemoWithNonInventoryItemWhenCOGSAccountIsEmpty()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CancelPostedPurchCrMemo: Codeunit "Cancel Posted Purch. Cr. Memo";
    begin
        // [FEATURE] [Purchase] [Credit Memo] [UT]
        // [SCENARIO 322909] Cassie can cancel Posted Purchase Credit Memo with Item of Type Non-Inventory when COGS account is empty in General Posting Setup.
        Initialize();

        CancelInvoiceByCreditMemoWithItemType(PurchCrMemoHdr, Item.Type::"Non-Inventory", GeneralPostingSetup);
        CleanCOGSAccountOnGenPostingSetup(GeneralPostingSetup);
        Commit();

        CancelPostedPurchCrMemo.TestCorrectCrMemoIsAllowed(PurchCrMemoHdr);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CantCancelPurchaseCrMemoWithInventoryItemWhenCOGSAccountIsEmpty()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CancelPostedPurchCrMemo: Codeunit "Cancel Posted Purch. Cr. Memo";
    begin
        // [FEATURE] [Purchase] [Credit Memo] [UT]
        // [SCENARIO 322909] Cassie can't cancel Posted Purchase Credit Memo with Item of Type Inventory when COGS account is empty in General Posting Setup.
        Initialize();

        CancelInvoiceByCreditMemoWithItemType(PurchCrMemoHdr, Item.Type::Inventory, GeneralPostingSetup);
        CleanCOGSAccountOnGenPostingSetup(GeneralPostingSetup);
        Commit();

        asserterror CancelPostedPurchCrMemo.TestCorrectCrMemoIsAllowed(PurchCrMemoHdr);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
            LibraryErrorMessage.GetMissingAccountErrorMessage(
                GeneralPostingSetup.FieldCaption("COGS Account"),
                GeneralPostingSetup));

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Purch. Correct Cr. Memo");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Purch. Correct Cr. Memo");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Purch. Correct Cr. Memo");
    end;

    local procedure CreateAndPostGlAccPurchInv(var PostedPurchInvoiceHeader: Record "Purch. Inv. Header"; VendorNo: Code[20]; var GLAccount: Record "G/L Account")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Ensure that Purchase & Payables Setup has a No. Code for Posted Invoices
        LibraryPurchase.SetPostedNoSeriesInSetup();

        // Create a purchase invoice with one line of type G/L Account
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, "Purchase Line Type"::"G/L Account");
        PurchaseLine.Validate("No.", GLAccount."No.");
        PurchaseLine.Validate(Quantity, 1);
        PurchaseLine.Validate("Direct Unit Cost", 1);
        PurchaseLine.Modify();

        // Post the Purchase Invoice
        PostedPurchInvoiceHeader."No." := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        PostedPurchInvoiceHeader.Find();
    end;

    local procedure CancelInvoiceByCreditMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PostPurchInvoice(PurchInvHeader);
        CancelInvoice(PurchCrMemoHdr, PurchInvHeader);
    end;

    local procedure CancelInvoiceByCreditMemoWithFixedAmount(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        CreateDocument(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, PurchLine.Type::Item, LibraryInventory.CreateItemNo());
        PurchLine.Validate("Direct Unit Cost", 99.98);
        PurchLine.Modify(true);
        LibrarySmallBusiness.UpdateInvRoundingAccountWithPurchSetup(
          PurchHeader."Vendor Posting Group", PurchHeader."Gen. Bus. Posting Group");
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchHeader."No.");
        PurchInvHeader.FindLast();
        CancelInvoice(PurchCrMemoHdr, PurchInvHeader);
    end;

    local procedure CancelInvoiceByCreditMemoWithItemType(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; ItemType: Enum "Item Type"; var GeneralPostingSetup: Record "General Posting Setup")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, ItemType);
        Item.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        CancelInvoice(PurchCrMemoHdr, PurchInvHeader);
    end;

    local procedure CleanCOGSAccountOnGenPostingSetup(var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Copy(OldGeneralPostingSetup);
        GeneralPostingSetup.Validate("COGS Account", '');
        GeneralPostingSetup.Modify(true);
    end;

    local procedure PostPurchInvoice(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PostDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchInvHeader.FindLast();
    end;

    local procedure PostCrMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PostDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        PurchCrMemoHdr.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchCrMemoHdr.FindLast();
    end;

    local procedure PostDocument(var PurchHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type")
    var
        PurchLine: Record "Purchase Line";
    begin
        CreateDocument(PurchHeader, PurchLine, DocType, PurchLine.Type::Item, LibraryInventory.CreateItemNo());
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
    end;

    local procedure CreateDocument(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; LineType: Enum "Purchase Line Type"; ItemNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocType, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, LineType, ItemNo, LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
    end;

    local procedure CancelInvoice(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchInvHeader: Record "Purch. Inv. Header")
    var
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        LibrarySmallBusiness.FindPurchCorrectiveCrMemo(PurchCrMemoHdr, PurchInvHeader);
    end;

    local procedure CancelCrMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        CancelPostedPurchCrMemo: Codeunit "Cancel Posted Purch. Cr. Memo";
    begin
        CancelPostedPurchCrMemo.CancelPostedCrMemo(PurchCrMemoHdr);
    end;

    local procedure CreateItemNoWithFIFO(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
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

    local procedure MockDtldVendLedgEntry(VendLedgEntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendLedgEntry.Init();
        DetailedVendLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedVendLedgEntry, DetailedVendLedgEntry.FieldNo("Entry No."));
        DetailedVendLedgEntry."Vendor Ledger Entry No." := VendLedgEntryNo;
        DetailedVendLedgEntry."Entry Type" := EntryType;
        DetailedVendLedgEntry.Insert();
    end;

    local procedure BlockVendor(VendNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendNo);
        Vendor.Validate(Blocked, Vendor.Blocked::All);
        Vendor.Modify(true);
    end;

    local procedure BlockItemOfPurchCrMemo(var Item: Record Item; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange(Type, PurchCrMemoLine.Type::Item);
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");
        PurchCrMemoLine.FindFirst();
        Item.Get(PurchCrMemoLine."No.");
        Item.Validate(Blocked, true);
        Item.Modify(true);
    end;

    local procedure UnapplyDocument(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, DocType, DocNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure PostApplyUnapplyInvoiceToCrMemo(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
    begin
        PurchHeader.Init();
        PurchHeader.Validate("Document Type", PurchHeader."Document Type"::Invoice);
        PurchHeader.Insert(true);
        CopyDocMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocMgt.CopyPurchDoc("Purchase Document Type From"::"Posted Credit Memo", PurchCrMemoHdr."No.", PurchHeader);
        PurchHeader."Vendor Invoice No." := PurchHeader."No.";
        PurchHeader.Modify(true);
        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, VendLedgEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure PostApplyUnapplyInvoiceToCrMemoWithSpecificAmount(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; Amount: Decimal; Unapply: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, GenJnlLine."Document Type"::Invoice, GenJnlLine."Account Type"::Vendor,
          PurchCrMemoHdr."Pay-to Vendor No.", Amount);
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::"Credit Memo");
        GenJnlLine.Validate("Applies-to Doc. No.", PurchCrMemoHdr."No.");
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        if Unapply then begin
            LibraryERM.FindVendorLedgerEntry(
              VendLedgEntry, VendLedgEntry."Document Type"::Invoice, GenJnlLine."Document No.");
            LibraryERM.UnapplyVendorLedgerEntry(VendLedgEntry);
        end;
    end;

    local procedure FindLastPurchInvHeader(var PurchInvHeader: Record "Purch. Inv. Header"; VendNo: Code[20])
    begin
        PurchInvHeader.SetRange("Pay-to Vendor No.", VendNo);
        PurchInvHeader.FindLast();
    end;

    local procedure FindItemLedgEntryNo(ItemNo: Code[20]): Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Purchase);
        ItemLedgEntry.FindLast();
        exit(ItemLedgEntry."Entry No.");
    end;

    local procedure RestoreGenPostingSetup(OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(OldGeneralPostingSetup."Gen. Bus. Posting Group", OldGeneralPostingSetup."Gen. Prod. Posting Group");
        GeneralPostingSetup."COGS Account" := OldGeneralPostingSetup."COGS Account";
        GeneralPostingSetup.Modify();
    end;

    local procedure VerifyAmountEqualRemainingAmount(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, DocType, DocNo);
        VendLedgEntry.CalcFields(Amount, "Remaining Amount");
        VendLedgEntry.TestField("Remaining Amount", VendLedgEntry.Amount);
    end;

    local procedure VerifyZeroRemainingAmount(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, DocType, DocNo);
        VendLedgEntry.CalcFields("Remaining Amount");
        VendLedgEntry.TestField("Remaining Amount", 0);
    end;

    local procedure VerifyCancellationDescrInSaleInvLine(PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
        PurchInvLine.SetRange(Type, PurchInvLine.Type::" ");
        PurchInvLine.TestField(Description, StrSubstNo(CrMemoCancellationTxt, PurchInvHeader."Applies-to Doc. No."));
    end;

    local procedure VerifyInvCrMemoCancelledDocument(InvNo: Code[20]; CrMemoNo: Code[20])
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        CancelledDocument.Get(DATABASE::"Purch. Inv. Header", InvNo);
        CancelledDocument.TestField("Cancelled By Doc. No.", CrMemoNo);
    end;

    local procedure VerifyCrMemoInvCancelledDocument(CrMemoNo: Code[20]; InvNo: Code[20])
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        CancelledDocument.Get(DATABASE::"Purch. Cr. Memo Hdr.", CrMemoNo);
        CancelledDocument.TestField("Cancelled By Doc. No.", InvNo);
    end;

    local procedure VerifyCancelledDocumentDoesNotExist(InvNo: Code[20])
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        Assert.IsFalse(CancelledDocument.FindPurchCorrectiveCrMemo(InvNo), '');
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

    local procedure VerifyInvRndLineExistsInPurchInvHeader(PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("No.", PurchInvHeader."No.");
        PurchInvLine.SetRange(Type, PurchInvLine.Type::"G/L Account");
        PurchInvLine.SetRange("No.",
          LibraryPurchase.GetInvRoundingAccountOfVendPostGroup(PurchInvHeader."Vendor Posting Group"));
        Assert.IsFalse(PurchInvLine.IsEmpty, InvRoundingLineDoesNotExistErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

