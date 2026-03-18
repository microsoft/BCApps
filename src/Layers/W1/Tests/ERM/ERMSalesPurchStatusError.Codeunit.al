codeunit 134383 "ERM Sales/Purch Status Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Error]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryResource: Codeunit "Library - Resource";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        NoSeriesNumbersPrefix: Code[3];
        StringLengthExceededErr: Label 'StringLengthExceeded';
        DateFilterTok: Label '%1..%2', Locked = true;
        JournalLineErr: Label 'You are not allowed to apply and post an entry to an entry with an earlier posting date.';
        FieldValueErr: Label 'Wrong %1 in %2';
        SalesDocumentTestReportDimErr: Label 'Sales Document Test Report has dimension errors';
        UnexpectedLocationCodeErr: Label 'Unexpected location code.';
        PostingDateNotAllowedErr: Label 'Posting Date is not within your range of allowed posting dates';
        ItemGETTok: Label 'Item.GET';
        NonCopleteOrderErr: Label 'This document cannot be shipped completely. Change the value in the Shipping Advice field to Partial.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderVATProdPostingError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Check that Error Raised on Validate of VAT Prod. Posting Group on Sales Line when Sales Order is Released.

        // Setup.
        Initialize();
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // Exercise: Validate VAT Prod. Posting Group for Error.
        SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        asserterror SalesLine2.Validate("VAT Prod. Posting Group");

        // Verify: Verify Error Raised on Sales Line Validation.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderQuantityError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Check that Error Raised on Validate of Qty on Sales Line when Sales Order is Released.

        // Setup.
        Initialize();
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // Exercise: Validate Quantity for Error.
        SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        asserterror SalesLine2.Validate(Quantity);

        // Verify: Verify Error Raised on Sales Line Validation.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderItemNoError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Check that Error Raised on Validate of Item No. on Sales Line when Sales Order is Released.

        // Setup.
        Initialize();
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // Exercise: Validate Item No. for Error.
        SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        asserterror SalesLine2.Validate("No.");

        // Verify: Verify Error Raised on Sales Line Validation.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderLineDiscountError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Check that Error Raised on Validate of Line Discount Percent on Sales Line when Sales Order is Released.

        // Setup.
        Initialize();
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // Exercise: Validate Line Discount for Error.
        SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        asserterror SalesLine2.Validate("Line Discount %");

        // Verify: Verify Error Raised on Sales Line Validation.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderUnitPriceError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Check that Error Raised on Validate of Unit Price on Sales Line when Sales Order is Released.

        // Setup.
        Initialize();
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // Exercise: Validate Unit Price for Error.
        SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        asserterror SalesLine2.Validate("Unit Price");

        // Verify: Verify Error Raised on Sales Line Validation.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderAllowInvDiscError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Check that Error Raised on Validate of Allow Invoice Discount on Sales Line when Sales Order is Released.

        // Setup.
        Initialize();
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // Exercise: Validate Allow Invoice Discount for Error.
        SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        asserterror SalesLine2.Validate("Allow Invoice Disc.");

        // Verify: Verify Error Raised on Sales Line Validation.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderTypeError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Check that Error Raised on Validate of Type on Sales Line when Sales Order is Released.

        // Setup.
        Initialize();
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // Exercise: Validate Sales Line Type for Error.
        SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        asserterror SalesLine2.Validate(Type);

        // Verify: Verify Error Raised on Sales Line Validation.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderPrepaymentNoSeriesValidation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check Prepayment No Series. validation does not throw unexpected error

        // Setup.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // Excercise and Verify: validation should be done without error.
        SalesHeader.Validate("Prepayment No. Series", SetupSalesPrepaymentInvNoSeries());
        SalesHeader.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoPrepaymentCrMemoNoSeriesValidation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check Prepayment Cr. Memo No. Series. validation does not throw unexpected error

        // Setup.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo");

        // Excercise and Verify: validation should be done without error.
        SalesHeader.Validate("Prepmt. Cr. Memo No. Series", SetupSalesPrepaymentCrMemoNoSeries());
        SalesHeader.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderPrepaymentCrMemoNoSeriesValidation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check Prepayment Cr. Memo No. Series. validation does not throw unexpected error

        // Setup.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");

        // Excercise and Verify: validation should be done without error.
        SalesHeader.Validate("Prepmt. Cr. Memo No. Series", SetupSalesPrepaymentCrMemoNoSeries());
        SalesHeader.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderUnitCostRetReasonInvValueZeroTrue()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check Direct Cost in Sales Line after validating Location Code when Return Reason Code is set

        // Setup.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");

        // Excercise: setup return reason code and location
        UpdateReturnReasonCodeOnSalesLine(SalesLine, true);

        // Verify
        VerifySalesLineUnitCost(SalesLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderUnitCostRetReasonInvValueZeroFalse()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check Direct Cost in Sales Line after validating Location Code when Return Reason Code is set

        // Setup.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");

        // Excercise: setup return reason code and location
        UpdateReturnReasonCodeOnSalesLine(SalesLine, false);

        // Verify
        VerifySalesLineUnitCost(SalesLine, GetItemCost(SalesLine."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderUnitCostRemoveRetReasonInvValueZeroTrue()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 181156] "Unit Cost" is recalculated after removal of "Return Reason Code" with "Inventory Value Zero" in Sales Return Order

        Initialize();

        // [GIVEN] Sales Return Order with "Unit Cost" = "X"
        CreateSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");

        // [GIVEN] "Return Reason Code" with "Inventory Value Zero" is set in Sales Line
        UpdateReturnReasonCodeOnSalesLine(SalesLine, true);

        // [WHEN] Remove "Return Reason Code" from Sales Line
        SalesLine.Validate("Return Reason Code", '');

        // [THEN] "Unit Cost" is "X" in Sales Line
        VerifySalesLineUnitCost(SalesLine, GetItemCost(SalesLine."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderUnitCostWhenValidateQtyAfterReturnReasonCodeWithInvValueZero()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 181156] "Unit Cost" is zero when validate Quantity after "Return Reason Code" with "Inventory Value Zero" in Sales Return Order

        Initialize();

        // [GIVEN] Item "A" with "Costing Method" = Standard
        // [GIVEN] Sales Return Order with Item "A", Quantity = 0 and "Unit Cost" = "X"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithCostingMethodStandard(), 0);

        // [GIVEN] "Return Reason Code" with "Inventory Value Zero" is set in Sales Line
        UpdateReturnReasonCodeOnSalesLine(SalesLine, true);

        // [WHEN] Set Quantity = 1 in Sales Return Order
        SalesLine.Validate(Quantity, 1);

        // [THEN] "Unit Cost" is 0 in Sales Line
        VerifySalesLineUnitCost(SalesLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDeletion()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Check that Sales Header does not exist after Deletion.

        // Setup.
        Initialize();
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        DocumentNo := SalesLine."Document No.";

        // Exercise: Delete Sales Order.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.Delete(true);

        // Verify: Verify that Sales Order does not exist after Deletion.
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo), 'Sales Header must not exist.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderVATProdPostingError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Check that Error Raised on Validate of VAT Prod. Posting Group on Purchase Line when Purchase Order is Released.

        // Setup.
        Initialize();
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // Exercise: Validate VAT Prod. Posting Group for Error.
        PurchaseLine2.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        asserterror PurchaseLine2.Validate("VAT Prod. Posting Group");

        // Verify: Verify Error Raised on Purchase Line Validation.
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption(Status), Format(PurchaseHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderQuantityError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Check that Error Raised on Validate of Quantity on Purchase Line when Purchase Order is Released.

        // Setup.
        Initialize();
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // Exercise: Validate Quantity for Error.
        PurchaseLine2.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        asserterror PurchaseLine2.Validate(Quantity);

        // Verify: Verify Error Raised on Purchase Line Validation.
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption(Status), Format(PurchaseHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderItemNoError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Check that Error Raised on Validate of Item No. on Purchase Line when Purchase Order is Released.

        // Setup.
        Initialize();
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // Exercise: Validate Item No. for Error.
        PurchaseLine2.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        asserterror PurchaseLine2.Validate("No.");

        // Verify: Verify Error Raised on Purchase Line Validation.
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption(Status), Format(PurchaseHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderLineDiscountAmtError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Check that Error Raised on Validate of Line Discount Amount on Purchase Line when Purchase Order is Released.

        // Setup.
        Initialize();
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // Exercise: Validate Line Discount Amount for Error.
        PurchaseLine2.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        asserterror PurchaseLine2.Validate("Line Discount Amount");

        // Verify: Verify Error Raised on Purchase Line Validation.
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption(Status), Format(PurchaseHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderLineAmtError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Check that Error Raised on Validate of Line Amount on Purchase Line when Purchase Order is Released.

        // Setup.
        Initialize();
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // Exercise: Validate Line Amount for Error.
        PurchaseLine2.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        asserterror PurchaseLine2.Validate("Line Amount");

        // Verify: Verify Error Raised on Purchase Line Validation.
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption(Status), Format(PurchaseHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderChargeError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Check that Error Raised on Validate of Type Charge (Item) on Purchase Line when Purchase Order is Released.

        // Setup.
        Initialize();
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // Exercise: Validate Type Charge (Item) for Error.
        PurchaseLine2.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        asserterror PurchaseLine2.Validate(Type, PurchaseLine2.Type::"Charge (Item)");

        // Verify: Verify Error Raised on Purchase Line Validation.
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption(Status), Format(PurchaseHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderPrepaymentNoSeriesValidation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check PrepaymentNo. Series. validation does not throw unexpected error

        // Setup.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // Exercise and Verify: field validation must not throw error
        PurchaseHeader.Validate("Prepayment No. Series", SetupPurchasePrepaymentInvNoSeries());
        PurchaseHeader.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoPrepaymentCrMemoNoSeriesValidation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Prepayment Cr. Memo No. Series. validation does not throw unexpected error

        // Setup.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo");

        // Exercise and Verify: field validation must not throw error
        PurchaseHeader.Validate("Prepmt. Cr. Memo No. Series", SetupPurchasePrepaymentCrMemoNoSeries());
        PurchaseHeader.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderPrepaymentCrMemoNoSeriesValidation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Prepayment Cr. Memo No. Series. validation does not throw unexpected error

        // Setup.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order");

        // Exercise and Verify: field validation must not throw error
        PurchaseHeader.Validate("Prepmt. Cr. Memo No. Series", SetupPurchasePrepaymentCrMemoNoSeries());
        PurchaseHeader.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderUnitCostRetReasonInvValueZeroTrue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Direct Cost in Purchase Line after validating Location Code when Return Reason Code is set

        // Setup.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order");

        // Excercise: setup return reason code and location

        UpdateReturnReasonCodeOnPurchaseLine(PurchaseLine, true);

        // Verify
        VerifyPurchaseLineUnitCost(PurchaseLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderUnitCostRetReasonInvValueZeroFalse()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Direct Cost in Purchase Line after validating Location Code when Return Reason Code is set

        // Setup.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order");

        // Excercise: setup return reason code and location
        UpdateReturnReasonCodeOnPurchaseLine(PurchaseLine, false);

        // Verify
        VerifyPurchaseLineUnitCost(PurchaseLine, GetItemCost(PurchaseLine."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderUnitCostRemoveRetReasonInvValueZeroTrue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ExpectedDirectUnitCost: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 181156] "Direct Unit Cost" is recalculated after removal of "Return Reason Code" with "Inventory Value Zero" in Purchase Return Order

        Initialize();

        // [GIVEN] Purchase Return Order with "Direct Unit Cost" = "X"
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order");
        ExpectedDirectUnitCost := PurchaseLine."Direct Unit Cost";

        // [GIVEN] "Return Reason Code" with "Inventory Value Zero" is set in Purchase Line
        UpdateReturnReasonCodeOnPurchaseLine(PurchaseLine, true);

        // [WHEN] Remove "Return Reason Code" from Purchase Line
        PurchaseLine.Validate("Return Reason Code", '');

        // [THEN] "Direct Unit Cost" is "X" in Purchase Line
        VerifyPurchaseLineUnitCost(PurchaseLine, ExpectedDirectUnitCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderUnitCostWhenValidateQtyAfterReturnReasonCodeWithInvValueZero()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 181156] "Direct Unit Cost" is zero when validate Quantity after "Return Reason Code" with "Inventory Value Zero" in Purchase Return Order

        Initialize();

        // [GIVEN] Item "A" with "Costing Method" = Standard
        // [GIVEN] Purchase Return Order with Item "A", Quantity = 0 and "Direct Unit Cost" = "X"
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, CreateItemWithCostingMethodStandard(), 0);

        // [GIVEN] "Return Reason Code" with "Inventory Value Zero" is set in Purchase Line
        PurchLine.Validate("Return Reason Code", SetupReturnReasonCode(true));

        // [WHEN] Set Quantity = 1 in Purchase Return Order
        PurchLine.Validate(Quantity, 1);

        // [THEN] "Direct Unit Cost" is 0 in Purchase Line
        VerifyPurchaseLineUnitCost(PurchLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderDeletion()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Check that Purchase Order does not exist after Deleting.

        // Setup.
        Initialize();
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);
        DocumentNo := PurchaseLine."Document No.";

        // Exercise: Delete Purchase Header.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.Delete(true);

        // Verify: Verify Purchase Header does not exist after Deletion.
        Assert.IsFalse(PurchaseHeader.Get(PurchaseLine."Document Type", DocumentNo), 'Purchase Header must not exist.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtAfterSalesOrderRelease()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check VAT Amount on Sales Order when its Release.
        Initialize();
        CreateSalesDocCheckAmtRelease(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtAfterSalesOrderOpen()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check VAT Amount on Sales Order when its Open.
        Initialize();
        CreateSalesDocCheckAmtOpen(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtAfterSalesCMRelease()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check VAT Amount on Sales Credit Memo when its Release.
        Initialize();
        CreateSalesDocCheckAmtRelease(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtAfterSalesCMOpen()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check VAT Amount on Sales Credit Memo when its Open.
        Initialize();
        CreateSalesDocCheckAmtOpen(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtAfterPurchOrderRelease()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check VAT Amount on Purchase Order when its Release.
        Initialize();
        CreatePurchDocCheckAmtRelease(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtAfterPurchOrderOpen()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check VAT Amount on Purchase Order when its Open.
        Initialize();
        CreatePurchDocCheckAmtOpen(PurchaseHeader."Document Type"::Order);
    end;

    local procedure CreateSalesDocCheckAmtRelease(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATBaseAmt: Decimal;
        AmtIncVAT: Decimal;
    begin
        // Setup.
        CreateSalesOrder(SalesHeader, SalesLine, DocumentType);
        VATBaseAmt := SalesLine."Unit Price" * SalesLine.Quantity;
        AmtIncVAT := Round(VATBaseAmt + (VATBaseAmt * SalesLine."VAT %") / 100);

        // Exercise: Release Sales Document.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Verify: Verify VAT Base Amount and Amount Including VAT on Sales Line.
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        SalesLine.TestField("VAT Base Amount", VATBaseAmt);
        SalesLine.TestField("Amount Including VAT", AmtIncVAT);
    end;

    local procedure CreateSalesDocCheckAmtOpen(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create and Release Sales Document.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, DocumentType);

        // Exercise: Open Sales Document.
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // Verify: Verify VAT Base Amount and Amount Including VAT on Sales Line.
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        SalesLine.TestField("VAT Base Amount");
        SalesLine.TestField("Amount Including VAT");
    end;

    local procedure CreatePurchDocCheckAmtRelease(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATBaseAmt: Decimal;
        AmtIncVAT: Decimal;
    begin
        // Setup.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, DocumentType);
        VATBaseAmt := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity;
        AmtIncVAT := Round(VATBaseAmt + (VATBaseAmt * PurchaseLine."VAT %") / 100);

        // Exercise: Release Purchase Document.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Verify: Verify VAT Base Amount and Amount Including VAT on Purchase Line.
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        PurchaseLine.TestField("VAT Base Amount", VATBaseAmt);
        PurchaseLine.TestField("Amount Including VAT", AmtIncVAT);
    end;

    local procedure CreatePurchDocCheckAmtOpen(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create and Release Purchase Order.
        Initialize();
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, DocumentType);

        // Exercise: Open Purchase Document.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // Verify: Verify VAT Base Amount and Amount Including VAT on Purchase Line.
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        PurchaseLine.TestField("VAT Base Amount");
        PurchaseLine.TestField("Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentTestReport()
    var
        SalesHeader: Record "Sales Header";
        SalesDocumentTest: Report "Sales Document - Test";
        DefaultPostingDate: Enum "Default Posting Date";
        FilePath: Text[1024];
    begin
        // Check Sales Document - Test Report when Sales Order is created with Foreign Currency and Blank Posting Date.

        // Setup.
        Initialize();
        SetupAndCreateSalesDocument(SalesHeader, DefaultPostingDate, SalesHeader."Document Type"::Order);

        // Exercise: Run and Save Sales Document - Test Report.
        Clear(SalesDocumentTest);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", SalesHeader."No.");
        SalesDocumentTest.SetTableView(SalesHeader);
        FilePath := TemporaryPath + Format(SalesHeader."Document Type") + SalesHeader."No." + '.xlsx';
        SalesDocumentTest.SaveAsExcel(FilePath);

        // Verify: Verify that saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);

        // Tear Down: Cleanup of Setup Done.
        UpdateSalesReceivableSetup(DefaultPostingDate, DefaultPostingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderConfirmReport()
    var
        SalesHeader: Record "Sales Header";
        ReturnOrderConfirmation: Report "Return Order Confirmation";
        DefaultPostingDate: Enum "Default Posting Date";
        FilePath: Text[1024];
    begin
        // Check Return Order Confirmation Report when Sales Order is created with Foreign Currency and Blank Posting Date.

        // Setup.
        Initialize();
        SetupAndCreateSalesDocument(SalesHeader, DefaultPostingDate, SalesHeader."Document Type"::"Return Order");

        // Exercise: Run and Save Return Order Confirmation Report.
        Clear(ReturnOrderConfirmation);
        ReturnOrderConfirmation.SetTableView(SalesHeader);
        FilePath := TemporaryPath + Format(SalesHeader."Document Type") + SalesHeader."No." + '.xlsx';
        ReturnOrderConfirmation.SaveAsExcel(FilePath);

        // Verify: Verify that saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);

        // Tear Down: Cleanup of Setup Done.
        UpdateSalesReceivableSetup(DefaultPostingDate, DefaultPostingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchDocumentTestReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocumentTest: Report "Purchase Document - Test";
        DefaultPostingDate: Enum "Default Posting Date";
        FilePath: Text[1024];
    begin
        // Check Purchase Document - Test Report when Purchase Order is created with Foreign Currency and Blank Posting Date.

        // Setup.
        Initialize();
        SetupAndCreatePurchDocument(PurchaseHeader, DefaultPostingDate, PurchaseHeader."Document Type"::Order);

        // Exercise: Run and Save Purchase Document - Test Report.
        Clear(PurchaseDocumentTest);
        PurchaseDocumentTest.SetTableView(PurchaseHeader);
        FilePath := TemporaryPath + Format(PurchaseHeader."Document Type") + PurchaseHeader."No." + '.xlsx';
        PurchaseDocumentTest.SaveAsExcel(FilePath);

        // Verify: Verify that saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);

        // Tear Down: Cleanup of Setup Done.
        UpdatePurchasePayableSetup(DefaultPostingDate, DefaultPostingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
        "Order": Report "Order";
        DefaultPostingDate: Enum "Default Posting Date";
        FilePath: Text[1024];
    begin
        // Check Order Report when Purchase Order is created with Foreign Currency and Blank Posting Date.

        // Setup.
        Initialize();
        SetupAndCreatePurchDocument(PurchaseHeader, DefaultPostingDate, PurchaseHeader."Document Type"::Order);

        // Exercise: Run and Save Order Report.
        Clear(Order);
        Order.SetTableView(PurchaseHeader);
        FilePath := TemporaryPath + Format(PurchaseHeader."Document Type") + PurchaseHeader."No." + '.xlsx';
        Order.SaveAsExcel(FilePath);

        // Verify: Verify that saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);

        // Tear Down: Cleanup of Setup Done.
        UpdatePurchasePayableSetup(DefaultPostingDate, DefaultPostingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
        ReturnOrder: Report "Return Order";
        DefaultPostingDate: Enum "Default Posting Date";
        FilePath: Text[1024];
    begin
        // Check Return Order Report when Purchase Order is created with Foreign Currency and Blank Posting Date.

        // Setup.
        Initialize();
        SetupAndCreatePurchDocument(PurchaseHeader, DefaultPostingDate, PurchaseHeader."Document Type"::"Return Order");

        // Exercise: Run and Save Return Order Report.
        ReturnOrder.SetTableView(PurchaseHeader);
        Clear(ReturnOrder);
        FilePath := TemporaryPath + Format(PurchaseHeader."Document Type") + PurchaseHeader."No." + '.xlsx';
        ReturnOrder.SaveAsExcel(FilePath);

        // Verify: Verify that saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);

        // Tear Down: Cleanup of Setup Done.
        UpdatePurchasePayableSetup(DefaultPostingDate, DefaultPostingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExceededLengthOfTarriffNo()
    var
        TariffNumber: Record "Tariff Number";
    begin
        // Verify error while insert Tariff No. more than 20 characters.

        // Setup.
        Initialize();
        TariffNumber.Init();

        // Exercise.
        asserterror TariffNumber.Validate(
            "No.", (LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID()));  // Assign More than 20 characters.

        // Verify: Verify error while insert Tariff No. more than 20 characters.
        Assert.ExpectedErrorCode(StringLengthExceededErr);
    end;

    [Test]
    [HandlerFunctions('ShowMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure DateFilterOnItemStatistic()
    var
        Item: Record Item;
        ItemStatistics: TestPage "Item Statistics";
    begin
        // Verify Values on Item Matrix after set Date Filter on Item Statistics.

        // Setup. Find Item, open Item Statistics page and set Item and Date Filter.
        Initialize();
        LibraryInventory.CreateItem(Item);
        ItemStatistics.OpenEdit();
        ItemStatistics.ItemFilter.SetValue(Item."No.");
        ItemStatistics.DateFilter.SetValue(StrSubstNo(DateFilterTok, WorkDate(), CalcDate('<2M>', WorkDate())));

        // Exercise.
        ItemStatistics.ShowMatrix.Invoke();

        // Verify: Verify Values on Item Matrix by ShowMatrixPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPaymentWithEarlierDateThanOnSalesInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Error raised on Validate of Customer No. on Cash Receipt Journal Line when payment date for Cash Receipt is earlier than Sales Invoice Date.
        PostCashReceiptWithEarlierDateToCustomer(GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRefundWithEarlierDateThanOnCustomerCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Error raised on Validate of Customer No. on  Cash Receipt Journal Line when payment date for refund is earlier than Credit Memo Date.
        PostCashReceiptWithEarlierDateToCustomer(GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund);
    end;

    local procedure PostCashReceiptWithEarlierDateToCustomer(DocumentTypeForSalesJournal: Enum "Gen. Journal Document Type"; DocumentTypeForCashReceiptJournal: Enum "Gen. Journal Document Type")
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLineForPayment: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Setup: Post Sales Journal and Update Applies Doc No. on Cash Recceipt Journal.
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        CreateCustomerWithPaymentTermsCode(Customer);
        CreateJournalLine(GenJournalLine, Customer."Gen. Bus. Posting Group", DocumentTypeForSalesJournal,
          GenJournalLine."Gen. Posting Type"::Sale, GenJournalTemplate.Type::Sales,
          GenJournalLine."Account Type"::Customer, Customer."No.", CreateAmount(DocumentTypeForSalesJournal));
        UpdateAdjustForPaymentDiscountOnVATPostingSetup(GenJournalLine, true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindBankAccount(BankAccount);
        CreateJournalLineWithAppliesToDocNo(GenJournalLineForPayment, GenJournalTemplate.Type::"Cash Receipts",
          DocumentTypeForCashReceiptJournal, GenJournalLine."Document Type", GenJournalLine."Bal. Account Type"::Customer,
          GenJournalLine."Document No.");
        GenJournalLineForPayment.Validate("Bal. Account No.", Customer."No.");

        // Exercise: Validate "Applies-to Doc. No." on Payment Journal Line.
        asserterror GenJournalLineForPayment.Validate("Applies-to Doc. No.", GenJournalLine."Document No.");

        // Verify: Verify Error raised on General Journal Line Validation.
        Assert.ExpectedError(JournalLineErr);

        // Tear down.
        UpdateAdjustForPaymentDiscountOnVATPostingSetup(GenJournalLine, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPaymentWithEarlierDateThanOnPurchaseInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Error raised on Validate of Vendor No. on Payment Journal Line when payment date for Vendor payment is earlier than Purchase Invoice Date.
        PostPaymentWithEarlierDateToVendor(GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRefundWithEarlierDateOnOnVendorCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Error raised on Validate of Vendor No. on Payment Journal Line when payment date on Vendor refund is earlier than on Credit Memo Date.
        PostPaymentWithEarlierDateToVendor(
            GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund);
    end;

    [Test]
    [HandlerFunctions('VerifySalesAmountOnShowMatrixPage')]
    [Scope('OnPrem')]
    procedure WorkDateGreaterThanDateFilterOnItemStatistic()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemStatistics: TestPage "Item Statistics";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        SalesAmount: Decimal;
    begin
        Initialize();
        // Setup. Create item.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);

        // Setup. Create and Post Item Journal.
        PostItemJournal(Item."No.", ItemJournalLine."Entry Type"::Sale, WorkDate());

        // Setup. Create and Post an Item Journal on next month.
        SalesAmount := PostItemJournal(Item."No.", ItemJournalLine."Entry Type"::Sale, CalcDate('<1M>', WorkDate()));
        LibraryVariableStorage.Enqueue(SalesAmount);

        // Setup. Open Item Statistics page and set Item and Date Filter.
        ItemStatistics.OpenEdit();
        ItemStatistics.ItemFilter.SetValue(Item."No.");
        ItemStatistics.ViewBy.SetValue(PeriodType::Month);
        ItemStatistics.DateFilter.SetValue(StrSubstNo(DateFilterTok, CalcDate('<-CM>', WorkDate()), CalcDate('<CM+1M>', WorkDate())));

        // Exercise.
        ItemStatistics.ShowMatrix.Invoke();

        // Verify: Verify Values on Item Matrix by ShowMatrixPageHandler.
    end;

    local procedure PostItemJournal(ItemNo: Code[20]; ItemJournalLineEntryType: Enum "Item Ledger Document Type"; PostingDate: Date): Decimal
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup. Find Journal Batch
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();

        // Setup. Create Item Journal Line and Store the Sales Amount.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLineEntryType, ItemNo,
          LibraryRandom.RandInt(5));
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);

        // Setup. Post Item Journal Line
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(ItemJournalLine.Amount);
    end;

    local procedure PostPaymentWithEarlierDateToVendor(DocumentTypeForPurchaseJournal: Enum "Gen. Journal Document Type"; DocumentTypeForPaymentJournal: Enum "Gen. Journal Document Type")
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLineForPayment: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        Vendor: Record Vendor;
    begin
        // Setup: Post Purchase Journal and Update Applies Doc No. on Payment Journal.
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        CreateVendorWithPaymentTermsCode(Vendor);
        CreateJournalLine(GenJournalLine, Vendor."Gen. Bus. Posting Group", DocumentTypeForPurchaseJournal,
          GenJournalLine."Gen. Posting Type"::Purchase, GenJournalTemplate.Type::Purchases,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", -1 * CreateAmount(DocumentTypeForPurchaseJournal));
        UpdateAdjustForPaymentDiscountOnVATPostingSetup(GenJournalLine, true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindBankAccount(BankAccount);
        CreateJournalLineWithAppliesToDocNo(GenJournalLineForPayment, GenJournalTemplate.Type::Payments,
          DocumentTypeForPaymentJournal, GenJournalLine."Document Type", GenJournalLine."Bal. Account Type"::Vendor,
          GenJournalLine."Document No.");
        GenJournalLineForPayment.Validate("Bal. Account No.", Vendor."No.");

        // Exercise: Validate "Applies-to Doc. No." on Payment Journal Line.
        asserterror GenJournalLineForPayment.Validate("Applies-to Doc. No.", GenJournalLine."Document No.");

        // Verify: Verify Error raised on General Journal Line Validation.
        Assert.ExpectedError(JournalLineErr);

        // Tear down.
        UpdateAdjustForPaymentDiscountOnVATPostingSetup(GenJournalLine, false);
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPage')]
    [Scope('OnPrem')]
    procedure SalesDocumentDimTestReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check Sales Document - Test Report when Sales Order is Created and Shipped with Dimensions
        Initialize();

        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        LibrarySales.PostSalesDocument(SalesHeader, true, false); // Ship

        RunSalesDocumentTestReport(SalesHeader."Document Type"::Order, SalesHeader."No.");

        VerifySalesDocumentTestReportHasNoErrors();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeCustWithLocaltionCodeOnSalesOrderWithBlankLine()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Location: Record Location;
    begin
        // [SCENARIO 360231] Verify that location code can be updated in sales order with blank line.

        // [GIVEN] Sales Order with blank line
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        CreateSalesOrderWithBlankLine(SalesHeader);
        LibraryWarehouse.CreateLocation(Location);
        // [GIVEN] Customer A with location code X
        LibrarySales.CreateCustomerWithLocationCode(Customer, Location.Code);
        SalesHeader.SetHideValidationDialog(true);

        // [WHEN] Set Customer A as "Sell-To Customer No."
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");

        // [THEN] Location code on the header is X
        Assert.AreEqual(Customer."Location Code", SalesHeader."Location Code", UnexpectedLocationCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeVendWithLocaltionCodeOnPurchOrderWithBlankLine()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        Location: Record Location;
    begin
        // [SCENARIO 360231] Verify that location code can be updated in purchase order with blank line.

        // [GIVEN] Purchase Order with blank line
        Initialize();
        CreatePurchOrderWithBlankLine(PurchHeader);
        LibraryWarehouse.CreateLocation(Location);
        // [GIVEN] Vendor A with location code X
        LibraryPurchase.CreateVendorWithLocationCode(Vendor, Location.Code);
        PurchHeader.SetHideValidationDialog(true);

        // [WHEN] Set Vendor A as "Buy-from Vendor No."
        PurchHeader.Validate("Buy-from Vendor No.", Vendor."No.");

        // [THEN] Location code on the header is X
        Assert.AreEqual(Vendor."Location Code", PurchHeader."Location Code", UnexpectedLocationCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceAfterValidatingReturnReasonCode()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Sales] [Return Reason]
        // [SCENARIO 375645] Validating Return Reason Code with Inventory Value Zero in Sales Line should not reset Unit Price
        Initialize();

        // [GIVEN] Sales Line with Unit Price = "Y"
        // [GIVEN] Return Reason Code "X" with Inventory Value Zero = TRUE
        CreateSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");
        UnitPrice := SalesLine."Unit Price";

        // [WHEN] Validate Return Reason Code in Sales Line to "X"
        SalesLine.Validate("Return Reason Code", SetupReturnReasonCode(true));

        // [THEN] Unit Price in Sales Line remains "Y"
        SalesLine.TestField("Unit Price", UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivePurchaseOrderNotAllowedPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 378711] "Receive" and "Invoice" fields remain unchanged when purchase order cannot be received due to "Posting Date" is out of allowed posting date range.

        // [GIVEN] GLSetup."Allow Posting From" = 01/01/2016
        // [GIVEN] GLSetup."Allow Posting To" = 31/01/2016
        Initialize();
        UpdateAllowedPostingDateInGLSetup(WorkDate() - 10, WorkDate() - 1);

        // [GIVEN] Purchase order "PO" with "Posting Date" = 21/02/2016, "Receive" = FALSE, "Invoice" = FALSE
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);
        Commit();

        // [WHEN] Post "PO" as receipt
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] "Posting Date is not within your range of allowed posting dates." error thrown
        PurchaseHeader.Find();
        Assert.ExpectedError(PostingDateNotAllowedErr);

        // [THEN] "PO".Receive = FALSE
        PurchaseHeader.TestField(Receive, false);
        // [THEN] "PO".Invoice = FALSE
        PurchaseHeader.TestField(Invoice, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicePurchaseReceiptNotAllowedPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 378711] "Receive" and "Invoice" fields remain unchanged when purchase receipt cannot be invoiced due to "Posting Date" is out of allowed posting date range.

        // [GIVEN] GLSetup."Allow Posting From" = 01/01/2016
        // [GIVEN] GLSetup."Allow Posting To" = 31/01/2016
        Initialize();
        UpdateAllowedPostingDateInGLSetup(WorkDate() - 10, WorkDate() + 10);

        // [GIVEN] Purchase order "PO" posted as receipt with "Posting Date" = 21/01/2016, "Receive" = TRUE, "Invoice" = FALSE
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);
        Commit();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        PurchaseHeader.Find();
        PurchaseHeader.TestField(Receive, true);
        PurchaseHeader.TestField(Invoice, false);

        // [GIVEN] "PO"."Posting Date" changed to 01/02/2016
        PurchaseHeader.Validate("Posting Date", WorkDate() + 11);
        PurchaseHeader.Modify(true);
        Commit();

        // [WHEN] Post "PO" as invoice
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] "Posting Date is not within your range of allowed posting dates." error thrown
        PurchaseHeader.Find();
        Assert.ExpectedError(PostingDateNotAllowedErr);

        // [THEN] "PO".Receive = TRUE
        PurchaseHeader.TestField(Receive, true);
        // [THEN] "PO".Invoice = FALSE
        PurchaseHeader.TestField(Invoice, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipSalesOrderNotAllowedPostingDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378711] "Ship" and "Invoice" fields remain unchanged when sales order cannot be shipped due to "Posting Date" is out of allowed posting date range.

        // [GIVEN] GLSetup."Allow Posting From" = 01/01/2016
        // [GIVEN] GLSetup."Allow Posting To" = 31/01/2016
        Initialize();
        UpdateAllowedPostingDateInGLSetup(WorkDate() - 10, WorkDate() - 1);

        // [GIVEN] Sales order "SO" with "Posting Date" = 21/02/2016, "Ship" = FALSE, "Invoice" = FALSE
        CreateSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        Commit();

        // [WHEN] Post "SO" as shipment
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] "Posting Date is not within your range of allowed posting dates." error thrown
        SalesHeader.Find();
        Assert.ExpectedError(PostingDateNotAllowedErr);

        // [THEN] "SO".Shipment = FALSE
        SalesHeader.TestField(Ship, false);
        // [THEN] "SO".Invoice = FALSE
        SalesHeader.TestField(Invoice, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceSalesShipmentNotAllowedPostingDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378711] "Ship" and "Invoice" fields remain unchanged when sales shipment cannot be invoiced due to "Posting Date" is out of allowed posting date range.

        // [GIVEN] GLSetup."Allow Posting From" = 01/01/2016
        // [GIVEN] GLSetup."Allow Posting To" = 31/01/2016
        Initialize();
        UpdateAllowedPostingDateInGLSetup(WorkDate() - 10, WorkDate() + 10);

        // [GIVEN] Sals order "SO" posted as shipment with "Posting Date" = 21/01/2016, "Ship" = TRUE, "Invoice" = FALSE
        CreateSalesOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        Commit();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        SalesHeader.Find();
        SalesHeader.TestField(Ship, true);
        SalesHeader.TestField(Invoice, false);

        // [GIVEN] "SO"."Posting Date" changed to 01/02/2016
        SalesHeader.Validate("Posting Date", WorkDate() + 11);
        SalesHeader.Modify(true);
        Commit();

        // [WHEN] Post "SO" as invoice
        asserterror LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] "Posting Date is not within your range of allowed posting dates." error thrown
        SalesHeader.Find();
        Assert.ExpectedError(PostingDateNotAllowedErr);

        // [THEN] "SO".Shipment = TRUE
        SalesHeader.TestField(Ship, true);
        // [THEN] "SO".Invoice = FALSE
        SalesHeader.TestField(Invoice, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendToPostBlankSalesHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 379956] Throw error "There is nothing to post" without intermediate confirmations when send to post blank Sales Header
        SalesHeader.Init();

        asserterror CODEUNIT.Run(CODEUNIT::"Sales-Post (Yes/No)", SalesHeader);

        Assert.ExpectedError('There is nothing to post');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendToPostBlankPurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 379956] Throw error "There is nothing to post" without intermediate confirmations when send to post blank Purchase Header
        PurchaseHeader.Init();

        asserterror CODEUNIT.Run(CODEUNIT::"Purch.-Post (Yes/No)", PurchaseHeader);

        Assert.ExpectedError('There is nothing to post');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckShippingAdviseDoNotCheckNonItemLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CodeCoverage: Record "Code Coverage";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
    begin
        // [FEATURE] [Shipping Advise] [UT]
        // [SCENARIO 255530] TAB36.CheckShippingAdvise ignores non-item lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLinesAllTypes(SalesLine, SalesHeader);

        Commit();

        CodeCoverageMgt.StartApplicationCoverage();
        SalesHeader.CheckShippingAdvice();
        CodeCoverageMgt.StopApplicationCoverage();
        Assert.AreEqual(
          1,
          CodeCoverageMgt.GetNoOfHitsCoverageForObject(CodeCoverage."Object Type"::Table, DATABASE::"Sales Header", ItemGETTok),
          StrSubstNo('%1 must be called once', ItemGETTok));

        SalesLine."Qty. Shipped (Base)" := LibraryRandom.RandIntInRange(2, 5);
        SalesLine.Modify();

        Commit();
        asserterror SalesHeader.CheckShippingAdvice();
        Assert.ExpectedError(NonCopleteOrderErr);

        SalesLine.Delete(true);

        CodeCoverageMgt.StartApplicationCoverage();
        SalesHeader.CheckShippingAdvice();
        CodeCoverageMgt.StopApplicationCoverage();
        Assert.AreEqual(
          0,
          CodeCoverageMgt.GetNoOfHitsCoverageForObject(CodeCoverage."Object Type"::Table, DATABASE::"Sales Line", ItemGETTok),
          StrSubstNo('%1 must not be called', ItemGETTok));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderAfterFixedNoSeriesInPurchaseSetup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        // [FEATURE] [No. Series] [Purchase] [Return Order]
        // [SCENARIO 363508] Stan can post Purchase Return Order with blank posting no. series fields when he updated no. series in purchase setup
        Initialize();
        ResetPostingNoSeriesOnPurchaseSetup();

        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);
        Commit();

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(PurchaseHeader.FieldCaption("Return Shipment No. Series"));

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Return Shpt. Nos.", CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify();
        Commit();

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(PurchaseHeader.FieldCaption("Posting No. Series"));

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Credit Memo Nos.", CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify();
        Commit();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        ReturnShipmentHeader.SetRange("No.", GetLastNoUsedFromNoSeries(PurchasesPayablesSetup."Posted Return Shpt. Nos."));
        Assert.RecordCount(ReturnShipmentHeader, 1);

        PurchCrMemoHdr.SetRange("No.", GetLastNoUsedFromNoSeries(PurchasesPayablesSetup."Posted Credit Memo Nos."));
        Assert.RecordCount(PurchCrMemoHdr, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderAfterFixedNoSeriesInPurchaseSetup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        // [FEATURE] [No. Series] [Purchase] [Order]
        // [SCENARIO 363508] Stan can post Purchase Order with blank posting no. series fields when he updated no. series in purchase setup
        Initialize();
        ResetPostingNoSeriesOnPurchaseSetup();

        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        Commit();

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(PurchaseHeader.FieldCaption("Receiving No. Series"));

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify();
        Commit();

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(PurchaseHeader.FieldCaption("Posting No. Series"));

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify();
        Commit();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptHeader.SetRange("No.", GetLastNoUsedFromNoSeries(PurchasesPayablesSetup."Posted Receipt Nos."));
        Assert.RecordCount(PurchRcptHeader, 1);

        PurchInvHeader.SetRange("No.", GetLastNoUsedFromNoSeries(PurchasesPayablesSetup."Posted Invoice Nos."));
        Assert.RecordCount(PurchInvHeader, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceAfterFixedNoSeriesInPurchaseSetup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [No. Series] [Purchase] [Invoice]
        // [SCENARIO 363508] Stan can post Purchase Invoice with blank posting no. series fields when he updated no. series in purchase setup
        Initialize();
        ResetPostingNoSeriesOnPurchaseSetup();

        asserterror LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        Assert.ExpectedError(PurchasesPayablesSetup.FieldCaption("Posted Invoice Nos."));

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify();
        Commit();

        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        Commit();
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(PurchaseHeader.FieldCaption("Receiving No. Series"));

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify();
        Commit();

        // Previously set Posting No. is not rolled back but, No. Series Last Used No. is so the test will fail unless we re-get the no.
        PurchaseHeader."Posting No." := '';

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.SetRange("No.", GetLastNoUsedFromNoSeries(PurchasesPayablesSetup."Posted Invoice Nos."));
        Assert.RecordCount(PurchInvHeader, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoAfterFixedNoSeriesInPurchaseSetup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [No. Series] [Purchase] [Credit Memo]
        // [SCENARIO 363508] Stan can post Purchase Credit Memo with blank posting no. series fields when he updated no. series in purchase setup
        Initialize();
        ResetPostingNoSeriesOnPurchaseSetup();

        asserterror LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        Assert.ExpectedError(PurchasesPayablesSetup.FieldCaption("Posted Credit Memo Nos."));

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Credit Memo Nos.", CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify();
        Commit();

        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        Commit();

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(PurchaseHeader.FieldCaption("Return Shipment No. Series"));

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Return Shpt. Nos.", CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify();
        Commit();

        // need to reset Posting No. as it is not rolled back
        PurchaseHeader."Posting No." := '';

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchCrMemoHdr.SetRange("No.", GetLastNoUsedFromNoSeries(PurchasesPayablesSetup."Posted Credit Memo Nos."));
        Assert.RecordCount(PurchCrMemoHdr, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderAfterFixedNoSeriesInSalesSetup()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        // [FEATURE] [No. Series] [Sales] [Return Order]
        // [SCENARIO 363508] Stan can post Sales Return Order with blank posting no. series fields when he updated no. series in sales setup
        Initialize();
        ResetPostingNoSeriesOnSalesSetup();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        Commit();

        asserterror PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(SalesHeader.FieldCaption("Return Receipt No. Series"));

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Return Receipt Nos.", CreateNoSeriesCode());
        SalesReceivablesSetup.Modify();
        Commit();

        asserterror PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(SalesHeader.FieldCaption("Posting No. Series"));

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Credit Memo Nos.", CreateNoSeriesCode());
        SalesReceivablesSetup.Modify();
        Commit();

        PostSalesDocument(SalesHeader, true, true);

        ReturnReceiptHeader.SetRange("No.", GetLastNoUsedFromNoSeries(SalesReceivablesSetup."Posted Return Receipt Nos."));
        Assert.RecordCount(ReturnReceiptHeader, 1);

        SalesCrMemoHeader.SetRange("No.", GetLastNoUsedFromNoSeries(SalesReceivablesSetup."Posted Credit Memo Nos."));
        Assert.RecordCount(SalesCrMemoHeader, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderAfterFixedNoSeriesInSalesSetup()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [FEATURE] [No. Series] [Sales] [Order]
        // [SCENARIO 363508] Stan can post Sales Order with blank posting no. series fields when he updated no. series in sales setup
        Initialize();
        ResetPostingNoSeriesOnSalesSetup();

        LibrarySales.CreateSalesOrder(SalesHeader);
        Commit();

        asserterror PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(SalesHeader.FieldCaption("Shipping No. Series"));

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Shipment Nos.", CreateNoSeriesCode());
        SalesReceivablesSetup.Modify();
        Commit();

        asserterror PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(SalesHeader.FieldCaption("Posting No. Series"));

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", CreateNoSeriesCode());
        SalesReceivablesSetup.Modify();
        Commit();

        PostSalesDocument(SalesHeader, true, true);

        SalesShipmentHeader.SetRange("No.", GetLastNoUsedFromNoSeries(SalesReceivablesSetup."Posted Shipment Nos."));
        Assert.RecordCount(SalesShipmentHeader, 1);

        SalesInvoiceHeader.SetRange("No.", GetLastNoUsedFromNoSeries(SalesReceivablesSetup."Posted Invoice Nos."));
        Assert.RecordCount(SalesInvoiceHeader, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceAfterFixedNoSeriesInSalesSetup()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [No. Series] [Sales] [Invoice]
        // [SCENARIO 363508] Stan can post Sales Invoice with blank posting no. series fields when he updated no. series in sales setup
        Initialize();
        ResetPostingNoSeriesOnSalesSetup();

        asserterror LibrarySales.CreateSalesInvoice(SalesHeader);
        Assert.ExpectedError(SalesReceivablesSetup.FieldCaption("Posted Invoice Nos."));

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", CreateNoSeriesCode());
        SalesReceivablesSetup.Modify();
        Commit();

        LibrarySales.CreateSalesInvoice(SalesHeader);
        Commit();

        asserterror PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(SalesHeader.FieldCaption("Shipping No. Series"));

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Shipment Nos.", CreateNoSeriesCode());
        SalesReceivablesSetup.Modify();
        Commit();

        PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("No.", GetLastNoUsedFromNoSeries(SalesReceivablesSetup."Posted Invoice Nos."));
        Assert.RecordCount(SalesInvoiceHeader, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoAfterFixedNoSeriesInSalesSetup()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [No. Series] [Sales] [Credit Memo]
        // [SCENARIO 363508] Stan can post Sales Credit Memo with blank posting no. series fields when he updated no. series in sales setup
        Initialize();
        ResetPostingNoSeriesOnSalesSetup();

        asserterror LibrarySales.CreateSalesCreditMemo(SalesHeader);
        Assert.ExpectedError(SalesReceivablesSetup.FieldCaption("Posted Credit Memo Nos."));

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Credit Memo Nos.", CreateNoSeriesCode());
        SalesReceivablesSetup.Modify();
        Commit();

        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        Commit();

        asserterror PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(SalesHeader.FieldCaption("Return Receipt No. Series"));

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Return Receipt Nos.", CreateNoSeriesCode());
        SalesReceivablesSetup.Modify();
        Commit();

        PostSalesDocument(SalesHeader, true, true);

        SalesCrMemoHeader.SetRange("No.", GetLastNoUsedFromNoSeries(SalesReceivablesSetup."Posted Credit Memo Nos."));
        Assert.RecordCount(SalesCrMemoHeader, 1);
    end;

    [Test]
    procedure PostPurchaseCreditMemoManualNoSeries()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        NoSeriesCode: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [No. Series] [Purchase] [Credit Memo]
        // [SCENARIO 368758] Stan can post Purchase Credit Memo with No. Series having "Default Nos." = false and "Manual Nos." = true
        Initialize();
        ResetPostingNoSeriesOnPurchaseSetup();

        DocumentNo := LibraryUtility.GenerateGUID() + '-ABC';
        PurchCrMemoHdr.SetRange("No.", DocumentNo);
        Assert.RecordCount(PurchCrMemoHdr, 0);

        NoSeriesCode := CreateNoSeriesCode();
        UpdateNoSeries(NoSeriesCode, false, true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Credit Memo Nos.", NoSeriesCode);
        PurchasesPayablesSetup.Validate("Posted Credit Memo Nos.", NoSeriesCode);
        PurchasesPayablesSetup.Validate("Posted Return Shpt. Nos.", CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Validate("No.", DocumentNo);
        PurchaseHeader.Insert(true);

        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.RecordCount(PurchCrMemoHdr, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoManualNoSeries()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NoSeriesCode: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [No. Series] [Sales] [Credit Memo]
        // [SCENARIO 368758] Stan can post Sales Credit Memo with No. Series having "Default Nos." = false and "Manual Nos." = true
        Initialize();
        ResetPostingNoSeriesOnSalesSetup();

        DocumentNo := LibraryUtility.GenerateGUID() + '-ABC';
        SalesCrMemoHeader.SetRange("No.", DocumentNo);
        Assert.RecordCount(SalesCrMemoHeader, 0);

        NoSeriesCode := CreateNoSeriesCode();
        UpdateNoSeries(NoSeriesCode, false, true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Memo Nos.", NoSeriesCode);
        SalesReceivablesSetup.Validate("Posted Credit Memo Nos.", NoSeriesCode);
        SalesReceivablesSetup.Validate("Posted Return Receipt Nos.", CreateNoSeriesCode());
        SalesReceivablesSetup.Modify();

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Validate("No.", DocumentNo);
        SalesHeader.Insert(true);

        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);

        SalesHeader.Validate(Ship, true);
        SalesHeader.Validate(Receive, true);
        SalesHeader.Validate(Invoice, true);
        Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);

        Assert.RecordCount(SalesCrMemoHeader, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanChangeRequestedReceiptDateOnReleasedPurchOrderHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NewDate: Date;
    begin
        // [FEATURE] [Purchase] [Order] [Release Document] [UT]
        // [SCENARIO 362133] Stan can change "Requested Receipt Date" on released purchase order.
        Initialize();
        NewDate := LibraryRandom.RandDateFromInRange(WorkDate(), 20, 40);

        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        PurchaseHeader.Validate("Requested Receipt Date", NewDate);
        PurchaseHeader.Modify(true);

        PurchaseHeader.TestField("Requested Receipt Date", NewDate);
        PurchaseLine.Find();
        PurchaseLine.TestField("Requested Receipt Date", NewDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanChangeLeadTimeCalculationOnReleasedPurchOrderHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LeadTimeCalculation: DateFormula;
    begin
        // [FEATURE] [Purchase] [Order] [Release Document] [UT]
        // [SCENARIO 362133] Stan can change "Lead Time Calculation" on released purchase order.
        Initialize();
        Evaluate(LeadTimeCalculation, StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(20, 40)));

        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        PurchaseHeader.Validate("Lead Time Calculation", LeadTimeCalculation);
        PurchaseHeader.Modify(true);

        PurchaseHeader.TestField("Lead Time Calculation", LeadTimeCalculation);
        PurchaseLine.Find();
        PurchaseLine.TestField("Lead Time Calculation", LeadTimeCalculation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanChangeInboundWhseHandlingTimeOnReleasedPurchOrderHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InboundWhseHandlingTime: DateFormula;
    begin
        // [FEATURE] [Purchase] [Order] [Release Document] [UT]
        // [SCENARIO 362133] Stan can change "Inbound Whse. Handling Time" on released purchase order.
        Initialize();
        Evaluate(InboundWhseHandlingTime, StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(20, 40)));

        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        PurchaseHeader.Validate("Inbound Whse. Handling Time", InboundWhseHandlingTime);
        PurchaseHeader.Modify(true);

        PurchaseHeader.TestField("Inbound Whse. Handling Time", InboundWhseHandlingTime);
        PurchaseLine.Find();
        PurchaseLine.TestField("Inbound Whse. Handling Time", InboundWhseHandlingTime);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CanChangeOrderDateOnReleasedPurchOrderHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NewDate: Date;
    begin
        // [FEATURE] [Purchase] [Order] [Release Document] [UT]
        // [SCENARIO 362133] Stan can change "Order Date" on released purchase order.
        Initialize();
        NewDate := LibraryRandom.RandDateFromInRange(WorkDate(), 20, 40);

        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        PurchaseHeader.Validate("Order Date", NewDate);
        PurchaseHeader.Modify(true);

        PurchaseHeader.TestField("Order Date", NewDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanChangeRequestedReceiptDateOnReleasedPurchOrderLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NewDate: Date;
    begin
        // [FEATURE] [Purchase] [Order] [Release Document] [UT]
        // [SCENARIO 362133] Stan can change "Requested Receipt Date" on released purchase order line.
        Initialize();
        NewDate := LibraryRandom.RandDateFromInRange(WorkDate(), 20, 40);

        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        PurchaseLine.Validate("Requested Receipt Date", NewDate);

        PurchaseLine.TestField("Requested Receipt Date", NewDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanChangeLeadTimeCalculationOnReleasedPurchOrderLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LeadTimeCalculation: DateFormula;
    begin
        // [FEATURE] [Purchase] [Order] [Release Document] [UT]
        // [SCENARIO 362133] Stan can change "Lead Time Calculation" on released purchase order line.
        Initialize();
        Evaluate(LeadTimeCalculation, StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(20, 40)));

        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        PurchaseLine.Validate("Lead Time Calculation", LeadTimeCalculation);

        PurchaseLine.TestField("Lead Time Calculation", LeadTimeCalculation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanChangeInboundWhseHandlingTimeOnReleasedPurchOrderLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InboundWhseHandlingTime: DateFormula;
    begin
        // [FEATURE] [Purchase] [Order] [Release Document] [UT]
        // [SCENARIO 362133] Stan can change "Inbound Whse. Handling Time" on released purchase order line.
        Initialize();
        Evaluate(InboundWhseHandlingTime, StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(20, 40)));

        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        PurchaseLine.Validate("Inbound Whse. Handling Time", InboundWhseHandlingTime);

        PurchaseLine.TestField("Inbound Whse. Handling Time", InboundWhseHandlingTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanChangeOrderDateOnReleasedPurchOrderLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NewDate: Date;
    begin
        // [FEATURE] [Purchase] [Order] [Release Document] [UT]
        // [SCENARIO 362133] Stan can change "Order Date" on released purchase order line.
        Initialize();
        NewDate := LibraryRandom.RandDateFromInRange(WorkDate(), 20, 40);

        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        PurchaseLine.Validate("Order Date", NewDate);

        PurchaseLine.TestField("Order Date", NewDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanChangePlannedReceiptDateOnReleasedPurchOrderLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NewDate: Date;
    begin
        // [FEATURE] [Purchase] [Order] [Release Document] [UT]
        // [SCENARIO 362133] Stan can change "Planned Receipt Date" on released purchase order line.
        Initialize();
        NewDate := LibraryRandom.RandDateFromInRange(WorkDate(), 20, 40);

        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        PurchaseLine.Validate("Planned Receipt Date", NewDate);

        PurchaseLine.TestField("Planned Receipt Date", NewDate);
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostCorrectiveCreditMemoWithDefaultNoSetToFalseOnNoSeries()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        SalesRecvSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO 448855] Hole in the Numbering of Sales Credit Memos
        Initialize();

        // [GIVEN] Create  and Post sales Invoice
        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvHeader);

        // [GIVEN] Create No. Series "Y" with "Default Nos" = No and no. series line setup
        LibraryUtility.CreateNoSeries(NoSeries, false, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        // [GIVEN] Update No. series on Sales Setup and "Journal Templ. Name Mandatory" is false on GL Setup 
        SalesRecvSetup.Get();
        SalesRecvSetup."Posted Credit Memo Nos." := NoSeries.Code;
        SalesRecvSetup.Modify();
        GLSetup.Get();
        GLSetup."Journal Templ. Name Mandatory" := false;
        GLSetup.Modify();

        // [THEN] Create Corrective Credit memo 
        ErrorMessages.Trap();
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GotoRecord(SalesInvHeader);
        PostedSalesInvoice.CreateCreditMemo.Invoke();

        // [VERIFY] Verify Posting No series Error
        ErrorMessages.First();
        SalesHeader.SetRange("Sell-to Customer No.", Cust."No.");
        SalesHeader.FindFirst();
        Assert.IsSubstring(ErrorMessages.Description.Value, NoSeries.Code);

        // [VERIFY] Verify No Sales Credit memo has been posted.
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", Cust."No.");
        Assert.RecordIsEmpty(SalesCrMemoHeader);
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPurchCorrectiveCrMemoWithDefaultNoSetToFalseOnNoSeriesAndThrowError()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO 480238] Hole in the Numbering of Purchase Credit Memos
        Initialize();

        // [GIVEN] Create and Post Purchase Invoice
        CreateAndPostPurchaseInvForNewItemAndVend(Item, Vendor, 1, 1, PurchInvHeader);

        // [GIVEN] Create No. Series with Default Nos set to false.
        LibraryUtility.CreateNoSeries(NoSeries, false, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        // [GIVEN] Update No. series on Purchase & Payables Setup.
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Posted Credit Memo Nos." := NoSeries.Code;
        PurchasesPayablesSetup.Modify();

        // [GIVEN] Set Journal Templ. Name Mandatory to false on General ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Journal Templ. Name Mandatory" := false;
        GeneralLedgerSetup.Modify();

        // [THEN] Find Posted Purchase Invoice & Create Corrective Credit Memo.
        ErrorMessages.Trap();
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        PostedPurchaseInvoice.CreateCreditMemo.Invoke();

        // [VERIFY] Verify Posting No series Error.
        ErrorMessages.First();
        Assert.IsSubstring(ErrorMessages.Description.Value, NoSeries.Code);

        // [VERIFY] Verify Purchase Credit Memo is not posted.
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", Vendor."No.");
        Assert.RecordIsEmpty(PurchCrMemoHdr);
    end;

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        NoSeriesNumbersPrefix := IncStr(NoSeriesNumbersPrefix);
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales/Purch Status Error");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales/Purch Status Error");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveSalesSetup();
        IsInitialized := true;
        NoSeriesNumbersPrefix := '001';
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales/Purch Status Error");
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    begin
        CreateSalesOrder(SalesHeader, SalesLine, DocumentType);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, DocumentType);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    begin
        // Using Random Value for Quantity and Unit Price in Sales Line.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Validate("Line Discount %", 0);  // Keep Line Discount % Zero.
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithBlankLine(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        RecRef.GetTable(SalesLine);
        SalesLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No.")));
        SalesLine.Insert(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    begin
        // Using Random Value for Quantity and Direct Unit Cost in Purchase Line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchOrderWithBlankLine(var PurchHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        PurchLine: Record "Purchase Line";
        RecRef: RecordRef;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, Vendor."No.");
        PurchLine.Init();
        PurchLine.Validate("Document Type", PurchHeader."Document Type");
        PurchLine.Validate("Document No.", PurchHeader."No.");
        RecRef.GetTable(PurchLine);
        PurchLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PurchLine.FieldNo("Line No.")));
        PurchLine.Insert(true);
    end;

    local procedure CreateSalesDocumentWithFCY(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        Currency: Record Currency;
        SalesLine: Record "Sales Line";
    begin
        // Using Random Value for Quantity in Sales Line.
        LibraryERM.FindCurrency(Currency);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        SalesHeader.Validate("Currency Code", Currency.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreatePurchaseDocumentFCY(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Sales Document Type")
    var
        Currency: Record Currency;
        PurchaseLine: Record "Purchase Line";
    begin
        // Using Random Value for Quantity in Purchase Line.
        LibraryERM.FindCurrency(Currency);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor());
        PurchaseHeader.Validate("Currency Code", Currency.Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        CreateCustDefaultDimension(Customer."No.");
        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Last Direct Cost", Item."Unit Cost");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithCostingMethodStandard(): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItem());
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCustomerWithPaymentTermsCode(var Customer: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        Customer.Get(CreateCustomer());
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
    end;

    local procedure CreateVendorWithPaymentTermsCode(var Vendor: Record Vendor)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        Vendor.Get(CreateVendor());
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateGeneralJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template"; Type: Enum "Gen. Journal Template Type")
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, Type);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenBusinessPostingGroup: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type";
                                                                                                                                           GenJournalTemplateType: Enum "Gen. Journal Template Type";
                                                                                                                                           AccountType: Enum "Gen. Journal Account Type";
                                                                                                                                           AccountNo: Code[20];
                                                                                                                                           Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateGeneralJournalTemplate(GenJournalTemplate, GenJournalTemplateType);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccount(GenBusinessPostingGroup, GenPostingType));
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenPostingType);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateJournalLineWithAppliesToDocNo(var GenJournalLine: Record "Gen. Journal Line"; GenJournalTemplateType: Enum "Gen. Journal Template Type"; DocumentType: Enum "Gen. Journal Document Type";
                                                                                                                                    AppliesToDocumentType: Enum "Gen. Journal Document Type";
                                                                                                                                    BalAccountType: Enum "Gen. Journal Account Type";
                                                                                                                                    DocumentNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindBankAccount(BankAccount);
        CreateGeneralJournalTemplate(GenJournalTemplate, GenJournalTemplateType);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::"Bank Account", BankAccount."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", CalcDate(StrSubstNo('<-%1D>', LibraryRandom.RandInt(10)), WorkDate()));
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocumentType);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAmount(DocumentType: Enum "Gen. Journal Document Type"): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if GenJournalLine."Document Type"::Invoice = DocumentType then
            exit(LibraryRandom.RandDecInRange(1000, 2000, 2));
        exit(-1 * LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure CreateGLAccount(GenBusPostingGroup: Code[20]; GenPostingType: Enum "General Posting Type"): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        // TFS ID: 307158
        if GLAccount."Gen. Posting Type" = GLAccount."Gen. Posting Type"::Purchase then
            GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup())
        else
            GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        GLAccount.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        // required for NO
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateCustDefaultDimension(CustNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustNo, Dimension.Code, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify();
    end;

    local procedure CreateSalesLinesAllTypes(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        FixedAsset: Record "Fixed Asset";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::" ", '', 0);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandIntInRange(2, 5));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandIntInRange(2, 5));
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset",
          FixedAsset."No.", LibraryRandom.RandIntInRange(2, 5));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Resource,
          LibraryResource.CreateResourceNo(), LibraryRandom.RandIntInRange(2, 5));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(2, 5));
    end;

    local procedure GetItemCost(ItemNo: Code[20]): Decimal
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        exit(Item."Unit Cost");
    end;

    local procedure CreateNoSeriesCode(): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesCode: Code[20];
    begin
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.FindFirst();
        NoSeriesLine."Starting No." := StrSubstNo('%1-000000', NoSeriesNumbersPrefix);
        NoSeriesLine."Ending No." := StrSubstNo('%1-999999', NoSeriesNumbersPrefix);
        NoSeriesLine.Modify();
        exit(NoSeriesCode);
    end;

    local procedure UpdateNoSeries(NoSeriesCode: Code[20]; DefaultNos: Boolean; ManualNos: Boolean)
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(NoSeriesCode);
        NoSeries.Validate("Default Nos.", DefaultNos);
        NoSeries.TestField("Manual Nos.", ManualNos);
        NoSeries.Modify(true);
    end;

    local procedure GetLastNoUsedFromNoSeries(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.FindFirst();
        exit(NoSeriesLine."Last No. Used");
    end;

    local procedure PostSalesDocument(var SalesHeader: Record "Sales Header"; NewShipReceive: Boolean; NewInvoice: Boolean)
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesHeader.Validate(Ship, NewShipReceive);
        SalesHeader.Validate(Receive, NewShipReceive);
        SalesHeader.Validate(Invoice, NewInvoice);
        SalesPost.Run(SalesHeader)
    end;

    local procedure ResetPostingNoSeriesOnPurchaseSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Posted Invoice Nos." := '';
        PurchasesPayablesSetup."Posted Receipt Nos." := '';
        PurchasesPayablesSetup."Posted Return Shpt. Nos." := '';
        PurchasesPayablesSetup."Posted Credit Memo Nos." := '';
        PurchasesPayablesSetup."Return Shipment on Credit Memo" := true;
        PurchasesPayablesSetup."Receipt on Invoice" := true;
        PurchasesPayablesSetup.Modify();
        Commit();
    end;

    local procedure ResetPostingNoSeriesOnSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Posted Invoice Nos." := '';
        SalesReceivablesSetup."Posted Shipment Nos." := '';
        SalesReceivablesSetup."Posted Return Receipt Nos." := '';
        SalesReceivablesSetup."Posted Credit Memo Nos." := '';
        SalesReceivablesSetup."Return Receipt on Credit Memo" := true;
        SalesReceivablesSetup."Shipment on Invoice" := true;
        SalesReceivablesSetup.Modify();
        Commit();
    end;

    local procedure RunSalesDocumentTestReport(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesDocumentTest: Report "Sales Document - Test";
    begin
        Commit();
        Clear(SalesDocumentTest);
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("No.", DocumentNo);
        SalesDocumentTest.SetTableView(SalesHeader);
        SalesDocumentTest.Run();
    end;

    local procedure SetupAndCreateSalesDocument(var SalesHeader: Record "Sales Header"; var DefaultPostingDate: Enum "Default Posting Date"; DocumentType: Enum "Sales Document Type")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // Update Sales & Receivable Setup and Create Sales document.

        SalesReceivablesSetup.Get();
        UpdateSalesReceivableSetup(DefaultPostingDate, SalesReceivablesSetup."Default Posting Date"::"No Date");
        CreateSalesDocumentWithFCY(SalesHeader, DocumentType);
    end;

    local procedure SetupAndCreatePurchDocument(var PurchaseHeader: Record "Purchase Header"; var DefaultPostingDate: Enum "Default Posting Date"; DocumentType: Enum "Purchase Document Type")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Update Purchase & Payable Setup and Create Sales document.

        PurchasesPayablesSetup.Get();
        UpdatePurchasePayableSetup(DefaultPostingDate, PurchasesPayablesSetup."Default Posting Date"::"No Date");
        CreatePurchaseDocumentFCY(PurchaseHeader, DocumentType);
    end;

    local procedure SetupSalesPrepaymentInvNoSeries(): Code[20]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Prepmt. Inv. Nos.", LibraryERM.CreateNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
        exit(SalesReceivablesSetup."Posted Prepmt. Inv. Nos.");
    end;

    local procedure SetupPurchasePrepaymentInvNoSeries(): Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Prepmt. Inv. Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
        exit(PurchasesPayablesSetup."Posted Prepmt. Inv. Nos.");
    end;

    local procedure SetupSalesPrepaymentCrMemoNoSeries(): Code[20]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Prepmt. Cr. Memo Nos.", LibraryERM.CreateNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
        exit(SalesReceivablesSetup."Posted Prepmt. Cr. Memo Nos.");
    end;

    local procedure SetupPurchasePrepaymentCrMemoNoSeries(): Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Prepmt. Cr. Memo Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
        exit(PurchasesPayablesSetup."Posted Prepmt. Cr. Memo Nos.");
    end;

    local procedure SetupReturnReasonCode(InventoryValueZero: Boolean): Code[10]
    var
        ReturnReason: Record "Return Reason";
    begin
        LibraryERM.CreateReturnReasonCode(ReturnReason);
        ReturnReason."Inventory Value Zero" := InventoryValueZero;
        ReturnReason.Modify();
        exit(ReturnReason.Code);
    end;

    local procedure UpdateAdjustForPaymentDiscountOnVATPostingSetup(GenJournalLine: Record "Gen. Journal Line"; AdjustForPaymentDisc: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(GenJournalLine."Bal. VAT Bus. Posting Group", GenJournalLine."Bal. VAT Prod. Posting Group");
        VATPostingSetup.Validate("Adjust for Payment Discount", AdjustForPaymentDisc);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivableSetup(var OldDefaultPostingDate: Enum "Default Posting Date"; DefaultPostingDate: Enum "Default Posting Date")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldDefaultPostingDate := SalesReceivablesSetup."Default Posting Date";
        SalesReceivablesSetup.Validate("Default Posting Date", DefaultPostingDate);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePurchasePayableSetup(var OldDefaultPostingDate: Enum "Default Posting Date"; DefaultPostingDate: Enum "Default Posting Date")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldDefaultPostingDate := PurchasesPayablesSetup."Default Posting Date";
        PurchasesPayablesSetup.Validate("Default Posting Date", DefaultPostingDate);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateReturnReasonCodeOnSalesLine(var SalesLine: Record "Sales Line"; InventoryValueZero: Boolean)
    begin
        VerifySalesLineUnitCost(SalesLine, GetItemCost(SalesLine."No."));
        SalesLine.Validate("Return Reason Code", SetupReturnReasonCode(InventoryValueZero));
    end;

    local procedure UpdateReturnReasonCodeOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; InventoryValueZero: Boolean)
    begin
        VerifyPurchaseLineUnitCost(PurchaseLine, GetItemCost(PurchaseLine."No."));
        PurchaseLine.Validate("Return Reason Code", SetupReturnReasonCode(InventoryValueZero));
    end;

    local procedure UpdateAllowedPostingDateInGLSetup(FromDate: Date; ToDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Posting From" := FromDate;
        GeneralLedgerSetup."Allow Posting To" := ToDate;
        GeneralLedgerSetup.Modify();
    end;

    local procedure CreateAndPostSalesInvForNewItemAndCust(var Item: Record Item; var Cust: Record Customer; UnitPrice: Decimal; Qty: Decimal; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        CreateItemWithPrice(Item, UnitPrice);
        LibrarySales.CreateCustomer(Cust);
        SellItem(Cust, Item, Qty, SalesInvoiceHeader);
    end;

    local procedure CreateItemWithPrice(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := UnitPrice;
        Item.Modify();
    end;

    local procedure SellItem(SellToCust: Record Customer; Item: Record Item; Qty: Decimal; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesInvoiceForItem(SellToCust, Item, Qty, SalesHeader, SalesLine);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesInvoiceForItem(Cust: Record Customer; Item: Record Item; Qty: Decimal; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
    end;

    local procedure CreateAndPostPurchaseInvForNewItemAndVend(var Item: Record Item; var Vendor: Record Vendor; LastDirectCost: Decimal; Qty: Decimal; var PurchaseInvoiceHeader: Record "Purch. Inv. Header")
    begin
        CreateItemWithCost(Item, LastDirectCost);
        LibraryPurchase.CreateVendor(Vendor);
        BuyItem(Vendor, Item, Qty, PurchaseInvoiceHeader);
    end;

    local procedure CreateItemWithCost(var Item: Record Item; LastDirectCost: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Last Direct Cost" := LastDirectCost;
        Item.Modify();
    end;

    local procedure BuyItem(var Vendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseInvoiceForItem(Vendor, Item, Qty, PurchaseHeader, PurchaseLine);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchaseInvoiceForItem(Vendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShowMatrixPageHandler(var ItemStatisticsMatrix: TestPage "Item Statistics Matrix")
    begin
        ItemStatisticsMatrix.Amount.AssertEquals(0);
        ItemStatisticsMatrix.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifySalesAmountOnShowMatrixPage(var ItemStatisticsMatrix: TestPage "Item Statistics Matrix")
    var
        SalesAmount: Variant;
    begin
        // Verify the value displayed on Field is correctly.
        LibraryVariableStorage.Dequeue(SalesAmount);
        ItemStatisticsMatrix.Field2.AssertEquals(SalesAmount);
        ItemStatisticsMatrix.OK().Invoke();
    end;

    local procedure VerifySalesLineUnitCost(SalesLine: Record "Sales Line"; ExpectedValue: Decimal)
    begin
        Assert.AreEqual(
          ExpectedValue,
          SalesLine."Unit Cost (LCY)",
          StrSubstNo(FieldValueErr, SalesLine.FieldCaption("Unit Cost (LCY)"), SalesLine.TableCaption()));
    end;

    local procedure VerifyPurchaseLineUnitCost(PurchaseLine: Record "Purchase Line"; ExpectedValue: Decimal)
    begin
        Assert.AreEqual(
          ExpectedValue,
          PurchaseLine."Direct Unit Cost",
          StrSubstNo(FieldValueErr, PurchaseLine.FieldCaption("Direct Unit Cost"), PurchaseLine.TableCaption()));
    end;

    local procedure VerifySalesDocumentTestReportHasNoErrors()
    var
        i: Integer;
    begin
        LibraryReportDataset.LoadDataSetFile();
        for i := 1 to LibraryReportDataset.RowCount() do begin
            LibraryReportDataset.MoveToRow(i);
            Assert.IsFalse(LibraryReportDataset.CurrentRowHasElement('LineErrorCounter_Number'), SalesDocumentTestReportDimErr);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocumentTestRequestPage(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    begin
        SalesDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [PageHandler]
    procedure SalesCreditMemoPageHandler(var SalesCreditMemo: TestPage "Sales Credit Memo")
    begin
        SalesCreditMemo.Post.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    procedure PurchaseCreditMemoPageHandler(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    begin
        PurchaseCreditMemo."Vendor Cr. Memo No.".SetValue(LibraryRandom.RandInt(100));
        PurchaseCreditMemo.Post.Invoke();
    end;
}

