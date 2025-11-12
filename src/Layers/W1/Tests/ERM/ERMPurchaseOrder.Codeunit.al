codeunit 134327 "ERM Purchase Order"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Order] [Purchase]
        isInitialized := false;
    end;

    var
        TempDocumentEntry2: Record "Document Entry" temporary;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJob: Codeunit "Library - Job";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryPlanning: Codeunit "Library - Planning";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        LibraryResource: Codeunit "Library - Resource";
        LibraryTemplates: Codeunit "Library - Templates";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryItemReference: Codeunit "Library - Item Reference";
        isInitialized: Boolean;
        FieldError: Label 'Number of Lines for %1 and %2  must be Equal.';
        CurrencyError: Label '%1 must be Equal in %2.';
        PostingDate2: Date;
        DocumentNo2: Code[20];
        AmountError: Label '%1 must be %2 in %3.';
        PostError: Label 'Amount must be negative';
        CountErr: Label 'There must be %1 record(-s) in table %2 with the following filters: %3';
        ColumnWrongVisibilityErr: Label 'Column[%1] has wrong visibility';
        IncorrectFieldValueErr: Label 'Incorrect %1 field value.';
        WrongQtyToReceiveErr: Label 'Qty. to Receive should not be non zero because Quantity was not changed.';
        IncorrectDimSetIDErr: Label 'Incorrect Dimension Set ID in %1.';
        JobUnitPriceErr: Label 'Job Unit Price is incorrect.';
        WrongDimValueErr: Label 'Wrong dimension value in Sales Header %1.';
        WrongValuePurchaseHeaderInvoiceErr: Label 'The value of field Invoice in copied Purchase Order must be ''No''.';
        WrongValuePurchaseHeaderReceiveErr: Label 'The value of field Receive in copied Purchase Order must be ''No''.';
        WrongInvDiscAmountErr: Label 'Wrong Invoice Discount Amount in Purchase Line.';
        QtyToRecvBaseErr: Label 'Qty. to Receive (Base) must be equal to Qty. to Receive in Purchase Line';
        QtyToInvcBaseErr: Label 'Qty. to Invoice (Base) must be equal to Qty. to Invoice in Purchase Line';
        ReturnQtyToShipBaseErr: Label 'Return Qty. to Ship (Base) must be equal to Return Qty. to Ship in Purchase Line';
        QuantityToRecvBaseErr: Label 'Qty. to Receive (Base) must be equal to Quantity in Purchase Line';
        ReturnQuantitytyToShipBaseErr: Label 'Return Qty. to Ship (Base) must be equal to Quantity in Purchase Line';
        WrongJobTotalPriceErr: Label 'Wrong Job Total Price in Purchase Line.';
        WrongJobTotalPriceLCYErr: Label 'Wrong Job Total Price (LCY) in Purchase Line.';
        PostedDocsToPrintCreatedMsg: Label 'One or more related posted documents have been generated during deletion to fill gaps in the posting number series. You can view or print the documents from the respective document archive.';
        AmountToAssignErr: Label 'Wrong Amount to Assign on reassigned lines';
        OptionStringRef: Option "Posted Receipts","Posted Invoices","Posted Return Shipments","Posted Cr. Memos";
        InvoiceDiscountChangedErr: Label 'Invoice Discount % must not be auto calculated for header on open page.';
        MixedDropshipmentErr: Label 'You cannot print the purchase order because it contains one or more lines for drop shipment in addition to regular purchase lines.';
        ContactShouldNotBeEditableErr: Label 'Contact should not be editable when vendor is not selected.';
        ContactShouldBeEditableErr: Label 'Contact should be editable when vendorr is selected.';
        PayToAddressFieldsNotEditableErr: Label 'Pay-to address fields should not be editable.';
        PayToAddressFieldsEditableErr: Label 'Pay-to address fields should be editable.';
        ShipmentMethodCodeIsDisabledErr: Label 'Shipment Method Code field on Purchase Order Page is disabled.';
        ShipToAddrOnCompanyInfoIsDisabledErr: Label 'One of Ship-To Address fields on Company Information page is disabled.';
        PurchLineGetLineAmountToHandleErr: Label 'Incorrect amount returned by PurchLine.GetLineAmountToHandle().';
        SuggestAssignmentErr: Label 'Qty. to Invoice must have a value in Purchase Line';
        CopyFromPurchaseErr: Label 'Wrong result of CopyFrom function';
        CopyFromResourceErr: Label 'Wrong result of validate No. with resource';
        QtyToReceiveUpdateErr: Label 'Qty. to Receive must be equal to %1 in Purchase Line';
        RecreatePurchaseLinesCancelErr: Label 'Change in the existing purchase lines for the field %1 is cancelled by user.';
        RecreatePurchaseLinesQst: Label 'If you change %1, the existing purchase lines will be deleted and new purchase lines based on the new information in the header will be created.\\Do you want to continue?';
        GenProdPostingGroupErr: Label '%1 is not set for the %2 G/L account with no. %3.', Comment = '%1 - caption Gen. Prod. Posting Group; %2 - G/L Account Description; %3 - G/L Account No.';
        DisposedErr: Label '%1 is disposed.';
        RoundingTo0Err: Label 'Rounding of the field';
        RemitToCodeShouldNotBeEditableErr: Label 'Remit-to code should not be editable when vendor is not selected.';
        RemitToCodeShouldBeEditableErr: Label 'Remit-to code should be editable when vendor is selected.';
        UpdateLinesOrderDateAutomaticallyQst: Label 'You have changed the Order Date on the purchase header, which might affect the prices and discounts on the purchase lines.\Do you want to update the order date for existing lines?';
        OrderDateErr: Label 'The purchase line order date is (%1), but it should be (%2).', Comment = '%1 - Actual Purchase Line Order Date; %2 - Expected Purchase Line Order Date';
        DescriptionErr: Label 'The purchase line description (%1) should be the same as the random generated description (%2).', Comment = '%1 - Purchase Line Description; %2 - Random Generated Description';
        QtyReceivedBaseErr: Label 'Qty. Received (Base) is not as expected.';
        InteractionLogErr: Label 'Interaction log must be enabled.';
        ItemRefrenceNoErr: Label 'Item Reference No. should be %1.', Comment = '%1 - old reference no.';
        GrossWeightErr: Label '%1 must be calculated in %2.', Comment = '%1=Field Caption; %2 Page Caption.';
        QuantityMustBeZeroLbl: Label '%1 must be 0', Comment = '%1=Field Caption';
        GlobalDimensionCodeErr: Label '%1 must be blank in %2.', Comment = '%1=Field Caption; %2 Page Caption.';
        SourceCurrencyErr: Label '%1 must be negative.', Comment = '%1=Field Caption.';
        PurchaseLineQtyErr: Label 'Purchase Line %1 must be equal to %2', Comment = '%1= Field ,%2= Value';
        ItemFilterOnAnalysisViewCardMatchesCreatedItemErr: Label 'The created item should be selected in the analysis view card.';
        OptionString: Option PostedReturnReceipt,PostedInvoices,PostedShipments,PostedCrMemo;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePostedInvoicedPurchOrder()
    var
        InvoicePurchaseHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocNo: Code[20];
    begin
        // Tests that execution of report "Delete invoiced purch orders" deletes only purchase orders
        // which are posted and also invoiced.

        // Setup: Create and Purchase Order.
        Initialize();
        PurchaseDocNo := CreateAndPostPurchaseDocument(PurchaseHeader);

        InvoicePostedPurchaseOrder(InvoicePurchaseHeader, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(InvoicePurchaseHeader, false, true);

        // Exercise: Run Delete Purchase Report Report.
        RunDeleteInvoicePurchaseReport(PurchaseHeader."Buy-from Vendor No.");

        // Verify: Verify Purchase Order has been deleted after running report.
        Assert.IsFalse(PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseDocNo), 'Purchase order was not deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePostedNotInvoicedPuOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Tests that execution of report "Delete invoiced purch orders" may not delete purchase orders
        // which are posted but not invoiced.

        // Setup.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseHeader);

        // Run Delete Purchase Report Report and Verify.
        RunVerifyDeleteInvoiceReport(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteNotPostedPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Tests that execution of report "Delete invoiced purch orders" may not delete purchase orders
        // which are not posted. It does not matter if the order has/has not a stand-alone invoice
        // because the posting is a pre-requisite to match an order and an invoice.

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);

        // Run Delete Purchase Report Report and Verify.
        RunVerifyDeleteInvoiceReport(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."No.");
    end;

    local procedure RunVerifyDeleteInvoiceReport(BuyFromVendorNo: Code[20]; PurchaseDocNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Exercise.
        RunDeleteInvoicePurchaseReport(BuyFromVendorNo);

        // Return TRUE if purchase order has been deleted, otherwise FALSE
        Assert.IsTrue(PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseDocNo), 'Purchase order was deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderCreation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Test New Purchase Order creation.

        // Setup.
        Initialize();

        // Exercise: Create Purchase Order.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);

        // Verify: Verify Purchase Order created.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldsOnPurchaseInvoiceHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PaymentMethod: Record "Payment Method";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize();

        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);

        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PurchaseHeader."Creditor No." :=
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Creditor No."), DATABASE::"Purchase Header");
        PurchaseHeader."Payment Method Code" := PaymentMethod.Code;
        PurchaseHeader.Modify(true);

        // Exercise
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Validate
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.TestField("Creditor No.", PurchaseHeader."Creditor No.");
        PurchInvHeader.TestField("Payment Reference", PurchaseHeader."Payment Reference");
        PurchInvHeader.TestField("Payment Method Code", PurchaseHeader."Payment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPurhcaseOrder()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
        VATAmount: Decimal;
    begin
        // Create a Purchase Order, Calculates applicable VAT for a VAT Posting Group and verify it with VAT Amount Line.

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);

        // Exercise: Calculate VAT Amount on Purchase Order.
        PurchaseLine.CalcVATAmountLines(QtyType::Invoicing, PurchaseHeader, PurchaseLine, VATAmountLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);
        VATAmount := PurchaseHeader.Amount * PurchaseLine."VAT %" / 100;

        // Verify: Verify VAT Amount on Purchase Order.
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          VATAmount, VATAmountLine."VAT Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, VATAmountLine.FieldCaption("VAT Amount"), VATAmount, VATAmountLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        "Order": Report "Order";
        FilePath: Text[1024];
    begin
        // Create New Purchase Order and save as external file and verify saved files have data.

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);

        // Exercise: Generate Report as external file for Purchase Order.
        Clear(Order);
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Order.SetTableView(PurchaseHeader);
        FilePath := TemporaryPath + Format(PurchaseHeader."Document Type") + PurchaseHeader."No." + '.xlsx';
        Order.SaveAsExcel(FilePath);

        // Verify: Verify that Saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderAsReceive()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseLineCount: Integer;
        PostedDocumentNo: Code[20];
    begin
        // Create New Purchase Order post as Receive and verify Posted Receipt No. of Lines are equals as Purchase Order No. of Lines.

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLineCount := PurchaseLine.Count();

        // Exercise: Post Purchase Order as Receive.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify Purchase Receipt Line Count with Purchase Line Count.
        PurchRcptLine.SetRange("Document No.", PostedDocumentNo);
        Assert.AreEqual(
          PurchaseLineCount, PurchRcptLine.Count, StrSubstNo(FieldError, PurchaseLine.TableCaption(), PurchRcptLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderAsInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedDocumentNo: Code[20];
    begin
        // Create a Purchase Order, Post as Receive and Invoice and verify Vendor Ledger, GL Entry, and VAT Entry.

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);

        // Exercise: Post Purchase Order as Receive and Invoice.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: GL Entry, Vendor Ledger Entry, Value Entry and VAT Entry.
        PurchInvHeader.Get(PostedDocumentNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        VerifyGLEntry(PostedDocumentNo, PurchInvHeader."Amount Including VAT");
        VerifyVendorLedgerEntry(PostedDocumentNo, PurchInvHeader."Amount Including VAT");
        VerifyVATEntry(PostedDocumentNo, PurchInvHeader."Amount Including VAT");
        VerifyValueEntry(PostedDocumentNo, PurchInvHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: Report "Purchase - Invoice";
        PostedDocumentNo: Code[20];
        FilePath: Text[1024];
    begin
        // Test if Post a Purchase Order and generate Posted Purchase Invoice Report.

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Generate Report as external file for Posted Purchase Invoice.
        Clear(PurchaseInvoice);
        PurchInvHeader.SetRange("No.", PostedDocumentNo);
        PurchaseInvoice.SetTableView(PurchInvHeader);
        FilePath := TemporaryPath + Format('Purchase - Invoice') + PurchInvHeader."No." + '.xlsx';
        PurchaseInvoice.SaveAsExcel(FilePath);

        // Verify: Verify that Saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderForWhseLocation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        WarehouseEmployee: Record "Warehouse Employee";
        NoSeries: Codeunit "No. Series";
        PostedDocumentNo: Code[20];
    begin
        // Test if Post a Purchase Order with Warehouse Location and verify Posted Purchase Receipt Entry.

        // Setup
        Initialize();

        // Exercise: Create Purchase Order for Warehouse Location. Using RANDOM Quantity for Purchase Line, value is not important.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);
        ModifyLocationOnPurchaseLine(PurchaseLine);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, PurchaseLine."Location Code", false);
        PostedDocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Receiving No. Series");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // Post Warehouse Document as Receive.
        ReceiveWarehouseDocument(PurchaseHeader."No.", PurchaseLine."Line No.");

        // Verify: Verify Quantity Posted Receipt Document.
        PurchRcptLine.SetRange("Document No.", PostedDocumentNo);
        PurchRcptLine.FindFirst();
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(
          PurchaseLine."Quantity Received", PurchRcptLine.Quantity, StrSubstNo(FieldError, PurchaseLine.TableCaption(),
            PurchRcptLine.TableCaption()));

        // Tear Down: Rollback Setup changes for Location and Warehouse Employee.
        ModifyWarehouseLocation(false);
        WarehouseEmployee.Get(UserId, PurchaseLine."Location Code");
        WarehouseEmployee.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderForRequireReceiveLocation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Test Quantity re-validating with the same value does not cause Qty. to Receive modification.

        // Setup.
        Initialize();

        // Exercise: Create Purchase Order for Warehouse Location with Require Receive.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);
        ModifyLocationOnPurchaseLine(PurchaseLine);

        PurchaseLine.Validate(Quantity, PurchaseLine.Quantity);
        PurchaseLine.Modify(true);

        // Verify.
        Assert.AreEqual(0, PurchaseLine."Qty. to Receive", WrongQtyToReceiveErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderContactNotEditableBeforeVendorSelected()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Purchase Order Page not editable if no vendor selected
        // [Given]
        Initialize();

        // [WHEN] Purchase Order page is opened
        PurchaseOrder.OpenNew();

        // [THEN] Contact Field is not editable
        Assert.IsFalse(PurchaseOrder."Buy-from Contact".Editable(), ContactShouldNotBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderContactEditableAfterVendorSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Purchase Order Page  editable if vendor selected
        // [Given]
        Initialize();

        // [Given] A sample Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());

        // [WHEN] Purchase Order page is opened
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // [THEN] Contact Field is editable
        Assert.IsTrue(PurchaseOrder."Buy-from Contact".Editable(), ContactShouldBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderPayToAddressFieldsNotEditableIfSamePayToVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Pay-to Address Fields on Purchase Order Page not editable if vendor selected equals pay-to vendor
        // [Given]
        Initialize();

        // [Given] A sample Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());

        // [WHEN] Purchase Order page is opened
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // [THEN] Pay-to Address Fields is not editable
        Assert.IsFalse(PurchaseOrder."Pay-to Address".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(PurchaseOrder."Pay-to Address 2".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(PurchaseOrder."Pay-to City".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(PurchaseOrder."Pay-to Contact".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(PurchaseOrder."Pay-to Post Code".Editable(), PayToAddressFieldsNotEditableErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderPayToAddressFieldsEditableIfDifferentPayToVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PayToVendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Pay-to Address Fields on Purchase Order Page editable if vendor selected not equals pay-to vendor
        // [Given]
        Initialize();

        // [Given] A sample Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());

        // [WHEN] Purchase Order page is opened
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // [WHEN] Another Pay-to vendor is picked
        PayToVendor.Get(CreateVendor());
        PurchaseOrder."Pay-to Name".SetValue(PayToVendor.Name);

        // [THEN] Pay-to Address Fields is editable
        Assert.IsTrue(PurchaseOrder."Pay-to Address".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(PurchaseOrder."Pay-to Address 2".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(PurchaseOrder."Pay-to City".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(PurchaseOrder."Pay-to Contact".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(PurchaseOrder."Pay-to Post Code".Editable(), PayToAddressFieldsEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountOnPurhcaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PriceListLine: Record "Price List Line";
        PostedDocumentNo: Code[20];
        DiscountAmount: Decimal;
    begin
        // Test Line Discount on Purchase Order, Post as Receive and Invoice and verify Posted GL Entry.

        // Setup: Create Line Discount Setup.
        Initialize();
        SetupLineDiscount(PurchaseLineDiscount);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        // Exercise: Create and Post Purchase Order with Random Quantity. Take Quantity greater than Purchas Line Discount Minimum Quantity.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLineDiscount."Vendor No.");
        ModifyPurchaseHeader(PurchaseHeader, PurchaseHeader."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLineDiscount."Item No.",
          PurchaseLineDiscount."Minimum Quantity" + LibraryRandom.RandInt(10));
        DiscountAmount := (PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * PurchaseLineDiscount."Line Discount %" / 100;
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Purchase Line and Posted G/L Entry for Line Discount Amount.
        VerifyLineDiscountAmount(PurchaseLine, PostedDocumentNo, DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnPurchaseOrder()
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
        DiscountAmount: Decimal;
    begin
        // Create New Invoice Discount Setup for Vendor and make new Purchase Order, Post as Receive and Invoice and verify Posted GL Entry.

        // Setup: Create Invoice Discount Setup.
        Initialize();
        SetupInvoiceDiscount(VendorInvoiceDisc);

        // Exercise: Create Purchase Order, calculate Invoice Discount and Post as Receive and Invoice.
        // Using RANDOM Quantity for Purchase Line, value is not important.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorInvoiceDisc.Code);
        ModifyPurchaseHeader(PurchaseHeader, PurchaseHeader."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));

        // Order Value always greater than Minimum Amount of Invoice Discount Setup.
        PurchaseLine.Validate("Direct Unit Cost", VendorInvoiceDisc."Minimum Amount");
        PurchaseLine.Modify(true);
        DiscountAmount := (PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * VendorInvoiceDisc."Discount %" / 100;
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Purchase Line and Posted G/L Entry for Invoice Discount Amount.
        VerifyInvoiceDiscountAmount(PurchaseLine, PostedDocumentNo, DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithFCY()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedDocumentNo: Code[20];
    begin
        // Create and Post a Purchase Order with Currency and verify currency on Posted Purchase Invoice Entry.

        // Setup.
        Initialize();

        // Exercise: Create Purchase Order, attach new Currency on Purchase Order and Post as Receive and Invoice.
        CreatePurchaseHeaderWithCurrency(PurchaseHeader, CreateCurrency());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Currency Code in Purchase Line and Posted Purchase Invoice Header.
        PurchInvHeader.Get(PostedDocumentNo);
        Assert.AreEqual(
          PurchaseHeader."Currency Code", PurchaseLine."Currency Code",
          StrSubstNo(CurrencyError, PurchaseLine.FieldCaption("Currency Code"), PurchaseLine.TableCaption()));
        Assert.AreEqual(
          PurchaseHeader."Currency Code", PurchInvHeader."Currency Code",
          StrSubstNo(CurrencyError, PurchInvHeader.FieldCaption("Currency Code"), PurchInvHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler')]
    [Scope('OnPrem')]
    procedure PostedInvoiceNavigate()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNo: Code[20];
    begin
        // Test Navigate functionality for Posted Purchase Invoice.

        // Setup.
        Initialize();
        InitGlobalVariables();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);

        // Exercise: Post Purchase Order as Ship & Invoice and open Navigate form.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvHeader.Get(DocumentNo);

        // Set global variable for page handler.
        PostingDate2 := PurchInvHeader."Posting Date";
        DocumentNo2 := PurchInvHeader."No.";

        PurchInvHeader.Navigate();

        // Verify: Verify Number of entries for all related tables.
        VerifyPostedEntries(DocumentNo2);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler')]
    [Scope('OnPrem')]
    procedure PostedShipmentNavigate()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        DocumentNo: Code[20];
    begin
        // Test Navigate functionality for Posted Purchase Shipment.

        // Setup.
        Initialize();
        InitGlobalVariables();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);

        // Exercise: Post Purchase Order as Ship and open Navigate form.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchRcptHeader.Get(DocumentNo);

        // Set global variable for page handler.
        PostingDate2 := PurchRcptHeader."Posting Date";
        DocumentNo2 := PurchRcptHeader."No.";

        PurchRcptHeader.Navigate();

        // Verify: Verify Number of entries with Item Ledger Entry.
        ItemLedgerEntry.SetRange("Document No.", DocumentNo2);
        VerifyNavigateRecords(TempDocumentEntry2, DATABASE::"Item Ledger Entry", ItemLedgerEntry.Count);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler')]
    [Scope('OnPrem')]
    procedure PostedCreditMemoNavigate()
    var
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // Test Navigate functionality for Posted Purchase Credit Memo.

        // Setup.
        Initialize();
        InitGlobalVariables();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::"Credit Memo");

        // Exercise: Post Purchase Credit Memo and open Navigate page.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchCrMemoHdr.Get(DocumentNo);

        // Set global variable for page handler.
        PostingDate2 := PurchCrMemoHdr."Posting Date";
        DocumentNo2 := PurchCrMemoHdr."No.";

        PurchCrMemoHdr.Navigate();

        // Verify: Verify Number of entries for all related tables.
        VerifyPostedEntries(DocumentNo2);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler')]
    [Scope('OnPrem')]
    procedure PostedReturnShipmentNavigate()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PurchaseHeader: Record "Purchase Header";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
    begin
        // Test Navigate functionality for Posted Purchase Return Shipment.

        // Setup.
        Initialize();
        InitGlobalVariables();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::"Return Order");

        // Exercise: Post Purchase Return Order and open Navigate page.
        DocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Return Shipment No. Series");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ReturnShipmentHeader.Get(DocumentNo);

        // Set global variable for page handler.
        PostingDate2 := ReturnShipmentHeader."Posting Date";
        DocumentNo2 := ReturnShipmentHeader."No.";

        ReturnShipmentHeader.Navigate();

        // Verify: Verify Number of entries for all related tables.
        ItemLedgerEntry.SetRange("Document No.", DocumentNo2);
        VerifyNavigateRecords(TempDocumentEntry2, DATABASE::"Item Ledger Entry", ItemLedgerEntry.Count);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler')]
    [Scope('OnPrem')]
    procedure PostedPaymentNavigate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Navigate: Page Navigate;
    begin
        // Test Navigate functionality for Financial Management with General Lines.

        // Setup.
        Initialize();
        InitGlobalVariables();
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, CreateVendor(), LibraryRandom.RandDec(1000, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Set global variable for page handler.
        DocumentNo2 := GenJournalLine."Document No.";
        PostingDate2 := GenJournalLine."Posting Date";

        // Exercise: Post General Journal Line and open Navigate page.
        Navigate.SetDoc(PostingDate2, DocumentNo2);
        Navigate.Run();

        // Verify: Verify Number of entries for all related tables.
        VerifyPostedPaymentNavigation(DocumentNo2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedTextInPurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        Text: Text[100];
    begin
        // Check Extended Text in Purchase Order with Extended Text Line.

        // 1. Setup: Create Item, Vendor and Purchase Order.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        Text := CreateItemAndExtendedText(Item);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");

        // 2. Exercise: Insert Extended Text in Purchase Line.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines."Insert Ext. Texts".Invoke();

        // 3. Verify: Check Desription and No. of Purchase Order must match with Extended Text Line.
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::" ");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField(Description, Text);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialPurchaseOrder()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        TotalAmount: Decimal;
    begin
        // Check GL Entry after Posting Partial Purchase Order.

        // Setup: Create and Post Purchase Order with Partial Receive.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);
        ModifyPurchaseLineQtyToReceive(PurchaseLine, PurchaseLine."Qty. to Receive" / 2);
        TotalAmount := PurchaseLine."Qty. to Receive" * PurchaseLine."Direct Unit Cost";
        TotalAmount := TotalAmount + (TotalAmount * PurchaseLine."VAT %" / 100);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify GL Entry for Partial Purchase Invoice.
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        FindGLEntry(GLEntry, DocumentNo, VendorPostingGroup."Payables Account");
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          -TotalAmount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), TotalAmount, GLEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderNegativeErrorMsg()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Purchase Order Posting Error Message when amount is Negative.

        // Setup: Create and Post Purchase Order with Partial Receive and modify Purchase Line with Negative Amount.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);
        ModifyPurchaseLineQtyToReceive(PurchaseLine, PurchaseLine."Qty. to Receive" / 2);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        ModifyPurchaseHeader(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.");
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Direct Unit Cost", -PurchaseLine."Direct Unit Cost");
        PurchaseLine.Modify(true);

        // Exercise: Try to Post Purchase Order with Negative Amount.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Error Message raised during Negative amount posting of Purchase Order.
        Assert.ExpectedError(PostError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchieveVersionPurchaseOrder()
    var
        PurchaseLineArchive: Record "Purchase Line Archive";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Purchase Line Archive for Archive Version after Posting Partial Purchase Order.

        // Setup: Create and Post Purchase Order with Archive Quotes and Orders TRUE on Purchase and payable Setup.
        Initialize();
        LibraryPurchase.SetArchiveOrders(true);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);
        ModifyPurchaseLineQtyToReceive(PurchaseLine, PurchaseLine."Qty. to Receive" / 2);

        // Exercise: Post Purchase Order with Receive.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify No. of Archived Versions fields on Purchase Header and Purchase Line Archive.
        // Take 1 as static becuase it will generate 1 Posting of Purchase Order on first time.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.CalcFields("No. of Archived Versions");
        PurchaseHeader.TestField("No. of Archived Versions", 1);

        PurchaseLineArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLineArchive.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLineArchive.FindFirst();
        PurchaseLineArchive.TestField("Version No.", PurchaseHeader."No. of Archived Versions");
        PurchaseLineArchive.TestField("Qty. to Receive", PurchaseLine."Qty. to Receive");
        PurchaseLineArchive.TestField(Quantity, PurchaseLine.Quantity);
        PurchaseLineArchive.TestField("Qty. to Invoice", PurchaseLine."Qty. to Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorRemainingPaymentDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        DueDate: Date;
        PmtDiscountDate: Date;
        RemainingPmtDiscPossible: Decimal;
    begin
        // Test and verify Remaining Payment Discount Possible for Vendor.

        // Setup: Create and Post Purchase Order.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Update Vendor Ledger Entry.
        DueDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        PmtDiscountDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        RemainingPmtDiscPossible := PurchaseLine."Line Amount" / 2;
        UpdateVendorLedgerEntry(DocumentNo, DueDate, PmtDiscountDate, -RemainingPmtDiscPossible);

        // Verify: Verify values on Vendor Ledger Entry.
        VerifyValuesOnVendLedgerEntry(DocumentNo, DueDate, PmtDiscountDate, -RemainingPmtDiscPossible);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure VendorCreationByPage()
    var
        TempVendor: Record Vendor temporary;
    begin
        // To create a new Vendor with Page and verify it.

        // Setup.
        Initialize();

        // Exercise: Create Vendor with Page.
        CreateTempVendor(TempVendor);
        CreateVendorCard(TempVendor);

        // Verify: Verify values on Vendor.
        VerifyVendor(TempVendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Create Purchase Invoice, Post and Verify Purchase Invoice Header and Line.

        // Setup: Create Purchase Invoice.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Invoice);

        // Exercise: Post Purchase Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Check Buy from Vendor No., Item No., Quantity in Purchase Invoice Header and Line.
        VerifyPurchaseInvoice(DocumentNo, PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Create Purchase Credit Memo, Post and Verify Purchase Credit Memo Header and Line.

        // Setup: Create Purchase Credit Memo.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::"Credit Memo");

        // Exercise: Post Purchase Credit Memo.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Check Buy from Vendor No., Item No., Quantity in Purchase Credit Memo Header and Line.
        VerifyPurchaseCreditMemo(DocumentNo, PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('StandardVendorPurchCodesHndlr')]
    [Scope('OnPrem')]
    procedure PurchaseOrderStandardPurchCode()
    var
        PurchaseHeader: Record "Purchase Header";
        StandardPurchaseLine: Record "Standard Purchase Line";
    begin
        // Check Purchase Code Line are copied correctly in Purchase Line.

        // Setup: Update Stock Out Warning.
        Initialize();

        // Exercise: Create Purchase Order with Purchase Code.
        CreatePurchOrderWithPurchCode(StandardPurchaseLine, PurchaseHeader, '', '');

        // Verify: Verify Purchase Code Line are copied correctly in Purchase Line.
        VerifyPurchaseLine(StandardPurchaseLine, PurchaseHeader."No.", '', '');
    end;

    [Test]
    [HandlerFunctions('StandardVendorPurchCodesHndlr')]
    [Scope('OnPrem')]
    procedure PurchaseOrderCopyStandardCode()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        StandardPurchaseLine: Record "Standard Purchase Line";
        PostedPurchaseInvoiceNo: Code[20];
    begin
        // Verify Posted Purchase Line of one document is copied correctly in Purchase Line of second document.

        // Setup: Create and post Purchase Order with Purchase Code.
        Initialize();
        CreatePurchOrderWithPurchCode(StandardPurchaseLine, PurchaseHeader, '', '');
        ModifyDirectUnitCost(PurchaseHeader);
        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.");
        Commit();  // COMMIT is required here.

        // Exercise: Copy Purchase Document.
        PurchaseCopyDocument(PurchaseHeader2, PostedPurchaseInvoiceNo, "Purchase Document Type From"::"Posted Invoice");

        // Verify: Verify values on Copy Purchase Lines .
        VerifyCopyPurchaseLine(PostedPurchaseInvoiceNo, PurchaseHeader2."No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseCodePageHandler')]
    [Scope('OnPrem')]
    procedure DimensionOnVendorAndStandardPurchaseCode()
    var
        Item: Record Item;
        Dimension: Record Dimension;
        Vendor: Record Vendor;
        StandardPurchaseLine: Record "Standard Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DefaultDimension: Record "Default Dimension";
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        DifferentDimensionCode: Code[20];
    begin
        // Test Dimensions are "merged" between the ones coming from Standard Sales Code and Sales Header (customer)

        // 1. Setup : Create Item and customer with dimensions
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreateItemWithDimension(Item, Dimension.Code, DefaultDimension."Value Posting"::" ");
        DifferentDimensionCode := FindDifferentDimension(Dimension.Code);
        CreateVendorWithDimension(Vendor, DefaultDimension, DefaultDimension."Value Posting", DifferentDimensionCode);

        // Create Standard Codes and sales header
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);
        CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code, StandardPurchaseLine.Type::Item, Item."No.");
        UpdateDimensionSetID(StandardPurchaseLine, Dimension.Code);
        LibraryPurchase.CreateVendorPurchaseCode(StandardVendorPurchaseCode, Vendor."No.", StandardPurchaseLine."Standard Purchase Code");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // 2. Exercise
        LibraryVariableStorage.Enqueue(Vendor."No."); // for the page handler
        StandardVendorPurchaseCode.InsertPurchLines(PurchaseHeader);

        // 3. Verify : Verify that sales Line Dimensions are copied from Standard Sales Line and header
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Document Type");
        VerifyDimensionCode(PurchaseLine."Dimension Set ID", Dimension.Code);
        VerifyDimensionCode(PurchaseLine."Dimension Set ID", DefaultDimension."Dimension Code");
    end;

    [Test]
    [HandlerFunctions('SuggstItemChargeAssgntVldHndlr,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Order and Validate Item Charge Assignment Purch.

        // Setup: Create Purchase Order.
        Initialize();
        CreatePurchaseOrderChargeItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // Exercise: Create Purchase Line with Document Type as Item and Charge(Item).
        DocumentNo2 := PurchaseHeader."No.";  // Insert the Purchase Header No. in global variable.
        PurchaseLine.ShowItemChargeAssgnt();

        // Verify: Verification of Item Charge Assignment Purchase has done in SuggstItemChargeAssgntVldHndlr Handler.
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentHandler')]
    [Scope('OnPrem')]
    procedure ValidateItemChargeAssignmentPostPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Order and Suggest Item Charge Assignment then Validate Item Charge Assignment Purch.

        // Setup: Create Purchase Order.
        Initialize();
        CreatePurchaseOrderChargeItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // Exercise: Assign the Item Charge.
        PurchaseLine.ShowItemChargeAssgnt();

        // Verify: Validate Item Charge Assignment Purch.
        VerifyItemChargeAssignment(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentHandler')]
    [Scope('OnPrem')]
    procedure GetReceiptLinesOnPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Invoice, and Get Receipt Lines, Verify that lines get generated on Purchase Invoice and Post the Invoice.

        // Setup: Create Purchase Order and Post.
        Initialize();
        CreatePurchaseOrderAndPost(PurchaseHeader, PurchaseLine);

        // Exercise: Get Receipt Lines for Invoice.
        InvoicePostedPurchaseOrder(PurchaseHeader2, PurchaseHeader);

        // Verify: Validate Purchase Invoice.
        VerifyPurchaseDocument(PurchaseHeader."No.", PurchaseHeader2."No.");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentHandler')]
    [Scope('OnPrem')]
    procedure VendorInvoiceNoPostedPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Invoice with Item Charge Assignment & Validate the Vendor Invoice No in Posted Purchase Invoice.

        // Setup: Create Purchase Order and Post.
        Initialize();
        CreatePurchaseOrderAndPost(PurchaseHeader, PurchaseLine);

        // Exercise: Create Purchase Invoice and Get Receipt Lines for Invoice.
        InvoicePostedPurchaseOrder(PurchaseHeader2, PurchaseHeader);
        PurchaseLine.SetRange("Document No.", PurchaseHeader2."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindFirst();
        PurchaseLine.ShowItemChargeAssgnt();

        DocumentNo2 := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // Verify: Validate Vendor Invoice No. in Posted Purchase Invoice.
        VerifyPurchaseInvoiceDocument(DocumentNo2, PurchaseHeader2."Vendor Invoice No.", PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithPostingDateBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Try to Post a Purchase Order with blank Posting Date.

        // Setup: Create Purchase Order with Modified Purchase and Payables Setup.
        Initialize();
        UpdateDefaultPostingDate(PurchasesPayablesSetup."Default Posting Date"::"No Date");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));

        // Exercise: Try to post Purchase Order.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify posting error message.
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption("Posting Date"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        DocumentNo: Code[20];
        OldAutomaticCostPosting: Boolean;
        DiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // Create a new Purchase Order and Verify the posted values.

        // Setup: Update Automatic Cost Posting in Inventory setup, Vendor Invoice Discount and Create Purchase Order.
        Initialize();
        CreateInvoiceDiscount(VendorInvoiceDisc);
        UpdateAutomaticCostPosting(OldAutomaticCostPosting, true);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, VendorInvoiceDisc.Code, PurchaseHeader."Document Type"::Order);
        DiscountAmount := ((VendorInvoiceDisc."Discount %" * PurchaseLine."Line Amount") / 100);
        VATAmount := ((PurchaseLine."VAT %" * (PurchaseLine."Line Amount" - DiscountAmount)) / 100);

        // Exercise: Calculate Invoice Discount and post Purchase Order.
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Check GL Entry, Vendor Ledger Entry, Detailed Vendor Ledger Entry, Value Entry and VAT Entry.
        VerifyGLEntryWithVATAmount(DocumentNo, PurchaseLine);
        VerifyVATEntryWithBase(DocumentNo, PurchaseLine);
        VerifyVendorLedgerEntryWithRemainingAmount(DocumentNo, PurchaseLine."Line Amount" - DiscountAmount + VATAmount);
        VerifyDetailedVendorLedgerEntry(DocumentNo, PurchaseLine."Line Amount" - DiscountAmount + VATAmount);
        VerifyAmountInValueEntry(DocumentNo, PurchaseHeader."Buy-from Vendor No.", PurchaseLine."Line Amount" - DiscountAmount);

        // Tear Down:
        UpdateAutomaticCostPosting(OldAutomaticCostPosting, OldAutomaticCostPosting);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithDifferentPayToVendorNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        // Test to validate Program populates information on Individual tab on Purchase Order according to Pay-to Vendor No.

        // Setup: Create purchase Order.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateItem());

        // Exercise: Change pay to Vendor No of Purchase Order.
        VendorNo := CreateVendor();
        PurchaseHeader.Validate("Pay-to Vendor No.", VendorNo);
        PurchaseHeader.Modify(true);

        // Verify: Purchase Order With Different Pay To Vendor No.
        VerifyPurchaseOrder(PurchaseHeader."No.", PurchaseHeader."Pay-to Vendor No.", PurchaseLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchLineStdTextOnModifyBuyFromVendorNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 360323] Purchase line with Standard Text type is not deleted when 'Buy-From Vendor No.' changed
        Initialize();

        // [GIVEN] Create Purchase Order header with Vendor = 'A'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        // [GIVEN] Add a Purchase Line of Standard Text
        CreateStandardTextLine(PurchaseLine, PurchaseHeader);

        // [WHEN] Modify 'Buy-From Vendor No.' to 'B' on Purchase Header.
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", CreateVendor());

        // [THEN] Purchase line with Standard Text still exists
        PurchaseLine.SetRange(Type, PurchaseLine.Type::" ");
        PurchaseLine.SetRange("No.", PurchaseLine."No.");
        PurchaseLine.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithChangeUOM()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Create Item with multiple Unit of Measure and Create Purchase Order with Job and verify Job Unit Price is updated when changing UOM on Purchase Line.

        // Setup: Create Item with multiple item unit of measure and Create purchase order.
        Initialize();
        CreateItemWithUnitPrice(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);

        // Exercise: Create Purchase Order and Change the UOM on Purchase Line.
        CreatePurchaseOrderWithJob(PurchaseHeader, PurchaseLine, Item."No.", ItemUnitOfMeasure.Code);

        // Verify: Check the JOB Unit Price is changed.
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          PurchaseLine."Job Unit Price", Item."Unit Price" * ItemUnitOfMeasure."Qty. per Unit of Measure",
          GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, PurchaseLine.FieldCaption("Job Unit Price"), PurchaseLine."Job Unit Price", PurchaseLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithJobUnitCostFactor()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        UnitCostFactor: Decimal;
    begin
        // Create Item with multiple Unit of Measure and Create Purchase Order with Job and verify Job Unit Price is updated when changing UOM on Purchase Line.

        // Setup: Create Item with item unit of measure and Create purchase order.
        Initialize();

        // Exercise: Create Purchase Order and Change the UOM on Purchase Line.
        CreateItemWithUOMandStandartCost(Item);
        CreatePurchOrderWithJobAndJobItemPrice(PurchaseHeader, PurchaseLine, Item."No.", Item."Base Unit of Measure", UnitCostFactor);

        // Verify: Job Unit Price is not cleared after setting Quantity.
        Assert.AreEqual(Item."Unit Cost" * UnitCostFactor, PurchaseLine."Job Unit Price", JobUnitPriceErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithChangeUOMAndVerifyGLAndJobLedger()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        JobNo: Code[20];
        LineAmount: Decimal;
        JobUnitPrice: Decimal;
    begin
        // Create Item with multiple Unit of Measure and Create Purchase Order with Job and change UOM on Purchase Line and verify GL Entry.

        // Setup: Create Item with multiple item unit of measure and Create purchase order.
        Initialize();
        CreateItemWithUnitPrice(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        CreatePurchaseOrderWithJob(PurchaseHeader, PurchaseLine, Item."No.", ItemUnitOfMeasure.Code);
        JobNo := PurchaseLine."Job No.";
        LineAmount := PurchaseLine."Line Amount";
        JobUnitPrice := PurchaseLine."Job Unit Price";

        // Exercise: Post Purchase Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Check the JOB Unit Price is changed.
        VerifyGLEntryWithJob(DocumentNo, JobNo, LineAmount);
        VerifyJobLedgerEntry(PurchaseLine, DocumentNo, JobNo, JobUnitPrice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithIndirectCostItemVerifyJobLedger()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        JobNo: Code[20];
        JobUnitPrice: Decimal;
    begin
        // Create Item with multiple Unit of Measure and Create Purchase Order with Job and change UOM on Purchase Line and verify GL Entry.

        // Setup: Create Item with multiple item unit of measure and Create purchase order.
        Initialize();
        CreateItemWithUnitPrice(Item);
        ModifyItemIndirectCost(Item);

        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        CreatePurchaseOrderWithJob(PurchaseHeader, PurchaseLine, Item."No.", ItemUnitOfMeasure.Code);
        JobNo := PurchaseLine."Job No.";
        JobUnitPrice := PurchaseLine."Job Unit Price";

        // Exercise: Post Purchase Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Check the JOB Ledger Entry has right Total Cost (LCY).
        VerifyJobLedgerEntry(PurchaseLine, DocumentNo, JobNo, JobUnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnQtyToShipBaseInPurchaseCreditMemoIsValidatedWhileDefaultQtyToReceiveIsRemainder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361731] "Return Qty. to Ship (Base)" in Purchase Credit Memo is validated while "Default Qty. to Receive" is "Remainder"
        Initialize();

        // [GIVEN] "Default Quantity to Receive" is "Remainder" in Purchase and Payable Setup.
        UpdateDefaultQtyToReceive(PurchasesPayablesSetup."Default Qty. to Receive"::Remainder);

        // [GIVEN] Purchase Credit Memo Line with "Quantity" = 0.
        CreatePurchaseLineWithQty(PurchaseLine, 0, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Set "Quantity" in Purchase Invoice Line to "X"
        Qty := LibraryRandom.RandDec(1000, 2);
        PurchaseLine.Validate(Quantity, Qty);

        // [THEN] "Return Qty. to Ship (Base)" in Purchase Credit Memo Line is "X"
        Assert.AreEqual(Qty, PurchaseLine."Return Qty. to Ship (Base)", ReturnQuantitytyToShipBaseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnQtyToShipBaseInPurchaseCreditMemoIsValidatedWhileDefaultQtyToReceiveIsBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361731] "Return Qty. to Ship (Base)" in Purchase Credit Memo is validated while "Default Qty. to Receive" is "Blank"
        Initialize();

        // [GIVEN] "Default Quantity to Receive" is "Blank" in Purchase and Payable Setup.
        UpdateDefaultQtyToReceive(PurchasesPayablesSetup."Default Qty. to Receive"::Blank);

        // [GIVEN] Purchase Invoice Line with "Quantity" = 0.
        CreatePurchaseLineWithQty(PurchaseLine, 0, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Set "Quantity" in Purchase Invoice Line to "X"
        Qty := LibraryRandom.RandDec(1000, 2);
        PurchaseLine.Validate(Quantity, Qty);

        // [THEN] "Return Qty. to Ship (Base)" in Purchase Credit Memo Line is "X"
        Assert.AreEqual(Qty, PurchaseLine."Return Qty. to Ship (Base)", ReturnQuantitytyToShipBaseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToReceiveBaseInPurchaseInvoiceIsValidatedWhileDefaultQtyToReceiveIsReminder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361731] "Qty. To Receive (Base)" in Purchase Invoice is validated while "Default Qty. to Receive" is "Reminder"
        Initialize();

        // [GIVEN] "Default Quantity to Receive" is "Remainder" in Purchase and Payable Setup.
        UpdateDefaultQtyToReceive(PurchasesPayablesSetup."Default Qty. to Receive"::Remainder);

        // [GIVEN] Purchase Invoice Line with "Quantity" = 0.
        CreatePurchaseLineWithQty(PurchaseLine, 0, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Set "Quantity" in Purchase Invoice Line to "X"
        Qty := LibraryRandom.RandDec(1000, 2);
        PurchaseLine.Validate(Quantity, Qty);

        // [THEN] "Qty. To Receive (Base)" in Purchase Invoice Line is "X"
        Assert.AreEqual(Qty, PurchaseLine."Qty. to Receive (Base)", QuantityToRecvBaseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToReceiveBaseInPurchaseInvoiceIsValidatedWhileDefaultQtyToReceiveIsBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361731] "Qty. To Receive (Base)" in Purchase Invoice is validated while "Default Qty. to Receive" is "Blank"
        Initialize();

        // [GIVEN] "Default Quantity to Receive" is "Blank" in Purchase and Payable Setup.
        UpdateDefaultQtyToReceive(PurchasesPayablesSetup."Default Qty. to Receive"::Blank);

        // [GIVEN] Purchase Invoice Line with "Quantity" = 0.
        CreatePurchaseLineWithQty(PurchaseLine, 0, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Set "Quantity" in Purchase Invoice Line to "X"
        Qty := LibraryRandom.RandDec(1000, 2);
        PurchaseLine.Validate(Quantity, Qty);

        // [THEN] "Qty. To Receive (Base)" in Purchase Invoice Line is "X"
        Assert.AreEqual(Qty, PurchaseLine."Qty. to Receive (Base)", QuantityToRecvBaseErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptWithDefaultQtyBlank()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // Verify that Qty to receive in Purchase Line is blank after doing Undo receipt when Default Qty To Receive field is balnk in Purchases & Payables setup.

        // Setup: Update Purchases & Payables setup, Create and post purchase order.
        Initialize();
        UpdateDefaultQtyToReceive(PurchasesPayablesSetup."Default Qty. to Receive"::Blank);

        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);
        ModifyPurchaseLineQtyToReceive(PurchaseLine, PurchaseLine.Quantity / LibraryRandom.RandIntInRange(2, 4)); // To make sure Qty. to receive must be less than Quantity.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        FindPurchRcptLine(PurchRcptLine, PurchaseLine."Document No.");

        // Exercise: Undo purchase receipt.
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // Verify: Verify Quantity after Undo Receipt on Posted Purchase Receipt And Quantity to Receive is blank on Purchase Line.
        VerifyUndoReceiptLineOnPostedReceipt(PurchaseLine."Document No.", PurchaseLine."Qty. to Receive");
        VerifyQuantitytoReceiveOnPurchaseLine(PurchaseHeader."Document Type", PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToReceiveBaseInPurchaseLineIsValidatedWhileDefaultQtyToReceiveIsRemainder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361537] "Qty. to receive (Base)" in Purchase Line is validated while "Default Qty. to Receive" is "Remainder"
        Initialize();

        // [GIVEN] "Default Quantity to Receive" is "Remainder" in Purchase and Payable Setup.
        UpdateDefaultQtyToReceive(PurchasesPayablesSetup."Default Qty. to Receive"::Remainder);

        // [GIVEN] Purchase Line with "Qty. To Receive" = 0.
        Qty := LibraryRandom.RandDec(1000, 2);
        CreatePurchaseLineWithQty(PurchaseLine, Qty, PurchaseHeader."Document Type"::Order);

        // [WHEN] Set "Qty. To Receive" in Purchase Order Line to "X"
        PurchaseLine.Validate("Qty. to Receive", Qty);

        // [THEN] "Qty. To Receive (Base)" in Purchase Order Line is "X"
        Assert.AreEqual(Qty, PurchaseLine."Qty. to Receive (Base)", QtyToRecvBaseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToReceiveBaseInPurchaseLineIsValidatedWhileDefaultQtyToReceiveIsBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361537] "Qty. to receive (Base)" in Purchase Line is validated while "Default Qty. to Receive" is "Blank"
        Initialize();

        // [GIVEN] "Default Quantity to Receive" is "Blank" in Purchase and Payable Setup.
        UpdateDefaultQtyToReceive(PurchasesPayablesSetup."Default Qty. to Receive"::Blank);

        // [GIVEN] Purchase Line with "Qty. To Receive" = 0.
        Qty := LibraryRandom.RandDec(1000, 2);
        CreatePurchaseLineWithQty(PurchaseLine, Qty, PurchaseHeader."Document Type"::Order);

        // [WHEN] Set "Qty. To Receive" in Purchase Order Line to "X"
        PurchaseLine.Validate("Qty. to Receive", Qty);

        // [THEN] "Qty. To Receive (Base)" in Purchase Order Line is "X"
        Assert.AreEqual(Qty, PurchaseLine."Qty. to Receive (Base)", QtyToRecvBaseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQuantityIsRoundedTo0OnPurchaseOrderLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Purchase Order Line - Rounding Precision]
        // [SCENARIO] Error is thrown when rounding precision causes the base values to be rounded to 0.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1 / LibraryRandom.RandIntInRange(2, 10);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Purchase Line where the unit of measure code is set to the nonbase unit of measure.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));

        PurchaseLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        PurchaseLine.Modify(true);

        // [Then] Base Quantity rounds to 0 and throws error.
        asserterror PurchaseLine.Validate(Quantity, 1 / (LibraryRandom.RandIntInRange(100, 1000)));
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyToReceiveRoundedTo0OnPurchaseOrderLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Purchase Order Line - Rounding Precision]
        // [SCENARIO] Error is thrown when rounding precision causes the base values to be rounded to 0.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1 / LibraryRandom.RandIntInRange(2, 10);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Purchase Line where the unit of measure code is set to the nonbase unit of measure.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));

        PurchaseLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        PurchaseLine.Modify(true);

        // [Then] Base "Qty. to Receive" to Order rounds to 0 and throws error.
        asserterror PurchaseLine.Validate("Qty. to Receive", 1 / (LibraryRandom.RandIntInRange(100, 1000)));
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyToInvoiceRoundedTo0OnPurchaseOrderLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Purchase Order Line - Rounding Precision]
        // [SCENARIO] Error is thrown when rounding precision causes the base values to be rounded to 0.
        Initialize();

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1 / LibraryRandom.RandIntInRange(2, 10);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Purchase Line where the unit of measure code is set to the nonbase unit of measure.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));

        PurchaseLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        PurchaseLine.Modify(true);

        // [Then] Base Qty. to Invoice rounds to 0 and throws error.
        asserterror PurchaseLine.Validate("Qty. to Invoice", 1 / (LibraryRandom.RandIntInRange(100, 1000)));
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseReturnQtyToShipRoundedTo0OnPurchaseOrderLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Purchase Order Line - Rounding Precision]
        // [SCENARIO] Error is thrown when rounding precision causes the base values to be rounded to 0.
        Initialize();
        UpdateDefaultQtyToReceive(PurchasesPayablesSetup."Default Qty. to Receive"::Remainder);

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1 / LibraryRandom.RandIntInRange(2, 10);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Purchase Line where the unit of measure code is set to the nonbase unit of measure.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));

        PurchaseLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        PurchaseLine.Modify(true);

        // [Then] Base "Return Qty. to Ship" to Order rounds to 0 and throws error.
        asserterror PurchaseLine.Validate("Return Qty. to Ship", 1 / (LibraryRandom.RandIntInRange(100, 1000)));
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseValuesAreRoundedWithRoundingPrecisionSpecifiedOnPurchaseOrderLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
        QtyToSet: Decimal;
    begin
        // [FEATURE] [Purchase Order Line - Rounding Precision]
        // [SCENARIO] Base values are rounded with the specified rounding precision.
        Initialize();
        UpdateDefaultQtyToReceive(PurchasesPayablesSetup."Default Qty. to Receive"::Remainder);

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1 / LibraryRandom.RandIntInRange(2, 10);
        QtyToSet := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Validate("Replenishment System", "Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Purchase Line where the unit of measure code is set to the nonbase unit of measure.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));

        PurchaseLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        PurchaseLine.Modify(true);

        // [WHEN] Quantity is set to a value that rounds the base quantity
        PurchaseLine.Validate(Quantity, QtyToSet);
        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, QtyRoundingPrecision), PurchaseLine."Quantity (Base)", 'Base quantity is not rounded correctly.');

        // [THEN] Qty. to Invoice (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, QtyRoundingPrecision), PurchaseLine."Qty. to Invoice (Base)", 'Qty. to Invoice (Base) is not rounded correctly.');

        // [THEN] "Qty. to Receive (Base)" is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, QtyRoundingPrecision), PurchaseLine."Qty. to Receive (Base)", '"Qty. to Receive (Base)" is not rounded correctly.');

        // [WHEN] "Return Qty. to Ship" is set to a value that rounds the base quantity
        PurchaseLine.Validate("Return Qty. to Ship", PurchaseLine.Quantity);
        // [THEN] "Return Qty. to Ship (Base)" is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, QtyRoundingPrecision), PurchaseLine."Return Qty. to Ship (Base)", '"Return Qty. to Ship (Base)" is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseValuesAreRoundedWithRoundingPrecisionUnspecifiedOnPurchaseOrderLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyToSet: Decimal;
    begin
        // [FEATURE] [Purchase Order Line - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the default rounding precision when rounding precision is not specified.
        Initialize();
        UpdateDefaultQtyToReceive(PurchasesPayablesSetup."Default Qty. to Receive"::Remainder);

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        BaseQtyPerUOM := 1;
        QtyToSet := LibraryRandom.RandDec(10, 7);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Validate("Replenishment System", "Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Purchase Line where the unit of measure code is set to the nonbase unit of measure.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));

        PurchaseLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        PurchaseLine.Modify(true);

        // [WHEN] Quantity is set to a value that rounds the base quantity
        PurchaseLine.Validate(Quantity, QtyToSet);

        // [THEN] Quantity (Base) is rounded with the default rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, 0.00001), PurchaseLine."Quantity (Base)", 'Base qty. is not rounded correctly.');

        // [THEN] Qty. to Invoice (Base) is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, 0.00001), PurchaseLine."Qty. to Invoice (Base)", 'Qty. to Invoice (Base) is not rounded correctly.');

        // [THEN] "Qty. to Receive (Base)" is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, 0.00001), PurchaseLine."Qty. to Receive (Base)", '"Qty. to Receive (Base)" is not rounded correctly.');

        // [WHEN] "Return Qty. to Ship" is set to a value that rounds the base quantity
        PurchaseLine.Validate("Return Qty. to Ship", PurchaseLine.Quantity);
        // [THEN] "Return Qty. to Ship (Base)" is rounded with the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM * QtyToSet, 0.00001), PurchaseLine."Return Qty. to Ship (Base)", '"Return Qty. to Ship (Base)" is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseValuesAreRoundedWithRoundingPrecisionOnPurchaseOrderLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
        QtyToSet: Decimal;
    begin
        // [FEATURE] [Purchase Order Line - Rounding Precision]
        // [SCENARIO] Quantity (Base) is rounded with the default rounding precision when rounding precision is not specified.
        Initialize();
        UpdateDefaultQtyToReceive(PurchasesPayablesSetup."Default Qty. to Receive"::Remainder);

        // [GIVEN] An item with 2 unit of measures and qty. rounding precision on the base item unit of measure set.
        NonBaseQtyPerUOM := LibraryRandom.RandIntInRange(5, 10);
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := 1 / LibraryRandom.RandIntInRange(2, 10);
        QtyToSet := LibraryRandom.RandDec(10, 7);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Validate("Replenishment System", "Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Purchase Line where the unit of measure code is set to the nonbase unit of measure.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));

        PurchaseLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        PurchaseLine.Modify(true);

        // [WHEN] Quantity is set to a value that rounds the base quantity
        PurchaseLine.Validate(Quantity, (NonBaseQtyPerUOM - 1) / NonBaseQtyPerUOM);

        // [THEN] Quantity (Base) is rounded with the specified rounding precision
        Assert.AreEqual(NonBaseQtyPerUOM - 1, PurchaseLine."Quantity (Base)", 'Base quantity is not rounded correctly.');

        // [THEN] Qty. to Invoice (Base) is rounded with the specified rounding precision
        Assert.AreEqual(NonBaseQtyPerUOM - 1, PurchaseLine."Qty. to Invoice (Base)", 'Qty. to Invoice (Base) is not rounded correctly.');

        // [THEN] "Qty. to Receive (Base)" is rounded with the specified rounding precision
        Assert.AreEqual(NonBaseQtyPerUOM - 1, PurchaseLine."Qty. to Receive (Base)", '"Qty. to Receive (Base)" is not rounded correctly.');

        // [WHEN] "Return Qty. to Ship" is set to a value that rounds the base quantity
        PurchaseLine.Validate("Return Qty. to Ship", PurchaseLine.Quantity);
        // [THEN] "Return Qty. to Receive (Base)" is rounded with the specified rounding precision
        Assert.AreEqual(NonBaseQtyPerUOM - 1, PurchaseLine."Return Qty. to Ship (Base)", 'Return Qty. to Ship (Base) is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToInvoiceBaseIsRoundedToBaseUnitOfMeasure()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemUnitOfMeasure1: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        LibraryInventory: Codeunit "Library - Inventory";
        Qty: Decimal;
        QtyPerUoM: Integer;
    begin
        // [FEATURE] [Qty. to Invoice]
        // [SCENARIO 361537] "Qty. to invoice (Base)" is rounded with the Quantity Rounding Precision from the base UoM
        Initialize();

        // [GIVEN] Create Item with item unit of measure and set the rounding precision to 1.
        CreateItemWithUnitPrice(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure1, Item."No.", 1);
        ItemUnitOfMeasure1.Validate("Qty. Rounding Precision", 1);
        ItemUnitOfMeasure1.Modify(true);

        // [GIVEN] Set the Base UoM
        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure1.Code);
        Item.Modify(true);

        // [GIVEN] Create a second item UoM
        QtyPerUoM := 6;
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure2, Item."No.", QtyPerUoM);

        // [GIVEN] Purchase Line with a Qty.
        Qty := 1;
        CreatePurchaseLineWithQty(PurchaseLine, Qty, PurchaseHeader."Document Type"::Order);
        PurchaseLine.Validate("No.", Item."No.");
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure2.Code);

        // [WHEN] Set "Qty. To Invoice" to a fraction of the quantity
        Qty := 5 / 6;
        PurchaseLine.Validate("Qty. to Invoice", Qty);

        // [THEN] "Qty. To Invoice (Base)" is rounded
        Assert.AreEqual(5, PurchaseLine."Qty. to Invoice (Base)", QtyToInvcBaseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnQtyToShipBaseInPurchaseLineIsValidatedWhileDefaultQtyToReceiveIsRemainder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361537] "Return Qty. to Ship (Base)" in Purchase Line is validated while "Default Qty. to Receive" is "Remainder"
        Initialize();

        // [GIVEN] "Default Quantity to Receive" is "Blank" in Purchase and Payable Setup.
        UpdateDefaultQtyToReceive(PurchasesPayablesSetup."Default Qty. to Receive"::Remainder);

        // [GIVEN] Purchase Line with "Return Qty. To Ship" = 0.
        Qty := LibraryRandom.RandDec(1000, 2);
        CreatePurchaseLineWithQty(PurchaseLine, Qty, PurchaseHeader."Document Type"::Order);

        // [WHEN] Set "Return Qty. to Ship" in Purchase Order Line to "X"
        PurchaseLine.Validate("Return Qty. to Ship", Qty);

        // [THEN] "Return Qty. to Ship (Base)" in Purchase Order Line is "X"
        Assert.AreEqual(Qty, PurchaseLine."Return Qty. to Ship (Base)", ReturnQtyToShipBaseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnQtyToShipBaseInPurchaseLineIsValidatedWhileDefaultQtyToReceiveIsBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361537] "Return Qty. to Ship (Base)" in Purchase Line is validated while "Default Qty. to Receive" is "Blank"
        Initialize();

        // [GIVEN] "Default Quantity to Receive" is "Remainder" in Purchase and Payable Setup.
        UpdateDefaultQtyToReceive(PurchasesPayablesSetup."Default Qty. to Receive"::Blank);

        // [GIVEN] Purchase Line with "Return Qty. To Ship" = 0.
        Qty := LibraryRandom.RandDec(1000, 2);
        CreatePurchaseLineWithQty(PurchaseLine, Qty, PurchaseHeader."Document Type"::Order);

        // [WHEN] Set "Return Qty. to Ship" in Purchase Order Line to "X"
        PurchaseLine.Validate("Return Qty. to Ship", Qty);

        // [THEN] "Return Qty. to Ship (Base)" in Purchase Order Line is "X"
        Assert.AreEqual(Qty, PurchaseLine."Return Qty. to Ship (Base)", ReturnQtyToShipBaseErr);
    end;


    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure QtyToReceiveInPurchaseLineIsCorrectlyUpdatedWithChangeInQty()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReceivablesSetup: Record "Purchases & Payables Setup";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
        PurchaseLine4: Record "Purchase Line";
        Item1: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Item4: Record Item;
        Qty: Decimal;
        Loc1: Record Location;
        Loc2: Record Location;
    begin
        Initialize();

        // [GIVEN] "Default Quantity to Receive" is "Remainder" in Purchase and Payable Setup.
        UpdateDefaultQtyToReceive(PurchaseReceivablesSetup."Default Qty. to Receive"::Remainder);
        UpdateDefaultWarehouseSetup(true, false, true, false);

        // [GIVEN] Qty is "X"
        Qty := LibraryRandom.RandDec(1000, 2);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);

        // [CASE 1]: Purchase Line with non inventory item
        LibraryInventory.CreateNonInventoryTypeItem(Item1);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item1."No.", 0);
        PurchaseLine1.Validate(Quantity, Qty);

        // [THEN] "Qty. to Receive " in Purchase Order Line is "X"
        Assert.AreEqual(Qty, PurchaseLine1."Qty. to Receive", StrSubstNo(QtyToReceiveUpdateErr, Qty));

        // [CASE 2]: Purchase Line with inventory item, no location
        LibraryInventory.CreateItem(Item2);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, Item2."No.", 0);
        PurchaseLine2.Validate(Quantity, Qty);

        // [THEN] "Qty. to Receive " in Purchase Order Line is "0"
        Assert.AreEqual(0, PurchaseLine2."Qty. to Receive", StrSubstNo(QtyToReceiveUpdateErr, 0));

        //[CASE 3]: Purchase Line with inventory item and wharehouse location with putaway and receive true
        LibraryWarehouse.CreateLocationWMS(Loc1, false, true, false, true, false);
        LibraryInventory.CreateItem(Item3);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine3, PurchaseHeader, PurchaseLine3.Type::Item, Item3."No.", 0);
        PurchaseLine3.Validate("Location Code", Loc1.Code);
        PurchaseLine3.Validate(Quantity, Qty);

        // [THEN] "Qty. to Receive " in Purchase Order Line is "0"
        Assert.AreEqual(0, PurchaseLine3."Qty. to Receive", StrSubstNo(QtyToReceiveUpdateErr, 0));

        // [CASE 4]: Purchase Line with inventory item and wharehouse location with putaway and receive false
        LibraryWarehouse.CreateLocationWMS(Loc2, false, false, false, false, false);
        LibraryInventory.CreateItem(Item4);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine4, PurchaseHeader, PurchaseLine4.Type::Item, Item4."No.", 0);
        PurchaseLine4.Validate("Location Code", Loc2.Code);
        PurchaseLine4.Validate(Quantity, Qty);

        // [THEN] "Qty. to Receive " in Purchase Order Line is "X"
        Assert.AreEqual(Qty, PurchaseLine4."Qty. to Receive", StrSubstNo(QtyToReceiveUpdateErr, Qty));

    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithGLAccAndUOMDefaultQtyBlank()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // Verify that Qty to receive in Purchase Line is blank after enering G/L Account with UoM

        // Setup: Update Purchases & Payables setup, Create purchase order.
        Initialize();
        UpdateDefaultQtyToReceive(PurchasesPayablesSetup."Default Qty. to Receive"::Blank);

        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());

        // Exercise: create purchase line for G/L account and update Unit of Measure
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(10));
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        PurchaseLine.Validate("Unit of Measure", UnitOfMeasure.Code);

        // Verify: Verify Quantity after Undo Receipt on Posted Purchase Receipt And Quantity to Receive is blank on Purchase Line.
        Assert.AreEqual(0, PurchaseLine."Qty. to Receive", 'qty. to Receive should be 0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceWithPartialQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check the Quantity on Posted Purchase Invoice Line when Purchase Order Posted using Purchase Order Page.

        // Setup: Create Purchase Order.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateItem());
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Qty. to Invoice" / LibraryRandom.RandIntInRange(2, 5));
        PurchaseLine.Modify(true);

        // Exercise: Open Created Purchase Header from Purchase Order Page check "Buy from Vendor No." and Post Purchase Document.
        OpenPurchaseOrder(PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.", PurchaseHeader.Status);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Quantity on Posted Purchase Invoice Line is equal to Purchase Line Quantity to Invoice.
        VerifyQuantityOnPurchaseInvoiceLine(PurchaseHeader."No.", PurchaseLine."Buy-from Vendor No.", PurchaseLine."Qty. to Invoice");
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportPurchaseRequestPageHandler,PurchaseAnalysisMatrixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisReportWithItemLedgerEntryTypePurchase()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisReportName: Record "Analysis Report Name";
        ItemAnalysisView: Record "Item Analysis View";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // Check Cost Amount(Expected) on Purchase Analysis Matrix when Item Ledger Entry Type Filter Purchase.

        // Setup: Post Purchase Document with Ship Option and Create Analysis Report Name.
        Initialize();
        ItemNo := CreateItem();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo);
        FindValueEntry(ValueEntry, ItemNo, PurchaseHeader."Buy-from Vendor No.",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
        LibraryVariableStorage.Enqueue(ValueEntry."Cost Amount (Expected)");
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Purchase);
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, ItemAnalysisView."Analysis Area");

        // Exercise: Open Analysis Report Purchase with Correct filter Item Ledger Entry Type Purchase.
        OpenAnalysisReportPurchase(AnalysisReportName.Name,
          CreateAnalysisLineWithTypeVendor(ItemAnalysisView."Analysis Area", PurchaseHeader."Buy-from Vendor No."),
          CreateAnalysisColumnWithItemLedgerEntryType(ItemAnalysisView."Analysis Area",
            Format(ValueEntry."Item Ledger Entry Type"::Purchase), AnalysisColumn."Value Type"::"Cost Amount"));

        // Verify: Verification done in PurchaseAnalysisMatrixRequestPageHandler.
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportPurchaseRequestPageHandler,PurchaseAnalysisMatrixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisReportWithItemLedgerEntryTypePurchaseAndValueTypeSale()
    var
        AnalysisColumn: Record "Analysis Column";
        ValueEntry: Record "Value Entry";
    begin
        // Check Sale Amount on Purchase Analysis Matrix when Item Ledger Entry Type Filter Purchase.
        PurchaseAnalysisReportWithItemLedgerEntryTypeAndValueType(AnalysisColumn."Value Type"::"Sales Amount",
          ValueEntry."Item Ledger Entry Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportPurchaseRequestPageHandler,PurchaseAnalysisMatrixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisReportWithItemLedgerEntryTypeSaleAndValueTypeCost()
    var
        AnalysisColumn: Record "Analysis Column";
        ValueEntry: Record "Value Entry";
    begin
        // Check Cost Amount(Expected) on Purchase Analysis Matrix when Item Ledger Entry Type Filter Sale.
        PurchaseAnalysisReportWithItemLedgerEntryTypeAndValueType(AnalysisColumn."Value Type"::"Cost Amount",
          ValueEntry."Item Ledger Entry Type"::Sale);
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportPurchaseRequestPageHandler,PurchaseAnalysisMatrixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisReportWithItemLedgerEntryTypeSaleAndValueTypeSales()
    var
        AnalysisColumn: Record "Analysis Column";
        ValueEntry: Record "Value Entry";
    begin
        // Check Sales Amount on Purchase Analysis Matrix when Item Ledger Entry Type Filter Sale.
        PurchaseAnalysisReportWithItemLedgerEntryTypeAndValueType(AnalysisColumn."Value Type"::"Sales Amount",
          ValueEntry."Item Ledger Entry Type"::Sale);
    end;

    local procedure PurchaseAnalysisReportWithItemLedgerEntryTypeAndValueType(AnalysisColumnValueType: Enum "Analysis Value Type"; ValueType: Enum "Item Ledger Entry Type")
    var
        AnalysisReportName: Record "Analysis Report Name";
        ItemAnalysisView: Record "Item Analysis View";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        // Setup: Post Purchase Document with Ship Option and Create Analysis Report Name.
        Initialize();
        ItemNo := CreateItem();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        LibraryVariableStorage.Enqueue(0);  // Amount must be zero when an incorrect filter is applied.
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Purchase);
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, ItemAnalysisView."Analysis Area");

        // Exercise: Open Analysis Report Purchase with wrong filter Item Ledger Entry Type Sale.
        OpenAnalysisReportPurchase(AnalysisReportName.Name,
          CreateAnalysisLineWithTypeVendor(ItemAnalysisView."Analysis Area", PurchaseHeader."Buy-from Vendor No."),
          CreateAnalysisColumnWithItemLedgerEntryType(ItemAnalysisView."Analysis Area", Format(ValueType), AnalysisColumnValueType));

        // Verify: Verification done in PurchaseAnalysisMatrixRequestPageHandler.
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportPurchaseRequestPageHandler,PurchaseAnalysisMatrixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisReportWIthColumnHeader()
    var
        AnalysisReportName: Record "Analysis Report Name";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisColumn: Record "Analysis Column";
        AnalysisLineTemplateName: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 201736] "Column Header" is placed as column caption in Purchase Analysis Matrix
        Initialize();

        // [GIVEN] Analysis Report Name "N" for Purchase Analysis Area
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, AnalysisReportName."Analysis Area"::Purchase);
        AnalysisLineTemplateName := CreateAnalysisLineWithTypeVendor(AnalysisReportName."Analysis Area"::Purchase, CreateVendor());

        // [GIVEN] Analysis Column defined with "Column No." = '' and "Column Header" = "Col"
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisReportName."Analysis Area"::Purchase);
        LibraryERM.CreateAnalysisColumn(AnalysisColumn, AnalysisReportName."Analysis Area"::Purchase, AnalysisColumnTemplate.Name);
        AnalysisColumn."Column No." := '';
        AnalysisColumn."Column Header" := LibraryUtility.GenerateGUID();
        AnalysisColumn.Modify();

        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(AnalysisColumn."Column Header");

        // [WHEN] Open Analysis Report Purchase for Analysis Report Name "N"
        OpenAnalysisReportPurchase(AnalysisReportName.Name, AnalysisLineTemplateName, AnalysisColumnTemplate.Name);

        // [THEN] Column "Col" is visible and has caption "Col"
        // Verification done in PurchaseAnalysisMatrixRequestPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostingDateOnPurchRcptHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // Verify Program generates the Posted Purchase Receipt on same posting date of Warehouse Receipt Header posting date.

        // Setup: Create purchase order & create warehouse receipt for purchase order.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateItem());
        ModifyLocationOnPurchaseLine(PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        ModifyPostingDateOnWarehouseReceiptHeader(WarehouseReceiptHeader, PurchaseHeader."No.", PurchaseLine."No.");

        // Exercise: Post Warehouse Document.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Verify Purch Rcpt-Header posting date equal to Warehouse Receipt Header posting date.
        VerifyPurchRcptHeader(PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.", WarehouseReceiptHeader."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDefaultBinInPurchLine()
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Bin: Record Bin;
    begin
        // Verify that bin code exist in purchase Line when re-enter item removes the default bin.

        // Setup: Create purchase document with bin and bin content.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateBinAndBinContent(Bin, Item);
        CreatePurchaseDocumentWithLocation(PurchaseLine, PurchaseLine."Document Type"::Order, Item."No.", Bin."Location Code");

        // Exercise: Re-enter Item No.
        PurchaseLine.Validate("No.", Item."No.");

        // Verify: Verifying bin code exist on purchase line.
        PurchaseLine.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderAsReceiveWithDimension()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderToReverse: Record "Purchase Header";
        PostedDocumentNo: Code[20];
    begin
        // Create New Purchase Order post as Receive and verify Purchase Return Order Line Dimension Set ID with Purchase Receipt Dimension Set ID.
        // Setup: Create Purchase Order with Dimension and post as Receive then Create Purchase Return Order.
        Initialize();
        PostedDocumentNo := CreateAndPostPurchaseReceiptWithDimension(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderToReverse, PurchaseHeaderToReverse."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.");

        // Exercise: Get posted document lines to reverse.
        GetPostedDocLinesToReverse(PurchaseHeaderToReverse, OptionStringRef::"Posted Receipts", PostedDocumentNo);

        // Verify: Verify Purchase Return Order Line Dimension Set ID with Purchase Receipt Dimension Set ID.
        VerifyDimensionSetIDOnPurchLine(PurchaseHeaderToReverse."No.", PostedDocumentNo);
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyReceiptNoAndReceiptLineNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PostedInvoiceNo: Code[20];
        PostedReceiptNo: Code[20];
    begin
        // Create New Purchase Order post as Receive and verify the Receipt No. and Receipt Line No.

        // Setup: Create Purchase Order post as Receive then Create Purchase Invoice.
        Initialize();
        PostedReceiptNo := CreateAndPostPurchaseReceipt(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader2, PurchaseHeader2."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.");
        GetReceiptLine(PurchaseHeader2);

        // Excercise: Post the above created purchase invoice with last posted purchaase order as receipt.
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // Verify: Verify the Receipt No. and Receipt Line No.
        VerifyGetReceiptDocNo(PostedInvoiceNo, PostedReceiptNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckNoOverFlowErrorExistOnPurchaseLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify that no Overflow error on purchase line with more ranges.

        // Setup: Create purchase order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);

        // Exercise: Taken large random values.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(0, 1, 3));
        PurchaseLine.Validate(Quantity, LibraryRandom.RandIntInRange(10000000, 2147483647));

        // Verify: Verifying purchase line amount.
        Assert.AreEqual(
          Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost"), PurchaseLine."Line Amount",
          StrSubstNo(AmountError, PurchaseLine.FieldCaption("Line Amount"), PurchaseLine."Line Amount", PurchaseLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('StandardVendorPurchCodesHndlr')]
    [Scope('OnPrem')]
    procedure PurchaseLineWithStandardPurchCodeDimesion()
    var
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        StandardPurchaseLine: Record "Standard Purchase Line";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        // Check Purchase Code Line with Dimensions are copied correctly in Purchase Line.

        // Setup: Create Dimesion Values.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue1, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue2, GeneralLedgerSetup."Shortcut Dimension 2 Code");

        // Exercise: Create Purchase Order with Purchase Code.
        CreatePurchOrderWithPurchCode(StandardPurchaseLine, PurchaseHeader, DimensionValue1.Code, DimensionValue2.Code);

        // Verify: Verify Purchase Code Line are copied correctly in Purchase Line.
        VerifyPurchaseLine(StandardPurchaseLine, PurchaseHeader."No.", DimensionValue1.Code, DimensionValue2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckStatusOpenErrorWithReleasedPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // Verify the Status open error when one more purchase line added on release purchase order.

        // Setup: Create and release purchase order.
        Initialize();
        CreatePurchaseDocumentWithLocation(PurchaseLine, PurchaseLine."Document Type"::Order, LibraryInventory.CreateItem(Item), '');
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Exercise: Add one more purchase line.
        asserterror LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLine."No.", LibraryRandom.RandDec(100, 2));

        // Verify: Verifying Open Status Error.
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption(Status), Format(PurchaseHeader.Status::Open));
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportPurchaseRequestPageHandler,PurchaseAnalysisMatrixColumnsRPH')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisReportMultipleColumns()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisReportName: Record "Analysis Report Name";
        ItemAnalysisView: Record "Item Analysis View";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        PurchAnalysisMatrix: Page "Purchase Analysis Matrix";
        ItemNo: Code[20];
    begin
        // Check columns' visibility in matrix form

        // Setup: Post Purchase Document and Create Analysis Report
        Initialize();
        ItemNo := CreateItem();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo);
        FindValueEntry(
          ValueEntry, ItemNo, PurchaseHeader."Buy-from Vendor No.",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Purchase);
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, ItemAnalysisView."Analysis Area");

        // Exercise: Open Analysis Report Purchase with Correct filter Item Ledger Entry Type Purchase.
        OpenAnalysisReportPurchase(
          AnalysisReportName.Name,
          CreateAnalysisLineWithTypeVendor(ItemAnalysisView."Analysis Area", PurchaseHeader."Pay-to Vendor No."),
          CreateAnalysisMultipleColumns(
            ItemAnalysisView."Analysis Area", Format(ValueEntry."Item Ledger Entry Type"::Purchase),
            AnalysisColumn."Value Type"::"Cost Amount", PurchAnalysisMatrix.GetMatrixDimension()));

        // Verify: Verification done in PurchaseAnalysisMatrixColumnsRPH.
    end;

    [Test]
    [HandlerFunctions('StandardVendorPurchCodesHndlr')]
    [Scope('OnPrem')]
    procedure StandardPurchLineWithDefaultDimension()
    var
        Item: Record Item;
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        StandardPurchaseCode: Record "Standard Purchase Code";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GLAccountNo: Code[20];
    begin
        // Verify that correct dimensions are populated in purchase line when using default dimensions for G/L and Item using standard purchase code.

        // Setup: Create standard purchase document and default dimensions
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        CreateStandardPurchaseDocument(StandardPurchaseCode, GLAccountNo, LibraryInventory.CreateItem(Item));
        CreateDefaultDimensions(DimensionValue1, DimensionValue2, GLAccountNo, Item."No.");

        // Exercise: Create Purchase Order with Purchase Code.
        CreateStandardPurchLineForPurchaseOrder(PurchHeader, StandardPurchaseCode.Code);

        // Verify: Verify dimensions on Purchase line for G/L and item line.
        VerifyDimensionsOnPurchLine(PurchHeader."No.", PurchLine.Type::"G/L Account", GLAccountNo, DimensionValue1.Code, '');
        VerifyDimensionsOnPurchLine(PurchHeader."No.", PurchLine.Type::Item, Item."No.", '', DimensionValue2.Code);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CheckUnitCostLCYWithExchangeRate()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        ExchangeRateAmount: Decimal;
    begin
        // Verify the Unit Cost LCY on purchase return line when get posted document lines to reverse is doing with currency exchange rate.

        // Setup: Create vendor with currency and Create post Purchase order and create return purchase order.
        Initialize();
        CreateVendorWithCurrency(Vendor);
        ExchangeRateAmount := LibraryRandom.RandDec(10, 2);
        CreateExchangeRates(Vendor."Currency Code",
          CalcDate(StrSubstNo('<-%1M>', LibraryRandom.RandInt(5)), WorkDate()), ExchangeRateAmount, ExchangeRateAmount / 2);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, Vendor."No.", PurchaseHeader."Document Type"::Order);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CreateExchangeRates(Vendor."Currency Code", WorkDate(), ExchangeRateAmount, 2 * ExchangeRateAmount);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");

        // Exercise: Get posted document lines to reverse.
        GetPostedDocLinesToReverse(PurchaseHeader, OptionStringRef::"Posted Receipts", DocumentNo);

        // Verify: Verifying Unit Cost(LCY) with exchange rate.
        VerifyUnitCostLCYOnPurchaseReturnLine(PurchaseHeader."No.", PurchaseLine."Direct Unit Cost" / PurchaseHeader."Currency Factor");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderWithItemInventoryValueZeroAndJob()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        Initialize();
        CreateItemInventoryValueZero(Item);
        CreatePurchaseOrderWithJob(PurchaseHeader, PurchaseLine, Item."No.", Item."Base Unit of Measure");

        // Exercise: Post Purchase Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Check the Job ledger entry Unit Cost is zero.
        VerifyJobLedgerEntryZeroUnitCost(DocumentNo, PurchaseLine."Job No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithFCYDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        AmountLCY: Decimal;
    begin
        // Verify no error will appear while posting a Purchase Order with discount on Currency rounding.

        // Setup: Create Purchase Order, attach new Currency on Purchase Order and Post as Receive and Invoice.
        Initialize();
        CreatePurchaseHeaderWithCurrency(PurchaseHeader, CreateAndUpdateCurrency());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
        AmountLCY := Round(LibraryERM.ConvertCurrency(PurchaseLine."Amount Including VAT", PurchaseHeader."Currency Code", '', WorkDate()));

        // Exercise: Post Purchase document.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Remaining Amount LCY on Vendor ledger Entry.
        VerifyRemainingAmountLCY(PurchaseHeader."Buy-from Vendor No.", AmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CombinedDimOnPurchInvoiceWithItemChargeAssignedOnReceipt()
    var
        ConflictDimension: Record Dimension;
        ItemDimValue: Record "Dimension Value";
        ItemChargeDimValue: Record "Dimension Value";
        PurchHeader: Record "Purchase Header";
        DimensionMgt: Codeunit DimensionManagement;
        ConflictDimValue: array[2] of Code[20];
        ExpShortcutDimCode1: Code[20];
        ExpShortcutDimCode2: Code[20];
        DimNo: Option " ",Item,ItemCharge;
        DimSetID: array[10] of Integer;
        ExpectedDimSetID: Integer;
    begin
        // Check that posted invoice with item charge is inherit dimensions from assigned receipt

        Initialize();
        CreateDimValues(ConflictDimension, ConflictDimValue);
        CreateDimValue(ItemDimValue);
        CreateDimValue(ItemChargeDimValue);
        // Dimension from item have higher priority
        DimSetID[2] :=
          CreatePostPurchOrderWithDimension(PurchHeader, ItemDimValue, ConflictDimension.Code, ConflictDimValue[DimNo::Item]);
        DimSetID[1] :=
          CreatePostInvoiceWithReceiptLines(
            ItemChargeDimValue, ConflictDimension.Code, ConflictDimValue[DimNo::ItemCharge], PurchHeader);
        ExpectedDimSetID :=
          DimensionMgt.GetCombinedDimensionSetID(DimSetID, ExpShortcutDimCode1, ExpShortcutDimCode2);
        VerifyDimSetIDOnItemLedgEntry(ExpectedDimSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetReceiptLinesOnItemChargeAssignedOnMultipleShpts()
    var
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        DocNo: array[2] of Code[20];
        Qty: array[2] of Decimal;
        i: Integer;
    begin
        // Check that item charge is assign to correct shipment from the multiple set when posting purchase invoice with GetReceiptLines function.

        Initialize();
        CreateSalesOrder(SalesLine);
        CreatePurchaseOrderWithChargeItem(PurchHeader, PurchLine, SalesLine.Quantity);
        Qty[1] := Round(SalesLine.Quantity / 3, 1);
        Qty[2] := SalesLine.Quantity - Qty[1];
        for i := 1 to ArrayLen(Qty) do begin
            DocNo[i] := PostPartialShipment(SalesLine, Qty[i]);
            PurchLine.Find();
            ModifyPurchaseLineQtyToReceive(PurchLine, Qty[i]);
            AssignItemChargeToShipment(SalesLine."Document No.", PurchLine);
            LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
        end;
        CreatePostPurchInvWithGetReceiptLines(PurchHeader);
        VerifyChargeValueEntry(DocNo, PurchLine."No.", ArrayLen(Qty));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetReceiptLinesFromPurchOrderWithJobPrices()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InvoicePurchaseHeader: Record "Purchase Header";
        InvoicePurchLine: Record "Purchase Line";
    begin
        // Check that job unit prices successfully inherited from purchase order to purchase invoice with fucntion "Get Receipt Lines"

        Initialize();
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateItemWithUnitPrice(Item);
        CreateReceivePurchOrderWithJobUnitPrices(PurchaseHeader, PurchaseLine, Item."No.", JobTask);
        InvoicePostedPurchaseOrder(InvoicePurchaseHeader, PurchaseHeader);
        // Change "Qty To Invoice" to make sure that job prices won't changed
        ChangeQtyToInvoice(InvoicePurchLine, InvoicePurchaseHeader);
        VerifyJobPricesOfPurchInvWithRcptPurchOrder(PurchaseLine, InvoicePurchLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchHeaderDimWithSalesPerson()
    var
        PurchHeader: Record "Purchase Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        // Setup.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", SalespersonPurchaser.Code, Dimension.Code, DimensionValue.Code);

        // Exercise.
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, CreateVendor());
        PurchHeader.Validate("Purchaser Code", SalespersonPurchaser.Code);
        PurchHeader.Modify(true);

        // Verify.
        VerifyPurchHeaderDimensions(PurchHeader, DefaultDimension."Dimension Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePostReceivePurchOrderWithDiscount()
    var
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchHeader: Record "Purchase Header";
        ExpectedInvDiscAmount: Decimal;
        InvoiceDiscountValue: Decimal;
    begin
        // [SCENARIO 375185] Invoice Discount Amount is recalculated on Purchase Line created from Posted Receipt Line but not on Purchase Header
        Initialize();
        // [GIVEN] Create purchase order and calculate "Inv. Discount Amount" = "X" excl. VAT
        ExpectedInvDiscAmount := CreatePurchOrderAndGetDiscountWithoutVAT(PurchHeader);
        // [GIVEN] Set "Prices Including VAT" = TRUE and Receive order
        PostReceivePurchOrderWithVAT(PurchRcptLine, PurchHeader);
        // [GIVEN] Create Purchase Invoice excl. VAT with "Invoice Discount Value" in Header = "Y"
        Clear(PurchHeader);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, PurchRcptLine."Buy-from Vendor No.");
        CreateSimplePurchLine(PurchLine, PurchHeader, PurchLine.Type::Item);
        InvoiceDiscountValue := PurchHeader."Invoice Discount Value";
        // [WHEN] Run InsertInvLineFromRcptLine on Invoice
        PurchRcptLine.InsertInvLineFromRcptLine(PurchLine);
        // [THEN] Created Purchase Line in Invoice, where "Inv. Discount Amount" = "X"
        PurchLine.Find();
        Assert.AreEqual(ExpectedInvDiscAmount, PurchLine."Inv. Discount Amount", WrongInvDiscAmountErr);
        // [THEN] Invoice Header is not changed, "Invoice Discount Value" = "Y"
        PurchHeader.Find();
        PurchHeader.TestField("Invoice Discount Value", InvoiceDiscountValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchaseLineWithJobTaskLCY()
    var
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
    begin
        // [FEATURE] [Job]
        // [SCENARIO 123636] The Job Total Price and Job Total Price (LCY) fields are populated in the Purchase Order/Invoice line after you select the Job No, Job Task No (in local currency)
        LightInit();
        // [GIVEN] Update precision in General Ledger Setup
        LibraryERM.SetAmountRoundingPrecision(LibraryRandom.RandPrecision());
        // [GIVEN] Purchase Line in LCY, where "Job No." is set
        CreatePurchLineAndJobTask(PurchaseLine, JobTask);
        // [GIVEN] Purchase Line, where "Job Unit Price" = "P", "Job Unit Price (LCY)" = "P(LCY)", Quantity = "Q"

        // [WHEN] Enter "Job Task No." = JobTask."Job Task No." in Purchase Line
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");

        // [THEN] Purchase Line is updated
        // [THEN] "Job Total Price" = "P" * "Q"
        // [THEN] "Job Total Price (LCY)" = "P(LCY)" * "Q"
        VerifyJobTotalPrices(PurchaseLine, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchaseLineWithJobTaskFCY()
    var
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Job]
        // [SCENARIO 123636] The Job Total Price and Job Total Price (LCY) fields are populated in the Purchase Order/Invoice line after you select the Job No, Job Task No (in foreign currency)
        LightInit();
        // [GIVEN] Create currency with precisions
        CurrencyCode := LibraryERM.CreateCurrencyWithRounding();
        // [GIVEN] Update precision in General Ledger Setup
        LibraryERM.SetAmountRoundingPrecision(LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode) / 10);
        // [GIVEN] Purchase Line in FCY, where "Job No." is set
        CreatePurchLineWithCurrency(PurchaseLine, CurrencyCode);
        CreateJobTaskWithCurrency(JobTask, CurrencyCode);
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        // [GIVEN] Purchase Line, where "Job Unit Price" = "P", "Job Unit Price (LCY)" = "P(LCY)", Quantity = "Q"

        // [WHEN] Enter "Job Task No." = JobTask."Job Task No." in Purchase Line
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");

        // [THEN] Purchase Line is updated
        // [THEN] "Job Total Price" = "P" * "Q"
        // [THEN] "Job Total Price (LCY)" = "P(LCY)" * "Q"
        VerifyJobTotalPrices(PurchaseLine, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ItemChargeSetupHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyPurchAmountToAssignInItemChargeAssgmenAfterRevalidatingUnitCost()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase Order] [Item Charge]
        // [SCENARIO 364307] "Quantity to Assign" is taken to account in calculating "Amount to Assign" while Re-validating "Direct Unit Cost"
        Initialize();

        // [GIVEN] Purchase Order Line with Type = "Charge (Item)", Direct Cost = "D", Quantity = "X"
        // [GIVEN] Item Charge Assignment with "Quantity to Assign" = "X"
        // [GIVEN] Partially Receive Purchase Order
        CreateAndReceivePurchaseOrderChargeItem(PurchaseHeader, PurchaseLine);

        // [GIVEN] Set "Quantity to Assign" on Item Charge Assignment to "Y"
        Qty := LibraryRandom.RandInt(9);
        OpenItemChargeAssgnt(PurchaseLine, true, Qty);

        // [WHEN] Re-Validate Direct Cost on Purchase Line
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseLine.Validate("Direct Unit Cost");

        // [THEN] "Amount to Assign" on Item Charge Assignment is "D"* "Y" / "X"
        OpenItemChargeAssgnt(PurchaseLine, true, Qty * PurchaseLine."Direct Unit Cost");
    end;

    [Test]
    [HandlerFunctions('CopyPurchaseDocumentHandler')]
    [Scope('OnPrem')]
    procedure CopyPurchaseOrderFromPartialPostingPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        FromPurchaseOrderNo: Code[20];
    begin
        // [SCENARIO] Verifies Receive and Invoice fiels in document copied for posted Purchase Order.
        Initialize();
        // [GIVEN] Create Purchase Order with two lines
        // [GIVEN] In second line set Qty. to Receive = 0
        // [GIVEN] Release, Post (Receive) and Post (Invoice) purchase order
        FromPurchaseOrderNo := CreatePostPurchaseOrder();
        // [WHEN] Coping purchase order to new purchase order
        CreateCopyPurchaseOrder(PurchaseHeader, FromPurchaseOrderNo);
        // [THEN] Invoice and Receive fields must not get value from original document
        Assert.IsFalse(PurchaseHeader.Invoice, WrongValuePurchaseHeaderInvoiceErr);
        Assert.IsFalse(PurchaseHeader.Receive, WrongValuePurchaseHeaderReceiveErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscAmtAfterGetReceiptLinesAndEnabledCalcDiscSetup()
    var
        PurchaseHeader: Record "Purchase Header";
        NewPurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Discount] [Receipt Lines]
        // [SCENARIO 364443] Invoice Discount Amount remains after "Get Receipt Lines" from posted Purchase Order. "Purchases & Payables Setup"."Calc. Inv. Discount" = TRUE.
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Create and Ship Purchase Order with Invoice Discount Amount = "A"
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateItem());
        PurchaseLine.Validate("Inv. Discount Amount", Round(PurchaseLine."Line Amount" * LibraryRandom.RandDec(1, 2)));
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Run "Get Receipt Lines" from new Purchase Invoice
        InvoicePostedPurchaseOrder(NewPurchaseHeader, PurchaseHeader);

        // [THEN] Purchase Invoice Discount Amount = "A"
        NewPurchaseHeader.CalcFields("Invoice Discount Amount");
        Assert.AreEqual(
          PurchaseLine."Inv. Discount Amount",
          NewPurchaseHeader."Invoice Discount Amount",
          NewPurchaseHeader.FieldCaption("Invoice Discount Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscAmtAfterGetReceiptLinesAndDisabledCalcDiscSetup()
    var
        PurchaseHeader: Record "Purchase Header";
        NewPurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Discount] [Receipt Lines]
        // [SCENARIO 364443] Invoice Discount Amount remains after "Get Receipt Lines" from posted Purchase Order. "Purchases & Payables Setup"."Calc. Inv. Discount" = FALSE.
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(false);

        // [GIVEN] Create and Ship Purchase Order with Invoice Discount Amount = "A"
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateItem());
        PurchaseLine.Validate("Inv. Discount Amount", Round(PurchaseLine."Line Amount" * LibraryRandom.RandDec(1, 2)));
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Run "Get Receipt Lines" from new Purchase Invoice
        InvoicePostedPurchaseOrder(NewPurchaseHeader, PurchaseHeader);

        // [THEN] Purchase Invoice Discount Amount = "A"
        NewPurchaseHeader.CalcFields("Invoice Discount Amount");
        Assert.AreEqual(
          PurchaseLine."Inv. Discount Amount",
          NewPurchaseHeader."Invoice Discount Amount",
          NewPurchaseHeader.FieldCaption("Invoice Discount Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscAmtAfterGetReturnShipmentLinesAndEnabledCalcDiscSetup()
    var
        PurchaseHeader: Record "Purchase Header";
        NewPurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Discount] [Return Shipment Lines]
        // [SCENARIO 364443] Invoice Discount Amount remains after "Get Return Shipment Lines" from posted Purchase Return Order. "Purchases & Payables Setup"."Calc. Inv. Discount" = TRUE.
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Create and Ship Purchase Return Order with Invoice Discount Amount = "A"
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::"Return Order");
        PurchaseLine.Validate("Inv. Discount Amount", Round(PurchaseLine."Line Amount" * LibraryRandom.RandDec(1, 2)));
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Run "Get Retrun Shipment Lines" from new Purchase Credit Memo
        CrMemoPostedPurchaseReturnOrder(NewPurchaseHeader, PurchaseHeader);

        // [THEN] Purchase Credit Memo Discount Amount = "A"
        NewPurchaseHeader.CalcFields("Invoice Discount Amount");
        Assert.AreEqual(
          PurchaseLine."Inv. Discount Amount",
          NewPurchaseHeader."Invoice Discount Amount",
          NewPurchaseHeader.FieldCaption("Invoice Discount Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscAmtAfterGetReturnShipmentLinesAndDisabledCalcDiscSetup()
    var
        PurchaseHeader: Record "Purchase Header";
        NewPurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Discount] [Return Shipment Lines]
        // [SCENARIO 364443] Invoice Discount Amount remains after "Get Return Shipment Lines" from posted Purchase Return Order. "Purchases & Payables Setup"."Calc. Inv. Discount" = FALSE.
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(false);

        // [GIVEN] Create and Ship Purchase Return Order with Invoice Discount Amount = "A"
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::"Return Order");
        PurchaseLine.Validate("Inv. Discount Amount", Round(PurchaseLine."Line Amount" * LibraryRandom.RandDec(1, 2)));
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Run "Get Retrun Shipment Lines" from new Purchase Credit Memo
        CrMemoPostedPurchaseReturnOrder(NewPurchaseHeader, PurchaseHeader);

        // [THEN] Purchase Credit Memo Discount Amount = "A"
        NewPurchaseHeader.CalcFields("Invoice Discount Amount");
        Assert.AreEqual(
          PurchaseLine."Inv. Discount Amount",
          NewPurchaseHeader."Invoice Discount Amount",
          NewPurchaseHeader.FieldCaption("Invoice Discount Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoGLEntriesAfterZeroAmountPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 364561] Two G/L Entries with zero amount are created after posting of Purchase Invoice with zero amount
        Initialize();

        // [GIVEN] Vendor Posting Setup, where "Payables Account No." = "X", "Purch. Account No." = "Y"
        // [WHEN] Post Purchase Invoice with zero amount
        DocumentNo := CreatePostPurchaseInvoiceWithZeroAmount(PurchaseHeader, PurchaseLine);

        // [THEN] Two G/L Entries with zero Amount are posted to G/L accounts "X" and "Y"
        FindGLEntry(GLEntry, DocumentNo, GetPayablesAccountNo(PurchaseHeader."Buy-from Vendor No."));
        Assert.AreEqual(0, GLEntry.Amount, GLEntry.FieldCaption(Amount));

        FindGLEntry(
          GLEntry, DocumentNo,
          GetPurchAccountNo(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group"));
        Assert.AreEqual(0, GLEntry.Amount, GLEntry.FieldCaption(Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLRegInSyncWithVLEAfterZeroAmountPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLRegister: Record "G/L Register";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 364561] G/L Register should be in sync with Vendor Ledger Entry after posting of Purchase Invoice with zero amount
        Initialize();

        // [GIVEN] Create Purchase Invoice with zero amount
        // [WHEN] Post Purchase Invoice
        DocumentNo := CreatePostPurchaseInvoiceWithZeroAmount(PurchaseHeader, PurchaseLine);

        // [THEN] Vendor Ledger Entry No. in range ["From Entry No.",..,"To Entry No."] of G/L Register
        FindVendorLedgerEntry(VendorLedgerEntry, PurchaseHeader."Buy-from Vendor No.", DocumentNo);
        GLRegister.FindLast();
        Assert.IsTrue(
          VendorLedgerEntry."Entry No." in [GLRegister."From Entry No." .. GLRegister."To Entry No."],
          VendorLedgerEntry.FieldCaption("Entry No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure CheckVATAmountOnPurchInvoiceWithReverseVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineReverseCharge: Record "Purchase Line";
        PurchaseLineNormalVAT: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Reverse Charge VAT] [Purchase Invoice] [UT]
        // [SCENARIO 363018] Statistics of Purchase Invoice should have 0 VAT%, 0 VAT Amount and Amount Including VAT equals to Amount in case of Reverse Charge VAT

        // [GIVEN] General Ledger Setup having "Pmt. Disc. Excl. VAT" set as TRUE; Purchase Payables Setup having "Allow VAT Difference" set as TRUE
        AllowVATDiscount();

        // [GIVEN] Purchase Header for new Vendor with 2% VAT Base Discount
        CreatePurchHeaderWithVATBaseDisc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] Purchase Line for G/L Account with 19% Reverse Charge VAT and "Direct unit Cost" = 1000
        CreatePurchaseLineWithVATType(
          PurchaseLineReverseCharge, PurchaseHeader,
          PurchaseLineReverseCharge."VAT Calculation Type"::"Reverse Charge VAT");

        // [GIVEN] Purchase Line for G/L Account with 21% Normal VAT and "Direct unit Cost" = 1000
        CreatePurchaseLineWithVATType(
          PurchaseLineNormalVAT, PurchaseHeader, PurchaseLineNormalVAT."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] Posted Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] When calling CalcVATAmountLines procedure for Posted Purchase Invoice
        PurchInvHeader.Get(DocumentNo);
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        PurchInvLine.CalcVATAmountLines(PurchInvHeader, TempVATAmountLine);

        // [THEN] VAT Amount Line calculated on the Line with Reverse Charge VAT has "VAT %" = 0, "VAT Amount" = 0 and "Amount Including VAT" = "Amount"
        VerifyVATAmountLine(
          TempVATAmountLine, PurchaseLineReverseCharge."VAT Identifier", PurchaseLineReverseCharge."VAT Calculation Type",
          0, PurchaseLineReverseCharge.Amount);

        // [THEN] VAT Amount Line calculated on the Line with Normal VAT has "VAT %", "VAT Amount", "Amount Including VAT" as they are in Purchase Line
        VerifyVATAmountLine(
          TempVATAmountLine, PurchaseLineNormalVAT."VAT Identifier", PurchaseLineNormalVAT."VAT Calculation Type",
          PurchaseLineNormalVAT."Amount Including VAT" - PurchaseLineNormalVAT."Line Amount",
          PurchaseLineNormalVAT."Amount Including VAT");

        // TearDown
        VATPostingSetup.Get(PurchaseHeader."VAT Bus. Posting Group", PurchaseLineNormalVAT."VAT Prod. Posting Group");
        VATPostingSetup.Delete();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure CheckVATAmountOnPurchCrMemoWithReverseVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineReverseCharge: Record "Purchase Line";
        PurchaseLineNormalVAT: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Reverse Charge VAT] [Purchase Credit Memo] [UT]
        // [SCENARIO 363018] Statistics of Purchase Credit Memo should have 0 VAT%, 0 VAT Amount and Amount Including VAT equals to Amount in case of Reverse Charge VAT

        // [GIVEN] General Ledger Setup having "Pmt. Disc. Excl. VAT" set as TRUE; Purchase Payables Setup having "Allow VAT Difference" set as TRUE
        AllowVATDiscount();

        // [GIVEN] Purchase Header for new Vendor with 2% VAT Base Discount
        CreatePurchHeaderWithVATBaseDisc(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        // [GIVEN] Purchase Line for G/L Account with 19% Reverse Charge VAT and "Direct unit Cost" = 1000
        CreatePurchaseLineWithVATType(
          PurchaseLineReverseCharge, PurchaseHeader,
          PurchaseLineReverseCharge."VAT Calculation Type"::"Reverse Charge VAT");

        // [GIVEN] Purchase Line for G/L Account with 21% Normal VAT and "Direct unit Cost" = 1000
        CreatePurchaseLineWithVATType(
          PurchaseLineNormalVAT, PurchaseHeader, PurchaseLineNormalVAT."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] Posted Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] When calling CalcVATAmountLines procedure for Posted Purchase Invoice
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.FindFirst();
        PurchCrMemoLine.CalcVATAmountLines(PurchCrMemoHdr, TempVATAmountLine);

        // [THEN] VAT Amount Line calculated on the Line with Reverse Charge VAT has "VAT %" = 0, "VAT Amount" = 0 and "Amount Including VAT" = "Amount"
        VerifyVATAmountLine(
          TempVATAmountLine, PurchaseLineReverseCharge."VAT Identifier", PurchaseLineReverseCharge."VAT Calculation Type",
          0, PurchaseLineReverseCharge.Amount);

        // [THEN] VAT Amount Line calculated on the Line with Normal VAT has "VAT %", "VAT Amount", "Amount Including VAT" as they are in Purchase Line
        VerifyVATAmountLine(
          TempVATAmountLine, PurchaseLineNormalVAT."VAT Identifier", PurchaseLineNormalVAT."VAT Calculation Type",
          PurchaseLineNormalVAT."Amount Including VAT" - PurchaseLineNormalVAT."Line Amount",
          PurchaseLineNormalVAT."Amount Including VAT");

        // TearDown
        VATPostingSetup.Get(PurchaseHeader."VAT Bus. Posting Group", PurchaseLineNormalVAT."VAT Prod. Posting Group");
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchInvoiceFromReceiptLineWithManualDiscount()
    var
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchHeader: Record "Purchase Header";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        InvoiceDiscountValue: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice Discount]
        // [SCENARIO 158032] Invoice Discount Amount is not recalculated on Purchase Line created from Posted Receipt Line if "Purchases & Payables Setup"."Calc. Inv. Discount" set to FALSE

        // [GIVEN] Create purchase order with Customer with Discount percent, set "Invoice Discount Value" to "Y"
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, CreateVendorInvDiscount());
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, CreateItem(), LibraryRandom.RandIntInRange(5, 10));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);

        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(
          LibraryRandom.RandDecInRange(10, 20, 2), PurchHeader);
        InvoiceDiscountValue := PurchHeader."Invoice Discount Value";

        // [GIVEN] Receive Order
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
        FindPurchRcptLine(PurchRcptLine, PurchHeader."No.");

        // [GIVEN] Create Purchase Invoice
        Clear(PurchHeader);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, PurchRcptLine."Buy-from Vendor No.");
        CreateSimplePurchLine(PurchLine, PurchHeader, PurchLine.Type::Item);

        // [WHEN] Run "Get Receipt Lines" and select Posted Receipt Line
        PurchRcptLine.InsertInvLineFromRcptLine(PurchLine);

        // [THEN] Invoice "Invoice Discount Value" = "Y"
        PurchHeader.Find();
        PurchHeader.CalcFields("Invoice Discount Amount");
        PurchHeader.TestField("Invoice Discount Amount", InvoiceDiscountValue);
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceForItemChargeWithVATDifferencePostValuesPricesInclVAT()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        ValueEntry: Record "Value Entry";
        PurchaseInvoiceNo: Code[20];
        MaxVATDifference: Decimal;
        AmountToAssign: Decimal;
    begin
        // [FEATURE] [Statistics] [Item Charge]
        // [SCENARIO 378379] Create Purch. Invoice with Item Charge Assignment (Prices Incl. VAT = TRUE), change VAT difference and post
        Initialize();

        // [GIVEN] "Purchases & Payables Setup"."Allow VAT Difference" = TRUE
        // [GIVEN] "General Ledger Setup"."Max. VAT Difference Allowed" = "D"
        MaxVATDifference := EnableVATDiffAmount();
        LibraryVariableStorage.Enqueue(MaxVATDifference);

        // [GIVEN] Purchase Invoice ("Prices Incl. VAT" = TRUE) with Item Charge of amount "A" assigned to Posted Purchase Order
        // [GIVEN] "VAT Amount" is increased by "D" on "Purchase Statistics" page
        // [WHEN] Post Purchase Invoice
        PostPurchaseInvoiceWithItemCharge(PurchaseInvoiceNo, AmountToAssign, true);

        // [THEN] PurchInvLine.Amount = "A-D"
        PurchInvLine.SetRange("Document No.", PurchaseInvoiceNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Amount, AmountToAssign - MaxVATDifference);

        // [THEN] ValueEntry."Cost Amount (Actual)" = "A-D"
        ValueEntry.SetRange("Document No.", PurchaseInvoiceNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Actual)", AmountToAssign - MaxVATDifference);
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceForItemChargeWithVATDifferencePostValuesPricesWoVAT()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        ValueEntry: Record "Value Entry";
        PurchaseInvoiceNo: Code[20];
        MaxVATDifference: Decimal;
        AmountToAssign: Decimal;
    begin
        // [FEATURE] [Statistics] [Item Charge]
        // [SCENARIO 378379] Create Purch. Invoice with Item Charge Assignment (Prices Incl. VAT = FALSE), change VAT difference and post
        Initialize();

        // [GIVEN] "Purchases & Payables Setup"."Allow VAT Difference" = TRUE
        // [GIVEN] "General Ledger Setup"."Max. VAT Difference Allowed" = "D"
        MaxVATDifference := EnableVATDiffAmount();
        LibraryVariableStorage.Enqueue(MaxVATDifference);

        // [GIVEN] Purchase Invoice ("Prices Incl. VAT" = FALSE) with Item Charge of amount "A" assigned to Posted Purchase Order
        // [GIVEN] "VAT Amount" is increased by "D" on "Purchase Statistics" page
        // [WHEN] Post Purchase Invoice
        PostPurchaseInvoiceWithItemCharge(PurchaseInvoiceNo, AmountToAssign, false);

        // [THEN] PurchInvLine.Amount = "A"
        PurchInvLine.SetRange("Document No.", PurchaseInvoiceNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Amount, AmountToAssign);

        // [THEN] ValueEntry."Cost Amount (Actual)" = "A"
        ValueEntry.SetRange("Document No.", PurchaseInvoiceNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Actual)", AmountToAssign);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GenBusinessPostingGroupInLinesUpdated()
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 164950] Field "Gen. Bus. Posting Group" is updated in lines when user changes it in the document header and Gen. Bus. Posting Group has "Auto Insert Default" = False

        // [GIVEN] Gen. Bus. Posting Group "B" with "Auto Insert Default" = False,
        Initialize();
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        GenBusPostingGroup."Auto Insert Default" := false;
        GenBusPostingGroup.Modify();
        // [GIVEN] Vendor with  "Gen. Bus. Posting Group" = "X",
        // [GIVEN] Purchase Order for vendor with one line
        CreateOrderCheckVATSetup(PurchaseHeader, PurchaseLine);

        // [WHEN] Validate field "Gen. Bus. Posting Group" = "B" in Purchase Order header
        PurchaseHeader.Validate("Gen. Bus. Posting Group", GenBusPostingGroup.Code);

        // [THEN] Field "Gen. Bus. Posting Group" in Purchase Order line is "B"
        PurchaseLine.Find();
        PurchaseLine.TestField("Gen. Bus. Posting Group", GenBusPostingGroup.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure GenBusinessPostingGroupInLinesNotUpdated()
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OldGenBusPostingGroup: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 164950] Field "Gen. Bus. Posting Group" is not updated in lines when user changes it in the document header and chooses "No" in Confirm dialog

        // [GIVEN] Gen. Bus. Posting Group "B" with "Auto Insert Default" = False,
        Initialize();
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        GenBusPostingGroup."Auto Insert Default" := false;
        GenBusPostingGroup.Modify();
        // [GIVEN] Vendor with  Gen. Bus. Posting Group = "X",
        // [GIVEN] Purchase Order for vendor with one line
        CreateOrderCheckVATSetup(PurchaseHeader, PurchaseLine);
        OldGenBusPostingGroup := PurchaseLine."Gen. Bus. Posting Group";
        Commit();

        // [WHEN] Validate field "Gen. Bus. Posting Group" = "B" in Purchase Order header
        asserterror PurchaseHeader.Validate("Gen. Bus. Posting Group", GenBusPostingGroup.Code);

        // [THEN] Field "Gen. Bus. Posting Group" in Purchase Order is not changed because of error message
        Assert.ExpectedError(StrSubstNo(RecreatePurchaseLinesCancelErr, PurchaseLine.FieldCaption("Gen. Bus. Posting Group")));
        PurchaseLine.Find();
        PurchaseLine.TestField("Gen. Bus. Posting Group", OldGenBusPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceDescriptionLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocNo: Code[20];
        Description: Text[100];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 378530] Purchase Invoice description line with Type = "G/L Account"
        Initialize();

        // [GIVEN] Purchase Order with two lines:
        // [GIVEN] Line1: Type = "G/L Account", No="8640", Description = "Miscellaneous"
        // [GIVEN] Line2: Type = "G/L Account", No="", Description = "Description Line"
        CreatePurchDocWithGLDescriptionLine(PurchaseHeader, Description, PurchaseHeader."Document Type"::Order);

        // [WHEN] Post Purchase Order (Invoice).
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Description line has been posted: Type = "", No="", Description = "Description Line"
        VerifyPurchInvDescriptionLineExists(PostedDocNo, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchRcptDescriptionLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocNo: Code[20];
        Description: Text[100];
    begin
        // [FEATURE] [Receipt]
        // [SCENARIO 378530] Purchase Receipt description line with Type = "G/L Account"
        Initialize();

        // [GIVEN] Purchase Order with two lines:
        // [GIVEN] Line1: Type = "G/L Account", No="8640", Description = "Miscellaneous"
        // [GIVEN] Line2: Type = "G/L Account", No="", Description = "Description Line"
        CreatePurchDocWithGLDescriptionLine(PurchaseHeader, Description, PurchaseHeader."Document Type"::Order);

        // [WHEN] Post Purchase Order (Receive).
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Description line has been posted: Type = "", No="", Description = "Description Line"
        VerifyPurchRcptDescriptionLineExists(PostedDocNo, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchCrMemoDescriptionLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocNo: Code[20];
        Description: Text[100];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 378530] Purchase Credit Memo description line with Type = "G/L Account"
        Initialize();

        // [GIVEN] Purchase Return Order with two lines:
        // [GIVEN] Line1: Type = "G/L Account", No="8640", Description = "Miscellaneous"
        // [GIVEN] Line2: Type = "G/L Account", No="", Description = "Description Line"
        CreatePurchDocWithGLDescriptionLine(PurchaseHeader, Description, PurchaseHeader."Document Type"::"Return Order");

        // [WHEN] Post Purchase Return Order (Invoice).
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Description line has been posted: Type = "", No="", Description = "Description Line"
        VerifyPurchCrMemoDescriptionLineExists(PostedDocNo, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchRetShptDescriptionLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocNo: Code[20];
        Description: Text[100];
    begin
        // [FEATURE] [Return Shipment]
        // [SCENARIO 378530] Purchase Return Shipment description line with Type = "G/L Account"
        Initialize();

        // [GIVEN] Purchase Return Order with two lines:
        // [GIVEN] Line1: Type = "G/L Account", No="8640", Description = "Miscellaneous"
        // [GIVEN] Line2: Type = "G/L Account", No="", Description = "Description Line"
        CreatePurchDocWithGLDescriptionLine(PurchaseHeader, Description, PurchaseHeader."Document Type"::"Return Order");

        // [WHEN] Post Purchase Return Order (Receive).
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Description line has been posted: Type = "", No="", Description = "Description Line"
        VerifyPurchRetShptDescriptionLineExists(PostedDocNo, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchRcptLine_InitFromPurchLine_UT()
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [FEATURE] [UT] [Receipt]
        // [SCENARIO] TAB121 "Purch. Rcpt. Line".InitFromPurchLine() correctly inits PurchRcptLine from PurchaseLine
        PurchRcptHeader.Init();
        PurchRcptHeader."Posting Date" := LibraryRandom.RandDate(100);
        PurchRcptHeader."No." := LibraryUtility.GenerateGUID();

        InitPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Order);

        PurchRcptLine.InitFromPurchLine(PurchRcptHeader, PurchaseLine);
        Assert.AreEqual(PurchRcptHeader."Posting Date", PurchRcptLine."Posting Date", PurchRcptLine.FieldCaption("Posting Date"));
        Assert.AreEqual(PurchRcptHeader."No.", PurchRcptLine."Document No.", PurchRcptLine.FieldCaption("Document No."));
        Assert.AreEqual(PurchaseLine."Qty. to Receive", PurchRcptLine.Quantity, PurchRcptLine.FieldCaption(Quantity));
        Assert.AreEqual(PurchaseLine."Qty. to Receive (Base)", PurchRcptLine."Quantity (Base)", PurchRcptLine.FieldCaption("Quantity (Base)"));
        Assert.AreEqual(PurchaseLine."Qty. to Invoice", PurchRcptLine."Quantity Invoiced", PurchRcptLine.FieldCaption("Quantity Invoiced"));
        Assert.AreEqual(PurchaseLine."Qty. to Invoice (Base)", PurchRcptLine."Qty. Invoiced (Base)", PurchRcptLine.FieldCaption("Qty. Invoiced (Base)"));
        Assert.AreEqual(
          PurchaseLine."Qty. to Receive" - PurchaseLine."Qty. to Invoice",
          PurchRcptLine."Qty. Rcd. Not Invoiced", PurchRcptLine.FieldCaption("Qty. Rcd. Not Invoiced"));
        Assert.AreEqual(PurchaseLine."Document No.", PurchRcptLine."Order No.", PurchRcptLine.FieldCaption("Order No."));
        Assert.AreEqual(PurchaseLine."Line No.", PurchRcptLine."Order Line No.", PurchRcptLine.FieldCaption("Order Line No."));
        Assert.AreEqual(PurchRcptLine.Type::" ", PurchRcptLine.Type, PurchRcptLine.FieldCaption(Type));
        Assert.AreEqual(PurchaseLine."No.", PurchRcptLine."No.", PurchRcptLine.FieldCaption("No."));
        Assert.AreEqual(PurchaseLine.Description, PurchRcptLine.Description, PurchRcptLine.FieldCaption(Description));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvLine_InitFromPurchLine_UT()
    var
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // [FEATURE] [UT] [Invoice]
        // [SCENARIO] TAB123 "Purch. Inv. Line".InitFromPurchLine() correctly inits PurchInvLine from PurchaseLine
        PurchInvHeader.Init();
        PurchInvHeader."Posting Date" := LibraryRandom.RandDate(100);
        PurchInvHeader."No." := LibraryUtility.GenerateGUID();

        InitPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Order);

        PurchInvLine.InitFromPurchLine(PurchInvHeader, PurchaseLine);
        Assert.AreEqual(PurchInvHeader."Posting Date", PurchInvLine."Posting Date", PurchInvLine.FieldCaption("Posting Date"));
        Assert.AreEqual(PurchInvHeader."No.", PurchInvLine."Document No.", PurchInvLine.FieldCaption("Document No."));
        Assert.AreEqual(PurchaseLine."Qty. to Invoice", PurchInvLine.Quantity, PurchInvLine.FieldCaption(Quantity));
        Assert.AreEqual(PurchaseLine."Qty. to Invoice (Base)", PurchInvLine."Quantity (Base)", PurchInvLine.FieldCaption("Quantity (Base)"));
        Assert.AreEqual(PurchInvLine.Type::" ", PurchInvLine.Type, PurchInvLine.FieldCaption(Type));
        Assert.AreEqual(PurchaseLine."No.", PurchInvLine."No.", PurchInvLine.FieldCaption("No."));
        Assert.AreEqual(PurchaseLine.Description, PurchInvLine.Description, PurchInvLine.FieldCaption(Description));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoLine_InitFromPurchLine_UT()
    var
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        // [FEATURE] [UT] [Credit Memo]
        // [SCENARIO] TAB125 "Purch. Cr. Memo Line".InitFromPurchLine() correctly inits PurchCrMemoLine from PurchaseLine
        PurchCrMemoHdr.Init();
        PurchCrMemoHdr."Posting Date" := LibraryRandom.RandDate(100);
        PurchCrMemoHdr."No." := LibraryUtility.GenerateGUID();

        InitPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::"Return Order");

        PurchCrMemoLine.InitFromPurchLine(PurchCrMemoHdr, PurchaseLine);
        Assert.AreEqual(PurchCrMemoHdr."Posting Date", PurchCrMemoLine."Posting Date", PurchCrMemoLine.FieldCaption("Posting Date"));
        Assert.AreEqual(PurchCrMemoHdr."No.", PurchCrMemoLine."Document No.", PurchCrMemoLine.FieldCaption("Document No."));
        Assert.AreEqual(PurchaseLine."Qty. to Invoice", PurchCrMemoLine.Quantity, PurchCrMemoLine.FieldCaption(Quantity));
        Assert.AreEqual(PurchaseLine."Qty. to Invoice (Base)", PurchCrMemoLine."Quantity (Base)", PurchCrMemoLine.FieldCaption("Quantity (Base)"));
        Assert.AreEqual(PurchCrMemoLine.Type::" ", PurchCrMemoLine.Type, PurchCrMemoLine.FieldCaption(Type));
        Assert.AreEqual(PurchaseLine."No.", PurchCrMemoLine."No.", PurchCrMemoLine.FieldCaption("No."));
        Assert.AreEqual(PurchaseLine.Description, PurchCrMemoLine.Description, PurchCrMemoLine.FieldCaption(Description));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnShipmentLine_InitFromPurchLine_UT()
    var
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // [FEATURE] [UT] [Receipt]
        // [SCENARIO] TAB6651 "Return Shipment Line".InitFromPurchLine() correctly inits ReturnShipmentLine from PurchaseLine
        ReturnShipmentHeader.Init();
        ReturnShipmentHeader."Posting Date" := LibraryRandom.RandDate(100);
        ReturnShipmentHeader."No." := LibraryUtility.GenerateGUID();

        InitPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::"Return Order");

        ReturnShipmentLine.InitFromPurchLine(ReturnShipmentHeader, PurchaseLine);
        Assert.AreEqual(ReturnShipmentHeader."Posting Date", ReturnShipmentLine."Posting Date", ReturnShipmentLine.FieldCaption("Posting Date"));
        Assert.AreEqual(ReturnShipmentHeader."No.", ReturnShipmentLine."Document No.", ReturnShipmentLine.FieldCaption("Document No."));
        Assert.AreEqual(PurchaseLine."Return Qty. to Ship", ReturnShipmentLine.Quantity, ReturnShipmentLine.FieldCaption(Quantity));
        Assert.AreEqual(PurchaseLine."Return Qty. to Ship (Base)", ReturnShipmentLine."Quantity (Base)", ReturnShipmentLine.FieldCaption("Quantity (Base)"));
        Assert.AreEqual(PurchaseLine."Qty. to Invoice", ReturnShipmentLine."Quantity Invoiced", ReturnShipmentLine.FieldCaption("Quantity Invoiced"));
        Assert.AreEqual(PurchaseLine."Qty. to Invoice (Base)", ReturnShipmentLine."Qty. Invoiced (Base)", ReturnShipmentLine.FieldCaption("Qty. Invoiced (Base)"));
        Assert.AreEqual(
          PurchaseLine."Return Qty. to Ship" - PurchaseLine."Qty. to Invoice",
          ReturnShipmentLine."Return Qty. Shipped Not Invd.", ReturnShipmentLine.FieldCaption("Return Qty. Shipped Not Invd."));
        Assert.AreEqual(PurchaseLine."Document No.", ReturnShipmentLine."Return Order No.", ReturnShipmentLine.FieldCaption("Return Order No."));
        Assert.AreEqual(PurchaseLine."Line No.", ReturnShipmentLine."Return Order Line No.", ReturnShipmentLine.FieldCaption("Return Order Line No."));
        Assert.AreEqual(ReturnShipmentLine.Type::" ", ReturnShipmentLine.Type, ReturnShipmentLine.FieldCaption(Type));
        Assert.AreEqual(PurchaseLine."No.", ReturnShipmentLine."No.", ReturnShipmentLine.FieldCaption("No."));
        Assert.AreEqual(PurchaseLine.Description, ReturnShipmentLine.Description, ReturnShipmentLine.FieldCaption(Description));
    end;

    [Test]
    [HandlerFunctions('ExactMessageHandler')]
    [Scope('OnPrem')]
    procedure PostedDocToPrintMessageRaisedWhenDeletePurchInvithNoInPostedInvoiceNos()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchHeader: Record "Purchase Header";
        GLSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 379123] Message raised when delete Purchase Invoice with "Posted Invoice Nos." = "Invoice Nos." in Purchase Setup

        Initialize();
        // [GIVEN] "Posted Invoice Nos." = "Invoice Nos." in Purchase Setup
        SetPostedInvoiceNosEqualInvoiceNosInPurchSetup(PurchasesPayablesSetup);

        // [GIVEN] Purchase Invoice
        GLSetup.Get();
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, '');
        if GLSetup."Journal Templ. Name Mandatory" then
            PurchHeader.Validate("Posting No.", LibraryUtility.GenerateGUID())
        else begin
            PurchHeader.Validate("No. Series", PurchasesPayablesSetup."Posted Invoice Nos.");
            PurchHeader.Validate("Posting No. Series", PurchasesPayablesSetup."Invoice Nos.");
        end;
        PurchHeader.Modify(true);
        LibraryVariableStorage.Enqueue(PostedDocsToPrintCreatedMsg);

        // [WHEN] Delete Purchase Invoice
        PurchHeader.Delete(true);

        // [THEN] Message "One or more documents have been posted during deletion which you can print" was raised
        // Verification done in ExactMessageHandler
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderEquallyItemChargeAssignment()
    var
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        AmountToAssign: Decimal;
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Item Charge]
        // [SCENARIO 379418] Equally Item Charge Assignment line Amount to Assign calculation
        Initialize();

        // [GIVEN] Purchase Order with 3 item lines and equally assigned item charge line (Suggest Choice = 1)
        // [GIVEN] AmountToAssign = "A", QtyToAssign = "Q"
        PurchaseOrderItemChargeAssignment(PurchaseLine, AmountToAssign, QtyToAssign, 1);

        // [WHEN] Reassign all qty "Q" to one line
        AssignQtyToOneLine(ItemChargeAssignmentPurch, PurchaseLine, QtyToAssign);

        // [THEN] Amount to Assign is equal "A"
        ItemChargeAssignmentPurch.CalcSums("Amount to Assign");
        Assert.AreEqual(AmountToAssign, ItemChargeAssignmentPurch."Amount to Assign", AmountToAssignErr);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentHandler,ItemChargeAssignMenuHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderAmountItemChargeAssignment()
    var
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        AmountToAssign: Decimal;
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Item Charge]
        // [SCENARIO 379418] Item Charge Assignment by amount line Amount to Assign calculation
        Initialize();

        // [GIVEN] Purchase Order with 3 item lines and assigned item charge line by amount (Suggest Choice = 2)
        // [GIVEN] AmountToAssign = "A", QtyToAssign = "Q"
        PurchaseOrderItemChargeAssignment(PurchaseLine, AmountToAssign, QtyToAssign, 2);

        // [WHEN] Reassign all qty "Q" to one line
        AssignQtyToOneLine(ItemChargeAssignmentPurch, PurchaseLine, QtyToAssign);

        // [THEN] Amount to Assign is equal "A"
        ItemChargeAssignmentPurch.CalcSums("Amount to Assign");
        Assert.AreEqual(AmountToAssign, ItemChargeAssignmentPurch."Amount to Assign", AmountToAssignErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacePurchLineStandardTextWithExtText()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        StandardText: Record "Standard Text";
        ExtendedText: Text;
    begin
        // [FEATURE] [Standard Text] [Extended Text]
        // [SCENARIO 380579] Replacing of Purchase Line's Standard Text Code updates attached Extended Text lines
        Initialize();

        // [GIVEN] Standard Text (Code = "ST1", Description = "SD1") with Extended Text "ET1".
        // [GIVEN] Standard Text (Code = "ST2", Description = "SD2") with Extended Text "ET2".
        // [GIVEN] Purchase Order with line: "Type" = "", "No." = "ST1"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(PurchaseLine, PurchaseHeader);
        ValidatePurchaseLineStandardCode(PurchaseLine, LibrarySales.CreateStandardTextWithExtendedText(StandardText, ExtendedText));

        // [WHEN] Validate Purchase Line "No." = "ST2"
        ValidatePurchaseLineStandardCode(PurchaseLine, LibrarySales.CreateStandardTextWithExtendedText(StandardText, ExtendedText));

        // [THEN] There are two Purchase lines:
        // [THEN] Line1: Type = "", "No." = "ST2", Description = "SD2"
        // [THEN] Line2: Type = "", "No." = "", Description = "ET2"
        VerifyPurchaseLineCount(PurchaseHeader, 2);
        VerifyPurchaseLineDescription(PurchaseLine, PurchaseLine.Type::" ", StandardText.Code, StandardText.Description);
        PurchaseLine.Next();
        VerifyPurchaseLineDescription(PurchaseLine, PurchaseLine.Type::" ", '', ExtendedText);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithQtyPerUoMVerifyJobLedger()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        DocumentNo: Code[20];
        QtyPerUoM: Decimal;
    begin
        // [FEATURE] [Job] [Unit of Measure]
        // [SCENARIO 221458] Post Purchase Order with job and alternative unit of measure

        Initialize();

        // [GIVEN] Create Item with item unit of measure
        CreateItemWithUnitPrice(Item);
        QtyPerUoM := LibraryRandom.RandIntInRange(2, 100);

        // [GIVEN] Alternative item's "Unit of Measure" = "U" with alternative "Qty. per Unit of Measure" = 5
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPerUoM);

        // [GIVEN] Purchase Order with "Unit of Measure" = "U"  where "Unit Cost" = 100
        CreatePurchaseOrderWithJob(PurchaseHeader, PurchaseLine, Item."No.", ItemUnitOfMeasure.Code);

        // [WHEN] Post Purchase Order
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "Job Ledger Entry" is posted with "Base Unit of Measure" where "Unit Cost" = 20
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, PurchaseLine."Job No.");
        JobLedgerEntry.TestField("Unit Cost", PurchaseLine."Unit Cost" / QtyPerUoM);
        JobLedgerEntry.TestField("Total Cost (LCY)", CalculateTotalCostLCY(PurchaseLine));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderForWhseLocationAndItemChargeWithPrepayment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        WarehouseEmployee: Record "Warehouse Employee";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Prepayment] [Warehouse Receipt]
        // [SCENARIO 382050] Posting warehouse receipt for prepaid Purchase Order with item charge
        Initialize();

        // [GIVEN] Purchase Order for Warehouse Location where second line is Item Charge with Amount of 10
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineCharge, PurchaseHeader, PurchaseLineCharge.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        PurchaseLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLineCharge.Validate("Gen. Prod. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchaseLineCharge.Validate("VAT Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        PurchaseLineCharge.Modify(true);
        LibraryERM.UpdatePurchPrepmtAccountVATGroup(
            PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        LocationCode := ModifyWarehouseLocation(true);

        // [GIVEN] Prepayment is posted for Purchase Order
        ModifyFullPrepmtAndLocationOnPurchLine(PurchaseLine, LocationCode);
        ModifyFullPrepmtAndLocationOnPurchLine(PurchaseLineCharge, LocationCode);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Modify();

        // [GIVEN] Warehouse receipt for released Purchase Order is created
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, PurchaseLine."Location Code", false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [WHEN] Post Warehouse Document as Receive.
        ReceiveWarehouseDocument(PurchaseHeader."No.", PurchaseLine."Line No.");

        // [THEN] "Prepmt Amt to Deduct" is updated for Item Charge line as 10
        PurchaseLineCharge.Find();
        PurchaseLineCharge.TestField("Prepmt Amt to Deduct", PurchaseLineCharge.Amount);

        // Tear Down
        ModifyWarehouseLocation(false);
        WarehouseEmployee.Get(UserId, PurchaseLine."Location Code");
        WarehouseEmployee.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLine_FindRecordByDescription_GLAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        No: Code[20];
        Description: Text[100];
    begin
        // [FEATURE] [Find Record By Description] [G/L Account]
        // [SCENARIO 203978] Purchase Line's G/L Account validation can be done using "Description" field
        // [SCENARIO 252065]
        Initialize();
        No := 'GLACC_TEST_GLACC';
        Description := 'Description(Test)Description';

        // [GIVEN] G/L Account "GLACC" with "Name" = "(Desc)"
        MockGLAccountWithNoAndDescription(No, Description);

        // [GIVEN] Purchase order line, "Type" = "G/L Account"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");

        // [WHEN] Validate purchase line's "Description" = "glacc"/"(desc)"/"glac"/"(des"/"acc"/"esc"/"xesc)"
        // [THEN] Purchase line's: "No." = "GLACC", "Description" = "(Desc)"
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'glacc_test_glacc', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'description_(test)_description', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'glacc_test', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'description(test)', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'test_glacc', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, '(test)description', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'discriptyon(tezt)discriptyon', No, Description);

        // Tear down
        GLAccount.Get(No);
        GLAccount.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLine_FindRecordByDescription_Item()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        No: Code[20];
        Description: Text[100];
    begin
        // [FEATURE] [Find Record By Description] [Item]
        // [SCENARIO 203978] Purchase Line's Item validation can be done using "Description" field
        // [SCENARIO 252065]
        Initialize();
        No := 'ITEM_TEST_ITEM';
        Description := 'Description(Test)Description';

        // [GIVEN] Item "ITEM" with "Description" = "(Desc)"
        MockItemWithNoAndDescription(No, Description);
        // [GIVEN] Purchase order line, "Type" = "Item"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);

        // [WHEN] Validate purchase line's "Description" = "glacc"/"(desc)"/"glac"/"(des"/"acc"/"esc"/"xesc)"
        // [THEN] Purchase line's: "No." = "ITEM", "Description" = "(Desc)"
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'item_test_item', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'Description(Test)Description', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'item_test', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'description(test)', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'test_item', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, '(test)description', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'discriptyon(tezt)discriptyon', No, Description);

        // Tear down
        Item.Get(No);
        Item.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLine_FindRecordByDescription_ItemCharge()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
        No: Code[20];
        Description: Text[100];
    begin
        // [FEATURE] [Find Record By Description] [Item Charge]
        // [SCENARIO 203978] Purchase Line's Item Charge validation can be done using "Description" field
        // [SCENARIO 252065]
        Initialize();
        No := 'ITEMCH_TEST_ITEMCH';
        Description := 'Description(Test)Description';

        // [GIVEN] Item Charge "ITEMCHARGE" with "Description" = "(Desc)"
        MockItemChargeWithNoAndDescription(No, Description);
        // [GIVEN] Purchase order line, "Type" = "Charge (Item)"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::"Charge (Item)");

        // [WHEN] Validate purchase line's "Description" = "itemcharge"/"desc"/"itemch"/"des"/"charge"/"esc"/"xesc"
        // [THEN] Purchase line's: "No." = "ITEMCHARGE", "Description" = "(Desc)"
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'itemch_test_itemch', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'Description(Test)Description', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'itemch_test', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'description(test)', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'test_itemch', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, '(test)description', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'discriptyon(tezt)discriptyon', No, Description);

        // Tear down
        ItemCharge.Get(No);
        ItemCharge.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLine_FindRecordByDescription_FixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FixedAsset: Record "Fixed Asset";
        No: Code[20];
        Description: Text[100];
    begin
        // [FEATURE] [Find Record By Description] [Fixed Asset]
        // [SCENARIO 203978] Purchase Line's Fixed Asset validation can be done using "Description" field
        // [SCENARIO 252065]
        Initialize();
        No := 'FA_TEST_FA';
        Description := 'Description(Test)Description';

        // [GIVEN] Fixed Asset "FIXEDASSET" with "Description" = "(Desc)"
        MockFAWithNoAndDescription(No, Description);
        // [GIVEN] Purchase order line, "Type" = "Fixed Asset"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::"Fixed Asset");

        // [WHEN] Validate purchase line's "Description" = "fixedasset"/"desc"/"fixed"/"des"/"asset"/"esc"/"xesc"
        // [THEN] Purchase line's: "No." = "FIXEDASSET", "Description" = "(Desc)"
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'fa_test_fa', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'Description(Test)Description', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'fa_test', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'description(test)', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'test_fa', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, '(test)description', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'discriptyon(tezt)discriptyon', No, Description);

        // Tear down
        FixedAsset.Get(No);
        FixedAsset.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLine_FindRecordByDescription_StandardText_Negative()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        StandardText: Record "Standard Text";
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By Description] [Standard Text]
        // [SCENARIO 222522] Purchase Line's Standard Text validation can not be done using "Description" field.
        // [SCENARIO 222522] Typed value remains in the "Description" field with empty "Type", "No." values.
        // [SCENARIO 252065]
        Initialize();
        No := 'STDTEXT_TEST_STDTEXT';
        Description := 'Description(Test)Description';

        // [GIVEN] Standard Text "STDTEXT" with "Description" = "(Desc)"
        MockStandardText(No, Description);
        // [GIVEN] Purchase order line, "Type" = ""
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(PurchaseLine, PurchaseHeader);

        // [WHEN] Validate purchase line's "Description" = "stdtext"/"desc"/"stdte"/"des"/"tdtext"/"esc"/"xesc"
        // [THEN] Purchase line's: "No." = "", "Description" = "stdtext"/"desc"/"stdte"/"des"/"tdtext"/"esc"/"xesc"
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'stdtext_test_stdtext', '', 'stdtext_test_stdtext');
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'description(test)des', '', 'description(test)des');
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'stdtext_test', '', 'stdtext_test');
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'test_stdtext', '', 'test_stdtext');
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, '(test)description', '', '(test)description');
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'tdtext_test_stdtex', '', 'tdtext_test_stdtex');
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'ription(test)descrip', '', 'ription(test)descrip');

        // Tear down
        StandardText.Get(No);
        StandardText.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLine_FindRecordByNo_GLAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        No: Code[20];
        Description: Text[100];
    begin
        // [FEATURE] [Find Record By No] [G/L Account]
        // [SCENARIO 215821] Purchase Line's G/L Account validation can be done using partial-typed "No." value
        // [SCENARIO 252065]
        Initialize();
        No := 'GLACC_TEST_GLACC';
        Description := 'Description(Test)Description';

        // [GIVEN] G/L Account "GLACC" with "Name" = "(Desc)"
        MockGLAccountWithNoAndDescription(No, Description);
        // [GIVEN] Purchase order line, "Type" = "G/L Account"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");

        // [WHEN] Validate purchase line's "No." = "glacc"/"desc"/"glac"/"des"/"acc"/"esc"/"xesc"
        // [THEN] Purchase line's: "No." = "GLACC", "Description" = "(Desc)"
        VerifyPurchaseLineFindRecordByNo(PurchaseLine, 'glacc_test_glacc', No, Description);

        // Tear down
        GLAccount.Get(No);
        GLAccount.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLine_FindRecordByNo_Item()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        No: Code[20];
        Description: Text[100];
    begin
        // [FEATURE] [Find Record By No] [Item]
        // [SCENARIO 215821] Purchase Line's Item validation can be done using partial-typed "No." value
        // [SCENARIO 252065]
        Initialize();
        No := 'ITEM_TEST_ITEM';
        Description := 'Description(Test)Description';

        // [GIVEN] Item "ITEM" with "Description" = "(Desc)"
        MockItemWithNoAndDescription(No, Description);
        // [GIVEN] Purchase order line, "Type" = "Item"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);

        // [WHEN] Validate purchase line's "Description" = "glacc"/"(desc)"/"glac"/"(des"/"acc"/"esc"/"xesc)"
        // [THEN] Purchase line's: "No." = "ITEM", "Description" = "(Desc)"
        VerifyPurchaseLineFindRecordByNo(PurchaseLine, 'item_test_item', No, Description);

        // Tear down
        Item.Get(No);
        Item.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLine_FindRecordByNo_ItemCharge()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
        No: Code[20];
        Description: Text[100];
    begin
        // [FEATURE] [Find Record By No] [Item Charge]
        // [SCENARIO 215821] Purchase Line's Item Charge validation can be done using partial-typed "No." value
        // [SCENARIO 252065]
        Initialize();
        No := 'ITEMCH_TEST_ITEMCH';
        Description := 'Description(Test)Description';

        // [GIVEN] Item Charge "ITEMCHARGE" with "Description" = "(Desc)"
        MockItemChargeWithNoAndDescription(No, Description);
        // [GIVEN] Purchase order line, "Type" = "Charge (Item)"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::"Charge (Item)");

        // [WHEN] Validate purchase line's "Description" = "itemcharge"/"desc"/"itemch"/"des"/"charge"/"esc"/"xesc"
        // [THEN] Purchase line's: "No." = "ITEMCHARGE", "Description" = "(Desc)"
        VerifyPurchaseLineFindRecordByNo(PurchaseLine, 'itemch_test_itemch', No, Description);

        // Tear down
        ItemCharge.Get(No);
        ItemCharge.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLine_FindRecordByNo_FixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FixedAsset: Record "Fixed Asset";
        No: Code[20];
        Description: Text[100];
    begin
        // [FEATURE] [Find Record By No] [Fixed Asset]
        // [SCENARIO 215821] Purchase Line's Fixed Asset validation can be done using partial-typed "No." value
        // [SCENARIO 252065]
        Initialize();
        No := 'FA_TEST_FA';
        Description := 'Description(Test)Description';

        // [GIVEN] Fixed Asset "FIXEDASSET" with "Description" = "(Desc)"
        MockFAWithNoAndDescription(No, Description);
        // [GIVEN] Purchase order line, "Type" = "Fixed Asset"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::"Fixed Asset");

        // [WHEN] Validate purchase line's "Description" = "fixedasset"/"desc"/"fixed"/"des"/"asset"/"esc"/"xesc"
        // [THEN] Purchase line's: "No." = "FIXEDASSET", "Description" = "(Desc)"
        VerifyPurchaseLineFindRecordByNo(PurchaseLine, 'fa_test_fa', No, Description);

        // Tear down
        FixedAsset.Get(No);
        FixedAsset.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLine_FindRecordByNo_StandardText()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        StandardText: Record "Standard Text";
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By No] [Standard Text]
        // [SCENARIO 222522] Purchase Line's Standard Text validation can be done using partial-typed "No." value
        // [SCENARIO 252065]
        Initialize();
        No := 'STDTEXT_TEST_STDTEXT';
        Description := 'Description(Test)Description';

        // [GIVEN] Standard Text "STDTEXT" with "Description" = "(Desc)"
        MockStandardText(No, Description);
        // [GIVEN] Purchase order line, "Type" = ""
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(PurchaseLine, PurchaseHeader);

        // [WHEN] Validate purchase line's "Description" = "stdtext"/"desc"/"stdte"/"des"/"tdtext"/"esc"/"xesc"
        // [THEN] Purchase line's: "No." = "STDTEXT", "Description" = "(Desc)"
        VerifyPurchaseLineFindRecordByNo(PurchaseLine, 'stdtext_test_stdtext', No, Description);

        // Tear down
        StandardText.Get(No);
        StandardText.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SellToCodeEditableOnlyWhenSellToCustomerExist()
    var
        PurchaseHeaderSellTo: Record "Purchase Header";
        PurchaseLineSellTo: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Create a purchase order and verify that the Sell-To code is only editable when Sell-To customer is filled in.

        // 1. Setup: Create two Purchase Orders
        Initialize();
        CreatePurchaseOrder(PurchaseHeaderSellTo, PurchaseLineSellTo, CreateItem());
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateItem());

        // 2. Exercise: Mark one of the purchase orders with a Sell-To customer
        PurchaseHeaderSellTo.Validate("Sell-to Customer No.", CreateCustomer());
        PurchaseHeaderSellTo.Modify(true);

        // 3. Verify: The Ship-to Code field is only editable if Sell-to customer was filled in.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoKey(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.IsFalse(PurchaseOrder."Ship-to Code".Editable(), 'Ship-to Code should not be editable');
        PurchaseOrder.Close();

        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoKey(PurchaseHeaderSellTo."Document Type", PurchaseHeaderSellTo."No.");
        Assert.IsTrue(PurchaseOrder."Ship-to Code".Editable(), 'Ship-to Code should be editable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThrowErrorOnPrintPurchOrderWithMixedDropshipment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment] [UT]
        // [SCENARIO 201668] Stan gets error when tries to print purchase order having lines with and without "Drop Shipment" attribute
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        CreateDropShipmentPurchaseLine(PurchaseLine, PurchaseHeader);

        asserterror PurchaseHeader.PrintRecords(false);

        Assert.ExpectedError(MixedDropshipmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThrowErrorOnPrintPurchOrderWithDropShipmentAndFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Drop Shipment] [UT]
        // [SCENARIO 277528] Stan gets error when tries to print purchase order having a line with "Drop Shipment" attribute and a line for fixed asset.
        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreateDropShipmentPurchaseLine(PurchaseLine, PurchaseHeader);

        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", 1);

        asserterror PurchaseHeader.PrintRecords(false);

        Assert.ExpectedError(MixedDropshipmentErr);
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseOrderReportDataHandler')]
    procedure DoNotThrowErrorOnPrintPurchOrderWithMixedDropShipmentAndNonInvtItem()
    var
        NonInvtItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment] [Non-Inventory Item] [UT]
        // [SCENARIO 431276] No error when trying to print purchase order having lines for drop shipment and non-inventory items.
        Initialize();

        LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, NonInvtItem."No.", LibraryRandom.RandInt(10));
        CreateDropShipmentPurchaseLine(PurchaseLine, PurchaseHeader);

        PurchaseHeader.PrintRecords(false);
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseOrderReportDataHandler')]
    [Scope('OnPrem')]
    procedure PrintPurchOrderWithDropshipmentAndCommentLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment] [UT]
        // [SCENARIO 201668] Stan can print purchase order having comment and "Drop Shipment" lines
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreateDropShipmentPurchaseLine(PurchaseLine, PurchaseHeader);

        Clear(PurchaseLine);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::" ", '', 0);
        PurchaseLine.Description := LibraryUtility.GenerateGUID();
        PurchaseLine.Modify();

        PurchaseHeader.PrintRecords(false);
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseOrderReportDataHandler')]
    [Scope('OnPrem')]
    procedure PrintPurchOrderWithoutDropshipmentLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment] [UT]
        // [SCENARIO 201668] Stan can print purchase order without "Drop Shipment" lines
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        PurchaseHeader.PrintRecords(false);
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseOrderReportDataHandler')]
    [Scope('OnPrem')]
    procedure PrintPurchOrderWithDropShipmentAndStandardText()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        StandardText: Record "Standard Text";
    begin
        // [FEATURE] [Drop Shipment] [Standard Text]
        // [SCENARIO 275521] Stan can print purchase order having "Drop Shipment" lines and standard text lines

        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreateDropShipmentPurchaseLine(PurchaseLine, PurchaseHeader);
        LibrarySales.CreateStandardText(StandardText);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::" ", StandardText.Code, 0);

        PurchaseHeader.PrintRecords(false);
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseOrderReportDataHandler')]
    [Scope('OnPrem')]
    procedure PrintPurchOrderWithDropShipmentAndGLAccAndItemChargeLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment] [UT]
        // [SCENARIO 277528] Stan can print purchase order having "Drop Shipment" lines and "G/L Account"- and "Item (Charge)"-typed lines.
        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreateDropShipmentPurchaseLine(PurchaseLine, PurchaseHeader);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 0);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(10));

        PurchaseHeader.PrintRecords(false);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure GetPostedDocLinesFromPurchaseReceiptWithAutoExtText()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderRet: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Extended Text]
        // [SCENARIO 215215] Extended Text Line is copied from Posted Purchase Receipt using 'Get Posted Document Lines to Reverse'
        Initialize();

        // [GIVEN] Purchase order for Item with extended text is received.
        DocumentNo := CreatePostPurchDocWithAutoExtText(PurchaseHeader, PurchaseHeader."Document Type"::Order, false);

        // [GIVEN] Purchase Return Order is created.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderRet, PurchaseHeaderRet."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Run 'Get Posted Document Lines to Reverse' for posted receipt
        GetPostedDocLinesToReverse(PurchaseHeaderRet, OptionStringRef::"Posted Receipts", DocumentNo);

        // [THEN] Extended Text Line exits for Purchase Return Order attached to item line
        VerifyPurchExtLineExists(PurchaseHeaderRet);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure GetPostedDocLinesFromPurchaseInvoiceWithAutoExtText()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderRet: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Extended Text]
        // [SCENARIO 215215] Extended Text Line is copied from Posted Purchase Invoice using 'Get Posted Document Lines to Reverse'
        Initialize();

        // [GIVEN] Purchase order for Item with extended text is received and invoiced.
        DocumentNo := CreatePostPurchDocWithAutoExtText(PurchaseHeader, PurchaseHeader."Document Type"::Order, true);

        // [GIVEN] Purchase Return Order for vendor is created.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderRet, PurchaseHeaderRet."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Get Posted Doc Lines To Reverse for posted invoice
        GetPostedDocLinesToReverse(PurchaseHeaderRet, OptionStringRef::"Posted Invoices", DocumentNo);

        // [THEN] Extended Text Line exits for Purchase Return Order attached to item line
        VerifyPurchExtLineExists(PurchaseHeaderRet);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure GetPostedDocLinesFromPurchaseRetOrderWithAutoExtText()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderRet: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Extended Text]
        // [SCENARIO 215215] Extended Text Line is copied from Posted Return Order using 'Get Posted Document Lines to Reverse'
        Initialize();

        // [GIVEN] Posted Return Purchase order for Item with extended text.
        DocumentNo := CreatePostPurchDocWithAutoExtText(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", true);

        // [GIVEN] Purchase Return Order for vendor is created.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderRet, PurchaseHeaderRet."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Get Posted Doc Lines To Reverse for posted return order
        GetPostedDocLinesToReverse(PurchaseHeaderRet, OptionStringRef::"Posted Return Shipments", DocumentNo);

        // [THEN] Extended Text Line exits for Purchase Return Order attached to item line
        VerifyPurchExtLineExists(PurchaseHeaderRet);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure GetPostedDocLinesFromPurchaseCrMemoWithAutoExtText()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderRet: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Extended Text]
        // [SCENARIO 215215] Extended Text Line is copied from Posted Purchase Cr.Memo using 'Get Posted Document Lines to Reverse'
        Initialize();

        // [GIVEN] Posted Purchase credit memo for Item with extended text is received and invoiced.
        DocumentNo := CreatePostPurchDocWithAutoExtText(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", true);

        // [GIVEN] Purchase Return Order for vendor is created.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderRet, PurchaseHeaderRet."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Get Posted Doc Lines To Reverse for posted credit memo
        GetPostedDocLinesToReverse(PurchaseHeaderRet, OptionStringRef::"Posted Cr. Memos", DocumentNo);

        // [THEN] Extended Text Line exits for Purchase Return Order attached to item line
        VerifyPurchExtLineExists(PurchaseHeaderRet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmountToHandleRecalculatesBasedOnQtyAndPrice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 211691] "Line Amount" recalculates by GetLineAmountToHandle function of table "Purchase Line" based on current Quantity and "Unit Price"

        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchaseHeader, PurchLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 3);
        PurchLine."Direct Unit Cost" := 41.68;
        PurchLine."Line Discount %" := 10;
        PurchLine."Line Discount Amount" := 8.34;

        // "Line Amount" = "Qty. To Handle" * "Unit Price" = 2 * 41.68 = 83.36
        // "Line Discount Amount" = ROUND("Line Amount " * "Line Discount %" / 100) = 83.36 * 10 / 100 = ROUND(8.336) = 8.34
        // "Line Amount To Handle" = "Line Amount" - "Line Discount Amount" = 83.36 - 8.34 = 75.02
        Assert.AreEqual(75.02, PurchLine.GetLineAmountToHandle(2), PurchLineGetLineAmountToHandleErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmountToHandleRoundingWithIntegerPrecision()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 261533] "Line Amount" recalculates by GetLineAmountToHandle function of table "Purchase Line" based on current Quantity and "Unit Price"
        // [SCENARIO 261533] in case of integer Amount Rounding Precision, rounding of partial Quantity
        Initialize();
        LibraryERM.SetAmountRoundingPrecision(1);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchaseHeader, PurchLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 48);
        PurchLine."Direct Unit Cost" := 6706996.8;

        // "Line Amount" = ROUND("Qty. To Handle" * "Unit Price") = ROUND(37 * 6706996.8) = ROUND(248158881,6) = 248158882
        Assert.AreEqual(248158882, PurchLine.GetLineAmountToHandle(37), PurchLineGetLineAmountToHandleErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmountToHandleRoundingWithIntegerPrecisionAndPrepmt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Prepayment]
        // [SCENARIO 261533] "Line Amount" recalculates by GetLineAmountToHandle function of table "Purchase Line" based on current Quantity and "Unit Price"
        // [SCENARIO 261533] in case of integer Amount Rounding Precision, rounding of partial Quantity, prepayment
        Initialize();
        LibraryERM.SetAmountRoundingPrecision(1);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchaseHeader, PurchLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 48);
        PurchLine."Direct Unit Cost" := 6706996.8;
        PurchLine."Prepmt Amt to Deduct" := 1;

        // TempTotalLineAmount = ROUND(Quantity * "Unit Price") = ROUND(48 * 6706996.8) = ROUND(321935846,4) = 321935846
        // "Line Amount" = ROUND("Qty. To Handle" * TempTotalLineAmount / Quantity) = ROUND(37 * 321935846 / 48) = ROUND(248158881,29) = 248158881
        Assert.AreEqual(248158881, PurchLine.GetLineAmountToHandle(37), PurchLineGetLineAmountToHandleErr);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsUpdateTotalVATHandler,VATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure AmountInclVATContainsVATDifferenceInOpenSalesOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        MaxVATDifference: Decimal;
        VATDifference: Decimal;
        AmountInclVATBefore: Decimal;
    begin
        // [FEATURE] [Statistics] [VAT Difference]
        // [SCENARIO 224140] "Amount Incl. VAT" contains VAT Difference in open Purchase Order
        Initialize();

        // [GIVEN] VAT Difference is allowed
        MaxVATDifference := EnableVATDiffAmount();
        VATDifference := LibraryRandom.RandDecInDecimalRange(0.01, MaxVATDifference, 2);
        LibraryVariableStorage.Enqueue(VATDifference);

        // [GIVEN] Purchase Order with Amount = 4000, Amount Incl. VAT = 5000
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), PurchaseHeader."Document Type"::Order);
        AmountInclVATBefore := PurchaseLine."Amount Including VAT";

        // [WHEN] Add "VAT Difference" = 1 in SalesStatisticHandler
        UpdateVATAmountOnPurchaseOrderStatistics(PurchaseHeader, PurchaseOrder);

        // [THEN] "VAT Difference" and "Amount Including VAT" fields contain VAT difference amount in purchase line
        // [THEN] "VAT Difference" = 1 in purchase line
        // [THEN] "Amount Including VAT" = 5001 in purchase line
        PurchaseLine.Find();
        PurchaseLine.TestField("VAT Difference", VATDifference);
        PurchaseLine.TestField("Amount Including VAT", AmountInclVATBefore + VATDifference);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsUpdateTotalVATPageHandler,VATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure AmtInclVATContainsVATDifferenceInOpenSalesOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        MaxVATDifference: Decimal;
        VATDifference: Decimal;
        AmountInclVATBefore: Decimal;
    begin
        // [FEATURE] [Statistics] [VAT Difference]
        // [SCENARIO 224140] "Amount Incl. VAT" contains VAT Difference in open Purchase Order
        Initialize();

        // [GIVEN] VAT Difference is allowed
        MaxVATDifference := EnableVATDiffAmount();
        VATDifference := LibraryRandom.RandDecInDecimalRange(0.01, MaxVATDifference, 2);
        LibraryVariableStorage.Enqueue(VATDifference);

        // [GIVEN] Purchase Order with Amount = 4000, Amount Incl. VAT = 5000
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), PurchaseHeader."Document Type"::Order);
        AmountInclVATBefore := PurchaseLine."Amount Including VAT";

        // [WHEN] Add "VAT Difference" = 1 in SalesStatisticHandler
        UpdateVATAmountOnPurchaseOrderStats(PurchaseHeader, PurchaseOrder);

        // [THEN] "VAT Difference" and "Amount Including VAT" fields contain VAT difference amount in purchase line
        // [THEN] "VAT Difference" = 1 in purchase line
        // [THEN] "Amount Including VAT" = 5001 in purchase line
        PurchaseLine.Find();
        PurchaseLine.TestField("VAT Difference", VATDifference);
        PurchaseLine.TestField("Amount Including VAT", AmountInclVATBefore + VATDifference);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentMethodCodeIsEnabledForSuite()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Shipment Method]
        // [SCENARIO 235272] Shipment Method Code on Purchase Order Page is enabled for #Suite
        Initialize();

        // [GIVEN] User experience set to Suite
        LibraryApplicationArea.EnableRelationshipMgtSetup();

        // [WHEN] Item card page is being opened
        PurchaseOrder.OpenNew();

        // [THEN] Field "Shipment Method Code" is enabled
        Assert.IsTrue(PurchaseOrder."Shipment Method Code".Enabled(), ShipmentMethodCodeIsDisabledErr);

        // TearDown
        PurchaseOrder.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentMethodCodeIsEnabledForBasic()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Shipment Method]
        // [SCENARIO 235272] Shipment Method Code on Purchase Order Page is enabled for #Basic
        Initialize();

        // [GIVEN] User experience set to Basic
        LibraryApplicationArea.EnableBasicSetupForCurrentCompany();

        // [WHEN] Item card page is being opened
        PurchaseOrder.OpenNew();

        // [THEN] Field "Shipment Method Code" is enabled
        Assert.IsTrue(PurchaseOrder."Shipment Method Code".Enabled(), ShipmentMethodCodeIsDisabledErr);

        // TearDown
        PurchaseOrder.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuyFromAddressIsRevertedWhenOrderAddressCodeIsBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        OrderAddress: Record "Order Address";
    begin
        // [FEATURE] [Order Address Code]
        // [SCENARIO 234908] The removal of the Order Address Code on a Purchase Order refreshes the Buy-From Address back to the Vendor Address.
        Initialize();

        // [GIVEN] Vendor "V" with address.
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // [GIVEN] Order Address "OA" for "V".
        LibraryPurchase.CreateOrderAddress(OrderAddress, Vendor."No.");

        // [GIVEN] Purchase Order "PO" for "V" with "OA".
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, Vendor."No.", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Validate("Order Address Code", OrderAddress.Code);
        PurchaseHeader.Modify(true);

        // [WHEN] "PO" Order Address Code is set to blank.
        PurchaseHeader.Validate("Order Address Code", '');
        PurchaseHeader.Modify(true);

        // [THEN] "PO" Buy-From Address are refreshed back to the Vendor Address
        VerifyBuyFromAddressIsVendorAddress(PurchaseHeader, Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultLocationCodeFromVendorOnValidateAndInsert()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Vendor] [Location] [UT]
        // [SCENARIO 231794] Default location code set from the vendor card should be preserved in the purchase document when the Purchase Header record is inserted after validating the vendor code
        Initialize();
        CreateVendorWithDefaultLocation(Vendor);

        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Insert(true);

        PurchaseHeader.TestField("Location Code", Vendor."Location Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DefaultLocationCodeFromVendorOnRevalidatingBuyFromVendor()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Vendor] [Location] [UT]
        // [SCENARIO 231794] Location code in a sales header should be copied from the vendor card when "Buy-from Vendor No." is set and then revalidated with a new value
        Initialize();
        CreateVendorWithDefaultLocation(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        CreateVendorWithDefaultLocation(Vendor);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");

        PurchaseHeader.TestField("Location Code", Vendor."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S461624_DefaultLocationCodeOnPurchaseOrderFromVendor_ValidateVendorAfterInsert()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Company Information] [Vendor] [Location] [Purchase Order]
        // [SCENARIO 461624] "Location Code" in Purchase Document must be copied from Vendor when Purchase Header is inserted before validating "Buy-from Vendor No.".
        Initialize();

        // [GIVEN] 468125 - Set Location Code in Company Information.
        SetLocationInCompanyInformation();

        // [GIVEN] Create Vendor "V10000" with Location "BLUE".
        CreateVendorWithDefaultLocation(Vendor);

        // [WHEN] Create "Purchase Header" for Purchase Order and then validate "Buy-from Vendor No." with "V10000" after inserting Purchase Order Header.
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Modify(true);

        // [THEN] "Location Code" = "BLUE" in the Purchase Order.
        PurchaseHeader.TestField("Location Code", Vendor."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S461624_DefaultLocationCodeOnPurchaseOrderFromCustomer_ValidateVendorAfterInsert()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Company Information] [Vendor] [Customer] [Ship-To Address] [Location] [Purchase Order]
        // [SCENARIO 461624] Customer has "Ship-To Address" defined with "Location Code" defined both on Vendor and Customer.
        // [SCENARIO 461624] "Location Code" in Purchase Document must be copied from Customer when Purchase Header is inserted before validating "Buy-from Vendor No.".
        Initialize();

        // [GIVEN] 468125 - Set Location Code in Company Information.
        SetLocationInCompanyInformation();

        // [GIVEN] Create Vendor "V10000" with Location "BLUE".
        CreateVendorWithDefaultLocation(Vendor);

        // [GIVEN] Create Customer "C10000" with Location "RED".
        // [GIVEN] Create Customer Ship-to Address "C10000_SA" without "Location Code".
        CreateCustomerWithLocationAndShipToAddressWithoutLocation(Customer, ShipToAddress);

        // [WHEN] Create "Purchase Header" for Purchase Order and then validate "Buy-from Vendor No." with "V10000" after inserting Purchase Order Header.
        // [WHEN] Then validate "Sell-to Customer No." with "C10000" and "Ship-to Code" with "C10000_SA".
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Validate("Sell-to Customer No.", Customer."No.");
        PurchaseHeader.Validate("Ship-to Code", ShipToAddress.Code);
        PurchaseHeader.Modify(true);

        // [THEN] "Location Code" = "RED" in the Purchase Order.
        PurchaseHeader.TestField("Location Code", Customer."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S461624_DefaultLocationCodeOnPurchaseOrderFromShipToAddress_ValidateVendorAfterInsert()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Company Information] [Vendor] [Customer] [Ship-To Address] [Location] [Purchase Order]
        // [SCENARIO 461624] Customer has "Ship-To Address" defined with "Location Code" defined on Vendor, Customer and "Ship-To Address".
        // [SCENARIO 461624] "Location Code" in Purchase Document must be copied from "Ship-to Address" when Purchase Header is inserted before validating "Buy-from Vendor No.".
        Initialize();

        // [GIVEN] 468125 - Set Location Code in Company Information.
        SetLocationInCompanyInformation();

        // [GIVEN] Create Vendor "V10000" with Location "BLUE".
        CreateVendorWithDefaultLocation(Vendor);

        // [GIVEN] Create Customer "C10000" with Location "RED".
        // [GIVEN] Create Customer Ship-to Address "C10000_SA" with Location "GREEN".
        CreateCustomerWithLocationAndShipToAddressWithDifferentLocation(Customer, ShipToAddress);

        // [WHEN] Create "Purchase Header" for Purchase Order and then validate "Buy-from Vendor No." with "V10000" after inserting Purchase Order Header.
        // [WHEN] Then validate "Sell-to Customer No." with "C10000" and "Ship-to Code" with "C10000_SA".
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Validate("Sell-to Customer No.", Customer."No.");
        PurchaseHeader.Validate("Ship-to Code", ShipToAddress.Code);
        PurchaseHeader.Modify(true);

        // [THEN] "Location Code" = "GREEN" in the Purchase Order.
        PurchaseHeader.TestField("Location Code", ShipToAddress."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S468125_DefaultLocationCodeOnPurchaseOrderFromVendor_ValidateVendorBeforeInsert()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Vendor] [Location] [Purchase Order] [UT]
        // [SCENARIO 468125] "Location Code" in Purchase Document must be copied from Vendor when Purchase Header is inserted after validating "Buy-from Vendor No.".
        Initialize();

        // [GIVEN] Set Location Code in Company Information.
        SetLocationInCompanyInformation();

        // [GIVEN] Create Vendor "V10000" with Location "BLUE".
        CreateVendorWithDefaultLocation(Vendor);

        // [WHEN] Create "Purchase Header" for Purchase Order and then validate "Buy-from Vendor No." with "V10000" before inserting Purchase Order Header.
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Insert(true);

        // [THEN] "Location Code" = "BLUE" in the Purchase Order.
        PurchaseHeader.TestField("Location Code", Vendor."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S468125_DefaultLocationCodeOnPurchaseOrderFromVendor_ValidateVendorBeforeInsert_ValidateCustomerBeforeInsert()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Company Information] [Vendor] [Customer] [Ship-To Address] [Location] [Purchase Order]
        // [SCENARIO 468125] Customer has "Ship-To Address" defined with "Location Code" defined both on Vendor and Customer.
        // [SCENARIO 468125] "Location Code" in Purchase Document must be copied from Vendor when Purchase Header is inserted after validating "Buy-from Vendor No.".
        Initialize();

        // [GIVEN] Set Location Code in Company Information.
        SetLocationInCompanyInformation();

        // [GIVEN] Create Vendor "V10000" with Location "BLUE".
        CreateVendorWithDefaultLocation(Vendor);

        // [GIVEN] Create Customer "C10000" with Location "RED".
        // [GIVEN] Create Customer Ship-to Address "C10000_SA" without "Location Code".
        CreateCustomerWithLocationAndShipToAddressWithoutLocation(Customer, ShipToAddress);

        // [WHEN] Create "Purchase Header" for Purchase Order and then validate "Buy-from Vendor No." with "V10000" before inserting Purchase Order Header.
        // [WHEN] Then validate "Sell-to Customer No." with "C10000" and "Ship-to Code" with "C10000_SA".
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Validate("Sell-to Customer No.", Customer."No.");
        PurchaseHeader.Validate("Ship-to Code", ShipToAddress.Code);
        PurchaseHeader.Insert(true);

        // [THEN] "Location Code" = "BLUE" in the Purchase Order because Validate("Sell-to Customer No.", '') is executed in InitRecord().
        PurchaseHeader.TestField("Location Code", Vendor."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S468125_DefaultLocationCodeOnPurchaseOrderFromVendor_ValidateVendorBeforeInsert_ValidateShipToCodeBeforeInsert()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Company Information] [Vendor] [Customer] [Ship-To Address] [Location] [Purchase Order]
        // [SCENARIO 468125] Customer has "Ship-To Address" defined with "Location Code" defined on Vendor, Customer and "Ship-To Address".
        // [SCENARIO 468125] "Location Code" in Purchase Document must be copied from Vendor when Purchase Header is inserted after validating "Buy-from Vendor No.".
        Initialize();

        // [GIVEN] Set Location Code in Company Information.
        SetLocationInCompanyInformation();

        // [GIVEN] Create Vendor "V10000" with Location "BLUE".
        CreateVendorWithDefaultLocation(Vendor);

        // [GIVEN] Create Customer "C10000" with Location "RED".
        // [GIVEN] Create Customer Ship-to Address "C10000_SA" with Location "GREEN".
        CreateCustomerWithLocationAndShipToAddressWithDifferentLocation(Customer, ShipToAddress);

        // [WHEN] Create "Purchase Header" for Purchase Order and then validate "Buy-from Vendor No." with "V10000" before inserting Purchase Order Header.
        // [WHEN] Then validate "Sell-to Customer No." with "C10000" and "Ship-to Code" with "C10000_SA".
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Validate("Sell-to Customer No.", Customer."No.");
        PurchaseHeader.Validate("Ship-to Code", ShipToAddress.Code);
        PurchaseHeader.Insert(true);

        // [THEN] "Location Code" = "BLUE" in the Purchase Order because Validate("Sell-to Customer No.", '') is executed in InitRecord().
        PurchaseHeader.TestField("Location Code", Vendor."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S468125_DefaultLocationCodeOnPurchaseOrderFromCustomer_ValidateVendorBeforeInsert_ValidateCustomerAfterInsert()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Company Information] [Vendor] [Customer] [Ship-To Address] [Location] [Purchase Order]
        // [SCENARIO 468125] Customer has "Ship-To Address" defined with "Location Code" defined both on Vendor and Customer.
        // [SCENARIO 468125] "Location Code" in Purchase Document must be copied from Customer when Purchase Header is inserted after validating "Buy-from Vendor No.".
        Initialize();

        // [GIVEN] Set Location Code in Company Information.
        SetLocationInCompanyInformation();

        // [GIVEN] Create Vendor "V10000" with Location "BLUE".
        CreateVendorWithDefaultLocation(Vendor);

        // [GIVEN] Create Customer "C10000" with Location "RED".
        // [GIVEN] Create Customer Ship-to Address "C10000_SA" without "Location Code".
        CreateCustomerWithLocationAndShipToAddressWithoutLocation(Customer, ShipToAddress);

        // [WHEN] Create "Purchase Header" for Purchase Order and then validate "Buy-from Vendor No." with "V10000" before inserting Purchase Order Header.
        // [WHEN] Then validate "Sell-to Customer No." with "C10000" and "Ship-to Code" with "C10000_SA".
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Sell-to Customer No.", Customer."No.");
        PurchaseHeader.Validate("Ship-to Code", ShipToAddress.Code);
        PurchaseHeader.Modify(true);

        // [THEN] "Location Code" = "RED" in the Purchase Order.
        PurchaseHeader.TestField("Location Code", Customer."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S468125_DefaultLocationCodeOnPurchaseOrderFromShipToAddress_ValidateVendorBeforeInsert_ValidateCustomerAfterInsert()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Company Information] [Vendor] [Customer] [Ship-To Address] [Location] [Purchase Order]
        // [SCENARIO 468125] Customer has "Ship-To Address" defined with "Location Code" defined on Vendor, Customer and "Ship-To Address".
        // [SCENARIO 468125] "Location Code" in Purchase Document must be copied from "Ship-To Address" when Purchase Header is inserted after validating "Buy-from Vendor No.".
        Initialize();

        // [GIVEN] Set Location Code in Company Information.
        SetLocationInCompanyInformation();

        // [GIVEN] Create Vendor "V10000" with Location "BLUE".
        CreateVendorWithDefaultLocation(Vendor);

        // [GIVEN] Create Customer "C10000" with Location "RED".
        // [GIVEN] Create Customer Ship-to Address "C10000_SA" with Location "GREEN".
        CreateCustomerWithLocationAndShipToAddressWithDifferentLocation(Customer, ShipToAddress);

        // [WHEN] Create "Purchase Header" for Purchase Order and then validate "Buy-from Vendor No." with "V10000" before inserting Purchase Order Header.
        // [WHEN] Then validate "Sell-to Customer No." with "C10000" and "Ship-to Code" with "C10000_SA".
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Sell-to Customer No.", Customer."No.");
        PurchaseHeader.Validate("Ship-to Code", ShipToAddress.Code);
        PurchaseHeader.Modify(true);

        // [THEN] "Location Code" = "GREEN" in the Purchase Order.
        PurchaseHeader.TestField("Location Code", ShipToAddress."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S468125_DefaultLocationCodeOnPurchaseOrderFromCompanyInformation_ValidateVendorBeforeInsert()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [Company Information] [Vendor] [Location] [Purchase Order]
        // [SCENARIO 468125] "Location Code" in Purchase Document must be copied from Company Information when Purchase Header is inserted before validating "Buy-from Vendor No.".
        Initialize();

        // [GIVEN] Set Location Code in Company Information.
        SetLocationInCompanyInformation();

        // [GIVEN] Create Vendor "V10000" without Location.
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Create "Purchase Header" for Purchase Order and then validate "Buy-from Vendor No." with "V10000" before inserting Purchase Order Header.
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Insert(true);

        // [THEN] "Location Code" = "Company Information"."Location Code" in the Purchase Order.
        CompanyInformation.Get();
        PurchaseHeader.TestField("Location Code", CompanyInformation."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S468125_DefaultLocationCodeOnPurchaseOrderFromCompanyInformation_ValidateVendorAfterInsert()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [Company Information] [Vendor] [Location] [Purchase Order]
        // [SCENARIO 468125] "Location Code" in Purchase Document must be copied from Company Information when Purchase Header is inserted before validating "Buy-from Vendor No.".
        Initialize();

        // [GIVEN] Set Location Code in Company Information.
        SetLocationInCompanyInformation();

        // [GIVEN] Create Vendor "V10000" without Location.
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Create "Purchase Header" for Purchase Order and then validate "Buy-from Vendor No." with "V10000" after inserting Purchase Order Header.
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Modify(true);

        // [THEN] "Location Code" = "Company Information"."Location Code" in the Purchase Order.
        CompanyInformation.Get();
        PurchaseHeader.TestField("Location Code", CompanyInformation."Location Code");
    end;

    [Test]
    procedure S470567_ShipmentMethodAssignmentPriority_CustomerWithoutSM_NoDefaultShipToAddress_ShipToAddressWithoutSM()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Vendor] [Customer] [Ship-to Address] [Shipment Method] [Purchase Order] [UT]
        // [SCENARIO 470567] Customer does not have default "Ship-to Address" and "Shipment Method Code" is blank in Customer Card and blank in "Ship-to Address".
        // [SCENARIO 470567] "Shipment Method Code" must be copied from "Customer Card" if ther is not "Ship-to Address" defined or "Ship-to Address" has blank "Shipment Method Code".
        Initialize();

        // [GIVEN] Create Vendor "V" with "Shipment Method Code".
        CreateVendorWithDefaultLocation(Vendor);
        if Vendor."Shipment Method Code" = '' then begin
            Vendor.Validate("Shipment Method Code", CreateShipmentMethodCode());
            Vendor.Modify(true);
        end;

        // [GIVEN] Create Customer "C" without "Shipment Method Code" and without default "Ship-to Address".
        LibrarySales.CreateCustomer(Customer);
        if Customer."Shipment Method Code" <> '' then begin
            Customer.Validate("Shipment Method Code", '');
            Customer.Modify(true);
        end;

        // [GIVEN] Create Customer Ship-to Address "C_SA" without "Shipment Method Code".
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        if ShipToAddress."Shipment Method Code" <> '' then begin
            ShipToAddress.Validate("Shipment Method Code", '');
            ShipToAddress.Modify(true);
        end;

        // [WHEN] Create "Purchase Header" for Purchase Order and validate "Buy-from Vendor No." with "V" after inserting Purchase Order Header.
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Purchase Order = "Shipment Method Code" from Vendor "V".
        PurchaseHeader.TestField("Shipment Method Code", Vendor."Shipment Method Code");

        // [WHEN] Then validate "Sell-to Customer No." as "C" in Purchase Order.
        PurchaseHeader.Validate("Sell-to Customer No.", Customer."No.");
        PurchaseHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Purchase Order = "Shipment Method Code" from "Customer" (blank).
        PurchaseHeader.TestField("Shipment Method Code", '');

        // [WHEN] Set "C_SA" as "Ship-to Code" in Purchase Order.
        PurchaseHeader.Validate("Ship-to Code", ShipToAddress.Code);
        PurchaseHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Purchase Order = "Shipment Method Code" from "Customer" (blank).
        PurchaseHeader.TestField("Shipment Method Code", '');
    end;

    [Test]
    procedure S470567_ShipmentMethodAssignmentPriority_CustomerWithoutSM_NoDefaultShipToAddress_ShipToAddressWithSM()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Vendor] [Customer] [Ship-to Address] [Shipment Method] [Purchase Order] [UT]
        // [SCENARIO 470567] Vendor has "Shipment Method Code" defined. Customer does not have default "Ship-to Address" and "Shipment Method Code" is blank in Customer Card, but is defined for "Ship-to Address".
        // [SCENARIO 470567] "Shipment Method Code" must be copied from "Customer Card" if ther is not "Ship-to Address" defined or "Ship-to Address" has blank "Shipment Method Code".
        Initialize();

        // [GIVEN] Create Vendor "V" with "Shipment Method Code".
        CreateVendorWithDefaultLocation(Vendor);
        if Vendor."Shipment Method Code" = '' then begin
            Vendor.Validate("Shipment Method Code", CreateShipmentMethodCode());
            Vendor.Modify(true);
        end;

        // [GIVEN] Create Customer "C" without "Shipment Method Code" and without default "Ship-to Address".
        LibrarySales.CreateCustomer(Customer);
        if Customer."Shipment Method Code" <> '' then begin
            Customer.Validate("Shipment Method Code", '');
            Customer.Modify(true);
        end;

        // [GIVEN] Create Customer Ship-to Address "C_SA" with "Shipment Method Code".
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        if ShipToAddress."Shipment Method Code" = '' then begin
            ShipToAddress.Validate("Shipment Method Code", CreateShipmentMethodCode());
            ShipToAddress.Modify(true);
        end;

        // [WHEN] Create "Purchase Header" for Purchase Order and validate "Buy-from Vendor No." with "V" after inserting Purchase Order Header.
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Purchase Order = "Shipment Method Code" from Vendor "V".
        PurchaseHeader.TestField("Shipment Method Code", Vendor."Shipment Method Code");

        // [WHEN] Then validate "Sell-to Customer No." as "C" in Purchase Order.
        PurchaseHeader.Validate("Sell-to Customer No.", Customer."No.");
        PurchaseHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Purchase Order = "Shipment Method Code" from "Customer" (blank).
        PurchaseHeader.TestField("Shipment Method Code", '');

        // [WHEN] Set "C_SA" as "Ship-to Code" in Purchase Order.
        PurchaseHeader.Validate("Ship-to Code", ShipToAddress.Code);
        PurchaseHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Purchase Order = "Shipment Method Code" from "Ship-to Address".
        PurchaseHeader.TestField("Shipment Method Code", ShipToAddress."Shipment Method Code");
    end;

    [Test]
    procedure S470567_ShipmentMethodAssignmentPriority_CustomerWithSM_NoDefaultShipToAddress_ShipToAddressWithoutSM()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Vendor] [Customer] [Ship-to Address] [Shipment Method] [Purchase Order] [UT]
        // [SCENARIO 470567] Customer does not have default "Ship-to Address" and "Shipment Method Code" is defined for Customer Card and blank in "Ship-to Address".
        // [SCENARIO 470567] "Shipment Method Code" must be copied from "Customer Card" if ther is not "Ship-to Address" defined or "Ship-to Address" has blank "Shipment Method Code".
        Initialize();

        // [GIVEN] Create Vendor "V" with "Shipment Method Code".
        CreateVendorWithDefaultLocation(Vendor);
        if Vendor."Shipment Method Code" = '' then begin
            Vendor.Validate("Shipment Method Code", CreateShipmentMethodCode());
            Vendor.Modify(true);
        end;

        // [GIVEN] Create Customer "C" with "Shipment Method Code" and without default "Ship-to Address".
        LibrarySales.CreateCustomer(Customer);
        if Customer."Shipment Method Code" = '' then begin
            Customer.Validate("Shipment Method Code", CreateShipmentMethodCode());
            Customer.Modify(true);
        end;

        // [GIVEN] Create Customer Ship-to Address "C_SA" without "Shipment Method Code".
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        if ShipToAddress."Shipment Method Code" <> '' then begin
            ShipToAddress.Validate("Shipment Method Code", '');
            ShipToAddress.Modify(true);
        end;

        // [WHEN] Create "Purchase Header" for Purchase Order and validate "Buy-from Vendor No." with "V" after inserting Purchase Order Header.
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Purchase Order = "Shipment Method Code" from Vendor "V".
        PurchaseHeader.TestField("Shipment Method Code", Vendor."Shipment Method Code");

        // [WHEN] Then validate "Sell-to Customer No." as "C" in Purchase Order.
        PurchaseHeader.Validate("Sell-to Customer No.", Customer."No.");
        PurchaseHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Purchase Order = "Shipment Method Code" from "Customer".
        PurchaseHeader.TestField("Shipment Method Code", Customer."Shipment Method Code");

        // [WHEN] Set "C_SA" as "Ship-to Code" in Purchase Order.
        PurchaseHeader.Validate("Ship-to Code", ShipToAddress.Code);
        PurchaseHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Purchase Order = "Shipment Method Code" from "Customer".
        PurchaseHeader.TestField("Shipment Method Code", Customer."Shipment Method Code");
    end;

    [Test]
    procedure S470567_ShipmentMethodAssignmentPriority_CustomerWithSM_NoDefaultShipToAddress_ShipToAddressWithSM()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Vendor] [Customer] [Ship-to Address] [Shipment Method] [Purchase Order] [UT]
        // [SCENARIO 470567] Customer does not have default "Ship-to Address" and "Shipment Method Code" is defined for Customer Card and is defined for "Ship-to Address".
        // [SCENARIO 470567] "Shipment Method Code" must be copied from "Customer Card" if ther is not "Ship-to Address" defined or "Ship-to Address" has blank "Shipment Method Code".
        Initialize();

        // [GIVEN] Create Vendor "V" with "Shipment Method Code".
        CreateVendorWithDefaultLocation(Vendor);
        if Vendor."Shipment Method Code" = '' then begin
            Vendor.Validate("Shipment Method Code", CreateShipmentMethodCode());
            Vendor.Modify(true);
        end;

        // [GIVEN] Create Customer "C" with "Shipment Method Code" and without default "Ship-to Address".
        LibrarySales.CreateCustomer(Customer);
        if Customer."Shipment Method Code" = '' then begin
            Customer.Validate("Shipment Method Code", CreateShipmentMethodCode());
            Customer.Modify(true);
        end;

        // [GIVEN] Create Customer Ship-to Address "C_SA" with "Shipment Method Code".
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        if ShipToAddress."Shipment Method Code" = '' then begin
            ShipToAddress.Validate("Shipment Method Code", CreateShipmentMethodCode());
            ShipToAddress.Modify(true);
        end;

        // [WHEN] Create "Purchase Header" for Purchase Order and validate "Buy-from Vendor No." with "V" after inserting Purchase Order Header.
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Purchase Order = "Shipment Method Code" from Vendor "V".
        PurchaseHeader.TestField("Shipment Method Code", Vendor."Shipment Method Code");

        // [WHEN] Then validate "Sell-to Customer No." as "C" in Purchase Order.
        PurchaseHeader.Validate("Sell-to Customer No.", Customer."No.");
        PurchaseHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Purchase Order = "Shipment Method Code" from "Customer".
        PurchaseHeader.TestField("Shipment Method Code", Customer."Shipment Method Code");

        // [WHEN] Set "C_SA" as "Ship-to Code" in Purchase Order.
        PurchaseHeader.Validate("Ship-to Code", ShipToAddress.Code);
        PurchaseHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Purchase Order = "Shipment Method Code" from "Ship-to Address".
        PurchaseHeader.TestField("Shipment Method Code", ShipToAddress."Shipment Method Code");
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NotInsertInvLineFromExtTextRcptLine()
    var
        Item: Record Item;
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchHeader: Record "Purchase Header";
        ItemNo1: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Get Receipt Lines]
        // [SCENARIO 252893] Deletion of extedned text lines must not cause suggestion of extra lines from Receipt
        Initialize();

        // Create Item with Extended Text
        LibraryInventory.CreateItem(Item);
        ItemNo1 := Item."No.";
        CreateExtendedText(Item);

        // [GIVEN] Create purchase order and line with Extended Text
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchLineWithExtTexts(PurchHeader, PurchLine, Item, 1);

        // [GIVEN] Create Receive Order
        PostReceivePurchOrderWithVAT(PurchRcptLine, PurchHeader);

        // [GIVEN] Remove Extended Text lines from Purchase Order
        PurchHeader.Find();
        PurchHeader.SetStatus(PurchHeader.Status::Open.AsInteger());
        PurchLine.SetRange("Document Type", PurchHeader."Document Type"::Order);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange(Type, PurchLine.Type::" ");
        PurchLine.DeleteAll();

        // [GIVEN] Add one more Purchase Line to Order
        Clear(PurchLine);
        LibraryInventory.CreateItem(Item);
        ItemNo2 := Item."No.";
        CreateExtendedText(Item);
        CreatePurchLineWithExtTexts(PurchHeader, PurchLine, Item, 2);

        // [GIVEN] Create Purchase Invoice
        Clear(PurchHeader);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, PurchRcptLine."Buy-from Vendor No.");

        // [WHEN] Get Receipt Lines
        GetReceiptLine(PurchHeader);

        // [THEN] Newly added Purchase Line does not appear in Purchase Invoice
        Clear(PurchLine);
        PurchLine.SetRange("Document Type", PurchHeader."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("No.", ItemNo1);
        Assert.RecordCount(PurchLine, 1);

        PurchLine.SetRange("No.", ItemNo2);
        Assert.RecordIsEmpty(PurchLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotModifyHeaderOnAutoCalcInvoiceDiscInLinesSalesOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderOld: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Invoice Discount] [Order] [UI] [Document Totals]
        // [SCENARIO 254317] Do not modify Order when invoice discount is calculated on lines
        Initialize();

        // [GIVEN] "Purchases & Payables Setup" with "Calc. Inv. Discount" = TRUE
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Vendor "X" with Service Charge settings
        // [GIVEN] Purchase Order "PO" for the vendor "X" with a single line
        CreatePurchaseDocumentWithSingleLineWithQuantity(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandIntInRange(10, 20));

        PurchaseHeader.TestField("Invoice Discount Value", 0);
        PurchaseHeaderOld := PurchaseHeader;

        // [WHEN] Open Purchase Order page for "PO"
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // [THEN] The "PO"."Invoice Discount Value" = 0 (remains unchanged)
        PurchaseHeader.Find();
        Assert.AreEqual(PurchaseHeaderOld."Invoice Discount Value", PurchaseHeader."Invoice Discount Value", InvoiceDiscountChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotModifyHeaderOnAutoCalcInvoiceDiscInLinesSalesInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderOld: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Invoice Discount] [Invoice] [UI] [Document Totals]
        // [SCENARIO 254317] Do not modify Invoice when invoice discount is calculated on lines
        Initialize();

        // [GIVEN] "Purchases & Payables Setup" with "Calc. Inv. Discount" = TRUE
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Vendor "X" with Discount settings
        // [GIVEN] Purchase Invoice "PI" for the vendor "X" with a single line
        CreatePurchaseDocumentWithSingleLineWithQuantity(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandIntInRange(10, 20));

        PurchaseHeader.TestField("Invoice Discount Value", 0);
        PurchaseHeaderOld := PurchaseHeader;

        // [WHEN] Open Purchase Invoice card page with invoice "PI"
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // [THEN] The "PI"."Invoice Discount Value" = 0 (remains unchanged)
        PurchaseHeader.Find();
        Assert.AreEqual(PurchaseHeaderOld."Invoice Discount Value", PurchaseHeader."Invoice Discount Value", InvoiceDiscountChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotModifyHeaderOnAutoCalcInvoiceDiscInLinesSalesQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderOld: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [Invoice Discount] [Quote] [UI] [Document Totals]
        // [SCENARIO 254317] Do not modify Quote when invoice discount is calculated on lines
        Initialize();

        // [GIVEN] "Purchases & Payables Setup" with "Calc. Inv. Discount" = TRUE
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Vendor "X" with Discount settings
        // [GIVEN] Sales Quote "Q" for the vendor "X" with a single line
        CreatePurchaseDocumentWithSingleLineWithQuantity(
          PurchaseHeader, PurchaseHeader."Document Type"::Quote, LibraryRandom.RandIntInRange(10, 20));

        PurchaseHeader.TestField("Invoice Discount Value", 0);
        PurchaseHeaderOld := PurchaseHeader;

        // [GIVEN] Open Purchase Quote card page with  "Q"
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);

        // [THEN] The "Q"."Invoice Discount Value" = 0 (remains unchanged)
        PurchaseHeader.Find();
        Assert.AreEqual(PurchaseHeaderOld."Invoice Discount Value", PurchaseHeader."Invoice Discount Value", InvoiceDiscountChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotModifyHeaderOnAutoCalcInvoiceDiscInLinesSalesCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderOld: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Invoice Discount] [Credit Memo] [UI] [Document Totals]
        // [SCENARIO 254317] Do not modify Credit Memo when invoice discount is calculated on lines
        Initialize();

        // [GIVEN] "Purchases & Payables Setup" with "Calc. Inv. Discount" = TRUE
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Vendor "X" with Discount settings
        // [GIVEN] Purchase Credit Memo "CrM" for the vendor "X" with a single line
        CreatePurchaseDocumentWithSingleLineWithQuantity(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryRandom.RandIntInRange(10, 20));

        PurchaseHeader.TestField("Invoice Discount Value", 0);
        PurchaseHeaderOld := PurchaseHeader;

        // [WHEN] Open Purchase Credit Memo card page with "CrM"
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);

        // [THEN] The "CrM"."Invoice Discount Value" = 0 (remains unchanged)
        PurchaseHeader.Find();
        Assert.AreEqual(PurchaseHeaderOld."Invoice Discount Value", PurchaseHeader."Invoice Discount Value", InvoiceDiscountChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressIsVisibleOnCompanyInformationPageForSuite()
    var
        CompanyInformation: TestPage "Company Information";
    begin
        // [FEATURE] [UI] [Company Information]
        // [SCENARIO 255862] Ship-To Address fields on Company Information Page are enabled for #Suite.
        Initialize();

        // [GIVEN] User experience set to Suite.
        LibraryApplicationArea.EnableFoundationSetupForCurrentCompany();

        // [WHEN] Company Information page is being opened.
        CompanyInformation.OpenEdit();

        // [THEN] Ship-To Address fields are enabled
        Assert.IsTrue(CompanyInformation."Ship-to Name".Enabled(), ShipToAddrOnCompanyInfoIsDisabledErr);
        Assert.IsTrue(CompanyInformation."Ship-to Address".Enabled(), ShipToAddrOnCompanyInfoIsDisabledErr);
        Assert.IsTrue(CompanyInformation."Ship-to Address 2".Enabled(), ShipToAddrOnCompanyInfoIsDisabledErr);
        Assert.IsTrue(CompanyInformation."Ship-to Post Code".Enabled(), ShipToAddrOnCompanyInfoIsDisabledErr);
        Assert.IsTrue(CompanyInformation."Ship-to City".Enabled(), ShipToAddrOnCompanyInfoIsDisabledErr);
        Assert.IsTrue(CompanyInformation."Ship-to Country/Region Code".Enabled(), ShipToAddrOnCompanyInfoIsDisabledErr);
        Assert.IsTrue(CompanyInformation."Ship-to Contact".Enabled(), ShipToAddrOnCompanyInfoIsDisabledErr);
        Assert.IsTrue(CompanyInformation."Ship-to Phone No.".Enabled(), ShipToAddrOnCompanyInfoIsDisabledErr);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup();
        CompanyInformation.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPurchaseReceiptWithCalcInvDiscountForServiceCharge()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        VendorNo: Code[20];
        ServiceChargeAmt: Decimal;
    begin
        // [FEATURE] [Invoice Discount] [Service Charge] [Warehouse Receipt]
        // [SCENARIO 257351] Posting warehouse receipt for purchase order with enabled invoice discount and service charge should re-calculate the service charge amount if it is changed in Vendor Invoice Discount after the document is released.
        Initialize();

        // [GIVEN] Enable invoice discount calculation on "Purchases & Payables Setup".
        // [GIVEN] Set "Service Charge" = 10 in "Vendor Invoice Discount" setting for vendor "V".
        LibraryPurchase.SetCalcInvDiscount(true);
        VendorNo := CreateVendorInvDiscount();
        ServiceChargeAmt := LibraryRandom.RandDecInDecimalRange(10, 20, 2);
        VendorInvoiceDisc.SetRange(Code, VendorNo);
        VendorInvoiceDisc.FindFirst();
        VendorInvoiceDisc.Validate("Service Charge", ServiceChargeAmt);
        VendorInvoiceDisc.Modify(true);

        // [GIVEN] Location "L" set up for required receive.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Purchase order with vendor = "V" and location = "L".
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, VendorNo,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), Location.Code, WorkDate());

        // [GIVEN] Releasing the purchase order adds a service charge purchase line to the order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Update "Service Charge" to 20 in "Vendor Invoice Discount" setting for vendor "V".
        VendorInvoiceDisc.Validate("Service Charge", 2 * ServiceChargeAmt);
        VendorInvoiceDisc.Modify(true);

        // [GIVEN] Create warehouse receipt from the purchase order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
            DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));

        // [WHEN] Post the warehouse receipt.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] The receipt is posted without an error.
        PurchaseLine.Find();
        PurchaseLine.TestField("Qty. Received (Base)", PurchaseLine."Quantity (Base)");

        // [THEN] Purchase line amount for the service charge is updated to 20.
        FindPurchaseLineWithType(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Document Type", PurchaseLine.Type::"G/L Account");
        PurchaseLine.TestField(Amount, 2 * ServiceChargeAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestingItemChargeAsmgtNotAllowedWithZeroQtyToInvoiceOnPurchLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        // [FEATURE] [Purchase Order] [Item Charge]
        // [SCENARIO 271095] Suggesting item charge assignment must lead to "Qty. to Invoice must have a value." error when Qty to Invoice is zero

        Initialize();

        // [GIVEN] Create Purchase Order with single line of "Charge (Item)" type
        CreatePurchaseOrderWithChargeItem(PurchaseHeader, PurchaseLine, 1);

        // [GIVEN] Set "Qty. to Invoice" to 0 in purchase line
        PurchaseLine.Validate("Qty. to Invoice", 0);
        PurchaseLine.Modify(true);

        // [WHEN] Trying to Suggest Item Charge Assignment
        asserterror ItemChargeAssgntPurch.SuggestAssgnt(PurchaseLine, 0, 0, 0, 0);

        // [THEN] Expected error: "Qty. to Invoice must have a value."
        Assert.ExpectedError(SuggestAssignmentErr);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchPageHandler')]
    [Scope('OnPrem')]
    procedure CreatingItemChargeAsmgtNotAllowedWithZeroQtyToInvoiceOnPurchLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase Order] [Item Charge]
        // [SCENARIO 271095] Creating item charge assignment by Get Receipt Lines action must lead to "Qty. to Invoice must have a value." error when Qty to Invoice is zero

        Initialize();

        // [GIVEN] Create Purchase Order with single line of "Charge (Item)" type
        CreatePurchaseOrderWithChargeItem(PurchaseHeader, PurchaseLine, 1);

        // [GIVEN] Set "Qty. to Invoice" to 0 in purchase line
        PurchaseLine.Validate("Qty. to Invoice", 0);
        PurchaseLine.Modify(true);

        // [WHEN] Start item assignment page
        asserterror PurchaseLine.ShowItemChargeAssgnt();

        // [THEN] Expected error: "Qty. to Invoice must have a value."
        Assert.ExpectedError(SuggestAssignmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillingInQtyToAssgnItemChargeAsmgtNotAllowedWithZeroQtyToInvoiceOnPurchLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchOrderNo: Code[20];
    begin
        // [FEATURE] [Purchase Order] [Item Charge]
        // [SCENARIO 271095] Filling in Qty. to Assign field in existing item charge assignment must lead to "Qty. to Invoice must have a value." error when Qty to Invoice is zero

        Initialize();

        // Create purchase header and post it as receipt
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchOrderNo := PurchaseHeader."No.";

        // [GIVEN] Create purchase order with single line of "Charge (Item)" type
        CreatePurchaseOrderWithChargeItem(PurchaseHeader, PurchaseLine, 1);

        // [GIVEN] Create item charge assignment for the purchase order
        FindRcptLine(PurchRcptLine, PurchOrderNo);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");

        // [GIVEN] Set "Qty. to Invoice" to 0 in purchase line
        PurchaseLine.Validate("Qty. to Invoice", 0);
        PurchaseLine.Modify(true);

        // [WHEN] Setting Qty. to Assign field
        asserterror ItemChargeAssignmentPurch.Validate("Qty. to Assign", LibraryRandom.RandInt(100));

        // [THEN] Expected error: "Qty. to Invoice must have a value."
        Assert.ExpectedError(SuggestAssignmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSalesOrderLineAutoCalcInvoiceDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        // [FEATURE] [Invoice Discount] [UT]
        // [SCENARIO 273796] COD70.CalculateInvoiceDiscountOnLine returns actual Purchase Line
        Initialize();

        // [GIVEN] "Purchases & Payables Setup" with "Calc. Inv. Discount" = TRUE
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Purchase Order with a single line
        CreatePurchaseDocumentWithSingleLineWithQuantity(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] "Recalculate Invoice Disc." in Purchase Line is equal to TRUE
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Document Type");

        PurchaseLine.TestField("Recalculate Invoice Disc.");

        // [WHEN] Call COD70.CalculateInvoiceDiscountOnLine
        PurchCalcDiscount.CalculateInvoiceDiscountOnLine(PurchaseLine);

        // [THEN] "Recalculate Invoice Disc." in returned Purchase Line is equal to FALSE
        PurchaseLine.TestField("Recalculate Invoice Disc.", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSalesOrderLineAutoCalcInvoiceDiscTwoLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        LineNo: Integer;
    begin
        // [FEATURE] [Invoice Discount] [UT]
        // [SCENARIO 276919] COD70.CalculateInvoiceDiscountOnLine returns updated initial Purchase Line
        Initialize();

        // [GIVEN] "Purchases & Payables Setup" with "Calc. Inv. Discount" = TRUE
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Purchase Order with 2 lines
        CreatePurchaseDocumentWithSingleLineWithQuantity(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandIntInRange(10, 20));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLine."No.", LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] "Recalculate Invoice Disc." in Purchase Line is equal to TRUE
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Document Type");
        LineNo := PurchaseLine."Line No.";
        PurchaseLine.TestField("Recalculate Invoice Disc.");

        // [WHEN] Call COD70.CalculateInvoiceDiscountOnLine from first line with Line No. = 10000
        PurchCalcDiscount.CalculateInvoiceDiscountOnLine(PurchaseLine);

        // [THEN] Returned line has Line No matching to 10000
        // [THEN] "Recalculate Invoice Disc." in returned Purchase Line is equal to FALSE
        PurchaseLine.TestField("Line No.", LineNo);
        PurchaseLine.TestField("Recalculate Invoice Disc.", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ShipmentMethodCodeAfterValidatePayToVendor()
    var
        Vendor: array[2] of Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 277844] Shipment Method Code of Purchase Order does not update after validating "Pay-to Vendor"
        Initialize();

        // [GIVEN] Vendor "V1" with Shipment Method Code "SMC1"
        CreateVendorWithShipmentMethodCode(Vendor[1]);

        // [GIVEN] Vendor "V2" with Shipment Method Code "SMC2"
        CreateVendorWithShipmentMethodCode(Vendor[2]);

        // [GIVEN] Purchase Order with "Vendor No." and "Pay-to Vendor" = "V1" and "Shipment Method Code" = "SMC1"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor[1]."No.");
        PurchaseHeader.TestField("Shipment Method Code", Vendor[1]."Shipment Method Code");

        // [WHEN] Validate "Pay-to Vendor" = "V2"
        PurchaseHeader.Validate("Pay-to Vendor No.", Vendor[2]."No.");

        // [THEN] Shipment Method Code = "SMC1"
        PurchaseHeader.TestField("Shipment Method Code", Vendor[1]."Shipment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseHeaderAmountReceivedNotInvoicedLCYFilters()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Index: Integer;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 277892] Amount received not invoiced (LCY) calculates sum of corresponding values of purchase lines filtered by Document Type and Document No.

        Initialize();
        DocumentNo := LibraryUtility.GenerateGUID();
        for Index := 1 to 2 do begin
            MockPurchaseHeader(PurchaseHeader, "Purchase Document Type".FromInteger(Index), DocumentNo);
            MockPurchaseLineWithReceivedNotInvLCY(PurchaseLine, PurchaseHeader, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        end;

        PurchaseHeader.CalcFields("A. Rcd. Not Inv. Ex. VAT (LCY)", "Amt. Rcd. Not Invoiced (LCY)");
        PurchaseHeader.TestField(
          "Amt. Rcd. Not Invoiced (LCY)",
          PurchaseLine."Amt. Rcd. Not Invoiced (LCY)");
        PurchaseHeader.TestField(
          "A. Rcd. Not Inv. Ex. VAT (LCY)",
          PurchaseLine."A. Rcd. Not Inv. Ex. VAT (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderChangePricesInclVATRefreshesPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderPage: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 277993] User changes Prices including VAT, page refreshes and shows appropriate captions
        Initialize();

        // [GIVEN] Page with Prices including VAT disabled was open
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.GotoRecord(PurchaseHeader);

        // [WHEN] User checks Prices including VAT
        PurchaseOrderPage."Prices Including VAT".SetValue(true);

        // [THEN] Caption for PurchaseOrderPage.PurchLines."Direct Unit Cost" field is updated
        Assert.AreEqual('Direct Unit Cost Incl. VAT',
          PurchaseOrderPage.PurchLines."Direct Unit Cost".Caption,
          'The caption for PurchaseOrderPage.PurchLines."Direct Unit Cost" is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDescriptionOnValidateAndInsert()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PostingDescription: Text;
    begin
        // [FEATURE] [Purchase Order] [Posting Description] [UT]
        // [SCENARIO 285973] "Posting Description" contains "Document Type" and "No." in the purchase document when the Purchase Header record is inserted after validating the vendor code
        Initialize();
        // [GIVEN] Vendor - X
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Validate "Buy-from Vendor No." with X
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Insert(true);

        // [THEN] "Posting Description" contains "Document Type" and "No."
        PostingDescription := Format(PurchaseHeader."Document Type") + ' ' + PurchaseHeader."No.";
        PurchaseHeader.TestField("Posting Description", PostingDescription);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostingDescriptionOnRevalidatingBuyFromVendor()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PostingDescription: Text;
    begin
        // [FEATURE] [Purchase Order] [Posting Description] [UT]
        // [SCENARIO 285973] "Posting Description" contains "Document Type" and "No." when "Buy-from Vendor No." is set and then revalidated with a new value
        Initialize();
        // [GIVEN] Vendor - X
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Purchase header with "Buy-from Vendor No." = X
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        // [GIVEN] Vendor - Y
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Validate "Buy-from Vendor No." with Y
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");

        // [THEN] "Posting Description" contains "Document Type" and "No."
        PostingDescription := Format(PurchaseHeader."Document Type") + ' ' + PurchaseHeader."No.";
        PurchaseHeader.TestField("Posting Description", PostingDescription);
    end;

    [Test]
    [HandlerFunctions('QtyToAssgnItemChargeModalPageHandler')]
    [Scope('OnPrem')]
    procedure PartialPurchInvoicePostingDontClearQtyToAssignInPrimaryDocument()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        UOMMgt: Codeunit "Unit of Measure Management";
        Qty: Decimal;
        UnitCost: Decimal;
    begin
        // [FEATURE] [Purchase Order] [Item Charge] [Get Receipt Lines]
        // [SCENARIO 283749] When purchase order is being invoiced by a separate document (Purch. Invoice), Qty. to Assign field in charge assignment (made for initial purch. order) must decrease accordingly.
        Initialize();

        // [GIVEN] Create Purch. Order with item and item charge lines. Quantity = 10 for both lines, Unit Cost = 2 LCY.
        Qty := 10;
        UnitCost := 2.0;
        CreatePurchaseHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order);
        CreatePurchaseLineWithDirectUnitCost(
          PurchaseLine, PurchaseHeaderOrder, PurchaseLine.Type::Item, CreateItem(), Qty, UnitCost);
        CreatePurchaseLineWithDirectUnitCost(
          PurchaseLine, PurchaseHeaderOrder, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), Qty, UnitCost);

        // [GIVEN] Open Item Charge Assignment page and set Qty to Assign = 10
        OpenItemChargeAssgnt(PurchaseLine, true, Qty);

        // [GIVEN] Decrease Qty. to Receive = 10 / 3 = 3.33333 on item charge line.
        PurchaseLine.Validate("Qty. to Receive", Round(Qty / 3, UOMMgt.QtyRndPrecision()));
        PurchaseLine.Modify(true);

        // [GIVEN] Post (partialy) Purch. Order as Receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [GIVEN] Create Purch. Invoice with the help of "Get Receipt Lines"
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, PurchaseHeaderOrder."Buy-from Vendor No.");
        PurchRcptLine.SetRange("Order No.", PurchaseHeaderOrder."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [WHEN] Post Purch. Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] "Qty. to Assign" = 6.66667 (rounded to 5 digits), "Amount to Assign" = 13.33 LCY (rounded to 2 digits).
        ItemChargeAssignmentPurch.SetRange("Document Type", ItemChargeAssignmentPurch."Document Type"::Order);
        ItemChargeAssignmentPurch.SetRange("Document No.", PurchaseHeaderOrder."No.");
        ItemChargeAssignmentPurch.FindFirst();
        ItemChargeAssignmentPurch.TestField("Qty. to Assign", Round(Qty * 2 / 3, UOMMgt.QtyRndPrecision()));
        ItemChargeAssignmentPurch.TestField("Amount to Assign", Round(Qty * UnitCost * 2 / 3, LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [HandlerFunctions('QtyToAssgnItemChargeModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PartialPurchInvoicePostingClearsQtyToAssignThatIsLessThanAssignedInInvoice()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        Qty: Decimal;
        UnitCost: Decimal;
    begin
        // [FEATURE] [Purchase Order] [Item Charge] [Get Receipt Lines]
        // [SCENARIO 283749] When you invoice purchase order by a separate document, and the quantity of item charge assigned in the invoice is greater than the assigned quantity in the order, this zeroes out Qty. to Assign in the order.
        Initialize();

        Qty := LibraryRandom.RandIntInRange(10, 20);
        UnitCost := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Create Purch. Order with item and item charge lines. Quantity = 10 for both lines.
        CreatePurchaseHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order);
        CreatePurchaseLineWithDirectUnitCost(
          PurchaseLine, PurchaseHeaderOrder, PurchaseLine.Type::Item, CreateItem(), Qty, UnitCost);
        CreatePurchaseLineWithDirectUnitCost(
          PurchaseLine, PurchaseHeaderOrder, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), Qty, UnitCost);

        // [GIVEN] Open Item Charge Assignment and set Qty to Assign = 5.
        OpenItemChargeAssgnt(PurchaseLine, true, Qty / 2);

        // [GIVEN] Receive the purchase order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [GIVEN] Create Purch. Invoice using "Get Receipt Lines".
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, PurchaseHeaderOrder."Buy-from Vendor No.");
        PurchRcptLine.SetRange("Order No.", PurchaseHeaderOrder."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [GIVEN] Open Item Charge Assignment on the invoice line and set "Qty. to Assign" = 10.
        FindPurchaseLineWithType(
          PurchaseLine, PurchaseHeaderInvoice."No.", PurchaseHeaderInvoice."Document Type", PurchaseLine.Type::"Charge (Item)");
        OpenItemChargeAssgnt(PurchaseLine, true, Qty);

        // [WHEN] Post Purch. Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] "Qty. to Assign" = 0 on the purchase order line for the item charge.
        ItemChargeAssignmentPurch.SetRange("Document Type", ItemChargeAssignmentPurch."Document Type"::Order);
        ItemChargeAssignmentPurch.SetRange("Document No.", PurchaseHeaderOrder."No.");
        ItemChargeAssignmentPurch.FindFirst();
        ItemChargeAssignmentPurch.TestField("Qty. to Assign", 0);
        ItemChargeAssignmentPurch.TestField("Amount to Assign", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptNavigateDocumentNo()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        NoSeries: Codeunit "No. Series";
        Navigate: TestPage Navigate;
        PurchRcptNo: Code[20];
    begin
        // [FEATURE] [Purchase] [UT] [UI]
        // [SCENARIO 286007] Navigate page opened from Posted Purchase Receipt page has Document No. filter equal to
        Initialize();

        // [GIVEN] Purchase order with Purchase Line having Location with "Require Recieve" set to TRUE
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        // [GIVEN] Posted Warehouse Receipt with No "X" and Posted Whse. Receipt Line
        PurchRcptNo := NoSeries.PeekNextNo(PurchaseHeader."Receiving No. Series");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        ReceiveWarehouseDocument(PurchaseHeader."No.", PurchaseLine."Line No.");

        // [WHEN] Navigate page is opened from Posted Purchase Receipt
        Navigate.Trap();
        PurchRcptHeader.Get(PurchRcptNo);
        PurchRcptHeader.Navigate();

        // [THEN] Filter "Document No" on page Navigate is equal to "X"
        Assert.AreEqual(PurchRcptNo, Navigate.FILTER.GetFilter("Document No."), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure CancelChangePayToVendorNoWhenValidateBuyFromVendorNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PayToVendNo: Code[20];
    begin
        // [FEATURE] [UI] [UT] [Pay-to Vendor]
        // [SCENARIO 288106] Stan validates Buy-from Vendor No in Purchase Document and cancels change of Pay-to Vendor No
        Initialize();

        // [GIVEN] Purchase Invoice with a Line
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // [GIVEN] Stan confirmed change of Pay-to Vendor No. and line recalculation in Purchase Invoice
        PayToVendNo := LibraryPurchase.CreateVendorNo();
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        PurchaseHeader.Validate("Pay-to Vendor No.", PayToVendNo);
        PurchaseHeader.Modify(true);

        // [GIVEN] Stan validated Buy-from Vendor No. in Purchase Invoice
        LibraryVariableStorage.Enqueue(false);
        PurchaseHeader.Validate("Buy-from Vendor No.");

        // [WHEN] Stan cancels change of Pay-to Vendor No.
        // done in ConfirmHandlerYesNo

        // [THEN] Pay-to Vendor No. is not changed in Purchase Invoice
        PurchaseHeader.TestField("Pay-to Vendor No.", PayToVendNo);

        // [THEN] No other confirmations pop up and no errors
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToInvoiceDistributedEvenlyOnChargeAssgnmtWhilePartialyPostingPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemChargePurchLine: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        QtyToAssign: Decimal;
        ItemChargeUnitCost: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Purchase Order] [Item Charge]
        // [SCENARIO 291232] When partialy received Purchase Order with Charge Assignment is Invoiced partialy, Qty. to Assign is adjusted automatically.
        Initialize();

        // [GIVEN] Create Item Charge
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Create Purch. Order with 3 item and 1 item charge lines.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        for i := 1 to 3 do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), 10);
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
            PurchaseLine.Modify(true);
        end;
        LibraryPurchase.CreatePurchaseLine(
          ItemChargePurchLine, PurchaseHeader, ItemChargePurchLine.Type::"Charge (Item)", ItemCharge."No.", 9);
        ItemChargeUnitCost := LibraryRandom.RandDec(10, 2);
        ItemChargePurchLine.Validate("Direct Unit Cost", ItemChargeUnitCost);
        ItemChargePurchLine.Validate("Qty. to Receive", 6);
        ItemChargePurchLine.Modify(true);

        // [GIVEN] Create 3 Item Charge Assignment lines and set Qty to Assign with distribution by lines 4:4:1 respectively
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        i := 0;
        repeat
            i += 1;
            if i in [1, 2] then
                QtyToAssign := 4;
            if i = 3 then
                QtyToAssign := 1;
            LibraryPurchase.CreateItemChargeAssignment(
              ItemChargeAssignmentPurch, ItemChargePurchLine, ItemCharge, PurchaseHeader."Document Type",
              PurchaseHeader."No.", PurchaseLine."Line No.", PurchaseLine."No.", QtyToAssign, ItemChargeUnitCost);
            ItemChargeAssignmentPurch.Insert(true);
            PurchaseLine.Validate("Qty. to Receive", LibraryRandom.RandInt(5));
            PurchaseLine.Modify();
        until PurchaseLine.Next() = 0;

        // [GIVEN] Post Purch. Order as a Receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Post Purch. Order as Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] No error occurs, which means that distribution has been made correctly.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingInvoiceFilledWithGetReceiptLinesFromMultipleReceivings()
    var
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemChargePurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        // [FEATURE] [Purchase Order] [Item Charge] [Get Receipt Lines]
        // [SCENARIO 290332] Posting invoice filled with Get Receipt lines doesn't raise an error when item and its charge were received separately.
        Initialize();

        // [GIVEN] Create Item Charge
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Purchase Order with 1 item and 1 item charge lines.
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeaderOrder, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          ItemChargePurchLine, PurchaseHeaderOrder, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.",
          LibraryRandom.RandIntInRange(1, PurchaseLine.Quantity));

        // [GIVEN] Item charge assigned to item
        LibraryPurchase.CreateItemChargeAssignment(
          ItemChargeAssignmentPurch, ItemChargePurchLine, ItemCharge, PurchaseHeaderOrder."Document Type", PurchaseHeaderOrder."No.",
          PurchaseLine."Line No.", PurchaseLine."No.", ItemChargePurchLine.Quantity, LibraryRandom.RandInt(100));
        ItemChargeAssignmentPurch.Insert(true);

        // [GIVEN] Item and it assigned charge are received separately
        ItemChargePurchLine.Validate("Qty. to Receive", 0);
        ItemChargePurchLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        ItemChargePurchLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [GIVEN] Get Receipt Lines is run for Purchase Invoice
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, PurchaseHeaderOrder."Buy-from Vendor No.");

        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchaseHeaderInvoice."Buy-from Vendor No.");
        PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [WHEN] Post the purchase invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Purchase line with item is fully posted.
        PurchaseLine.Find();
        PurchaseLine.TestField("Quantity Invoiced", PurchaseLine.Quantity);

        // [THEN] Purchase line with item charge is fully assigned and posted.
        ItemChargePurchLine.Find();
        ItemChargePurchLine.TestField("Quantity Invoiced", ItemChargePurchLine.Quantity);
        ItemChargePurchLine.CalcFields("Qty. Assigned");
        ItemChargePurchLine.TestField("Qty. Assigned", ItemChargePurchLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentLineDescriptionToGLEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [G/L Entry] [Description]
        // [SCENARIO 300843] G/L account type document line Description is copied to G/L entry when PurchasSetup."Copy Line Descr. to G/L Entry" = "Yes"
        Initialize();

        // [GIVEN] Set PurchaseSetup."Copy Line Descr. to G/L Entry" = "Yes"
        SetPurchSetupCopyLineDescrToGLEntry(true);

        // [GIVEN] Create purchase order with 5 "G/L Account" type purchase lines with unique descriptions "Descr1" - "Descr5"
        CreatePurchOrderWithUniqueDescriptionLines(PurchaseHeader, TempPurchaseLine, TempPurchaseLine.Type::"G/L Account");

        // [WHEN] Purchase order is being posted
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L entries created with descriptions "Descr1" - "Descr5"
        VerifyGLEntriesDescription(TempPurchaseLine, InvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CombineGLEntriesForTheSameAccountIfCopyDocumentLineDescrToGLEntryIsFalse()
    var
        PurchaseHeader: Record "Purchase Header";
        AccountNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [G/L Entry] [Description]
        // [SCENARIO 300843] G/L account type lines combined  to single G/L entry when PurchasSetup."Copy Line Descr. to G/L Entry" = "No"
        Initialize();

        // [GIVEN] Set PurchaseSetup."Copy Line Descr. to G/L Entry" = "No"
        SetPurchSetupCopyLineDescrToGLEntry(false);

        // [GIVEN] Create purchase order with sereval "G/L Account" type purchase lines with unique descriptions "Descr1" - "Descr5"
        AccountNo := CreatePurchOrderWithSameAccountLines(PurchaseHeader, "Purchase Line Type"::"G/L Account", 3);

        // [WHEN] Purchase order is being posted
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] One G/L entry created for combined lines
        VerifyCombinedGLEntries(InvoiceNo, AccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendCopyDocumentLineDescriptionToGLEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        ERMPurchaseOrder: Codeunit "ERM Purchase Order";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [G/L Entry] [Description] [Event]
        // [SCENARIO 300843] Event InvoicePostBuffer.OnAfterInvPostBufferPreparePurchase can be used to copy document line Description for line type Item
        Initialize();

        // [GIVEN] Subscribe on InvoicePostBuffer.OnAfterInvPostBufferPreparePurchase
        BINDSUBSCRIPTION(ERMPurchaseOrder);

        // [GIVEN] Set PurchaseSetup."Copy Line Descr. to G/L Entry" = "No"
        SetPurchSetupCopyLineDescrToGLEntry(false);

        // [GIVEN] Create purchase order with 5 "Item" type purchase lines with unique descriptions "Descr1" - "Descr5"
        CreatePurchOrderWithUniqueDescriptionLines(PurchaseHeader, TempPurchaseLine, TempPurchaseLine.Type::Item);

        // [WHEN] Purchase order is being posted
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L entries created with descriptions "Descr1" - "Descr5"
        VerifyGLEntriesDescription(TempPurchaseLine, InvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckNotHandlerCreationPurchaseOrderForFixedAssets()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [FEATURE] [Purchase Order]
        // [SCENARIO 320976] For Non-inventoriable item type changing Location Code to new one in Purchase Order should not send notification

        Initialize();

        // [GIVEN] My Notification for Posting Setup is created and enabled
        SetupMyNotificationsForPostingSetup();

        // [GIVEN] New Location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Purchase Order is created with Type = "Fixed Asset"
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateItem());
        PurchaseLine.Validate(Type, PurchaseLine.Type::"Fixed Asset");

        // [WHEN] Change Location Code to Location.Code value
        PurchaseLine.Validate("Location Code", Location.Code);

        // [THEN] The Massage handled successfully
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure CheckNotHandlerCreationPurchaseOrderForItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [FEATURE] [Purchase Order]
        // [SCENARIO 320976] For Non-inventoriable item type changing Location Code to new one in Purchase Order should send notification

        Initialize();

        // [GIVEN] My Notification for Posting Setup is created and enabled
        SetupMyNotificationsForPostingSetup();

        // [GIVEN] New Location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Purchase Order is created with Type = Item
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateItem());

        // [WHEN] Change Location Code to Location.Code value
        PurchaseLine.Validate("Location Code", Location.Code);

        // [THEN] The Massage handled successfully
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptLineChargeItem()
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemCharge: Record "Item Charge";
    begin
        // [FEATURE] [Undo receipt] [Item charge]
        // [SCENARIO 289385] Stan is able to undo receipt for purchase receipt line of Charge (Item) type
        Initialize();

        // [GIVEN] Create and post receipt of purchase order with Charge (Item) type line
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreatePostPurchOrderForUndoReceipt(
            PurchaseLine,
            VATPostingSetup,
            PurchaseLine.Type::"Charge (Item)",
            ItemCharge."No.");

        FindPurchReceiptLine(PurchRcptLine, PurchaseLine."Document No.");

        // [WHEN] Undo purchase receipt
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] Verify Quantity after Undo Receipt
        VerifyUndoReceiptLineOnPostedReceipt(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptLineGLAccount()
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Undo receipt] [G/L Account]
        // [SCENARIO 289385] Stan is able to undo receipt for purchase receipt line of G/L Account type
        Initialize();

        // [GIVEN] Create and post receipt of purchase order with G/L Account type line
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePostPurchOrderForUndoReceipt(
            PurchaseLine,
            VATPostingSetup,
            PurchaseLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithPurchSetup());

        FindPurchReceiptLine(PurchRcptLine, PurchaseLine."Document No.");

        // [WHEN] Undo purchase receipt
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] Verify Quantity after Undo Receipt
        VerifyUndoReceiptLineOnPostedReceipt(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReturnShipmentLineChargeItem()
    var
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemCharge: Record "Item Charge";
    begin
        // [FEATURE] [Undo shipment] [Item charge]
        // [SCENARIO 289385] Stan is able to undo receipt for purchase receipt line of Charge (Item) type
        Initialize();

        // [GIVEN] Create and post return shipment of purchase return order with Charge (Item) type line
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreatePostPurchReturnOrderForUndoShipment(
            PurchaseLine,
            VATPostingSetup,
            PurchaseLine.Type::"Charge (Item)",
            ItemCharge."No.");

        FindPurchReturnShipmentLine(ReturnShipmentLine, PurchaseLine."Document No.");

        // [WHEN] Undo purchase receipt
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);

        // [THEN] Verify Quantity after Undo Shipment on Posted Return Shipment
        VerifyUndoReceiptLineOnPostedReturnShipment(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReturnShipmentLineGLAccount()
    var
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Undo shipment] [G/L Account]
        // [SCENARIO 289385] Stan is able to undo receipt for purchase receipt line of G/L Account type
        Initialize();

        // [GIVEN] Create and post return shipment of purchase return order with G/L Account type line
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePostPurchReturnOrderForUndoShipment(
            PurchaseLine,
            VATPostingSetup,
            PurchaseLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithPurchSetup());

        FindPurchReturnShipmentLine(ReturnShipmentLine, PurchaseLine."Document No.");

        // [WHEN] Undo purchase receipt
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);

        // [THEN] Verify Quantity after Undo Shipment on Posted Return Shipment
        VerifyUndoReceiptLineOnPostedReturnShipment(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('PostOrderStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostAndNew()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseOrder2: TestPage "Purchase Order";
        NoSeries: Codeunit "No. Series";
        NextDocNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 293548] Action "Post and new" opens new order after posting the current one
        Initialize();

        // [GIVEN] Purchase Order card is opened with order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] Action "Post and new" is being clicked
        PurchaseOrder2.Trap();
        PurchSetup.Get();
        NextDocNo := NoSeries.PeekNextNo(PurchSetup."Order Nos.");
        LibraryVariableStorage.Enqueue(3); // receive and invoice
        PurchaseOrder.PostAndNew.Invoke();

        // [THEN] Purchase order page opened with new invoice
        PurchaseOrder2."No.".AssertEquals(NextDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullDocTypeName()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Get full document type and name
        // [GIVEN] Purchase Header of type "Order"
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Purchase Order' is returned
        Assert.AreEqual('Purchase Order', PurchaseHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLine_FindRecordByDescription_Resource()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
        No: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Find Record By Description] [Resource]
        // [SCENARIO 289386] Purchase Line's Resource validation can be done using "Description" field
        Initialize();
        No := 'RES_TEST_RES';
        Description := 'Description(Test)Description';

        // [GIVEN] Resource "RESOURCE" with "Description" = "(Desc)"
        LibraryResource.CreateResourceNew(Resource);
        Resource.Rename(No);
        Resource.Validate(Name, 'Description(Test)Description');
        Resource.Modify(true);

        // [GIVEN] Purchase order with resource line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Resource);

        // [WHEN] Validate purchase line's "Description" = "resource"/"desc"/"res"/"des"/"ource"/"esc"/"xesc"

        // [THEN] Purchase line's: "No." = "RESOURCE", "Description" = "(Desc)"
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'res_test_res', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'description(test)description', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'res_test', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'description(test', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'test_res', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'test)description', No, Description);
        VerifyPurchaseLineFindRecordByDescription(PurchaseLine, 'discriptyon(tezt)discriptyon', No, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceJournalLineCopyFromPurchaseHeaderUT()
    var
        PurchaseHeader: Record "Purchase Header";
        ReasonCode: Record "Reason Code";
        ResJournalLine: Record "Res. Journal Line";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Resource journal line fields are filled from the purchase header
        Initialize();

        // [GIVEN] Purchase header: "Document Date" = WD + 1, "Posting Date" = WD + 2, "Reason Code" = "RC1".
        LibraryERM.CreateReasonCode(ReasonCode);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader."Document Date" := WorkDate() + 1;
        PurchaseHeader."Posting Date" := WorkDate() + 2;
        PurchaseHeader.Validate("Reason Code", ReasonCode.Code);
        PurchaseHeader.Modify(true);

        // [WHEN] Run function "CopyFrom" in "Res. Journal Line"
        ResJournalLine.CopyFrom(PurchaseHeader);

        // [THEN] "Res. Journal Line"."Document Date" = "Purchase Header"."Document Date"
        Assert.AreEqual(PurchaseHeader."Document Date", ResJournalLine."Document Date", CopyFromPurchaseErr);
        // [THEN] "Res. Journal Line"."Posting Date" = "Purchase Header"."Posting Date"
        Assert.AreEqual(PurchaseHeader."Posting Date", ResJournalLine."Posting Date", CopyFromPurchaseErr);
        // [THEN] "Res. Journal Line"."Reason Code" = "Purchase Header"."Reason Code"
        Assert.AreEqual(PurchaseHeader."Reason Code", ResJournalLine."Reason Code", CopyFromPurchaseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceJournalLineCopyFromPurchaseLineUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
        ResJournalLine: Record "Res. Journal Line";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Resource journal line fields are filled from the purchase line
        Initialize();

        // [GIVEN] Purchase line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, Resource."No.", LibraryRandom.RandIntInRange(5, 10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Qty. to Invoice", LibraryRandom.RandIntInRange(1, 4));
        PurchaseLine.Modify(true);

        // [WHEN] Run function "CopyFrom" in "Res. Journal Line"
        ResJournalLine.CopyFrom(PurchaseLine);

        // [THEN] "Res. Journal Line" fields are filled from purchase line
        VerifyResJournalLineCopiedFromPurchaseLine(ResJournalLine, PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineValidateNoWithResource()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Purchase line fields are filled from resource
        Initialize();

        // [GIVEN] Resource
        LibraryResource.CreateResourceNew(Resource);
        Resource.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        Resource.Modify(true);

        // [GIVEN] Purchase line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := LibraryUtility.GetNewRecNo(PurchaseLine, PurchaseLine.FieldNo("Line No."));
        PurchaseLine.Type := PurchaseLine.Type::Resource;
        PurchaseLine.Insert();

        // [WHEN] Validate "Purchase Line"."No." with resource
        PurchaseLine.Validate("No.", Resource."No.");

        // [THEN] "Purchase Line" fields are filled from resource
        VerifyPurchaseLineCopiedFromResource(PurchaseLine, Resource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineValidateNoWithBlockedResource()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Error when validate "Purchase Line"."No." with blocked resource
        Initialize();

        // [GIVEN] Blocked resource
        LibraryResource.CreateResourceNew(Resource);
        Resource.Validate(Blocked, true);
        Resource.Modify(true);

        // [GIVEN] Purchase line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := LibraryUtility.GetNewRecNo(PurchaseLine, PurchaseLine.FieldNo("Line No."));
        PurchaseLine.Type := PurchaseLine.Type::Resource;
        PurchaseLine.Insert();

        // [WHEN] Validate "Purchase Line"."No." with blocked resource
        asserterror PurchaseLine.Validate("No.", Resource."No.");

        // [THEN] Error "Blocked must be equal to 'No'  in Resource: No.= ***. Current value is 'Yes'."
        Assert.ExpectedTestFieldError(Resource.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ResourceListPageHandler')]
    procedure PurchaseLineResourceTableRelation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Lookup "No." field from purchase line with resource
        Initialize();

        // [GIVEN] Purchase order with resource line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, '', LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(PurchaseLine."No.");

        // [WHEN] Lookup "No." from resource line
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);
        PurchaseOrder.PurchLines."No.".Lookup();

        // [THEN] "Resource List" page is run (ResourceListPageHandler)
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ResourceListPageHandler')]
    procedure PurchaseInvLineResourceTableRelation()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Lookup "No." field from posted purchase invoice line with resource
        Initialize();

        // [GIVEN] Mocked posted purchase invoice with resource line
        MockPostedPurchaseInvoice(PurchInvHeader, PurchInvLine);
        LibraryVariableStorage.Enqueue(PurchInvLine."No.");

        // [WHEN] Lookup "No." from resource line
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.GoToRecord(PurchInvHeader);
        PostedPurchaseInvoice.PurchInvLines."No.".Lookup();

        // [THEN] "Resource List" page is run (ResourceListPageHandler)
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ResourceListPageHandler')]
    procedure PurchaseCrMemoLineResourceTableRelation()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Lookup "No." field from posted purchase credit memo line with resource
        Initialize();

        // [GIVEN] Mocked posted purchase invoice with resource line
        MockPostedPurchaseCrMemo(PurchCrMemoHdr, PurchCrMemoLine);
        LibraryVariableStorage.Enqueue(PurchCrMemoLine."No.");

        // [WHEN] Lookup "No." from resource line
        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.GoToRecord(PurchCrMemoHdr);
        PostedPurchaseCreditMemo.PurchCrMemoLines."No.".Lookup();

        // [THEN] "Resource List" page is run (ResourceListPageHandler)
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ResourceListPageHandler')]
    procedure PurchaseReceiptLineResourceTableRelation()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Lookup "No." field from posted purchase receipt line with resource
        Initialize();

        // [GIVEN] Mocked posted purchase invoice with resource line
        MockPostedPurchaseReceipt(PurchRcptHeader, PurchRcptLine);
        LibraryVariableStorage.Enqueue(PurchRcptHeader."No.");

        // [WHEN] Lookup "No." from resource line
        PostedPurchaseReceipt.OpenView();
        PostedPurchaseReceipt.GoToRecord(PurchRcptHeader);
        PostedPurchaseReceipt.PurchReceiptLines."No.".Lookup();

        // [THEN] "Resource List" page is run (ResourceListPageHandler)
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ResourceListPageHandler')]
    procedure PurchaseReturnShptResourceTableRelation()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnShipmentLine: Record "Return Shipment Line";
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Lookup "No." field from posted purchase return shipment line with resource
        Initialize();

        // [GIVEN] Mocked posted purchase invoice with resource line
        MockPostedReturnShpt(ReturnShipmentHeader, ReturnShipmentLine);
        LibraryVariableStorage.Enqueue(ReturnShipmentLine."No.");

        // [WHEN] Lookup "No." from resource line
        PostedReturnShipment.OpenView();
        PostedReturnShipment.GoToRecord(ReturnShipmentHeader);
        PostedReturnShipment.ReturnShptLines."No.".Lookup();

        // [THEN] "Resource List" page is run (ResourceListPageHandler)
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithResourceAndResourceCost()
    var
        PriceListLine: Record "Price List Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
        ResourceCost: Record "Resource Cost";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
    begin
        // [FEATURE] [Resource] [Resource Cost]
        // [SCENARIO 341999] "Direct Unit Cost" in the purchase line is filled from the resource cost
        Initialize();

        // [GIVEN] Resource "R"
        LibraryResource.CreateResourceNew(Resource);

        // [GIVEN] Resource cost "RC"
        ResourceCost.Init();
        ResourceCost.Validate(Type, ResourceCost.Type::Resource);
        ResourceCost.Validate(Code, Resource."No.");
        ResourceCost.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(200, 300));
        ResourceCost.Insert(true);
        CopyFromToPriceListLine.CopyFrom(ResourceCost, PriceListLine);

        // [WHEN] Create purchase order with "R"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10));

        // [THEN] "Direct Unit Cost" = "RC"
        Assert.AreEqual(PurchaseLine."Direct Unit Cost", ResourceCost."Direct Unit Cost", 'Wrong resource cost');
    end;

    [Test]
    [HandlerFunctions('ImplementStandardCostChangesHandler,MessageHandler')]
    procedure T280_ImplementResourceStandardCostChanges()
    var
        ResourceCost: Record "Resource Cost";
        Resource: Record Resource;
        NewStdCost: Decimal;
    begin
        Initialize();
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        // [GIVEN] Resource 'R', where "Direct Unit Cost" is 100
        LibraryResource.CreateResource(Resource, '');

        // [GIVEN] ResourceCost, where for 'R'
        ResourceCost.Validate(Type, ResourceCost.Type::Resource);
        ResourceCost.Validate(Code, Resource."No.");
        ResourceCost.Validate("Cost Type", ResourceCost."Cost Type"::Fixed);
        ResourceCost.Validate("Direct Unit Cost", Resource."Direct Unit Cost" + 1);
        ResourceCost.Validate("Unit Cost", Resource."Direct Unit Cost");
        ResourceCost.Insert();

        // [WHEN] Implement Standard Cost Change, where "New Standard Cost" is 111
        NewStdCost := Resource."Direct Unit Cost" + LibraryRandom.RandDec(100, 2);
        ImplementStandardCostChanges(Resource, Resource."Direct Unit Cost", NewStdCost);

        // [THEN] ResourceCost is updated: "Direct Unit Cost" is 100, "Unit Cost" is 111
        ResourceCost.Find();
        ResourceCost.TestField("Direct Unit Cost", Resource."Direct Unit Cost");
        ResourceCost.TestField("Unit Cost", NewStdCost);
    end;

    [Test]
    [HandlerFunctions('ExplodeBOMHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderExplodeBOMWithResource()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BOMComponent: Record "BOM Component";
    begin
        // [FEATURE] [Resource] [BOM]
        // [SCENARIO 341999] Explode BOM with resource component
        Initialize();

        // [GIVEN] Item with resource BOM component
        LibraryInventory.CreateBOMComponent(BOMComponent, LibraryInventory.CreateItemNo(), BOMComponent.Type::Resource, LibraryResource.CreateResourceNo(), 1, '');

        // [GIVEN] Purchase order with item
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, BOMComponent."Parent Item No.", LibraryRandom.RandInt(10));

        // [WHEN] Explode BOM
        LibraryPurchase.ExplodeBOM(PurchaseLine);

        // [THEN] Purchase line with resource BOM component created
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Resource);
        PurchaseLine.SetRange("No.", BOMComponent."No.");
        Assert.RecordCount(PurchaseLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure RecreatePurchCommentLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        // [FEATURE] [Purch Comment Line] [UT]
        // [SCENARIO 351187] The Purch. Comment Lines must be copied after Purchase Lines have been recreated
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::Item, LibraryInventory.CreateItemNo(), 1);
        LibraryPurchase.CreatePurchCommentLine(PurchCommentLine, "Purchase Document Type"::Order, PurchaseHeader."No.", PurchaseLine."Line No.");

        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());
        // [SCENARIO 360476] No duplicate Comment Lines inserted
        Commit();

        VerifyCountPurchCommentLine(PurchaseHeader."Document Type", PurchaseHeader."No.", 10000);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure RecreatePurchCommentLineForPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        // [FEATURE] [Purch Comment Line] [UT]
        // [SCENARIO 399071] The Purch. Comment Lines must be copied after Purchase Lines have been recreated if Purchase Line No. < 10000
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreateSimplePurchLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::Item, 5000);
        PurchaseLine.Validate("No.", LibraryInventory.CreateItemNo());
        PurchaseLine.Validate(Quantity, 1);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchCommentLine(PurchCommentLine, "Purchase Document Type"::Order, PurchaseHeader."No.", PurchaseLine."Line No.");
        LibraryPurchase.CreatePurchCommentLine(PurchCommentLine, "Purchase Document Type"::Order, PurchaseHeader."No.", 0);

        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());
        Commit();

        VerifyCountPurchCommentLine(PurchaseHeader."Document Type", PurchaseHeader."No.", 10000);
        VerifyCountPurchCommentLine(PurchaseHeader."Document Type", PurchaseHeader."No.", 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithVerification')]
    [Scope('OnPrem')]
    procedure RevertCurrencyCodeWhenRefusedToRecreateSalesLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UT] [Currency] [FCY]
        // [SCENARIO 347892] System throws error and reverts entered "Currency Code" when Stan refused to recreate existing purchase lines on Purchase Order
        Initialize();

        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseHeader.TestField("Currency Code", '');
        Commit();

        PurchaseOrder.Trap();
        PAGE.Run(PAGE::"Purchase Order", PurchaseHeader);

        PurchaseOrder."No.".AssertEquals(PurchaseHeader."No.");
        PurchaseOrder."Currency Code".AssertEquals('');

        LibraryVariableStorage.Enqueue(StrSubstNo(RecreatePurchaseLinesQst, PurchaseHeader.FieldCaption("Currency Code")));
        LibraryVariableStorage.Enqueue(false);
        asserterror PurchaseOrder."Currency Code".SetValue(LibraryERM.CreateCurrencyWithRandomExchRates());

        Assert.ExpectedError(StrSubstNo(RecreatePurchaseLinesCancelErr, PurchaseHeader.FieldCaption("Currency Code")));

        PurchaseOrder."Currency Code".AssertEquals('');
        PurchaseOrder.Close();

        PurchaseHeader.Find();
        PurchaseHeader.TestField("Currency Code", '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentMethodCodeOnPoWorksForVendorWithPayToNo()
    var
        Vendor: array[2] of Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 360277] Shipment Method Code of Purchase Order fills in even if Vendor has Pay-To Vendor No. of another Vendor
        Initialize();

        // [GIVEN] Vendor "V2" with Shipment Method Code "SMC2"
        CreateVendorWithShipmentMethodCode(Vendor[2]);

        // [GIVEN] Vendor "V1" with Shipment Method Code "SMC1" and Pay-to Vendor = V2
        CreateVendorWithShipmentMethodCode(Vendor[1]);
        Vendor[1].Validate("Pay-to Vendor No.", Vendor[2]."No.");
        Vendor[1].Modify();

        // [WHEN] Create Purchase Order with "Vendor No." = "V1"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor[1]."No.");

        // [THEN] Shipment Method Code = "SMC1"
        PurchaseHeader.TestField("Shipment Method Code", Vendor[1]."Shipment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPurchaseOrderReceiveWithDisposedAssetError()
    var
        FADeprBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DepreciationCalc: Codeunit "Depreciation Calculation";
    begin
        // [FEATURE] [Fixed Asset]
        // [SCENARIO 359820] It's not possible to Post Receive Purchase Order with disposed Fixed Asset.
        Initialize();

        // [GIVEN] Disposed Fixed Asset, Fixed Asset No. = FA01, Depreciation Book Code = DEPRBOOK.
        MockFixedAsset(FADeprBook, true);
        Commit();

        // [GIVEN] Purchase Order with Purchase Line with disposed Fixed Asset.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FADeprBook."FA No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Depreciation Book Code", FADeprBook."Depreciation Book Code");
        PurchaseLine.Modify(true);

        // [WHEN] Post Receive Purchase Order.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Error is shown with text "Fixed Asset No. = FA01 in Depreciation Book Code = DEPRBOOK is disposed".
        Assert.ExpectedErrorCode('Dialog');
        FixedAsset.Get(FADeprBook."FA No.");
        Assert.ExpectedError(STRSUBSTNO(DisposedErr, DepreciationCalc.FAName(FixedAsset, FADeprBook."Depreciation Book Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPurchaseOrderPartialReceiveWithDisposedAssetError()
    var
        FADeprBook: array[2] of Record "FA Depreciation Book";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
    begin
        // [FEATURE] [Fixed Asset]
        // [SCENARIO 457181] Purchase order with first received and disposed FA and second non-received FA can be posted
        Initialize();

        // [GIVEN] Create Fixed Asset, Fixed Asset No. = FA01, Depreciation Book Code = DEPRBOOK.
        MockFixedAsset(FADeprBook[1], false);
        // [GIVEN] Create Fixed Asset, Fixed Asset No. = FA02, Depreciation Book Code = DEPRBOOK.
        MockFixedAsset(FADeprBook[2], false);
        Commit();

        // [GIVEN] Purchase Order with two Purchase Lines for disposed and non-disposed FA
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine[1], PurchaseHeader, "Purchase Line Type"::"Fixed Asset", FADeprBook[1]."FA No.", 1);
        PurchaseLine[1].Validate("Depreciation Book Code", FADeprBook[1]."Depreciation Book Code");
        PurchaseLine[1].Modify(true);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine[2], PurchaseHeader, "Purchase Line Type"::"Fixed Asset", FADeprBook[2]."FA No.", 1);
        PurchaseLine[2].Validate("Depreciation Book Code", FADeprBook[2]."Depreciation Book Code");
        PurchaseLine[2].Modify(true);

        // [WHEN] Post first Fixed Asset as received and invoiced
        PurchaseLine[2].Get(PurchaseLine[2]."Document Type", PurchaseLine[2]."Document No.", PurchaseLine[2]."Line No.");
        PurchaseLine[2].Validate("Qty. to Receive", 0);
        PurchaseLine[2].Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Mark posted fixed asset as disposed
        FADeprBook[1].Get(FADeprBook[1]."FA No.", FADeprBook[1]."Depreciation Book Code");
        FADeprBook[1].Validate("Disposal Date", WorkDate());
        FADeprBook[1].Modify();

        // [THEN] Post purchase order as received and invoiced succesfully
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."Vendor Invoice No." + '-2');
        PurchaseHeader.Modify();
        PurchaseLine[2].Get(PurchaseLine[2]."Document Type", PurchaseLine[2]."Document No.", PurchaseLine[2]."Line No.");
        PurchaseLine[2].Validate("Qty. to Receive", 1);
        PurchaseLine[2].Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderAfterLastAccoutningPeriodWithAutomaticCostAdjustment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        AccountingPeriod: Record "Accounting Period";
        InventorySetup: Record "Inventory Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Item: Record Item;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Cost Adjustment]
        // It's possible to Post when posting date is greater than the last accounting period.
        Initialize();
        InventorySetup.FindFirst();
        InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Always;
        InventorySetup."Average Cost Period" := InventorySetup."Average Cost Period"::"Accounting Period";
        InventorySetup.Modify();

        // Setup: Create an Item and set the costing method to average
        Item.Get(CreateItem());
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify();

        // [GIVEN] Purchase Order with Purchase Line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        if not AccountingPeriod.FindLast() then begin
            CreateAccountingPeriod();
            AccountingPeriod.FindLast();
        end;
        PurchaseHeader.Validate("Posting Date", CalcDate('<2D>', AccountingPeriod."Starting Date"));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);

        // [WHEN] Post Invoice and Receive Purchase Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posting finishes successfully and vendor ledger entry can be found.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyInvNoToPmtRefExistsInPurchPayablesSetup()
    var
        PurchasesPayablesSetup: TestPage "Purchases & Payables Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 362612] A "Copy Inv. No. To Pmt. Ref." field is visible in the Purchases & Payables Setup page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        PurchasesPayablesSetup.OpenEdit();
        Assert.IsTrue(PurchasesPayablesSetup."Copy Inv. No. To Pmt. Ref.".Visible(), 'A field is not visible');
        PurchasesPayablesSetup.Close();

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    //[HandlerFunctions('ConfirmHandler')]
    procedure ErrorGLAccountMustHaveAValueIsShownForPurchaseOrderWithMissingGenBusPostingGroupInGLAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        // [FEATURE] [Invoice Rounding] [Posting Group]
        // [SCENARIO 391619] Create Purchase Order with missing "Invoice Rounding Account" in "Vendor Posting Group"
        Initialize();

        // [GIVEN] "Inv. Rounding Precision (LCY)" = 1 in General Ledger Setup
        LibraryERM.SetInvRoundingPrecisionLCY(1);
        LibraryPurchase.SetInvoiceRounding(true);

        // [GIVEN] Created Vendor with new Vendor Posting Group
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor.Modify(true);

        // [GIVEN] Delete "Gen. Prod. Posting Group" code from  "Invoice Rounding Account"
        GLAccount.Get(VendorPostingGroup."Invoice Rounding Account");
        GLAccount."Gen. Prod. Posting Group" := '';
        GLAccount.Modify();

        // [GIVEN] Created Purchase Order
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Order with Invoice Rounding Line
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Error has been thrown: "Gen. Prod. Posting Group  is not set for the Prepayment G/L account with no. XXXXX."
        Assert.ExpectedError(
          StrSubstNo(GenProdPostingGroupErr, PurchaseLine.FieldCaption("Gen. Prod. Posting Group"), GLAccount.Name, GLAccount."No."));
    end;

    [Test]
    procedure LocationForNonInventoryItemsAllowed()
    var
        ServiceItem: Record Item;
        NonInventoryItem: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] Create Purchase Order with non-inventory items having a location set is allowed.
        Initialize();

        // [GIVEN] A non-inventory item and a service item.
        LibraryInventory.CreateServiceTypeItem(ServiceItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] A location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Created Purchase Order for the non-inventory items with locations set.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, ServiceItem."No.", 1);
        PurchaseLine1.Validate("Location Code", Location.Code);
        PurchaseLine1.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, NonInventoryItem."No.", 1);
        PurchaseLine2.Validate("Location Code", Location.Code);
        PurchaseLine2.Modify(true);

        // [WHEN] Posting Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] An item ledger entry is created for non-inventory items with location set.
        ItemLedgerEntry.SetRange("Item No.", ServiceItem."No.");
        Assert.AreEqual(1, ItemLedgerEntry.Count, 'Expected only one ILE to be created.');
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(1, ItemLedgerEntry.Quantity, 'Expected quantity to be 1.');
        Assert.AreEqual(Location.Code, ItemLedgerEntry."Location Code", 'Expected location to be set.');

        ItemLedgerEntry.SetRange("Item No.", NonInventoryItem."No.");
        Assert.AreEqual(1, ItemLedgerEntry.Count, 'Expected only one ILE to be created.');
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(1, ItemLedgerEntry.Quantity, 'Expected quantity to be 1.');
        Assert.AreEqual(Location.Code, ItemLedgerEntry."Location Code", 'Expected location to be set.');
    end;


    [Test]
    procedure BinCodeNotAllowedForNonInventoryItems()
    var
        Item: Record Item;
        ServiceItem: Record Item;
        NonInventoryItem: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
    begin
        // [SCENARIO] Create purchase order with location for item and non-inventory items.
        // Bin code should only be possible to set for item.
        Initialize();

        // [GIVEN] An item, A non-inventory item and a service item.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateServiceTypeItem(ServiceItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] A location with require bin and a default bin code.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        LibraryWarehouse.CreateBinContent(
            BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure"
        );
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] A vendor with default location.
        LibraryPurchase.CreateVendorWithLocationCode(Vendor, Location.Code);

        // [GIVEN] Created Purchase Order for the item and non-inventory items.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, Item."No.", 1);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, ServiceItem."No.", 1);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine3, PurchaseHeader, PurchaseLine3.Type::Item, NonInventoryItem."No.", 1);

        // [THEN] Location is set for all lines and bin code is set for item.
        Assert.AreEqual(Location.Code, PurchaseLine1."Location Code", 'Expected location code to be set');
        Assert.AreEqual(Bin.Code, PurchaseLine1."Bin Code", 'Expected bin code to be set');

        Assert.AreEqual(Location.Code, PurchaseLine2."Location Code", 'Expected location code to be set');
        Assert.AreEqual('', PurchaseLine2."Bin Code", 'Expected no bin code set');

        Assert.AreEqual(Location.Code, PurchaseLine3."Location Code", 'Expected location code to be set');
        Assert.AreEqual('', PurchaseLine3."Bin Code", 'Expected no bin code set');

        // [WHEN] Setting bin code on non-inventory items.
        asserterror PurchaseLine2.Validate("Bin Code", Bin.Code);
        asserterror PurchaseLine3.Validate("Bin Code", Bin.Code);

        // [THEN] An error is thrown.
    end;

    [Test]
    procedure EditItemGenProdPostGroup()
    var
        Item: Record "Item";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GenProdPostingGroupCode: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO] When the column gen. prod. post. id is edited the column gen. prod. post. code is updated as well
        // [GIVEN] An item
        ItemNo := CreateItem();
        // [GIVEN] A Gen. Prod. Posting Group
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        Commit();
        GenProdPostingGroupCode := GenProdPostingGroup.Code;

        // [WHEN] it's assigned to a gen. prod. post. group through its id.
        Item.Validate("Gen. Prod. Posting Group Id", GenProdPostingGroup.SystemId);
        Commit();

        // [THEN] its gen. prod. post. group code is updated as well.
        GenProdPostingGroup.Get(Item."Gen. Prod. Posting Group");
        Assert.AreEqual(GenProdPostingGroupCode, GenProdPostingGroup.Code, 'The gen. prod. posting group code is not the same as assigned.');
    end;

    [Test]
    procedure EditItemInventoryPostGroup()
    var
        Item: Record "Item";
        InventoryPostingGroup: Record "Inventory Posting Group";
        InventoryPostingGroupCode: Code[20];
    begin
        // [SCENARIO] When the column gen. prod. post. id is edited the column gen. prod. post. code is updated as well
        // [GIVEN] An item
        CreateItem();
        // [GIVEN] A Gen. Prod. Posting Group
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        Commit();
        InventoryPostingGroupCode := InventoryPostingGroup.Code;

        // [WHEN] it's assigned to a gen. prod. post. group through its id.
        Item.Validate("Inventory Posting Group Id", InventoryPostingGroup.SystemId);
        Commit();

        // [THEN] its gen. prod. post. group code is updated as well with the corresponding code.
        InventoryPostingGroup.Get(Item."Inventory Posting Group");
        Assert.AreEqual(InventoryPostingGroupCode, InventoryPostingGroup.Code, 'The inventory posting group code is not the same as assigned.');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure RecreatePurchaseItemLineWithEmptyNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // [FEATURE]
        // [SCENARIO 414831] The purchase line with "No." = '' and Type <> 'Item' must be recreated when Vendor No. is changed
        Initialize();

        // [GIVEN] Item with empty description
        LibraryInventory.CreateItem(Item);
        Item.Description := '';
        Item.Modify();

        // [GIVEN] Purchase Order with Vendor No. = '10000' Purchase Line with Type = "Item" and "No." is blank
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 0);
        PurchaseLine.Validate("No.", '');
        PurchaseLine.Modify(true);

        // [WHEN] Change Vendor No. in Purchase Header
        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());

        // [THEN] Purchase Line with "No." = '' and Type = "Item" exists
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", '');
        Assert.RecordCount(PurchaseLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderRemitToNotEditableBeforeVendorSelected()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI]
        // [Scenario] Remit-to code Field on Purchase Order Page not editable if no vendor selected
        // [Given]
        Initialize();
        // [WHEN] Purchase Order page is opened
        PurchaseOrder.OpenNew();
        // [THEN] Field is not editable
        Assert.IsFalse(PurchaseOrder."Remit-to Code".Editable(), RemitToCodeShouldNotBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderRemitToEditableAfterVendorSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        VendorNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [Scenario] Remit-to code Field on Purchase Order Page  editable if vendor selected
        // [Given]
        Initialize();
        // [Given] A sample Purchase Order
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder."Buy-from Vendor No.".SetValue(VendorNo);
        // [THEN] Remit-to code Field is editable
        Assert.IsTrue(PurchaseOrder."Remit-to Code".Editable(), RemitToCodeShouldBeEditableErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderReportVerifyRemit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RemitAddress: Record "Remit Address";
        PurchaseOrderPage: TestPage "Purchase Order";
        VendorNo: Code[20];
        PurchaseHeaderNo: Code[20];
        RequestPageXML: Text;
    begin
        // [SCENARIO] Create a Purchase Order with Negative quanity, try to post and then delete.
        Initialize();
        // [GIVEN] Create a new Remit-to address
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreateRemitToAddress(RemitAddress, VendorNo);
        // [GIVEN] Purchase Order with one Item
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseHeaderNo := PurchaseHeader."No.";
        PurchaseHeader.Validate("Remit-to Code", RemitAddress.Code);
        PurchaseHeader.Modify(true);
        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.GotoRecord(PurchaseHeader);
        Commit();
        // [WHEN] Run report "Purchase - Order"
        RequestPageXML := REPORT.RunRequestPage(REPORT::"Purchase Document - Test", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(REPORT::"Purchase Document - Test", PurchaseHeader, RequestPageXML);
        // [THEN] TotalBalOnBankAccount has value 200
        LibraryReportDataset.AssertElementWithValueExists('RemitToAddress_Name', RemitAddress.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithVerification')]
    [Scope('OnPrem')]
    procedure UpdatePurchaseOrderDateWithoutUpdatingLinesOrderDates()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Order Date", today());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        Commit();
        LibraryVariableStorage.Enqueue(UpdateLinesOrderDateAutomaticallyQst);
        LibraryVariableStorage.Enqueue(false);
        PurchaseHeader.Validate("Order Date", today() + 1);
        LibraryVariableStorage.AssertEmpty();

        Assert.AreNotEqual(PurchaseHeader."Order Date", PurchaseLine."Order Date", 'The purchase order date should be different from the purchase line order date');
        Assert.AreEqual(PurchaseHeader."Order Date", today() + 1, StrSubstNo('The purchase order date should be %1. Instead, it is %2', (today() + 1), PurchaseHeader."Order Date"));
        Assert.AreEqual(PurchaseLine."Order Date", today(), StrSubstNo('The purchase line order date should be %1. Instead, it is %2', today(), PurchaseLine."Order Date"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithVerification')]
    [Scope('OnPrem')]
    procedure UpdatePurchaseOrderDateUpdatesLinesOrderDates()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        Initialize();

        LibraryWarehouse.CreateLocation(Location);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Order Date", Today());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        Commit();
        LibraryVariableStorage.Enqueue(UpdateLinesOrderDateAutomaticallyQst);
        LibraryVariableStorage.Enqueue(true);
        PurchaseHeader.Validate("Order Date", Today() + 1);
        PurchaseHeader.Modify(true);
        LibraryVariableStorage.AssertEmpty();
        PurchaseLine.GetBySystemId(PurchaseLine.SystemId);

        Assert.AreEqual(PurchaseHeader."Order Date", Today() + 1, StrSubstNo('The purchase order date should be %1. Instead, it is %2', (Today() + 1), PurchaseHeader."Order Date"));
        Assert.AreEqual(PurchaseHeader."Order Date", PurchaseLine."Order Date", StrSubstNo('The purchase order date (%1) should be the same as the purchase line order date (%2)', PurchaseHeader."Order Date", PurchaseLine."Order Date"));
        PurchaseLine.TestField("Location Code", Location.Code);
    end;

    [Test]
    [HandlerFunctions('GetSalesOrdersHandler,ItemVendorCatalogHandler,ExplodeBOMHandler')]
    procedure VerifySpecialSalesOrderLineValuesAreClearedOnExplodeBOMFromPurchaseOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        ItemNo: Code[20];
    begin
        // [SCENARIO: 440130] Verify Special Sales Order Line values are cleared on Explode BOM action from Purchase Order for Assembly Item
        // [GIVEN] Initialize
        Initialize();

        // [GIVEN] Create New Item with BOM Component
        ItemNo := CreateItemWithBOMComponent();

        // [GIVEN] Create Special Sales Order and Release
        CreateSpecialSalesOrderForItem(SalesHeader, SalesLine, ItemNo);

        // [GIVEN] Get Special Order on Requisition Worksheet and create Purchase Order
        // [HANDLERS] GetSalesOrdersHandler, ItemVendorCatalogHandler
        GetSpecialOrderOnRequisitionWorksheetAndCreatePurchaseOrder(Vendor);

        // [WHEN] Find Created Purchase records and Open Purchase Order
        OpenCreatedPurchaseOrder(PurchaseOrder, PurchaseLine, Vendor);

        // [THEN] Verify Special Purchase Order and Sales Order are connected
        Assert.IsTrue(PurchaseLine."Special Order", 'Not Special Order.');
        Assert.IsTrue(PurchaseLine."Special Order Sales No." = SalesHeader."No.", 'Orders are not connected.');
        Assert.IsTrue(PurchaseLine."Special Order Sales Line No." = SalesLine."Line No.", 'Orders are not connected.');
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", '10000');
        Assert.IsTrue(SalesLine."Special Order", 'Not Special Order.');
        Assert.IsTrue(SalesLine."Special Order Purch. Line No." = PurchaseLine."Line No.", 'Orders are not connected.');
        Assert.IsTrue(SalesLine."Special Order Purchase No." = PurchaseLine."Document No.", 'Orders are not connected.');

        // [WHEN] Call Explode BOM action
        // [HANDLER] ExplodeBOMHandler
        PurchaseOrder.PurchLines."E&xplode BOM".Invoke();

        // [THEN] Verify special values on Sales Order and Purchase Order are cleared
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", '10000');
        Assert.IsTrue(SalesLine."Special Order", 'Not Special Order.');
        Assert.IsTrue(SalesLine."Special Order Purch. Line No." = 0, 'Values are not cleared.');
        Assert.IsTrue(SalesLine."Special Order Purchase No." = '', 'Values are not cleared.');
        Clear(PurchaseLine);
        PurchaseLine.SetRange("Document No.", PurchaseOrder."No.".Value);
        PurchaseLine.FindSet();
        repeat
            Assert.IsTrue(PurchaseLine."Special Order Sales No." = '', 'Values are not cleared.');
            Assert.IsTrue(PurchaseLine."Special Order Sales Line No." = 0, 'Values are not cleared.');
        until PurchaseLine.Next() = 0;
    end;

    [Test]
    procedure VerifyShortcutDimensionValuesExistOnPurchaseOrderLineOnValidateLocation()
    var
        DimensionValue, DimensionValue2 : Record "Dimension Value";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARION: 454839] Verify Shortcut Dimension Values exists on Purchase Order line on validate Location Code
        // [GIVEN] Initialize
        Initialize();

        // [GIVEN] Create two dimensions with Values and set them to Shortcut Dimension 3 Code and Shortcut Dimension 4 Code on General Ledger Setup
        CreateDimensionAndSetupOnGeneralLedgerSetup(DimensionValue, DimensionValue2);

        // [GIVEN] Create Location and set default dimensions
        CreateLocationWithDefaultDimensions(Location, DimensionValue, DimensionValue2);

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Open Purchase Order
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        // [WHEN] Set Location on Purchase Line
        PurchaseOrder.PurchLines."Location Code".SetValue(Location.Code);

        // [THEN] Verify Dimension Values exists on Purchase Order Line
        PurchaseOrder.PurchLines.ShortcutDimCode3.AssertEquals(DimensionValue.Code);
        PurchaseOrder.PurchLines.ShortcutDimCode4.AssertEquals(DimensionValue2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyAttachedDocumentFromItemToPurchaseOrderWhenCarryOutActionMessage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";

        RecRef: RecordRef;
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        // [SCENARIO: 440130] When Item has attached document and user creates Purchase Order from Requisition Worksheet, then attached document is copied to Purchase Order
        // [GIVEN] Initialize
        Initialize();

        // [GIVEN] Create New Item and set replenishment system to Purchase
        LibraryInventory.CreateItem(Item);
        Item."Replenishment System" := Item."Replenishment System"::"Purchase";
        if Item."Vendor No." = '' then begin
            LibraryPurchase.CreateVendor(Vendor);
            Item.Validate("Vendor No.", Vendor."No.");
        end;
        Item.Modify();

        // [GIVEN] Attach document to Item
        RecRef.GetTable(Item);
        AttachDummyDocumentImageToRecord(RecRef, true, false);

        // [GIVEN] Create Requisition Worksheet Line with Item
        SelectRequisitionTemplateAndCreateReqWkshName(ReqWkshTemplate);
        OpenRequisitionWorksheetPage(ReqWorksheet, FindRequisitionWkshName(ReqWkshTemplate.Type::"Req."));
        ReqWorksheet.New();
        ReqWorksheet.Type.SetValue(RequisitionLine.Type::Item);
        ReqWorksheet."No.".SetValue(Item."No.");
        ReqWorksheet.Quantity.SetValue(Random(10));
        ReqWorksheet.Close();

        // [WHEN] Create Purchase Order from Requisition Worksheet
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();
        ReqWkshCarryOutActionMessage(RequisitionLine);

        // [THEN] Verify Purchase Order Line contains attached document
        CheckPurchaseOrderLineContainsAttachedDocument(Item);
    end;

    local procedure CheckPurchaseOrderLineContainsAttachedDocument(Item: Record Item)
    var
        PurchaseLine: Record "Purchase Line";
        DocumentAttachment: Record "Document Attachment";
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.FindLast();

        DocumentAttachment.SetCurrentKey("Table ID", "No.", "Document Type", "Line No.", ID);
        DocumentAttachment.SetRange("Table ID", Database::"Purchase Line");
        DocumentAttachment.SetRange("No.", PurchaseLine."Document No.");
        DocumentAttachment.SetRange("Document Type", PurchaseLine."Document Type");
        DocumentAttachment.SetRange("Line No.", PurchaseLine."Line No.");

        Assert.IsTrue(not DocumentAttachment.IsEmpty, 'Attachment is not copied to Purchase Order Line');
    end;

    [Test]
    procedure VerifyPurchaseOrderCanBeInvoicedOnRenamedResourseWhichExistOnPurchaseLine()
    var
        Purchaseheader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
    begin
        // [SCENARION: 452918] Verify Purchase Order can be invoiced on rename resource which exist on Purchase Line
        // [GIVEN] Initialize
        Initialize();

        // [GIVEN] Create Purchase Order with Resource Line
        CreatePurchaseOrderWithResourceLine(Purchaseheader, PurchaseLine, Resource);

        // [GIVEN] Post Purchase Receipt for created Purchase Order
        LibraryPurchase.PostPurchaseDocument(Purchaseheader, true, false);

        // [WHEN] Rename a Resource
        Resource.Rename(LibraryUtility.GenerateGUID());

        // [THEN] Verify Resource is renamed on Purchase Line
        PurchaseLine.Get(Purchaseheader."Document Type"::Order, Purchaseheader."No.", '10000');
        Assert.IsTrue(PurchaseLine."No." = Resource."No.", 'Resource is not renamed on Purchase Line');

        // [THEN] Verify Purchase Order can be invoiced
        LibraryPurchase.PostPurchaseDocument(Purchaseheader, false, true);
    end;

    [Test]
    procedure VerifyShippingDataAreReturnedToDefaultWhenUserSwitchFromCustomAddressToDefaultOption()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CompanyInformation: Record "Company Information";
        PurchaseOrder: TestPage "Purchase Order";
        ShipToOptions: Option "Default (Company Address)",Location,"Customer Address","Custom Address";
    begin
        // [SCENARION: 459002] Verify Shipping Data are returned to default when user switch Ship-to option from Custom Address to Default
        // [GIVEN] Initialize
        Initialize();

        // [GIVEN] Create Purchase Order
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateItem());

        // [GIVEN] Open Purchase Order
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        // [GIVEN] Switch to "Custom Address" Ship-to option and update Ship-to Name field
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::"Custom Address");
        PurchaseOrder."Ship-to Name".SetValue(CreateGuid());

        // [WHEN] Return Default Ship-to option
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::"Custom Address");

        // [THEN] Verify Ship-to Name is returned to default value
        CompanyInformation.Get();
        PurchaseOrder."Ship-to Name".AssertEquals(CompanyInformation.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithVerification')]
    [Scope('OnPrem')]
    procedure UpdatePurchaseOrderDateShouldNotDeleteLinesWithDescription()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Description: Text[100];
    begin
        // [SCENARIO 459881] When changing the Order Date in Purchase Orders comment lines get deleted unexpectedly
        // [GIVEN] Initialize, Create Purchae Order
        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Order Date", Today());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        // [VERIFY] Verify Purchase Line has the same Order Date as Purchase Header
        PurchaseLine.TestField("Order Date", PurchaseHeader."Order Date");
        Clear(PurchaseLine);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::" ", '', 0);
        Description := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(PurchaseLine.Description), 1), 1, MAXSTRLEN(PurchaseLine.Description));
        PurchaseLine.Validate(Description, Description);
        PurchaseLine.Modify(true);
        // [VERIFY] Verify Purchase Line has blank Order Date
        PurchaseLine.TestField("Order Date", 0D);
        Commit();

        // [WHEN] Update Order Date on Purchase Order
        LibraryVariableStorage.Enqueue(UpdateLinesOrderDateAutomaticallyQst);
        LibraryVariableStorage.Enqueue(true);
        PurchaseHeader.Validate("Order Date", Today() + 1);
        PurchaseHeader.Modify(true);
        LibraryVariableStorage.AssertEmpty();
        PurchaseLine.GetBySystemId(PurchaseLine.SystemId);

        // [VERIFY] Verify Purchase Line with blank Order Date and Description Text on Purchase Order Line.
        Assert.AreEqual(
            0D, PurchaseLine."Order Date",
            StrSubstNo(OrderDateErr, 0D, PurchaseLine."Order Date"));

        Assert.AreEqual(
            PurchaseLine.Description, Description,
            StrSubstNo(DescriptionErr, PurchaseLine.Description, Description));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure VerifyServiceChargeLineIsRecreatedOnUpdatePayToVendorOnPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        VendorNo: array[2] of Code[20];
        ServiceChargeAmt: array[2] of Decimal;
        PayToOptions: Option "Default (Vendor)","Another Vendor";
    begin
        // [SCENARIO 461917] Verify Service Charge line is removed and new is created on update Pay-to Vendor on Purchase Order
        // [GIVEN] Initialize
        Initialize();

        // [GIVEN] Enable invoice discount calculation on "Purchases & Payables Setup".
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Create two Vendors with Service Charge line
        CreateVendorWithServiceChargeAmount(VendorNo[1], ServiceChargeAmt[1]);
        CreateVendorWithServiceChargeAmount(VendorNo[2], ServiceChargeAmt[2]);

        // [WHEN] Purchase order with vendor = "V"
        CreatePurchaseOrderWithServiceCharge(PurchaseHeader, VendorNo[1]);
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);

        // [THEN] Verify Charge Line is created
        FindPurchaseServiceChargeLine(PurchaseLine, PurchaseHeader);
        Assert.RecordCount(PurchaseLine, 1);
        PurchaseLine.TestField(Amount, ServiceChargeAmt[1]);

        // [WHEN] Purchase Order page is opened, and Pay-to Vendor is picked
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PayToOptions.SetValue(PayToOptions::"Another Vendor");
        PurchaseOrder."Pay-to Name".SetValue(VendorNo[2]);

        // [THEN] Verify Charge Line is recreated
        FindPurchaseServiceChargeLine(PurchaseLine, PurchaseHeader);
        Assert.RecordCount(PurchaseLine, 1);
        PurchaseLine.TestField(Amount, ServiceChargeAmt[2]);
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesModalPageHandler')]
    procedure VerifyPostPurchaseOrderWithChargeItemPostedFromPurchaseInvoiceRelatedToReceiptCreatedFromPurchaseOrder()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        ItemCharge: Record "Item Charge";
        Items: array[2] of Record Item;
    begin
        // [SCENARIO 463637] Verify Post Purchase Order, for partially Receive lines, with Charge (Item), and than that lines posted through Purchase Invoice
        Initialize();

        // [GIVEN] Create Item Charge and two Items
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryInventory.CreateItem(Items[1]);
        LibraryInventory.CreateItem(Items[2]);

        // [GIVEN] Create Purchase Order with three lines (two Item and one Charge (Item))
        CreatePurchaseOrderWithItemCharge(PurchaseHeaderOrder, ItemCharge."No.", Items);

        // [GIVEN] Set First Purchase Order Line not to Receive
        SetFirstPurchaseLineNotToReceive(PurchaseHeaderOrder, Items[1]."No.");

        // [GIVEN] Post Receive for one Item and Charge (Item) line
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [GIVEN] Create Purchase Invoice for Posted Receipt Lines from Purchase Order
        CreatePurchaseInvoice(PurchaseHeaderInvoice, PurchaseHeaderOrder, ItemCharge);

        // [WHEN] Post Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, true);

        // [THEN] Post Purchase Order
        PurchaseHeaderOrder.Get(PurchaseHeaderOrder."Document Type", PurchaseHeaderOrder."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, true);
    end;

    [Test]
    procedure VerifyUpdateQuantityOnPurchaseOrderWithMultiplePartialReceiveAndAdditionalItemUnitOfMeasure()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentType: Enum "Purchase Document Type";
    begin
        // [SCENARIO 476242] Verify Update Quantity on Purchase Order with multiple partial Receive and additional Item Unit of Measure
        Initialize();

        // [GIVEN] Create Item and Item Unit of Measure Code
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Item Unit of Measure Code
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 58.70198);

        // [GIVEN] Create Purchase Document
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, DocumentType::Order, LibraryPurchase.CreateVendorNo(), Item."No.", 50000, '', WorkDate());

        // [GIVEN] Set Qty. to Receive on Purchase Line and Post Receive
        UpdateQtyToReceiveOnPurchaseLineAndPostReceive(PurchaseHeader, PurchaseLine, 817.68);

        // [GIVEN] Set Qty. to Receive on Purchase Line and Post Receive
        UpdateQtyToReceiveOnPurchaseLineAndPostReceive(PurchaseHeader, PurchaseLine, 817.68);

        // [GIVEN] Set Qty. to Receive on Purchase Line and Post Receive
        UpdateQtyToReceiveOnPurchaseLineAndPostReceive(PurchaseHeader, PurchaseLine, 817.68);

        // [GIVEN] Set Qty. to Receive on Purchase Line and Post Receive
        UpdateQtyToReceiveOnPurchaseLineAndPostReceive(PurchaseHeader, PurchaseLine, 1022.10);

        // [GIVEN] Set Qty. to Receive on Purchase Line and Post Receive
        UpdateQtyToReceiveOnPurchaseLineAndPostReceive(PurchaseHeader, PurchaseLine, 1022.10);

        // [GIVEN] Set Qty. to Receive on Purchase Line and Post Receive
        UpdateQtyToReceiveOnPurchaseLineAndPostReceive(PurchaseHeader, PurchaseLine, 204.42);

        // [WHEN] Reopen Purchase Order
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [THEN] Verify update Quantity on Purchase Line
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate(Quantity, 4701.66);
        PurchaseLine.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPurchaseReceiptOnPurchaseDocTwice()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ServiceChargeAmt: Decimal;
        PurchaseOrderTestPage: TestPage "Purchase Order";
    begin
        // [FEATURE] [Take me there] [Warehouse Receipt]
        Initialize();

        // [GIVEN] Enable invoice discount calculation on "Purchases & Payables Setup".
        // [GIVEN] Set "Service Charge" = 10 in "Vendor Invoice Discount" setting for vendor "V".
        LibraryPurchase.SetCalcInvDiscount(true);
        VendorNo := CreateVendorInvDiscount();
        ServiceChargeAmt := LibraryRandom.RandDecInDecimalRange(10, 20, 2);
        VendorInvoiceDisc.SetRange(Code, VendorNo);
        VendorInvoiceDisc.FindFirst();
        VendorInvoiceDisc.Validate("Service Charge", ServiceChargeAmt);
        VendorInvoiceDisc.Modify(true);

        // [GIVEN] Location "L" set up for required receive.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Purchase order with vendor = "V" and location = "L".
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, VendorNo,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), Location.Code, WorkDate());

        // [GIVEN] Releasing the purchase order adds a service charge purchase line to the order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Update "Service Charge" to 20 in "Vendor Invoice Discount" setting for vendor "V".
        VendorInvoiceDisc.Validate("Service Charge", 2 * ServiceChargeAmt);
        VendorInvoiceDisc.Modify(true);

        // [GIVEN] Create warehouse receipt from the purchase order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] The receipt is posted without an error.
        PurchaseLine.Find();

        // [GIVEN] Try to invoke the warehouse Reciept action again.
        PurchaseOrderTestPage.OpenEdit();
        PurchaseOrderTestPage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrderTestPage.GotoRecord(PurchaseHeader);
        asserterror PurchaseOrderTestPage."Create &Whse. Receipt_Promoted".Invoke();

        // [THEN] validate error message is thrown.
        assert.ExpectedError('This usually happens');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyJobNoOnReleasePurchaseOrder()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 479158] A Purchase Order in status of Released allows for the deletion or addition of Job No., Job
        // Task No., and Job Line Type - This is not expected especially for a client using Approvals and now allowed to
        // change after Release
        Initialize();

        // [GIVEN] Create the Job
        LibraryJob.CreateJob(Job);

        // [GIVEN] Create the Job task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create the Purchase Order
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateItem());

        // [WHEN] Release the Purchase Order
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] Open the Purchase Order Page.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines.First();

        // [VERIFY] Verify the user will not able to add the Job No. and Job Line Type
        asserterror PurchaseOrder.PurchLines."Job No.".Value(Job."No.");
        asserterror PurchaseOrder.PurchLines."Job Line Type".Value(Format(PurchaseLine."Job Line Type".AsInteger()));
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseOrderRequestPageHandler')]
    procedure VerifyPrintPurchaseOrderAfterPostPrepaymentInvoiceAndUpdatePrepaymentPercent()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 479326] Verify Print Purchase Order after Post Prepayment Invoice and update Prepayment Percent
        Initialize();

        // [GIVEN] Create the Purchase Order
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateItem());

        // [GIVEN] Set Prepayment Percent on Purchase Header
        PurchaseHeader.Validate("Prepayment %", 20);
        PurchaseHeader."Prepayment Due Date" := CalcDate('<+1M>', WorkDate());
        PurchaseHeader.Modify(true);

        // [GIVEN] Post Prepayment
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Reopen Purchase Order
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [WHEN] Update Prepayment Percent on Purchase Header
        PurchaseHeader.Validate("Prepayment %", 30);
        PurchaseHeader.Modify(true);

        // [THEN] Verify Print Purchase Order
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Commit();
        Report.Run(Report::"Standard Purchase - Order", true, false, PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('VendorLookupHandler,ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure VerifyNewPurchaseOrderWithLookUpPayToVendorNameOnPreviousOrderNotChangingBuyFromVendor()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        PayToOptions: Option "Default (Vendor)","Another Vendor";
    begin
        // [SCENARIO 487985] If you enter the Vendor Name directly in a new Purchase Order, the vendor selected in a previous lookup on the Pay-to Vendor field is taken instead of the vendor entered.
        Initialize();

        // [GIVEN] Create Vendors and Purchase Order
        BuyFromVendor.Get(CreateVendor());
        PayToVendor.Get(CreateVendor());
        LibraryVariableStorage.Enqueue(PayToVendor."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, BuyFromVendor."No.");
        LibraryVariableStorage.Enqueue(true);

        // [GIVEN] Open Purchase Order page
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // [THEN] Pick another Pay-to vendor using Lookup
        PurchaseOrder.PayToOptions.SetValue(PayToOptions::"Another Vendor");
        PurchaseOrder."Pay-to Name".Lookup();

        // [GIVEN] Create New Purchase Order without closing the page
        PurchaseOrder.New();
        PurchaseOrder."Buy-from Vendor Name".SetValue(BuyFromVendor.Name);

        // [VERIFY] Verify: When set Buy-from Vendor Name directly not changed the Buy-from Vendor
        PurchaseOrder."Buy-from Vendor No.".AssertEquals(BuyFromVendor."No.");
        PurchaseOrder.Close();
    end;

    [Test]
    procedure VerifyQtyReceivedBaseAfterCorrectOnPartialInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PurchaseInvoceNo: Code[20];
    begin
        // [SCENARIO 494646] Verify Qty. Received (Base) on Purchase Line after Correct Posted Purchase Invoice on Partial Invoice
        Initialize();

        // [GIVEN] Create Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 100);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify();

        // [GIVEN] Set "Qty. to Receive" on Purchase Line
        PurchaseLine.Validate("Qty. to Receive", 80);
        PurchaseLine.Modify(true);

        // [GIVEN] Post Receive & Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Set "Qty. to Receive" on Purchase Line
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", 15);
        PurchaseLine.Modify(true);

        // [GIVEN] Set Vendor Invoice No.
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify();

        // [GIVEN] Post Receive & Invoice
        PurchaseInvoceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Correct Posted Purchase Invoice
        PurchInvHeader.Get(PurchaseInvoceNo);
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // [GIVEN] Reopen Purchase Order
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [WHEN] Update Quantity on Purchase Line
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate(Quantity, 95);

        // [THEN] Verify Qty. Received (Base) on Purchase Line
        Assert.AreEqual(PurchaseLine."Qty. Received (Base)", 80, QtyReceivedBaseErr);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentHandler,ConfirmHandler,PurchaseOrderTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderandInvoiceWithItemChargeAssignmentandReverseThroughCorrectAction()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedPurchaseInv: TestPage "Posted Purchase Invoice";
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO 497023] Reverse the Charge Item Quantity Assigned in Purchase Order and Delete the Order.
        Initialize();

        // [GIVEN] Setup: Create Purchase Order with charge (Item).
        CreatePurchaseOrderChargeItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // [GIVEN] Assign the Item Charge.
        PurchaseLine.UpdateItemChargeAssgnt();

        // [GIVEN] Post Purchase Order For Receipt
        DocumentNo2 := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create Purchase Invoice and Get Receipt Lines for Invoice.
        InvoicePostedPurchaseOrder(PurchaseHeader2, PurchaseHeader);

        // [GIVEN] Assign Item Charge In Purchase Line
        PurchaseLine.SetRange("Document No.", PurchaseHeader2."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindFirst();
        PurchaseLine.ShowItemChargeAssgnt();

        // [GIVEN] Post Purchase Invoice.
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        //[WHEN] Invoke Posted Purchase Invoice Correct Action for Reversing the Posted Transaction
        PostedPurchaseInv.OpenEdit();
        PostedPurchaseInv.FILTER.SetFilter("No.", PostedInvoiceNo);
        PostedPurchaseInv.CorrectInvoice.Invoke();

        // [VERIFY] Validate Item Charge Assignment Purch.
        VerifyItemChargeAssignmentQtyAssigned(PurchaseHeader."No.");

        // [THEN] Delete Purchase Order
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('PrintPurchaseOrderRequestPageHandler')]
    procedure StandardPurchaseOrderShouldHaveLogInteractionEnabled()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 537088] Possible to create log interaction when printing purchase order.
        Initialize();

        // [GIVEN] Create a Purchase Order.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateItem());

        // [THEN] Run Standard Purchase - Order report and check log intereaction enabled.
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Commit();
        Report.Run(Report::"Standard Purchase - Order", true, false, PurchaseHeader);
    end;

    [Test]
    procedure VerifyItemRefernceNotUpdateToDefaultOnLocationCodeChange()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Location: Record Location;
        Location1: Record Location;
        ItemReference: Record "Item Reference";
        ItemRefNoBefore: Code[50];
        ItemReferenceNoAfter: Code[50];
    begin
        // [SCENARIO 537660] Item Reference No. field on Purchase line is reverted after adding/changing the location.
        Initialize();

        // [GIVEN] Create Locations
        LibraryWarehouse.CreateLocation(Location);
        LibraryWareHouse.CreateLocation(Location1);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order with Location Code
        CreatePurchaseHeader(PurchaseHeader, PurchaseLine."Document Type"::Order);
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);

        // [GIVEN] Create Item reference with Reference Type- "Vendor"," ".
        CreateTwoItemReferences(ItemReference, PurchaseHeader, Item);

        // [THEN] Filter Item Reference to Blank Reference Type
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::" ");

        // [GIVEN] Create Purchase Line with item reference no set to reference type " ".
        // [GIVEN] Change the reference no. to any other reference no. from default.
        CreatePurchaseLineWithItemreferenceNo(PurchaseLine, PurchaseHeader, Item, ItemReference);

        // [THEN] Save the value of Item Reference No on ItemRefNoBefore variable
        ItemRefNoBefore := PurchaseLine."Item Reference No.";

        // [THEN] Change the Location Code on Purchase Line.
        PurchaseLine.Validate("Location Code", Location1.Code);

        // [THEN] Save the value of Item Reference No on ItemReferenceNoAfter variable
        ItemReferenceNoAfter := PurchaseLine."Item Reference No.";

        // [VERIFY] Item reference No will remains unchanged, on updating the Location Code.
        Assert.AreEqual(ItemRefNoBefore, ItemReferenceNoAfter, StrSubstNo(ItemRefrenceNoErr, ItemRefNoBefore));
    end;

    [Test]
    procedure ReleasingOfPurchaseOrderHavingPurchaseLineWithoutUOMGivesError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 522444] When run Release action from a Purchase Order having a Purchase Line without
        // Unit of Measure Code, then it gives error and the document is not released.
        Initialize();

        // [GIVEN] Create a Purchase Order.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateItem());

        // [WHEN] Validate Unit of Measure Code in Purchase Line.
        PurchaseLine.Validate("Unit of Measure Code", '');
        PurchaseLine.Modify(true);

        // [THEN] Error is shown and the Purchase Order is not released.
        asserterror LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    [Test]
    procedure PurchaseOrderPostingFromVendorCard()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorCard: TestPage "Vendor Card";
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseOrderNo: Code[20];
    begin
        // [SCENARIO 537495] After Posting a Purchase Order created from the Vendor Card no error is displayed
        Initialize();

        // [GIVEN] Create Vendor
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // [WHEN] Open Vendor Card and create new Purchase Document
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        PurchaseOrder.Trap();
        VendorCard.NewPurchaseOrder.Invoke();

        // [GIVEN] Set Vendor Invoice No. and create new purchase line
        PurchaseOrder."Vendor Invoice No.".SetValue(LibraryRandom.RandText(35));
        PurchaseOrder.PurchLines.New();
        PurchaseOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseOrder.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        PurchaseOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 1));
        PurchaseOrder.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandDecInRange(1, 100, 2));

        // [GIVEN] Save the Purchase Order NO in a Variable
        PurchaseOrderNo := PurchaseOrder."No.".Value();

        // [WHEN] Release and post Purchase Document
        PurchaseOrder.Release.Invoke();
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrderNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify the  Purchase Order Posted Succsessfully without any error and system doesn't found the current Purchase Order
        asserterror PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrderNo);
        Assert.AssertRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyLineDiscountPctafterProjectNoInserted()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        Job: Record Job;
    begin
        // [SCENARIO 544960] Purchase Line Disc % should not Cleared after entering the Project No. in the Current  Line
        Initialize();

        //[GIVEN] Create Job
        LibraryJob.CreateJob(Job);

        // [GIVEN] Create Purchase order
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LibraryInventory.CreateItemNo());
        PurchaseLine.validate("Location Code", LibraryWarehouse.CreateLocation(Location));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 99, 2));
        PurchaseLine.validate("Line Discount %", LibraryRandom.RandIntInRange(3, 5));

        // [WHEN] Assign Job No. on Purchase Line
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Modify(true);

        // [THEN] Verify: Verify the Line Discount % value should not be zero
        PurchaseLine.TestField("Line Discount %");
    end;

    [Test]
    [HandlerFunctions('GrossWeightItemChargeAssignmentHandler')]
    procedure ValidateItemChargeAssignmentPostPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
        ItemChargeNo: Code[20];
    begin
        // [SCENARIO 547482] Assigning the Charge (item) by Weight on Purchase Quote.
        Initialize();

        // [GIVEN] Create a Purchase Header with Document Type Quote.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote);

        // [GIVEN] Create a Purchase Line with an Item.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine[1],
            PurchaseHeader,
            PurchaseLine[1].Type::Item,
            CreateItem(),
            LibraryRandom.RandInt(10));

        // [GIVEN] Validate Direct Unit Cost, Net Weight, Gross Weight in Purchase Line.
        PurchaseLine[1].Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine[1].Validate("Net Weight", LibraryRandom.RandDec(10, 2));
        PurchaseLine[1].Validate("Gross Weight", LibraryRandom.RandDec(10, 2));
        PurchaseLine[1].Modify(true);

        // [GIVEN] Create an Item Charge.
        ItemChargeNo := LibraryInventory.CreateItemChargeNo();

        // [GIVEN] Create Item Charge Line in Purchase Quote and Validate Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine[2],
            PurchaseHeader,
            PurchaseLine[2].Type::"Charge (Item)",
            ItemChargeNo,
            LibraryRandom.RandInt(10));
        PurchaseLine[2].Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine[2].Modify(true);

        // [WHEN] Assign Item Charge.
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.PurchLines.Filter.SetFilter("No.", ItemChargeNo);

        // [THEN] Item Charge Assignment should calculate Gross Weight.
        PurchaseQuote.PurchLines.ItemChargeAssignment.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentModalPageHandler,ItemChargeAssignMenuHandler')]
    procedure QtyToAssignAndQtyToHandleUpdateCorrectInPurchOrderWhenTotalItemChargeIsUsedByPurchaseInvoice()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[4] of Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        Quantity: Integer;
        DirectUnitCost: Decimal;
    begin
        // [SCENARIO 547910] Item Charge fields 'Qty to Assign' and 'Item Charge Qty. to Handle' are not updated correctly by
        // Purchase Invoice in Purchase Order when total Item Charge has already been accounted for in the Purchase Invoice.
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Charge Item.
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Generate Quantity.
        Quantity := LibraryRandom.RandInt(0);

        // [GIVEN] Generate Direct Unit Cost
        DirectUnitCost := LibraryRandom.RandDecInRange(10, 50, 2);

        // [GIVEN] Create a Purchase Header with Document Type Order.
        CreatePurchaseHeader(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Order);

        // [GIVEN] Create Purchase Lines one with an Item.
        CreatePurchaseLinesAndUpdateQtytoReceive(
            PurchaseLine[1], PurchaseHeader[1], PurchaseLine[1].Type::Item,
            Item."No.", Quantity, Quantity, DirectUnitCost);

        // [GIVEN] Create Purchase Lines two with an Item.
        CreatePurchaseLinesAndUpdateQtytoReceive(
            PurchaseLine[2], PurchaseHeader[1], PurchaseLine[2].Type::Item,
            Item."No.", Quantity, 0, DirectUnitCost);

        // [GIVEN] Create Purchase Lines three with an Charge Item.
        CreatePurchaseLinesAndUpdateQtytoReceive(
            PurchaseLine[3], PurchaseHeader[1], PurchaseLine[3].Type::"Charge (Item)",
            ItemCharge."No.", Quantity, Quantity, LibraryRandom.RandDecInRange(20, 20, 2));

        // [GIVEN] Choice is Equally for Item Charge Assignment Page Handler.
        LibraryVariableStorage.Enqueue(1);

        // [GIVEN] Choice is to invoke Suggest Item Charge Assignment.
        LibraryVariableStorage.Enqueue(true);

        // [GIVEN] Open Item Charge Assignment.
        PurchaseLine[3].ShowItemChargeAssgnt();

        // [GIVEN] Posts Receipt of Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        // [GIVEN] Create Purchase Invoice with the help of "Get Receipt Lines".
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, PurchaseHeader[1]."Buy-from Vendor No.");
        PurchRcptLine.SetRange("Order No.", PurchaseHeader[1]."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeader[2]);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [GIVEN] Find Charge Item Purchase Line.
        FindItemChargePurchaseLine(PurchaseLine[4], PurchaseHeader[2]."No.", PurchaseHeader[2]."Document Type");

        // [GIVEN] Choice is Equally for Item Charge Assignment Page Handler.
        LibraryVariableStorage.Enqueue(1);

        // [GIVEN] Assign Item Charge
        PurchaseLine[4].ShowItemChargeAssgnt();

        // [WHEN] Posts Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], false, true);

        // [GIVEN] Choice is not to Invoke Suggest Item Charge.
        LibraryVariableStorage.Enqueue(false);

        // [GIVEN] Open Item Charge Assignment.
        PurchaseLine[3].ShowItemChargeAssgnt();

        // [THEN] Verify Fields Qty.to Assign and Qty. to Handle of Item Charge Assignment .
        VerifyItemChargeQty(PurchaseLine[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ItemChargeAssignmentModalPageHandler,ItemChargeAssignMenuHandler')]
    procedure PostPurchaseInvoiceWithItemChargeWhenReceiptLinesWithLocationDimension()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: array[2] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        Location: array[2] of Record Location;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[4] of Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ValueEntry: Record "Value Entry";
        WarehouseEmployee: Record "Warehouse Employee";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        Quantity: Integer;
        DirectUnitCost: Decimal;
    begin
        // [SCENARIO 561174] Unable to Post Purchase Invoice with Item Charge when the receipt lines are assigned to a location that has Dimension of Code Mandatory.
        Initialize();

        // [GIVEN] Create Location one with Dimension Value one and Inventory Posting Setup
        GeneralLedgerSetup.Get();
        CreateLocationWithDimension(Location[1], DimensionValue[1], GeneralLedgerSetup."Shortcut Dimension 1 Code", DefaultDimension."Value Posting"::"Code Mandatory");

        // [GIVEN] Create Location two with Dimension Value two and Inventory Posting Setup
        CreateLocationWithDimension(Location[2], DimensionValue[2], GeneralLedgerSetup."Shortcut Dimension 1 Code", DefaultDimension."Value Posting"::"Code Mandatory");

        // [GIVEN] Create Warehouse Employee with first Location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[1].Code, false);

        // [GIVEN] Create an Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Charge Item
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Generate Quantity
        Quantity := LibraryRandom.RandInt(0);

        // [GIVEN] Generate Direct Unit Cost
        DirectUnitCost := LibraryRandom.RandDecInRange(10, 50, 2);

        // [GIVEN] Create a Purchase Header with Document Type Order.
        CreatePurchaseHeader(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Order);

        // [GIVEN] Create Purchase Lines one with an Item with Location one and Dimension Value one.
        CreatePurchaseLinesAndUpdateLocationAndDimension(
            PurchaseLine[1], PurchaseHeader[1], PurchaseLine[1].Type::Item,
            Item."No.", Quantity, Quantity, DirectUnitCost, Location[1].Code, Dimensionvalue[1].Code);

        // [GIVEN] Create Purchase Lines two with an Item with Location two and Dimension Value two.
        CreatePurchaseLinesAndUpdateLocationAndDimension(
            PurchaseLine[2], PurchaseHeader[1], PurchaseLine[2].Type::Item,
            Item."No.", Quantity, Quantity, DirectUnitCost, Location[2].Code, Dimensionvalue[2].Code);

        // [GIVEN] Post Receipt of Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        // [GIVEN] Create Purchase Invoice with the help of "Get Receipt Lines".
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, PurchaseHeader[1]."Buy-from Vendor No.");
        PurchRcptLine.SetRange("Order No.", PurchaseHeader[1]."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeader[2]);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [GIVEN] Create new Purchase Lines three with an Charge Item.
        CreatePurchaseLinesAndUpdateQtytoReceive(
            PurchaseLine[3], PurchaseHeader[2], PurchaseLine[3].Type::"Charge (Item)",
            ItemCharge."No.", Quantity, Quantity, LibraryRandom.RandDecInRange(20, 20, 2));

        // [GIVEN] Find Charge Item Purchase Line.
        FindItemChargePurchaseLine(PurchaseLine[4], PurchaseHeader[2]."No.", PurchaseHeader[2]."Document Type");

        // [GIVEN] Invoke Suggest Item Charge Assignment with option By Amount
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(true);
        PurchaseLine[4].ShowItemChargeAssgnt();

        // [WHEN] Post Invoice of Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], false, true);

        // [THEN] Value Entry with Entry Type, Direct Cost, Item and item charge has Global Dimension 1 Code.
        FindDirectCostValueEntry(ValueEntry, Item."No.", ItemCharge."No.");
        Assert.AreEqual('', ValueEntry."Global Dimension 1 Code",
            StrSubstNo(
                GlobalDimensionCodeErr,
                ValueEntry.FieldCaption("Global Dimension 1 Code"),
                ValueEntry.TableCaption));
    end;

    [Test]
    procedure SourceCurrencyAmountReflectCorrectInGLEntryWhenVATCalculationTypeReverseChargeTax()
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        InvocieNo: Code[20];
    begin
        // [SCENARIO 559286] Calculation in Source Currency Amount with right Sign when VAT calculation type is Reverse Charge Tax in VAT Posting Setup.
        Initialize();

        // [GIVEN] Create Reverse Charge VAT in VAT Posting Setup.
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup,
            VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT",
            LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Validate Reverse Chrg. VAT Acc. in VAT Posting Setup.
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Reverse Chrg. VAT Unreal. Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        // [GIVEN] Create Currency With Exchange Rate.
        Currency.Get(
            LibraryERM.CreateCurrencyWithExchangeRate(
                WorkDate(),
                LibraryRandom.RandDecInRange(100, 110, 2),
                LibraryRandom.RandDecInRange(111, 120, 2)));

        // [GIVEN] Create an Item, Validate VAT Prod. Posting Group and Last Direct Cost.
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));
        Item.Modify(true);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader,
            PurchaseHeader."Document Type"::Order,
            LibraryPurchase.CreateVendorNo());

        // [GIVEN] Validate Vendor Invoice No., VAT Bus. Posting Group and Currency Code.
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Currency Code", Currency.Code);
        PurchaseHeader.Modify(true);

        // [GIVEN] Create Purchase Line and Validate VAT Product Posting Group.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item,
            Item."No.",
            LibraryRandom.RandInt(10));
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Order.
        InvocieNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Source Currency Amount in General Ledger Entry must have same sign as Amount.
        GLEntry.SetRange("Document No.", InvocieNo);
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Reverse Chrg. VAT Acc.");
        GLEntry.FindFirst();
        Assert.IsTrue(
            GLEntry."Source Currency Amount" < 0,
            StrSubstNo(
                SourceCurrencyErr,
                GLEntry.FieldCaption("Source Currency Amount")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure VerifyPurchaseOrderUpdatedAfterPartialCorrectPostedPurchaseInvoice()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO 578443] Verify quantity on posted Purchase Order updated correctly after partial posting of Corrective Credit memo.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order with Quantity as 10.
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, CreateVendor(),
            Item."No.", LibraryRandom.RandIntInRange(10, 10), '', WorkDate());

        // [GIVEN] Update Qty to Receive in Purchase Line as 5.
        PurchaseLine.Validate(PurchaseLine."Qty. to Receive", LibraryRandom.RandIntInRange(5, 5));
        PurchaseLine.Modify(true);

        // [GIVEN] Post the partial Purchase order.
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] Create Corrective Credit Memo.
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchaseHeader2);
        PurchaseHeader2.Validate("Vendor Cr. Memo No.", PurchaseHeader2."No.");
        PurchaseHeader2.Modify(true);

        // [GIVEN] Find Purchase Line of created Purchase Credit Memo.
        PurchaseLine2.SetRange("Document Type", PurchaseHeader2."Document Type");
        PurchaseLine2.SetRange("Document No.", PurchaseHeader2."No.");
        PurchaseLine2.SetRange("No.", Item."No.");
        PurchaseLine2.FindFirst();
        PurchaseLine2.Validate(Quantity, LibraryRandom.RandIntInRange(2, 2));
        PurchaseLine2.Modify(true);

        // [WHEN] Post the Corrective Credit Memo
        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(Purchaseheader2);
        PurchaseCreditMemo.Post.Invoke();

        // [THEN] Verify Purchase Order Qty. to Receive and Qty. to Invoice are updated as 7 in the Purchase line.
        VerifyPurchaseOrderAfterPartialPostCorrectiveCreditMemo(PurchaseHeader."No.", 7);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure VerifyPurchaseOrderUpdatedAfterCorrectPostedPurchaseInvoiceDifferentQuantity()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO 578443] Verify quantity on posted Purchase Order updated correctly after partial posting of Corrective Credit memo.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order with Quantity as 10.
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, CreateVendor(),
            Item."No.", LibraryRandom.RandIntInRange(10, 10), '', WorkDate());

        // [GIVEN] Update Qty to Receive in Purchase Line as 3.
        PurchaseLine.Validate("Qty. to Receive", LibraryRandom.RandIntInRange(3, 3));
        PurchaseLine.Modify(true);

        // [GIVEN] Receipt the partial Purchase order with Qty. to Receive as 3.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Update Qty to Receive in Purchase Line as 2.
        PurchaseLine2.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine2.Validate("Qty. to Receive", LibraryRandom.RandIntInRange(2, 2));
        PurchaseLine2.Modify(true);

        // [GIVEN] Receipt the partial Purchase order with Qty. to Receive as 2.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Update Qty. to Receive as 0 and Qty. to Invoice as 5 in Purchase Line.
        PurchaseLine2.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine2.Validate("Qty. to Receive", 0);
        PurchaseLine2.Validate("Qty. to Invoice", 5);
        PurchaseLine2.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));

        // [GIVEN] Create Corrective Credit Memo.
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchaseHeader2);
        PurchaseHeader2.Validate("Vendor Cr. Memo No.", PurchaseHeader2."No.");
        PurchaseHeader2.Modify(true);

        // [WHEN] Post the Corrective Credit Memo
        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(Purchaseheader2);
        PurchaseCreditMemo.Post.Invoke();

        // [THEN] Verify Purchase Order Qty. to Receive and Qty. to Invoice are updated as 10 in the Purchase line.
        VerifyPurchaseOrderAfterPartialPostCorrectiveCreditMemo(PurchaseHeader."No.", 10);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure VerifyPurchaseOrderUpdatedAfterCorrectPostedPurchaseInvoiceApplyEntries()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO 578443] Verify quantity on posted Purchase Order updated correctly after posting of Corrective Credit memo with Application.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order with Quantity as 10.
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, CreateVendor(),
            Item."No.", LibraryRandom.RandIntInRange(10, 10), '', WorkDate());
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);

        // [GIVEN] Update Qty to Receive in Purchase Line as 5.
        PurchaseLine.Validate("Qty. to Receive", LibraryRandom.RandIntInRange(5, 5));
        PurchaseLine.Modify(true);

        // [GIVEN] Post the partial Purchase order.
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] Create Corrective Credit Memo.
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchaseHeader2);
        PurchaseHeader2.Validate("Vendor Cr. Memo No.", PurchaseHeader2."No.");
        PurchaseHeader2.Modify(true);

        // [GIVEN] Set Applied-to ID on Vendor Ledger Entry.
        VendorLedgerEntry.SetRange("Document No.", PurchInvHeader."No.");
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry."Applies-to ID" := PurchaseHeader2."No.";
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry."Amount to Apply" := VendorLedgerEntry."Remaining Amount";

        // [WHEN] Post the Corrective Credit Memo
        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(Purchaseheader2);
        PurchaseCreditMemo.Post.Invoke();

        // [THEN] Verify Purchase Order Qty. to Receive and Qty. to Invoice are updated as 10 in the Purchase line.
        VerifyPurchaseOrderAfterPartialPostCorrectiveCreditMemo(PurchaseHeader."No.", 10);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler')]
    procedure ItemChargeAssignmentWithPartialWarehouseReceipt()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        PurchaseSetup: Record "Purchases & Payables Setup";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        ItemChargeNo: Code[20];
    begin
        // [SCENARIO 573822] Verify Warehouse Receipt should be posted successfully if Item Charge is assigned and Partial Receipt is Posted.
        Initialize();

        // [GIVEN] Assign Auto Post Non-Int. Via Whse. as Attached/Assigned in Purchases & Payables Setup.
        PurchaseSetup.Get();
        PurchaseSetup."Auto Post Non-Invt. via Whse." := PurchaseSetup."Auto Post Non-Invt. via Whse."::"Attached/Assigned";
        PurchaseSetup.Modify(true);

        // [GIVEN] Create Location with required Warehouse Setup and Warehouse Employee.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, true, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create Item and Item Charge.
        LibraryInventory.CreateItem(Item);
        ItemChargeNo := LibraryInventory.CreateItemChargeNo();

        // [GIVEN] Create Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Modify(true);

        // [GIVEN] Create first Purchase Line with Type as Item and Quantity as 100.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[1], PurchaseHeader, PurchaseLine[1].Type::Item, Item."No.", 100);
        PurchaseLine[1].Validate("Location Code", Location.Code);
        PurchaseLine[1].Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine[1].Modify(true);

        // [GIVEN] Create second Purchase Line with Type as Charge (Item) and Quantity as 1.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::"Charge (Item)", ItemChargeNo, 1);
        PurchaseLine[2].Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(50, 50, 2));
        PurchaseLine[2].Modify(true);

        // [GIVEN] Update Qty. to Assign on Item Charge Assignment
        LibraryVariableStorage.Enqueue(1);
        PurchaseLine[2].ShowItemChargeAssgnt();
        PurchaseLine[2].Modify(true);

        // [GIVEN] Release Purchase Document.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Warehouse Receipt.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptHeader.Get(
                  LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
                    DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));

        // [GIVEN] Modify Warehouse Receipt Line with Quantity as 50 and post the  partial warehouse Document
        ModifyQtyToReceiveOnWarehouseReceiptLine(PurchaseHeader."No.", PurchaseLine[1]."No.", 50);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [WHEN] Post the remaining warehouse Document.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] No error should appear and Warehouse Receipt should be posted successfully.
    end;

    [Test]
    [HandlerFunctions('ItemListOkModalPageHandler')]
    procedure VerifyCreatedItemSelectedInPurchaseAnalysisViewCard()
    var
        Item: Record Item;
        ItemAnalysisView: Record "Item Analysis View";
        ItemNo: Code[20];
        PurchaseAnalysisViewCard: TestPage "Purchase Analysis View Card";
    begin
        // [SCENARIO 601502] Verify created item is selected in purchase analysis view Card when ok is clicked on item lookup page.
        Initialize();

        // [GIVEN] Create a new item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Analysis View
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Purchase);

        // [GIVEN] Open Purchase Analysis View Card.
        PurchaseAnalysisViewCard.OpenView();
        PurchaseAnalysisViewCard.GoToRecord(ItemAnalysisView);
        LibraryVariableStorage.Enqueue(Item."No.");

        // [WHEN] Set Item Filter via lookup and select the created item
        PurchaseAnalysisViewCard."Item Filter".Lookup();
        ItemNo := PurchaseAnalysisViewCard."Item Filter".Value();
        PurchaseAnalysisViewCard.Close();

        // [THEN] Verify the Item Filter on Purchase Analysis View Card matches the created item
        Assert.AreEqual(Item."No.", ItemNo, ItemFilterOnAnalysisViewCardMatchesCreatedItemErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemListCancelModalPageHandler')]
    procedure VerifyCreatedItemNotSelectedInPurchaseAnalysisViewCard()
    var
        Item: Record Item;
        ItemAnalysisView: Record "Item Analysis View";
        ItemNo: Code[20];
        PurchaseAnalysisViewCard: TestPage "Purchase Analysis View Card";
    begin
        // [SCENARIO 601502] Verify created item is not selected in purchase analysis view card when cancel is clicked on item lookup page.
        Initialize();

        // [GIVEN] Create a new item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Analysis View
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Purchase);

        // [GIVEN] Open Purchase Analysis View Card.
        PurchaseAnalysisViewCard.OpenView();
        PurchaseAnalysisViewCard.GoToRecord(ItemAnalysisView);
        LibraryVariableStorage.Enqueue(Item."No.");

        // [WHEN] Set Item Filter via lookup and select the created item
        PurchaseAnalysisViewCard."Item Filter".Lookup();
        ItemNo := PurchaseAnalysisViewCard."Item Filter".Value();
        PurchaseAnalysisViewCard.Close();

        // [THEN] Verify that the Item Filter on the Purchase Analysis View Card is cleared when canceled.
        Assert.AreEqual('', ItemNo, ItemFilterOnAnalysisViewCardMatchesCreatedItemErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PostedPurchaseDocumentLinesHandler')]
    procedure VerifyManuallyCreatedPurchaseCrMemoUpdateExistingPurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO 578769] Verify manually created Purchase Credit Memo with get posted document lines to reverse should update the existing Purchase Order.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [GIVEN] Create Purchase Line with Quanity as 10.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 10));

        // [GIVEN] Update Qty To Receive in Purchase Line.
        PurchaseLine.Validate("Qty. to Receive", LibraryRandom.RandIntInRange(5, 5));
        PurchaseLine.Modify(true);

        // [GIVEN] Post the Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create Purchase Credit Memo
        LibraryPurchase.CreatePurchHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::"Credit Memo", Vendor."No.");

        // [GIVEN] Run Get Document Lines to Reverse and copy from posted purchase invoice
        GetPostedDocumentLines(PurchaseHeader2."No.", OptionString::PostedInvoices);
        FindPurchaseLine(PurchaseLine, PurchaseHeader2."Document Type", PurchaseHeader2."No.", PurchaseLine.Type::Item);

        // [WHEN] Post the Credit Memo
        PurchCreditMemo.OpenView();
        PurchCreditMemo.GotoRecord(PurchaseHeader2);
        PurchCreditMemo.Post.Invoke();

        // [THEN] Verify Purchase Order Qty. to Receive and Qty. to Invoice are updated as 10 in the Purchase line.
        VerifyPurchaseOrderQuantityforManualPurchaseCreditMemo(PurchaseHeader."No.", 10);
    end;

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Order");
        LightInit();
        LibrarySetupStorage.Restore();
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase Order");

        LibraryTemplates.EnableTemplatesFeature();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveCompanyInformation();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase Order");
    end;

    local procedure CreateAccountingPeriod()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.GetFiscalYearStartDate(WorkDate()) = 0D then begin
            AccountingPeriod.Init();
            AccountingPeriod."Starting Date" := CalcDate('<-CY>', WorkDate());
            AccountingPeriod."New Fiscal Year" := true;
            AccountingPeriod.Insert();
        end;
    end;

    local procedure LightInit()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Order");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
    end;

    local procedure InitGlobalVariables()
    begin
        Clear(TempDocumentEntry2);
        Clear(PostingDate2);
        DocumentNo2 := '';
    end;

    local procedure CreatePurchDocWithGLDescriptionLine(var PurchaseHeader: Record "Purchase Header"; var Description: Text[100]; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandIntInRange(2, 5));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type, PurchaseLine."No.", 0);
        PurchaseLine."No." := '';
        PurchaseLine.Description := LibraryUtility.GenerateGUID();
        PurchaseLine.Modify();
        Description := PurchaseLine.Description;
    end;

    local procedure CreateAnalysisColumnWithItemLedgerEntryType(ItemAnalysisViewAnalysisArea: Enum "Analysis Area Type"; ItemLedgerEntryTypeFilter: Text[250]; ValueType: Enum "Analysis Value Type"): Code[10]
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, ItemAnalysisViewAnalysisArea);
        LibraryVariableStorage.Enqueue(
          CreateAnalysisColumn(AnalysisColumnTemplate.Name, ItemAnalysisViewAnalysisArea, ItemLedgerEntryTypeFilter, ValueType));
        exit(AnalysisColumnTemplate.Name);
    end;

    local procedure CreateAnalysisMultipleColumns(ItemAnalysisViewAnalysisArea: Enum "Analysis Area Type"; ItemLedgerEntryTypeFilter: Text[250]; ValueType: Enum "Analysis Value Type"; ColumnCount: Integer): Code[10]
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
        Index: Integer;
    begin
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, ItemAnalysisViewAnalysisArea);
        for Index := 1 to ColumnCount do
            CreateAnalysisColumn(AnalysisColumnTemplate.Name, ItemAnalysisViewAnalysisArea, ItemLedgerEntryTypeFilter, ValueType);
        LibraryVariableStorage.Enqueue(ColumnCount);
        exit(AnalysisColumnTemplate.Name);
    end;

    local procedure CreateAnalysisColumn(ColumnTemplateName: Code[10]; ItemAnalysisViewAnalysisArea: Enum "Analysis Area Type"; ItemLedgerEntryTypeFilter: Text[250]; ValueType: Enum "Analysis Value Type"): Text[50]
    var
        AnalysisColumn: Record "Analysis Column";
    begin
        LibraryERM.CreateAnalysisColumn(AnalysisColumn, ItemAnalysisViewAnalysisArea, ColumnTemplateName);
        AnalysisColumn.Validate("Column No.", CopyStr(LibraryUtility.GenerateGUID(), 1, AnalysisColumn.FieldNo("Column No.")));
        AnalysisColumn.Validate(
          "Column Header",
          CopyStr(
            LibraryUtility.GenerateRandomCode(AnalysisColumn.FieldNo("Column Header"), DATABASE::"Analysis Column"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Analysis Column", AnalysisColumn.FieldNo("Column Header"))));
        AnalysisColumn.Validate("Item Ledger Entry Type Filter", ItemLedgerEntryTypeFilter);
        AnalysisColumn.Validate("Value Type", ValueType);
        AnalysisColumn.Modify(true);
        exit(AnalysisColumn."Column Header");
    end;

    local procedure CreateAnalysisLineWithTypeVendor(ItemAnalysisViewAnalysisArea: Enum "Analysis Area Type"; VendorNo: Code[20]): Code[10]
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, ItemAnalysisViewAnalysisArea);
        LibraryInventory.CreateAnalysisLine(AnalysisLine, ItemAnalysisViewAnalysisArea, AnalysisLineTemplate.Name);
        AnalysisLine.Validate(Type, AnalysisLine.Type::Vendor);
        AnalysisLine.Validate(Range, VendorNo);
        AnalysisLine.Modify(true);
        exit(AnalysisLine."Analysis Line Template Name");
    end;

    local procedure InvoicePostedPurchaseOrder(var InvoicePurchaseHeader: Record "Purchase Header"; PostedPurchaseHeader: Record "Purchase Header")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        LibraryPurchase.CreatePurchHeader(
          InvoicePurchaseHeader, InvoicePurchaseHeader."Document Type"::Invoice, PostedPurchaseHeader."Buy-from Vendor No.");
        ModifyPurchaseHeader(InvoicePurchaseHeader, InvoicePurchaseHeader."No.");

        PurchGetReceipt.SetPurchHeader(InvoicePurchaseHeader);
        PurchRcptHeader.SetRange("Order No.", PostedPurchaseHeader."No.");
        PurchRcptHeader.FindSet();
        repeat
            PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
            PurchGetReceipt.CreateInvLines(PurchRcptLine);
        until PurchRcptHeader.Next() = 0;
    end;

    local procedure CrMemoPostedPurchaseReturnOrder(var CrMemoPurchaseHeader: Record "Purchase Header"; PostedPurchaseHeader: Record "Purchase Header")
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
    begin
        LibraryPurchase.CreatePurchHeader(
          CrMemoPurchaseHeader, CrMemoPurchaseHeader."Document Type"::"Credit Memo", PostedPurchaseHeader."Buy-from Vendor No.");
        ModifyPurchaseHeader(CrMemoPurchaseHeader, CrMemoPurchaseHeader."No.");

        PurchGetReturnShipments.SetPurchHeader(CrMemoPurchaseHeader);
        ReturnShipmentHeader.SetRange("Return Order No.", PostedPurchaseHeader."No.");
        ReturnShipmentHeader.FindSet();
        repeat
            ReturnShipmentLine.SetRange("Document No.", ReturnShipmentHeader."No.");
            PurchGetReturnShipments.CreateInvLines(ReturnShipmentLine);
        until ReturnShipmentHeader.Next() = 0;
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateDropShipmentPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchaseLine."Drop Shipment" := true;
        PurchaseLine.Modify();
    end;

    local procedure CreatePostPurchaseInvoiceWithZeroAmount(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"): Code[20]
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Direct Unit Cost", 0);
        PurchaseLine.Modify();
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateBinAndBinContent(var Bin: Record Bin; Item: Record Item)
    var
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateBin(Bin, CreateLocationWithBinMandatory(), LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateAndUpdateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(CreateCurrency());
        Currency.Validate("Invoice Rounding Precision", 1);
        Currency.Validate("Amount Rounding Precision", 1);
        Currency.Validate("Amount Decimal Places", '0:0');
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateDefaultDimensions(var DimensionValue1: Record "Dimension Value"; var DimensionValue2: Record "Dimension Value"; GLAccountNo: Code[20]; ItemNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue1, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue2, GeneralLedgerSetup."Shortcut Dimension 2 Code");
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccountNo, DimensionValue1."Dimension Code", DimensionValue1.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, DimensionValue2."Dimension Code", DimensionValue2.Code);
    end;

    local procedure CreateExchangeRates(CurrencyCode: Code[10]; StartingDate: Date; ExchangeRateAmount: Decimal; RelationalExchangeRate: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchangeRate);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelationalExchangeRate);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateExtendedText(var Item: Record Item)
    var
        ExtendedTextHeader: Record "Extended Text Header";
    begin
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("Purchase Order", true);
        ExtendedTextHeader.Modify(true);
        CreateExtendedTextLine(ExtendedTextHeader);
        CreateExtendedTextLine(ExtendedTextHeader);
    end;

    local procedure CreateExtendedTextLine(ExtendedTextHeader: Record "Extended Text Header")
    var
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateGUID());
        ExtendedTextLine.Modify(true);
    end;

    local procedure CreateInvoiceDiscount(var VendorInvoiceDisc: Record "Vendor Invoice Disc.")
    begin
        // Enter Random Values for "Minimum Amount" and "Discount %".
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, CreateVendor(), '', LibraryRandom.RandInt(100));
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandInt(20));
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
    end;

    local procedure CreatePurchaseDocumentWithLocation(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType);
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLines(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        // Random Values used are not important.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithQty(var PurchaseLine: Record "Purchase Line"; Qty: Decimal; DocType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), Qty);
    end;

    local procedure CreatePurchLineWithExtTexts(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item; Qty: Integer)
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        TransferExtendedText.PurchCheckIfAnyExtText(PurchaseLine, false);
        TransferExtendedText.InsertPurchExtText(PurchaseLine);
    end;

    local procedure CreatePurchaseOrderChargeItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType);
        CreatePurchaseLines(PurchaseLine, PurchaseHeader);
    end;

    local procedure CreateAndReceivePurchaseOrderChargeItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        CreatePurchaseOrderChargeItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);
        OpenItemChargeAssgnt(PurchaseLine, true, PurchaseLine.Quantity);

        PurchaseLine.Validate("Qty. to Receive", 0);
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreatePurchaseOrderWithChargeItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Qty: Decimal)
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), Qty);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateSimplePurchLine(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; LineType: Enum "Purchase Line Type")
    begin
        CreateSimplePurchLine(PurchLine, PurchHeader, LineType, 0);
    end;

    local procedure CreateSimplePurchLine(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; LineType: Enum "Purchase Line Type"; LineNo: Integer)
    var
        RecRef: RecordRef;
    begin
        PurchLine.Init();
        PurchLine.Validate("Document Type", PurchHeader."Document Type");
        PurchLine.Validate("Document No.", PurchHeader."No.");
        if LineNo = 0 then begin
            RecRef.GetTable(PurchLine);
            PurchLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PurchLine.FieldNo("Line No.")))
        end else
            PurchLine.Validate("Line No.", LineNo);
        PurchLine.Validate(Type, LineType);
        PurchLine.Insert(true);
    end;

    local procedure CreatePurchaseDocumentWithSingleLineWithQuantity(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; LineQuantity: Decimal)
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();

        CreateInvoiceDiscountForVendor(
          VendorInvoiceDisc, VendorNo, LibraryRandom.RandIntInRange(10, 100), LibraryRandom.RandIntInRange(10, 20));

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        CreatePurchLineWithItem(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Quantity, LineQuantity);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchOrderWithUniqueDescriptionLines(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type")
    var
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        for i := 1 to LibraryRandom.RandIntInRange(3, 7) do begin
            case Type of
                PurchaseLine.Type::"G/L Account":
                    LibraryPurchase.CreatePurchaseLine(
                      PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
                PurchaseLine.Type::Item:
                    LibraryPurchase.CreatePurchaseLine(
                      PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
            end;
            PurchaseLine.Description :=
              COPYSTR(
                LibraryUtility.GenerateRandomAlphabeticText(MAXSTRLEN(PurchaseLine.Description), 1),
                1,
                MAXSTRLEN(PurchaseLine.Description));
            PurchaseLine.Modify();
            TempPurchaseLine := PurchaseLine;
            TempPurchaseLine.Insert();
        end;
    end;

    local procedure CreatePurchOrderWithSameAccountLines(var PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; LineCount: Integer): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        AccountNo: Code[20];
        i: Integer;
    begin
        AccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        for i := 1 to LineCount do
            case Type of
                PurchaseLine.Type::"G/L Account":
                    LibraryPurchase.CreatePurchaseLine(
                      PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", AccountNo, 1);
            end;
        exit(AccountNo);
    end;

    local procedure FindPurchRcptHeader(var PurchRcptHeader: Record "Purch. Rcpt. Header"; OrderNo: Code[20])
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindFirst();
    end;

    local procedure FindPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", OrderNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure CreatePurchaseOrderAndPost(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"): Code[20]
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        CreatePurchaseLines(PurchaseLine, PurchaseHeader);
        PurchaseLine.ShowItemChargeAssgnt();
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure CreatePurchaseOrderWithJob(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(20, 2));
        ModifyPurchaseLineJobNo(PurchaseLine, Job."No.", JobTask."Job Task No.", UnitOfMeasureCode);
    end;

    local procedure CreatePurchOrderWithJobAndJobItemPrice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; var UnitCostFactor: Decimal)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobItemPrice: Record "Job Item Price";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobItemPrice(JobItemPrice, Job."No.", '', ItemNo, '', '', UnitOfMeasureCode);
        UnitCostFactor := LibraryRandom.RandDec(1, 2);
        JobItemPrice.Validate("Unit Cost Factor", UnitCostFactor);
        JobItemPrice.Modify(true);
        CopyJobItemPriceToPriceListLine();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
        ModifyPurchaseLineJobNo(PurchaseLine, Job."No.", JobTask."Job Task No.", UnitOfMeasureCode);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CopyJobItemPriceToPriceListLine()
    var
        JobItemPrice: Record "Job Item Price";
        PriceListLine: Record "Price List Line";
    begin
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);
    end;

    local procedure CreatePostPurchOrderWithDimension(var PurchHeader: Record "Purchase Header"; ItemDimValue: Record "Dimension Value"; DimensionCode: Code[20]; DimValueCode: Code[20]): Integer
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, CreateItem(), LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        ModifyDimOnPurchaseLine(PurchLine, ItemDimValue, DimensionCode, DimValueCode);
        PurchLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        exit(PurchLine."Dimension Set ID");
    end;

    local procedure CreatePostInvoiceWithReceiptLines(ItemChargeDimValue: Record "Dimension Value"; DimensionCode: Code[20]; DimValueCode: Code[20]; OrderPurchHeader: Record "Purchase Header"): Integer
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, OrderPurchHeader."Buy-from Vendor No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"Charge (Item)", CreateItemCharge(), LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        ModifyDimOnPurchaseLine(PurchLine, ItemChargeDimValue, DimensionCode, DimValueCode);
        PurchLine.Modify(true);
        AssignItemChargeToReceipt(OrderPurchHeader."No.", PurchLine);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        exit(PurchLine."Dimension Set ID");
    end;

    local procedure CreatePostPurchInvWithGetReceiptLines(ChargePurchHeader: Record "Purchase Header")
    var
        PurchHeader: Record "Purchase Header";
        TempPurchRcptLine: Record "Purch. Rcpt. Line" temporary;
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, ChargePurchHeader."Buy-from Vendor No.");
        FillBufferOfRcptLinesByOrderNo(TempPurchRcptLine, ChargePurchHeader."No.");
        PurchGetReceipt.SetPurchHeader(PurchHeader);
        PurchGetReceipt.CreateInvLines(TempPurchRcptLine);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
    end;

    local procedure CreatePostPurchDocWithAutoExtText(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; PostInvoice: Boolean): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithAutoExtendedText(), LibraryRandom.RandInt(10));
        TransferExtendedText.PurchCheckIfAnyExtText(PurchaseLine, true);
        TransferExtendedText.InsertPurchExtText(PurchaseLine);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, PostInvoice));
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(100));
    end;

    local procedure CreateStandardTextLine(var PurchLine: Record "Purchase Line"; var PurchHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, CreateItem(), 0);
        PurchLine.Validate(Type, PurchLine.Type::" ");
        PurchLine.Validate("No.", FindStandardTextCode());
        PurchLine.Modify(true);
    end;

    local procedure CreateReceivePurchOrderWithJobUnitPrices(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ItemNo: Code[20]; JobTask: Record "Job Task")
    begin
        CreatePurchaseOrder(PurchHeader, PurchLine, ItemNo);
        PurchLine.Validate("Job No.", JobTask."Job No.");
        PurchLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchLine.Validate("Job Unit Price", LibraryRandom.RandDec(100, 2));
        PurchLine.Validate("Job Total Price", PurchLine.Quantity * PurchLine."Job Unit Price");
        PurchLine.Validate("Job Line Amount", PurchLine."Job Total Price");
        PurchLine.Validate("Job Line Discount %", LibraryRandom.RandIntInRange(3, 5));
        PurchLine.Validate("Job Line Discount Amount", Round(PurchLine."Job Line Amount" * PurchLine."Job Line Discount %" / 100));
        PurchLine.Validate("Job Unit Price (LCY)", PurchLine."Job Unit Price");
        PurchLine.Validate("Job Total Price (LCY)", PurchLine."Job Total Price");
        PurchLine.Validate("Job Line Amount (LCY)", PurchLine."Job Line Amount");
        PurchLine.Validate("Job Line Disc. Amount (LCY)", PurchLine."Job Line Discount Amount");
        PurchLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
    end;

    local procedure CreateItemAndExtendedText(var Item: Record Item): Text[100]
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        UpdateTextInExtendedTextLine(ExtendedTextLine, Item."No.");
        exit(ExtendedTextLine.Text);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Modify Item No. Series in Inventory setup.
        InventorySetup.Get();
        InventorySetup.Validate("Item Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));  // Using RANDOM value for Unit Price.
        FindVATPostingSetup(VATPostingSetup);
        if VATPostingSetup."VAT Prod. Posting Group" <> Item."VAT Prod. Posting Group" then
            Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithDimension(var Item: Record Item; DimensionCode: Code[20]; ValuePosting: Enum "Default Dimension Value Posting Type")
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);

        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        if DimensionCode = '' then
            exit;
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
    end;

    local procedure CreateItemWithUnitPrice(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure CreateItemInventoryValueZero(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Inventory Value Zero", true);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Modify(true);
    end;

    local procedure CreateItemCharge(): Code[20]
    var
        ItemCharge: Record "Item Charge";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        exit(ItemCharge."No.");
    end;

    local procedure CreateItemWithUOMandStandartCost(var Item: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        CreateItemWithUnitPrice(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", LibraryRandom.RandInt(50));
        Item.Modify(true);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
    end;

    local procedure CreateItemWithAutoExtendedText(): Code[20]
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", true);
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        UpdateTextInExtendedTextLine(ExtendedTextLine, Item."No.");
        exit(Item."No.");
    end;

    local procedure CreateLocationWithBinMandatory(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        exit(Location.Code);
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

    local procedure CreateVendorWithDimension(var Vendor: Record Vendor; var DefaultDimension: Record "Default Dimension"; ValuePosting: Enum "Default Dimension Value Posting Type"; DimensionCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        if DimensionCode = '' then
            exit;
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateTempVendor(var TempVendor: Record Vendor temporary)
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.FindGenBusinessPostingGroup(GenBusinessPostingGroup);
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        TempVendor.Init();
        TempVendor.Validate("No.", GenerateVendorNo());
        TempVendor.Insert();
        TempVendor.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        TempVendor.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        TempVendor.Validate("Vendor Posting Group", LibraryPurchase.FindVendorPostingGroup());
        TempVendor.Modify(true);
    end;

    local procedure CreateVendorCard(var Vendor: Record Vendor)
    var
        VendorCard: TestPage "Vendor Card";
    begin
        VendorCard.OpenNew();
        Vendor.Rename(VendorCard."No.".Value);
        VendorCard."Gen. Bus. Posting Group".SetValue(Vendor."Gen. Bus. Posting Group");
        VendorCard."VAT Bus. Posting Group".SetValue(Vendor."VAT Bus. Posting Group");
        VendorCard."Vendor Posting Group".SetValue(Vendor."Vendor Posting Group");
        VendorCard.OK().Invoke();
    end;

    local procedure CreateVendorInvDiscount(): Code[20]
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, CreateVendor(), '', 0);
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        VendorInvoiceDisc.Modify(true);
        exit(VendorInvoiceDisc.Code);
    end;

    local procedure CreateDimValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure CreateDimValues(var Dimension: Record Dimension; var DimensionValueCode: array[2] of Code[20])
    var
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        LibraryDimension.CreateDimension(Dimension);
        for i := 1 to ArrayLen(DimensionValueCode) do begin
            LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
            DimensionValueCode[i] := DimensionValue.Code;
        end;
    end;

    local procedure CreateDimSetIDFromDimValue(var DimSetID: Integer; DimensionValue: Record "Dimension Value")
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionMgt: Codeunit DimensionManagement;
    begin
        if DimSetID <> 0 then
            DimensionMgt.GetDimensionSet(TempDimSetEntry, DimSetID);
        TempDimSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        if not TempDimSetEntry.Insert() then
            TempDimSetEntry.Modify();
        DimSetID := DimensionMgt.GetDimensionSetID(TempDimSetEntry);
    end;

    local procedure CreatePurchOrderWithPurchCode(var StandardPurchaseLine: Record "Standard Purchase Line"; var PurchaseHeader: Record "Purchase Header"; ShortCutDimension1: Code[20]; ShortCutDimension2: Code[20])
    var
        StandardPurchaseCode: Record "Standard Purchase Code";
    begin
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);
        LibraryPurchase.CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code);
        ModifyStandardPurchaseLine(StandardPurchaseLine, ShortCutDimension1, ShortCutDimension2);
        StandardPurchaseLine.Get(StandardPurchaseLine."Standard Purchase Code", StandardPurchaseLine."Line No.");
        CreateStandardPurchLineForPurchaseOrder(PurchaseHeader, StandardPurchaseCode.Code);
    end;

    local procedure CreateStandardPurchLineForPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; StandardPurchaseCode: Code[10])
    var
        Vendor: Record Vendor;
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorPurchaseCode(StandardVendorPurchaseCode, Vendor."No.", StandardPurchaseCode);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        Commit();  // COMMIT is required here.
        StandardVendorPurchaseCode.InsertPurchLines(PurchaseHeader);
    end;

    local procedure CreateAndPostPurchaseReceiptWithDimension(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        PurchaseLine: Record "Purchase Line";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);
        PurchaseLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure CreateAndPostPurchaseReceipt(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateVendor(), PurchaseHeader."Document Type"::Order);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure CreateStandardPurchaseDocument(var StandardPurchaseCode: Record "Standard Purchase Code"; GLAccountNo: Code[20]; ItemNo: Code[20])
    var
        StandardPurchaseLine: Record "Standard Purchase Line";
    begin
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);
        CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code, StandardPurchaseLine.Type::"G/L Account", GLAccountNo);
        CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code, StandardPurchaseLine.Type::Item, ItemNo);
    end;

    local procedure CreateStandardPurchaseLine(var StandardPurchaseLine: Record "Standard Purchase Line"; StandardPurchaseCode: Code[10]; StandardPurchLineType: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode);
        StandardPurchaseLine.Validate(Type, StandardPurchLineType);
        StandardPurchaseLine.Validate("No.", No);
        StandardPurchaseLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        StandardPurchaseLine.Modify(true);
    end;

    local procedure CreateVendorWithCurrency(var Vendor: Record Vendor)
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", Currency.Code);
        Vendor.Modify(true);
    end;

    local procedure CreatePurchaseHeaderWithCurrency(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        ModifyPurchaseHeader(PurchaseHeader, PurchaseHeader."No.");
    end;

    local procedure CreatePurchOrderAndGetDiscountWithoutVAT(var PurchHeader: Record "Purchase Header") ExpectedInvDiscAmount: Decimal
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, CreateVendorInvDiscount());
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchLine.Validate("Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchLine.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchLine);
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        ExpectedInvDiscAmount := PurchLine."Inv. Discount Amount";
    end;

    local procedure CreatePurchLineAndJobTask(var PurchaseLine: Record "Purchase Line"; var JobTask: Record "Job Task")
    var
        PurchaseHeader: Record "Purchase Header";
        Job: Record Job;
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        CreatePurchaseLineWithItem(PurchaseLine, PurchaseHeader, LibraryRandom.RandInt(10), 0);
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchLineWithCurrency(var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        CreatePurchaseLineWithItem(PurchaseLine, PurchaseHeader, LibraryRandom.RandInt(10), 0);
    end;

    local procedure CreateJobTaskWithCurrency(var JobTask: Record "Job Task"; CurrencyCode: Code[10])
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Currency Code", CurrencyCode);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateInvoiceDiscountForVendor(var VendorInvoiceDisc: Record "Vendor Invoice Disc."; VendorNo: Code[20]; ServiceCharge: Decimal; DiscountPercent: Decimal)
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorNo, '', 0);
        VendorInvoiceDisc.Validate("Service Charge", ServiceCharge);
        VendorInvoiceDisc.Validate("Discount %", DiscountPercent);
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreatePurchLineWithItem(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandIntInRange(10, 100), LibraryRandom.RandIntInRange(10, 100));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          Item."No.", LibraryRandom.RandIntInRange(10, 100));
    end;

    local procedure SetLocationInCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        Location: Record Location;
    begin
        CompanyInformation.Get();
        if CompanyInformation."Location Code" = '' then begin
            LibraryWarehouse.CreateLocation(Location);
            CompanyInformation.Validate("Location Code", Location.Code);
            CompanyInformation.Modify(true);
        end;
    end;

    local procedure CreateVendorWithDefaultLocation(var Vendor: Record Vendor)
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Location Code", Location.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorWithShipmentMethodCode(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Shipment Method Code", CreateShipmentMethodCode());
        Vendor.Modify(true);
    end;

    local procedure CreateShipmentMethodCode(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.Init();
        ShipmentMethod.Code := LibraryUtility.GenerateRandomCode(ShipmentMethod.FieldNo(Code), DATABASE::"Shipment Method");
        ShipmentMethod.Insert();
        exit(ShipmentMethod.Code);
    end;

    local procedure CreatePostPurchOrderForUndoReceipt(var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; AccountType: Enum "Purchase Line Type"; AccountNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader,
            PurchaseHeader."Document Type"::Order,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            AccountType,
            AccountNo,
            LibraryRandom.RandDec(20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(200, 2));
        PurchaseLine.Modify();

        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / LibraryRandom.RandIntInRange(2, 4)); // To make sure Qty. to Receive must be less than Quantity.
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreatePostPurchReturnOrderForUndoShipment(var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; AccountType: Enum "Purchase Line Type"; AccountNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader,
            PurchaseHeader."Document Type"::"Return Order",
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            AccountType,
            AccountNo,
            LibraryRandom.RandDec(20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(200, 2));
        PurchaseLine.Modify();

        PurchaseLine.Validate("Return Qty. to Ship", PurchaseLine.Quantity / LibraryRandom.RandIntInRange(2, 4)); // To make sure Return Qty. to Ship must be less than Quantity.
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure UpdateDefaultWarehouseSetup(RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean)
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Require Put-away", RequirePutAway);
        WarehouseSetup.Validate("Require Pick", RequirePick);
        WarehouseSetup.Validate("Require Receive", RequireReceive);
        WarehouseSetup.Validate("Require Shipment", RequireShipment);
        WarehouseSetup.Modify(true);
    end;

    local procedure MockFixedAsset(var FADepreciationBook: Record "FA Depreciation Book"; Disposed: Boolean);
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Modify(true);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        if Disposed then
            FADepreciationBook.Validate("Disposal Date", WorkDate());
        FADepreciationBook.Modify(true);
    end;

    local procedure MockGLAccountWithNoAndDescription(NewNo: Code[20]; NewName: Text[100])
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        GLAccount.Init();
        GLAccount."No." := NewNo;
        GLAccount.Name := NewName;
        GLAccount."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        GLAccount."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        GLAccount.Insert();
    end;

    local procedure MockItemWithNoAndDescription(NewNo: Code[20]; NewDescription: Text[100])
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        if not InventoryPostingGroup.FindFirst() then
            LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);

        Item.Init();
        Item."No." := NewNo;
        Item.Description := NewDescription;
        Item."Inventory Posting Group" := InventoryPostingGroup.Code;
        Item."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        Item."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        Item.Insert();
    end;

    local procedure MockItemChargeWithNoAndDescription(NewNo: Code[20]; NewDescription: Text[100])
    var
        ItemCharge: Record "Item Charge";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);

        ItemCharge.Init();
        ItemCharge."No." := NewNo;
        ItemCharge.Description := NewDescription;
        ItemCharge."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        ItemCharge."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        ItemCharge.Insert();
    end;

    local procedure MockFAWithNoAndDescription(NewNo: Code[20]; NewDescription: Text[100])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.Init();
        FixedAsset."No." := NewNo;
        FixedAsset.Description := NewDescription;
        FixedAsset.Insert();
    end;

    local procedure MockStandardText(NewCode: Code[20]; NewDescription: Text[50])
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.Init();
        StandardText.Code := NewCode;
        StandardText.Description := NewDescription;
        StandardText.Insert();
    end;

    local procedure MockPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := DocumentNo;
        PurchaseHeader.Insert();
    end;

    local procedure MockPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := LibraryUtility.GetNewRecNo(PurchaseLine, PurchaseLine.FieldNo("Line No."));
        PurchaseLine.Insert();
    end;

    local procedure MockPurchaseLineWithReceivedNotInvLCY(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ReceivedNotInv_Base: Decimal; ReceivedNotInv: Decimal)
    begin
        MockPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine."A. Rcd. Not Inv. Ex. VAT (LCY)" := ReceivedNotInv_Base;
        PurchaseLine."Amt. Rcd. Not Invoiced" := ReceivedNotInv;
        PurchaseLine.Modify();
    end;

    local procedure PostReceivePurchOrderWithVAT(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchHeader: Record "Purchase Header")
    begin
        PurchHeader.Validate("Prices Including VAT", true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
        FindPurchRcptLine(PurchRcptLine, PurchHeader."No.");
    end;

    local procedure InitPurchaseLine(PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    begin
        PurchaseLine.Init();
        PurchaseLine."Document Type" := DocumentType;
        PurchaseLine."Document No." := LibraryUtility.GenerateGUID();
        PurchaseLine."Line No." := LibraryRandom.RandIntInRange(1000, 2000);
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := '';
        PurchaseLine.Description := LibraryUtility.GenerateGUID();
        PurchaseLine.Quantity := LibraryRandom.RandDecInRange(300, 400, 2);
        PurchaseLine."Qty. to Receive" := LibraryRandom.RandDecInRange(200, 300, 2);
        PurchaseLine."Qty. to Receive (Base)" := LibraryRandom.RandDecInRange(200, 300, 2);
        PurchaseLine."Qty. to Invoice" := LibraryRandom.RandDecInRange(100, 200, 2);
        PurchaseLine."Qty. to Invoice (Base)" := LibraryRandom.RandDecInRange(100, 200, 2);
        PurchaseLine."Return Qty. to Ship" := LibraryRandom.RandDecInRange(200, 300, 2);
        PurchaseLine."Return Qty. to Ship (Base)" := LibraryRandom.RandDecInRange(200, 300, 2);
    end;

    local procedure ValidatePurchaseLineStandardCode(var PurchaseLine: Record "Purchase Line"; StandardTextCode: Code[20])
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        PurchaseLine.Validate("No.", StandardTextCode);
        PurchaseLine.Modify(true);
        TransferExtendedText.PurchCheckIfAnyExtText(PurchaseLine, false);
        TransferExtendedText.InsertPurchExtText(PurchaseLine);
    end;

    local procedure FindDifferentDimension("Code": Code[20]): Code[20]
    var
        Dimension: Record Dimension;
    begin
        Dimension.SetFilter(Code, '<>%1', Code);
        LibraryDimension.FindDimension(Dimension);
        exit(Dimension.Code);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
    end;

    local procedure FindReceiptLineNo(DocumentNo: Code[20]): Integer
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Document No.", DocumentNo);
        PurchRcptLine.FindFirst();
        exit(PurchRcptLine."Line No.");
    end;

    local procedure FindPurchInvLine(var PurchInvLine: Record "Purch. Inv. Line"; DocumentNo: Code[20])
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        PurchInvLine.FindFirst();
    end;

    local procedure FindPurchReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", OrderNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure FindPurchReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; ReturnOrderNo: Code[20])
    begin
        ReturnShipmentLine.SetRange("Return Order No.", ReturnOrderNo);
        ReturnShipmentLine.FindFirst();
    end;

    local procedure FindStandardTextCode(): Code[20]
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.Next(LibraryRandom.RandInt(StandardText.Count));
        exit(StandardText.Code);
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; ItemNo: Code[20]; SourceNo: Code[20]; DocumentNo: Code[20])
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Source No.", SourceNo);
        ValueEntry.FindFirst();
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FindShptLine(var SalesShptLine: Record "Sales Shipment Line"; OrderNo: Code[20])
    var
        SalesShptHeader: Record "Sales Shipment Header";
    begin
        SalesShptHeader.SetRange("Order No.", OrderNo);
        SalesShptHeader.FindLast();
        SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
        SalesShptLine.FindLast();
    end;

    local procedure FindRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        FindPurchRcptHeader(PurchRcptHeader, OrderNo);
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.FindFirst();
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure FillBufferOfRcptLinesByOrderNo(var PassedPurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindSet();
        repeat
            PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
            PurchRcptLine.FindFirst();
            PassedPurchRcptLine := PurchRcptLine;
            PassedPurchRcptLine.Insert();
        until PurchRcptHeader.Next() = 0;
    end;

    local procedure FindPurchaseLineWithType(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type"; LineType: Enum "Purchase Line Type")
    begin
        PurchaseLine.SetRange(Type, LineType);
        FindPurchaseLine(PurchaseLine, DocumentNo, DocumentType);
    end;

    local procedure FindItemChargeAssignmentPurchLine(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchaseLine: Record "Purchase Line")
    begin
        ItemChargeAssignmentPurch.SetRange("Document Type", PurchaseLine."Document Type");
        ItemChargeAssignmentPurch.SetRange("Document No.", PurchaseLine."Document No.");
        ItemChargeAssignmentPurch.SetRange("Document Line No.", PurchaseLine."Line No.");
        ItemChargeAssignmentPurch.FindSet();
    end;

    local procedure GetDimensionSetId(PostedDocumentNo: Code[20]): Integer
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Document No.", PostedDocumentNo);
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.FindFirst();
        exit(PurchRcptLine."Dimension Set ID");
    end;

    local procedure GetReceiptLine(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Receipt", PurchaseLine);
    end;

    local procedure GetPayablesAccountNo(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        exit(VendorPostingGroup."Payables Account");
    end;

    local procedure GetPurchAccountNo(GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroupCode, GenProdPostingGroupCode);
        exit(GeneralPostingSetup."Purch. Account");
    end;

    local procedure GetPostedDocLinesToReverse(var PurchaseHeader: Record "Purchase Header"; OptionString: Option; DocumentNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(OptionString);
        LibraryVariableStorage.Enqueue(DocumentNo);
        PurchaseHeader.GetPstdDocLinesToReverse();
    end;

    local procedure PurchaseCopyDocument(PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type From")
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters(DocumentType, DocumentNo, true, false);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run();
    end;

    local procedure ModifyWarehouseLocation(RequireReceive: Boolean): Code[10]
    var
        Location: Record Location;
    begin
        Location.SetRange("Bin Mandatory", false);
        Location.SetRange("Use As In-Transit", false);
        Location.FindFirst();
        Location.Validate("Require Receive", RequireReceive);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure ModifyPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorInvoiceNo: Code[20])
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", VendorInvoiceNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure ModifyPurchaseLineQtyToReceive(var PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal)
    begin
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure ModifyPurchaseLineJobNo(var PurchaseLine: Record "Purchase Line"; JobNo: Code[20]; JobTaskNo: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        PurchaseLine.Validate("Job No.", JobNo);
        PurchaseLine.Validate("Job Task No.", JobTaskNo);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Modify(true);
    end;

    local procedure ModifyLocationOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Location Code", ModifyWarehouseLocation(true));
        PurchaseLine.Modify(true);
    end;

    local procedure ModifyStandardPurchaseLine(StandardPurchaseLine: Record "Standard Purchase Line"; ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        StandardPurchaseLine.Validate(Type, StandardPurchaseLine.Type::Item);
        StandardPurchaseLine.Validate("No.", Item."No.");
        StandardPurchaseLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        StandardPurchaseLine.Validate("Shortcut Dimension 1 Code", ShortcutDimension1Code);
        StandardPurchaseLine.Validate("Shortcut Dimension 2 Code", ShortcutDimension2Code);
        StandardPurchaseLine.Modify(true);
    end;

    local procedure ModifyDirectUnitCost(var PurchaseHeader: Record "Purchase Header"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindLast();
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        exit(PurchaseLine."Direct Unit Cost");
    end;

    local procedure ModifyDimOnPurchaseLine(var PurchLine: Record "Purchase Line"; BaseDimValue: Record "Dimension Value"; DimensionCode: Code[20]; DimValueCode: Code[20])
    var
        DimValue: Record "Dimension Value";
    begin
        CreateDimSetIDFromDimValue(PurchLine."Dimension Set ID", BaseDimValue);
        DimValue.Get(DimensionCode, DimValueCode);
        CreateDimSetIDFromDimValue(PurchLine."Dimension Set ID", DimValue);
    end;

    local procedure ModifyItemIndirectCost(var Item: Record Item)
    begin
        Item.Validate("Indirect Cost %", 10);
        Item.Modify(true);
    end;

    local procedure ModifyFullPrepmtAndLocationOnPurchLine(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    begin
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Prepayment %", 100);
        PurchaseLine.Modify(true);
    end;

    local procedure ChangeQtyToInvoice(var InvPurchLine: Record "Purchase Line"; InvPurchHeader: Record "Purchase Header")
    begin
        InvPurchLine.SetRange("Document Type", InvPurchHeader."Document Type");
        InvPurchLine.SetRange("Document No.", InvPurchHeader."No.");
        InvPurchLine.SetRange(Type, InvPurchLine.Type::Item);
        InvPurchLine.FindFirst();
        InvPurchLine.Validate("Qty. to Invoice", Round(InvPurchLine.Quantity / LibraryRandom.RandIntInRange(3, 5)));
        InvPurchLine.Modify(true);
    end;

    local procedure AssignItemChargeToReceipt(OrderNo: Code[20]; PurchLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        FindRcptLine(PurchRcptLine, OrderNo);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");
    end;

    local procedure AssignItemChargeToShipment(OrderNo: Code[20]; PurchLine: Record "Purchase Line")
    var
        SalesShptLine: Record "Sales Shipment Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        FindShptLine(SalesShptLine, OrderNo);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Sales Shipment",
          SalesShptLine."Document No.", SalesShptLine."Line No.", SalesShptLine."No.");
        ItemChargeAssignmentPurch.Validate("Qty. to Assign", PurchLine."Qty. to Receive");
        ItemChargeAssignmentPurch.Modify(true);
    end;

    local procedure OpenPurchaseOrder(PurchaseHeaderNo: Code[20]; BuyFromVendorNo: Code[20]; Status: Enum "Purchase Document Status")
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter(Status, Format(Status));
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeaderNo);
        PurchaseOrder."Buy-from Vendor Name".AssertEquals(BuyFromVendorNo);
        PurchaseOrder.OK().Invoke();
    end;

    local procedure OpenAnalysisReportPurchase(AnalysisReportName: Code[10]; AnalysisLineTemplateName: Code[10]; AnalysisColumnTemplateName: Code[10])
    var
        AnalysisReportPurchase: TestPage "Analysis Report Purchase";
    begin
        AnalysisReportPurchase.OpenEdit();
        AnalysisReportPurchase.FILTER.SetFilter(Name, AnalysisReportName);
        AnalysisReportPurchase."Analysis Line Template Name".SetValue(AnalysisLineTemplateName);
        AnalysisReportPurchase."Analysis Column Template Name".SetValue(AnalysisColumnTemplateName);
        AnalysisReportPurchase.EditAnalysisReport.Invoke();
    end;

    local procedure OpenItemChargeAssgnt(PurchaseLine: Record "Purchase Line"; IsSetup: Boolean; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(IsSetup);
        LibraryVariableStorage.Enqueue(Qty);
        PurchaseLine.ShowItemChargeAssgnt();
    end;

    local procedure ReceiveWarehouseDocument(DocumentNo: Code[20]; LineNo: Integer)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source No.", DocumentNo);
        WarehouseReceiptLine.SetRange("Source Line No.", LineNo);
        WarehouseReceiptLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Receipt", WarehouseReceiptLine);
    end;

    local procedure RunDeleteInvoicePurchaseReport(BuyFromVendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        DeleteInvoicedPurchOrders: Report "Delete Invoiced Purch. Orders";
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        DeleteInvoicedPurchOrders.UseRequestPage(false);
        DeleteInvoicedPurchOrders.SetTableView(PurchaseHeader);
        DeleteInvoicedPurchOrders.Run();
    end;

    local procedure ModifyPostingDateOnWarehouseReceiptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceNo: Code[20]; ItemNo: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        WarehouseReceiptHeader.Validate("Posting Date", CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(6)), WorkDate()));
        WarehouseReceiptHeader.Modify(true);
    end;

    local procedure SetupInvoiceDiscount(var VendorInvoiceDisc: Record "Vendor Invoice Disc.")
    begin
        // Required Random Value for "Minimum Amount" and "Discount %" fields value is not important.
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, CreateVendor(), '', LibraryRandom.RandInt(100));
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandInt(10));
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exits before creating
        // General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure SetupLineDiscount(var PurchaseLineDiscount: Record "Purchase Line Discount")
    var
        Item: Record Item;
    begin
        // Required Random Value for "Minimum Quantity" and "Line Discount %" fields value is not important.
        Item.Get(CreateItem());
        LibraryERM.CreateLineDiscForVendor(
          PurchaseLineDiscount, Item."No.", CreateVendor(), WorkDate(), '', '', Item."Base Unit of Measure", LibraryRandom.RandInt(10));
        PurchaseLineDiscount.Validate("Line Discount %", LibraryRandom.RandInt(10));
        PurchaseLineDiscount.Modify(true);
    end;

    local procedure SetPurchSetupCopyLineDescrToGLEntry(CopyLineDescrToGLEntry: Boolean)
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup."Copy Line Descr. to G/L Entry" := CopyLineDescrToGLEntry;
        PurchSetup.Modify();
    end;

    local procedure CalculateTotalCostLCY(PurchaseLine: Record "Purchase Line"): Decimal
    var
        Currency: Record Currency;
        UnitCostLCY: Decimal;
    begin
        if PurchaseLine."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(PurchaseLine."Currency Code");
        UnitCostLCY :=
          Round(PurchaseLine."Unit Cost" / PurchaseLine."Qty. per Unit of Measure",
            Currency."Unit-Amount Rounding Precision");
        exit(
          Round(
            UnitCostLCY * PurchaseLine."Qty. to Invoice" * PurchaseLine."Qty. per Unit of Measure",
            Currency."Amount Rounding Precision"));
    end;

    local procedure UpdateAutomaticCostPosting(var OldAutomaticCostPosting: Boolean; NewAutomaticCostPosting: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        OldAutomaticCostPosting := InventorySetup."Automatic Cost Posting";
        InventorySetup.Validate("Automatic Cost Posting", NewAutomaticCostPosting);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateDefaultPostingDate(NewDefaultPostingDate: Enum "Default Posting Date")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Default Posting Date", NewDefaultPostingDate);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateTextInExtendedTextLine(var ExtendedTextLine: Record "Extended Text Line"; Text: Code[20])
    begin
        ExtendedTextLine.Validate(Text, Text);
        ExtendedTextLine.Modify(true);
    end;

    local procedure UpdateVendorLedgerEntry(DocumentNo: Code[20]; DueDate: Date; PmtDiscountDate: Date; RemainingPmtDiscPossible: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.FILTER.SetFilter("Document No.", DocumentNo);
        VendorLedgerEntries.FILTER.SetFilter("Document Type", Format(VendorLedgerEntry."Document Type"::Invoice));
        VendorLedgerEntries."Due Date".SetValue(DueDate);
        VendorLedgerEntries."Pmt. Discount Date".SetValue(PmtDiscountDate);
        VendorLedgerEntries."Remaining Pmt. Disc. Possible".SetValue(RemainingPmtDiscPossible);
        VendorLedgerEntries.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure UpdateVATAmountOnPurchaseOrderStatistics(var PurchaseHeader: Record "Purchase Header"; var PurchaseOrder: TestPage "Purchase Order")
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.Statistics.Invoke();
        PurchaseOrder.GotoRecord(PurchaseHeader);
    end;
#endif

    local procedure UpdateVATAmountOnPurchaseOrderStats(var PurchaseHeader: Record "Purchase Header"; var PurchaseOrder: TestPage "Purchase Order")
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchaseOrderStatistics.Invoke();
        PurchaseOrder.GotoRecord(PurchaseHeader);
    end;

    local procedure UpdateDimensionSetID(var StandardPurchaseLine: Record "Standard Purchase Line"; DifferentDimension: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetID: Integer;
    begin
        LibraryDimension.FindDimensionValue(DimensionValue, DifferentDimension);
        DimensionSetID := LibraryDimension.CreateDimSet(StandardPurchaseLine."Dimension Set ID", DifferentDimension, DimensionValue.Code);
        StandardPurchaseLine.Validate("Dimension Set ID", DimensionSetID);
        StandardPurchaseLine.Modify(true);
    end;

    local procedure UpdateDefaultQtyToReceive(NewDefaultQtyToReceive: Option)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Default Qty. to Receive", NewDefaultQtyToReceive);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure AssignQtyToOneLine(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchaseLine: Record "Purchase Line"; QtyToAssign: Decimal)
    begin
        FindItemChargeAssignmentPurchLine(ItemChargeAssignmentPurch, PurchaseLine);
        repeat
            ItemChargeAssignmentPurch.Validate("Qty. to Assign", 0);
            ItemChargeAssignmentPurch.Modify(true);
        until ItemChargeAssignmentPurch.Next() = 0;
        ItemChargeAssignmentPurch.Validate("Qty. to Assign", QtyToAssign);
        ItemChargeAssignmentPurch.Modify(true);
    end;

    local procedure SetPostedInvoiceNosEqualInvoiceNosInPurchSetup(var PurchasesPayablesSetup: Record "Purchases & Payables Setup")
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Validate("Invoice Nos.", PurchasesPayablesSetup."Posted Invoice Nos.");
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure GenerateVendorNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        exit(CopyStr(LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor),
            1, LibraryUtility.GetFieldLength(DATABASE::Vendor, Vendor.FieldNo("No."))));
    end;

    local procedure CreatePostPurchaseOrder(): Code[20]
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Integer;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        Qty := LibraryRandom.RandInt(10);
        CreatePurchaseLineWithItem(PurchaseLine, PurchaseHeader, Qty, Qty);
        CreatePurchaseLineWithItem(PurchaseLine, PurchaseHeader, Qty, 0);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        exit(PurchaseHeader."No.");
    end;

    local procedure CreatePurchaseLineWithItem(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Qty: Decimal; QtyToReceive: Decimal)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item,
          LibraryRandom.RandDec(1000, 2),
          LibraryRandom.RandDec(1000, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateCopyPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; FromPurchaseOrderNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue("Purchase Document Type From"::Order);
        LibraryVariableStorage.Enqueue(FromPurchaseOrderNo);
        CopyPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseHeader."No.");
    end;

    local procedure CopyPurchaseDocument(PurchaseHeader: Record "Purchase Header")
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        Commit();
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.RunModal();
    end;

    local procedure CreatePurchHeaderWithVATBaseDisc(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        PurchaseHeader."VAT Bus. Posting Group" := VATBusinessPostingGroup.Code;
        PurchaseHeader."VAT Base Discount %" := LibraryRandom.RandInt(10);
        PurchaseHeader.Modify();
    end;

    local procedure CreateVATPostingSetupWithBusPostGroup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; VATBusinessPostingGroup: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup."VAT %" := LibraryRandom.RandInt(30);
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup."Reverse Chrg. VAT Acc." := VATPostingSetup."Purchase VAT Account";
        VATPostingSetup."VAT Calculation Type" := VATCalculationType;
        VATPostingSetup."VAT Identifier" := LibraryUtility.GenerateGUID();
        VATPostingSetup.Modify();
    end;

    local procedure CreatePurchaseLineWithVATType(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATType: Enum "Tax Calculation Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        CreateVATPostingSetupWithBusPostGroup(
          VATPostingSetup,
          VATType,
          PurchaseHeader."VAT Bus. Posting Group");

        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 10000));
        PurchaseLine.Modify();
    end;

    local procedure VerifyVATAmountLine(var TempVATAmountLine: Record "VAT Amount Line" temporary; VATIdentifier: Code[20]; VATCalculationType: Enum "Tax Calculation Type"; VATAmount: Decimal; AmountInclVAT: Decimal)
    begin
        TempVATAmountLine.SetRange("VAT Identifier", VATIdentifier);
        TempVATAmountLine.SetRange("VAT Calculation Type", VATCalculationType);
        TempVATAmountLine.FindFirst();
        TempVATAmountLine.TestField("VAT Amount", VATAmount);
        TempVATAmountLine.TestField("Amount Including VAT", AmountInclVAT);
    end;

    local procedure AllowVATDiscount()
    var
        GLSetup: Record "General Ledger Setup";
        PurchPayablesSetup: Record "Purchases & Payables Setup";
    begin
        GLSetup.Get();
        GLSetup."Pmt. Disc. Excl. VAT" := true;
        GLSetup.Modify();

        PurchPayablesSetup.Get();
        PurchPayablesSetup."Allow VAT Difference" := true;
        PurchPayablesSetup.Modify();
    end;

    local procedure PostPartialShipment(var SalesLine: Record "Sales Line"; QtyToShip: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure EnableVATDiffAmount() Result: Decimal
    begin
        Result := LibraryRandom.RandDec(2, 2);  // Use any Random decimal value between 0.01 and 1.99, value is not important.
        LibraryERM.SetMaxVATDifferenceAllowed(Result);
        LibraryPurchase.SetAllowVATDifference(true);
    end;

    local procedure CreatePurchaseInvoiceWithItemCharge(var InvoicePurchaseHeader: Record "Purchase Header"; PostedPurchaseHeader: Record "Purchase Header"; PricesIncludingVAT: Boolean)
    var
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryPurchase.CreatePurchHeader(
          InvoicePurchaseHeader, InvoicePurchaseHeader."Document Type"::Invoice, PostedPurchaseHeader."Buy-from Vendor No.");

        InvoicePurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        InvoicePurchaseHeader.Modify(true);

        LibraryInventory.CreateItemCharge(ItemCharge);
        CreateVATPostingSetupWithBusPostGroup(
          VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          InvoicePurchaseHeader."VAT Bus. Posting Group");
        ItemCharge.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ItemCharge.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, InvoicePurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithItemsAndAssignedItemCharge(var PurchaseHeader: Record "Purchase Header"; SuggestType: Integer)
    var
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        for i := 1 to 3 do
            CreatePurchaseLineWithDirectUnitCost(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 10, 10);

        LibraryInventory.CreateItemCharge(ItemCharge);
        CreateVATPostingSetupWithBusPostGroup(
          VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          PurchaseHeader."VAT Bus. Posting Group");
        ItemCharge.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ItemCharge.Modify(true);

        CreatePurchaseLineWithDirectUnitCost(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.", 1, 100);

        LibraryVariableStorage.Enqueue(SuggestType);

        PurchaseLine.ShowItemChargeAssgnt();
    end;

    local procedure CreatePurchaseLineWithDirectUnitCost(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure PurchaseOrderItemChargeAssignment(var PurchaseLine: Record "Purchase Line"; var AmountToAssign: Decimal; var QtyToAssign: Decimal; SuggestChoice: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrderWithItemsAndAssignedItemCharge(PurchaseHeader, SuggestChoice);

        FindPurchaseLineWithType(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Document Type", PurchaseLine.Type::"Charge (Item)");
        AmountToAssign := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity;
        QtyToAssign := PurchaseLine.Quantity;
    end;

    local procedure PostPurchaseInvoiceWithItemCharge(var PurchaseInvoiceNo: Code[20]; var AssignedAmount: Decimal; PricesInclVAT: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderCharge: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        CreateAndPostPurchaseReceipt(PurchaseHeader);

        CreatePurchaseInvoiceWithItemCharge(PurchaseHeaderCharge, PurchaseHeader, PricesInclVAT);
        FindRcptLine(PurchRcptLine, PurchaseHeader."No.");
        FindPurchaseLine(PurchaseLine, PurchaseHeaderCharge."No.", PurchaseHeaderCharge."Document Type");
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");
        LibraryVariableStorage.Enqueue(PurchaseHeaderCharge."No.");
        AssignedAmount := ItemChargeAssignmentPurch."Amount to Assign";

        PAGE.RunModal(PAGE::"Purchase Statistics", PurchaseHeaderCharge);

        PurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderCharge, true, true);
    end;

    local procedure CreateTwoItemReferences(var ItemReference: Record "Item Reference"; PurchaseHeader: Record "Purchase Header"; Item: Record Item)
    begin
        LibraryItemReference.CreateItemReference(ItemReference, Item."No.", ItemReference."Reference Type"::Vendor, PurchaseHeader."Buy-from Vendor No.");
        ItemReference.Validate("Reference No.", Item."No.");
        ItemReference.Insert(true);

        LibraryItemReference.CreateItemReference(
                  ItemReference, Item."No.", ItemReference."Reference Type"::" ", '');
        ItemReference.Validate("Reference No.", Item."No.");
        ItemReference.Insert(true);
    end;

    local procedure CreatePurchaseLineWithItemreferenceNo(
        var PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        ItemReference: Record "Item Reference")
    begin
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item, Item."No.",
            LibraryRandom.RandInt(10));

        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Item Reference No.", ItemReference."Reference No.");
        PurchaseLine.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", 'OnAfterPrepareInvoicePostingBuffer', '', false, false)]
    local procedure OnAfterPreparePurchase(var PurchaseLine: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        // Example of extending feature "Copy document line description to G/L entries" for lines with type = "Item"
        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::Item then begin
            InvoicePostingBuffer."Fixed Asset Line No." := PurchaseLine."Line No.";
            InvoicePostingBuffer."Entry Description" := PurchaseLine.Description;
            InvoicePostingBuffer.BuildPrimaryKey();
        end;
    end;

    local procedure VerifyAmountInValueEntry(DocumentNo: Code[20]; BuyFromVendorNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ValueEntry: Record "Value Entry";
    begin
        GeneralLedgerSetup.Get();
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Source No.", BuyFromVendorNo);
        ValueEntry.TestField("Source Type", ValueEntry."Source Type"::Vendor);
        ValueEntry.TestField("Cost Amount (Actual)", Amount);
        ValueEntry.TestField("Cost Amount (Actual)", Amount);
        ValueEntry.TestField("Purchase Amount (Actual)", Amount);
    end;

    local procedure VerifyCopyPurchaseLine(PostedDocumentNo: Code[20]; DocumentNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchInvLine(PurchInvLine, PostedDocumentNo);

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();

        PurchaseLine.TestField("No.", PurchInvLine."No.");
        PurchaseLine.TestField(Quantity, PurchInvLine.Quantity);
        PurchaseLine.TestField("Direct Unit Cost", PurchInvLine."Direct Unit Cost");
    end;

    local procedure VerifyDimensionsOnPurchLine(DocumentNo: Code[20]; PurchLineType: Enum "Purchase Line Type"; No: Code[20]; DimensionValue1: Code[20]; DimensionValue2: Code[20])
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", DocumentNo);
        PurchLine.SetRange(Type, PurchLineType);
        PurchLine.SetRange("No.", No);
        PurchLine.FindFirst();
        PurchLine.TestField("Shortcut Dimension 1 Code", DimensionValue1);
        PurchLine.TestField("Shortcut Dimension 2 Code", DimensionValue2);
    end;

    local procedure VerifyDimensionCode(DimensionSetID: Integer; DimensionCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        Assert.IsTrue(DimensionSetEntry.FindFirst(),
          Format('Could not find dimensions with filters ' + DimensionSetEntry.GetFilters));
    end;

    local procedure VerifyDetailedVendorLedgerEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Document Type", DetailedVendorLedgEntry."Document Type"::Invoice);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, Abs(DetailedVendorLedgEntry.Amount), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, DetailedVendorLedgEntry.FieldCaption(Amount), Amount, DetailedVendorLedgEntry.TableCaption()));
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalGLAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetFilter(Amount, '>0');
        GLEntry.FindSet();
        repeat
            TotalGLAmount += GLEntry.Amount;
        until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(
          Amount, TotalGLAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryWithVATAmount(DocumentNo: Code[20]; PurchaseLine: Record "Purchase Line")
    var
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Purch. Account");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          PurchaseLine."Line Amount", GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), PurchaseLine."Line Amount", GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
          PurchaseLine."VAT %" * PurchaseLine."Line Amount" / 100, GLEntry."VAT Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountError, GLEntry.FieldCaption("VAT Amount"), PurchaseLine."VAT %" * PurchaseLine."Line Amount" / 100, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryWithJob(DocumentNo: Code[20]; JobNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        GLEntry.TestField("Job No.", JobNo);
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyJobLedgerEntry(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; JobNo: Code[20]; UnitPrice: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobNo);
        JobLedgerEntry.TestField("Unit Price", UnitPrice);
        JobLedgerEntry.TestField("Total Cost (LCY)", CalculateTotalCostLCY(PurchaseLine));
    end;

    local procedure VerifyGLEntriesDescription(var TempPurchaseLine: Record "Purchase Line"; InvoiceNo: Code[20])
    var
        GLEntry: Record "g/l Entry";
    begin
        GLEntry.SETRANGE("Document No.", InvoiceNo);
        TempPurchaseLine.FindSet();
        repeat
            GLEntry.SETRANGE(Description, TempPurchaseLine.Description);
            Assert.RecordIsNotEmpty(GLEntry);
        until TempPurchaseLine.Next() = 0;
    end;

    local procedure VerifyCombinedGLEntries(InvoiceNo: Code[20]; AccountNo: Code[20])
    var
        GLEntry: Record "G/l Entry";
    begin
        GLEntry.SETRANGE("Document No.", InvoiceNo);
        GLEntry.SETRANGE("G/L Account No.", AccountNo);
        Assert.IsTrue(GLEntry.Count() = 1, 'One G/L Entry should be posted');
    end;

    local procedure VerifyJobLedgerEntryZeroUnitCost(DocumentNo: Code[20]; JobNo: Code[20])
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobNo);
        Assert.AreEqual(
          0,
          JobLedgerEntry."Unit Cost (LCY)",
          StrSubstNo(IncorrectFieldValueErr, JobLedgerEntry.FieldName("Unit Cost (LCY)")));
    end;

    local procedure VerifyInvoiceDiscountAmount(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; InvoiceDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        FindGLEntry(GLEntry, DocumentNo, GeneralPostingSetup."Purch. Inv. Disc. Account");
        Assert.AreNearlyEqual(
          InvoiceDiscountAmount, Abs(GLEntry.Amount), GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), InvoiceDiscountAmount, GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
          InvoiceDiscountAmount, PurchaseLine."Inv. Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, PurchaseLine.FieldCaption("Inv. Discount Amount"), InvoiceDiscountAmount, PurchaseLine.TableCaption()));
    end;

    local procedure VerifyItemChargeAssignment(DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();

        ItemChargeAssignmentPurch.SetRange("Document Type", ItemChargeAssignmentPurch."Document Type"::Order);
        ItemChargeAssignmentPurch.SetRange("Document No.", DocumentNo);
        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. No.", DocumentNo);
        ItemChargeAssignmentPurch.FindFirst();
        ItemChargeAssignmentPurch.TestField("Item No.", PurchaseLine."No.");

        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindFirst();
        ItemChargeAssignmentPurch.TestField("Applies-to Doc. No.", DocumentNo);
        ItemChargeAssignmentPurch.TestField("Item Charge No.", PurchaseLine."No.");
        ItemChargeAssignmentPurch.TestField("Qty. to Assign", PurchaseLine.Quantity);
        ItemChargeAssignmentPurch.TestField("Amount to Assign", PurchaseLine."Line Amount");
    end;

    local procedure VerifyLineDiscountAmount(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; LineDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        FindGLEntry(GLEntry, DocumentNo, GeneralPostingSetup."Purch. Line Disc. Account");
        Assert.AreNearlyEqual(
          LineDiscountAmount, Abs(GLEntry.Amount), GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), LineDiscountAmount, GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
          LineDiscountAmount, PurchaseLine."Line Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, PurchaseLine.FieldCaption("Line Discount Amount"), LineDiscountAmount, PurchaseLine.TableCaption()));
    end;

    local procedure VerifyVendorLedgerEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        Assert.AreNearlyEqual(
          Amount, Abs(VendorLedgerEntry."Amount (LCY)"), GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, VendorLedgerEntry.FieldCaption("Amount (LCY)"), Amount, VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyVendorLedgerEntryWithRemainingAmount(DocumentNo: Code[20]; Amount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.CalcFields("Amount (LCY)", "Remaining Amount", "Original Amount");
        VendorLedgerEntry.TestField(Open, true);
        VendorLedgerEntry.TestField("Remaining Pmt. Disc. Possible", 0);
        Assert.AreNearlyEqual(
          Amount, Abs(VendorLedgerEntry."Remaining Amount"), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, VendorLedgerEntry.FieldCaption("Remaining Amount"), Amount, VendorLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
          Amount, Abs(VendorLedgerEntry."Original Amount"), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, VendorLedgerEntry.FieldCaption("Original Amount"), Amount, VendorLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
          Amount, Abs(VendorLedgerEntry."Amount (LCY)"), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, VendorLedgerEntry.FieldCaption("Amount (LCY)"), Amount, VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ValueEntry: Record "Value Entry";
        PurchaseAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindSet();
        repeat
            PurchaseAmount += ValueEntry."Purchase Amount (Actual)";
        until ValueEntry.Next() = 0;
        Assert.AreNearlyEqual(
          Amount, PurchaseAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, ValueEntry.FieldCaption("Purchase Amount (Actual)"), Amount, ValueEntry.TableCaption()));
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
    begin
        GeneralLedgerSetup.Get();
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, Abs(VATEntry.Base + VATEntry.Amount), GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, VATEntry.FieldCaption(Amount), Amount, VATEntry.TableCaption()));
    end;

    local procedure VerifyVATEntryWithBase(DocumentNo: Code[20]; PurchaseLine: Record "Purchase Line")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetFilter(Base, '>=0');
        VATEntry.FindFirst();
        VATEntry.TestField("VAT Difference", 0);
        VATEntry.TestField(Closed, false);
        VATEntry.TestField(Base, PurchaseLine."Line Amount");
        // Nearly equal to handle decimal VAT %
        Assert.AreNearlyEqual(
          PurchaseLine."VAT %" * PurchaseLine."Line Amount" / 100, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountError, VATEntry.FieldCaption(Amount), PurchaseLine."VAT %" * PurchaseLine."Line Amount" / 100, VATEntry.TableCaption()));
    end;

    local procedure VerifyNavigateRecords(var DocumentEntry: Record "Document Entry"; TableID: Integer; NoOfRecords: Integer)
    begin
        DocumentEntry.SetRange("Table ID", TableID);
        DocumentEntry.FindFirst();
        DocumentEntry.TestField("No. of Records", NoOfRecords);
    end;

    local procedure VerifyPurchaseCreditMemo(DocumentNo: Code[20]; PurchaseLine: Record "Purchase Line")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoHdr.TestField("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.FindFirst();
        PurchCrMemoLine.TestField(Type, PurchaseLine.Type);
        PurchCrMemoLine.TestField("No.", PurchaseLine."No.");
        PurchCrMemoLine.TestField(Quantity, PurchaseLine.Quantity);
        PurchCrMemoLine.TestField(Amount, PurchaseLine."Line Amount");
        PurchCrMemoLine.TestField("Unit Cost (LCY)", PurchaseLine."Unit Cost (LCY)");
    end;

    local procedure VerifyPurchaseDocument(DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine2, DocumentNo2, PurchaseLine."Document Type"::Invoice);
        FindPurchaseLine(PurchaseLine, DocumentNo, PurchaseLine."Document Type"::Order);
        repeat
            PurchaseLine2.SetRange(Type, PurchaseLine.Type);
            PurchaseLine2.SetRange("No.", PurchaseLine."No.");
            PurchaseLine2.FindFirst();
            PurchaseLine2.TestField(Quantity, PurchaseLine.Quantity);
            PurchaseLine2.TestField("Direct Unit Cost", PurchaseLine."Direct Unit Cost");
            PurchaseLine2.TestField("Line Amount", PurchaseLine."Line Amount");
        until PurchaseLine.Next() = 0;
    end;

    local procedure VerifyPurchaseInvoiceDocument(DocumentNo: Code[20]; VendorInvoiceNo: Code[35]; PurchaseLine: Record "Purchase Line")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.TestField("Vendor Invoice No.", VendorInvoiceNo);
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindSet();
        repeat
            if PurchInvLine.Type <> PurchInvLine.Type::" " then begin
                PurchaseLine.SetRange(Type, PurchInvLine.Type);
                PurchaseLine.SetRange("No.", PurchInvLine."No.");
                PurchaseLine.FindFirst();
                PurchInvLine.TestField(Quantity, PurchaseLine.Quantity);
                PurchInvLine.TestField(Amount, PurchaseLine."Line Amount");
                PurchInvLine.TestField("Unit Cost (LCY)", PurchaseLine."Unit Cost (LCY)");
            end;
        until PurchInvLine.Next() = 0;
    end;

    local procedure VerifyPurchaseInvoice(DocumentNo: Code[20]; PurchaseLine: Record "Purchase Line")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.TestField("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Type, PurchaseLine.Type);
        PurchInvLine.TestField("No.", PurchaseLine."No.");
        PurchInvLine.TestField(Quantity, PurchaseLine.Quantity);
        PurchInvLine.TestField(Amount, PurchaseLine."Line Amount");
        PurchInvLine.TestField("Unit Cost (LCY)", PurchaseLine."Unit Cost (LCY)");
    end;

    local procedure VerifyPurchaseLine(StandardPurchaseLine: Record "Standard Purchase Line"; DocumentNo: Code[20]; ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField(Type, StandardPurchaseLine.Type);
        PurchaseLine.TestField("No.", StandardPurchaseLine."No.");
        PurchaseLine.TestField(Quantity, StandardPurchaseLine.Quantity);
        PurchaseLine.TestField("Shortcut Dimension 1 Code", ShortcutDimension1Code);
        PurchaseLine.TestField("Shortcut Dimension 2 Code", ShortcutDimension2Code);
    end;

    local procedure VerifyPurchaseOrder(PurchaseHeaderNo: Code[20]; VendorNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify 1: Verify Pay to Vendor No in Purchase Header.
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseHeaderNo);
        PurchaseHeader.TestField("Pay-to Vendor No.", VendorNo);

        // Verify 2: Verify Pay to Vendor No in Purchase Line.
        FindPurchaseLine(PurchaseLine, PurchaseHeaderNo, PurchaseHeader."Document Type"::Order);
        PurchaseLine.TestField("Pay-to Vendor No.", VendorNo);
        PurchaseLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedEntries(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        ValueEntry: Record "Value Entry";
    begin
        VerifyPostedPaymentNavigation(DocumentNo);

        VATEntry.SetRange("Document No.", DocumentNo);
        VerifyNavigateRecords(TempDocumentEntry2, DATABASE::"VAT Entry", VATEntry.Count);

        ValueEntry.SetRange("Document No.", DocumentNo);
        VerifyNavigateRecords(TempDocumentEntry2, DATABASE::"Value Entry", ValueEntry.Count);
    end;

    local procedure VerifyPostedPaymentNavigation(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        VerifyNavigateRecords(TempDocumentEntry2, DATABASE::"G/L Entry", GLEntry.Count);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VerifyNavigateRecords(TempDocumentEntry2, DATABASE::"Vendor Ledger Entry", VendorLedgerEntry.Count);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        VerifyNavigateRecords(TempDocumentEntry2, DATABASE::"Detailed Vendor Ledg. Entry", DetailedVendorLedgEntry.Count);
    end;

    local procedure VerifyPurchRcptHeader(OrderNo: Code[20]; VendorNo: Code[20]; PostingDate: Date)
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchRcptHeader.FindFirst();
        PurchRcptHeader.TestField("Posting Date", PostingDate);
    end;

    local procedure VerifyGetReceiptDocNo(DocumentNo: Code[20]; PostedDocNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        FindPurchInvLine(PurchInvLine, DocumentNo);
        PurchInvLine.TestField("Receipt No.", PostedDocNo);
        PurchInvLine.TestField("Receipt Line No.", FindReceiptLineNo(PostedDocNo));
    end;

    local procedure VerifyValuesOnVendLedgerEntry(DocumentNo: Code[20]; DueDate: Date; PmtDiscountDate: Date; RemainingPmtDiscPossible: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.TestField("Due Date", DueDate);
        VendorLedgerEntry.TestField("Pmt. Discount Date", PmtDiscountDate);
        VendorLedgerEntry.TestField("Remaining Pmt. Disc. Possible", RemainingPmtDiscPossible);
    end;

    local procedure VerifyVendor(Vendor: Record Vendor)
    var
        Vendor2: Record Vendor;
    begin
        Vendor2.Get(Vendor."No.");
        Vendor2.TestField("Gen. Bus. Posting Group", Vendor."Gen. Bus. Posting Group");
        Vendor2.TestField("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        Vendor2.TestField("Vendor Posting Group", Vendor."Vendor Posting Group");
    end;

    local procedure VerifyUndoReceiptLineOnPostedReceipt(DocumentNo: Code[20]; QtyToReceive: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", DocumentNo);
        PurchRcptLine.FindLast();
        PurchRcptLine.TestField(Quantity, -1 * QtyToReceive);
    end;

    local procedure VerifyUnitCostLCYOnPurchaseReturnLine(DocumentNo: Code[20]; UnitCostLCY: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        FindPurchaseLine(PurchaseLine, DocumentNo, PurchaseLine."Document Type"::"Return Order");
        PurchaseLine.TestField("Unit Cost (LCY)", UnitCostLCY);
    end;

    local procedure VerifyQuantitytoReceiveOnPurchaseLine(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Qty. to Receive", 0);
    end;

    local procedure VerifyQuantityOnPurchaseInvoiceLine(OrderNo: Code[20]; BuyFromVendorNo: Code[20]; Quantity: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchInvHeader.FindFirst();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyDimensionSetIDOnPurchLine(PurchaseHeaderNo: Code[20]; PostedDocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Return Order");
        PurchaseLine.SetRange("Document No.", PurchaseHeaderNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Dimension Set ID", GetDimensionSetId(PostedDocumentNo));
    end;

    local procedure VerifyDimSetIDOnItemLedgEntry(ExpectedDimSetID: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        ItemLedgEntry.FindLast();
        ValueEntry.SetFilter("Item Charge No.", '<>%1', '');
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        ValueEntry.FindFirst();
        Assert.AreEqual(
          ExpectedDimSetID, ValueEntry."Dimension Set ID", StrSubstNo(IncorrectDimSetIDErr, ItemLedgEntry.TableCaption()));
    end;

    local procedure VerifyChargeValueEntry(DocNo: array[2] of Code[20]; ItemChargeNo: Code[20]; ShipmentCount: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        i: Integer;
    begin
        for i := 1 to ArrayLen(DocNo) do begin
            ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Sale);
            ItemLedgEntry.SetRange("Document No.", DocNo[i]);
            ItemLedgEntry.FindLast();
            ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Purchase);
            ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
            ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
            ValueEntry.SetRange("Item Charge No.", ItemChargeNo);
            ValueEntry.FindFirst();
            Assert.AreEqual(ShipmentCount, ValueEntry.Count, StrSubstNo(CountErr, ShipmentCount, ValueEntry.TableCaption(), ValueEntry.GetFilters));
            Assert.AreEqual(
              ItemLedgEntry.Quantity, ValueEntry."Valued Quantity",
              StrSubstNo(AmountError, ValueEntry.FieldCaption("Valued Quantity"), ItemLedgEntry.Quantity, ValueEntry.TableCaption));
        end;
    end;

    local procedure VerifyJobPricesOfPurchInvWithRcptPurchOrder(PurchLine: Record "Purchase Line"; InvPurchLine: Record "Purchase Line")
    begin
        Assert.AreEqual(
          PurchLine."Job Unit Price", InvPurchLine."Job Unit Price", StrSubstNo(IncorrectFieldValueErr, InvPurchLine.FieldCaption("Job Unit Price")));
        Assert.AreEqual(
          PurchLine."Job Total Price", InvPurchLine."Job Total Price", StrSubstNo(IncorrectFieldValueErr, InvPurchLine.FieldCaption("Job Total Price")));
        Assert.AreEqual(
          PurchLine."Job Line Amount", InvPurchLine."Job Line Amount", StrSubstNo(IncorrectFieldValueErr, InvPurchLine.FieldCaption("Job Line Amount")));
        Assert.AreEqual(
          PurchLine."Job Line Discount Amount", InvPurchLine."Job Line Discount Amount",
          StrSubstNo(IncorrectFieldValueErr, InvPurchLine.FieldCaption("Job Line Discount Amount")));
        Assert.AreEqual(
          PurchLine."Job Line Discount %", InvPurchLine."Job Line Discount %",
          StrSubstNo(IncorrectFieldValueErr, InvPurchLine.FieldCaption("Job Line Discount %")));
        Assert.AreEqual(
          PurchLine."Job Unit Price (LCY)", InvPurchLine."Job Unit Price (LCY)",
          StrSubstNo(IncorrectFieldValueErr, InvPurchLine.FieldCaption("Job Unit Price (LCY)")));
        Assert.AreEqual(
          PurchLine."Job Total Price (LCY)", InvPurchLine."Job Total Price (LCY)",
          StrSubstNo(IncorrectFieldValueErr, InvPurchLine.FieldCaption("Job Total Price (LCY)")));
        Assert.AreEqual(
          PurchLine."Job Line Amount (LCY)", InvPurchLine."Job Line Amount (LCY)",
          StrSubstNo(IncorrectFieldValueErr, InvPurchLine.FieldCaption("Job Line Amount (LCY)")));
        Assert.AreEqual(
          PurchLine."Job Line Disc. Amount (LCY)", InvPurchLine."Job Line Disc. Amount (LCY)",
          StrSubstNo(IncorrectFieldValueErr, InvPurchLine.FieldCaption("Job Line Disc. Amount (LCY)")));
    end;

    local procedure VerifyPurchHeaderDimensions(PurchHeader: Record "Purchase Header"; DimCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Code", DimCode);
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(
          DimensionSetEntry."Dimension Set ID", PurchHeader."Dimension Set ID",
          StrSubstNo(WrongDimValueErr, PurchHeader."No."));
    end;

    local procedure VerifyPurchInvDescriptionLineExists(DocumentNo: Code[20]; ExpectedDescription: Text[100])
    var
        DummyPurchInvLine: Record "Purch. Inv. Line";
    begin
        DummyPurchInvLine.SetRange("Document No.", DocumentNo);
        DummyPurchInvLine.SetRange(Type, DummyPurchInvLine.Type::" ");
        DummyPurchInvLine.SetRange("No.", '');
        DummyPurchInvLine.SetRange(Description, ExpectedDescription);
        Assert.RecordIsNotEmpty(DummyPurchInvLine);
    end;

    local procedure VerifyPurchRcptDescriptionLineExists(DocumentNo: Code[20]; ExpectedDescription: Text[100])
    var
        DummyPurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        DummyPurchRcptLine.SetRange("Document No.", DocumentNo);
        DummyPurchRcptLine.SetRange(Type, DummyPurchRcptLine.Type::" ");
        DummyPurchRcptLine.SetRange("No.", '');
        DummyPurchRcptLine.SetRange(Description, ExpectedDescription);
        Assert.RecordIsNotEmpty(DummyPurchRcptLine);
    end;

    local procedure VerifyPurchCrMemoDescriptionLineExists(DocumentNo: Code[20]; ExpectedDescription: Text[100])
    var
        DummyPurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        DummyPurchCrMemoLine.SetRange("Document No.", DocumentNo);
        DummyPurchCrMemoLine.SetRange(Type, DummyPurchCrMemoLine.Type::" ");
        DummyPurchCrMemoLine.SetRange("No.", '');
        DummyPurchCrMemoLine.SetRange(Description, ExpectedDescription);
        Assert.RecordIsNotEmpty(DummyPurchCrMemoLine);
    end;

    local procedure VerifyPurchRetShptDescriptionLineExists(DocumentNo: Code[20]; ExpectedDescription: Text[100])
    var
        DummyReturnShipmentLine: Record "Return Shipment Line";
    begin
        DummyReturnShipmentLine.SetRange("Document No.", DocumentNo);
        DummyReturnShipmentLine.SetRange(Type, DummyReturnShipmentLine.Type::" ");
        DummyReturnShipmentLine.SetRange("No.", '');
        DummyReturnShipmentLine.SetRange(Description, ExpectedDescription);
        Assert.RecordIsNotEmpty(DummyReturnShipmentLine);
    end;

    local procedure FindJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; DocumentNo: Code[20]; JobNo: Code[20])
    begin
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.FindFirst();
    end;

    local procedure VerifyRemainingAmountLCY(VendorNo: Code[20]; RemainingAmtLCY: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Currency: Record Currency;
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Remaining Amt. (LCY)");
        Currency.Get(VendorLedgerEntry."Currency Code");
        Assert.AreNearlyEqual(
          -RemainingAmtLCY, VendorLedgerEntry."Remaining Amt. (LCY)", Currency."Invoice Rounding Precision",
          StrSubstNo(AmountError, VendorLedgerEntry.FieldCaption("Remaining Amt. (LCY)"), RemainingAmtLCY, VendorLedgerEntry.TableCaption));
    end;

    local procedure VerifyJobTotalPrices(PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10])
    var
        CurrExchRate: Record "Currency Exchange Rate";
        ExpectedResult: Decimal;
    begin
        ExpectedResult := Round(PurchaseLine.Quantity * PurchaseLine."Job Unit Price", LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode));
        Assert.AreEqual(ExpectedResult, PurchaseLine."Job Total Price", WrongJobTotalPriceErr);
        ExpectedResult := Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              WorkDate(), CopyStr(PurchaseLine."Job Currency Code", 1, 10),
              PurchaseLine."Job Total Price", PurchaseLine."Job Currency Factor"),
            LibraryERM.GetCurrencyAmountRoundingPrecision(''));
        Assert.AreEqual(ExpectedResult, PurchaseLine."Job Total Price (LCY)", WrongJobTotalPriceLCYErr);
    end;

    local procedure VerifyPurchaseLineCount(PurchaseHeader: Record "Purchase Header"; ExpectedCount: Integer)
    var
        DummyPurchaseLine: Record "Purchase Line";
    begin
        DummyPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        DummyPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(DummyPurchaseLine, ExpectedCount);
    end;

    local procedure VerifyPurchaseLineDescription(PurchaseLine: Record "Purchase Line"; ExpectedType: Enum "Purchase Line Type"; ExpectedNo: Code[20]; ExpectedDescription: Text)
    begin
        Assert.AreEqual(ExpectedType, PurchaseLine.Type, PurchaseLine.FieldCaption(Type));
        Assert.AreEqual(ExpectedNo, PurchaseLine."No.", PurchaseLine.FieldCaption("No."));
        Assert.AreEqual(ExpectedDescription, PurchaseLine.Description, PurchaseLine.FieldCaption(Description));
    end;

    local procedure VerifyPurchaseLineFindRecordByDescription(PurchaseLine: Record "Purchase Line"; TypedValue: Text[100]; ExpectedNo: Code[20]; ExpectedDescription: Text)
    begin
        PurchaseLine.Validate("No.", '');
        PurchaseLine.Validate(Description, TypedValue);
        VerifyPurchaseLineDescription(PurchaseLine, PurchaseLine.Type, ExpectedNo, ExpectedDescription);
    end;

    local procedure VerifyPurchaseLineFindRecordByNo(PurchaseLine: Record "Purchase Line"; TypedValue: Text[20]; ExpectedNo: Code[20]; ExpectedDescription: Text)
    begin
        PurchaseLine.Validate("No.", TypedValue);
        VerifyPurchaseLineDescription(PurchaseLine, PurchaseLine.Type, ExpectedNo, ExpectedDescription);
    end;

    local procedure VerifyBuyFromAddressIsVendorAddress(PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    begin
        PurchaseHeader.TestField("Buy-from Address", Vendor.Address);
        PurchaseHeader.TestField("Buy-from Address 2", Vendor."Address 2");
        PurchaseHeader.TestField("Buy-from City", Vendor.City);
        PurchaseHeader.TestField("Buy-from Post Code", Vendor."Post Code");
        PurchaseHeader.TestField("Buy-from County", Vendor.County);
        PurchaseHeader.TestField("Buy-from Country/Region Code", Vendor."Country/Region Code");
    end;

    local procedure CreateOrderCheckVATSetup(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        LibraryInventory.CreateItem(Item);
        if not VATPostingSetup.Get(PurchaseHeader."VAT Bus. Posting Group", Item."VAT Prod. Posting Group") then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
    end;

    local procedure VerifyPurchExtLineExists(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        PurchaseLine.SetRange("Attached to Line No.", PurchaseLine."Line No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::" ");
        Assert.RecordIsNotEmpty(PurchaseLine);
    end;

    local procedure VerifyUndoReceiptLineOnPostedReceipt(PurchaseLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange(Type, PurchaseLine.Type);
        PurchRcptLine.SetRange("No.", PurchaseLine."No.");
        PurchRcptLine.FindLast();
        PurchRcptLine.TestField(Quantity, -1 * PurchaseLine."Qty. to Receive");
    end;

    local procedure VerifyUndoReceiptLineOnPostedReturnShipment(PurchaseLine: Record "Purchase Line")
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        ReturnShipmentLine.SetRange("Return Order No.", PurchaseLine."Document No.");
        ReturnShipmentLine.SetRange(Type, PurchaseLine.Type);
        ReturnShipmentLine.SetRange("No.", PurchaseLine."No.");
        ReturnShipmentLine.FindLast();
        ReturnShipmentLine.TestField(Quantity, -1 * PurchaseLine."Return Qty. to Ship");

    end;

    local procedure SetupMyNotificationsForPostingSetup()
    var
        MyNotifications: Record "My Notifications";
        PostingSetupManagement: Codeunit PostingSetupManagement;
    begin
        MyNotifications.InsertDefaultWithTableNum(
          PostingSetupManagement.GetPostingSetupNotificationID(),
          LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(),
          DATABASE::"G/L Account");
        MyNotifications.Enabled := true;
        MyNotifications.Modify();
    end;

    local procedure VerifyResJournalLineCopiedFromPurchaseLine(ResJournalLine: Record "Res. Journal Line"; PurchaseLine: Record "Purchase Line")
    begin
        Assert.AreEqual(PurchaseLine."No.", ResJournalLine."Resource No.", CopyFromPurchaseErr);
        Assert.AreEqual(ResJournalLine."Source Type"::Vendor, ResJournalLine."Source Type", CopyFromPurchaseErr);
        Assert.AreEqual(PurchaseLine."Buy-from Vendor No.", ResJournalLine."Source No.", CopyFromPurchaseErr);
        Assert.AreEqual(PurchaseLine."Unit of Measure Code", ResJournalLine."Unit of Measure Code", CopyFromPurchaseErr);
        Assert.AreEqual(PurchaseLine."Gen. Bus. Posting Group", ResJournalLine."Gen. Bus. Posting Group", CopyFromPurchaseErr);
        Assert.AreEqual(PurchaseLine."Gen. Prod. Posting Group", ResJournalLine."Gen. Prod. Posting Group", CopyFromPurchaseErr);
        Assert.AreEqual(ResJournalLine."Entry Type"::Purchase, ResJournalLine."Entry Type", CopyFromPurchaseErr);
        Assert.AreEqual(PurchaseLine."Qty. to Invoice", ResJournalLine.Quantity, CopyFromPurchaseErr);
        Assert.AreEqual(PurchaseLine."Direct Unit Cost", ResJournalLine."Unit Price", CopyFromPurchaseErr);
        Assert.AreEqual(PurchaseLine.Amount, ResJournalLine."Total Price", CopyFromPurchaseErr);
    end;

    local procedure VerifyPurchaseLineCopiedFromResource(PurchaseLine: Record "Purchase Line"; Resource: Record Resource)
    begin
        Assert.AreEqual(Resource.Name, PurchaseLine.Description, CopyFromResourceErr);
        Assert.AreEqual(Resource."Base Unit of Measure", PurchaseLine."Unit of Measure Code", CopyFromResourceErr);
        Assert.AreEqual(Resource."Gen. Prod. Posting Group", PurchaseLine."Gen. Prod. Posting Group", CopyFromResourceErr);
        Assert.AreEqual(Resource."VAT Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group", CopyFromResourceErr);
        Assert.IsFalse(PurchaseLine."Allow Item Charge Assignment", CopyFromResourceErr);
        Assert.AreEqual(Resource."Direct Unit Cost", PurchaseLine."Direct Unit Cost", CopyFromResourceErr);
    end;

    local procedure VerifyCountPurchCommentLine(DocumentType: Enum "Purchase Comment Document Type"; No: Code[20]; DocumentLineNo: Integer)
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        PurchCommentLine.SetRange("Document Type", DocumentType);
        PurchCommentLine.SetRange("No.", No);
        PurchCommentLine.SetRange("Document Line No.", DocumentLineNo);
        Assert.RecordCount(PurchCommentLine, 1);
    end;

    local procedure MockPostedPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; PurchInvLine: Record "Purch. Inv. Line")
    begin
        PurchInvHeader.Init();
        PurchInvHeader."No." := LibraryUtility.GenerateRandomCode20(PurchInvHeader.FieldNo("No."), Database::"Purch. Inv. Header");
        PurchInvHeader.Insert();

        PurchInvLine.Init();
        PurchInvLine."Document No." := PurchInvHeader."No.";
        PurchInvLine."Line No." := LibraryUtility.GetNewRecNo(PurchInvLine, PurchInvLine.FieldNo("Line No."));
        PurchInvLine.Type := PurchInvLine.Type::Resource;
        PurchInvLine."No." := LibraryResource.CreateResourceNo();
        PurchInvLine.Insert();
    end;

    local procedure MockPostedPurchaseCrMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
        PurchCrMemoHdr.Init();
        PurchCrMemoHdr."No." := LibraryUtility.GenerateRandomCode20(PurchCrMemoHdr.FieldNo("No."), Database::"Purch. Cr. Memo Hdr.");
        PurchCrMemoHdr.Insert();

        PurchCrMemoLine.Init();
        PurchCrMemoLine."Document No." := PurchCrMemoHdr."No.";
        PurchCrMemoLine."Line No." := LibraryUtility.GetNewRecNo(PurchCrMemoLine, PurchCrMemoLine.FieldNo("Line No."));
        PurchCrMemoLine.Type := PurchCrMemoLine.Type::Resource;
        PurchCrMemoLine."No." := LibraryResource.CreateResourceNo();
        PurchCrMemoLine.Insert();
    end;

    local procedure MockPostedPurchaseReceipt(var PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        PurchRcptHeader.Init();
        PurchRcptHeader."No." := LibraryUtility.GenerateRandomCode20(PurchRcptHeader.FieldNo("No."), Database::"Purch. Cr. Memo Hdr.");
        PurchRcptHeader.Insert();

        PurchRcptLine.Init();
        PurchRcptLine."Document No." := PurchRcptHeader."No.";
        PurchRcptLine."Line No." := LibraryUtility.GetNewRecNo(PurchRcptLine, PurchRcptLine.FieldNo("Line No."));
        PurchRcptLine.Type := PurchRcptLine.Type::Resource;
        PurchRcptLine."No." := LibraryResource.CreateResourceNo();
        PurchRcptLine.Insert();
    end;

    local procedure MockPostedReturnShpt(var ReturnShipmentHeader: Record "Return Shipment Header"; ReturnShipmentLine: Record "Return Shipment Line")
    begin
        ReturnShipmentHeader.Init();
        ReturnShipmentHeader."No." := LibraryUtility.GenerateRandomCode20(ReturnShipmentHeader.FieldNo("No."), Database::"Purch. Cr. Memo Hdr.");
        ReturnShipmentHeader.Insert();

        ReturnShipmentLine.Init();
        ReturnShipmentLine."Document No." := ReturnShipmentHeader."No.";
        ReturnShipmentLine."Line No." := LibraryUtility.GetNewRecNo(ReturnShipmentLine, ReturnShipmentLine.FieldNo("Line No."));
        ReturnShipmentLine.Type := ReturnShipmentLine.Type::Resource;
        ReturnShipmentLine."No." := LibraryResource.CreateResourceNo();
        ReturnShipmentLine.Insert();
    end;

    local procedure CreateItemWithBOMComponent(): Code[20]
    var
        Item: Record Item;
        Item2: Record Item;
    begin
        // Create Item with BOM Component
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        CreateBOMComponent(Item."No.", Item2."No.");
        exit(Item."No.");
    end;

    local procedure CreateBOMComponent(ParentItemNo: Code[20]; ItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RecRef: RecordRef;
    begin
        // Create BOM Component with random Unit of Measure.
        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure.SetRange("Item No.", ItemNo);
        RecRef.GetTable(ItemUnitOfMeasure);
        LibraryUtility.FindRecord(RecRef);
        RecRef.SetTable(ItemUnitOfMeasure);

        LibraryInventory.CreateBOMComponent(
          BOMComponent, ParentItemNo, BOMComponent.Type::Item, ItemNo, LibraryRandom.RandInt(10), ItemUnitOfMeasure.Code);
    end;

    local procedure CreateSpecialSalesOrderForItem(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLineWithPurchasingCode(
          SalesHeader, SalesLine, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10), LibraryRandom.RandInt(100), '', CreatePurchasingCode(false, true));
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
    end;

    local procedure CreateSalesLineWithPurchasingCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal; LocationCode: Code[10]; PurchasingCode: Code[10])
    begin
        CreateSalesLine(SalesHeader, SalesLine, Type, ItemNo, Quantity, LocationCode);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchasingCode(DropShipment: Boolean; SpecialOrder: Boolean) PurchasingCode: Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", DropShipment);
        Purchasing.Validate("Special Order", SpecialOrder);
        Purchasing.Modify(true);
        PurchasingCode := Purchasing.Code
    end;

    local procedure GetSpecialOrderOnRequisitionWorksheetAndCreatePurchaseOrder(var Vendor: Record Vendor)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        SelectRequisitionTemplateAndCreateReqWkshName(ReqWkshTemplate);
        OpenRequisitionWorksheetPage(ReqWorksheet, FindRequisitionWkshName(ReqWkshTemplate.Type::"Req."));
        GetSpecialSalesOrderOnReqWorksheet(ReqWorksheet, Vendor);
        FindCreatedRequisitionLine(ReqWorksheet, RequisitionLine);
        ReqWkshCarryOutActionMessage(RequisitionLine);
    end;

    local procedure GetSpecialSalesOrderOnReqWorksheet(var ReqWorksheet: TestPage "Req. Worksheet"; var Vendor: Record Vendor)
    var
        ReplenishmentSystem: Enum "Replenishment System";
    begin
        ReqWorksheet.Action53.Invoke();
        ReqWorksheet.First();
        ReqWorksheet."Replenishment System".SetValue(ReplenishmentSystem::Purchase);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        ReqWorksheet."Vendor No.".Lookup();
        ReqWorksheet.Next();
        ReqWorksheet.Previous();
    end;

    local procedure FindCreatedRequisitionLine(var ReqWorksheet: TestPage "Req. Worksheet"; var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.SetRange("No.", ReqWorksheet."No.".Value);
        RequisitionLine.FindFirst();
    end;

    local procedure SelectRequisitionTemplateAndCreateReqWkshName(var ReqWkshTemplate: Record "Req. Wksh. Template")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::"Req.");
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        Commit();
    end;

    local procedure OpenRequisitionWorksheetPage(var ReqWorksheet: TestPage "Req. Worksheet"; Name: Code[20])
    begin
        ReqWorksheet.OpenEdit();
        ReqWorksheet.CurrentJnlBatchName.SetValue(Name);
    end;

    local procedure OpenCreatedPurchaseOrder(var PurchaseOrder: TestPage "Purchase Order"; var PurchaseLine: Record "Purchase Line"; Vendor: Record Vendor)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetCurrentKey("Document Date");
        PurchaseHeader.SetRange("Document Date", WorkDate());
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindLast();
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", '10000');
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GoToRecord(PurchaseHeader);
    end;

    local procedure SelectRequisitionTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Type: Enum "Req. Worksheet Template Type")
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
    end;

    local procedure FindRequisitionWkshName(ReqWkshTemplateType: Enum "Req. Worksheet Template Type"): Code[10]
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplateType);
        RequisitionWkshName.SetRange("Worksheet Template Name", ReqWkshTemplate.Name);
        RequisitionWkshName.FindFirst();
        exit(RequisitionWkshName.Name);
    end;

    local procedure ReqWkshCarryOutActionMessage(var RequisitionLine: Record "Requisition Line")
    var
        CarryOutActionMessage: Report "Carry Out Action Msg. - Req.";
    begin
        Commit();
        CarryOutActionMessage.SetReqWkshLine(RequisitionLine);
        CarryOutActionMessage.SetHideDialog(true);
        CarryOutActionMessage.UseRequestPage(false);
        CarryOutActionMessage.RunModal();
    end;

    [ModalPageHandler]
    procedure ItemVendorCatalogHandler(var ItemVendorCatalog: TestPage "Item Vendor Catalog")
    var
        VendorNo: Code[20];
    begin
        VendorNo := LibraryVariableStorage.DequeueText();
        ItemVendorCatalog.New();
        ItemVendorCatalog."Vendor No.".SetValue(VendorNo);
        ItemVendorCatalog.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure GetSalesOrdersHandler(var GetSalesOrders: TestRequestPage "Get Sales Orders")
    begin
        GetSalesOrders."Sales Line".SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        GetSalesOrders.OK().Invoke();
    end;

    local procedure OpenPurchaseOrder(PurchaseHeader: Record "Purchase Header"; var PurchaseOrder: TestPage "Purchase Order")
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
    end;

    local procedure CreateLocationWithDefaultDimensions(var Location: Record Location; var DimValue: Record "Dimension Value"; var DimValue2: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimValue."Dimension Code", DimValue.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimValue2."Dimension Code", DimValue2.Code);
    end;

    local procedure CreateDimensionAndSetupOnGeneralLedgerSetup(var DimensionValue: Record "Dimension Value"; var DimensionValue2: Record "Dimension Value")
    begin
        // Create two dimensions
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDimWithDimValue(DimensionValue2);

        // Change Shortcut Dimension 3 Code and Shortcut Dimension 4 Code successfully updated on General Ledger Setup
        LibraryERM.SetShortcutDimensionCode(3, DimensionValue."Dimension Code");
        LibraryERM.SetShortcutDimensionCode(4, DimensionValue2."Dimension Code");
    end;

    local procedure CreatePurchaseOrderWithResourceLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var Resource: Record Resource)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate(PurchaseHeader."Vendor Invoice No.", LibraryRandom.RandText(35));
        PurchaseHeader.Modify(true);

        Resource.Get(LibraryResource.CreateResourceNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, Resource."No.", 1);
    end;

    local procedure CreateCustomerWithLocationAndShipToAddressWithoutLocation(var Customer: Record Customer; var ShipToAddress: Record "Ship-to Address")
    begin
        CreateCustomerWithLocation(Customer);

        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
    end;

    local procedure CreateCustomerWithLocationAndShipToAddressWithDifferentLocation(var Customer: Record Customer; var ShipToAddress: Record "Ship-to Address")
    var
        ShipToLocation: Record Location;
    begin
        CreateCustomerWithLocation(Customer);

        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        LibraryWarehouse.CreateLocation(ShipToLocation);
        ShipToAddress.Validate("Location Code", ShipToLocation.Code);
        ShipToAddress.Modify(true);
    end;

    local procedure CreateCustomerWithLocation(var Customer: Record Customer)
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibrarySales.CreateCustomerWithLocationCode(Customer, Location.Code);
    end;

    local procedure CreatePurchaseOrderWithServiceCharge(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        Amount: Decimal;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);
    end;

    local procedure FindPurchaseServiceChargeLine(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.FindFirst();
    end;

    local procedure CreateVendorWithServiceChargeAmount(var VendorNo: Code[20]; var ServiceChargeAmt: Decimal)
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        VendorNo := CreateVendorInvDiscount();
        ServiceChargeAmt := LibraryRandom.RandDecInDecimalRange(10, 20, 2);
        VendorInvoiceDisc.SetRange(Code, VendorNo);
        VendorInvoiceDisc.FindFirst();
        VendorInvoiceDisc.Validate("Service Charge", ServiceChargeAmt);
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure SetFirstPurchaseLineNotToReceive(var PurchHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Qty. to Receive", 0);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseInvoice(var PurchHeaderInvoice: Record "Purchase Header"; var PurchHeaderOrder: Record "Purchase Header"; var ItemCharge: Record "Item Charge")
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseLineInvoice: Record "Purchase Line";
        ItemChargePurchLine: Record "Purchase Line";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeaderInvoice, PurchHeaderInvoice."Document Type"::Invoice, PurchHeaderOrder."Buy-from Vendor No.");
        PurchaseLineInvoice.Validate("Document Type", PurchHeaderInvoice."Document Type");
        PurchaseLineInvoice.Validate("Document No.", PurchHeaderInvoice."No.");

        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchHeaderOrder."Buy-from Vendor No.");
        PurchRcptLine.SetFilter(Quantity, '<>%1', 0);
        PurchRcptLine.FindSet();
        repeat
            LibraryVariableStorage.Enqueue(PurchRcptLine."Document No.");
            LibraryVariableStorage.Enqueue(PurchRcptLine."Line No.");
            LibraryPurchase.GetPurchaseReceiptLine(PurchaseLineInvoice);
        until PurchRcptLine.Next() = 0;

        FindPurchaseLines(PurchaseLine, PurchHeaderInvoice, PurchaseLineType::Item);
        FindPurchaseLines(ItemChargePurchLine, PurchHeaderInvoice, PurchaseLineType::"Charge (Item)");
        LibraryPurchase.CreateItemChargeAssignment(
            ItemChargeAssignmentPurch, ItemChargePurchLine, ItemCharge,
            PurchHeaderInvoice."Document Type"::Invoice, PurchHeaderInvoice."No.", PurchaseLine."Line No.",
            PurchaseLine."No.", ItemChargePurchLine.Quantity, LibraryRandom.RandIntInRange(10, 20));
        ItemChargeAssignmentPurch.Insert(true);
    end;

    local procedure FindPurchaseLines(var PurchaseLines: Record "Purchase Line"; var PurchHeader: Record "Purchase Header"; PurchaseLineType: Enum "Purchase Line Type")
    begin
        PurchaseLines.SetRange("Document Type", PurchHeader."Document Type");
        PurchaseLines.SetRange("Document No.", PurchHeader."No.");
        PurchaseLines.SetRange(Type, PurchaseLineType);
        PurchaseLines.FindFirst();
    end;

    local procedure CreatePurchaseOrderWithItemCharge(var PurchHeader: Record "Purchase Header"; ItemChargeNo: Code[20]; var Items: array[2] of Record Item)
    var
        PurchaseLineItemCharge: Record "Purchase Line";
        PurchaseLineItem: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineItem, PurchHeader, PurchaseLineItem.Type::Item, Items[1]."No.", 1);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineItem, PurchHeader, PurchaseLineItem.Type::Item, Items[2]."No.", 1);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineItemCharge, PurchHeader, PurchaseLineItemCharge.Type::"Charge (Item)", ItemChargeNo, 1);
        PurchaseLineItemCharge.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLineItemCharge.Modify(true);
    end;

    local procedure UpdateQtyToReceiveOnPurchaseLineAndPostReceive(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal)
    begin
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure AttachDummyDocumentImageToRecord(RecRef: RecordRef; FlowPurchase: Boolean; FlowSales: Boolean)
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
    begin
        DocumentAttachment.Init();
        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');
        DocumentAttachment.SaveAttachment(RecRef, 'test.jpeg', TempBlob);

        if FlowPurchase then
            DocumentAttachment."Document Flow Purchase" := true;
        if FlowSales then
            DocumentAttachment."Document Flow Sales" := true;
        if FlowPurchase or FlowSales then
            DocumentAttachment.Modify();
        Clear(DocumentAttachment);
    end;

    local procedure CreateTempBLOBWithImageOfType(var TempBlob: Codeunit "Temp Blob"; ImageType: Text)
    var
        ImageFormat: DotNet ImageFormat;
        Bitmap: DotNet Bitmap;
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        Bitmap := Bitmap.Bitmap(1, 1);
        case ImageType of
            'png':
                Bitmap.Save(InStr, ImageFormat.Png);
            'jpeg':
                Bitmap.Save(InStr, ImageFormat.Jpeg);
            else
                Bitmap.Save(InStr, ImageFormat.Bmp);
        end;
        Bitmap.Dispose();
    end;

    local procedure VerifyItemChargeAssignmentQtyAssigned(DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();

        ItemChargeAssignmentPurch.SetRange("Document Type", ItemChargeAssignmentPurch."Document Type"::Order);
        ItemChargeAssignmentPurch.SetRange("Document No.", DocumentNo);
        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. No.", DocumentNo);
        ItemChargeAssignmentPurch.FindFirst();
        ItemChargeAssignmentPurch.TestField("Item No.", PurchaseLine."No.");

        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindFirst();
        ItemChargeAssignmentPurch.TestField("Applies-to Doc. No.", DocumentNo);
        ItemChargeAssignmentPurch.TestField("Item Charge No.", PurchaseLine."No.");
        ItemChargeAssignmentPurch.TestField("Qty. Assigned", ItemChargeAssignmentPurch."Qty. Assigned");
    end;

    local procedure CreatePurchaseLinesAndUpdateQtytoReceive(
        var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; LineType: Enum "Purchase Line Type";
        ItemNo: Code[20]; Quantity: Decimal; Qtytoreceive: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, LineType, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        ModifyPurchaseLineQtyToReceive(PurchaseLine, Qtytoreceive);
    end;

    local procedure FindItemChargePurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindLast();
    end;

    local procedure VerifyItemChargeQty(PurchaseLine: Record "Purchase Line")
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssignmentPurch.SetRange("Document Type", ItemChargeAssignmentPurch."Document Type"::Order);
        ItemChargeAssignmentPurch.SetRange("Document No.", PurchaseLine."Document No.");
        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. No.", PurchaseLine."Document No.");
        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Line No.", PurchaseLine."Line No.");
        ItemChargeAssignmentPurch.FindFirst();
        Assert.AreEqual(
            ItemChargeAssignmentPurch."Qty. to Assign",
            0,
            StrSubstNo(QuantityMustBeZeroLbl, ItemChargeAssignmentPurch.FieldCaption("Qty. to Assign")));
        Assert.AreEqual(
            ItemChargeAssignmentPurch."Qty. to Handle",
            0,
            StrSubstNo(QuantityMustBeZeroLbl, ItemChargeAssignmentPurch.FieldCaption("Qty. to Handle")));
    end;

    local procedure CreateStandardCostWorksheet(var StandardCostWorksheetPage: TestPage "Standard Cost Worksheet"; ResourceNo: Code[20]; StandardCost: Decimal; NewStandardCost: Decimal)
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
    begin
        StandardCostWorksheetPage.Type.SetValue(StandardCostWorksheet.Type::Resource);
        StandardCostWorksheetPage."No.".SetValue(ResourceNo);
        StandardCostWorksheetPage."Standard Cost".SetValue(StandardCost);
        StandardCostWorksheetPage."New Standard Cost".SetValue(NewStandardCost);
        StandardCostWorksheetPage.Next();
    end;

    local procedure ImplementStandardCostChanges(Resource: Record Resource; StandardCost: Decimal; NewStandardCost: Decimal)
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        StandardCostWorksheetPage: TestPage "Standard Cost Worksheet";
    begin
        StandardCostWorksheet.DeleteAll();
        StandardCostWorksheetPage.OpenEdit();
        CreateStandardCostWorksheet(StandardCostWorksheetPage, Resource."No.", StandardCost, NewStandardCost);
        Commit();  // Commit Required due to Run Modal.
        StandardCostWorksheetPage."&Implement Standard Cost Changes".Invoke();
    end;

    [RequestPageHandler]
    procedure ImplementStandardCostChangesHandler(var ImplementStandardCostChange: TestRequestPage "Implement Standard Cost Change")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ImplementStandardCostChange.ItemJournalTemplate.SetValue(ItemJournalTemplate.Name);
        ImplementStandardCostChange.ItemJournalBatchName.SetValue(ItemJournalBatch.Name);
        ImplementStandardCostChange.OK().Invoke();
    end;

    local procedure CreateLocationWithDimension(var Location: Record Location; var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20]; ValuePosting: Enum "Default Dimension Value Posting Type")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        if DimensionCode = '' then
            exit;
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Location, Location.Code, DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue.Code);
        DefaultDimension.Modify(true);
    end;

    local procedure CreatePurchaseLinesAndUpdateLocationAndDimension(
        var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; LineType: Enum "Purchase Line Type";
        ItemNo: Code[20]; Quantity: Decimal; QtytoReceive: Decimal; DirectUnitCost: Decimal; LocationCode: Code[10]; DimensionCode: Code[20])
    begin
        CreatePurchaseLinesAndUpdateQtytoReceive(
            PurchaseLine, PurchaseHeader, LineType,
            ItemNo, Quantity, QtytoReceive, DirectUnitCost);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Shortcut Dimension 1 Code", DimensionCode);
        PurchaseLine.Modify();
    end;

    local procedure FindDirectCostValueEntry(var ValueEntry: Record "Value Entry"; ItemNo: Code[20]; ItemChargeNo: Code[20])
    begin
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Charge No.", ItemChargeNo);
        ValueEntry.FindFirst();
    end;

    local procedure VerifyPurchaseOrderAfterPartialPostCorrectiveCreditMemo(PurchaseHeaderNo: Code[20]; ExpectedQuantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeaderNo);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.FindSet();
        repeat
            Assert.AreEqual(ExpectedQuantity, PurchaseLine."Qty. to Receive", StrSubstNo(
                PurchaseLineQtyErr, PurchaseLine.FieldName("Qty. to Receive"), ExpectedQuantity));
            Assert.AreEqual(ExpectedQuantity, PurchaseLine."Qty. to Invoice", StrSubstNo(
                PurchaseLineQtyErr, PurchaseLine.FieldName("Qty. to Invoice"), ExpectedQuantity));
        until PurchaseLine.Next() = 0;
    end;

    local procedure ModifyQtyToReceiveOnWarehouseReceiptLine(SourceNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptLine.Validate("Qty. to Receive", Qty);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure GetPostedDocumentLines(No: Code[20]; OptionStr: Option)
    var
        PurchCreditMemo: TestPage "Purchase Credit Memo";
    begin
        LibraryVariableStorage.Enqueue(OptionStr);
        PurchCreditMemo.OpenEdit();
        PurchCreditMemo.FILTER.SetFilter("No.", No);
        PurchCreditMemo.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; Type: Enum "Purchase Line Type")
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, Type);
        PurchaseLine.FindFirst();
    end;

    local procedure VerifyPurchaseOrderQuantityforManualPurchaseCreditMemo(PurchaseHeaderNo: Code[20]; ExpectedQuantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeaderNo);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.FindSet();
        repeat
            Assert.AreEqual(ExpectedQuantity, PurchaseLine."Qty. to Receive", StrSubstNo(
                PurchaseLineQtyErr, PurchaseLine.FieldName("Qty. to Receive"), ExpectedQuantity));
            Assert.AreEqual(ExpectedQuantity, PurchaseLine."Qty. to Invoice", StrSubstNo(
                PurchaseLineQtyErr, PurchaseLine.FieldName("Qty. to Invoice"), ExpectedQuantity));
        until PurchaseLine.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StandardVendorPurchCodesHndlr(var StandardVendorPurchaseCodes: TestPage "Standard Vendor Purchase Codes")
    begin
        StandardVendorPurchaseCodes.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NavigatePageHandler(var Navigate: Page Navigate)
    begin
        Navigate.SetDoc(PostingDate2, DocumentNo2);
        Navigate.UpdateNavigateForm(false);
        Navigate.FindRecordsOnOpen();

        TempDocumentEntry2.DeleteAll();
        Navigate.ReturnDocumentEntry(TempDocumentEntry2);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SuggstItemChargeAssgntVldHndlr(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        ItemChargeAssignmentPurch."Applies-to Doc. Type".AssertEquals(PurchaseLine."Document Type"::Order);
        ItemChargeAssignmentPurch."Applies-to Doc. No.".AssertEquals(DocumentNo2);
        ItemChargeAssignmentPurch."Qty. to Assign".AssertEquals(0);
        ItemChargeAssignmentPurch."Amount to Assign".AssertEquals(0);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PostOrderStrMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeSetupHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    var
        DequedVar: Variant;
        IsSetup: Boolean;
        AmountToAssign: Decimal;
        QuantityToAssign: Decimal;
    begin
        LibraryVariableStorage.Dequeue(DequedVar);
        IsSetup := DequedVar;

        if IsSetup then begin
            LibraryVariableStorage.Dequeue(DequedVar);
            QuantityToAssign := DequedVar;
            ItemChargeAssignmentPurch."Qty. to Assign".SetValue(QuantityToAssign);
        end else begin
            LibraryVariableStorage.Dequeue(DequedVar);
            AmountToAssign := DequedVar;
            ItemChargeAssignmentPurch."Amount to Assign".AssertEquals(AmountToAssign);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QtyToAssgnItemChargeModalPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        if LibraryVariableStorage.DequeueBoolean() then
            ItemChargeAssignmentPurch."Qty. to Assign".SetValue(LibraryVariableStorage.DequeueDecimal())
        else
            LibraryVariableStorage.Enqueue(ItemChargeAssignmentPurch."Qty. to Assign".Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GrossWeightItemChargeAssignmentHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();

        Assert.AreNotEqual(
            ItemChargeAssignmentPurch."<Gross Weight>".AsDecimal(),
            0,
            StrSubstNo(
                GrossWeightErr,
                ItemChargeAssignmentPurch."<Gross Weight>".Caption(),
                ItemChargeAssignmentPurch.Caption()));

        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYesNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerWithVerification(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReceiptLinesPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    begin
        GetReceiptLines.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure EditAnalysisReportPurchaseRequestPageHandler(var PurchaseAnalysisReport: TestPage "Purchase Analysis Report")
    var
        PurchasePeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        PurchaseAnalysisReport.PeriodType.SetValue(PurchasePeriodType::Year);
        PurchaseAnalysisReport.ShowMatrix.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisMatrixRequestPageHandler(var PurchaseAnalysisMatrix: TestPage "Purchase Analysis Matrix")
    var
        CostAmountExpected: Variant;
    begin
        LibraryVariableStorage.Dequeue(CostAmountExpected);
        PurchaseAnalysisMatrix.Field1.AssertEquals(CostAmountExpected);
        Assert.IsTrue(PurchaseAnalysisMatrix.Field1.Visible(), StrSubstNo(ColumnWrongVisibilityErr, 1));
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), PurchaseAnalysisMatrix.Field1.Caption, '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinesPageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentType: Option "Posted Receipts","Posted Invoices","Posted Return Shipments","Posted Cr. Memos";
    begin
        case LibraryVariableStorage.DequeueInteger() of
            OptionStringRef::"Posted Receipts":
                PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Receipts"));
            OptionStringRef::"Posted Invoices":
                PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Invoices"));
            OptionStringRef::"Posted Return Shipments":
                PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Return Shipments"));
            OptionStringRef::"Posted Cr. Memos":
                PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Cr. Memos"));
        end;
        PostedPurchaseDocumentLines.PostedRcpts.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisMatrixColumnsRPH(var MatrixForm: TestPage "Purchase Analysis Matrix")
    var
        CountVar: Variant;
        FieldVisibilityArray: array[32] of Boolean;
        "Count": Integer;
        Index: Integer;
    begin
        LibraryVariableStorage.Dequeue(CountVar);
        Count := CountVar;

        FieldVisibilityArray[1] := MatrixForm.Field1.Visible();
        FieldVisibilityArray[2] := MatrixForm.Field2.Visible();
        FieldVisibilityArray[3] := MatrixForm.Field3.Visible();
        FieldVisibilityArray[4] := MatrixForm.Field4.Visible();
        FieldVisibilityArray[5] := MatrixForm.Field5.Visible();
        FieldVisibilityArray[6] := MatrixForm.Field6.Visible();
        FieldVisibilityArray[7] := MatrixForm.Field7.Visible();
        FieldVisibilityArray[8] := MatrixForm.Field8.Visible();
        FieldVisibilityArray[9] := MatrixForm.Field9.Visible();
        FieldVisibilityArray[10] := MatrixForm.Field10.Visible();
        FieldVisibilityArray[11] := MatrixForm.Field11.Visible();
        FieldVisibilityArray[12] := MatrixForm.Field12.Visible();
        FieldVisibilityArray[13] := MatrixForm.Field13.Visible();
        FieldVisibilityArray[14] := MatrixForm.Field14.Visible();
        FieldVisibilityArray[15] := MatrixForm.Field15.Visible();
        FieldVisibilityArray[16] := MatrixForm.Field16.Visible();
        FieldVisibilityArray[17] := MatrixForm.Field17.Visible();
        FieldVisibilityArray[18] := MatrixForm.Field18.Visible();
        FieldVisibilityArray[19] := MatrixForm.Field19.Visible();
        FieldVisibilityArray[20] := MatrixForm.Field20.Visible();
        FieldVisibilityArray[21] := MatrixForm.Field21.Visible();
        FieldVisibilityArray[22] := MatrixForm.Field22.Visible();
        FieldVisibilityArray[23] := MatrixForm.Field23.Visible();
        FieldVisibilityArray[24] := MatrixForm.Field24.Visible();
        FieldVisibilityArray[25] := MatrixForm.Field25.Visible();
        FieldVisibilityArray[26] := MatrixForm.Field26.Visible();
        FieldVisibilityArray[27] := MatrixForm.Field27.Visible();
        FieldVisibilityArray[28] := MatrixForm.Field28.Visible();
        FieldVisibilityArray[29] := MatrixForm.Field29.Visible();
        FieldVisibilityArray[30] := MatrixForm.Field30.Visible();
        FieldVisibilityArray[31] := MatrixForm.Field31.Visible();
        FieldVisibilityArray[32] := MatrixForm.Field32.Visible();

        for Index := 1 to Count do
            Assert.AreEqual(true, FieldVisibilityArray[Index], StrSubstNo(ColumnWrongVisibilityErr, Index));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCodePageHandler(var StandardVendorPurchaseCodes: Page "Standard Vendor Purchase Codes"; var Response: Action)
    var
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        VendorNo: Variant;
    begin
        // Modal Page Handler.
        LibraryVariableStorage.Dequeue(VendorNo);
        StandardVendorPurchaseCode.SetRange("Vendor No.", VendorNo);
        StandardVendorPurchaseCode.FindFirst();

        StandardVendorPurchaseCodes.SetRecord(StandardVendorPurchaseCode);
        Response := ACTION::LookupOK;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPurchaseDocumentHandler(var CopyPurchaseDocument: TestRequestPage "Copy Purchase Document")
    var
        DocType: Option;
        DocumentType: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(No);
        DocType := DocumentType;
        CopyPurchaseDocument.DocumentType.SetValue(DocType);
        CopyPurchaseDocument.DocumentNo.SetValue(No);
        CopyPurchaseDocument.IncludeHeader_Options.SetValue(true);
        CopyPurchaseDocument.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseStatistics.SubForm."VAT Amount".SetValue(
          PurchaseStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal());
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, LibraryVariableStorage.DequeueText());
        PurchaseStatistics.GotoRecord(PurchaseHeader); // Refresh
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExactMessageHandler(Message: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TemplateSelectionPageHandler(var SelectVendorTemplList: TestPage "Select Vendor Templ. List")
    begin
        SelectVendorTemplList.First();
        SelectVendorTemplList.OK().Invoke();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure StandardPurchaseOrderReportDataHandler(var StandardPurchaseOrder: Report "Standard Purchase - Order")
    begin
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsUpdateTotalVATHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
        PurchaseOrderStatistics.OK().Invoke();
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsUpdateTotalVATPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
        PurchaseOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATAmountLinesHandler(var VATAmountLine: TestPage "VAT Amount Lines")
    var
        VATAmount: Decimal;
    begin
        VATAmount := VATAmountLine."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal();
        LibraryVariableStorage.Enqueue(VATAmount);
        VATAmountLine."VAT Amount".SetValue(VATAmount);
        VATAmountLine.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.GetReceiptLines.Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceListPageHandler(var ResourceList: TestPage "Resource List")
    begin
        ResourceList.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ResourceList.First();
        ResourceList.Cancel().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ExplodeBOMHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestRequestPageHandler(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    begin
        // Close handler
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderTestRequestPageHandler(var PurchaseOrder: TestPage "Purchase Order")
    begin
        PurchaseOrder.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure StandardPurchaseOrderRequestPageHandler(var StandardPurchaseOrder: TestRequestPage "Standard Purchase - Order")
    begin
        StandardPurchaseOrder.Preview().Invoke();
    end;

    [ModalPageHandler]
    procedure GetReceiptLinesModalPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    var
        DocumentNo: Code[20];
        LineNo: Integer;
    begin
        DocumentNo := LibraryVariableStorage.DequeueText();
        LineNo := LibraryVariableStorage.DequeueInteger();
        GetReceiptLines.GotoKey(DocumentNo, LineNo);
        GetReceiptLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorLookupHandler(var VendorLookup: TestPage "Vendor Lookup")
    begin
        VendorLookup.GotoKey(LibraryVariableStorage.DequeueText());
        VendorLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemChargeAssignmentModalPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        if LibraryVariableStorage.DequeueBoolean() then
            ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchModalPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch."Qty. to Assign".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure PrintPurchaseOrderRequestPageHandler(var StandardPurchaseOrder: TestRequestPage "Standard Purchase - Order")
    begin
        Assert.IsTrue(StandardPurchaseOrder.LogInteraction.Enabled(), InteractionLogErr);
    end;

    [ModalPageHandler]
    procedure ItemListOkModalPageHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ItemList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemListCancelModalPageHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ItemList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure PostedPurchaseDocumentLinesHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentType: Option "Posted Shipments","Posted Invoices","Posted Return Receipts","Posted Cr. Memos";
    begin
        case LibraryVariableStorage.DequeueInteger() of
            OptionString::PostedReturnReceipt:
                PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Return Receipts"));
            OptionString::PostedInvoices:
                PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Invoices"));
            OptionString::PostedShipments:
                PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Shipments"));
            OptionString::PostedCrMemo:
                PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Cr. Memos"));
        end;
        PostedPurchaseDocumentLines.OK().Invoke();
    end;
}
