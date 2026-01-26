codeunit 141442 "ERM Sales Prepmt. Include Tax"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Prepayment]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure DisableInclTaxAfterPrepmtInv()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        PrepareSOwithPostedPrepmtInv(SalesHeader, SalesLine, 1, FindTaxAreaCode(), FindItem(), true);

        asserterror SalesHeader.Validate("Prepmt. Include Tax", false);
        Assert.ExpectedError(StrSubstNo('You cannot change %1', SalesHeader.FieldCaption("Prepmt. Include Tax")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SecondPrepmtInvPostingInclTax()
    begin
        SecondPrepmtInvPosting(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SecondPrepmtInvPostingExclTax()
    begin
        SecondPrepmtInvPosting(false);
    end;

    local procedure SecondPrepmtInvPosting(IncludeTax: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstPrepmtInvNo: Code[20];
    begin
        PrepareSOwithPostedPrepmtInv(SalesHeader, SalesLine, 1, FindTaxAreaCode(), FindItem(), IncludeTax);
        FirstPrepmtInvNo := SalesHeader."Last Prepayment No.";
        DoubleQuantityInLines(SalesHeader);

        PostSalesPrepmtInvoice(SalesHeader);

        Assert.AreNotEqual(FirstPrepmtInvNo, SalesHeader."Last Prepayment No.", 'New Prepmt Invoice No. exepected');
        VerifyPrepmtAmountsInLines(SalesHeader);
    end;

    local procedure ReopenSalesOrder(var SalesHeader: Record "Sales Header")
    var
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        ReleaseSalesDoc.PerformManualReopen(SalesHeader);
    end;

    local procedure DoubleQuantityInLines(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        ReopenSalesOrder(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        repeat
            SalesLine.Validate(Quantity, 2 * SalesLine.Quantity);
            SalesLine.Validate("Line Discount %", 0);
            SalesLine.Modify();
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyPrepmtAmountsInLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        repeat
            SalesLine.TestField("Line Amount", SalesLine."Prepmt. Line Amount");
            SalesLine.TestField("Prepmt. Line Amount", SalesLine."Prepmt. Amt. Inv.");
        until SalesLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiLineInvPartRoundErr()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        CreateTaxAreaGroupWithSpecialValues(TaxAreaCode, TaxGroupCode, 3, 2);
        PrepareSOwithPostedPrepmtInv(SalesHeader, SalesLine, 3, TaxAreaCode, CreateItemWithTaxGroup(TaxGroupCode), true);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.Validate("Qty. to Ship", 1);
        SalesLine.Modify();

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VerifyZeroCustomerAccEntry();
        // no rounding entry failures after fix 277059
        VerifyInvRoundingEqualToRoundingPrecision(SalesHeader."Bill-to Customer No.", SalesHeader."Customer Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiLineOrderPartLCYTFS323743()
    var
        SalesHeader: Record "Sales Header";
    begin
        MultiLineOrderPartTFS323743(SalesHeader);
        VerifyZeroCustomerAccEntry();
    end;

    local procedure MultiLineOrderPartTFS323743(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader."Prepmt. Include Tax" := true;
        PrepareSOwithPostedPrepmtInv(SalesHeader, SalesLine, 3, FindTaxAreaCode(), FindItem(), true);
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", SalesLine."Qty. to Ship" - 1);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyZeroCustomerAccEntry();

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiLineOrderLCYTFS323742()
    var
        SalesHeader: Record "Sales Header";
    begin
        MultiLineOrderTFS323742(SalesHeader);
        VerifyZeroCustomerAccEntry();
    end;

    local procedure MultiLineOrderTFS323742(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader."Prepmt. Include Tax" := true;
        PrepareSOwithPostedPrepmtInv(SalesHeader, SalesLine, 3, FindTaxAreaCode(), FindItem(), true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialShptInvOfOrderWith100PctPrepmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Prepmt. Include Tax] [100% Prepayment]
        // [SCENARIO 371956] Zero Cust. Ledg Entry should be posted for partial "ship and invoice" of Order with 100% prepayment

        // [GIVEN] Sales Order in LCY, where "Prepmt. Include Tax" = Yes
        SalesHeader."Prepmt. Include Tax" := true;
        // [GIVEN] Order contains 3 lines, where "Prepayment %" = 100
        // [GIVEN] 1st Line with "Line Amount" = 29.93, "Amount Including VAT" = 31.42
        // [GIVEN] 2nd and 3rd Line with "Line Amount" = 29.93, "Amount Including VAT" = 31.43
        // [GIVEN] Posted Prepayment Invoice
        CreateTaxAreaGroupWithSpecialValues(TaxAreaCode, TaxGroupCode, 3, 2);
        PrepareSOwithPostedPrepmtInv(SalesHeader, SalesLine, 3, TaxAreaCode, CreateItemWithTaxGroup(TaxGroupCode), true);
        // [GIVEN] Set "Quantity to Ship" = 0 for lines except the 1st one
        FindSalesLine(SalesLine, SalesLine."Document Type", SalesLine."Document No.");
        SalesLine.SetFilter("Line No.", '>%1', SalesLine."Line No.");
        SalesLine.FindSet();
        repeat
            SalesLine.Validate("Qty. to Ship", 0);
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;

        // [WHEN] Ship and Invoice the 1st line
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Cust. Ledger Entry is posted where Amount = 0
        VerifyZeroCustomerAccEntry();
        // [THEN] No Invoice Rounding G/L Entry is posted after fix 277059
        // failed before the fix for TFS200992
        VerifyInvRoundingEqualToRoundingPrecision(SalesHeader."Bill-to Customer No.", SalesHeader."Customer Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Scenario55698LCYExclTax()
    var
        SalesHeader: Record "Sales Header";
    begin
        Scenario55698(SalesHeader, false);
        asserterror VerifyZeroCustomerAccEntry();
        Assert.ExpectedError('Expected zero Customer Ledger Entry');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Scenario55698LCYInclTax()
    var
        SalesHeader: Record "Sales Header";
    begin
        Scenario55698(SalesHeader, true);
        VerifyZeroCustomerAccEntry();
    end;

    local procedure Scenario55698(SalesHeader: Record "Sales Header"; PrepmtInclTax: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        PrepareSOwithPostedPrepmtInv(SalesHeader, SalesLine, 1, FindTaxAreaCode(), FindItem(), PrepmtInclTax);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPostOrderLCYExcludeTax()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        Qty: array[2] of Decimal;
        UnitPrice: array[2] of Decimal;
        SalesInv1: Code[20];
        SalesInv2: Code[20];
        SalesInv3: Code[20];
        GLAccFilter: Text;
    begin
        // [SCENARIO 277059] Post partial invoice with two tax details and 100 pct prepayment when "Prepmt. Include Tax" = FALSE

        // [GIVEN] Tax Details for two tax jurisdiction with 5 and 9.975 %
        CreateTaxAreaGroupWithSpecialValues(TaxAreaCode, TaxGroupCode, 5, 9.975);

        // [GIVEN] Sales Order with "Prepmt. Include Tax" = FALSE
        // [GIVEN] First line of Qty = 4, Unit Price = 1503.4 and Amount Incl VAT = 6914.13
        // [GIVEN] Second line of Qty = 3, Unit Price = 500.00 and Amount Incl VAT = 1724.63
        // [GIVEN] 100 % prepayment is posted for the sales order
        SetupLineValues(Qty[1], UnitPrice[1], 4, 1503.4);
        SetupLineValues(Qty[2], UnitPrice[2], 3, 500.0);
        PrepareSOwithPostedPrepmtInvMultiLines(
          SalesHeader, SalesLine, Qty, UnitPrice, 2, TaxAreaCode, TaxGroupCode, 100, false);

        // [GIVEN] Second sales line is totally posted
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);
        SalesInv1 := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] First sales line is posted with Qty = 2
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Modify(true);
        SalesInv2 := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run final posting for the first line with Qty = 2
        SalesInv3 := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Tax Amount 224.63 is posted for first document, posted sales invoice has Amount = 0 and Amount Incl VAT = 224.63
        // [THEN] Tax Amount 450.27 is posted for second document, posted sales invoice has Amount = 0 and Amount Incl VAT = 450.27
        // [THEN] Tax Amount 450.26 is posted for last document, posted sales invoice has Amount = 0 and Amount Incl VAT = 450.26
        GLAccFilter := GetGLAccountFromTaxJurisdiction(TaxGroupCode);
        VerifyPostedSalesEntries(SalesInv1, GLAccFilter, 1500.0 * 2, 224.63, 0, 224.63);
        VerifyPostedSalesEntries(SalesInv2, GLAccFilter, 3006.8 * 2, 450.26, 0, 450.26);
        VerifyPostedSalesEntries(SalesInv3, GLAccFilter, 3006.8 * 2, 450.27, 0, 450.27);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPostOrderLCYIncludelTax()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        Qty: array[2] of Decimal;
        UnitPrice: array[2] of Decimal;
        SalesInv1: Code[20];
        SalesInv2: Code[20];
        SalesInv3: Code[20];
        GLAccFilter: Text;
    begin
        // [SCENARIO 277059] Post partial invoice with two tax details and 100 pct prepayment when "Prepmt. Include Tax" = TRUE

        // [GIVEN] Tax Details for two tax jurisdiction with 5 and 9.975 %
        CreateTaxAreaGroupWithSpecialValues(TaxAreaCode, TaxGroupCode, 5, 9.975);

        // [GIVEN] Sales Order with "Prepmt. Include Tax" = TRUE
        // [GIVEN] First line of Qty = 4, Unit Price = 1503.4 and Amount Incl VAT = 6914.13
        // [GIVEN] Second line of Qty = 3, Unit Price = 500.00 and Amount Incl VAT = 1724.63
        // [GIVEN] 100 % prepayment is posted for the sales order
        SetupLineValues(Qty[1], UnitPrice[1], 4, 1503.4);
        SetupLineValues(Qty[2], UnitPrice[2], 3, 500.0);
        PrepareSOwithPostedPrepmtInvMultiLines(
          SalesHeader, SalesLine, Qty, UnitPrice, 2, TaxAreaCode, TaxGroupCode, 100, true);

        // [GIVEN] Second sales line is totally posted
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);
        SalesInv1 := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] First sales line is posted with Qty = 2
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Modify(true);
        SalesInv2 := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run final posting for the first line with Qty = 2
        SalesInv3 := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Tax Amount 224.63 is posted for first document, posted sales invoice has Amount = -224.63 and Amount Incl VAT = 0
        // [THEN] Tax Amount 450.27 is posted for second document, posted sales invoice has Amount = -450.27 and Amount Incl VAT = 0
        // [THEN] Tax Amount 450.26 is posted for last document, posted sales invoice has Amount = -450.26 and Amount Incl VAT = 0
        GLAccFilter := GetGLAccountFromTaxJurisdiction(TaxGroupCode);
        VerifyPostedSalesEntries(SalesInv1, GLAccFilter, 1500.0 * 2, 224.63, -224.63, 0);
        VerifyPostedSalesEntries(SalesInv2, GLAccFilter, 3006.8 * 2, 450.26, -450.26, 0);
        VerifyPostedSalesEntries(SalesInv3, GLAccFilter, 3006.8 * 2, 450.27, -450.27, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RepostingSalesOrderWithPrepayment100()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
    begin
        // [FEATURE] [Prepmt. Include Tax] [100% Prepayment]
        // [SCENARIO 307233] Posting reopened Sales order with added Sales Line for Amount "X" results in posted Sales Invoice with Amount "X".

        // [GIVEN] Tax Details for tax jurisdiction with 5 %.
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxGroup(TaxGroup);
        CreateTaxAreaSetupWithValues(TaxDetail, TaxArea.Code, TaxGroup.Code, 5);

        // [GIVEN] Posted Sales Order with "Prepmt. Include Tax" = TRUE and "Prepayment %" = 100.
        // [GIVEN] Sales Line of "Unit Price" = 500.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithTaxArea(TaxArea.Code));
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Validate("Prepmt. Include Tax", true);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithTaxGroup(TaxGroup.Code), 1);
        SalesLine.Validate("Unit Price", 500);
        SalesLine.Modify(true);
        PostSalesPrepmtInvoice(SalesHeader);

        // [GIVEN] Sales Order Reopened and second Sales Line added with "Unit Price" = 300.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithTaxGroup(TaxGroup.Code), 1);
        SalesLine.Validate("Unit Price", 300);
        SalesLine.Modify(true);

        // [WHEN] Sales Order posted.
        PostSalesPrepmtInvoice(SalesHeader);

        // [THEN] Resulting posted Sales Invoice has Amount equal to 315.
        SalesInvoiceHeader.Get(SalesHeader."Last Prepayment No.");
        SalesInvoiceHeader.CalcFields(Amount);
        Assert.AreEqual(SalesLine."Amount Including VAT", SalesInvoiceHeader.Amount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmtInclVATOnSalesOrderWithPremptAdjustedOnlyOnPosting()
    var
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        AmountInclVAT: Decimal;
    begin
        // [FEATURE] [100% Prepayment] [Order] [Partial Posting]
        // [SCENARIO 319539] "Amount including VAT" is not updated on partially posted sales order with prepayment when a user updates the order in any way.

        // [GIVEN] Tax Details for tax jurisdiction with 5%.
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxGroup(TaxGroup);
        CreateTaxAreaSetupWithValues(TaxDetail, TaxArea.Code, TaxGroup.Code, 5);

        // [GIVEN] Sales order for an item with just created tax group, "Prepayment %" = 100.
        // [GIVEN] Post the prepayment invoice.
        PrepareSOwithSalesLine(SalesHeader, SalesLine, TaxArea.Code, CreateItemWithTaxGroup(TaxGroup.Code), false);
        AddSalesOrderLine(SalesLine, LibraryRandom.RandIntInRange(20, 40), LibraryRandom.RandDec(100, 2), 100);
        PostSalesPrepmtInvoice(SalesHeader);

        // [GIVEN] "Amount including VAT" on the sales order line = "X".
        SalesLine.Find();
        AmountInclVAT := SalesLine."Amount Including VAT";

        // [GIVEN] Partially ship and invoice the order.
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Update posting date on the sales order.
        SalesOrder.OpenEdit();
        SalesOrder.GotoKey(SalesHeader."Document Type", SalesHeader."No.");
        SalesOrder."Posting Date".SetValue(LibraryRandom.RandDate(60));

        // [THEN] "Amount including VAT" has not been changed and is still equal to "X".
        SalesLine.Find();
        SalesLine.TestField("Amount Including VAT", AmountInclVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPostingForPrepmtIncludeTax()
    var
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        TaxPct: Integer;
        PrepmtPct: Integer;
        Quantity: Integer;
        PrepmtAmount: Decimal;
        Invoice1: Code[20];
        Invoice2: Code[20];
    begin
        // [SCENARIO 359777] Post sales order partially when Prepmt. Include Tax = true.

        // [GIVEN] Tax Details for tax jurisdiction with 5 %.
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxGroup(TaxGroup);
        TaxPct := LibraryRandom.RandIntInRange(5, 10);
        CreateTaxAreaSetupWithValues(TaxDetail, TaxArea.Code, TaxGroup.Code, TaxPct);

        // [GIVEN] Posted Sales Order with "Prepmt. Include Tax" = TRUE and "Prepayment %" = 50.
        // [GIVEN] Sales Line with Quantity = 2, Amount = 1000, Tax Amount = 50
        PrepmtPct := LibraryRandom.RandIntInRange(1, 5) * 10;
        Customer.Get(CreateCustomerWithTaxArea(TaxArea.Code));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Prepayment %", PrepmtPct);
        SalesHeader.Validate("Prepmt. Include Tax", true);
        SalesHeader.Modify(true);
        Quantity := LibraryRandom.RandIntInRange(1, 5);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithTaxGroup(TaxGroup.Code), Quantity * 2);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 500));
        SalesLine.Modify(true);
        SalesHeader.CalcFields(Amount, "Amount Including VAT");
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // [GIVEN] Prepayment Invoice is posted with amount of 525 = (1000 + 50) * 50 %
        PostSalesPrepmtInvoice(SalesHeader);
        PrepmtAmount := Round(SalesHeader."Amount Including VAT" * PrepmtPct / 100);

        // [GIVEN] Sales order is posted partially with 'Qty. to ship' = 1
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", Quantity);
        SalesLine.Modify(true);
        Invoice1 := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Post final invoice
        Invoice2 := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] First Sales Invoice is posted with Amount = 237.5 (500 - 525/2 ) Amount Incl. Tax =262.5 (525 - 525/2)
        // [THEN] G/L Entry for Account Receivables has Amount = 262.5
        // [THEN] G/L Entry for Sales Prepayments Account has Amount = 237.5
        VerifyPostedSalesEntriesWithPrepmt(
          Invoice1, GetGLAccountFromTaxJurisdiction(TaxGroup.Code), SalesHeader.Amount / 2,
          (SalesHeader."Amount Including VAT" - SalesHeader.Amount) / 2,
          SalesHeader.Amount / 2 - PrepmtAmount / 2, SalesHeader."Amount Including VAT" / 2 - PrepmtAmount / 2,
          CustomerPostingGroup."Receivables Account", GeneralPostingSetup."Sales Prepayments Account", PrepmtAmount / 2);
        // [THEN] Final invoice has same values after posting
        VerifyPostedSalesEntriesWithPrepmt(
          Invoice2, GetGLAccountFromTaxJurisdiction(TaxGroup.Code), SalesHeader.Amount / 2,
          (SalesHeader."Amount Including VAT" - SalesHeader.Amount) / 2,
          SalesHeader.Amount / 2 - PrepmtAmount / 2, SalesHeader."Amount Including VAT" / 2 - PrepmtAmount / 2,
          CustomerPostingGroup."Receivables Account", GeneralPostingSetup."Sales Prepayments Account", PrepmtAmount / 2);
    end;

    local procedure PrepareSOwithPostedPrepmtInv(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; NoOfLines: Integer; TaxAreaCode: Code[20]; ItemNo: Code[20]; PrepmtInclTax: Boolean)
    var
        i: Integer;
    begin
        PrepareSOwithSalesLine(SalesHeader, SalesLine, TaxAreaCode, ItemNo, PrepmtInclTax);
        for i := 1 to NoOfLines do
            AddSalesOrderLine100PctPrepmt(SalesLine);

        PostSalesPrepmtInvoice(SalesHeader);
    end;

    local procedure PrepareSOwithSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; TaxAreaCode: Code[20]; ItemNo: Code[20]; PrepmtInclTax: Boolean)
    begin
        CreateSalesDoc(SalesHeader, TaxAreaCode, SalesHeader."Currency Code", PrepmtInclTax);
        PrepareSalesLine(SalesLine, SalesHeader, ItemNo);
    end;

    local procedure PrepareSOwithPostedPrepmtInvMultiLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Quantity: array[2] of Decimal; UnitPrice: array[2] of Decimal; NoOfLines: Integer; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; PrepmtPct: Decimal; PrepmtInclTax: Boolean)
    var
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
        i: Integer;
    begin
        CreateSalesDoc(SalesHeader, TaxAreaCode, '', PrepmtInclTax);
        PrepareSalesLine(SalesLine, SalesHeader, CreateItemWithTaxGroup(TaxGroupCode));
        for i := 1 to NoOfLines do
            AddSalesOrderLine(SalesLine, Quantity[i], UnitPrice[i], PrepmtPct);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);
        PostSalesPrepmtInvoice(SalesHeader);
    end;

    local procedure CreateItemWithTaxGroup(TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Validate("VAT Prod. Posting Group", '');
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20]; CurrencyCode: Code[10]; PrepmtInclTax: Boolean)
    var
        CustomerNo: Code[20];
    begin
        if SalesHeader."Sell-to Customer No." = '' then
            CustomerNo := CreateCustomerWithTaxArea(TaxAreaCode)
        else
            CustomerNo := SalesHeader."Sell-to Customer No.";
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Prices Including VAT", false);
        SalesHeader.Validate("Compress Prepayment", true);
        SalesHeader.Validate("Prepmt. Include Tax", PrepmtInclTax);
        SalesHeader.Modify();
    end;

    local procedure CreateCustomerWithTaxArea(TaxAreaCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.SetFilter("Sales Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GeneralPostingSetup.FindFirst();

        Customer.Init();
        Customer.Insert(true);
        Customer.Validate(Name, Customer."No.");
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("Tax Area Code", TaxAreaCode);
        Customer.Validate("Tax Liable", true);
        Customer.Validate("Customer Posting Group", LibrarySales.FindCustomerPostingGroup());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateTaxAreaGroupWithSpecialValues(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; Tax1: Decimal; Tax2: Decimal)
    var
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        TaxDetail1: Record "Tax Detail";
        TaxDetail2: Record "Tax Detail";
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxGroup(TaxGroup);
        CreateTaxAreaSetupWithValues(TaxDetail1, TaxArea.Code, TaxGroup.Code, Tax1);
        CreateTaxAreaSetupWithValues(TaxDetail2, TaxArea.Code, TaxGroup.Code, Tax2);
        TaxAreaCode := TaxArea.Code;
        TaxGroupCode := TaxGroup.Code;
    end;

    local procedure CreateTaxAreaSetupWithValues(var TaxDetail: Record "Tax Detail"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxBelowMax: Decimal)
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Sales)", LibraryERM.CreateGLAccountNo());
        TaxJurisdiction.Modify(true);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxBelowMax);
        TaxDetail.Modify(true);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdiction.Code);
    end;

    local procedure GetGLAccountFromTaxJurisdiction(TaxGroupCode: Code[20]) GLAccFilter: Text
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.FindSet();
        repeat
            TaxJurisdiction.Get(TaxDetail."Tax Jurisdiction Code");
            GLAccFilter += TaxJurisdiction."Tax Account (Sales)" + '|';
        until TaxDetail.Next() = 0;
        GLAccFilter := CopyStr(GLAccFilter, 1, StrLen(GLAccFilter) - 1);
    end;

    local procedure PrepareSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 0;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Validate("No.", ItemNo);

        FillPrepmtAcc(SalesLine);
    end;

    local procedure AddSalesOrderLine(var SalesLine: Record "Sales Line"; Qty: Decimal; UnitPrice: Decimal; PrepmtPct: Decimal)
    begin
        SalesLine."Line No." += 10000;
        SalesLine.Validate("No.");
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount %", 0);
        SalesLine.Validate("Prepayment %", PrepmtPct);
        SalesLine.Insert(true);
    end;

    local procedure AddSalesOrderLine100PctPrepmt(var SalesLine: Record "Sales Line")
    begin
        AddSalesOrderLine(SalesLine, 7.3, 3.993, 100); // Magic numbers that lead to prepmt rounding errors. See BUG 332246.
    end;

    local procedure FindTaxAreaCode(): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        if TaxArea.FindFirst() then;
        exit(TaxArea.Code);
    end;

    local procedure FindTaxGroupCode(): Code[20]
    var
        TaxGroup: Record "Tax Group";
    begin
        if TaxGroup.FindFirst() then;
        exit(TaxGroup.Code);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; DocNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocType);
        SalesLine.SetRange("Document No.", DocNo);
        SalesLine.FindSet();
    end;

    local procedure PostSalesPrepmtInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        SalesPostPrepayments.Invoice(SalesHeader);
    end;

    local procedure FindItem(): Code[20]
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Item.FindFirst();

        Item."No." := '';
        Item.Validate("Tax Group Code", FindTaxGroupCode());
        Item.Insert(true);

        ItemUnitOfMeasure."Item No." := Item."No.";
        ItemUnitOfMeasure.Code := Item."Base Unit of Measure";
        ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
        ItemUnitOfMeasure.Insert();

        exit(Item."No.");
    end;

    local procedure FillPrepmtAcc(SalesLine: Record "Sales Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Prod. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        GenPostingSetup."Sales Prepayments Account" := GLAccount."No.";
        GenPostingSetup.Modify();
    end;

    local procedure SetupLineValues(var Quantity: Decimal; var UnitPrice: Decimal; SetQty: Decimal; SetUnitPrice: Decimal)
    begin
        Quantity := SetQty;
        UnitPrice := SetUnitPrice;
    end;

    local procedure VerifyInvRoundingEqualToRoundingPrecision(CustNo: Code[20]; CustPostingGroupCode: Code[20])
    var
        CustPostingGroup: Record "Customer Posting Group";
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer);
        GLEntry.SetRange("Source No.", CustNo);
        GLEntry.FindLast();
        GLEntry.Reset();
        GLEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
        CustPostingGroup.Get(CustPostingGroupCode);
        GLEntry.SetRange("G/L Account No.", CustPostingGroup."Invoice Rounding Account");
        Assert.RecordIsEmpty(GLEntry);
    end;

    local procedure VerifyZeroCustomerAccEntry()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.FindLast();
        CustLedgEntry.CalcFields(Amount, "Amount (LCY)");
        Assert.AreEqual(0, CustLedgEntry.Amount, 'Expected zero Customer Ledger Entry due to 100% prepayment.');
        Assert.AreEqual(0, CustLedgEntry."Amount (LCY)", 'Expected zero Customer Ledger Entry in LCY due to 100% prepayment.');
    end;

    local procedure VerifyPostedSalesEntries(DocumentNo: Code[20]; GLAccountFilter: Text; ExpVATBase: Decimal; ExpVATAmount: Decimal; ExpSalesInvAmount: Decimal; ExpSalesInvRemAmount: Decimal)
    begin
        VerifyPostedSalesInvoice(DocumentNo, ExpSalesInvAmount, ExpSalesInvRemAmount, ExpSalesInvRemAmount);
        VerifyVATEntries(DocumentNo, -ExpVATBase, -ExpVATAmount);
        VerifyGLEntries(DocumentNo, GLAccountFilter, -ExpVATAmount);
    end;

    local procedure VerifyPostedSalesEntriesWithPrepmt(DocumentNo: Code[20]; GLAccountFilter: Text; ExpVATBase: Decimal; ExpVATAmount: Decimal; ExpSalesInvAmount: Decimal; ExpSalesInvRemAmount: Decimal; ReceivablesAcc: Code[20]; PrepaymentAcc: Code[20]; PrepmtAmount: Decimal)
    begin
        VerifyPostedSalesEntries(
          DocumentNo, GLAccountFilter, ExpVATBase, ExpVATAmount, ExpSalesInvAmount, ExpSalesInvRemAmount);
        VerifyGLEntries(DocumentNo, ReceivablesAcc, ExpVATBase + ExpVATAmount - PrepmtAmount);
        VerifyGLEntries(DocumentNo, PrepaymentAcc, PrepmtAmount);
    end;

    local procedure VerifyPostedSalesInvoice(DocumentNo: Code[20]; ExpAmount: Decimal; ExpAmountInclVAT: Decimal; ExpRemAmount: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT", "Remaining Amount");
        SalesInvoiceHeader.CalcFields(Amount);
        SalesInvoiceHeader.TestField(Amount, ExpAmount);
        SalesInvoiceHeader.TestField("Amount Including VAT", ExpAmountInclVAT);
        SalesInvoiceHeader.TestField("Remaining Amount", ExpRemAmount);
    end;

    local procedure VerifyVATEntries(DocumentNo: Code[20]; ExpBase: Decimal; ExpAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums(Base, Amount);
        VATEntry.TestField(Base, ExpBase);
        VATEntry.TestField(Amount, ExpAmount);
    end;

    local procedure VerifyGLEntries(DocumentNo: Code[20]; GLAccFilter: Text; ExpAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetFilter("G/L Account No.", GLAccFilter);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, ExpAmount);
    end;
}

