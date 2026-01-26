codeunit 142085 PurchDocTotalsSalesEntryUI
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Document Totals]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchInvoiceDisplaysDocTotalsAddTaxGroupCode()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        DocumentTotals: Codeunit "Document Totals";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Tax Group Code]
        // [SCENARIO 136988] Doc Totals with Sales Tax are updated when adding Tax Group Code on Purchase Invoice
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Invoice, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        PurchaseInvoice.PurchLines."Total VAT Amount".AssertEquals(0);
        PurchaseInvoice.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        PurchaseInvoice.PurchLines.Next();

        SetCompareAmounts(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchInvoiceDisplaysDocTotalsUpdateQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        DocumentTotals: Codeunit "Document Totals";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Quantity]
        // [SCENARIO 136988] Doc Totals with Sales Tax are updated when changing Quantity on Purchase Invoice
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line item that defaults the Tax Group Code
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Invoice, TaxPercentage, true, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User changes the quantity
        PurchaseInvoice.PurchLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        if PurchaseInvoice.PurchLines.Next() then
            PurchaseInvoice.PurchLines.Previous();

        SetCompareAmounts(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchInvoiceDisplaysDocTotalsNoInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalDirectUnitCost: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Purchase Invoice Doc Totals, Sales Tax are calculated but Invoice Discount is not per setup option
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := false;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocumentWithInvDisc(PurchaseLine, PurchaseHeader."Document Type"::Invoice, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AssertEquals(0);
        PurchaseInvoice.PurchLines."Total VAT Amount".AssertEquals(0);
        PurchaseInvoice.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalDirectUnitCost := PurchaseLine."Direct Unit Cost";
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(OriginalDirectUnitCost + 1);
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(OriginalDirectUnitCost);
        PurchaseInvoice.PurchLines.Next();

        SetCompareAmounts(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page but Inv Discount is 0
        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AssertEquals(0);
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PostAmounts[FieldType::DiscountPercent], RoundingPrecision, false);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchInvoiceDisplaysDocTotalsWithInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Purchase Invoice Doc Totals, Tax and Inv Discount are calculated when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocumentWithInvDisc(PurchaseLine, PurchaseHeader."Document Type"::Invoice, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);
        PurchaseInvoice.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        PurchaseInvoice.PurchLines.Next();

        SetCompareAmounts(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated, Invoice Discount and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, false);

        LibraryNotificationMgt.RecallNotificationsForRecord(OriginalPurchLine);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchInvoiceDisplaysDocTotalsUpdateInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Purchase Invoice Doc Totals, Tax and Invoice Discount are updated when changing Inv Disc Amount
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that defaults the Tax Code Group
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Invoice, TaxPercentage, true, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);

        // Store values from window before setting the Invoice Discount Amount
        SetCompareAmounts(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User sets the Invoice Discount Amount
        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(LibraryRandom.RandIntInRange(1, 1));

        SetCompareAmounts(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, true);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchInvoicePosting()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PurchHeaderAmounts: array[5] of Decimal;
        PurchPostedAmounts: array[5] of Decimal;
        TaxPercentage: Integer;
        PostedPurchDocNo: Code[20];
        TaxGroupCode: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Post]
        // [SCENARIO 136988] Doc Totals and taxes match before and after posting on Purchase Invoice
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line with no default Tax Group Code
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Invoice, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        PurchaseInvoice.PurchLines.Next();

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PurchHeaderAmounts);

        // [WHEN] User Posts the invoice
        PostedPurchDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Invoice.
        PurchInvHeader.Get(PostedPurchDocNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        SetCompareAmounts(PurchInvHeader."Invoice Discount Amount",
          PurchInvHeader.Amount,
          PurchInvHeader."Amount Including VAT" - PurchInvHeader.Amount,
          PurchInvHeader."Amount Including VAT",
          0,
          PurchPostedAmounts);

        // [THEN] Posted amounts should match the pre-posted amounts
        VerifyPostedFieldValues(PurchHeaderAmounts, PurchPostedAmounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderDisplaysDocTotalsAddTaxGroupCode()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseOrder: TestPage "Purchase Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Tax Group Code]
        // [SCENARIO 136988] Doc Totals with Sales Tax are updated when adding Tax Group Code on Purchase Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseOrderPageEdit(PurchaseOrder, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        PurchaseOrder.PurchLines."Total VAT Amount".AssertEquals(0);
        PurchaseOrder.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseOrderPageEdit(PurchaseOrder, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        PurchaseOrder.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        PurchaseOrder.PurchLines.Next();

        SetCompareAmounts(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderDisplaysDocTotalsUpdateQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseOrder: TestPage "Purchase Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Quantity]
        // [SCENARIO 136988] Doc Totals with Sales Tax are updated when changing Quantity on Purchase Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line item that defaults the Tax Group Code
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order, TaxPercentage, true, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseOrderPageEdit(PurchaseOrder, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User changes the quantity
        PurchaseOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        if PurchaseOrder.PurchLines.Next() then
            PurchaseOrder.PurchLines.Previous();

        SetCompareAmounts(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderDisplaysDocTotalsNoInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchaseOrder: TestPage "Purchase Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        TotalTax: Decimal;
        CalcInvDisc: Boolean;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Purchase Order Doc Totals, Sales Tax are calculated but Invoice Discount is not per setup option
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := false;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocumentWithInvDisc(PurchaseLine, PurchaseHeader."Document Type"::Order, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseOrderPageEdit(PurchaseOrder, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        PurchaseOrder.PurchLines."Invoice Discount Amount".AssertEquals(0);
        PurchaseOrder.PurchLines."Total VAT Amount".AssertEquals(0);
        PurchaseOrder.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseOrderPageEdit(PurchaseOrder, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        PurchaseOrder.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        PurchaseOrder.PurchLines.Next();

        SetCompareAmounts(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page but Inv Discount is 0
        PurchaseOrder.PurchLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PostAmounts[FieldType::DiscountPercent], RoundingPrecision, false);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderDisplaysDocTotalsWithInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseOrder: TestPage "Purchase Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalDirectUnitCost: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Purchase Order Doc Totals, Tax and Inv Discount are calculated when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocumentWithInvDisc(PurchaseLine, PurchaseHeader."Document Type"::Order, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseOrderPageEdit(PurchaseOrder, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);
        PurchaseOrder.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseOrderPageEdit(PurchaseOrder, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalDirectUnitCost := PurchaseLine."Direct Unit Cost";
        PurchaseOrder.PurchLines."Direct Unit Cost".SetValue(OriginalDirectUnitCost + 1);
        PurchaseOrder.PurchLines."Direct Unit Cost".SetValue(OriginalDirectUnitCost);
        PurchaseOrder.PurchLines.Next();

        SetCompareAmounts(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated, Invoice Discount and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, false);

        LibraryNotificationMgt.RecallNotificationsForRecord(OriginalPurchLine);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderDisplaysDocTotalsUpdateInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseOrder: TestPage "Purchase Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        CalcInvDisc: Boolean;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Purchase Order Doc Totals, Tax and Invoice Discount are updated when changing Inv Disc Amount
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that defaults the Tax Code Group
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order, TaxPercentage, true, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseOrderPageEdit(PurchaseOrder, PurchaseHeader);

        // Store values from window before setting the Invoice Discount Amount
        SetCompareAmounts(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User sets the Invoice Discount Amount
        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(LibraryRandom.RandIntInRange(1, 1));

        SetCompareAmounts(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, true);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchOrderPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseHeaderAmounts: array[5] of Decimal;
        PurchPostedAmounts: array[5] of Decimal;
        TaxPercentage: Integer;
        PostedPurchDocNo: Code[20];
        TaxGroupCode: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Post]
        // [SCENARIO 136988] Doc Totals and taxes match before and after posting on Purchase Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line with no default Tax Group Code
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseOrderPageEdit(PurchaseOrder, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        PurchaseOrder.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        PurchaseOrder.PurchLines.Next();

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PurchaseHeaderAmounts);

        // [WHEN] User Posts the invoice
        PostedPurchDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Invoice.
        PurchInvHeader.Get(PostedPurchDocNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        SetCompareAmounts(PurchInvHeader."Invoice Discount Amount",
          PurchInvHeader.Amount,
          PurchInvHeader."Amount Including VAT" - PurchInvHeader.Amount,
          PurchInvHeader."Amount Including VAT",
          0,
          PurchPostedAmounts);

        // [THEN] Posted amounts should match the pre-posted amounts
        VerifyPostedFieldValues(PurchaseHeaderAmounts, PurchPostedAmounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchReturnOrderDisplaysDocTotalsAddTaxGroupCode()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Tax Group Code]
        // [SCENARIO 136988] Doc Totals with Sales Tax are updated when adding Tax Group Code on Purchase Return Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Return Order", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseReturnOrderPageEdit(PurchaseReturnOrder, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        PurchaseReturnOrder.PurchLines."Total VAT Amount".AssertEquals(0);
        PurchaseReturnOrder.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseReturnOrderPageEdit(PurchaseReturnOrder, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        PurchaseReturnOrder.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        PurchaseReturnOrder.PurchLines.Next();

        SetCompareAmounts(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchReturnOrderDisplaysDocTotalsUpdateQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Quantity]
        // [SCENARIO 136988] Doc Totals with Sales Tax are updated when changing Quantity on Purchase Return Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line item that defaults the Tax Group Code
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Return Order", TaxPercentage, true, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseReturnOrderPageEdit(PurchaseReturnOrder, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User changes the quantity
        PurchaseReturnOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        if PurchaseReturnOrder.PurchLines.Next() then
            PurchaseReturnOrder.PurchLines.Previous();

        SetCompareAmounts(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchReturnOrderDisplaysDocTotalsNoInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        TotalTax: Decimal;
        CalcInvDisc: Boolean;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Purchase Return Order Doc Totals, Sales Tax are calculated but Inv Disc is not per setup option
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := false;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocumentWithInvDisc(PurchaseLine, PurchaseHeader."Document Type"::"Return Order", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseReturnOrderPageEdit(PurchaseReturnOrder, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AssertEquals(0);
        PurchaseReturnOrder.PurchLines."Total VAT Amount".AssertEquals(0);
        PurchaseReturnOrder.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseReturnOrderPageEdit(PurchaseReturnOrder, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        PurchaseReturnOrder.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        PurchaseReturnOrder.PurchLines.Next();

        SetCompareAmounts(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page but Inv Discount is 0
        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PostAmounts[FieldType::DiscountPercent], RoundingPrecision, false);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchReturnOrderDisplaysDocTotalsWithInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        DocumentTotals: Codeunit "Document Totals";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalDirectUnitCost: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Purchase Return Order Doc Totals, Tax and Inv Discount are calc'd when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocumentWithInvDisc(PurchaseLine, PurchaseHeader."Document Type"::"Return Order", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseReturnOrderPageEdit(PurchaseReturnOrder, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);
        PurchaseReturnOrder.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseReturnOrderPageEdit(PurchaseReturnOrder, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalDirectUnitCost := PurchaseLine."Direct Unit Cost";
        PurchaseReturnOrder.PurchLines."Direct Unit Cost".SetValue(OriginalDirectUnitCost + 1);
        PurchaseReturnOrder.PurchLines."Direct Unit Cost".SetValue(OriginalDirectUnitCost);
        PurchaseReturnOrder.PurchLines.Next();

        SetCompareAmounts(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated, Invoice Discount and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, false);

        LibraryNotificationMgt.RecallNotificationsForRecord(OriginalPurchLine);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchReturnOrderDisplaysDocTotalsUpdateInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        CalcInvDisc: Boolean;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Purchase Return Order Doc Totals, Tax and Invoice Discount are updated when changing Inv Disc Amount
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that defaults the Tax Code Group
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Return Order", TaxPercentage, true, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseReturnOrderPageEdit(PurchaseReturnOrder, PurchaseHeader);

        // Store values from window before setting the Invoice Discount Amount
        SetCompareAmounts(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User sets the Invoice Discount Amount
        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".SetValue(LibraryRandom.RandIntInRange(1, 1));

        SetCompareAmounts(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, true);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchReturnOrderPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PurchaseHeaderAmounts: array[5] of Decimal;
        PurchPostedAmounts: array[5] of Decimal;
        TaxPercentage: Integer;
        PostedPurchDocNo: Code[20];
        TaxGroupCode: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Post]
        // [SCENARIO 136988] Doc Totals and taxes match before and after posting on Purchase Return Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line with no default Tax Group Code
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Return Order", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseReturnOrderPageEdit(PurchaseReturnOrder, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        PurchaseReturnOrder.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        PurchaseReturnOrder.PurchLines.Next();

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PurchaseHeaderAmounts);

        // [WHEN] User Posts the invoice
        PostedPurchDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Invoice.
        PurchCrMemoHdr.Get(PostedPurchDocNo);
        PurchCrMemoHdr.CalcFields(Amount, "Amount Including VAT");
        SetCompareAmounts(PurchCrMemoHdr."Invoice Discount Amount",
          PurchCrMemoHdr.Amount,
          PurchCrMemoHdr."Amount Including VAT" - PurchCrMemoHdr.Amount,
          PurchCrMemoHdr."Amount Including VAT",
          0,
          PurchPostedAmounts);

        // [THEN] Posted amounts should match the pre-posted amounts
        VerifyPostedFieldValues(PurchaseHeaderAmounts, PurchPostedAmounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchCrMemoDisplaysDocTotalsAddTaxGroupCode()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Tax Group Code]
        // [SCENARIO 136988] Doc Totals with Sales Tax are updated when adding Tax Group Code on Credit Memo
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseCreditMemoPageEdit(PurchaseCreditMemo, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        PurchaseCreditMemo.PurchLines."Total VAT Amount".AssertEquals(0);
        PurchaseCreditMemo.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseCreditMemoPageEdit(PurchaseCreditMemo, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        PurchaseCreditMemo.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        PurchaseCreditMemo.PurchLines.Next();

        SetCompareAmounts(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchCrMemoDisplaysDocTotalsUpdateQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Quantity]
        // [SCENARIO 136988] Doc Totals with Sales Tax are updated when changing Quantity on Credit Memo
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line item that defaults the Tax Group Code
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", TaxPercentage, true, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseCreditMemoPageEdit(PurchaseCreditMemo, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User changes the quantity
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        if PurchaseCreditMemo.PurchLines.Next() then
            PurchaseCreditMemo.PurchLines.Previous();

        SetCompareAmounts(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchCrMemoDisplaysDocTotalsNoInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        TotalTax: Decimal;
        CalcInvDisc: Boolean;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Credit Memo Doc Totals, Sales Tax are calculated but Inv Disc is not per setup option
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := false;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocumentWithInvDisc(PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseCreditMemoPageEdit(PurchaseCreditMemo, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AssertEquals(0);
        PurchaseCreditMemo.PurchLines."Total VAT Amount".AssertEquals(0);
        PurchaseCreditMemo.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseCreditMemoPageEdit(PurchaseCreditMemo, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        PurchaseCreditMemo.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        PurchaseCreditMemo.PurchLines.Next();

        SetCompareAmounts(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page but Inv Discount is 0
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PostAmounts[FieldType::DiscountPercent], RoundingPrecision, false);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchCrMemoDisplaysDocTotalsWithInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalDirectUnitCost: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Purchase Credit Memo Doc Totals, Tax and Inv Discount are calc'd when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocumentWithInvDisc(PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseCreditMemoPageEdit(PurchaseCreditMemo, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);
        PurchaseCreditMemo.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseCreditMemoPageEdit(PurchaseCreditMemo, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalDirectUnitCost := PurchaseLine."Direct Unit Cost";
        PurchaseCreditMemo.PurchLines."Direct Unit Cost".SetValue(OriginalDirectUnitCost + 1);
        PurchaseCreditMemo.PurchLines."Direct Unit Cost".SetValue(OriginalDirectUnitCost);
        PurchaseCreditMemo.PurchLines.Next();

        SetCompareAmounts(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated, Invoice Discount and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, false);

        LibraryNotificationMgt.RecallNotificationsForRecord(OriginalPurchLine);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchCrMemoDisplaysDocTotalsUpdateInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        CalcInvDisc: Boolean;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Credit Memo Doc Totals, Tax and Invoice Discount are updated when changing Inv Disc Amount
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that defaults the Tax Code Group
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", TaxPercentage, true, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseCreditMemoPageEdit(PurchaseCreditMemo, PurchaseHeader);

        // Store values from window before setting the Invoice Discount Amount
        SetCompareAmounts(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User sets the Invoice Discount Amount
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(LibraryRandom.RandIntInRange(1, 1));

        SetCompareAmounts(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, true);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchCrMemoPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PurchaseHeaderAmounts: array[5] of Decimal;
        PurchPostedAmounts: array[5] of Decimal;
        TaxPercentage: Integer;
        PostedPurchDocNo: Code[20];
        TaxGroupCode: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Post]
        // [SCENARIO 136988] Doc Totals and taxes match before and after posting on Credit Memo
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line with no default Tax Group Code
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseCreditMemoPageEdit(PurchaseCreditMemo, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        PurchaseCreditMemo.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        PurchaseCreditMemo.PurchLines.Next();

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PurchaseHeaderAmounts);

        // [WHEN] User Posts the invoice
        PostedPurchDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Invoice.
        PurchCrMemoHdr.Get(PostedPurchDocNo);
        PurchCrMemoHdr.CalcFields(Amount, "Amount Including VAT");
        SetCompareAmounts(PurchCrMemoHdr."Invoice Discount Amount",
          PurchCrMemoHdr.Amount,
          PurchCrMemoHdr."Amount Including VAT" - PurchCrMemoHdr.Amount,
          PurchCrMemoHdr."Amount Including VAT",
          0,
          PurchPostedAmounts);

        // [THEN] Posted amounts should match the pre-posted amounts
        VerifyPostedFieldValues(PurchaseHeaderAmounts, PurchPostedAmounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchBlanketOrderDisplaysDocTotalsAddTaxGroupCode()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Tax Group Code]
        // [SCENARIO 136988] Doc Totals with Sales Tax are updated when adding Tax Group Code on Blanket Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenBlanketPurchaseOrderPageEdit(BlanketPurchaseOrder, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        BlanketPurchaseOrder.PurchLines."Total VAT Amount".AssertEquals(0);
        BlanketPurchaseOrder.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenBlanketPurchaseOrderPageEdit(BlanketPurchaseOrder, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        BlanketPurchaseOrder.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        BlanketPurchaseOrder.PurchLines.Next();

        SetCompareAmounts(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchBlanketOrderDisplaysDocTotalsUpdateQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Quantity]
        // [SCENARIO 136988] Doc Totals with Sales Tax are updated when changing Quantity on Blanket Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line item that defaults the Tax Group Code
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order", TaxPercentage, true, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenBlanketPurchaseOrderPageEdit(BlanketPurchaseOrder, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User changes the quantity
        BlanketPurchaseOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        if BlanketPurchaseOrder.PurchLines.Next() then
            BlanketPurchaseOrder.PurchLines.Previous();

        SetCompareAmounts(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchBlanketOrderDisplaysDocTotalsNoInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        TotalTax: Decimal;
        CalcInvDisc: Boolean;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Blanket Order Doc Totals, Sales Tax are calculated but Invoice Discount is not per setup option
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := false;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocumentWithInvDisc(PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenBlanketPurchaseOrderPageEdit(BlanketPurchaseOrder, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AssertEquals(0);
        BlanketPurchaseOrder.PurchLines."Total VAT Amount".AssertEquals(0);
        BlanketPurchaseOrder.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenBlanketPurchaseOrderPageEdit(BlanketPurchaseOrder, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        BlanketPurchaseOrder.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        BlanketPurchaseOrder.PurchLines.Next();

        SetCompareAmounts(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page but Inv Discount is 0
        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PostAmounts[FieldType::DiscountPercent], RoundingPrecision, false);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchBlanketOrderDisplaysDocTotalsWithInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalDirectUnitCost: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Blanket Order Doc Totals, Tax and Inv Discount are calculated when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocumentWithInvDisc(PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenBlanketPurchaseOrderPageEdit(BlanketPurchaseOrder, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);
        BlanketPurchaseOrder.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenBlanketPurchaseOrderPageEdit(BlanketPurchaseOrder, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalDirectUnitCost := PurchaseLine."Direct Unit Cost";
        BlanketPurchaseOrder.PurchLines."Direct Unit Cost".SetValue(OriginalDirectUnitCost + 1);
        BlanketPurchaseOrder.PurchLines."Direct Unit Cost".SetValue(OriginalDirectUnitCost);
        BlanketPurchaseOrder.PurchLines.Next();

        SetCompareAmounts(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated, Invoice Discount and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, false);

        LibraryNotificationMgt.RecallNotificationsForRecord(OriginalPurchLine);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchBlanketOrderDisplaysDocTotalsUpdateInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        CalcInvDisc: Boolean;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Blanket Order Doc Totals, Tax and Invoice Discount are updated when changing Inv Disc Amount
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that defaults the Tax Code Group
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order", TaxPercentage, true, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenBlanketPurchaseOrderPageEdit(BlanketPurchaseOrder, PurchaseHeader);

        // Store values from window before setting the Invoice Discount Amount
        SetCompareAmounts(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User sets the Invoice Discount Amount
        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(LibraryRandom.RandIntInRange(1, 1));

        SetCompareAmounts(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total VAT Amount".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketPurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, true);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchQuoteDisplaysDocTotalsAddTaxGroupCode()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseQuote: TestPage "Purchase Quote";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Tax Group Code]
        // [SCENARIO 136988] Doc Totals with Sales Tax are updated when adding Tax Group Code on Purchase Quote
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Quote, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseQuotePageEdit(PurchaseQuote, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseQuote.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        PurchaseQuote.PurchLines."Total VAT Amount".AssertEquals(0);
        PurchaseQuote.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseQuotePageEdit(PurchaseQuote, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        PurchaseQuote.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        PurchaseQuote.PurchLines.Next();

        SetCompareAmounts(PurchaseQuote.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchQuoteDisplaysDocTotalsUpdateQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseQuote: TestPage "Purchase Quote";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Quantity]
        // [SCENARIO 136988] Doc Totals with Sales Tax are updated when changing Quantity on Purchase Quote
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a purchase document with a purchase line item that defaults the Tax Group Code
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Quote, TaxPercentage, true, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseQuotePageEdit(PurchaseQuote, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseQuote.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User changes the quantity
        PurchaseQuote.PurchLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        if PurchaseQuote.PurchLines.Next() then
            PurchaseQuote.PurchLines.Previous();

        SetCompareAmounts(PurchaseQuote.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchQuoteDisplaysDocTotalsNoInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchaseQuote: TestPage "Purchase Quote";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        TotalTax: Decimal;
        CalcInvDisc: Boolean;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Purchase Quote Doc Totals, Sales Tax are calculated but Invoice Discount is not per setup option
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := false;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocumentWithInvDisc(PurchaseLine, PurchaseHeader."Document Type"::Quote, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseQuotePageEdit(PurchaseQuote, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseQuote.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        PurchaseQuote.PurchLines."Invoice Discount Amount".AssertEquals(0);
        PurchaseQuote.PurchLines."Total VAT Amount".AssertEquals(0);
        PurchaseQuote.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseQuotePageEdit(PurchaseQuote, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        PurchaseQuote.PurchLines."Direct Unit Cost".SetValue(PurchaseLine."Direct Unit Cost");
        PurchaseQuote.PurchLines.Next();

        SetCompareAmounts(PurchaseQuote.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page but Inv Discount is 0
        PurchaseQuote.PurchLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PostAmounts[FieldType::DiscountPercent], RoundingPrecision, false);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchQuoteDisplaysDocTotalsWithInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseQuote: TestPage "Purchase Quote";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalDirectUnitCost: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Purchase Quote Doc Totals, Tax and Inv Discount are calculated when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that did not default the Tax Code Group
        CreatePurchaseDocumentWithInvDisc(PurchaseLine, PurchaseHeader."Document Type"::Quote, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseQuotePageEdit(PurchaseQuote, PurchaseHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseQuote.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);
        PurchaseQuote.Close();

        // [WHEN] User sets the Tax Group Code
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseQuotePageEdit(PurchaseQuote, PurchaseHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalDirectUnitCost := PurchaseLine."Direct Unit Cost";
        PurchaseQuote.PurchLines."Direct Unit Cost".SetValue(OriginalDirectUnitCost + 1);
        PurchaseQuote.PurchLines."Direct Unit Cost".SetValue(OriginalDirectUnitCost);
        PurchaseQuote.PurchLines.Next();

        SetCompareAmounts(PurchaseQuote.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated, Invoice Discount and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, false);

        LibraryNotificationMgt.RecallNotificationsForRecord(OriginalPurchLine);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchQuoteDisplaysDocTotalsUpdateInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        TotalPurchLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseQuote: TestPage "Purchase Quote";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        CalcInvDisc: Boolean;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136988] Purchase Quote Doc Totals, Tax and Invoice Discount are updated when changing Inv Disc Amount
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a purchase document with a purchase line that defaults the Tax Code Group
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Quote, TaxPercentage, true, TaxGroupCode);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchLine);

        // Store away the line created, to pull back in later
        OriginalPurchLine := PurchaseLine;
        RoundingPrecision := 0.01;

        PurchaseHeader.Get(OriginalPurchLine."Document Type", OriginalPurchLine."Document No.");
        OpenPurchaseQuotePageEdit(PurchaseQuote, PurchaseHeader);

        // Store values from window before setting the Invoice Discount Amount
        SetCompareAmounts(PurchaseQuote.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User sets the Invoice Discount Amount
        PurchaseQuote.PurchLines."Invoice Discount Amount".SetValue(LibraryRandom.RandIntInRange(1, 1));

        SetCompareAmounts(PurchaseQuote.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseQuote.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseQuote.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax,
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(OriginalPurchLine), RoundingPrecision, true);

        // Clean-up
        SetupCalcInvoiceDisc(CalcInvDisc);
    end;

    local procedure CreateVendor(TaxAreaCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        UpdateVendorTaxAreaCode(Vendor, TaxAreaCode);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithDiscount(var Vendor: Record Vendor; TaxAreaCode: Code[20]; DiscPct: Decimal; MinimumAmount: Decimal)
    var
        LibrarySmallBusiness: Codeunit "Library - Small Business";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        UpdateVendorTaxAreaCode(Vendor, TaxAreaCode);
        LibrarySmallBusiness.SetInvoiceDiscountToVendor(Vendor, DiscPct, MinimumAmount, '');
    end;

    local procedure UpdateVendorTaxAreaCode(Vendor: Record Vendor; TaxAreaCode: Code[20])
    begin
        Vendor.Validate("VAT Bus. Posting Group", '');
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Modify(true);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        VATEntry: Record "VAT Entry";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        VATEntry.DeleteAll();
        LibrarySetupStorage.Restore();
        LibraryApplicationArea.ClearApplicationAreaCache();
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        CreateVATPostingSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Use Vendor's Tax Area Code" := true;
        PurchasesPayablesSetup.Modify();

        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
    end;

    local procedure CreateItem(TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        UpdateItem(Item, TaxGroupCode, LibraryRandom.RandInt(10));
        exit(Item."No.");
    end;

    local procedure CreateItemSpecifyUnitPrice(TaxGroupCode: Code[20]; UnitPrice: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        UpdateItem(Item, TaxGroupCode, UnitPrice);
        exit(Item."No.");
    end;

    local procedure UpdateItem(var Item: Record Item; TaxGroupCode: Code[20]; UnitPrice: Decimal)
    begin
        Item.Validate("VAT Prod. Posting Group", '');
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Validate("Unit Price", UnitPrice);
        Item.Validate("Last Direct Cost", UnitPrice);
        Item.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail"; TaxPercentage: Integer)
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax Only", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxPercentage);  // Using RANDOM value for Tax Below Maximum.
        TaxDetail.Modify(true);
    end;

    local procedure CreateSalesTaxJurisdiction(): Code[10]
    var
        GLAccount: Record "G/L Account";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateGLAccount(GLAccount);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Reverse Charge (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Report-to Jurisdiction", TaxJurisdiction.Code);
        TaxJurisdiction.Modify(true);
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateTaxAreaLine(var TaxDetail: Record "Tax Detail"; TaxPercentage: Integer): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        CreateSalesTaxDetail(TaxDetail, TaxPercentage);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        exit(TaxArea.Code);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; TaxPercentage: Integer; DefaultTaxCodeOnItem: Boolean; var TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
        TaxGroupCodeItem: Code[20];
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxPercentage);
        TaxGroupCode := TaxDetail."Tax Group Code";
        if DefaultTaxCodeOnItem then
            TaxGroupCodeItem := TaxGroupCode;
        CreatePurchaseDocumentWithCertainTax(PurchaseLine, DocumentType, TaxAreaCode, TaxGroupCodeItem);
    end;

    local procedure CreatePurchaseDocumentWithCertainTax(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, CreateVendor(TaxAreaCode));
        PurchaseHeader.Validate("Invoice Discount Calculation", PurchaseHeader."Invoice Discount Calculation"::None);
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify();
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItem(TaxGroupCode),
          LibraryRandom.RandInt(10));  // Using RANDOM value for Quantity.
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify();
    end;

    local procedure CreatePurchaseDocumentWithInvDisc(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; TaxPercentage: Integer; DefaultTaxCodeOnItem: Boolean; var TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
        Vendor: Record Vendor;
        ItemNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCodeItem: Code[20];
        ItemQuantity: Decimal;
        DiscPct: Decimal;
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxPercentage);
        TaxGroupCode := TaxDetail."Tax Group Code";
        if DefaultTaxCodeOnItem then
            TaxGroupCodeItem := TaxGroupCode;
        SetupDataForDiscountTypePct(Vendor, DiscPct, TaxAreaCode, ItemNo, ItemQuantity, TaxGroupCodeItem);
        CreatePurchaseDocumentWithCertainTaxAndDisc(PurchaseLine, DocumentType, Vendor."No.", ItemNo, TaxAreaCode);
    end;

    local procedure CreatePurchaseDocumentWithCertainTaxAndDisc(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; TaxAreaCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, VendorNo);
        if IsCalcInvDiscountMarked() then
            PurchaseHeader.Validate("Invoice Discount Calculation", PurchaseHeader."Invoice Discount Calculation"::"%");
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify();

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          ItemNo,
          LibraryRandom.RandInt(10));  // Using RANDOM value for Quantity.
        Item.Get(ItemNo);
        PurchaseLine.Validate("Tax Group Code", Item."Tax Group Code");
        PurchaseLine.Modify();
    end;

    local procedure OpenPurchaseOrderPageEdit(var PurchaseOrder: TestPage "Purchase Order"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
    end;

    local procedure OpenPurchaseInvoicePageEdit(var PurchaseInvoice: TestPage "Purchase Invoice"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
    end;

    local procedure OpenPurchaseQuotePageEdit(var PurchaseQuote: TestPage "Purchase Quote"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);
    end;

    local procedure OpenPurchaseCreditMemoPageEdit(var PurchaseCreditMemo: TestPage "Purchase Credit Memo"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
    end;

    local procedure OpenBlanketPurchaseOrderPageEdit(var BlanketPurchaseOrder: TestPage "Blanket Purchase Order"; PurchaseHeader: Record "Purchase Header")
    begin
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.GotoRecord(PurchaseHeader);
    end;

    local procedure OpenPurchaseReturnOrderPageEdit(var PurchaseReturnOrder: TestPage "Purchase Return Order"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
    end;

    local procedure SetCompareAmounts(InvoiceDiscountAmount: Decimal; TotalAmountExcTax: Decimal; TaxAmount: Decimal; TotalAmountIncTax: Decimal; CustDiscountPercent: Decimal; var Amounts: array[5] of Decimal)
    var
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Amounts[FieldType::InvoiceDiscountAmount] := InvoiceDiscountAmount;
        Amounts[FieldType::TotalAmountExcTax] := TotalAmountExcTax;
        Amounts[FieldType::TaxAmount] := TaxAmount;
        Amounts[FieldType::TotalAmountIncTax] := TotalAmountIncTax;
        Amounts[FieldType::DiscountPercent] := CustDiscountPercent;
    end;

    local procedure VerifyFieldValues(PurchaseHeader: Record "Purchase Header"; PreAmounts: array[5] of Decimal; PostAmounts: array[5] of Decimal; TotalTax: Decimal; TotalDiscountPercent: Decimal; RoundingPrecision: Decimal; LineAmountUpdated: Boolean)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        if LineAmountUpdated then
            Assert.AreNotEqual(
              PreAmounts[FieldType::TotalAmountExcTax],
              PostAmounts[FieldType::TotalAmountExcTax],
              'Before and after amounts for Total Amount Excluding Tax should not be equal')
        else
            Assert.AreEqual(
              PreAmounts[FieldType::TotalAmountExcTax],
              PostAmounts[FieldType::TotalAmountExcTax],
              'Before and after amounts for Total Amount Excluding Tax should be equal');

        Assert.AreNotEqual(
          PreAmounts[FieldType::TotalAmountIncTax],
          PostAmounts[FieldType::TotalAmountIncTax],
          'Before and after amounts for Total Amount Including Tax should not be equal');
        Assert.AreNotEqual(
          PreAmounts[FieldType::TaxAmount],
          PostAmounts[FieldType::TaxAmount],
          'Before and after amounts for Tax Amount should not be equal');

        VerifyTotals(PurchaseHeader, PostAmounts, TotalTax, TotalDiscountPercent, RoundingPrecision);
    end;

    local procedure VerifyPostedFieldValues(PurchHeaderAmounts: array[5] of Decimal; PurchPostedAmounts: array[5] of Decimal)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Assert.AreEqual(PurchHeaderAmounts[FieldType::InvoiceDiscountAmount], PurchPostedAmounts[FieldType::InvoiceDiscountAmount],
          'Posted Invoice Discount Amount not equal to pre-posted value.');
        Assert.AreEqual(PurchHeaderAmounts[FieldType::TotalAmountExcTax], PurchPostedAmounts[FieldType::TotalAmountExcTax],
          'Posted Total Amount Excluding Tax not equal to pre-posted value.');
        Assert.AreEqual(PurchHeaderAmounts[FieldType::TaxAmount], PurchPostedAmounts[FieldType::TaxAmount],
          'Posted Tax Amount not equal to pre-posted value.');
        Assert.AreEqual(PurchHeaderAmounts[FieldType::TotalAmountIncTax], PurchPostedAmounts[FieldType::TotalAmountIncTax],
          'Posted Total Amount Including Tax not equal to pre-posted value.');
    end;

    local procedure VerifyTotals(PurchaseHeader: Record "Purchase Header"; PostAmounts: array[5] of Decimal; TotalTax: Decimal; TotalDiscountPercent: Decimal; RoundingPrecision: Decimal)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::InvoiceDiscountAmount],
          PurchaseHeader."Invoice Discount Amount",
          RoundingPrecision,
          'An incorrect Invoice Discount Amount was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::TotalAmountExcTax],
          PurchaseHeader.Amount,
          RoundingPrecision,
          'An incorrect Total Amount was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::TotalAmountIncTax],
          PurchaseHeader."Amount Including VAT",
          RoundingPrecision,
          'An incorrect Total Amount Including Tax was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::TaxAmount],
          TotalTax,
          RoundingPrecision,
          'An incorrect Tax Amount was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::DiscountPercent],
          TotalDiscountPercent,
          RoundingPrecision,
          'Customer Discount Percent value is incorrect');
        Assert.AreNotEqual(PostAmounts[FieldType::TaxAmount], 0,
          'The Tax Amount is zero and should not be');
    end;

    local procedure SetupCalcInvoiceDisc(var Option: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        OriginalOption: Boolean;
    begin
        PurchasesPayablesSetup.Get();
        OriginalOption := PurchasesPayablesSetup."Calc. Inv. Discount";
        PurchasesPayablesSetup.Validate("Calc. Inv. Discount", Option);
        PurchasesPayablesSetup.Modify(true);
        Option := OriginalOption;
    end;

    local procedure SetupDataForDiscountTypePct(var Vendor: Record Vendor; var DiscPct: Decimal; TaxAreaCode: Code[20]; var ItemNo: Code[20]; var ItemQuantity: Decimal; TaxGroupCode: Code[20])
    var
        MinAmt: Decimal;
        ItemUnitPrice: Decimal;
    begin
        ItemUnitPrice := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        MinAmt := LibraryRandom.RandDecInDecimalRange(ItemUnitPrice, ItemUnitPrice * 2, 2);
        DiscPct := LibraryRandom.RandDecInDecimalRange(1, 100, 2);

        ItemNo := CreateItemSpecifyUnitPrice(TaxGroupCode, ItemUnitPrice);
        CreateVendorWithDiscount(Vendor, TaxAreaCode, DiscPct, MinAmt);
    end;

    [Scope('OnPrem')]
    procedure IsCalcInvDiscountMarked(): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        exit(PurchasesPayablesSetup."Calc. Inv. Discount");
    end;

    local procedure CreateVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Create Blank VAT Posting Setup with VAT Calculation Type - Sales Tax to fix MX,CA Country failure.
        if not VATPostingSetup.Get('', '') then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, '', '');
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);
    end;
}

