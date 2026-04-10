codeunit 137025 "SCM Purchase Correct Invoice"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cancelled Document] [Invoice] [Purchase]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJob: Codeunit "Library - Job";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ItemTrackingMode: Option "Assign Lot No.","Select Entries";
        IsInitialized: Boolean;
        WasConfirmShown: Boolean;
        CancelledDocExistsErr: Label 'Cancelled document exists.';
        CannotAssignNumbersAutoErr: Label 'It is not possible to assign numbers automatically. If you want the program to assign numbers automatically, please activate Default Nos.';
        CorrectPostedInvoiceFromSingleOrderQst: Label 'The invoice was posted from an order. The invoice will be cancelled, and the order will open so that you can make the correction.\ \Do you want to continue?';
        TransactionTypeErr: Label 'Transaction Type are not equal';
        TransportMethodErr: Label 'Transport Method are not equal';
        CommentCountErr: Label 'Wrong Purchase Line Count';
        ConfirmDialogErr: Label 'Expected confirm dialog was not shown';

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceCostReversing()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        Vend: Record Vendor;
        PurchaseHeaderCorrection: Record "Purchase Header";
        LastItemLedgEntry: Record "Item Ledger Entry";
        PreviousItemLedgEntry: Record "Item Ledger Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        Initialize();

        if GLEntry.FindLast() then;

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Vendor, 1, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, Vendor);

        PreviousItemLedgEntry.FindLast();

        // EXERCISE
        TurnOffExactCostReversing();
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY: The correction must use Exact Cost reversing
        LastItemLedgEntry.FindLast();
        Assert.AreEqual(
          LastItemLedgEntry."Applies-to Entry", PreviousItemLedgEntry."Entry No.",
          'Return should be applied to initial entry');

        CheckEverythingIsReverted(Item, Vendor, GLEntry);

        // VERIFY: Check exact reversing work even when new costs are introduced
        LibraryPurch.CreateVendor(Vend);
        CreateAndPostPurchInvForItem(PurchaseHeader, Vend, Item, 1, 1);

        CheckEverythingIsReverted(Item, Vendor, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIncludingGLAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeaderTmp: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreatePurchaseInvForNewItemAndVendor(Item, Vendor, 1, 1, PurchaseHeader, PurchaseLine);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 1);
        PurchaseLine.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate(Type, PurchaseLine.Type::" ");
        PurchaseLine.Modify(true);

        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        GLEntry.FindLast();

        // EXERCISE
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderTmp);
        CheckEverythingIsReverted(Item, Vendor, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingDateInvtBlocked()
    var
        Vend: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderTmp: Record "Purchase Header";
        InvtPeriod: Record "Inventory Period";
        GLEntry: Record "G/L Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        Initialize();

        CreateItemWithCost(Item, 0);

        LibraryPurch.CreateVendor(Vend);
        PurchInvHeader.Get(CreateAndPostPurchInvForItem(PurchaseHeader, Vend, Item, 1, 1));

        LibraryCosting.AdjustCostItemEntries('', '');

        InvtPeriod.Init();
        InvtPeriod."Ending Date" := CalcDate('<+1D>', WorkDate());
        InvtPeriod.Closed := true;
        InvtPeriod.Insert();
        Commit();

        GLEntry.FindLast();

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderTmp);
        InvtPeriod.Delete();
        Commit();

        CheckNothingIsCreated(Vend, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerVerify')]
    procedure TestGetShptInvoiceFromOrder()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        CorrectPstdPurchInvYesNo: Codeunit "Correct PstdPurchInv (Yes/No)";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        PurchaseOrderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO] It is be possible to cancel a get shipment invoice that is associated to an order
        Initialize();

        CreateItemWithCost(Item, 1);
        LibraryPurchase.CreateVendor(Vendor);

        CreatePurchaseOrderForItem(Vendor, Item, 1, PurchaseHeaderOrder, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true));
        Commit();

        GLEntry.FindLast();

        LibraryVariableStorage.Enqueue(CorrectPostedInvoiceFromSingleOrderQst);
        LibraryVariableStorage.Enqueue(true);

        PurchaseOrderPage.Trap();

        CorrectPstdPurchInvYesNo.CorrectInvoice(PurchInvHeader);

        PurchaseOrderPage."No.".AssertEquals(PurchaseHeaderOrder."No.");
        PurchaseOrderPage.Close();

        CheckEverythingIsReverted(Item, Vendor, GLEntry);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemTracking()
    var
        PurchaseHeader: Record "Purchase Header";
        Vend: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        ReservEntry: Record "Reservation Entry";
        PurchaseHeaderCorrection: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreateItemWithCost(Item, 1);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), Item."No.", 1, '', 0D);
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservEntry, PurchaseLine, '', 'LOT1', 1);
        GLEntry.FindLast();

        PurchaseLine.Find();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY
        Vend.Get(PurchInvHeader."Buy-from Vendor No.");
        CheckEverythingIsReverted(Item, Vend, GLEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestJobNo()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        Job: Record Job;
        JobTask: Record "Job Task";
        GLEntry: Record "G/L Entry";
        PurchaseHeaderCorrection: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreatePurchaseInvForNewItemAndVendor(Item, Vendor, 1, 1, PurchaseHeader, PurchaseLine);

        CreateJobwithJobTask(Job, JobTask);
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // CHECK IT IS POSSIBLE TO REVERT A JOBS RELATED INVOICE
        GLEntry.FindLast();
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY
        CheckEverythingIsReverted(Item, Vendor, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemLedgEntryApplied()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PurchaseHeaderCorrection: Record "Purchase Header";
        LastItemLedgEntry: Record "Item Ledger Entry";
        PreviousItemLedgEntry: Record "Item Ledger Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Vendor, 0, 1, PurchInvHeader);

        PreviousItemLedgEntry.FindLast();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        PurchaseLine.Validate("Appl.-to Item Entry", PreviousItemLedgEntry."Entry No.");
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LastItemLedgEntry.FindLast();
        Assert.AreEqual(LastItemLedgEntry."Applies-to Entry", PreviousItemLedgEntry."Entry No.",
          'Return should be applied to initial entry');

        GLEntry.FindLast();
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(Vendor, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelInvoiceAfterApplyUnapplyToCreditMemo()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        NewPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CancelledDocument: Record "Cancelled Document";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO 168492] Corrective Credit Memo is generated when there are other credit memos applied and unapplied to invoice before cancellation

        Initialize();
        // [GIVEN] Posted Invoice "A"
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Vend, 1, 1, PurchInvHeader);

        // [GIVEN] Unapplied Credit Memo "B"
        PostApplyUnapplyCreditMemoToInvoice(PurchInvHeader);
        PurchCrMemoHdr.SetRange("Pay-to Vendor No.", PurchInvHeader."Pay-to Vendor No.");
        PurchCrMemoHdr.FindLast();
        Commit();
        LibraryLowerPermissions.SetPurchDocsPost();

        // [WHEN] Cancel Posted Invoice "A"
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // [THEN] Corrective Credit Memo "C" is generated
        NewPurchCrMemoHdr.SetRange("Pay-to Vendor No.", PurchInvHeader."Pay-to Vendor No.");
        NewPurchCrMemoHdr.FindLast();

        // [THEN] Cancelled Document is generated (Invoice = "A", "Credit Memo" = "C")
        CancelledDocument.Get(DATABASE::"Purch. Inv. Header", PurchInvHeader."No.");
        CancelledDocument.TestField("Cancelled By Doc. No.", NewPurchCrMemoHdr."No.");

        // [THEN] No Cancelled Document with "Credit Memo" = "B"
        Assert.IsFalse(
          CancelledDocument.FindPurchCorrectiveCrMemo(PurchCrMemoHdr."No."), CancelledDocExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoInvoiceRoundingWhenCorrectInvoice()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Invoice Rounding]
        // [SCENARIO 169199] No invoice rounding is assigned to new Invoice when correct original invoice

        Initialize();
        // [GIVEN] "Invoice Rounding Precision" is 1.00 in "General Ledger Setup" and On in Payables Setup
        SetInvoiceRounding();

        // [GIVEN] Posted Invoice "A" with total amount = 100 (Amount Including VAT is 99.98, Invoice Rounding Line is 0.02)
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Vendor, 99.98, 1, PurchInvHeader);
        LibrarySmallBusiness.UpdateInvRoundingAccountWithSalesSetup(
          PurchInvHeader."Vendor Posting Group", PurchInvHeader."Gen. Bus. Posting Group");
        ExpectedAmount := GetAmountInclVATOfPurchInvLine(PurchInvHeader);
        LibraryLowerPermissions.SetPurchDocsPost();
        Commit();

        // [WHEN] Correct Posted Invoice "A" with new Invoice "B"
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchHeader);

        // [THEN] "Amount Including VAT" of Invoice "B" is 99.98
        PurchHeader.CalcFields("Amount Including VAT");
        PurchHeader.TestField("Amount Including VAT", ExpectedAmount);

        // [THEN] Invoice Rounding Line does not exist in Invoice "B"
        VerifyInvRndLineDoesNotExistInPurchHeader(PurchHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectiveCrMemoIsRoundedWhenCancelInvoice()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Invoice Rounding]
        // [SCENARIO 169199] Corrective Credit Memo is rounded according to "Inv. Rounding Precision" when cancel Invoice

        Initialize();
        // [GIVEN] "Invoice Rounding Precision" is 1.00 in "General Ledger Setup" and On in Payables Setup
        SetInvoiceRounding();

        // [GIVEN] Posted Invoice "A" with total amount = 100 (Amount Including VAT is 99.98, Invoice Rounding Line is 0.02)
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Vendor, 9.99, 1, PurchInvHeader);
        LibrarySmallBusiness.UpdateInvRoundingAccountWithSalesSetup(
          PurchInvHeader."Vendor Posting Group", PurchInvHeader."Gen. Bus. Posting Group");
        PurchInvHeader.CalcFields("Amount Including VAT");
        LibraryLowerPermissions.SetPurchDocsPost();
        Commit();

        // [WHEN] Cancel Posted Invoice "A" with Corrective Credit Memo "B"
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // [THEN] "Amount Including VAT" of Credit Memo "B" is 100
        LibrarySmallBusiness.FindPurchCorrectiveCrMemo(PurchCrMemoHdr, PurchInvHeader);
        PurchCrMemoHdr.CalcFields("Amount Including VAT");
        PurchCrMemoHdr.TestField("Amount Including VAT", PurchInvHeader."Amount Including VAT");

        // [THEN] Invoice Rounding Line exists in Invoice "B"
        VerifyInvRndLineExistsInPurchCrMemoHeader(PurchCrMemoHdr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCorrectiveCrMemoFromPostedPurchInvoicePage()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Credit Memo" on page "Posted Purchase Invoice" open Corrective Credit Memo when called from canceled Purchase Invoice

        Initialize();
        // [GIVEN] Posted Invoice "A"
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Vend, 1, 1, PurchInvHeader);

        // [GIVEN] Canceled Posted Invoice "A" with corrective Credit Memo "B"
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        LibrarySmallBusiness.FindPurchCorrectiveCrMemo(PurchCrMemoHdr, PurchInvHeader);

        // [GIVEN] Opened page "Posted Purchase Invoice" with Invoice "A"
        PostedPurchaseCreditMemo.Trap();
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.FILTER.SetFilter("No.", PurchInvHeader."No.");

        // [WHEN] Run action "Show Canceled/Corrective Credit Memo"
        PostedPurchaseInvoice.ShowCreditMemo.Invoke();

        // [THEN] "Posted Purchase Credit Memo" page with Credit Memo "B" is opened
        PostedPurchaseCreditMemo."No.".AssertEquals(PurchCrMemoHdr."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCorrectiveCrMemoFromPostedPurchInvoicesPage()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Credit Memo" on page "Posted Purchase Invoices" open Corrective Credit Memo when called from canceled Purchase Invoice

        Initialize();
        // [GIVEN] Posted Invoice "A"
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Vend, 1, 1, PurchInvHeader);

        // [GIVEN] Canceled Posted Invoice "A" with corrective Credit Memo "B"
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        LibrarySmallBusiness.FindPurchCorrectiveCrMemo(PurchCrMemoHdr, PurchInvHeader);

        // [GIVEN] Opened page "Posted Purchase Invoices" with Invoice "A"
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
    procedure UI_ShowCanceledInvoiceFromPostedPurchCrMemoPage()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Invoice" on page "Posted Purchase Credit Memo" open Canceled Invoice when called from Corrective Purchase Credit Memo

        Initialize();
        // [GIVEN] Posted Invoice "A"
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Vend, 1, 1, PurchInvHeader);

        // [GIVEN] Canceled Posted Invoice "A" with corrective Credit Memo "B"
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        LibrarySmallBusiness.FindPurchCorrectiveCrMemo(PurchCrMemoHdr, PurchInvHeader);

        // [GIVEN] Opened page "Posted Purchase Credit Memo" with Credit Memo "B"
        PostedPurchaseInvoice.Trap();
        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.FILTER.SetFilter("No.", PurchCrMemoHdr."No.");

        // [WHEN] Run action "Show Canceled/Corrective Invoice"
        PostedPurchaseCreditMemo.ShowInvoice.Invoke();

        // [THEN] "Posted Purchase Invoice" page with Invoice "A" is opened
        PostedPurchaseInvoice."No.".AssertEquals(PurchInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ShowCanceledInvoiceFromPostedPurchCrMemosPage()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedPurchaseCreditMemos: TestPage "Posted Purchase Credit Memos";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 170460] Action "Show Canceled/Corrective Invoice" on page "Posted Purchase Credit Memos" open Canceled Invoice when called from Corrective Purchase Credit Memo

        Initialize();
        // [GIVEN] Posted Invoice "A"
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Vend, 1, 1, PurchInvHeader);

        // [GIVEN] Canceled Posted Invoice "A" with corrective Credit Memo "B"
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        LibrarySmallBusiness.FindPurchCorrectiveCrMemo(PurchCrMemoHdr, PurchInvHeader);

        // [GIVEN] Opened page "Posted Purchase Credit Memos" with Credit Memo "B"
        PostedPurchaseInvoice.Trap();
        PostedPurchaseCreditMemos.OpenView();
        PostedPurchaseCreditMemos.FILTER.SetFilter("No.", PurchCrMemoHdr."No.");

        // [WHEN] Run action "Show Canceled/Corrective Invoice"
        PostedPurchaseCreditMemos.ShowInvoice.Invoke();

        // [THEN] "Posted Purchase Invoice" page with Invoice "A" is opened
        PostedPurchaseInvoice."No.".AssertEquals(PurchInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDescriptionLineWithCancelledInvNoInNewInvoice()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchHeader: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO 171281] There is no blank line with description about copied-from document when correct Purchase Invoice

        Initialize();
        // [GIVEN] Posted Purchase Invoice "A"
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Vend, 1, 1, PurchInvHeader);

        // [WHEN] Correct Purchase Invoice "A" with new Purchase Invoice "B"
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchHeader);

        // [THEN] No description line in Purchase Invoice "B"
        VerifyBlankLineDoesNotExist(PurchHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PossibleToCorrectInvoiceWithAmountRoundedToZero()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchHeader: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Invoice Rounding]
        // [SCENARIO 172718] Not possible to correct Posted Purchase Invoice with amount rounded to zero

        Initialize();

        // [GIVEN] Invoice Rounding Precision is 1,00 in General Ledger Setup
        LibraryPurchase.SetInvoiceRounding(true);
        LibraryERM.SetInvRoundingPrecisionLCY(1);

        // [GIVEN] Posted Purchase Invoice with original Amount = 0.01 rounded to zero by Invoice Rounding Precision
        CreateAndPostPurchInvWithCustomAmount(PurchInvHeader, 0.01);

        // [WHEN] Correct Posted Purchase Invoice
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchHeader);
    end;

    [Test]
    [HandlerFunctions('NoSeriesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithNonDefaultNoSeriesWithRelation()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchHeader: Record "Purchase Header";
        NoSeries: Record "No. Series";
        RelatedNoSeries: Record "No. Series";
        RelatedNoSeriesLine: Record "No. Series Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        LibraryNoSeries: Codeunit "Library - No. Series";
        ExpectedCrMemoNo: Code[20];
    begin
        // [FEATURE] [Corrective Credit Memo] [No. Series]
        // [SCENARIO 210983] Stan can select no. series for Corrective Credit Memo if no. series from "Credit Memo Nos." in Purchase Setup is not "Default Nos" and has relations

        Initialize();

        // [GIVEN] Posted Invoice
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Vend, 1, 1, PurchInvHeader);

        // [GIVEN] No. Series "Y" with "Default Nos" = Yes and no. series line setup
        LibraryUtility.CreateNoSeries(RelatedNoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(RelatedNoSeriesLine, RelatedNoSeries.Code, '', '');
        LibraryVariableStorage.Enqueue(RelatedNoSeries.Code);
        ExpectedCrMemoNo := LibraryUtility.GetNextNoFromNoSeries(RelatedNoSeries.Code, WorkDate());

        // [GIVEN] No. Series "X" with "Default Nos" = No and related No. series "Y". Next "No." in no. series is "X1"
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, RelatedNoSeries.Code);

        // [GIVEN] "Credit Memo Nos." in Purchase Setup is "X"
        SetCreditMemoNosInPurchSetup(NoSeries.Code);

        // [WHEN] Create Corrective Credit Memo for Purchase Invoice "A" and specify "No. Series" = "Y" from "No. Series" page
        // No. Series selection handles by NoSeriesListModalPageHandler
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchHeader);

        // [THEN] Corrective Credit Memo created with "No." = "X1"
        PurchHeader.TestField("No.", ExpectedCrMemoNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithDefaultNoSeries()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Item: Record Item;
        Vend: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchHeader: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        ExpectedCrMemoNo: Code[20];
    begin
        // [FEATURE] [Corrective Credit Memo] [No. Series]
        // [SCENARIO 210983]  Corrective Credit Memo posts with default no. series from "Credit Memo Nos." in Purchase Setup

        Initialize();

        // [GIVEN] Posted Invoice
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Vend, 1, 1, PurchInvHeader);

        // [GIVEN] Next no. in no. series "Credit Memo Nos." of Purchase Setup is "X1"
        PurchasesPayablesSetup.Get();
        ExpectedCrMemoNo := LibraryUtility.GetNextNoFromNoSeries(PurchasesPayablesSetup."Credit Memo Nos.", WorkDate());

        // [WHEN] Create Corrective Credit Memo for Purchase Invoice "A"
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchHeader);

        // [THEN] Corrective Credit Memo created with "No." = "X1"
        PurchHeader.TestField("No.", ExpectedCrMemoNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithNonDefaultNoSeriesWithoutRelation()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchHeader: Record "Purchase Header";
        NoSeries: Record "No. Series";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Corrective Credit Memo] [No. Series]
        // [SCENARIO 210983] Error message is thrown when create Corrective Credit Memo if no. series from "Credit Memo Nos." in Purchase Setup is not "Default Nos" and has no relations

        Initialize();

        // [GIVEN] Posted Invoice
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Vend, 1, 1, PurchInvHeader);

        // [GIVEN] No. Series "X" with "Default Nos" = No
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);

        // [GIVEN] "Credit Memo Nos." in Purchase Setup is "X"
        SetCreditMemoNosInPurchSetup(NoSeries.Code);

        // [WHEN] Create Corrective Credit Memo for Purchase Invoice "A"
        asserterror CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchHeader);

        // [THEN] Error message 'It is not possible to assign numbers automatically. If you want the program to assign numbers automatically, please activate Default Nos.' is thrown
        Assert.ExpectedError(CannotAssignNumbersAutoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithNonDefaultNoSeriesWithRelationCancelSeriesSelection()
    var
        Item: Record Item;
        Vend: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchHeader: Record "Purchase Header";
        NoSeries: Record "No. Series";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Corrective Credit Memo] [No. Series]
        // [SCENARIO 210983] Error message is thrown when create Corrective Credit Memo if no. series from "Credit Memo Nos." in Purchase Setup is not "Default Nos" and has relations but No. Series is not selected from the list of series.

        Initialize();

        // [GIVEN] Posted Invoice
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Vend, 1, 1, PurchInvHeader);

        // [GIVEN] No. Series "X" with "Default Nos" = No and related No. series "Y". Next "No." in no. series is "X1"
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);

        // [GIVEN] "Credit Memo Nos." in Purchase Setup is "X"
        SetCreditMemoNosInPurchSetup(NoSeries.Code);

        // [WHEN] Create Corrective Credit Memo for Purchase Invoice "A" and do not specify any no. series from "No. Series" page
        // No. Series selection cancellation handles by NoSeriesListSelectNothingModalPageHandler
        asserterror CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchHeader);

        // [THEN] Error message 'It is not possible to assign numbers automatically. If you want the program to assign numbers automatically, please activate Default Nos.' is thrown
        Assert.ExpectedError(CannotAssignNumbersAutoErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryModalPageHandler')]
    [Scope('OnPrem')]
    procedure NegativeLineWithTrackingCopiedToCorrCrMemo()
    var
        PurchHeaderCorrection: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        ItemNo: Code[20];
        InvNo: Code[20];
    begin
        // [FEATURE] [Corrective Credit Memo] [Item Tracking] [Exact Cost Reversing Mandatory]
        // [SCENARIO 210894] Negative Line of Posted Purchase Invoice with Lot Tracking copies to Corrective Credit Memo

        Initialize();

        // [GIVEN] Item with Lot Tracking
        ItemNo := CreateTrackedItem();

        // [GIVEN] Positive Adjustment with Item and Lot Tracking
        PostPositiveAdjmtWithLotNo(ItemNo);

        // [GIVEN] Posted Purchase Invoice with Quantity = - 1 and "Lot No."
        PostPurchInvWithNegativeLineAndLotNo(InvNo, PurchLine, ItemNo);
        PurchInvHeader.Get(InvNo);

        // [WHEN] Create Corrective Credit Memo for Posted Purchase Invoice
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchHeaderCorrection);

        // [THEN] Credit Memo created with Quantity = -1 and "Lot No."
        VerifyPurchLineWithTrackedQty(PurchHeaderCorrection, PurchLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryModalPageHandler')]
    [Scope('OnPrem')]
    procedure NegativeLineWithTrackingCopiedWithExactCostRevMandatory()
    var
        PurchHeaderCorrection: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemNo: Code[20];
        InvNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Exact Cost Reversing Mandatory]
        // [SCENARIO 210894] Negative Line of Posted Purchase Invoice with Lot Tracking copies to Credit Memo when "Exact Cost Reversing Mandatory" is set

        Initialize();

        // [GIVEN] Item with Lot Tracking
        ItemNo := CreateTrackedItem();

        // [GIVEN] Positive Adjustment with Item and Lot Tracking
        PostPositiveAdjmtWithLotNo(ItemNo);

        // [GIVEN] Posted Purchase Invoice with Quantity = - 1 and "Lot No."
        PostPurchInvWithNegativeLineAndLotNo(InvNo, PurchLine, ItemNo);

        // [GIVEN] "Exact Cost Reversing Mandatory" is set
        LibraryPurchase.SetExactCostReversingMandatory(true);

        // [GIVEN] Purchase Credit Memo
        LibraryPurchase.CreatePurchHeader(
          PurchHeaderCorrection, PurchHeaderCorrection."Document Type"::"Credit Memo", PurchLine."Buy-from Vendor No.");

        // [WHEN] Copy Posted Purchase Invoice to Purchase Credit Memo
        LibraryPurchase.CopyPurchaseDocument(PurchHeaderCorrection, "Purchase Document Type From"::"Posted Invoice", InvNo, true, false);

        // [THEN] Credit Memo created with Quantity = -1 and "Lot No."
        VerifyPurchLineWithTrackedQty(PurchHeaderCorrection, PurchLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('SetLotItemWithQtyToHandleTrackingPageHandler')]
    procedure CancelPurchaseInvoiceFromOrderWithItemTracking()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        QtyToReceive: Decimal;
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 387956] Item Tracking Lines for the original Purchase Order Lines have "Qty. Handled (Base)" and "Qty. Invoiced (Base)" values reverted when canceling Posted Purchase Invoice
        Initialize();

        // [GIVEN] Item with Lot Tracking
        Item.Get(CreateTrackedItem());

        // [GIVEN] Purchase Order for 15 PCS of the Item, with "Qty. to Receive" = "Qty. to Invoice" = 5 PCS
        QtyToReceive := LibraryRandom.RandDec(10, 2);
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseOrderForItem(Vendor, Item, 3 * QtyToReceive, PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);

        // [GIVEN] Item Tracking Line for Lot "L", Quantity = "Qty. to Handle" = 5 PCS
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(QtyToReceive);
        LibraryVariableStorage.Enqueue(QtyToReceive);
        PurchaseLine.OpenItemTrackingLines();

        // [GIVEN] Purchase Order posted with Receive and Invoice
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Cancel the Posted Purchase Invoice 
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // [THEN] Item Tracking for the original Purchase Order has "Quantity Handled (Base)" = 0
        PurchaseLine.Find();
        TrackingSpecification.SetSourceFilter(
            Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.",
            PurchaseLine."Line No.", false);
        Assert.RecordIsEmpty(TrackingSpecification);

        // [THEN] Item Tracking for the original Purchase Order has "Quantity Invoiced (Base)" = 0
        ReservationEntry.SetSourceFilter(
            Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.",
            PurchaseLine."Line No.", false);
        ReservationEntry.FindFirst();
        Assert.AreEqual(ReservationEntry."Quantity Invoiced (Base)", 0, 'Quantity Invoiced must be 0.');

        // [THEN] The Purchase Order can be posted again
        PurchaseHeader.Find();
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SetLotItemWithQtyToHandleTrackingPageHandler')]
    procedure CancelPurchaseInvoiceCreatedViaGetReceiptLinesWithItemTracking()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Get Receipt Lines]
        // [SCENARIO 400516] Restore item tracking in the original purchase order when the invoice is created via "Get Receipt Lines" and then canceled.
        Initialize();

        // [GIVEN] Lot-tracked item.
        Item.Get(CreateTrackedItem());

        // [GIVEN] Purchase order.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, Vendor."No.");

        // [GIVEN] Add two purchase lines, quantity = 1, assign lot no.
        for i := 1 to ArrayLen(PurchaseLine) do begin
            LibraryPurchase.CreatePurchaseLineWithUnitCost(
                PurchaseLine[i], PurchaseHeader, Item."No.", LibraryRandom.RandDec(10, 2), 1);
            LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
            LibraryVariableStorage.Enqueue(PurchaseLine[i].Quantity);
            LibraryVariableStorage.Enqueue(PurchaseLine[i].Quantity);
            PurchaseLine[i].OpenItemTrackingLines();
        end;

        // [GIVEN] Receive purchase order.
        PurchRcptHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));

        // [GIVEN] Create purchase invoice using "Get Receipt Lines".
        // [GIVEN] Post the invoice.
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, "Purchase Document Type"::Invoice, Vendor."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true));

        // [WHEN] Cancel the posted invoice.
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // [THEN] Item tracking is restored in the original purchase order.
        // [THEN] "Quantity Handled" = "Quantity Invoiced" = 0 in item tracking for each purchase line.
        for i := 1 to ArrayLen(PurchaseLine) do begin
            PurchaseLine[i].Find();
            TrackingSpecification.SetSourceFilter(
                Database::"Purchase Line", PurchaseLine[i]."Document Type".AsInteger(), PurchaseLine[i]."Document No.",
                PurchaseLine[i]."Line No.", false);
            Assert.RecordIsEmpty(TrackingSpecification);

            ReservationEntry.SetSourceFilter(
                Database::"Purchase Line", PurchaseLine[i]."Document Type".AsInteger(), PurchaseLine[i]."Document No.",
                PurchaseLine[i]."Line No.", false);
            ReservationEntry.FindFirst();
            ReservationEntry.TestField("Quantity Invoiced (Base)", 0);
        end;

        // [THEN] The purchase order can be posted again.
        PurchaseHeader.Find();
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTransportAndTransactionTransferredInPurchCreditMemoHeader()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PurchInvHeaderNo: Code[20];
    begin
        // [SCENARIO 452722]  Fields “Transaction Type” and “Transport Method” are not transferred to Purchase Credit Memo Header
        Initialize();

        // [GIVEN] Create Purchase Header with Transaction Type & Transport Method
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader."Transaction Specification" := LibraryUtility.GenerateGUID();
        PurchaseHeader."Transaction Type" := LibraryUtility.GenerateGUID();
        PurchaseHeader."Transport Method" := LibraryUtility.GenerateGUID();
        PurchaseHeader.Modify();

        // [GIVEN] Create Purchase Line
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);

        // [GIVEN] Post the Purchase Invoice
        PurchInvHeaderNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvHeader.Get(PurchInvHeaderNo);

        // [WHEN] Create Corrective Credit Memo for Purchase Invoice
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchaseHeader2);

        // [THEN] Verify Transaction Type & Transport Method are transferred to Credit Memo
        Assert.AreEqual(PurchaseHeader."Transaction Type", PurchaseHeader2."Transaction Type", TransactionTypeErr);
        Assert.AreEqual(PurchaseHeader."Transport Method", PurchaseHeader2."Transport Method", TransportMethodErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure NoDuplicateCommentLineWhenUsingCorrectiveCreditMemoOnPostedPurchInv()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchHeader: Record "Purchase Header";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PurchaseOrderPage: TestPage "Purchase Order";
    begin
        // [SCENARIO 456470] Duplicate comment lines in Sales/Purchase Credit Memo when created by Corrective Credit Memo
        Initialize();

        // [GIVEN] Create a Item with a Price
        CreateItemWithCost(Item, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create a Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Purchase Order
        CreatePurchaseOrderForItem(Vendor, Item, 1, PurchaseHeaderOrder, PurchaseLine);

        // [GIVEN] Post a Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [GIVEN] Select a Purchase Receipt Lines
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Create a Purchase Invoice for selected Purchase Receipt Line
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [GIVEN] Post the Purchase Invoice 
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true));
        //Commit();

        // [WHEN] Correct the Posted Purchase Invoice 
        LibraryVariableStorage.Enqueue(CorrectPostedInvoiceFromSingleOrderQst);
        LibraryVariableStorage.Enqueue(true);
        PurchaseOrderPage.Trap();
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchHeader);

        // [THEN] Two Comments Lines should be created in the Purchase Line.
        CheckCommentsOnCreditLine(PurchHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CheckCorrectiveCreditMemoConfirmDialogOnPostedPurchaseInv()
    var
        Item: Record Item;
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        Vendor: Record Vendor;
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO 578461] Message when using "Create corrective Credit Memo" on a partial sales or purchase invoice related to an 
        // existing Order needs to inform that the Order Quantities will be changed.
        Initialize();

        // [GIVEN] Create a Item with a Price
        CreateItemWithCost(Item, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create a Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Purchase Order
        CreatePurchaseOrderForItem(Vendor, Item, 10, PurchaseHeaderOrder, PurchaseLine);
        PurchaseLine.Validate("Qty. to Receive", 5);
        PurchaseLine.Modify(true);

        // [GIVEN] Post a Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, true);

        // [GIVEN] Get Posted Purchase Invoice. 
        GetPostedInvoice(PurchInvHeader, PurchaseHeaderOrder);

        // [WHEN] Correct the posted Purchase Invoice.
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchHeader);

        // [THEN] Assert that confirm was called.
        Assert.IsTrue(WasConfirmShown, ConfirmDialogErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Purchase Correct Invoice");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Purchase Correct Invoice");

        IsInitialized := true;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        // fix No. Series setup
        SetGlobalNoSeriesInSetups();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SavePurchasesSetup();

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Purchase Correct Invoice");
    end;

    local procedure SetGlobalNoSeriesInSetups()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        MarketingSetup: Record "Marketing Setup";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Customer Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup.Modify();

        MarketingSetup.Get();
        MarketingSetup."Contact Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        MarketingSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Ext. Doc. No. Mandatory" := false;
        PurchasesPayablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Vendor Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup.Modify();

        WarehouseSetup.Get();
        WarehouseSetup."Whse. Ship Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseSetup.Modify();
    end;

    local procedure CreateItemWithCost(var Item: Record Item; UnitCost: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Last Direct Cost" := UnitCost;
        Item.Modify();
    end;

    local procedure CreateTrackedItem(): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);
        exit(Item."No.");
    end;

    local procedure SellItem(SellToVendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseInvoiceForItem(SellToVendor, Item, Qty, PurchaseHeader, PurchaseLine);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseInvForNewItemAndVendor(var Item: Record Item; var Vendor: Record Vendor; UnitCost: Decimal; Qty: Decimal; var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        CreateItemWithCost(Item, UnitCost);
        LibraryPurchase.CreateVendor(Vendor);
        SellItem(Vendor, Item, Qty, PurchInvHeader);
    end;

    local procedure CreateAndPostPurchInvWithCustomAmount(var PurchInvHeader: Record "Purch. Inv. Header"; UnitCost: Decimal)
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateItemWithCost(Item, UnitCost);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchaseInvForNewItemAndVendor(var Item: Record Item; var Vendor: Record Vendor; UnitPrice: Decimal; Qty: Decimal; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        CreateItemWithCost(Item, UnitPrice);
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseInvoiceForItem(Vendor, Item, Qty, PurchaseHeader, PurchaseLine);
    end;

    local procedure CreatePurchaseInvoiceForItem(Vendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
    end;

    local procedure CreateJobwithJobTask(var Job: Record Job; var JobTask: Record "Job Task")
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreatePurchaseOrderForItem(Vendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
    end;

    local procedure CreateAndPostPurchInvForItem(var PurchHeader: Record "Purchase Header"; Vend: Record Vendor; Item: Record Item; UnitCost: Decimal; Qty: Decimal): Code[20]
    var
        PurchLine: Record "Purchase Line";
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        LibraryPurch.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vend."No.");
        LibraryPurch.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", Qty);
        PurchLine.Validate("Unit Cost", UnitCost);
        PurchLine.Modify(true);
        exit(LibraryPurch.PostPurchaseDocument(PurchHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure PostApplyUnapplyCreditMemoToInvoice(PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchHeader: Record "Purchase Header";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        ReasonCode: Record "Reason Code";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        InvNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(
            PurchHeader, PurchHeader."Document Type"::"Credit Memo", PurchInvHeader."Buy-from Vendor No.");
        CopyDocMgt.SetProperties(
          true, false, false, false, false, false, false);
        CopyDocMgt.CopyPurchDoc("Purchase Document Type From"::"Posted Invoice", PurchInvHeader."No.", PurchHeader);
        LibraryERM.CreateReasonCode(ReasonCode);
        PurchHeader.Validate("Reason Code", ReasonCode.Code);
        PurchHeader.Modify();
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::"Credit Memo", InvNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgerEntry);
    end;

    local procedure TurnOffExactCostReversing()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Exact Cost Reversing Mandatory", false);
        PurchasesPayablesSetup.Modify(true);
        Commit();
    end;

    local procedure SetInvoiceRounding()
    begin
        LibraryERM.SetInvRoundingPrecisionLCY(1);
        LibraryPurchase.SetInvoiceRounding(true);
    end;

    local procedure SetCreditMemoNosInPurchSetup(NoSeriesCode: Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Credit Memo Nos.", NoSeriesCode);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure GetAmountInclVATOfPurchInvLine(PurchInvHeader: Record "Purch. Inv. Header"): Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
        exit(PurchInvLine."Amount Including VAT");
    end;

    local procedure VerifyInvRndLineDoesNotExistInPurchHeader(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange(Type, PurchLine.Type::"G/L Account");
        PurchLine.SetRange("No.", LibraryPurchase.GetInvRoundingAccountOfVendPostGroup(PurchHeader."Vendor Posting Group"));
        Assert.RecordIsEmpty(PurchLine);
    end;

    local procedure VerifyInvRndLineExistsInPurchCrMemoHeader(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");
        PurchCrMemoLine.SetRange(Type, PurchCrMemoLine.Type::"G/L Account");
        PurchCrMemoLine.SetRange("No.", LibraryPurchase.GetInvRoundingAccountOfVendPostGroup(PurchCrMemoHdr."Vendor Posting Group"));
        Assert.RecordIsNotEmpty(PurchCrMemoLine);
    end;

    local procedure VerifyBlankLineDoesNotExist(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange(Type, PurchLine.Type::" ");
        Assert.RecordIsEmpty(PurchLine);
    end;

    local procedure CheckSomethingIsPosted(Item: Record Item; Vendor: Record Vendor)
    begin
        // Inventory should be positive
        Item.CalcFields(Inventory);
        Assert.IsTrue(Item.Inventory > 0, '');

        // Vendor balance should be positive
        Vendor.CalcFields(Balance);
        Assert.IsTrue(Vendor.Balance > 0, '');
    end;

    local procedure CheckEverythingIsReverted(Item: Record Item; Vendor: Record Vendor; LastGLEntry: Record "G/L Entry")
    var
        GLEntry: Record "G/L Entry";
        ValueEntry: Record "Value Entry";
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        TotalCost: Decimal;
        TotalQty: Decimal;
    begin
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Vendor);
        ValueEntry.SetRange("Source No.", Vendor."No.");
        ValueEntry.FindSet();
        repeat
            TotalQty += ValueEntry."Item Ledger Entry Quantity";
            TotalCost += ValueEntry."Cost Amount (Actual)";
        until ValueEntry.Next() = 0;
        Assert.AreEqual(0, TotalQty, '');
        Assert.AreEqual(0, TotalCost, '');

        // Vendor balance should go back to zero
        Vendor.CalcFields(Balance);
        Assert.AreEqual(0, Vendor.Balance, '');

        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntry."Entry No.");
        GLEntry.FindSet();
        repeat
            TotalDebit += GLEntry."Credit Amount";
            TotalCredit += GLEntry."Debit Amount";
        until GLEntry.Next() = 0;

        Assert.AreEqual(TotalDebit, TotalCredit, '');
    end;

    local procedure CheckNothingIsCreated(Vendor: Record Vendor; LastGLEntry: Record "G/L Entry")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Assert.IsTrue(LastGLEntry.Next() = 0, 'No new G/L entries are created');
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.SetRange("Pay-to Vendor No.", Vendor."No.");
        Assert.IsTrue(PurchaseHeader.IsEmpty, 'The Credit Memo should not have been created');
    end;

    local procedure PostPositiveAdjmtWithLotNo(ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, ItemNo, '', '', LibraryRandom.RandDecInRange(10, 20, 2));
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostPurchInvWithNegativeLineAndLotNo(var InvNo: Code[20]; var PurchLine: Record "Purchase Line"; ItemNo: Code[20])
    var
        PurchHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo, -1);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
        PurchLine.OpenItemTrackingLines();
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
    end;

    local procedure VerifyPurchLineWithTrackedQty(PurchHeader: Record "Purchase Header"; ExpectedQty: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.FindFirst();
        PurchLine.TestField(Quantity, ExpectedQty);
        LibraryInventory.VerifyReservationEntryWithLotExists(
          DATABASE::"Purchase Line", PurchHeader."Document Type".AsInteger(), PurchHeader."No.",
          PurchLine."Line No.", PurchLine."No.", PurchLine.Quantity);
    end;

    local procedure CheckCommentsOnCreditLine(PurchHeader: Record "Purchase Header")
    var
        PurcLine: Record "Purchase Line";
        PurchLineCount: Integer;
    begin
        PurcLine.SetRange("Document Type", PurcLine."Document Type"::"Credit Memo");
        PurcLine.SetRange("Document No.", PurchHeader."No.");
        PurcLine.SetFilter(Type, '%1', PurcLine.Type::" ");
        PurchLineCount := PurcLine.Count();
        Assert.AreEqual(2, PurchLineCount, CommentCountErr);
    end;

    local procedure GetPostedInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchaseHeaderOrder: Record "Purchase Header")
    begin
        PurchInvHeader.SetRange("Order No.", PurchaseHeaderOrder."No.");
        PurchInvHeader.FindFirst();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        WasConfirmShown := true;
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerVerify(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedConfirm(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListModalPageHandler(var NoSeriesList: TestPage "No. Series")
    begin
        NoSeriesList.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        NoSeriesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingMode::"Assign Lot No.":
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingMode::"Select Entries":
                ItemTrackingLines."Select Entries".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SetLotItemWithQtyToHandleTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines."Qty. to Handle (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;
}

