﻿codeunit 134908 "ERM VAT Serv. Charge"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Invoice Discount] [Service Charge] [VAT]
        IsInitialized := false;
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        AmountError: Label 'Amount must be %1 in %2.';
        ExpectedMessage: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        CannotChangePrepaidServiceChargeErr: Label 'You cannot change the line because it will affect service charges that are already invoiced as part of a prepayment.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderVATServiceCharge()
    var
        SalesHeader: Record "Sales Header";
        ServiceCharge: Integer;
    begin
        // Check Sales Line for Invoice Discount with VAT and Service Charge after Create and Release Sales Order with 1 Fix
        // Value for Invoice Discount.
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);
        ServiceCharge := CreateSalesOrderWithInvDisc(SalesHeader, 1);

        // Verify: Verify Invoice Discount on Sales Line.
        SalesHeader.CalcFields("Amount Including VAT");
        VerifySalesLine(SalesHeader."No.", ServiceCharge, SalesHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankSalesLineServiceCharge()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check that Sales Line not lead to Service charge Line after Create Sales Order and Change Unit Price.
        Initialize();
        CreateSalesOrderWithInvDisc(SalesHeader, -1);

        // Verify: Verify Sales Line.
        Assert.IsFalse(FindSalesLine(SalesLine, SalesHeader."No."), 'Sales Line must not exist.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderGLVATServiceCharge()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceCharge: Integer;
        VATAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check GL Entry for Invoice Discount with Modified VAT and Service Charge after Create and Release Sales Order with 1 Fix
        // Value for Invoice Discount.
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);
        ServiceCharge := CreateSalesOrderWithInvDisc(SalesHeader, 1);
        FindSalesLine(SalesLine, SalesHeader."No.");
        VATAmount := (ServiceCharge * SalesLine."VAT %") / 100;
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify GL Entry for VAT Amount.
        VerifyGLEntryForSales(DocumentNo, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCMVATWithServiceCharge()
    var
        PurchaseHeader: Record "Purchase Header";
        ServiceCharge: Integer;
    begin
        // Check Purchase Credit memo Line for Invoice Discount with modified VAT and Service Charge after Create
        // Purchase Credit memo with 1 Fix Value for Invoice Discount.
        Initialize();
        ServiceCharge := CreatePurchCreditMemoInvDisc(PurchaseHeader, 1);

        // Verify: Verify Purchase Line for VAT Amount.
        PurchaseHeader.CalcFields("Amount Including VAT");
        VerifyPurchaseLine(PurchaseHeader."No.", ServiceCharge, PurchaseHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankPurchLineServiceCharge()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check that Purchase Line not lead to Service charge Line after Create Purchase Order and Change Direct Unit Cost.
        Initialize();
        CreatePurchCreditMemoInvDisc(PurchaseHeader, -2);

        // Verify: Verify Purchase Line.
        Assert.IsFalse(FindPurchaseLine(PurchaseLine, PurchaseHeader."No."), 'Purchase Line must not exist');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchCMGLEntryVATServiceCharge()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceCharge: Integer;
        VATAmount: Decimal;
    begin
        // Check GL Entry for Invoice Discount and VAT Amount with Modified Service Charge after Create and Release Purchase Credit memo.
        Initialize();
        ServiceCharge := CreatePurchCreditMemoInvDisc(PurchaseHeader, 1);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        VATAmount := (ServiceCharge * PurchaseLine."VAT %") / 100;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExecuteUIHandler();

        // Verify: Verify GL Entry for Posted Purchase Credit memo.
        VerifyGLEntryForPurchase(PurchaseHeader."No.", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithPrepmtCreateLineWithServChargeLine()
    var
        SalesHeader: Record "Sales Header";
        ServiceCharge: Decimal;
    begin
        // [FEATURE] [Prepayment] [Sales]
        // [SCENARIO 278599] Service charge line is created with Prepayment % = 100 from Sales Order
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Prepayment Sales Order with 100 % with Amount = 1000 and Service Charge = 100
        ServiceCharge := LibraryRandom.RandDecInRange(10, 20, 2);
        CreateSalesOrderWithPrepaymentAndServiceCharge(SalesHeader, 100, ServiceCharge);

        // [WHEN] Calculate Invoice Discount
        LibrarySales.CalcSalesDiscount(SalesHeader);

        // [THEN] Service Charge line has Prepayment % = 100 and "Prepmt. Line Amount" = 100
        VerifyServChargeSalesLines(SalesHeader, SalesHeader."Prepayment %", ServiceCharge);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderUpdatePrepmtInServChargeLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceCharge: Decimal;
    begin
        // [FEATURE] [Prepayment] [Sales]
        // [SCENARIO 278599] Update Prepayment % in Service charge line
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Prepayment Sales Order with 0 % with Amount = 1000 and Service Charge = 100
        ServiceCharge := LibraryRandom.RandDecInRange(10, 20, 2);
        CreateSalesOrderWithPrepaymentAndServiceCharge(SalesHeader, 0, ServiceCharge);

        // [GIVEN] Calculate Invoice Discount
        LibrarySales.CalcSalesDiscount(SalesHeader);

        // [WHEN] Update Prepayment % in Service Charge Line to 50
        FindSalesLineWithType(SalesLine, SalesHeader, SalesLine.Type::"G/L Account");
        SalesLine.Validate("Prepayment %", LibraryRandom.RandIntInRange(50, 100));
        SalesLine.Modify(true);

        // [THEN] Service Charge line has Prepayment % = 50 and "Prepmt. Line Amount" = 50
        VerifyServChargeSalesLines(SalesHeader, SalesLine."Prepayment %", Round(ServiceCharge * SalesLine."Prepayment %" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithPrepmtResetPrepmtInServiceChargeLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Prepayment] [Sales]
        // [SCENARIO 278599] Reset Prepayment % in Service charge line to zero
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Prepayment Sales Order with 100 % with Amount = 1000 and Service Charge = 100
        CreateSalesOrderWithPrepaymentAndServiceCharge(SalesHeader, 100, LibraryRandom.RandDecInRange(10, 20, 2));

        // [GIVEN] Calculate Invoice Discount
        LibrarySales.CalcSalesDiscount(SalesHeader);

        // [WHEN] Reset Prepayment % in Service Charge Line to 0
        FindSalesLineWithType(SalesLine, SalesHeader, SalesLine.Type::"G/L Account");
        SalesLine.Validate("Prepayment %", 0);
        SalesLine.Modify(true);

        // [THEN] Service Charge line has Prepayment % = 0 and "Prepmt. Line Amount" = 0
        VerifyServChargeSalesLines(SalesHeader, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderPostWithFullPrepmtAndServChargeLine()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Prepayment] [Sales]
        // [SCENARIO 278599] Post Sales Order with Service charge line and Prepayment % = 100
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Prepayment Sales Order with 100 % with Amount = 1000 and Service Charge = 100
        CreateSalesOrderWithPrepaymentAndServiceCharge(SalesHeader, 100, LibraryRandom.RandDecInRange(10, 20, 2));
        LibrarySales.CalcSalesDiscount(SalesHeader);

        // [WHEN] Post Prepayment Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader));

        // [THEN] Prepayment Invoice is posted with Amount = 1100
        SalesHeader.CalcFields(Amount);
        SalesInvoiceHeader.CalcFields(Amount);
        SalesInvoiceHeader.TestField(Amount, SalesHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderPostWithPrepmtAndServChargeLine()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Prepayment] [Sales]
        // [SCENARIO 278599] Post Sales Order with Service charge line and Prepayment % = 50
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Prepayment Sales Order with 50 % with Amount = 1000 and Service Charge = 100
        CreateSalesOrderWithPrepaymentAndServiceCharge(
          SalesHeader, LibraryRandom.RandDecInRange(50, 100, 2), LibraryRandom.RandDecInRange(10, 20, 2));
        LibrarySales.CalcSalesDiscount(SalesHeader);
        // [WHEN] Post Prepayment Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader));

        // [THEN] Prepayment Invoice is posted with Amount = 5500
        SalesHeader.CalcFields(Amount);
        SalesInvoiceHeader.CalcFields(Amount);
        SalesInvoiceHeader.TestField(Amount, Round(SalesHeader.Amount * SalesHeader."Prepayment %" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithServChargeIsUpdatedWhenPrepmtPosted()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceCharge: Decimal;
        NewQuantity: Decimal;
    begin
        // [FEATURE] [Prepayment] [Sales]
        // [SCENARIO 278599] Update quantity on Sales Line when prepayment invoice is posted and service charge is not changed
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Prepayment Sales Order with 100 % with Amount = 1000 and Service Charge = 100
        ServiceCharge := LibraryRandom.RandDecInRange(10, 20, 2);
        CreateSalesOrderWithPrepaymentAndServiceCharge(SalesHeader, 100, ServiceCharge);
        LibrarySales.CalcSalesDiscount(SalesHeader);

        // [GIVEN] Post Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [WHEN] Update quantity in item line
        FindSalesLineWithType(SalesLine, SalesHeader, SalesLine.Type::Item);
        NewQuantity := SalesLine.Quantity * 2;
        SalesLine.Validate(Quantity, NewQuantity);
        SalesLine.Modify(true);
        LibrarySales.CalcSalesDiscount(SalesHeader);

        // [THEN] Quantity is updated in item line, service charge stays = 100
        SalesLine.TestField(Quantity, NewQuantity);
        FindSalesLineWithType(SalesLine, SalesHeader, SalesLine.Type::"G/L Account");
        SalesLine.TestField(Amount, ServiceCharge);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithServChargeChangedCannotBeUpdatedWhenPrepmtPosted()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceCharge: Decimal;
        NewQuantity: Decimal;
    begin
        // [FEATURE] [Prepayment] [Sales]
        // [SCENARIO 278599] Sales Line cannot be updated when prepayment invoice is posted and service charge is changed
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Prepayment Sales Order with 100 % with Amount = 1000 and Service Charge = 100 with Min Amount = 1000
        ServiceCharge := LibraryRandom.RandDecInRange(10, 20, 2);
        CreateSalesOrderWithPrepaymentAndServiceCharge(SalesHeader, 100, ServiceCharge);
        LibrarySales.CalcSalesDiscount(SalesHeader);
        SalesHeader.CalcFields(Amount);

        // [GIVEN] Service Charge = 50 with Min Amount = 1001
        CreateCustInvoiceDiscount(SalesHeader."Sell-to Customer No.", ServiceCharge / 2, SalesHeader.Amount + 1);

        // [GIVEN] Post Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [WHEN] Update quantity in item line
        FindSalesLineWithType(SalesLine, SalesHeader, SalesLine.Type::Item);
        NewQuantity := SalesLine.Quantity * 2;
        SalesLine.Validate(Quantity, NewQuantity);
        SalesLine.Modify(true);
        asserterror LibrarySales.CalcSalesDiscount(SalesHeader);

        // [THEN] Error raised that you cannot change the line because it affects on prepaid service charge
        Assert.ExpectedError(CannotChangePrepaidServiceChargeErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithPrepmtCreateLineWithServChargeLine()
    var
        PurchaseHeader: Record "Purchase Header";
        ServiceCharge: Decimal;
    begin
        // [FEATURE] [Prepayment] [Purchase]
        // [SCENARIO 278599] Service charge line is created with Prepayment % = 100 from Purchase Order
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Prepayment Purchase Order with 100 % with Amount = 1000 and Service Charge = 100
        ServiceCharge := LibraryRandom.RandDecInRange(10, 20, 2);
        CreatePurchaseOrderWithPrepaymentAndServiceCharge(PurchaseHeader, 100, ServiceCharge);

        // [WHEN] Calculate Invoice Discount
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);

        // [THEN] Service Charge line has Prepayment % = 100 and "Prepmt. Line Amount" = 100
        VerifyServChargePurchaseLines(PurchaseHeader, PurchaseHeader."Prepayment %", ServiceCharge);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderUpdatePrepmtInServChargeLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceCharge: Decimal;
    begin
        // [FEATURE] [Prepayment] [Purchase]
        // [SCENARIO 278599] Update Prepayment % in Service charge line
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Prepayment Purchase Order with 0 % with Amount = 1000 and Service Charge = 100
        ServiceCharge := LibraryRandom.RandDecInRange(10, 20, 2);
        CreatePurchaseOrderWithPrepaymentAndServiceCharge(PurchaseHeader, 0, ServiceCharge);

        // [GIVEN] Calculate Invoice Discount
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);

        // [WHEN] Update Prepayment % in Service Charge Line to 50
        FindPurchaseLineWithType(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account");
        PurchaseLine.Validate("Prepayment %", LibraryRandom.RandIntInRange(50, 100));
        PurchaseLine.Modify(true);

        // [THEN] Service Charge line has Prepayment % = 50 and "Prepmt. Line Amount" = 50
        VerifyServChargePurchaseLines(
          PurchaseHeader, PurchaseLine."Prepayment %", Round(ServiceCharge * PurchaseLine."Prepayment %" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithPrepmtResetPrepmtInServiceChargeLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Prepayment] [Purchase]
        // [SCENARIO 278599] Reset Prepayment % in Service charge line to zero
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Prepayment Purchase Order with 100 % with Amount = 1000 and Service Charge = 100
        CreatePurchaseOrderWithPrepaymentAndServiceCharge(PurchaseHeader, 100, LibraryRandom.RandDecInRange(10, 20, 2));

        // [GIVEN] Calculate Invoice Discount
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);

        // [WHEN] Reset Prepayment % in Service Charge Line to 0
        FindPurchaseLineWithType(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account");
        PurchaseLine.Validate("Prepayment %", 0);
        PurchaseLine.Modify(true);

        // [THEN] Service Charge line has Prepayment % = 0 and "Prepmt. Line Amount" = 0
        VerifyServChargePurchaseLines(PurchaseHeader, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderPostWithFullPrepmtAndServChargeLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [Prepayment] [Purchase]
        // [SCENARIO 278599] Post Purchase Order with Service charge line and Prepayment % = 100
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Prepayment Purchase Order with 100 % with Amount = 1000 and Service Charge = 100
        CreatePurchaseOrderWithPrepaymentAndServiceCharge(PurchaseHeader, 100, LibraryRandom.RandDecInRange(10, 20, 2));
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);

        // [WHEN] Post Prepayment Invoice
        PurchInvHeader.Get(LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader));

        // [THEN] Prepayment Invoice is posted with Amount = 1100
        PurchInvHeader.CalcFields(Amount);
        PurchInvHeader.TestField(Amount, PurchaseHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderPostWithPrepmtAndServChargeLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [Prepayment] [Purchase]
        // [SCENARIO 278599] Post Purchase Order with Service charge line and Prepayment % = 50
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Prepayment Purchase Order with 50 % with Amount = 1000 and Service Charge = 100
        CreatePurchaseOrderWithPrepaymentAndServiceCharge(
          PurchaseHeader, LibraryRandom.RandDecInRange(50, 100, 2), LibraryRandom.RandDecInRange(10, 20, 2));
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);

        // [WHEN] Post Prepayment Invoice
        PurchInvHeader.Get(LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader));

        // [THEN] Prepayment Invoice is posted with Amount = 5500
        PurchInvHeader.CalcFields(Amount);
        PurchInvHeader.TestField(Amount, Round(PurchaseHeader.Amount * PurchaseHeader."Prepayment %" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithServChargeIsUpdatedWhenPrepmtPosted()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceCharge: Decimal;
        NewQuantity: Decimal;
    begin
        // [FEATURE] [Prepayment] [Purchase]
        // [SCENARIO 278599] Update quantity on Purchase Line when prepayment invoice is posted and service charge is not changed
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Prepayment Purchase Order with 100 % with Amount = 1000 and Service Charge = 100
        ServiceCharge := LibraryRandom.RandDecInRange(10, 20, 2);
        CreatePurchaseOrderWithPrepaymentAndServiceCharge(PurchaseHeader, 100, ServiceCharge);
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);

        // [GIVEN] Post Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [WHEN] Update quantity in item line
        FindPurchaseLineWithType(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item);
        NewQuantity := PurchaseLine.Quantity * 2;
        PurchaseLine.Validate(Quantity, NewQuantity);
        PurchaseLine.Modify(true);
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);

        // [THEN] Quantity is updated in item line, service charge stays = 100
        PurchaseLine.TestField(Quantity, NewQuantity);
        FindPurchaseLineWithType(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account");
        PurchaseLine.TestField(Amount, ServiceCharge);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithServChargeChangedCannotBeUpdatedWhenPrepmtPosted()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceCharge: Decimal;
        NewQuantity: Decimal;
    begin
        // [FEATURE] [Prepayment] [Purchase]
        // [SCENARIO 278599] Purchase Line cannot be updated when prepayment invoice is posted and service charge is changed
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Prepayment Purchase Order with 100 % with Amount = 1000 and Service Charge = 100 with Min Amount = 1000
        ServiceCharge := LibraryRandom.RandDecInRange(10, 20, 2);
        CreatePurchaseOrderWithPrepaymentAndServiceCharge(PurchaseHeader, 100, ServiceCharge);
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);

        // [GIVEN] Service Charge = 50 with Min Amount = 1001
        CreateVendInvoiceDiscount(PurchaseHeader."Pay-to Vendor No.", ServiceCharge / 2, PurchaseHeader.Amount + 1);

        // [GIVEN] Post Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [WHEN] Update quantity in item line
        FindPurchaseLineWithType(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item);
        NewQuantity := PurchaseLine.Quantity * 2;
        PurchaseLine.Validate(Quantity, NewQuantity);
        PurchaseLine.Modify(true);
        asserterror LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);

        // [THEN] Error raised that you cannot change the line because it affects on prepaid service charge
        Assert.ExpectedError(CannotChangePrepaidServiceChargeErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM VAT Serv. Charge");
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM VAT Serv. Charge");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySales.SetOrderNoSeriesInSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM VAT Serv. Charge");
    end;

    local procedure CreateSalesOrderWithInvDisc(var SalesHeader: Record "Sales Header"; InvDiscAmt: Integer) ServiceCharge: Integer
    var
        CustomerNo: Code[20];
        MinimumAmount: Integer;
    begin
        // Setup: Create Customer with Invoice Discount and Random Value for Minimum Amount and Service Charge, Create Sales Order and
        // Release it.
        ServiceCharge := LibraryRandom.RandInt(10);
        MinimumAmount := ServiceCharge * 2;
        CustomerNo := CreateCustAndInvoiceDiscount(ServiceCharge, MinimumAmount);

        // Exercise: Create Sales Order and Release it.
        CreateSalesOrder(SalesHeader, CustomerNo, MinimumAmount - InvDiscAmt);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreatePurchCreditMemoInvDisc(var PurchaseHeader: Record "Purchase Header"; InvDiscAmt: Integer) ServiceCharge: Integer
    var
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        VendorNo: Code[20];
        MinimumAmount: Integer;
    begin
        // Setup: Create Vendor with Invoice Discount, Purchase Credit memo and Calculate Invoice Discount.
        ServiceCharge := LibraryRandom.RandInt(10);
        MinimumAmount := ServiceCharge * 2;
        VendorNo := CreateVendAndInvoiceDiscount(ServiceCharge, MinimumAmount);

        // Exercise: Create Purchase Credit Memo and Calculate Invoice Discount.
        CreatePurchaseCreditMemo(PurchaseHeader, PurchaseLine, VendorNo, MinimumAmount - InvDiscAmt);
        PurchCalcDiscount.Run(PurchaseLine);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), 1);
        // 1 Fix Qty Required to Keep Price Static.
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseCreditMemo(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        // 1 Fix Qty Required to Keep Price Static.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateCustInvoiceDiscount(CustomerNo: Code[20]; ServiceCharge: Decimal; MinimumAmount: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', MinimumAmount);
        CustInvoiceDisc.Validate("Service Charge", ServiceCharge);
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateVendInvoiceDiscount(VendorNo: Code[20]; ServiceCharge: Decimal; MinimumAmount: Decimal)
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorNo, '', MinimumAmount);
        VendorInvoiceDisc.Validate("Service Charge", ServiceCharge);
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure CreateCustAndInvoiceDiscount(ServiceCharge: Decimal; MinimumAmount: Decimal): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateCustInvoiceDiscount(Customer."No.", ServiceCharge, 0);
        CreateCustInvoiceDiscount(Customer."No.", 0, MinimumAmount);
        exit(Customer."No.");
    end;

    local procedure CreateVendAndInvoiceDiscount(ServiceCharge: Decimal; MinimumAmount: Decimal): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateVendInvoiceDiscount(Vendor."No.", ServiceCharge, 0);
        CreateVendInvoiceDiscount(Vendor."No.", 0, MinimumAmount);
        exit(Vendor."No.");
    end;

    local procedure CreateSalesOrderWithPrepaymentAndServiceCharge(var SalesHeader: Record "Sales Header"; PrepaymentPct: Decimal; ServiceCharge: Decimal)
    var
        SalesLine: Record "Sales Line";
        CustomerPostingGroup: Record "Customer Posting Group";
        Amount: Decimal;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prepayment %", PrepaymentPct);
        SalesHeader.Modify(true);
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
        CreateCustInvoiceDiscount(SalesHeader."Sell-to Customer No.", ServiceCharge, SalesLine.Amount);
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        UpdateServiceChargeAccWithVAT(CustomerPostingGroup."Service Charge Acc.", SalesLine."No.");
        LibraryERM.UpdateSalesPrepmtAccountVATGroup(
            SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
    end;

    local procedure CreatePurchaseOrderWithPrepaymentAndServiceCharge(var PurchaseHeader: Record "Purchase Header"; PrepaymentPct: Decimal; ServiceCharge: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        VendorPostingGroup: Record "Vendor Posting Group";
        Amount: Decimal;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Prepayment %", PrepaymentPct);
        PurchaseHeader.Validate("Prepmt. Payment Terms Code", PurchaseHeader."Payment Terms Code");
        PurchaseHeader.Modify(true);
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);
        CreateVendInvoiceDiscount(PurchaseHeader."Pay-to Vendor No.", ServiceCharge, PurchaseLine.Amount);
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        UpdateServiceChargeAccWithVAT(VendorPostingGroup."Service Charge Acc.", PurchaseLine."No.");
        LibraryERM.UpdatePurchPrepmtAccountVATGroup(
            PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]): Boolean
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        exit(SalesLine.FindFirst())
    end;

    local procedure FindSalesLineWithType(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, Type);
        SalesLine.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]): Boolean
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"G/L Account");
        exit(PurchaseLine.FindFirst())
    end;

    local procedure FindPurchaseLineWithType(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, Type);
        PurchaseLine.FindFirst();
    end;

    local procedure FindGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; VATAmount: Decimal; AmountRoundingPrecision: Decimal): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("VAT Amount", VATAmount - AmountRoundingPrecision, VATAmount + AmountRoundingPrecision);
        GLEntry.FindFirst();
        exit(GLEntry."VAT Amount");
    end;

    local procedure UpdateServiceChargeAccWithVAT(GLAccountNo: Code[20]; ItemNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        GLAccount.Get(GLAccountNo);
        GLAccount.Validate("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure VerifySalesLine(DocumentNo: Code[20]; LineAmount: Decimal; AmountIncludingVat: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesLine: Record "Sales Line";
        AmtIncVat: Decimal;
    begin
        GeneralLedgerSetup.Get();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindSet();
        repeat
            AmtIncVat += SalesLine."Line Amount";
        until SalesLine.Next() = 0;
        Assert.AreNearlyEqual(
          AmountIncludingVat, AmtIncVat, GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountError, AmountIncludingVat,
            SalesLine.TableCaption()));

        FindSalesLine(SalesLine, DocumentNo);
        LineAmount += LineAmount * SalesLine."VAT %" / 100;
        Assert.AreNearlyEqual(
          LineAmount, SalesLine."Line Amount", GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountError, LineAmount,
            SalesLine.TableCaption()));
    end;

    local procedure VerifyPurchaseLine(DocumentNo: Code[20]; LineAmount: Decimal; AmountIncludingVat: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        AmtIncVat: Decimal;
    begin
        GeneralLedgerSetup.Get();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
        repeat
            AmtIncVat += PurchaseLine."Line Amount";
        until PurchaseLine.Next() = 0;
        Assert.AreNearlyEqual(
          AmountIncludingVat, AmtIncVat, GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountError, AmountIncludingVat,
            PurchaseLine.TableCaption()));

        FindPurchaseLine(PurchaseLine, DocumentNo);
        LineAmount += LineAmount * PurchaseLine."VAT %" / 100;
        Assert.AreNearlyEqual(
          LineAmount, PurchaseLine."Line Amount", GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountError,
            LineAmount, PurchaseLine.TableCaption()));
    end;

    local procedure VerifyGLEntryForSales(DocumentNo: Code[20]; VATAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        GLVatAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        GLVatAmount :=
          FindGLEntry(GLEntry."Document Type"::Invoice, DocumentNo, -VATAmount, GeneralLedgerSetup."Amount Rounding Precision");
        Assert.AreNearlyEqual(
          -VATAmount, GLVatAmount, GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountError, -VATAmount,
            GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryForPurchase(PreAssignedNo: Code[20]; VATAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GLEntry: Record "G/L Entry";
        GLVatAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        PurchCrMemoHdr.SetRange("Pre-Assigned No.", PreAssignedNo);
        PurchCrMemoHdr.FindFirst();
        GLVatAmount :=
          FindGLEntry(
            GLEntry."Document Type"::"Credit Memo", PurchCrMemoHdr."No.", -VATAmount, GeneralLedgerSetup."Amount Rounding Precision");
        Assert.AreNearlyEqual(
          -VATAmount, GLVatAmount, GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountError, -VATAmount,
            GLEntry.TableCaption()));
    end;

    local procedure VerifyServChargeSalesLines(SalesHeader: Record "Sales Header"; PrepaymentPct: Decimal; PrepmtLineAmt: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLineWithType(SalesLine, SalesHeader, SalesLine.Type::"G/L Account");
        SalesLine.TestField("Prepayment %", PrepaymentPct);
        Assert.AreNearlyEqual(PrepmtLineAmt, SalesLine."Prepmt. Line Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(), '');
    end;

    local procedure VerifyServChargePurchaseLines(PurchaseHeader: Record "Purchase Header"; PrepaymentPct: Decimal; PrepmtLineAmt: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLineWithType(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account");
        PurchaseLine.TestField("Prepayment %", PrepaymentPct);
        Assert.AreNearlyEqual(PrepmtLineAmt, PurchaseLine."Prepmt. Line Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(), '');
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessage)) then;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}