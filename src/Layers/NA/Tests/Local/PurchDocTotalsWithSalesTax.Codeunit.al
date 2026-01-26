codeunit 142057 PurchDocTotalsWithSalesTax
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Document Totals] [UI] [Sales Tax]
    end;

    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        VATDifferenceErr: Label 'VAT Difference must be equal to %1', Comment = '%1 = TaxAmount value';

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchaseLine: Record "Purchase Line";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        InvDiscAmtPct: Decimal;
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        TotalTax: Decimal;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 136984] For page Mini Purchase Invoice Subform (1355) Entry
        // Setup
        Initialize();
        InvDiscAmtPct := LibraryRandom.RandDecInDecimalRange(0.01, 0.09, 1);

        // [GIVEN] User has created a purchasing document with a purchasing line containing sales tax
        LibraryLowerPermissions.SetPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Invoice, false);

        // Store away the line created, to pull back in later
        OriginalPurchaseLine := PurchaseLine;
        RoundingPrecision := 0.01;
        TaxGroupCode := OriginalPurchaseLine."Tax Group Code";

        PurchaseHeader.Get(OriginalPurchaseLine."Document Type", OriginalPurchaseLine."Document No.");
        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);
        // For purchasing, we have to set the cost of the line
        // Clear out the initial Tax Group Code
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandInt(1000));

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          0,
          PreAmounts);
        PurchaseInvoice.Close();

        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        // [WHEN] User sets the Invoice Discount Amount and Tax Group Code
        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);
        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal() * InvDiscAmtPct);
        PurchaseInvoice.Close();

        // [THEN] Total amounts match Purchase Header amounts
        // Reopen the window with the updated record
        OpenPurchaseInvoicePageView(PurchaseInvoice, PurchaseHeader);

        SetCompareAmounts(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the CustInvoiceDiscountPct
        PurchaseLine := OriginalPurchaseLine;
        PurchaseLine.Find();
        PreAmounts[FieldType::DiscountPercent] := PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine);
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax, RoundingPrecision);
        PurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoicePosting()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        OriginalPurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PurchHeaderAmounts: array[5] of Decimal;
        PurchPostedAmounts: array[5] of Decimal;
        InvDiscAmtPct: Decimal;
        PostedPurchDocNo: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Invoice] [Posting]
        // [SCENARIO 136984] For page Mini Purchase Invoice Subform (1355) Posting
        // Setup
        Initialize();
        InvDiscAmtPct := LibraryRandom.RandDecInDecimalRange(0.01, 0.09, 1);

        // [GIVEN] User has created a purchasing document with a purchasing line containing sales tax
        LibraryLowerPermissions.SetPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Invoice, false);

        // Store away the line created, to pull back in later
        OriginalPurchaseLine := PurchaseLine;
        TaxGroupCode := OriginalPurchaseLine."Tax Group Code";

        PurchaseHeader.Get(OriginalPurchaseLine."Document Type", OriginalPurchaseLine."Document No.");
        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);
        // For purchasing, we have to set the cost of the line
        // Clear out the initial Tax Group Code, defaults to a value we cannot use
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandInt(1000));
        PurchaseInvoice.Close();

        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);
        PurchaseInvoice.PurchLines.InvoiceDiscountAmount.SetValue(
          PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AsDecimal() * InvDiscAmtPct);
        PurchaseInvoice.Close();

        // Reopen the window with the updated record
        OpenPurchaseInvoicePageView(PurchaseInvoice, PurchaseHeader);

        // Calculate the CustInvoiceDiscountPct
        PurchaseLine := OriginalPurchaseLine;
        PurchaseLine.Find();
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");

        SetCompareAmounts(PurchaseHeader."Invoice Discount Amount",
          PurchaseHeader.Amount,
          PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount,
          PurchaseHeader."Amount Including VAT", 0, PurchHeaderAmounts);

        // [WHEN] User posts the Purchase Invoice
        LibraryLowerPermissions.SetPurchDocsPost();
        PostedPurchDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as invoice

        // [THEN] Posted amounts should match the pre-posted amounts
        PurchInvHeader.Get(PostedPurchDocNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        SetCompareAmounts(PurchInvHeader."Invoice Discount Amount",
          PurchInvHeader.Amount,
          PurchInvHeader."Amount Including VAT" - PurchInvHeader.Amount,
          PurchInvHeader."Amount Including VAT", 0, PurchPostedAmounts);

        VerifyPostedFieldValues(PurchHeaderAmounts, PurchPostedAmounts);
        PurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        InvDiscAmtPct: Decimal;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 136984] For page Mini Purchase Credit Memo Subform (1370) Entry
        // Setup
        Initialize();
        InvDiscAmtPct := LibraryRandom.RandDecInDecimalRange(0.01, 0.09, 1);

        // [GIVEN] User has created a purchasing document with a purchasing line containing sales tax
        LibraryLowerPermissions.SetPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", false);

        // Store away the line created, to pull back in later
        OriginalPurchaseLine := PurchaseLine;
        RoundingPrecision := 0.01;
        TaxGroupCode := OriginalPurchaseLine."Tax Group Code";

        PurchaseHeader.Get(OriginalPurchaseLine."Document Type", OriginalPurchaseLine."Document No.");
        OpenPurchaseCrMemoPageEdit(PurchaseCreditMemo, PurchaseHeader);
        // For purchasing, we have to set the cost of the line
        // Clear out the initial Tax Group Code, defaults to a value we cannot use
        PurchaseCreditMemo.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandInt(1000));

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          0,
          PreAmounts);
        PurchaseCreditMemo.Close();

        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Validate("Recalculate Invoice Disc.", false);
        PurchaseLine.Modify(true);

        // [WHEN] User sets the Invoice Discount Amount and Tax Group Code
        OpenPurchaseCrMemoPageEdit(PurchaseCreditMemo, PurchaseHeader);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal() * InvDiscAmtPct);
        PurchaseCreditMemo.Close();

        // [THEN] Total amounts match Purchase Header amounts
        // Reopen the window with the updated record
        OpenPurchaseCrMemoPageView(PurchaseCreditMemo, PurchaseHeader);

        SetCompareAmounts(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total VAT Amount".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".AsDecimal(),
          PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the CustInvoiceDiscountPct
        PurchaseLine := OriginalPurchaseLine;
        PurchaseLine.Find();
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount;

        VerifyFieldValues(PurchaseHeader, PreAmounts, PostAmounts, TotalTax, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        OriginalPurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PurchHeaderAmounts: array[5] of Decimal;
        PurchPostedAmounts: array[5] of Decimal;
        InvDiscAmtPct: Decimal;
        PostedPurchDocNo: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 136984] For page Mini Purchase Credit Memo Subform (1370) Posting
        // Setup
        Initialize();
        InvDiscAmtPct := LibraryRandom.RandDecInDecimalRange(0.01, 0.09, 1);

        // [GIVEN] User has created a purchasing document with a purchasing line containing sales tax
        LibraryLowerPermissions.SetPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", false);

        // Store away the line created, to pull back in later
        OriginalPurchaseLine := PurchaseLine;
        TaxGroupCode := OriginalPurchaseLine."Tax Group Code";

        PurchaseHeader.Get(OriginalPurchaseLine."Document Type", OriginalPurchaseLine."Document No.");
        OpenPurchaseCrMemoPageEdit(PurchaseCreditMemo, PurchaseHeader);
        // For purchasing, we have to set the cost of the line
        // Clear out the initial Tax Group Code, defaults to a value we cannot use
        PurchaseCreditMemo.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandInt(1000));
        PurchaseCreditMemo.Close();

        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        OpenPurchaseCrMemoPageEdit(PurchaseCreditMemo, PurchaseHeader);
        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(
          PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".AsDecimal() * InvDiscAmtPct);
        PurchaseCreditMemo.Close();

        // Reopen the window with the updated record
        OpenPurchaseCrMemoPageView(PurchaseCreditMemo, PurchaseHeader);

        // Calculate the CustInvoiceDiscountPct
        PurchaseLine := OriginalPurchaseLine;
        PurchaseLine.Find();
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");

        // [WHEN] User posts the Purchase Invoice
        SetCompareAmounts(PurchaseHeader."Invoice Discount Amount",
          PurchaseHeader.Amount,
          PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount,
          PurchaseHeader."Amount Including VAT", 0, PurchHeaderAmounts);

        // [THEN] Posted amounts should match the pre-posted amounts
        LibraryLowerPermissions.SetPurchDocsPost();
        PostedPurchDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as invoice

        PurchCrMemoHdr.Get(PostedPurchDocNo);
        PurchCrMemoHdr.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        SetCompareAmounts(PurchCrMemoHdr."Invoice Discount Amount",
          PurchCrMemoHdr.Amount,
          PurchCrMemoHdr."Amount Including VAT" - PurchCrMemoHdr.Amount,
          PurchCrMemoHdr."Amount Including VAT", 0, PurchPostedAmounts);

        VerifyPostedFieldValues(PurchHeaderAmounts, PurchPostedAmounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoicePostingWithExpenseTaxDetails()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        PurchaseInvoice: TestPage "Purchase Invoice";
        TaxPercent: Decimal;
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Invoice] [Expense/Capitalize]
        // [SCENARIO 312198] Tax Amount must be calculated in Document Totals when "Expense/Capitalize" is true in Tax Details
        Initialize();

        LibraryLowerPermissions.SetPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();

        // [GIVEN] Tax setup where tax detail with "Expense/Capitalize" = TRUE and "Tax Below Maximum" = 10%
        TaxPercent := LibraryRandom.RandIntInRange(10, 20);
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, true, TaxPercent);

        // [GIVEN] Purchase invoice with two lines where "Amount" = 100 in each line
        CreatePurchaseDocumentWithCertainTax(PurchaseLine, PurchaseHeader."Document Type"::Invoice, TaxDetail, TaxAreaCode);
        PurchaseLine."Line No." += 10000;
        PurchaseLine.Insert();

        // [WHEN] Open Purchase Invoice card page
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);

        // [THEN] "Total Amoun Excl. Tax" = 200
        // [THEN] "Total Tax" = (200 * 10%) = 20;
        // [THEN] "Total Amoun Incl. Tax" = 220
        PurchaseLine.TestField(Amount);
        PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AssertEquals(Round(2 * PurchaseLine.Amount));
        PurchaseInvoice.PurchLines."Total VAT Amount".AssertEquals(Round(2 * PurchaseLine.Amount * TaxPercent / 100));
        PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AssertEquals(Round(2 * PurchaseLine.Amount * (100 + TaxPercent) / 100));
        PurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithExciseTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        PurchaseInvoice: TestPage "Purchase Invoice";
        TaxPercent: Decimal;
        TaxAreaCode: Code[20];
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxGroup: Record "Tax Group";
        Item: Record Item;
        VendorCreated: Code[20];
        ItemCreated: Code[20];
    begin
        // The following verifies excise tax when there is no unit cost or amount per line.  Bug 313016 reported by customer.
        Initialize();

        LibraryLowerPermissions.SetPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();

        // Create excise tax to be used by purchase invoice
        TaxPercent := LibraryRandom.RandIntInRange(10, 20);
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxDetail."Tax Type"::"Excise Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxPercent);
        TaxDetail.Validate("Expense/Capitalize", false);
        TaxDetail.Modify(true);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");

        VendorCreated := CreateVendor(TaxAreaCode);
        ItemCreated := CreateItem(TaxDetail."Tax Group Code");
        Item.Get(ItemCreated);
        Item.Modify(true);

        // Create purchase invoice and assign tax area
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorCreated);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader."Tax Area Code" := TaxArea.Code;
        PurchaseHeader."Tax Liable" := true;
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine,
          PurchaseHeader, PurchaseLine.Type::Item, ItemCreated, LibraryRandom.RandInt(10));
        PurchaseLine."Line No." += 10000;
        PurchaseLine.Insert();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);

        // Verify amounts:  "Total Amoun Excl. Tax" = 0, "Total VAT Amount" and "Total Amount Incl. VAT" = (2 * quantity * excise tax amount)
        PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AssertEquals(0);
        PurchaseInvoice.PurchLines."Total VAT Amount".AssertEquals(Round(2 * PurchaseLine.Quantity * TaxPercent));
        PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AssertEquals(0 + 2 * PurchaseLine.Quantity * TaxPercent);
        PurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithExciseTaxPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        PurchaseInvoice: TestPage "Purchase Invoice";
        TaxPercent: Decimal;
        TaxAreaCode: Code[20];
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxGroup: Record "Tax Group";
        Item: Record Item;
        VendorCreated: Code[20];
        ItemCreated: Code[20];
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchDocNo: Code[20];
        Assert: Codeunit Assert;
    begin
        // The following verifies the posting of excise tax when there is no unit cost or amount per line.  Bug 313016 reported by customer.
        Initialize();

        LibraryLowerPermissions.SetPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();

        // Create excise tax to be used by purchase invoice
        TaxPercent := LibraryRandom.RandIntInRange(10, 20);
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxDetail."Tax Type"::"Excise Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxPercent);
        TaxDetail.Validate("Expense/Capitalize", false);
        TaxDetail.Modify(true);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");

        VendorCreated := CreateVendor(TaxAreaCode);
        ItemCreated := CreateItem(TaxDetail."Tax Group Code");
        Item.Get(ItemCreated);
        Item.Modify(true);

        // Create purchase invoice and assign tax area
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorCreated);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader."Tax Area Code" := TaxArea.Code;
        PurchaseHeader."Tax Liable" := true;
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine,
          PurchaseHeader, PurchaseLine.Type::Item, ItemCreated, LibraryRandom.RandInt(10));
        PurchaseLine."Line No." += 10000;
        PurchaseLine.Insert();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        OpenPurchaseInvoicePageEdit(PurchaseInvoice, PurchaseHeader);

        // Verify amounts:  "Total Amoun Excl. Tax" = 0, "Total VAT Amount" and "Total Amount Incl. VAT" = (2 * quantity * excise tax amount) 
        PurchaseHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AssertEquals(0);
        PurchaseInvoice.PurchLines."Total VAT Amount".AssertEquals(Round(2 * PurchaseLine.Quantity * TaxPercent));
        PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AssertEquals(0 + 2 * PurchaseLine.Quantity * TaxPercent);
        Assert.AreEqual(0, PurchaseHeader.Amount, 'PurchaseHeader.Amount is incorrect');
        Assert.AreEqual(2 * PurchaseLine.Quantity * TaxPercent, PurchaseHeader."Amount Including VAT", 'PurchaseHeader."Amount Including VAT" is incorrect');
        PurchaseInvoice.Close();

        // Post invoice and verify amounts
        LibraryLowerPermissions.SetPurchDocsPost();
        PostedPurchDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvHeader.Get(PostedPurchDocNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        Assert.AreEqual(0, PurchInvHeader.Amount, 'PurchaseHeader.Amount is incorrect');
        Assert.AreEqual(2 * PurchaseLine.Quantity * TaxPercent, PurchInvHeader."Amount Including VAT", 'PurchaseHeader."Amount Including VAT" is incorrect');
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatsUpdateTaxAmountModalPageHandler,ConfirmHandlerYes')]
    procedure PostPurchInvoiceTaxLiableWithIncomingDocAndTaxDifference()
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        TaxDifference: Decimal;
    begin
        // [FEATURE] [Incoming Document] [Purchase]
        // [SCENARIO 409746] Post Purchase Invoice with linked Incoming Document after Tax Amount is corrected according to Incoming Document.
        Initialize();
        LibraryApplicationArea.EnableSalesTaxSetup();   // for MX

        // [GIVEN] Allowed Max Tax Difference = 10.
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibraryPurchase.SetAllowVATDifference(true);

        // [GIVEN] Tax Area "T" with Tax Detail that has "Tax Below Maximum" = 10%. 
        // [GIVEN] Vendor with Tax Area "T", Tax Liable = true.
        // [GIVEN] Purchase Invoice with Tax Area "T" that has Amount Incl. VAT = 500 and Tax Amount = 50.
        // [GIVEN] Incoming Document with Amount Incl. VAT = 505 and Tax Amount = 55. Document is linked to Purchase Invoice.
        CreatePurchaseDocument(PurchaseLine, "Purchase Document Type"::Invoice, false);
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        UpdateIncomingDocEntryNoOnPurchaseInvoice(PurchaseLine."Document No.", IncomingDocument."Entry No.");
        TaxDifference := 5;
        UpdateAmountInclVATOnIncomingDoc(IncomingDocument, PurchaseLine."Amount Including VAT" + TaxDifference);

        // [GIVEN] Tax Amount for Puchase Invoice is updated from 50 to 55 on Purchase Invoice Statistics page.
        LibraryVariableStorage.Enqueue(TaxDifference);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseLine."Document No.");
        PurchaseInvoice.Statistics.Invoke();
        PurchaseInvoice.Close();

        // [WHEN] Post Purchase Invoice.
        PostPurchaseInvoiceFromPage(PurchaseLine."Document No.");

        // [THEN] Purchase Invoice was posted. Amount Incl. VAT = 505.
        VerifyAmountInclVATOnPostedPurchaseInvoice(PurchaseLine."Document No.", IncomingDocument."Amount Incl. VAT");

        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatsUpdateTaxAmountPageHandler,ConfirmHandlerYes')]
    procedure PostPurchaseInvoiceTaxLiableWithIncomingDocAndTaxDifference()
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        TaxDifference: Decimal;
    begin
        // [FEATURE] [Incoming Document] [Purchase]
        // [SCENARIO 409746] Post Purchase Invoice with linked Incoming Document after Tax Amount is corrected according to Incoming Document.
        Initialize();

        LibraryApplicationArea.EnableSalesTaxSetup();   // for MX

        // [GIVEN] Allowed Max Tax Difference = 10.
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibraryPurchase.SetAllowVATDifference(true);

        // [GIVEN] Tax Area "T" with Tax Detail that has "Tax Below Maximum" = 10%. 
        // [GIVEN] Vendor with Tax Area "T", Tax Liable = true.
        // [GIVEN] Purchase Invoice with Tax Area "T" that has Amount Incl. VAT = 500 and Tax Amount = 50.
        // [GIVEN] Incoming Document with Amount Incl. VAT = 505 and Tax Amount = 55. Document is linked to Purchase Invoice.
        CreatePurchaseDocument(PurchaseLine, "Purchase Document Type"::Invoice, false);
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        UpdateIncomingDocEntryNoOnPurchaseInvoice(PurchaseLine."Document No.", IncomingDocument."Entry No.");
        TaxDifference := 5;
        UpdateAmountInclVATOnIncomingDoc(IncomingDocument, PurchaseLine."Amount Including VAT" + TaxDifference);

        // [GIVEN] Tax Amount for Puchase Invoice is updated from 50 to 55 on Purchase Invoice Statistics page.
        LibraryVariableStorage.Enqueue(TaxDifference);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseLine."Document No.");
        PurchaseInvoice.PurchaseStats.Invoke();

        // [WHEN] Post Purchase Invoice.
        PostPurchaseInvoiceFromPage(PurchaseLine."Document No.");

        // [THEN] Purchase Invoice was posted. Amount Incl. VAT = 505.
        VerifyAmountInclVATOnPostedPurchaseInvoice(PurchaseLine."Document No.", IncomingDocument."Amount Incl. VAT");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PurchaseStatsPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure VATDiffInVATEntryIsEqualToTaxAmtOfSalesTaxAmtLineInPurchInvStatsWhenPostPurchInv()
    var
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        PurchaseInvoice: TestPage "Purchase Invoice";
        TaxAmount: Decimal;
    begin
        // [SCENARIO 555978] "VAT Difference" in VAT Entry is equal to "TAX Amount" of Purchase Statistics 
        // when post Purchase Invoice having "Currency Code" and Allow VAT Difference is set in 
        // General Ledger Setup and Purchases & Payables Setup.
        Initialize();

        // [GIVEN] Enable Sales Tax Setup.
        LibraryApplicationArea.EnableSalesTaxSetup();

        // [GIVEN] Set Max VAT Difference Allowed.
        LibraryERM.SetMaxVATDifferenceAllowed(LibraryRandom.RandIntInRange(500, 500));
        LibraryPurchase.SetAllowVATDifference(true);

        // [GIVEN] Create a Purchase Invoice and Validate "Currency Code".
        CreatePurchaseDocument(PurchaseLine, "Purchase Document Type"::Invoice, false);
        PurchaseLine.Validate("Currency Code", CreateCurrencyWithExchRate());
        PurchaseLine.Modify(true);

        // [GIVEN] Open Purchase Invoice page and run Purchase Stats action.
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseLine."Document No.");
        PurchaseInvoice.PurchaseStats.Invoke();

        // [GIVEN] Post Purchase Invoice.
        PostPurchaseInvoiceFromPage(PurchaseLine."Document No.");

        // [GIVEN] Generate and save "Tax Amount" from Purchase Statistics in a Vraiable.
        TaxAmount := -LibraryVariableStorage.DequeueDecimal();

        // [WHEN] Find VAT Entry.
        VATEntry.SetRange("Tax Area Code", PurchaseLine."Tax Area Code");
        VATEntry.FindFirst();

        // [THEN] "VAT Difference" in VAT Entry is equal to TaxAmount.
        Assert.AreEqual(TaxAmount, VATEntry."VAT Difference", VATDifferenceErr);
    end;

    [Test]
    procedure PurchaseInvoiceWithAllocationAccountsAndTaxDifference()
    var
        AllocationAccount: Record "Allocation Account";
        BalancingGLAccount: Record "G/L Account";
        BreakdownGLAccount: array[3] of Record "G/L Account";
        DestinationGLAccount: Record "G/L Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        TaxDetail: Record "Tax Detail";
    begin
        // [SCENARIO 555978] Purchase Invoice with Allocation Accounts and Tax Difference is posted.
        Initialize();

        // [GIVEN] Max VAT Difference Allowed is updated in General Ledger Setup.
        GeneralLedgerSetup.GetRecordOnce();
        GeneralLedgerSetup.Validate("Max. VAT Difference Allowed", LibraryRandom.RandIntInRange(5, 10));
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Allow VAT Difference is set in Purchases & Payables Setup.
        PurchasesPayablesSetup.GetRecordOnce();
        PurchasesPayablesSetup.Validate("Allow VAT Difference", true);
        PurchasesPayablesSetup.Modify(true);

        // [GIVEN] Create Tax Detail with "Expense/Capitalize" = false and "Tax Rate".
        CreateTaxAreaLine(TaxDetail, false, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(BreakdownGLAccount[1], BreakdownGLAccount[2], BreakdownGLAccount[3]);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());

        // [GIVEN] Create Allocation Account with Fixed GL Distributions.
        CreateAllocationAccountwithFixedGLDistributions(AllocationAccount);
        AllocationAccount."Document Lines Split" := AllocationAccount."Document Lines Split"::"Split Quantity";
        AllocationAccount.Modify();

        // [GIVEN] Create Purchase Invoice with Allocation Account and Tax Difference.
        CreatePurchaseInvoiceWithTaxDetail(PurchaseHeader, AllocationAccount."No.");

        // [WHEN] Post Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posted Purchase Invoice is created with Allocation Account and Tax Difference.
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchInvHeader.FindFirst();
        Assert.RecordIsNotEmpty(PurchInvHeader);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        TaxSetup: Record "Tax Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup();

        if isInitialized then
            exit;

        PurchasesPayablesSetup.Get('');
        PurchasesPayablesSetup."Invoice Rounding" := false;
        PurchasesPayablesSetup.Modify();

        LibraryERMCountryData.CreateVATData();

        TaxSetup.DeleteAll();
        TaxSetup.Init();
        TaxSetup.Insert();

        if not VATPostingSetup.Get('', '') then begin
            VATPostingSetup."VAT Bus. Posting Group" := '';
            VATPostingSetup."VAT Prod. Posting Group" := '';
            VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Sales Tax";
            VATPostingSetup.Insert(true);
        end;

        LibraryInventory.NoSeriesSetup(InventorySetup);

        isInitialized := true;
        Commit();
    end;

    local procedure CreateItem(TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", '');
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Validate("Unit Price", LibraryRandom.RandInt(10));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ExpenseCapitalize: Boolean)
    var
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, ExpenseCapitalize, LibraryRandom.RandIntInRange(10, 20));
        CreatePurchaseDocumentWithCertainTax(PurchaseLine, DocumentType, TaxDetail, TaxAreaCode);
    end;

    local procedure CreatePurchaseDocumentWithCertainTax(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; TaxDetail: Record "Tax Detail"; TaxAreaCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        VendorCreated: Code[20];
        ItemCreated: Code[20];
    begin
        VendorCreated := CreateVendor(TaxAreaCode);
        ItemCreated := CreateItem(TaxDetail."Tax Group Code");
        Item.Get(ItemCreated);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(1000));
        Item.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorCreated);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader."Tax Area Code" := TaxAreaCode;
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine,
          PurchaseHeader, PurchaseLine.Type::Item, ItemCreated, LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail"; ExpenseCapitalize: Boolean; TaxPercent: Decimal)
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax Only", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxPercent);
        TaxDetail.Validate("Expense/Capitalize", ExpenseCapitalize);
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

    local procedure CreateTaxAreaLine(var TaxDetail: Record "Tax Detail"; ExpenseCapitalize: Boolean; TaxPercent: Decimal): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        CreateSalesTaxDetail(TaxDetail, ExpenseCapitalize, TaxPercent);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        exit(TaxArea.Code);
    end;

    local procedure CreateVendor(TaxAreaCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", '');
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure OpenPurchaseInvoicePageEdit(var PurchaseInvoice: TestPage "Purchase Invoice"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");
    end;

    local procedure OpenPurchaseCrMemoPageEdit(var PurchaseCreditMemo: TestPage "Purchase Credit Memo"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", PurchaseHeader."No.");
    end;

    local procedure OpenPurchaseInvoicePageView(var PurchaseInvoice: TestPage "Purchase Invoice"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseInvoice.OpenView();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");
    end;

    local procedure OpenPurchaseCrMemoPageView(var PurchaseCreditMemo: TestPage "Purchase Credit Memo"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.FILTER.SetFilter("No.", PurchaseHeader."No.");
    end;

    local procedure PostPurchaseInvoiceFromPage(PurchaseInvoiceNo: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseInvoiceNo);
        PurchaseInvoice.Post.Invoke();
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

    local procedure UpdateAmountInclVATOnIncomingDoc(var IncomingDocument: Record "Incoming Document"; AmountInclVAT: Decimal)
    begin
        IncomingDocument."Amount Incl. VAT" := AmountInclVAT;
        IncomingDocument.Modify();
    end;

    local procedure UpdateIncomingDocEntryNoOnPurchaseInvoice(PurchaseInvoiceNo: Code[20]; IncomingDocEntryNo: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get("Purchase Document Type"::Invoice, PurchaseInvoiceNo);
        PurchaseHeader.Validate("Incoming Document Entry No.", IncomingDocEntryNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyFieldValues(PurchaseHeader: Record "Purchase Header"; PreAmounts: array[5] of Decimal; PostAmounts: array[5] of Decimal; TotalTax: Decimal; RoundingPrecision: Decimal)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        DiscPct: Decimal;
    begin
        Assert.AreNotEqual(PreAmounts[FieldType::TotalAmountExcTax], PostAmounts[FieldType::TotalAmountExcTax],
          'Before and after amounts for Total Amount excluding Tax should not be equal');

        Assert.AreNotEqual(PreAmounts[FieldType::TotalAmountIncTax], PostAmounts[FieldType::TotalAmountIncTax],
          'Before and after amounts for Total Amount including Tax should not be equal');

        Assert.AreNotEqual(PreAmounts[FieldType::TaxAmount], PostAmounts[FieldType::TaxAmount],
          'Before and after amounts for Tax Amount should not be equal');

        // Assert.AreNotEqual(PreAmounts[FieldType::DiscountPercent],PostAmounts[FieldType::DiscountPercent],
        // 'Before and adter amounts for Customer Discount Percent should not be equal');

        Assert.AreNearlyEqual(PostAmounts[FieldType::InvoiceDiscountAmount], PurchaseHeader."Invoice Discount Amount",
          RoundingPrecision, 'An incorrect Invoice Discount Amount was saved');

        Assert.AreNearlyEqual(PostAmounts[FieldType::TotalAmountExcTax], PurchaseHeader.Amount,
          RoundingPrecision, 'An incorrect Total Amount was saved');

        Assert.AreNearlyEqual(PostAmounts[FieldType::TotalAmountIncTax], PurchaseHeader."Amount Including VAT",
          RoundingPrecision, 'An incorrect Total Amount Including Tax was saved');

        Assert.AreNearlyEqual(PostAmounts[FieldType::TaxAmount], TotalTax,
          RoundingPrecision, 'An incorrect Tax Amount was saved');

        DiscPct := PurchaseHeader."Invoice Discount Amount" * 100 / (PurchaseHeader.Amount + PurchaseHeader."Invoice Discount Amount");
        Assert.AreNearlyEqual(PostAmounts[FieldType::DiscountPercent], DiscPct,
          RoundingPrecision, 'Customer Discount Percent value is incorrect');
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

    local procedure VerifyAmountInclVATOnPostedPurchaseInvoice(PurchaseInvoiceNo: Code[20]; ExpectedAmountInclVAT: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseInvoiceNo);
        PurchInvHeader.FindFirst();
        PurchInvHeader.CalcFields("Amount Including VAT");
        Assert.AreEqual(ExpectedAmountInclVAT, PurchInvHeader."Amount Including VAT", '');
    end;

    local procedure CreateCurrencyWithExchRate(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Max. VAT Difference Allowed", LibraryRandom.RandIntInRange(500, 500));
        Currency.Modify(true);

        LibraryERM.CreateRandomExchangeRate(Currency.Code);

        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();

        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandIntInRange(1, 1));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDecInDecimalRange(0.5, 0.5, 0));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", LibraryRandom.RandIntInRange(1, 1));
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", LibraryRandom.RandDecInDecimalRange(0.5, 0.5, 0));
        CurrencyExchangeRate.Modify(true);

        exit(Currency.Code);
    end;

    local procedure CreateBreakdownAccountsWithBalances(var FirstBreakdownGLAccount: Record "G/L Account"; var SecondBreakdownGLAccount: Record "G/L Account"; var ThirdBreakdownGLAccount: Record "G/L Account")
    begin
        FirstBreakdownGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        CreateBalanceForGLAccount(LibraryRandom.RandIntInRange(100, 100), FirstBreakdownGLAccount, 0);

        SecondBreakdownGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        CreateBalanceForGLAccount(LibraryRandom.RandIntInRange(200, 200), SecondBreakdownGLAccount, 0);

        ThirdBreakdownGLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        CreateBalanceForGLAccount(LibraryRandom.RandIntInRange(300, 300), ThirdBreakdownGLAccount, 0);
    end;

    local procedure CreateAllocationAccountwithFixedGLDistributions(var AllocationAccount: Record "Allocation Account")
    var
        AllocationAccountPage: TestPage "Allocation Account";
        FixedAllocationAccountCode: Code[20];
    begin
        FixedAllocationAccountCode := CreateAllocationAccountWithFixedDistribution(AllocationAccountPage);
        AllocationAccount.Get(FixedAllocationAccountCode);
    end;

    local procedure CreateAllocationAccountWithFixedDistribution(var AllocationAccountPage: TestPage "Allocation Account"): Code[20]
    var
        DummyAllocationAccount: Record "Allocation Account";
        AllocationAccountNo: Code[20];
    begin
        AllocationAccountPage.OpenNew();
        AllocationAccountNo := LibraryUtility.GenerateGUID();

        AllocationAccountPage."No.".SetValue(AllocationAccountNo);
        AllocationAccountPage."Account Type".SetValue(DummyAllocationAccount."Account Type"::Fixed);
        AllocationAccountPage.Name.SetValue(LibraryRandom.RandText(5));
        exit(AllocationAccountNo);
    end;

    local procedure CreatePurchaseInvoiceWithTaxDetail(var PurchaseHeader: Record "Purchase Header"; AllocationAccountNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxGroup: Record "Tax Group";
        VendorCreated: Code[20];
        ItemCreated: Code[20];
        TaxPercent: Decimal;
    begin
        TaxPercent := LibraryRandom.RandIntInRange(10, 20);
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxDetail."Tax Type"::"Excise Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxPercent);
        TaxDetail.Validate("Expense/Capitalize", false);
        TaxDetail.Modify(true);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");

        VendorCreated := CreateVendor(TaxArea.Code);
        ItemCreated := CreateItem(TaxDetail."Tax Group Code");

        // Create purchase invoice and assign tax area
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorCreated);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader."Tax Area Code" := TaxArea.Code;
        PurchaseHeader."Tax Liable" := true;
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader,
            PurchaseLine.Type::Item,
            ItemCreated,
            LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Allocation Account No.", AllocationAccountNo);
        PurchaseLine.Validate(Amount, (PurchaseLine.Amount - LibraryRandom.RandIntInRange(1, 1)));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateBalanceForGLAccount(Balance: Decimal; var GLAccount: Record "G/L Account"; DimensionSetID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", Balance);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Dimension Set ID", DimensionSetID);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    procedure PurchaseStatsUpdateTaxAmountModalPageHandler(var PurchaseStats: TestPage "Purchase Stats.")
    var
        TaxDifference: Decimal;
        NewTaxAmount: Decimal;
    begin
        TaxDifference := LibraryVariableStorage.DequeueDecimal();
        NewTaxAmount := PurchaseStats.SubForm."Tax Amount".AsDecimal() + TaxDifference;
        PurchaseStats.SubForm."Tax Amount".SetValue(NewTaxAmount);
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatsUpdateTaxAmountPageHandler(var PurchaseStats: TestPage "Purchase Stats.")
    var
        TaxDifference: Decimal;
        NewTaxAmount: Decimal;
    begin
        TaxDifference := LibraryVariableStorage.DequeueDecimal();
        NewTaxAmount := PurchaseStats.SubForm."Tax Amount".AsDecimal() + TaxDifference;
        PurchaseStats.SubForm."Tax Amount".SetValue(NewTaxAmount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatsPageHandler(var PurchaseStats: TestPage "Purchase Stats.")
    begin
        PurchaseStats.SubForm."Tax Amount".SetValue(PurchaseStats.TaxAmount.AsDecimal() / LibraryRandom.RandIntInRange(2, 2));
        LibraryVariableStorage.Enqueue(PurchaseStats.SubForm."Tax Amount".AsDecimal());
        PurchaseStats.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

