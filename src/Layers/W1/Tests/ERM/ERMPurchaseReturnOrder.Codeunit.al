codeunit 134329 "ERM Purchase Return Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Return Order] [Purchase]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        VATAmountError: Label 'VAT %1 must be %2 in %3.';
        LineAmountError: Label 'Total Amount must be equal to %1 in %2.';
        AmountError: Label '%1 must be equal to %2 in %3.';
        FieldError: Label '%1 must be %2 in %3.';
        ExpectedMessage: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        PostingDateReq: Date;
        isInitialized: Boolean;
        ShipReq: Boolean;
        InvReq: Boolean;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
        DateError: Label 'Enter the posting date.';
        CalcInvDiscount: Boolean;
        InvoicedQuantityError: Label 'Invoiced quantity must be equal to %1.';
        CostAmountActualError: Label 'Cost amount actual must be equal to %1.';
        ItemLedgerQuantityError: Label 'Item ledger quantity must be equal to %1.';
        CopyDocForReturnOrderMsg: Label 'One or more return document lines were not copied. This is because quantities on the posted';
        InsDocForReturnOrderMsg: Label 'One or more return document lines were not inserted or they contain only the remaining quantity of the original document line.';
        ContactShouldNotBeEditableErr: Label 'Contact should not be editable when vendor is not selected.';
        ContactShouldBeEditableErr: Label 'Contact should be editable when vendorr is selected.';
        FunctionMustNotBeCalledErr: Label 'Function %1 must not be called.', Comment = '%1 - function name';
        BatchPostingErrrorNotificationMsg: Label 'An error or warning occured during operation Batch processing of Purchase Header records.';
        ReturnQtyToShipMustBeZeroErr: Label ' Return Qty. to Ship must be zero.';
        QtyToAssignErr: Label '%1 must be %2 in %3', Comment = '%1 = Qty. to Assign, %2 = Quantity, %3 = Purchase Return Order Subform';

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderCreation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Covers Test Case TFS_TC_ID: 122437.
        // Check the Creation of Purchase Return Order.

        // Setup.
        Initialize();

        // Exercise: Create Purchase Return Order.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());

        // Verify: Creation of the Purchase Return Order.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindSet();
        repeat
            PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        until PurchaseLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Covers Test Case TFS_TC_ID: 122438.
        // Check Line Amount as on Purchase Header.

        // Setup: Create Purchase Return Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());

        // Exercise: Calculate VAT Amount and Release Purchase Return Order.
        PurchaseLine.CalcVATAmountLines(QtyType::Invoicing, PurchaseHeader, PurchaseLine, VATAmountLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);

        // Verify: Check Purchase Return Line has calculated Correct VAT Amount.
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          PurchaseHeader.Amount * PurchaseLine."VAT %" / 100, VATAmountLine."VAT Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            VATAmountError, VATAmountLine.FieldCaption("VAT Amount"), PurchaseHeader.Amount * PurchaseLine."VAT %" / 100,
            VATAmountLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocumentTest: Report "Purchase Document - Test";
        FilePath: Text[1024];
    begin
        // Covers Test Case TFS_TC_ID: 122439.
        // Check the Purchase Document Test report has some data after Creating of Purchase Return Order.

        // Setup: Create Purchase Return Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());

        // Exercise: Save Purchase Document Test Report in file.
        Clear(PurchaseDocumentTest);
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        PurchaseDocumentTest.SetTableView(PurchaseHeader);
        FilePath := TemporaryPath + Format(PurchaseHeader."Document Type") + PurchaseHeader."No." + '.xlsx';
        PurchaseDocumentTest.SaveAsExcel(FilePath);

        // Verify: Verify that saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipPurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Covers Test Case TFS_TC_ID: 122440,122441.
        // Check that Posted Purchase Return Order corrected Post as Ship on Posted Purchase Shipment.

        // Setup: Create Purchase Return Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());

        // Exercise: Release Return Order and Post with Ship Option.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify Posted Purchase Shipment.
        VerifyPostedPurchaseEntry(PurchaseHeader."No.", PurchaseHeader.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoTestReport()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: Report "Purchase - Credit Memo";
        FilePath: Text[1024];
    begin
        // Covers Test Case TFS_TC_ID: 122445.
        // Check that Purchase Credit memo report has some data after Post Purchase Return Order as Ship and Invoice.

        // Setup: Create, Release and Post Purchase Return Order with Ship and Invoice Option.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExecuteUIHandler();

        // Exercise: Save Posted Purchase Credit Memo report in a file.
        Clear(PurchaseCreditMemo);
        PurchCrMemoHdr.SetRange("Return Order No.", PurchaseHeader."No.");
        PurchaseCreditMemo.SetTableView(PurchCrMemoHdr);
        FilePath := TemporaryPath + Format('Credit Memo') + PurchaseHeader."No." + '.xlsx';
        PurchaseCreditMemo.SaveAsExcel(FilePath);

        // Verify: Verify that saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ShipAndInvoiceReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VATAmount: Decimal;
    begin
        // Covers Test Case TFS_TC_ID: 122442,122443,122444.
        // Check various Entries after Post Purchase Return Order as Ship and Invoice

        // Setup: Create and Release Purchase Return Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        VATAmount := (PurchaseHeader.Amount * PurchaseLine."VAT %") / 100;

        // Exercise: Post Purchase Return Order as Receive and Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExecuteUIHandler();

        // Verify: Check GL Entry, VAT Entry, Value Entry and Vendor Ledger Entry for Posted Return Order.
        VerifyGLEntry(PurchaseHeader."No.", PurchaseHeader.Amount + VATAmount);
        PurchCrMemoHdr.SetRange("Return Order No.", PurchaseHeader."No.");
        PurchCrMemoHdr.FindFirst();
        VerifyVATEntry(PurchCrMemoHdr."No.", PurchaseHeader."Document Type"::"Credit Memo", -VATAmount);
        VerifyVendorLedgerEntry(PurchaseHeader."No.", PurchaseHeader.Amount + VATAmount);
        VerifyValueEntries(PurchaseHeader."No.", PurchaseHeader.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LocationforReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        RequireShipment: Boolean;
    begin
        // Covers Test Case TFS_TC_ID: 122446,122447.
        // Check that Posted Credit Memo has Correct Location after Posting Purchase Return Order.

        // Setup. Find Location with Require Shipment with True and Create Purchase Return Order.
        Initialize();
        Location.SetRange("Bin Mandatory", false);
        Location.SetRange("Use As In-Transit", false);
        Location.FindFirst();
        RequireShipment := Location."Require Shipment";
        Location.Validate("Require Shipment", true);
        Location.Modify(true);

        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Return Qty. to Ship", PurchaseLine.Quantity);
        PurchaseLine.Modify(true);

        // Exercise: Post Purchase Return Order with Ship and Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExecuteUIHandler();

        // Verify: Verify the Location on Posted Purchase Credit Memo.
        VerifyLocationOnCreditMemo(PurchaseHeader."No.", PurchaseLine."Location Code");

        // TearDown: Roll Back Location with previous state.
        Location.FindFirst();
        Location.Validate("Require Shipment", RequireShipment);
        Location.Modify(true);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderForNonInvItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderRet: Record "Purchase Header";
        PurchaseLineRet: Record "Purchase Line";
        Item: Record Item;
        Location: Record Location;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        VendorNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Setup. Create Full WS Location and set Default Qty. to Receive as Blank in Purchases & Payables Setup.
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Default Qty. to Receive", PurchasesPayablesSetup."Default Qty. to Receive"::Blank);
        PurchasesPayablesSetup.Modify(true);

        //Setup. Create Non Inventory Item and Vendor.
        LibraryInventory.CreateNonInventoryTypeItem(Item);
        VendorNo := CreateVendor();

        // Exercise: Create Purchase Order and Post it for the item created above.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Item."No.", VendorNo);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity);
        PurchaseLine.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryVariableStorage.Enqueue(DocumentNo);

        // Exercise: Create Purchase Return Order and Post it for posted Purchase Order above.
        CreatePurchRetOrderGetPstdDocLineToRev(PurchaseHeaderRet, VendorNo);
        FindPurchaseLine(PurchaseLineRet, PurchaseHeaderRet);

        // Verify: Verify the Return Qty. to Ship on Purchase Return Order is 0.
        Assert.AreEqual(PurchaseLineRet."Return Qty. to Ship", 0, '');

        // Exercise: Set Return Qty. to Ship on Purchase Return Order.
        PurchaseLineRet.Validate("Return Qty. to Ship", PurchaseLine.Quantity);
        PurchaseLineRet.Modify(true);
        // Verify: Verify the Return Qty. to Ship on Purchase Return Order is equal to Purchase Line Quantity.
        Assert.AreEqual(PurchaseLineRet."Return Qty. to Ship", PurchaseLine.Quantity, '');

        // Exercise: Post Purchase Return Order with Ship and Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderRet, true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LineDiscountforReturnOrder()
    var
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PriceListLine: Record "Price List Line";
    begin
        // Covers Test Case TFS_TC_ID: 122448,122449.
        // Check that Posted Credit Memo has Correct Line Discount after Posting Purchase Return Order.

        // Setup. Setup Line Discount for Vendor and Create Purchase Return order.
        Initialize();
        SetupLineDiscount(PurchaseLineDiscount);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        CreatePurchaseReturnHeader(PurchaseHeader, PurchaseLineDiscount."Vendor No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLineDiscount."Item No.",
          PurchaseLineDiscount."Minimum Quantity" + LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Qty. to Receive", 0);  // Qty. to Receive must be 0 in Purchase Return Order.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(500));
        PurchaseLine.Modify(true);

        // Exercise: Post Purchase Return Order with Ship and Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExecuteUIHandler();

        // Verify: Verify Line Discount Amount in Posted Purchase Credit Memo.
        VerifyLineDiscountAmount(
          PurchaseHeader."No.", (PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * PurchaseLineDiscount."Line Discount %" / 100);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        // Covers Test Case TFS_TC_ID: 122450,122451.
        // Check that Vendor Ledger Entry has Correct Invoice Discount after Posting Purchase Return Order.

        // Setup. Create and Release Purchase Return order.
        Initialize();
        CreateInvoiceDiscount(VendorInvoiceDisc);
        CreatePurchaseReturnHeader(PurchaseHeader, VendorInvoiceDisc.Code);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Qty. to Receive", 0);  // Qty. to Receive must be 0 in Purchase Return Order.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(500));
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Exercise: Calculate Invoice Discount on Purchase Line and Post it with Ship and Invoice.
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
        PurchaseHeader.CalcFields(Amount);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExecuteUIHandler();

        // Verify: Verify Invoice Discount on Vendor Ledger Entry.
        VerifyInvoiceDiscountAmount(
          PurchaseHeader."No.", (PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * VendorInvoiceDisc."Discount %" / 100);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CurrencyOnReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Covers Test Case TFS_TC_ID: 122452,122453, 122454.
        // Check that Currency has been posted correctly on Posted Credit Memo after Post Purchase Return Order.

        // Setup: Create Purchase Return Order with Currency and Random Quantity for Purchase Line.
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateVendor());
        PurchaseHeader.Validate("Currency Code", CreateCurrency());
        UpdatePurchaseHeader(PurchaseHeader, PurchaseHeader."No.");

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Qty. to Receive", 0);  // Qty. to Receive must be 0 in Purchase Return Order.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(500));
        PurchaseLine.Modify(true);

        // Exercise: Post Purchase Return Order with Ship and Invoice option.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExecuteUIHandler();

        // Verify: Verify Posted Credit Memo for Currency.
        VerifyCurrencyOnPostedOrder(PurchaseHeader."No.", PurchaseHeader."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentFromReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Covers Test Case TFS_TC_ID: 122455.
        // Check Copy Document Functionalities from Purchase Return Order.

        // Setup: Create Purchase Order and Header for Purchase Return Order.
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(100));
        DocumentNo := PurchaseHeader."No.";
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Return Order");
        PurchaseHeader.Insert(true);

        // Exercise: Copy Document from Purchase Order to Purchase Return Order.
        CopyDocument(PurchaseHeader, DocumentNo);

        // Verify: Verify Purchase Line created on Purchase Return Order after Copy Document from Purchase Order.
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyInvoiceFromReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Covers Test Case TFS_TC_ID: 122456,122457.
        // Check that Posted Credit Memo has correct Applies to Doc. No after Apply from Purchase Return Order.

        // Setup: Create Purchase Invoice and Post it.
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(500));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(500));
        PurchaseLine.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Create Purchase Return Order and Apply Previous Purchase Invoice Document and Post it with Qty. to Receive is Zero.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader2, PurchaseHeader2."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader2.Validate("Vendor Cr. Memo No.", PurchaseHeader2."No.");
        PurchaseHeader2.Validate("Applies-to Doc. Type", PurchaseHeader2."Applies-to Doc. Type"::Invoice);
        PurchaseHeader2.Validate("Applies-to Doc. No.", DocumentNo);
        PurchaseHeader2.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader2, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Qty. to Receive", 0);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader2);
        PurchaseHeader2.CalcFields(Amount);
        VATAmount := PurchaseHeader2.Amount + (PurchaseHeader2.Amount * PurchaseLine."VAT %") / 100;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);
        ExecuteUIHandler();

        // Verify: Posted Credit Memo for Apply to Doc. No. has been shifted correctly and Vendor Ledger Entry.
        VerifyPostedCreditMemo(PurchaseHeader2."No.", DocumentNo);
        VerifyVendorLedgerEntry(PurchaseHeader2."No.", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchRetOrderShipmentCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verifying that the posted purchase Shipment and posted purchase Credit Memo have been created after posting return order.

        // Setup: Create Purchase Return Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());
        FindPurchaseLine(PurchaseLine, PurchaseHeader);

        // Exercise: Post Purchase Return Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Return Shipment Line and Purchase Credit Memo Line.
        VerifyReturnShipmentLine(PurchaseLine, FindReturnShipmentHeaderNo(PurchaseHeader."No."));
        VerifyPurchCrMemoLine(PurchaseLine, FindPurchCrMemoHeaderNo(PurchaseHeader."No."));
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchReturnOrderHandler,MessageHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostWithWorkDate()
    var
        PurchaseHeader: Record "Purchase Header";
        RecID: RecordID;
    begin
        // [SCENARIO] Batch Post Purch. Ret. Orders Report with WorkDate as Posting Date and all the fields checked based on Purchase Return Order without Vendor Cr. Memo No.

        // [GIVEN] Create Purchase Return Document without Vendor Credit Memo No..
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(false);
        RecID := PurchaseHeader.RecordId;
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());
        UpdatePurchaseHeader(PurchaseHeader, '');

        // [WHEN] Run Batch Post Purch. Ret. Orders Report with Work Date as Posting Date and all field.
        ShipReq := true;
        InvReq := true;
        PostingDateReq := WorkDate();
        ReplacePostingDate := true;
        ReplaceDocumentDate := true;
        CalcInvDiscount := true;

        RunBatchPostPurchaseReturnOrders(PurchaseHeader);

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Purchase Header records.'
        Assert.ExpectedMessage(BatchPostingErrrorNotificationMsg, LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(RecID);
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Purchase Return Order is not posted
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Return Order", PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchReturnOrderHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostWithWorkDateBackground()
    var
        PurchaseHeader: Record "Purchase Header";
        ErrorMessage: Record "Error Message";
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        RecID: RecordID;
    begin
        // [SCENARIO] Batch Post (Background) Purch. Ret. Orders Report with WorkDate as Posting Date and all the fields checked based on Purchase Return Order without Vendor Cr. Memo No.

        // [GIVEN] Create Purchase Return Document without Vendor Credit Memo No..
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        RecID := PurchaseHeader.RecordId;
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());
        UpdatePurchaseHeader(PurchaseHeader, '');

        // [WHEN] Run Batch Post Purch. Ret. Orders Report with Work Date as Posting Date and all field.
        ShipReq := true;
        InvReq := true;
        PostingDateReq := WorkDate();
        ReplacePostingDate := true;
        ReplaceDocumentDate := true;
        CalcInvDiscount := true;

        RunBatchPostPurchaseReturnOrders(PurchaseHeader);
        JobQueueEntry.SetRange("Record ID to Process", PurchaseHeader.RecordId);
        JobQueueEntry.FindFirst();
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId, true);

        // [THEN] Error message contains zero record for Purchase Header
        ErrorMessage.SetRange("Context Record ID", PurchaseHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 0);
        // [THEN] Purchase Return Order is not posted
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Return Order", PurchaseHeader."No.");
        Assert.AreEqual(PurchaseHeader."Job Queue Status", PurchaseHeader."Job Queue Status"::Error, 'Wrong JQ status in purchase header');
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchReturnOrderHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostWithBlankPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Batch Post Purch. Ret. Orders Report with blank Posting Date and other fields checked based on Purchase Return Order without Vendor Cr. Memo No.

        // Setup: Create Purchase Return Document without Vendor Credit Memo No..
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());
        UpdatePurchaseHeader(PurchaseHeader, '');

        // Exercise: Run Batch Post Purch. Ret. Orders Report with all Fields Except Posting Date as Blank date .
        ShipReq := true;
        InvReq := true;
        PostingDateReq := 0D;
        ReplacePostingDate := true;
        ReplaceDocumentDate := true;
        CalcInvDiscount := true;
        asserterror RunBatchPostPurchaseReturnOrders(PurchaseHeader);

        // Verify: Check the Posting Date error.
        Assert.ExpectedError(DateError);
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchReturnOrderHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostWithCalcInvDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        // Check Batch Post Purch. Ret. Orders Report with Ship, Invoice and  Calc. Inv. Discount as true based on Purchase Return Order.

        // Setup: Create Purchase Return Document.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(false);
        CreateInvoiceDiscount(VendorInvoiceDisc);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), VendorInvoiceDisc.Code);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);

        // Exercise: Run Batch Post Purch. Ret. Orders Report with with Ship, Invoice and  Calc. Inv. Discount as true.
        ShipReq := true;
        InvReq := true;
        PostingDateReq := 0D;
        ReplacePostingDate := false;
        ReplaceDocumentDate := false;
        CalcInvDiscount := true;
        RunBatchPostPurchaseReturnOrders(PurchaseHeader);

        // Verify: Check Purchase Return Order after Run Batch Post Purch. Ret. Orders Report.
        VerifyInvoiceDiscountAmount(
          PurchaseHeader."No.", (PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * VendorInvoiceDisc."Discount %" / 100);
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchReturnOrderHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostWithCalcInvDiscountBackground()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // Check Batch Post (Background) Purch. Ret. Orders Report with Ship, Invoice and  Calc. Inv. Discount as true based on Purchase Return Order.

        // Setup: Create Purchase Return Document.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        CreateInvoiceDiscount(VendorInvoiceDisc);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), VendorInvoiceDisc.Code);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);

        // Exercise: Run Batch Post Purch. Ret. Orders Report with with Ship, Invoice and  Calc. Inv. Discount as true.
        ShipReq := true;
        InvReq := true;
        PostingDateReq := 0D;
        ReplacePostingDate := false;
        ReplaceDocumentDate := false;
        CalcInvDiscount := true;
        RunBatchPostPurchaseReturnOrders(PurchaseHeader);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // Verify: Check Purchase Return Order after Run Batch Post Purch. Ret. Orders Report.
        VerifyInvoiceDiscountAmount(
          PurchaseHeader."No.", (PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * VendorInvoiceDisc."Discount %" / 100);
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchReturnOrderHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostWithReturnShipmentLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Batch Post Purch. Ret. Orders Report with Work Date as Posting Date and all field checked based on Purchase Return Order with Vendor Cr. Memo No.

        // Setup: Create Purchase Return Document with Vendor Credit Memo No.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(false);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());
        FindPurchaseLine(PurchaseLine, PurchaseHeader);

        // Exercise: Run Batch Post Purch. Ret. Orders Report with all Fields.
        ShipReq := true;
        InvReq := true;
        PostingDateReq := WorkDate();
        ReplacePostingDate := true;
        ReplaceDocumentDate := true;
        CalcInvDiscount := true;
        RunBatchPostPurchaseReturnOrders(PurchaseHeader);

        // Verify: Check Return Shipment Line.
        VerifyReturnShipmentLine(PurchaseLine, FindReturnShipmentHeaderNo(PurchaseHeader."No."));
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchReturnOrderHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostWithReturnShipmentLineBackground()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // Check Batch Post (Background) Purch. Ret. Orders Report with Work Date as Posting Date and all field checked based on Purchase Return Order with Vendor Cr. Memo No.

        // Setup: Create Purchase Return Document with Vendor Credit Memo No.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());
        FindPurchaseLine(PurchaseLine, PurchaseHeader);

        // Exercise: Run Batch Post Purch. Ret. Orders Report with all Fields.
        ShipReq := true;
        InvReq := true;
        PostingDateReq := WorkDate();
        ReplacePostingDate := true;
        ReplaceDocumentDate := true;
        CalcInvDiscount := true;
        RunBatchPostPurchaseReturnOrders(PurchaseHeader);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // Verify: Check Return Shipment Line.
        VerifyReturnShipmentLine(PurchaseLine, FindReturnShipmentHeaderNo(PurchaseHeader."No."));
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesHandler,MessageHandler,ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure PostPurchRetOrderWithoutAppItemEntryWithIT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InventorySetup: Record "Inventory Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Verify GL Entries after Post Purchase Return Order without Appl.-to Item Entry with Item Tracking after Get Posted Invoice Line to Reverse.

        // Setup: Update Inventory and Purchase & Payable Setups, create Purchase Invoice and Post with Item Tracking.
        Initialize();
        InventorySetup.Get();
        PurchasesPayablesSetup.Get();
        UpdateInventorySetup(InventorySetup."Automatic Cost Adjustment"::Always);
        UpdatePurchasesPayablesSetup(true);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateTrackedItem(), CreateVendor());
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Create Purchase Return Order, Get Posted Invoice Line to Reverse and update Appl.-to Item Entry on Purchase Return Order Line.
        CreateAndUpdatePurchRetOrder(PurchaseHeader2, PurchaseLine."Buy-from Vendor No.");
        PurchaseHeader2.CalcFields("Amount Including VAT");

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // Verify: Verify GL Entries after Post Purchase Return Order without Appl.-to Item Entry with Item Tracking.
        VerifyGLEntry(PurchaseHeader2."No.", PurchaseHeader2."Amount Including VAT");

        // Tear down.
        UpdateInventorySetup(InventorySetup."Automatic Cost Adjustment");
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Exact Cost Reversing Mandatory");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderPartiallyWithJob()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Program populate the correct Invoiced Quantity and Cost Amount in Item Ledger Entries after posting the Purchase return order partially with Job No.

        // Setup: Create Purchase Return Order with Copy Document.
        Initialize();
        PurchaseReturnOrderWithCopyDocument(PurchaseHeader, PurchaseLine);

        // Exercise: Post Purchase Return Order Partiallly.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Item Ledger and Value Entry.
        VerifyItemLedgerEntry(PurchaseLine);
        VerifyValueEntry(PurchaseHeader."No.", PurchaseLine.Quantity - PurchaseLine."Qty. to Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderFullyWithJob()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Program populate the correct Invoiced Quantity and Cost Amount in Item Ledger Entries after posting the Purchase return order fully with Job No.

        // Setup: Create Purchase Return Order with Copy Document.
        Initialize();
        PurchaseReturnOrderWithCopyDocument(PurchaseHeader, PurchaseLine);

        // Exercise: Post Purchase Return Order Fully.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        UpdatePurchaseHeader(PurchaseHeader, LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Item Ledger and Value Entry.
        VerifyItemLedgerEntry(PurchaseLine);
        VerifyValueEntry(PurchaseHeader."No.", PurchaseLine.Quantity - PurchaseLine."Qty. to Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostReverseChargeVATPurchaseOrderWithJob()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
    begin
        // Verify Program creates correct VAT Entries when post reverse Charge VAT Purchase Order with multiple lines with Job.

        // Setup: Create VAT Posting Setup with Reverse Charge VAT. Craete Purchase Order with multiple lines with Job.
        Initialize();
        Vendor.Get(CreateVendor());
        CreateReverseChargeVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group");
        CreatePurchaseOrderWithJob(PurchaseLine, Vendor."No.");
        ModifyPurchaseLineVATProdPostingGroup(PurchaseLine, VATPostingSetup."VAT Prod. Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseLineWithJob(PurchaseLine2, PurchaseHeader, PurchaseLine."Job No.", PurchaseLine."Job Task No.");
        ModifyPurchaseLineVATProdPostingGroup(PurchaseLine2, PurchaseLine."VAT Prod. Posting Group");

        // Calculate VAT on Purchase Order.
        VATAmount := PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * VATPostingSetup."VAT %" / 100;
        VATAmount := VATAmount + PurchaseLine2.Quantity * PurchaseLine2."Direct Unit Cost" * VATPostingSetup."VAT %" / 100;

        // Exercise: Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify VAT Amount when post reverse Charge VAT Purchase Order with multiple lines with Job.
        VerifyVATEntry(PurchaseHeader."Last Posting No.", PurchaseHeader."Document Type"::Invoice, VATAmount);
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyRetrunShipmentNoAndReturnShpimentLineNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PostedShipmentNo: Code[20];
        PostedCrMemoNo: Code[20];
    begin
        // Create New Purchase Return Order post as Ship, post a credit Memo and verify Retrun Shipment No and Return Shipment Line No.

        // Setup: Create Purchase Retrun Order and post as Ship then Create Credit Memo.
        Initialize();
        PostedShipmentNo := CreateAndPostPurchaseReturnOrder(PurchaseHeader);
        CreatePurchaseHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");
        GetReturnShipmentLine(PurchaseHeader2);

        // Excercise: Post the above created purchase credit Memo.
        PostedCrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // Verify: Verify the Return Shipment No and Return Shipment Line No.
        VerifyReturnShipment(PostedCrMemoNo, PostedShipmentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderWithMultipleJobLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify that program does not throw any error while posting the purchase return shipment with multiple job line.

        // Setup: Create Purchase Return Order with Copy Document.
        Initialize();
        CreatePurchaseReturnHeader(PurchaseHeader, CreateVendor());
        LibraryPurchase.CopyPurchaseDocument(
          PurchaseHeader, "Purchase Document Type From"::"Posted Invoice",
          PostPurchaseOrderWithMultipleJobLine(PurchaseHeader."Buy-from Vendor No."), false, false);
        FindPurchaseLine(PurchaseLine, PurchaseHeader);

        // Exercise: Post Purchase Return Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify that no error comes up after posting the purchase return and also verified the Item Ledger Entry.
        VerifyItemAndDocTypeOnItemLedgerEntry(DocumentNo, PurchaseLine."No.");
    end;

    [Test]
    [HandlerFunctions('MessageVerificationHandler')]
    [Scope('OnPrem')]
    procedure CopyUnappliedPurchLineToPurchRetOrderByCopyDocument()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PostedPurchaseHeaderNo: Code[20];
        VendorNo: Code[20];
    begin
        // Verify that unapplied Purchase Lines can be copied to Purchase Return Order by Copy Document
        // and Appl.-to Item Entry is filled when Exact Cost Reversing Mondatory is enabled.

        // Setup: Create Item, vendor and update Purchases & Payables Setup for Exact Cost Reversing Mandatory.
        Initialize();
        PurchasesPayablesSetup.Get();
        UpdateExactCostReversingMandatory(true);
        VendorNo := CreateVendor();
        PostedPurchaseHeaderNo := CreateAndPostPurchaseOrderWithMultipleLines(PurchaseHeader, VendorNo);

        // Create Purchase Return Order by Copy Document. Find and delete the first Purchase Line.
        CreatePurchaseReturnOrderByCopyDocument(PurchaseHeader, VendorNo, "Purchase Document Type From"::"Posted Invoice", PostedPurchaseHeaderNo, false, false);
        FindAndDeleteOnePurchaseLine(PurchaseHeader);

        // Post Purchase Return Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Exercise: Create Purchase Return Order by Copy Document again. Find Purchase Line.
        // Verify: Verify the warning message in MessageHandler2.
        LibraryVariableStorage.Enqueue(CopyDocForReturnOrderMsg); // Enqueue for MessageHandler2.
        CreatePurchaseReturnOrderByCopyDocument(PurchaseHeader2, VendorNo, "Purchase Document Type From"::"Posted Invoice", PostedPurchaseHeaderNo, false, false);

        // Verify the unapplied line can be copied and Exact Cost Reversal link is created.
        VerifyPurchaseReturnOrderLine(PurchaseHeader);

        // Tear down: Reset Exact Cost Reversing Mandatory.
        UpdateExactCostReversingMandatory(PurchasesPayablesSetup."Exact Cost Reversing Mandatory");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLedgEntryWithDocumentTypeRefund()
    var
        PaymentMethod: Record "Payment Method";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Verify that Vendor ledger entry exist with document type refund when payment method code exist with balancing account

        // Setup: Create payment method code & create purchase return order.
        Initialize();
        CreatePaymentMethodCode(PaymentMethod);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());
        PurchaseHeader.Validate("Payment Method Code", PaymentMethod.Code);

        // Exercise: Post Purchase Return Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verifying vendor ledger entry with document type refund.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Refund, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnOrderPostedAsReceiveWhenReturnShipmentOnCrMemoOptionIsDisabled()
    var
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ExpectedReturnShipmentNo: Code[20];
    begin
        // [FEATURE] [Return Order] [Return Shipment on Credit Memo]
        // [SCENARIO 382442] Return Order posted as "Shipment" should have correct "Document No." according to "Return Shipment No. Series" and "Document Type" in associated Item Ledger Entry

        Initialize();

        // [GIVEN] "Return Shipment on Credit Memo" = "No" in Sales Receivables Setup
        UpdateReturnShipmentOnCrMemoInPurchSetup(false);

        // [GIVEN] Purchase Return Order
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());

        // [GIVEN] Next number from no. series "Return Receipt No. Series" is "X"
        ExpectedReturnShipmentNo :=
          LibraryUtility.GetNextNoFromNoSeries(PurchaseHeader."Return Shipment No. Series", WorkDate());

        // [WHEN] Post Purchase Return Order as "Shipment"
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] The "No." of Posted Shipment is "X"
        ReturnShipmentHeader.SetRange("Pay-to Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        ReturnShipmentHeader.FindFirst();
        ReturnShipmentHeader.TestField("No.", ExpectedReturnShipmentNo);

        // [THEN] "Document Type" in Item Ledger Entry of Return Shipment is "Purchase Return Shipment"
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Purchase Return Shipment");
        ItemLedgerEntry.SetRange("Document No.", ExpectedReturnShipmentNo);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderContactNotEditableBeforeVendorSelected()
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Purchase Return Order Page not editable if no vendor selected
        // [Given]
        Initialize();

        // [WHEN] Purchase Return Order page is opened
        PurchaseReturnOrder.OpenNew();

        // [THEN] Contact Field is not editable
        Assert.IsFalse(PurchaseReturnOrder."Buy-from Contact".Editable(), ContactShouldNotBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderContactEditableAfterVendorSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Purchase Return Order Page  editable if vendor selected
        // [Given]
        Initialize();

        // [Given] A sample Purchase Return Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());

        // [WHEN] Purchase Return Order page is opened
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);

        // [THEN] Contact Field is editable
        Assert.IsTrue(PurchaseReturnOrder."Buy-from Contact".Editable(), ContactShouldBeEditableErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseReturnShipmentReportHandler,PurchaseCreditMemoReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderPostAndPrintCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchPostPrint: Codeunit "Purch.-Post + Print";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 225494] Purchase Credit Memo is printed after Purchase Return Order Post&Print action is invoked
        Initialize();

        // [GIVEN] Posted Purchase Return Order "PRO" with Invoice = TRUE and Ship = TRUE
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());
        UpdatePurchaseHeader(PurchaseHeader, LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Post purchas Return Order is posted and printed
        PurchPostPrint.GetReport(PurchaseHeader)

        // [THEN] Report "Purchase - Credit Memo" ran
        // Verification done by calling (PurchaseReturnShipmentReportHandler and PurchaseCreditMemoReportHandler)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderChangePricesInclVATRefreshesPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrderPage: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 277993] User changes Prices including VAT, page refreshes and shows appropriate captions
        Initialize();

        // [GIVEN] Page with Prices including VAT disabled was open
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '');
        PurchaseReturnOrderPage.OpenEdit();
        PurchaseReturnOrderPage.GotoRecord(PurchaseHeader);

        // [WHEN] User checks Prices including VAT
        PurchaseReturnOrderPage."Prices Including VAT".SetValue(true);

        // [THEN] Caption for PurchaseReturnOrderPage.PurchLines."Direct Unit Cost" field is updated
        Assert.AreEqual('Direct Unit Cost Incl. VAT',
          PurchaseReturnOrderPage.PurchLines."Direct Unit Cost".Caption,
          'The caption for PurchaseReturnOrderPage.PurchLines."Direct Unit Cost" is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderSubpageDocTotalRedistibuteInvDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        CodeCoverage: Record "Code Coverage";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NoOfHits: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 283259] Function DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts is not run when return order page opened
        Initialize();

        // [GIVEN] New purchase return order "PRO"
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);

        // [WNEN] Purchase order card is being opened with return order "PRO"
        CodeCoverageMgt.StartApplicationCoverage();
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        CodeCoverageMgt.StopApplicationCoverage();
        NoOfHits :=
          GetCodeCoverageForObject(
            CodeCoverage."Object Type"::Page,
            PAGE::"Purchase Return Order Subform",
            'PurchaseRedistributeInvoiceDiscountAmounts');

        // [THEN] Function DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts is not run
        Assert.AreEqual(0, NoOfHits, StrSubstNo(FunctionMustNotBeCalledErr, 'PurchaseRedistributeInvoiceDiscountAmounts'));
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesModalPageHandlerWithPostedReceipts,MessageHandlerWithEnqueue')]
    [Scope('OnPrem')]
    procedure GetPostedDocToReverseMessageWhenAlreadyReversed()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 316339] Warning message when trying to Get Posted Doc to Reverse for already reversed Purchase Order
        Initialize();

        // [GIVEN] Posted Purchase Order
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryInventory.CreateItemNo(), LibraryPurchase.CreateVendorNo());
        LibraryVariableStorage.Enqueue(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] Posted Purchase Return Order for Purchase Order
        CreatePurchaseReturnHeader(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.GetPstdDocLinesToReverse();
        LibraryVariableStorage.Enqueue(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] Purchase Return Order and Get Posted Doc to Reverse
        CreatePurchaseReturnHeader(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.");

        // [GIVEN] Stan selected receipt on page Posted Purchase Document Lines
        // done in PostedPurchaseDocumentLinesModalPageHandlerWithPostedReceipts

        // [WHEN] Stan pushes OK on page Posted Purchase Document Lines
        PurchaseHeader.GetPstdDocLinesToReverse();

        // [THEN] Message "One or more return document lines were not copied..."
        Assert.ExpectedMessage(CopyDocForReturnOrderMsg, LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(InsDocForReturnOrderMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinesPageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PostedPurchaseDocumentLines.PostedInvoices.FILTER.SetFilter("Document No.", DocumentNo);
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesModalPageHandlerWithPostedReceipts,MessageHandlerWithEnqueue,ItemTrackingLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure GetPostedDocToReverseWithTrackingMessageWhenAlreadyReversed()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UI] [Item Tracking]
        // [SCENARIO 316339] Warning message when trying to Get Posted Doc to Reverse for already reversed Purchase Order with Item Tracking
        Initialize();

        // [GIVEN] Posted Purchase Order with Item Tracking
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateTrackedItem(), LibraryPurchase.CreateVendorNo());
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
        PurchaseLine.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] Posted Purchase Return Order for Purchase Order
        CreatePurchaseReturnHeader(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.GetPstdDocLinesToReverse();
        LibraryVariableStorage.Enqueue(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] Purchase Return Order and Get Posted Doc to Reverse
        CreatePurchaseReturnHeader(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.");

        // [GIVEN] Stan selected receipt on page Posted Purchase Document Lines
        // done in PostedPurchaseDocumentLinesModalPageHandlerWithPostedReceipts

        // [WHEN] Stan pushes OK on page Posted Purchase Document Lines
        PurchaseHeader.GetPstdDocLinesToReverse();

        // [THEN] Message "One or more return document lines were not copied..."
        Assert.ExpectedMessage(CopyDocForReturnOrderMsg, LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(InsDocForReturnOrderMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullDocTypeName()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Get full document type and name
        // [GIVEN] Purchase Header of type "Return Order"
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::"Return Order";

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Purchase Return Order' is returned
        Assert.AreEqual('Purchase Return Order', PurchaseHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');
    end;

    [Test]
    [HandlerFunctions('PostBatchRequestValuesHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BatchPostPurchRetOrdersRequestValuesNotOverriddenWhenRunInBackground()
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        RequestPageXML: Text;
    begin
        // [SCENARIO] Saved Request page values are not overridden when running the batch job in background.

        // [GIVEN] Saved request page values.
        Initialize();
        LibraryVariableStorage.Enqueue(true);
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Purch. Ret. Orders", RequestPageXML);

        // [WHEN] Running the request page in the background.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Background);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Purch. Ret. Orders", RequestPageXML);

        // [THEN] The saved request page values are not overriden (see PostBatchRequestValuesHandler).

        // [WHEN] Running the request page as desktop.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        asserterror RequestPageXML := Report.RunRequestPage(Report::"Batch Post Purch. Ret. Orders", RequestPageXML);

        // [THEN] The saved request page values are overridden.
    end;

    [Test]
    procedure VerifyBinCodeMustBeBlankWhenLocationIsChangedInPurchaseReturnLine()
    var
        Bin: Record Bin;
        BinNew: Record Bin;
        Item: Record Item;
        Location: Record Location;
        LocationNew: Record Location;
        BinContent: Record "Bin Content";
        BinContentNew: Record "Bin Content";
        ReturnReason: Record "Return Reason";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrderSubform: TestPage "Purchase Return Order Subform";
    begin
        // [SCENARIO 482714] Verify that the Bin Code is blank when the location is changed in the purchase return line.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Inventory);
        Item.Modify(true);

        // [GIVEN] Create a location and set "Bin Mandatory" to true.
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        // [GIVEN] Create another Location and set "Bin Mandatory" to true.
        LibraryWarehouse.CreateLocation(LocationNew);
        LocationNew.Validate("Bin Mandatory", true);
        LocationNew.Modify(true);

        // [GIVEN] Create a bin for both Locations.
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(BinNew, LocationNew.Code, '', '', '');

        // [GIVEN] Create Bin Contents for both Bins.
        LibraryWarehouse.CreateBinContent(
            BinContent,
            Bin."Location Code",
            '',
            Bin.Code,
            Item."No.",
            '',
            Item."Base Unit of Measure");

        LibraryWarehouse.CreateBinContent(
            BinContentNew,
            BinNew."Location Code",
            '',
            BinNew.Code,
            Item."No.",
            '',
            Item."Base Unit of Measure");

        // [GIVEN] Create a return reason code and assign a first location value in "Default Location Code".
        LibraryERM.CreateReturnReasonCode(ReturnReason);
        ReturnReason.Validate("Default Location Code", Location.Code);
        ReturnReason.Modify(true);

        // [GIVEN] Create a new Purchase Return Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());

        // [WHEN] Create a Purchase Return Line and validated its fields.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Return Reason Code", ReturnReason.Code);
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify(true);

        // [VERIFY] Verify that the location code must have a default Location Code in the purchase line.
        Assert.AreEqual(
            PurchaseLine."Location Code",
            ReturnReason."Default Location Code",
            StrSubstNo(
                FieldError,
                PurchaseLine.FieldCaption("Location Code"),
                ReturnReason."Default Location Code",
                PurchaseLine.TableCaption));

        // [WHEN] Update Location Code in Purchase Line.
        PurchaseReturnOrderSubform.OpenEdit();
        PurchaseReturnOrderSubform.GoToRecord(PurchaseLine);
        PurchaseReturnOrderSubform."Location Code".SetValue(LocationNew.Code);
        PurchaseReturnOrderSubform.Close();

        // [VERIFY] Verify that "Bin Code" must be blank in the Purchase Line.
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        Assert.AreEqual(
            '',
            PurchaseLine."Bin Code",
            StrSubstNo(
                FieldError,
                PurchaseLine.FieldCaption("Bin Code"),
                PurchaseLine."Bin Code",
                PurchaseLine.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SuggestItemChargeAssignmentPageHandler,PostedPurchDocumentLinesPageHandler')]
    procedure GetPostedDocumentLinesToReverseCopiesLinesWhenDefaultQtyToReceiveIsBlankInPurchPayablesSetup()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PurchaseReturnOrderSubform: TestPage "Purchase Return Order Subform";
    begin
        // [SCENARIO 500596] Get Posted Document Lines to Reverse action on Purchase Return Order copies Purchase Invoice Lines of Type Item Charge Even when Default Qty to Receive on Purchase & Payables Setup is set to Blank.
        Initialize();

        // [GIVEN] Validate Default Qty. to Receive in Purchase & Payables Setup.
        PurchasePayablesSetup.Get();
        PurchasePayablesSetup.Validate("Default Qty. to Receive", PurchasePayablesSetup."Default Qty. to Receive"::Blank);
        PurchasePayablesSetup.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create an Item Charge.
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Generate and Save Quantity in a Variable.
        Quantity := LibraryRandom.RandIntInRange(25, 25);

        // [GIVEN] Create a Purchase Order with Item Charge.
        CreatePurchaseOrderWithItemCharge(PurchaseHeader, ItemCharge."No.", Item."No.", Quantity);

        // [GIVEN] Set Purchase Order Lines Qty. to Receive.
        SetPurchaseLinesQtyToReceive(PurchaseHeader, Quantity);

        // [GIVEN] Update Qty. to Assign on Item Charge Assignment.
        UpdateQtyToAssignOnItemChargeAssignment(PurchaseHeader);

        // [GIVEN] Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create a Purchase Return Order.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.");

        // [GIVEN] Open Purchase Return Order page and run Get Posted Document Lines to Reverse action.
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GoToRecord(PurchaseHeader2);
        LibraryVariableStorage.Enqueue(ItemCharge."No.");
        PurchaseReturnOrder.GetPostedDocumentLinesToReverse.Invoke();

        // [WHEN] Find Purchase Line of Purchase Return Order.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Return Order");
        PurchaseLine.SetRange("Document No.", PurchaseHeader2."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindFirst();

        // [VERIFY] Return Qty. to Receive in Purchase Line is 0.
        Assert.AreEqual(0, PurchaseLine."Return Qty. to Ship", ReturnQtyToShipMustBeZeroErr);

        // [WHEN] Open Purchase Return Order Subform page.
        PurchaseReturnOrderSubform.OpenEdit();
        PurchaseReturnOrderSubform.GoToRecord(PurchaseLine);

        // [VERIFY] Quantity and Qty. to Assign in Purchase Line are same.
        Assert.AreEqual(
            Quantity,
            PurchaseReturnOrderSubform."Qty. to Assign".AsDecimal(),
            StrSubstNo(
                QtyToAssignErr,
                PurchaseReturnOrderSubform."Qty. to Assign".Caption(),
                Quantity,
                PurchaseReturnOrderSubform.Caption()));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Return Order");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        // Clear global variables.
        ShipReq := false;
        InvReq := false;
        ReplacePostingDate := false;
        ReplaceDocumentDate := false;
        CalcInvDiscount := false;
        PostingDateReq := 0D;

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase Return Order");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase Return Order");
    end;

    local procedure CreatePurchaseOrderWithJob(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20])
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
    begin
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTask.FindFirst();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        CreatePurchaseLineWithJob(PurchaseLine, PurchaseHeader, JobTask."Job No.", JobTask."Job Task No.");
    end;

    local procedure CreatePurchaseLineWithJob(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithLastDirectCost(), LibraryRandom.RandDec(10, 2));  // Use Random Quantity.
        PurchaseLine.Validate("Job No.", JobNo);
        PurchaseLine.Validate("Job Task No.", JobTaskNo);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrderWithJob(VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrderWithJob(PurchaseLine, VendorNo);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateItem(), CreateVendor());
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure CreateAndPostPurchaseOrderWithMultipleLines(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        CreatePurchaseLines(PurchaseLine, PurchaseHeader);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndUpdatePurchRetOrder(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20])
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", BuyFromVendorNo);
        GetPostedLinesFromPurchRetOrdPage(PurchaseHeader."No.");
        UpdatePurchaseLine(PurchaseHeader);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreatePaymentMethodCode(var PaymentMethod: Record "Payment Method")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account No.", GLAccount."No.");
        PaymentMethod.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(500));  // Used RandInt for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(500));  // Used RandInt for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseReturnHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);
        UpdatePurchaseHeader(PurchaseHeader, LibraryUtility.GenerateGUID());
    end;

    local procedure PostPurchaseOrderWithMultipleJobLine(VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrderWithJob(PurchaseLine, VendorNo);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseLineWithJob(PurchaseLine, PurchaseHeader, PurchaseLine."Job No.", PurchaseLine."Job Task No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateTrackedItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode());
        exit(Item."No.");
    end;

    local procedure CreateItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemWithLastDirectCost(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Identifier", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(20));  // Generating VAT with in 20%. Value is not important.
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreatePurchaseLines(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    var
        Counter: Integer;
    begin
        // Using random value because value is not important.
        for Counter := 1 to 1 + LibraryRandom.RandInt(5) do
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(100));
    end;

    local procedure CreatePurchaseReturnOrderByCopyDocument(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; DocType: Enum "Purchase Document Type From"; PurchaseHeaderNo: Code[20]; NewIncludeHeader: Boolean; NewRecalcLines: Boolean)
    begin
        CreatePurchaseReturnHeader(PurchaseHeader, VendorNo);
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, DocType, PurchaseHeaderNo, NewIncludeHeader, NewRecalcLines);
    end;

    local procedure GetCodeCoverageForObject(ObjectType: Option; ObjectID: Integer; CodeLine: Text) NoOfHits: Integer
    var
        CodeCoverage: Record "Code Coverage";
    begin
        CodeCoverageMgt.Refresh();
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        CodeCoverage.SetRange("Object Type", ObjectType);
        CodeCoverage.SetRange("Object ID", ObjectID);
        CodeCoverage.SetFilter("No. of Hits", '>%1', 0);
        CodeCoverage.SetFilter(Line, '@*' + CodeLine + '*');
        if CodeCoverage.FindSet() then
            repeat
                NoOfHits += CodeCoverage."No. of Hits";
            until CodeCoverage.Next() = 0;
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
    end;

    local procedure FindAndDeleteOnePurchaseLine(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Delete();
    end;

    local procedure FindReturnShipmentHeaderNo(OrderNo: Code[20]): Code[20]
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        ReturnShipmentHeader.SetRange("Return Order No.", OrderNo);
        ReturnShipmentHeader.FindFirst();
        exit(ReturnShipmentHeader."No.");
    end;

    local procedure FindPurchCrMemoHeaderNo(OrderNo: Code[20]): Code[20]
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Return Order No.", OrderNo);
        PurchCrMemoHdr.FindFirst();
        exit(PurchCrMemoHdr."No.");
    end;

    local procedure FindPurchCrMemoLine(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; PostedCrMemoNo: Code[20])
    begin
        PurchCrMemoLine.SetRange("Document No.", PostedCrMemoNo);
        PurchCrMemoLine.SetRange(Type, PurchCrMemoLine.Type::Item);
        PurchCrMemoLine.FindFirst();
    end;

    local procedure FindReturnShipmentLineNo(DocumentNo: Code[20]): Integer
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        ReturnShipmentLine.SetRange("Document No.", DocumentNo);
        ReturnShipmentLine.FindFirst();
        exit(ReturnShipmentLine."Line No.");
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure CopyDocument(PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20])
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters("Purchase Document Type From"::Order, DocumentNo, true, false);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run();
    end;

    local procedure CreateInvoiceDiscount(var VendorInvoiceDisc: Record "Vendor Invoice Disc.")
    begin
        // Enter Random Values for "Minimum Amount" and "Discount %".
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, CreateVendor(), '', LibraryRandom.RandInt(100));
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandInt(10));
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreatePurchRetOrderGetPstdDocLineToRev(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", BuyFromVendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        GetPostedDocToReverseOnPurchReturnOrder(PurchaseHeader."No.");
    end;

    local procedure GetPostedDocToReverseOnPurchReturnOrder(No: Code[20])
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", No);
        PurchaseReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure GetPostedLinesFromPurchRetOrdPage(No: Code[20])
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", No);
        PurchaseReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure GetReturnShipmentLine(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Return Shipments", PurchaseLine);
    end;

    local procedure ModifyPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity / LibraryRandom.RandIntInRange(2, 4));
        PurchaseLine.Modify(true);
    end;

    local procedure ModifyPurchaseLineVATProdPostingGroup(var PurchaseLine: Record "Purchase Line"; VATProductPostingGroup: Code[20])
    begin
        PurchaseLine.Validate("VAT Prod. Posting Group", VATProductPostingGroup);
        PurchaseLine.Modify(true);
    end;

    local procedure RunBatchPostPurchaseReturnOrders(var PurchaseHeader: Record "Purchase Header")
    var
        BatchPostPurchRetOrders: Report "Batch Post Purch. Ret. Orders";
    begin
        Commit();  // COMMIT need before run report.

        // Set filter to current record.
        PurchaseHeader.SetRecFilter();

        Clear(BatchPostPurchRetOrders);
        BatchPostPurchRetOrders.SetTableView(PurchaseHeader);
        BatchPostPurchRetOrders.Run();
    end;

    local procedure PurchaseReturnOrderWithCopyDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        CreatePurchaseReturnHeader(PurchaseHeader, CreateVendor());
        LibraryPurchase.CopyPurchaseDocument(
          PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", CreateAndPostPurchaseOrderWithJob(PurchaseHeader."Buy-from Vendor No."), false, false);
        ModifyPurchaseLine(PurchaseLine, PurchaseHeader);
    end;

    local procedure SetupLineDiscount(var PurchaseLineDiscount: Record "Purchase Line Discount")
    var
        Item: Record Item;
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Enter Random Values for "Minimum Quantity" and "Line Discount %".
        Item.Get(CreateItem());
        LibraryERM.CreateLineDiscForVendor(
          PurchaseLineDiscount, Item."No.", CreateVendor(), WorkDate(), '', '', Item."Base Unit of Measure", LibraryRandom.RandInt(10));
        PurchaseLineDiscount.Validate("Line Discount %", LibraryRandom.RandInt(10));
        PurchaseLineDiscount.Modify(true);
    end;

    local procedure UpdatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorCrMemoNo: Code[35])
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", VendorCrMemoNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdatePurchaseLine(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate("Appl.-to Item Entry", 0);  // Required for TC to check posting in case of 'Appl.-to Item Entry' is 0.
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateInventorySetup(AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Adjustment", AutomaticCostAdjustment);
        InventorySetup.Modify(true);
    end;

    local procedure UpdatePurchasesPayablesSetup(ExactCostReversingMandatory: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateExactCostReversingMandatory(NewExactCostReversingMandatory: Boolean)
    var
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasePayablesSetup.Get();
        PurchasePayablesSetup.Validate("Exact Cost Reversing Mandatory", NewExactCostReversingMandatory);
        PurchasePayablesSetup.Modify(true);
    end;

    local procedure UpdateReturnShipmentOnCrMemoInPurchSetup(NewReturnShptOnCrMemo: Boolean)
    var
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasePayablesSetup.Get();
        PurchasePayablesSetup.Validate("Return Shipment on Credit Memo", NewReturnShptOnCrMemo);
        PurchasePayablesSetup.Modify(true);
    end;

    local procedure VerifyPostedPurchaseEntry(ReturnOrderNo: Code[20]; Amount: Decimal)
    var
        ReturnShipmentLine: Record "Return Shipment Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalAmount: Decimal;
    begin
        ReturnShipmentLine.SetRange("Return Order No.", ReturnOrderNo);
        ReturnShipmentLine.FindSet();
        repeat
            TotalAmount += ReturnShipmentLine.Quantity * ReturnShipmentLine."Direct Unit Cost";
        until ReturnShipmentLine.Next() = 0;
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          Amount, TotalAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(LineAmountError, Amount, ReturnShipmentLine.TableCaption()));
    end;

    local procedure VerifyPostedCreditMemo(ReturnOrderNo: Code[20]; AppliestoDocNo: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Return Order No.", ReturnOrderNo);
        PurchCrMemoHdr.FindFirst();
        Assert.AreEqual(PurchCrMemoHdr."Applies-to Doc. Type"::Invoice, PurchCrMemoHdr."Applies-to Doc. Type"::Invoice,
          StrSubstNo(
            FieldError, PurchCrMemoHdr.FieldCaption("Applies-to Doc. Type"), PurchCrMemoHdr."Applies-to Doc. Type"::Invoice,
            PurchCrMemoHdr.TableCaption()));
        Assert.AreEqual(
          AppliestoDocNo, PurchCrMemoHdr."Applies-to Doc. No.",
          StrSubstNo(FieldError, PurchCrMemoHdr.FieldCaption("Applies-to Doc. No."), AppliestoDocNo, PurchCrMemoHdr.TableCaption()));
    end;

    local procedure VerifyGLEntry(ReturnOrderNo: Code[20]; Amount: Decimal)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GLEntry: Record "G/L Entry";
    begin
        PurchCrMemoHdr.SetRange("Return Order No.", ReturnOrderNo);
        PurchCrMemoHdr.FindFirst();
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::"Credit Memo");
        GLEntry.SetRange("Document No.", PurchCrMemoHdr."No.");
        GLEntry.SetFilter(Amount, '>0');
        GLEntry.FindLast();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyItemLedgerEntry(PurchaseLine: Record "Purchase Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.SetRange("Document No.", FindReturnShipmentHeaderNo(PurchaseLine."Document No."));
        ItemLedgerEntry.SetRange("Item No.", PurchaseLine."No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreNearlyEqual(
          ItemLedgerEntry."Invoiced Quantity", PurchaseLine."Qty. to Invoice", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(InvoicedQuantityError, PurchaseLine."Qty. to Invoice"));
        Assert.AreNearlyEqual(
          ItemLedgerEntry."Cost Amount (Actual)", PurchaseLine."Qty. to Invoice" * PurchaseLine."Direct Unit Cost",
          LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(CostAmountActualError, PurchaseLine."Qty. to Invoice" * PurchaseLine."Direct Unit Cost"));
    end;

    local procedure VerifyValueEntry(No: Code[20]; Quantity: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", FindReturnShipmentHeaderNo(No));
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.");
        ValueEntry.FindFirst();
        Assert.AreNearlyEqual(
          ValueEntry."Item Ledger Entry Quantity", Quantity, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ItemLedgerQuantityError, ValueEntry."Item Ledger Entry Quantity"));
    end;

    local procedure VerifyVendorLedgerEntry(ReturnOrderNo: Code[20]; Amount: Decimal)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        PurchCrMemoHdr.SetRange("Return Order No.", ReturnOrderNo);
        PurchCrMemoHdr.FindFirst();
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
        VendorLedgerEntry.SetRange("Document No.", PurchCrMemoHdr."No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);
        Assert.AreNearlyEqual(
          Amount, VendorLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, VendorLedgerEntry.FieldCaption(Amount), Amount, VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type"; VATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          VATAmount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(VATAmountError, VATEntry.FieldCaption(Amount), VATEntry.Amount, VATEntry.TableCaption()));
    end;

    local procedure VerifyValueEntries(ReturnOrderNo: Code[20]; CostAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ValueEntry: Record "Value Entry";
        TotalCostAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        PurchCrMemoHdr.SetRange("Return Order No.", ReturnOrderNo);
        PurchCrMemoHdr.FindFirst();
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Credit Memo");
        ValueEntry.SetRange("Document No.", PurchCrMemoHdr."No.");
        ValueEntry.FindSet();
        repeat
            TotalCostAmount += ValueEntry."Cost Amount (Actual)";
        until ValueEntry.Next() = 0;
        Assert.AreNearlyEqual(
          -CostAmount, TotalCostAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldError, ValueEntry.FieldCaption("Cost Amount (Actual)"), TotalCostAmount, ValueEntry.TableCaption()));
    end;

    local procedure VerifyLineDiscountAmount(ReturnOrderNo: Code[20]; LineDiscountAmount: Decimal)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        PurchCrMemoHdr.SetRange("Return Order No.", ReturnOrderNo);
        PurchCrMemoHdr.FindFirst();
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");
        PurchCrMemoLine.FindFirst();
        Assert.AreNearlyEqual(LineDiscountAmount, PurchCrMemoLine."Line Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldError, PurchCrMemoLine.FieldCaption("Line Discount Amount"), LineDiscountAmount, PurchCrMemoLine.TableCaption()));
    end;

    local procedure VerifyInvoiceDiscountAmount(ReturnOrderNo: Code[20]; InvoiceDiscountAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        PurchCrMemoHdr.SetRange("Return Order No.", ReturnOrderNo);
        PurchCrMemoHdr.FindFirst();
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
        VendorLedgerEntry.SetRange("Document No.", PurchCrMemoHdr."No.");
        VendorLedgerEntry.FindFirst();
        Assert.AreNearlyEqual(
          InvoiceDiscountAmount, VendorLedgerEntry."Inv. Discount (LCY)", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            FieldError, VendorLedgerEntry.FieldCaption("Inv. Discount (LCY)"), InvoiceDiscountAmount, VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyLocationOnCreditMemo(ReturnOrderNo: Code[20]; LocationCode: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoHdr.SetRange("Return Order No.", ReturnOrderNo);
        PurchCrMemoHdr.FindFirst();
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");
        PurchCrMemoLine.FindFirst();
        Assert.AreEqual(
          LocationCode, PurchCrMemoLine."Location Code",
          StrSubstNo(FieldError, PurchCrMemoLine.FieldCaption("Location Code"), LocationCode, PurchCrMemoLine.TableCaption()));
    end;

    local procedure VerifyCurrencyOnPostedOrder(ReturnOrderNo: Code[20]; CurrencyCode: Code[10])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Return Order No.", ReturnOrderNo);
        PurchCrMemoHdr.FindFirst();
        Assert.AreEqual(
          CurrencyCode, PurchCrMemoHdr."Currency Code",
          StrSubstNo(FieldError, PurchCrMemoHdr.FieldCaption("Currency Code"), CurrencyCode, PurchCrMemoHdr.TableCaption()));
    end;

    local procedure VerifyReturnShipmentLine(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        ReturnShipmentLine.SetRange("Document No.", DocumentNo);
        ReturnShipmentLine.FindFirst();
        ReturnShipmentLine.TestField("No.", PurchaseLine."No.");
        ReturnShipmentLine.TestField(Quantity, PurchaseLine.Quantity);
    end;

    local procedure VerifyReturnShipment(PostedCrMemoNo: Code[20]; PostedDocumentNo: Code[20])
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        FindPurchCrMemoLine(PurchCrMemoLine, PostedCrMemoNo);
        PurchCrMemoLine.TestField("Return Shipment No.", PostedDocumentNo);
        PurchCrMemoLine.TestField("Return Shipment Line No.", FindReturnShipmentLineNo(PostedDocumentNo));
    end;

    local procedure VerifyPurchCrMemoLine(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.FindFirst();
        PurchCrMemoLine.TestField("No.", PurchaseLine."No.");
        PurchCrMemoLine.TestField(Quantity, PurchaseLine.Quantity);
    end;

    local procedure VerifyItemAndDocTypeOnItemLedgerEntry(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Item No.", ItemNo);
        ItemLedgerEntry.TestField("Document Type", ItemLedgerEntry."Document Type"::"Purchase Return Shipment");
    end;

    local procedure VerifyPurchaseReturnOrderLine(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.TestField("Appl.-to Item Entry");
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessage)) then;
    end;

    local procedure CreatePurchaseOrderWithItemCharge(
        var PurchaseHeader: Record "Purchase Header";
        ItemChargeNo: Code[20];
        ItemNo: Code[20];
        Quantity: Decimal)
    var
        PurchaseLineItemCharge: Record "Purchase Line";
        PurchaseLineItem: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLineItem,
            PurchaseHeader,
            PurchaseLineItem.Type::Item,
            ItemNo,
            Quantity);

        PurchaseLineItem.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLineItem.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLineItemCharge,
            PurchaseHeader,
            PurchaseLineItemCharge.Type::"Charge (Item)",
            ItemChargeNo,
            Quantity);

        PurchaseLineItemCharge.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLineItemCharge.Modify(true);
    end;

    local procedure SetPurchaseLinesQtyToReceive(var PurchaseHeader: Record "Purchase Header"; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
        repeat
            PurchaseLine.Validate("Qty. to Receive", Quantity);
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    local procedure UpdateQtyToAssignOnItemChargeAssignment(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindFirst();
        PurchaseLine.ShowItemChargeAssgnt();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostPurchReturnOrderHandler(var BatchPostPurchRetOrders: TestRequestPage "Batch Post Purch. Ret. Orders")
    begin
        BatchPostPurchRetOrders.Ship.SetValue(ShipReq);
        BatchPostPurchRetOrders.Invoice.SetValue(InvReq);
        BatchPostPurchRetOrders.PostingDate.SetValue(PostingDateReq);
        BatchPostPurchRetOrders.ReplacePostingDate.SetValue(ReplacePostingDate);
        BatchPostPurchRetOrders.ReplaceDocumentDate.SetValue(ReplaceDocumentDate);
        BatchPostPurchRetOrders.CalcInvDiscount.SetValue(CalcInvDiscount);
        BatchPostPurchRetOrders.OK().Invoke();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoReportHandler(var PurchaseCreditMemo: Report "Purchase - Credit Memo")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure PurchaseReturnShipmentReportHandler(var PurchaseReturnShipment: Report "Purchase - Return Shipment")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageVerificationHandler(Message: Text[1024])
    var
        DequeueVariable: Variant;
        ExpectedMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ExpectedMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerWithEnqueue(Message: Text)
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinesHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentType: Option "Posted Receipts","Posted Invoices","Posted Return Shipments","Posted Cr. Memos";
    begin
        PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Invoices"));
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinesModalPageHandlerWithPostedReceipts(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    begin
        PostedPurchaseDocumentLines.PostedRcpts.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        PostedPurchaseDocumentLines.First();
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnShipmentLinesPageHandler(var GetReturnShipmentLines: TestPage "Get Return Shipment Lines")
    begin
        GetReturnShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchDocumentLinesPageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    begin
        PostedPurchaseDocumentLines.PostedInvoices.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SuggestItemChargeAssignmentPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBatchRequestValuesHandler(var PostBatchForm: TestRequestPage "Batch Post Purch. Ret. Orders")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();

        if LibraryVariableStorage.DequeueBoolean() then begin
            PostBatchForm.Ship.SetValue(true);
            PostBatchForm.Invoice.SetValue(true);
            PostBatchForm.PostingDate.SetValue(20200101D);
            PostBatchForm.ReplacePostingDate.SetValue(true);
            PostBatchForm.ReplaceDocumentDate.SetValue(true);
            PostBatchForm.CalcInvDiscount.SetValue(not PurchasesPayablesSetup."Calc. Inv. Discount");
            PostBatchForm.PrintDoc.SetValue(true);
            PostBatchForm.OK().Invoke();
        end else begin
            Assert.AreEqual(PostBatchForm.Ship.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.Invoice.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.PostingDate.AsDate(), 20200101D, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplacePostingDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplaceDocumentDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(
                PostBatchForm.CalcInvDiscount.AsBoolean(),
                not PurchasesPayablesSetup."Calc. Inv. Discount",
                'Expected value to be restored.'
            );
            Assert.AreEqual(PostBatchForm.PrintDoc.AsBoolean(), true, 'Expected value to be restored.');
        end;
    end;
}
