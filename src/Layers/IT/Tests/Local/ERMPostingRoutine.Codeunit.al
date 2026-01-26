codeunit 144069 "ERM Posting Routine"
{
    //  // [FEATURE] [Post]
    //  Test for feature - POSTROUT - Posting Routine.
    //  1. Test to verify error while posting Purchase Order with already posted Purchase Order with same vendor and vendor invoice number.
    //  2. Test to verify error while posting Purchase Invoice with Posting Date before Last Date Used of Number Series.
    //  3. Test to verify error while posting Sales Invoice with Posting Date before Last Date Used on Number Series.
    //  4. Test to verify error while posting Purchase Order with Operation Occurred date Prior To Last Printing Date of General Ledger Setup.
    //  5. Test to verify error while posting Service Invoice with Operation Occurred date Prior To Last Printing Date of General Ledger Setup.
    //  6. Test to verify error while posting Sales Order with Operation Occurred date Prior To Last Printing Date of General Ledger Setup.
    //  7. Test to verify error for Date order while posting Sales Invoice with Operation type associated with the No. Series having Date Order FALSE.
    //  8. Test to verify error for Date order while posting Sales Order with Operation type associated with the No. Series having Date Order FALSE.
    //  9. Test to verify error for Date order while posting Sales Credit Memo with Operation type associated with the No. Series having Date Order FALSE.
    // 10. Test to verify error for Date order while posting Sales Order with Operation type associated with the No. Series having Date Order FALSE.
    // 11. Test to verify error for Date order while posting Purchase Invoice with Operation type associated with the No. Series having Date Order FALSE.
    // 12. Test to verify error for Date order while posting Purchase Order with Operation type associated with the No. Series having Date Order FALSE.
    // 13. Test to verify error for Date order while posting Purchase Credit Memo with Operation type associated with the No. Series having Date Order FALSE.
    // 14. Test to verify error for Date order while posting Purchase Return Order with Operation type associated with the No. Series having Date Order FALSE.
    // 
    //   Covers Test Cases for WI - 345136
    //   --------------------------------------------------------------------------------------------
    //   Test Function Name                                                                   TFS ID
    //   --------------------------------------------------------------------------------------------
    //   PurchaseInvoiceAlreadyExistsError                                                    152668
    //   PurchaseInvoiceNumberSeriesDateError                                                 152733
    //   SalesInvoiceNumberSeriesDateError                                             152723,152731
    //   PurchOrderOperationOccurredPriorToLastPrintingDateError                       152750,152756
    //   ServiceInvOperationOccurredPriorToLastPrintingDateError                       152751,152758
    // 
    //   Covers Test Cases for WI - 345135
    //   --------------------------------------------------------------------------------------------
    //   Test Function Name                                                                   TFS ID
    //   --------------------------------------------------------------------------------------------
    //   SalesOrderOperationOccurredPriorToLastPrintingDateError                       152749,152753
    //   DateOrderPostSalesInvoiceError                                                       152706
    //   DateOrderPostSalesOrderError                                                         152705
    //   DateOrderPostSalesCreditMemoError                                                    152707
    //   DateOrderPostReturnOrderError                                                        152708
    //   DateOrderPostPurchaseInvoiceError                                                    152711
    //   DateOrderPostPurchaseOrderError                                                      152710
    //   DateOrderPostPurchaseCreditMemoError                                                 152714
    //   DateOrderPostPurchaseReturnOrderError                                                152715

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        PurchaseInvoiceExistsErr: Label 'Purchase Invoice %1 already exists for this vendor';
        NumberSeriesLastDateUsedErr: Label 'You cannot assign new numbers from the number series %1 on a date before %2.';
        SalesDocLastGenJourPrintingDateErr: Label 'Operation Occurred Date must not be prior to %1 in Sales Header Document Type=''%2'',No.=''%3''.';
        ServiceDocLastGenJourPrintingDateErr: Label 'Operation Occurred Date must not be prior to %1 in Service Header Document Type=''%2'',No.=''%3''.';
        PurchDocLastGenJourPrintingDateErr: Label 'Operation Occurred Date must not be prior to %1 in Purchase Header Document Type=''%2'',No.=''%3''.';
        DateOrderErr: Label 'Date Order must have a value in No. Series:';
        InvalidAppliesToOccNoErr: Label 'Invalid Applies-to Occurence No.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        CopyDocDateOrderConfirmMsg: Label 'The Posting Date of the copied document is different from the Posting Date of the original document. The original document already has a Posting No. based on a number series with date order. When you post the copied document, you may have the wrong date order in the posted documents.\Do you want to continue?';
        DocumentShouldNotBeCopiedErr: Label 'Document should not be copied';
        DocumentShouldBeCopiedErr: Label 'Document should be copied';
        WrongConfirmationMsgErr: Label 'Wrong confirmation message';
        isInitialized: Boolean;
        VATIdentifierMustHaveValueErr: Label 'VAT Identifier must have a value';
        TestfieldErr: Label 'TestField';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceAlreadyExistsError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
    begin
        // Setup: Create and Post Purchase Order, Create Purchase Order with same Vendor and Vendor invoice number already Posted Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, true);  // Date Order - True.
        CreatePurchaseDocument(PurchaseHeader2, PurchaseHeader2."Document Type"::Order, true);  // Date Order - True.
        PurchaseHeader2.Validate("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader2.Validate("Vendor Invoice No.", PurchaseHeader."Vendor Invoice No.");
        PurchaseHeader2.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Post Purchase Order with same Vendor and Vendor Invoice number of already Posted Purchase Order.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // Verify: Verify Error: Purchase Invoice already exists for this vendor.
        Assert.ExpectedError(StrSubstNo(PurchaseInvoiceExistsErr, PurchaseHeader."Vendor Invoice No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceNumberSeriesDateError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        LastDateUsed: Date;
    begin
        // Setup: Create Purchase Invoice, Update Posting Date before Number Series Line - Last Date Used.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, true);  // Date Order - True.
        PurchasesPayablesSetup.Get();
        LastDateUsed := FindNoSeriesLine(PurchasesPayablesSetup."Invoice Nos.");
        PurchaseHeader.Validate(
          "Posting Date", CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', LastDateUsed));  // Posting Date Earlier than No. Series Line - Last Date Used.
        PurchaseHeader.Modify(true);

        // Exercise: Post Purchase Invoice with Posting Date before Last Date Used of Number Series.
        PurchaseHeader.Receive := true;
        PurchaseHeader.Ship := true;
        PurchaseHeader.Invoice := true;
        asserterror Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader);

        // Verify: Verify Error: You cannot assign new numbers from the number series on a date before Number Series Line - Last Date Used.
        Assert.ExpectedError(StrSubstNo(NumberSeriesLastDateUsedErr, PurchaseHeader."Operation Type", LastDateUsed));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceNumberSeriesDateError()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LastDateUsed: Date;
    begin
        // Setup: Create Sales Invoice, Update Posting Date before Number Series Line - Last Date Used.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, true);  // Date Order - True.
        SalesReceivablesSetup.Get();
        LastDateUsed := FindNoSeriesLine(SalesReceivablesSetup."Invoice Nos.");
        SalesHeader.Validate(
          "Posting Date", CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', LastDateUsed));  // Posting Date Earlier than No. Series Line - Last Date Used.
        SalesHeader.Modify(true);

        // Exercise: Post Sales Invoice with Posting Date before Last Date Used of Number Series used on Purchase Invoice.
        SalesHeader.Ship := true;
        SalesHeader.Receive := true;
        SalesHeader.Invoice := true;
        asserterror Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);

        // Verify: Verify Error: You cannot assign new numbers from the number series on a date before Number Series Line - Last Date Used.
        Assert.ExpectedError(StrSubstNo(NumberSeriesLastDateUsedErr, SalesHeader."Operation Type", LastDateUsed));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderOperationOccurredPriorToLastPrintingDateError()
    var
        PurchaseHeader: Record "Purchase Header";
        NewLastGenJourPrintingDate: Date;
    begin
        // Setup: Update General Ledger Setup - Last Gen. Jour. Printing Date, Create Purchase Order.
        Initialize();
        NewLastGenJourPrintingDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());  // Last Gen. Jour. Printing Date after WORKDATE.
        UpdateGLSetupLastGenJourPrintingDate(NewLastGenJourPrintingDate);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, true);  // Date Order - True.

        // Exercise: Post Purchase Order.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Error: Operation Occurred Date must not be prior to General Ledger Setup - Last Gen. Jour. Printing Date in Purchase Order.
        Assert.ExpectedError(
          StrSubstNo(PurchDocLastGenJourPrintingDateErr, NewLastGenJourPrintingDate, PurchaseHeader."Document Type", PurchaseHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvOperationOccurredPriorToLastPrintingDateError()
    var
        ServiceHeader: Record "Service Header";
        NewLastGenJourPrintingDate: Date;
    begin
        // Setup: Update General Ledger Setup - Last Gen. Jour. Printing Date, Create Service Invoice.
        Initialize();
        NewLastGenJourPrintingDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());  // Last Gen. Jour. Printing Date after WORKDATE.
        UpdateGLSetupLastGenJourPrintingDate(NewLastGenJourPrintingDate);
        CreateServiceInvoice(ServiceHeader);

        // Exercise.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // Post as Ship and Invoice.

        // Verify: Verify Error: Operation Occurred Date must not be prior to General Ledger Setup - Last Gen. Jour. Printing Date in Service Invoice.
        Assert.ExpectedError(
          StrSubstNo(ServiceDocLastGenJourPrintingDateErr, NewLastGenJourPrintingDate, ServiceHeader."Document Type", ServiceHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderOperationOccurredPriorToLastPrintingDateError()
    var
        SalesHeader: Record "Sales Header";
        NewLastGenJourPrintingDate: Date;
    begin
        // Setup: Update General Ledger Setup - Last Gen. Jour. Printing Date, Create Sales Order.
        Initialize();
        NewLastGenJourPrintingDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());  // Last Gen. Jour. Printing Date after WORKDATE.
        UpdateGLSetupLastGenJourPrintingDate(NewLastGenJourPrintingDate);
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, true);  // Date Order - True.

        // Exercise: Post Sales Order.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Error: Operation Occurred Date must not be prior to General Ledger Setup - Last Gen. Jour. Printing Date in Sales Order.
        Assert.ExpectedError(
          StrSubstNo(SalesDocLastGenJourPrintingDateErr, NewLastGenJourPrintingDate, SalesHeader."Document Type", SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateOrderPostSalesInvoiceError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Post Sales Invoice with Operation type associated with the No. Series having Date Order FALSE.
        DateOrderPostSalesDocument(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateOrderPostSalesOrderError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Post Sales Order with Operation type associated with the No. Series having Date Order FALSE.
        DateOrderPostSalesDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateOrderPostSalesCreditMemoError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Post Sales Credit Memo with Operation type associated with the No. Series having Date Order FALSE.
        DateOrderPostSalesDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateOrderPostReturnOrderError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Post Sales Return Order with Operation type associated with the No. Series having Date Order FALSE.
        DateOrderPostSalesDocument(SalesHeader."Document Type"::"Return Order");
    end;

    local procedure DateOrderPostSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        NoSeriesCode: Code[20];
    begin
        // Setup: Create Sales Document with Operation type associated with the No. Series having Date Order FALSE.
        Initialize();
        CreateSalesDocument(SalesHeader, DocumentType, false);  // Date Order - False.
        NoSeriesCode := SalesHeader."Operation Type";
        UpdateNoSeries(NoSeriesCode, false);  // Date Order - False.

        // Exercise: Post Sales Document.
        SalesHeader.Ship := true;
        SalesHeader.Receive := true;
        SalesHeader.Invoice := true;
        asserterror Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);

        // Verify: Verify error, Date Order must have a value in No. Series.
        Assert.ExpectedError(DateOrderErr);

        // Teardown.
        UpdateNoSeries(NoSeriesCode, true);  // Date Order - True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateOrderPostPurchaseInvoiceError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Post Purchase Invoice with Operation type associated with the No. Series having date Order FALSE.
        DateOrderPostPurchaseDocument(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateOrderPostPurchaseOrderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Post Purchase Order with Operation type associated with the No. Series having date Order FALSE.
        DateOrderPostPurchaseDocument(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateOrderPostPurchaseCreditMemoError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Post Purchase Credit Memo Order with Operation type associated with the No. Series having date Order FALSE.
        DateOrderPostPurchaseDocument(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateOrderPostPurchaseReturnOrderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Post Purchase Return Order with Operation type associated with the No. Series having date Order FALSE.
        DateOrderPostPurchaseDocument(PurchaseHeader."Document Type"::"Return Order");
    end;

    local procedure DateOrderPostPurchaseDocument(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        NoSeriesCode: Code[20];
    begin
        // Setup: Create Purchase Document with Operation type associated with the No. Series having date Order FALSE.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, DocumentType, false);  // Date Order - False.
        NoSeriesCode := PurchaseHeader."Operation Type";
        UpdateNoSeries(NoSeriesCode, false);  // Date Order - False.

        // Exercise: Post Purchase Document.
        PurchaseHeader.Receive := true;
        PurchaseHeader.Ship := true;
        PurchaseHeader.Invoice := true;
        asserterror Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader);

        // Verify: Verify error, Date Order must have a value in No. Series.
        Assert.ExpectedError(DateOrderErr);

        // Teardown.
        UpdateNoSeries(NoSeriesCode, true);  // Date Order - True.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AppliesToOccurenceNoForCopySalesDocument()
    var
        SalesHeader: Record "Sales Header";
        PostedInvoiceNo: Code[20];
    begin
        // Verify that Applies-to Occurence No. is filled in during the copy sales document function

        // SETUP
        Initialize();

        // Create and post sales invoice
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, true);
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // Create credit memo
        CreateSalesDocumentForCustomer(SalesHeader, SalesHeader."Document Type"::"Credit Memo", true, SalesHeader."Sell-to Customer No.");

        // EXERSIZE
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", PostedInvoiceNo, true, false);

        // VERIFY
        VerifySalesHeaderAppliesToOccurenceNo(SalesHeader, PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AppliesToOccurenceNoForCopyPurchDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedInvoiceNo: Code[20];
    begin
        // Verify that Applies-to Occurence No. is filled in during the copy purchase document function

        // SETUP
        Initialize();

        // Create and post purchase invoice
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, true);
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // Create credit memo
        CreatePurchaseDocumentForVendor(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", true, PurchaseHeader."Pay-to Vendor No.");

        // EXERSIZE
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", PostedInvoiceNo, true, false);

        // VERIFY
        VerifyPurchHeaderAppliesToOccurenceNo(PurchaseHeader, PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmCopyDocDateOrderHandlerVerify')]
    [Scope('OnPrem')]
    procedure CopySalesPostedInvShptDateOrderNonConfirm()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedDocNo: Code[20];
        InitialPostingDate: Date;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Posted Sales Invoice and Shipment with Date Order enabled and user not accepted confirmation
        Initialize();

        // [GIVEN] Posted Sales Invoice with Posting Date = "X"
        CreateSalesDocumentForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, true, LibrarySales.CreateCustomerNo());
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Sales Document with Posting Date = "X" + 1 day and Posting No. assigned
        CreateSalesDocumentWithPostingNo(
          SalesHeader, SalesHeader."Sell-to Customer No.",
          LibraryRandom.RandInt(5), PostedDocNo);
        InitialPostingDate := SalesHeader."Posting Date";
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Copy Document from Posted Sales Invoice to Sales Document with Include Header = TRUE
        CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", PostedDocNo);
        SalesHeader.Find();

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        Assert.AreEqual(InitialPostingDate, SalesHeader."Posting Date", DocumentShouldNotBeCopiedErr);

        // [WHEN] Run Copy Document from Posted Sales Shipment to Sales Document with Include Header = TRUE
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentHeader.FindFirst();
        LibraryVariableStorage.Enqueue(false);
        CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Shipment", SalesShipmentHeader."No.");
        SalesHeader.Find();

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        Assert.AreEqual(InitialPostingDate, SalesHeader."Posting Date", DocumentShouldNotBeCopiedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmCopyDocDateOrderHandlerVerify')]
    [Scope('OnPrem')]
    procedure CopySalesPostedCrMemoRetRecDateOrderNonConfirm()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderDst: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PostedDocNo: Code[20];
        InitialPostingDate: Date;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Posted Sales Credit Memo and Return Receipt with Date Order enabled and user not accepted confirmation
        Initialize();

        // [GIVEN] Posted Credit Memo with Posting Date = "X"
        CreateSalesDocumentForCustomer(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", true, LibrarySales.CreateCustomerNo());
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Sales Document with Posting Date = "X" + 1 day and Posting No. assigned
        CreateSalesDocumentWithPostingNo(
          SalesHeaderDst, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandInt(5), PostedDocNo);
        InitialPostingDate := SalesHeaderDst."Posting Date";
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Copy Document from Posted Sales Cr. Memo to Sales Document with Include Header = TRUE
        CopySalesDocument(SalesHeaderDst, "Sales Document Type From"::"Posted Credit Memo", PostedDocNo);

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        SalesHeaderDst.Find();
        Assert.AreEqual(InitialPostingDate, SalesHeaderDst."Posting Date", DocumentShouldNotBeCopiedErr);

        // [WHEN] Run Copy Document from Posted Return Receipt to Sales Document with Include Header = TRUE
        ReturnReceiptHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        ReturnReceiptHeader.FindFirst();
        LibraryVariableStorage.Enqueue(false);
        CopySalesDocument(SalesHeaderDst, "Sales Document Type From"::"Posted Return Receipt", ReturnReceiptHeader."No.");
        SalesHeaderDst.Find();

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        Assert.AreEqual(InitialPostingDate, SalesHeaderDst."Posting Date", DocumentShouldBeCopiedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmCopyDocDateOrderHandlerVerify')]
    [Scope('OnPrem')]
    procedure CopySalesQuoteDateOrderNonConfirm()
    var
        SalesHeaderSrc: Record "Sales Header";
        SalesHeaderDst: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Sales Quote with Date Order enabled and user not accepted confirmation
        Initialize();

        // [GIVEN] Sales Quote with Posting Date = "X"
        LibrarySales.CreateSalesHeader(SalesHeaderSrc, SalesHeaderSrc."Document Type"::Quote, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Document with Posting Date = "X" + 1 day and Posting No. assigned
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateSalesDocumentWithPostingNo(
          SalesHeaderDst, CustomerNo, LibraryRandom.RandInt(5),
          LibraryUtility.GenerateRandomCode(SalesHeaderDst.FieldNo("Posting No."), DATABASE::"Sales Header"));
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Copy Document from Sales Quote to Sales Document with Include Header = TRUE
        CopySalesDocument(SalesHeaderDst, "Sales Document Type From"::Quote, SalesHeaderSrc."No.");

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        SalesHeaderDst.Find();
        Assert.AreEqual(CustomerNo, SalesHeaderDst."Sell-to Customer No.", DocumentShouldBeCopiedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopySalesQuoteDateOrderConfirm()
    var
        SalesHeaderSrc: Record "Sales Header";
        SalesHeaderDst: Record "Sales Header";
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Sales Quote with Date Order enabled and user accepted confirmation
        Initialize();

        // [GIVEN] Sales Quote with Posting Date = "X"
        LibrarySales.CreateSalesHeader(SalesHeaderSrc, SalesHeaderSrc."Document Type"::Quote, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Document with Posting Date = "X" + 1 day and Posting No. assigned
        CreateSalesDocumentWithPostingNo(
          SalesHeaderDst, LibrarySales.CreateCustomerNo(), LibraryRandom.RandInt(5),
          LibraryUtility.GenerateRandomCode(SalesHeaderDst.FieldNo("Posting No."), DATABASE::"Sales Header"));

        // [WHEN] Run Copy Document from Sales Quote to Sales Document with Include Header = TRUE
        CopySalesDocument(SalesHeaderDst, "Sales Document Type From"::Quote, SalesHeaderSrc."No.");

        // [THEN] Confirmation dialog appears with warning and Document is copied after user confirmation
        SalesHeaderDst.Find();
        Assert.AreEqual(SalesHeaderSrc."Sell-to Customer No.", SalesHeaderDst."Sell-to Customer No.", DocumentShouldBeCopiedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmCopyDocDateOrderHandlerVerify')]
    [Scope('OnPrem')]
    procedure CopyPostedPurchInvShptDateOrderNonConfirm()
    var
        PurchHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        InitialPostingDate: Date;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Posted Purchase Invoice and Receipt with Date Order enabled and user not accepted confirmation
        Initialize();

        // [GIVEN] Posted Purchase Invoice with Posting Date = "X"
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreatePurchaseDocumentForVendor(PurchHeader, PurchHeader."Document Type"::Invoice, true, VendorNo);
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [GIVEN] Purchase Document with Posting Date = "X" + 1 day and Posting No. assigned
        CreatePurchaseHeaderWithPostingNo(
          PurchHeader, LibraryPurchase.CreateVendorNo(),
          LibraryRandom.RandInt(5), PostedDocNo);
        InitialPostingDate := PurchHeader."Posting Date";
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Copy Document from Posted Purchase Invoice to Purchase Document with Include Header = TRUE
        CopyPurchDocument(PurchHeader, "Purchase Document Type From"::"Posted Invoice", PostedDocNo);
        PurchHeader.Find();

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        Assert.AreEqual(InitialPostingDate, PurchHeader."Posting Date", DocumentShouldNotBeCopiedErr);

        // [WHEN] Run Copy Document from Posted Purchase Receipt to Purchase Document with Include Header = TRUE
        PurchRcptHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchRcptHeader.FindFirst();
        LibraryVariableStorage.Enqueue(false);
        CopyPurchDocument(PurchHeader, "Purchase Document Type From"::"Posted Receipt", PurchRcptHeader."No.");
        PurchHeader.Find();

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        Assert.AreEqual(InitialPostingDate, PurchHeader."Posting Date", DocumentShouldNotBeCopiedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmCopyDocDateOrderHandlerVerify')]
    [Scope('OnPrem')]
    procedure CopyPostedPurchCrMemoRetRecDateOrderNonConfirm()
    var
        PurchHeader: Record "Purchase Header";
        PurchHeaderDst: Record "Purchase Header";
        ReturnShptHeader: Record "Return Shipment Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        InitialPostingDate: Date;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Posted Purchase Credit Memo and Return Shipment with Date Order enabled and user not accepted confirmation
        Initialize();

        // [GIVEN] Posted Credit Memo with Posting Date = "X"
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreatePurchaseDocumentForVendor(PurchHeader, PurchHeader."Document Type"::"Return Order", true, VendorNo);
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [GIVEN] Purchase Document with Posting Date = "X" + 1 day and Posting No. assigned
        CreatePurchaseHeaderWithPostingNo(
          PurchHeaderDst, LibraryPurchase.CreateVendorNo(),
          LibraryRandom.RandInt(5), PostedDocNo);
        InitialPostingDate := PurchHeaderDst."Posting Date";
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Copy Document from Posted Purchase Cr. Memo to Purchase Document with Include Header = TRUE
        CopyPurchDocument(PurchHeaderDst, "Purchase Document Type From"::"Posted Credit Memo", PostedDocNo);

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        PurchHeaderDst.Find();
        Assert.AreEqual(InitialPostingDate, PurchHeaderDst."Posting Date", DocumentShouldNotBeCopiedErr);

        // [WHEN] Run Copy Document from Posted Return Shipment to Purchase Document with Include Header = TRUE
        ReturnShptHeader.SetRange("Buy-from Vendor No.", VendorNo);
        ReturnShptHeader.FindFirst();
        LibraryVariableStorage.Enqueue(false);
        CopyPurchDocument(PurchHeaderDst, "Purchase Document Type From"::"Posted Return Shipment", ReturnShptHeader."No.");
        PurchHeaderDst.Find();

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        Assert.AreEqual(InitialPostingDate, PurchHeaderDst."Posting Date", DocumentShouldBeCopiedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmCopyDocDateOrderHandlerVerify')]
    [Scope('OnPrem')]
    procedure CopyPurchQuoteDateOrderNonConfirm()
    var
        PurchHeaderSrc: Record "Purchase Header";
        PurchHeaderDst: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Purchase Quote with Date Order enabled and user not accepted confirmation
        Initialize();

        // [GIVEN] Purchase Quote with Posting Date = "X"
        LibraryPurchase.CreatePurchHeader(
          PurchHeaderSrc, PurchHeaderSrc."Document Type"::Quote, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Document with Posting Date = "X" + 1 day and Posting No. assigned
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreatePurchaseHeaderWithPostingNo(
          PurchHeaderDst, VendorNo, LibraryRandom.RandInt(5),
          LibraryUtility.GenerateRandomCode(PurchHeaderDst.FieldNo("Posting No."), DATABASE::"Purchase Header"));
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Copy Document from Purchase Quote to Purchase Document with Include Header = TRUE
        CopyPurchDocument(PurchHeaderDst, "Purchase Document Type From"::Quote, PurchHeaderSrc."No.");

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        PurchHeaderDst.Find();
        Assert.AreEqual(VendorNo, PurchHeaderDst."Buy-from Vendor No.", DocumentShouldBeCopiedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyPurchQuoteDateOrderConfirm()
    var
        PurchHeaderSrc: Record "Purchase Header";
        PurchHeaderDst: Record "Purchase Header";
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Purchase Quote with Date Order enabled and user accepted confirmation
        Initialize();

        // [GIVEN] Purchase Quote with Posting Date = "X"
        LibraryPurchase.CreatePurchHeader(
          PurchHeaderSrc, PurchHeaderSrc."Document Type"::Quote, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Document with Posting Date = "X" + 1 day and Posting No. assigned
        CreatePurchaseHeaderWithPostingNo(
          PurchHeaderDst, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandInt(5),
          LibraryUtility.GenerateRandomCode(PurchHeaderDst.FieldNo("Posting No."), DATABASE::"Purchase Header"));

        // [WHEN] Run Copy Document from Purchase Quote to Purchase Document with Include Header = TRUE
        CopyPurchDocument(PurchHeaderDst, "Purchase Document Type From"::Quote, PurchHeaderSrc."No.");

        // [THEN] Confirmation dialog appears with warning and Document is copied after user confirmation
        PurchHeaderDst.Find();
        Assert.AreEqual(
          PurchHeaderSrc."Buy-from Vendor No.", PurchHeaderDst."Buy-from Vendor No.", DocumentShouldBeCopiedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWhenOperationOccuredDateLessThenPostingDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PaymentMethod: Record "Payment Method";
        Customer: Record Customer;
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Operation Occured Date] [Sales]
        // [SCENARIO 381568] Posted Sales Invoice and VAT Entry "Operation Occured Date" are set to Operation Occured Date of Sales Document when post it
        Initialize();

        // [GIVEN] Sales Invoice with "Operation Occurred Date"=29.01.16 and "Posting Date"=30.01.16
        CreatePaymentMethod(PaymentMethod);
        CreateCustomerWithPostingSetup(Customer);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.",
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2), '', WorkDate());
        SalesHeader.Validate("Operation Occurred Date", WorkDate() - 1);
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        SalesHeader.Modify(true);

        // [WHEN] Post Sales Invoice
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted Sales Invoice and VAT Entry "Operation Occured Date" should be 29.01.16
        VerifyPostedSalesInvoiceOperationOccuredDate(PostedDocumentNo, SalesHeader."Operation Occurred Date");
        VerifyVATEntryOperationOccuredDateFilteredOnDocNo(PostedDocumentNo, SalesHeader."Operation Occurred Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWhenOperationOccuredDateLessThenPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PaymentMethod: Record "Payment Method";
        Vendor: Record Vendor;
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Operation Occured Date] [Purchase]
        // [SCENARIO 381568] Posted Purchase Invoice and VAT Entry Operation Occured Date are set to Operation Occured Date of Purchase Document when post it
        Initialize();

        // [GIVEN] Purchase Invoice with "Operation Occurred Date"=29.01.16 and "Posting Date"=30.01.16
        CreatePaymentMethod(PaymentMethod);
        CreateVendorWithPostingSetup(Vendor);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, Vendor."No.",
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2), '', WorkDate());
        PurchaseHeader.Validate("Operation Occurred Date", WorkDate() - 1);
        PurchaseHeader.Validate("Payment Method Code", PaymentMethod.Code);
        PurchaseHeader.Modify(true);

        // [WHEN] Post Purchase Invoice
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posted Purchase Invoice and VAT Entry "Operation Occured Date" fields should be 29.01.16
        VerifyPostedPurchaseInvoiceOperationOccuredDate(PostedDocumentNo, PurchaseHeader."Operation Occurred Date");
        VerifyVATEntryOperationOccuredDateFilteredOnDocNo(PostedDocumentNo, PurchaseHeader."Operation Occurred Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJournalLineCustomerWithOperationOccuredDate()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Operation Occured Date] [Sales]
        // [SCENARIO 381568] VAT Entry Operation Occured Date is set to Operation Occured Date of Sales Gen. Journal Line when post it
        Initialize();

        // [GIVEN] Gen. Journal Line for Customer with "Operation Occurred Date"=29.01.16 and "Posting Date"=30.01.16
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(),
          GenJournalLine."Bal. Account Type"::Customer, LibrarySales.CreateCustomerNo(), -LibraryRandom.RandDec(10, 2));
        GenJournalLine.Validate("Operation Occurred Date", WorkDate() - 1);
        GenJournalLine.Modify(true);

        // [WHEN] Post Journal Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] VAT Entry "Operation Occured Date" field should be 29.01.16
        VerifyVATEntryOperationOccuredDateFilteredOnDocNo(GenJournalLine."Document No.", GenJournalLine."Operation Occurred Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJournalLineVendorWithOperationOccuredDate()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Operation Occured Date] [Purchase]
        // [SCENARIO 381568] VAT Entry Operation Occured Date is set to Operation Occured Date of Purchase Gen. Journal Line when post it
        Initialize();

        // [GIVEN] Gen. Journal Line for Vendor with "Operation Occurred Date"=29.01.16 and "Posting Date"=30.01.16
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(),
          GenJournalLine."Bal. Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDec(10, 2));
        GenJournalLine.Validate("Operation Occurred Date", WorkDate() - 1);
        GenJournalLine.Modify(true);

        // [WHEN] Post Journal Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] VAT Entry "Operation Occured Date" field should be 29.01.16
        VerifyVATEntryOperationOccuredDateFilteredOnDocNo(GenJournalLine."Document No.", GenJournalLine."Operation Occurred Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTotalPurchaseInvoiceLCYPreviewMode()
    var
        PurchaseHeader: Record "Purchase Header";
        GLPostingPreview: TestPage "G/L Posting Preview";
        AmountIncludingVAT: Decimal;
    begin
        // [FEATURE] [Purchase][Preview][UI]
        // [SCENARIO 382392] Preview page have to been opened when value of "Purchase Order"."Check Total" are not equal to previewing "Gen. Journal Line"."Amount (LCY)" if LCY "Purchase Order"
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Purchase Invoice with "Currency Code" = '' and "Check Total" = 100 and "Amount Including VAT" = 200
        CreatePurchInvoice(PurchaseHeader, AmountIncludingVAT, '');
        Commit();

        // [WHEN] Open Preview Posting
        OpenPreviewPurchInvoice(GLPostingPreview, PurchaseHeader);

        // [THEN] Preview page has been opened
        GLPostingPreview.OK().Invoke();
        asserterror Error(''); // it is required to complete posting preview engine
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTotalPurchaseInvoiceFCYPreviewMode()
    var
        PurchaseHeader: Record "Purchase Header";
        GLPostingPreview: TestPage "G/L Posting Preview";
        CurrencyCode: Code[10];
        AmountIncludingVAT: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 382392] Preview page have to been opened when value of "Purchase Order"."Check Total" are not equal to SUM of "Purchase Line"."Amount Including VAT" if FCY "Purchase Order"
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Purchase Invoice with "Currency Code" = "USD" and "Check Total" = 100 and "Amount Including VAT" = 200
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        CreatePurchInvoice(PurchaseHeader, AmountIncludingVAT, CurrencyCode);
        Commit();

        // [WHEN] Open Preview Posting
        OpenPreviewPurchInvoice(GLPostingPreview, PurchaseHeader);

        // [THEN] Preview page has been opened
        GLPostingPreview.OK().Invoke();
        asserterror Error(''); // it is required to complete posting preview engine
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWhenVATIdentifierIsEmpty()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 213400] Posting of Purchase Document is not allowed when VAT Identifier is empty
        Initialize();

        // [GIVEN] Purchase Invoice with empty VAT Identifier in line
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, Vendor."No.",
          CreateItemWithEmptyVATIdentifier(Vendor."VAT Bus. Posting Group"),
          LibraryRandom.RandDec(10, 2), '', WorkDate());

        // [WHEN] Post Purchase Invoice
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] 'VAT Identifier must have a value' error thrown
        Assert.ExpectedErrorCode(TestfieldErr);
        Assert.ExpectedError(VATIdentifierMustHaveValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWhenVATIdentifierIsEmpty()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 213400] Posting of Sales Document is not allowed when VAT Identifier is empty
        Initialize();

        // [GIVEN] Sales Invoice with empty VAT Identifier in line
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.",
          CreateItemWithEmptyVATIdentifier(Customer."VAT Bus. Posting Group"),
          LibraryRandom.RandDec(10, 2), '', WorkDate());

        // [WHEN] Post Sales Invoice
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] 'VAT Identifier must have a value' error thrown
        Assert.ExpectedErrorCode(TestfieldErr);
        Assert.ExpectedError(VATIdentifierMustHaveValueErr);
    end;

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());

        if isInitialized then
            exit;

        isInitialized := true;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure CopySalesDocument(SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type From"; DocumentNo: Code[20])
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters(DocumentType, DocumentNo, true, false);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.Run();
    end;

    local procedure CopyPurchDocument(PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type From"; DocumentNo: Code[20])
    var
        CopyPurchDocument: Report "Copy Purchase Document";
    begin
        CopyPurchDocument.SetPurchHeader(PurchHeader);
        CopyPurchDocument.SetParameters(DocumentType, DocumentNo, true, false);
        CopyPurchDocument.UseRequestPage(false);
        CopyPurchDocument.Run();
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; DateOrder: Boolean)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocumentForVendor(PurchaseHeader, DocumentType, DateOrder, Vendor."No.");
    end;

    local procedure CreatePurchaseHeaderWithPostingNo(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; PostingDateShift: Integer; PostingNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Posting Date", PurchaseHeader."Posting Date" + PostingDateShift);
        PurchaseHeader.Validate("Posting No.", PostingNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; DateOrder: Boolean)
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocumentForCustomer(SalesHeader, DocumentType, DateOrder, Customer."No.");
    end;

    local procedure CreateSalesDocumentWithPostingNo(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; PostingDateShift: Integer; PostingNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", SalesHeader."Posting Date" + PostingDateShift);
        SalesHeader.Validate("Posting No.", PostingNo);
        SalesHeader.Modify(true);
    end;

    local procedure CreatePurchaseDocumentForVendor(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; DateOrder: Boolean; VendorNo: Code[20])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        NoSeries: Record "No. Series";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Operation Type", UpdateNoSeries(FindNoSeries(NoSeries."No. Series Type"::Purchase), DateOrder));
        PurchaseHeader.Validate("Operation Occurred Date", WorkDate());
        PurchaseHeader.Validate("Document Date", WorkDate());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocumentForCustomer(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; DateOrder: Boolean; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        NoSeries: Record "No. Series";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Operation Type", UpdateNoSeries(FindNoSeries(NoSeries."No. Series Type"::Sales), DateOrder));
        SalesHeader.Validate("Operation Occurred Date", WorkDate());
        SalesHeader.Validate("Document Date", WorkDate());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceInvoice(var ServiceHeader: Record "Service Header")
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceLine: Record "Service Line";
        NoSeries: Record "No. Series";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceHeader.Validate("Operation Type", UpdateNoSeries(FindNoSeries(NoSeries."No. Series Type"::Sales), true));  // Date Order - True.
        ServiceHeader.Validate("Posting Date", WorkDate());
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateCustomerWithPostingSetup(var Customer: Record Customer)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup.Validate("Free Invoice Account", LibraryERM.CreateGLAccountNo());
        CustomerPostingGroup.Modify(true);
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Modify(true);
    end;

    local procedure CreatePaymentMethod(var PaymentMethod: Record "Payment Method")
    begin
        LibraryERM.CreatePaymentMethodWithBalAccount(PaymentMethod);
        PaymentMethod.Validate("Free Type", PaymentMethod."Free Type"::"Only VAT Amt.");
        PaymentMethod.Modify(true);
    end;

    local procedure CreateVendorWithPostingSetup(var Vendor: Record Vendor)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        VendorPostingGroup.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor.Modify(true);
    end;

    local procedure CreatePurchInvoice(var PurchaseHeader: Record "Purchase Header"; var AmountIncludingVAT: Decimal; CurrencyCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 100));
        PurchaseLine.Modify(true);
        AmountIncludingVAT := LibraryERM.InvoiceAmountRounding(PurchaseLine."Amount Including VAT", CurrencyCode);
        PurchaseHeader.Validate("Check Total", AmountIncludingVAT + LibraryRandom.RandIntInRange(10, 100));
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateItemWithEmptyVATIdentifier(VATBusGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        Item.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        Item.Modify(true);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Identifier", '');
        VATPostingSetup.Modify(true);
        exit(Item."No.");
    end;

    local procedure OpenPreviewPurchInvoice(var GLPostingPreview: TestPage "G/L Posting Preview"; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.Trap();
        PAGE.Run(PAGE::"Purchase Invoice", PurchaseHeader);
        GLPostingPreview.Trap();
        PurchaseInvoice.Preview.Invoke();
    end;

    local procedure UpdateNoSeries(NoSeriesCode: Code[20]; DateOrder: Boolean): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(NoSeriesCode);
        NoSeries.Validate("Date Order", DateOrder);
        NoSeries.Modify(true);
        exit(NoSeries.Code);
    end;

    local procedure FindNoSeriesLine(SeriesCode: Code[20]): Date
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", SeriesCode);
        NoSeriesLine.FindFirst();
        exit(NoSeriesLine."Last Date Used");
    end;

    local procedure FindNoSeries(NoSeriesType: Enum "No. Series Type"): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.SetRange("No. Series Type", NoSeriesType);
        NoSeries.SetFilter("VAT Register", '<>%1', '');  // VAT Register must not blank.
        NoSeries.SetRange("Date Order", true);
        NoSeries.FindFirst();
        exit(NoSeries.Code);
    end;

    local procedure UpdateGLSetupLastGenJourPrintingDate(NewLastGenJourPrintingDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Last Gen. Jour. Printing Date" := NewLastGenJourPrintingDate;
        GeneralLedgerSetup.Modify();
    end;

    local procedure VerifySalesHeaderAppliesToOccurenceNo(var SalesHeader: Record "Sales Header"; PostedInvoiceNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        SalesHeader.Find();
        CustLedgerEntry.SetRange("Customer No.", SalesHeader."Sell-to Customer No.");
        CustLedgerEntry.SetRange("Document No.", PostedInvoiceNo);
        CustLedgerEntry.FindLast();
        Assert.AreEqual(CustLedgerEntry."Document Occurrence", SalesHeader."Applies-to Occurrence No.", InvalidAppliesToOccNoErr);
    end;

    local procedure VerifyPurchHeaderAppliesToOccurenceNo(var PurchaseHeader: Record "Purchase Header"; PostedInvoiceNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        PurchaseHeader.Find();
        VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        VendorLedgerEntry.SetRange("Document No.", PostedInvoiceNo);
        VendorLedgerEntry.FindLast();
        Assert.AreEqual(VendorLedgerEntry."Document Occurrence", PurchaseHeader."Applies-to Occurrence No.", InvalidAppliesToOccNoErr);
    end;

    local procedure VerifyVATEntryOperationOccuredDateFilteredOnDocNo(PostedDocumentNo: Code[20]; ExpectedDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", PostedDocumentNo);
        VATEntry.FindFirst();
        Assert.RecordCount(VATEntry, 1);
        VATEntry.TestField("Operation Occurred Date", ExpectedDate);
    end;

    local procedure VerifyPostedSalesInvoiceOperationOccuredDate(PostedDocumentNo: Code[20]; ExpectedDate: Date)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(PostedDocumentNo);
        SalesInvoiceHeader.TestField("Operation Occurred Date", ExpectedDate);
    end;

    local procedure VerifyPostedPurchaseInvoiceOperationOccuredDate(PostedDocumentNo: Code[20]; ExpectedDate: Date)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(PostedDocumentNo);
        PurchInvHeader.TestField("Operation Occurred Date", ExpectedDate);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmCopyDocDateOrderHandlerVerify(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedConfirmText: Text;
    begin
        ExpectedConfirmText := CopyDocDateOrderConfirmMsg;
        Assert.AreEqual(ExpectedConfirmText, Question, WrongConfirmationMsgErr);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

