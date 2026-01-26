codeunit 144057 "Test CH Sales Quote Reports"
{
    // // [FEATURE] [Sales] [Quote]
    // Test CH Sales Quote Reports:
    //
    // 1.  VariantsOnSalesQuote
    // 2.  VariantsNotOnSalesQuoteStatistics
    // 3.  VariantsNotOnSalesOrderStatistics
    // 4.  SpecialLinesOnSalesQuote
    // 5.  SpecialLinesOnSalesOrder
    // 6.  VATAmtOnPostedInvoice
    // 7.  VATAmtOnPostedCrMemo
    // 8.  CombineShipmentsDescLine
    // 9.  MakeSalesOrderWithSpecialLines
    // 10. Verify "Completely Shipped" in Sales Header is correct after post shipment for Sales Order with Special Lines
    //
    //   Covers Test Cases for WI
    //   -------------------------------------------------------
    //   Test Function Name                               TFS ID
    //   -------------------------------------------------------
    //   VariantsOnSalesQuote
    //   VariantsNotOnSalesQuoteStatistics
    //   VariantsNotOnSalesOrderStatistics
    //   SpecialLinesOnSalesQuote
    //   SpecialLinesOnSalesOrder
    //   VATAmtOnPostedInvoice
    //   VATAmtOnPostedCrMemo
    //   CombineShipmentsDescLine
    //   MakeSalesOrderWithSpecialLines
    //
    //   Covers Test Cases for WI
    //   -------------------------------------------------------
    //   Test Function Name                               TFS ID
    //   -------------------------------------------------------
    //   PostShipmentForSalesOrderWithSpecialLines        101380

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCH: Codeunit "Library - CH";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        CompletelyShippedErr: Label 'Completely Shipped should be Yes after fully post shipment';

    [Test]
    [HandlerFunctions('StandardSalesQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VariantsOnSalesQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Setup.
        SetSalesQuoteAutoRecalc(false);
        SetupSalesOrderWithSpecialLines(SalesHeader, SalesHeader."Document Type"::Quote);

        // Exercise.
        Commit();
        SalesHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);

        // Verify.
        VerifySalesQuoteReport(SalesHeader, true);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure VariantsNotOnSalesQuoteStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        // Setup.
        SetupSalesOrderWithSpecialLines(SalesHeader, SalesHeader."Document Type"::Quote);
        CalcSalesStatistics(SalesHeader);

        // Exercise.
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.Statistics.Invoke();

        // Verify. In page handler.
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure VariantsNotOnSalesOrderStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        // Setup.
        SetupSalesOrderWithSpecialLines(SalesHeader, SalesHeader."Document Type"::Order);
        CalcSalesStatistics(SalesHeader);

        // Exercise.
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.Statistics.Invoke();

        // Verify. In page handler.
    end;
#endif
    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure VariantsNotOnSalesQuoteSalesStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        // Setup.
        SetupSalesOrderWithSpecialLines(SalesHeader, SalesHeader."Document Type"::Quote);
        CalcSalesStatistics(SalesHeader);

        // Exercise.
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.SalesStatistics.Invoke();

        // Verify. In page handler.
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure VariantsNotOnSalesOrderStatisticsNM()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        // Setup.
        SetupSalesOrderWithSpecialLines(SalesHeader, SalesHeader."Document Type"::Order);
        CalcSalesStatistics(SalesHeader);

        // Exercise.
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesOrderStatistics.Invoke();

        // Verify. In page handler.
    end;

    [Test]
    [HandlerFunctions('StandardSalesQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SpecialLinesOnSalesQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Setup.
        SetSalesQuoteAutoRecalc(false);
        SetupSalesOrderWithSpecialLines(SalesHeader, SalesHeader."Document Type"::Quote);

        // Exercise.
        Commit();
        SalesHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);

        // Verify.
        VerifySalesQuoteReport(SalesHeader, false);
    end;

    [Test]
    [HandlerFunctions('SalesDocTestReqPageHandler')]
    [Scope('OnPrem')]
    procedure SpecialLinesOnSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        // Setup.
        SetupSalesOrderWithSpecialLines(SalesHeader, SalesHeader."Document Type"::Order);

        // Exercise.
        Commit();
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder."Test Report".Invoke();

        // Verify.
        VerifySalesOrderReport(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtOnPostedInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        QuoteMgt: Codeunit QuoteMgt;
        InvoiceVATAmt: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup.
        SetupSalesOrderWithTotals(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvoiceVATAmt := GetVATAmount(SalesHeader);

        // Exercise.
        QuoteMgt.ReCalc(SalesHeader, false);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify. Posted document.
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"End-Total");
        if SalesInvoiceLine.FindFirst() then
            SalesInvoiceLine.TestField("Subtotal gross", InvoiceVATAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtOnPostedCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        QuoteMgt: Codeunit QuoteMgt;
        InvoiceVATAmt: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup.
        SetupSalesOrderWithTotals(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        InvoiceVATAmt := GetVATAmount(SalesHeader);

        // Exercise.
        QuoteMgt.ReCalc(SalesHeader, false);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify. Posted document.
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::"End-Total");
        if SalesCrMemoLine.FindFirst() then
            SalesCrMemoLine.TestField("Subtotal gross", InvoiceVATAmt);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipmentsDescLine()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        CombineShipments: Report "Combine Shipments";
        i: Integer;
    begin
        Initialize();

        // Setup.
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);

        for i := 1 to 3 do begin
            Clear(SalesHeader);
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
            SalesHeader.Validate("Combine Shipments", true);
            SalesHeader.Modify(true);
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.",
              LibraryRandom.RandDecInRange(10, 100, 2));
            SalesLine.Validate("Qty. to Ship", LibraryRandom.RandDecInDecimalRange(1, SalesLine.Quantity, 2));
            SalesLine.Modify(true);
            LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;

        // Exercise.
        SalesHeader.SetRange("Bill-to Customer No.", Customer."No.");
        CombineShipments.InitializeRequest(WorkDate(), WorkDate(), false, false, false, false);
        CombineShipments.UseRequestPage(false);
        CombineShipments.SetTableView(SalesHeader);
        CombineShipments.Run();

        // Verify.
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Bill-to Customer No.", Customer."No.");
        Assert.AreEqual(1, SalesHeader.Count, 'There should be 1 combined invoice per customer.');
        SalesHeader.FindFirst();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        Assert.AreEqual(3, SalesLine.Count, 'There should be 3 item invoice lines.');
        SalesLine.FindSet();
        repeat
            SalesLine2.CopyFilters(SalesLine);
            SalesLine2.SetRange(Type, SalesLine2.Type::" ");
            SalesLine2.SetFilter(Description, '*' + SalesLine."Shipment No." + '*');
            Assert.AreEqual(1, SalesLine2.Count, 'Description line missing.');
        until SalesLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeSalesOrderWithSpecialLines()
    var
        TempSalesLine: Record "Sales Line" temporary;
        SalesHeader: Record "Sales Header";
        SalesQuoteToOrder: Codeunit "Sales-Quote to Order";
    begin
        Initialize();

        // Setup.
        SetupSalesOrderWithTotals(SalesHeader, SalesHeader."Document Type"::Quote);
        FindSalesLines(TempSalesLine, SalesHeader);

        // Exercise.
        SalesQuoteToOrder.Run(SalesHeader);
        SalesQuoteToOrder.GetSalesOrderHeader(SalesHeader);

        // Verify.
        VerifySalesOrder(TempSalesLine, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostShipmentForSalesOrderWithSpecialLines()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify "Completely Shipped" in Sales Header is correct after post shipment for Sales Order with Special Lines

        // Setup: Create a Sales Order with Specila Lines - New Page, Begin-Total, Title, Item, End-Total...
        Initialize();
        SetupSalesOrderWithSpecialLines(SalesHeader, SalesHeader."Document Type"::Order);

        // Exercise: Post Shipment only.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: "Completely Shipped" in Sales Header updated to Yes
        SalesHeader.CalcFields("Completely Shipped");
        Assert.IsTrue(SalesHeader."Completely Shipped", CompletelyShippedErr);
    end;

    [Test]
    [HandlerFunctions('StandardSalesQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintSalesQuoteWithSpecialLinesAutoRecalcQuotes()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [Report] [Automatic Recalculate Quotes]
        // [SCENARIO 382458] Printing of sales quote causes "End-Total" line recalculation when "Automatic Recalculate Quotes" is set in "Sales & Receivables Setup"
        Initialize();

        // [GIVEN] "Sales & Receivables Setup"."Automatic Recalculate Quotes" = TRUE
        SetSalesQuoteAutoRecalc(true);
        // [GIVEN] Sales quote with the "End-Total" line
        SetupSalesOrderWithSpecialLines(SalesHeader, SalesHeader."Document Type"::Quote);

        // [WHEN] Print the sales quote
        Commit();
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.Print.Invoke();
        SalesQuote.Close();

        // [THEN] "Classification", "Subtotal Net" and "Subtotal Gross" fields are updated in "End-Total" line
        VerifySalesQuoteAutoRecalculated(SalesHeader);
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test CH Sales Quote Reports");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test CH Sales Quote Reports");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Invoice Rounding", false);
        SalesReceivablesSetup.Modify();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test CH Sales Quote Reports");
    end;

    local procedure CalcSalesStatistics(SalesHeader: Record "Sales Header")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesLine: Record "Sales Line";
        TotalAmount: Decimal;
        TotalQty: Decimal;
        TotalCost: Decimal;
    begin
        GeneralLedgerSetup.Get();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Quote Variant", '<>%1', SalesLine."Quote Variant"::Variant);
        SalesLine.FindSet();
        repeat
            TotalAmount += Round(SalesLine."Line Amount", GeneralLedgerSetup."Amount Rounding Precision");
            TotalQty += SalesLine.Quantity;
            TotalCost += SalesLine.Quantity * SalesLine."Unit Cost (LCY)";
        until SalesLine.Next() = 0;

        LibraryVariableStorage.Enqueue(TotalAmount);
        LibraryVariableStorage.Enqueue(TotalQty);
        LibraryVariableStorage.Enqueue(TotalCost);
    end;

    local procedure GetVATAmount(SalesHeader: Record "Sales Header"): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Quote Variant", '<>%1', SalesLine."Quote Variant"::Variant);
        SalesLine.CalcSums("Amount Including VAT");
        exit(SalesLine."Amount Including VAT");
    end;

    local procedure FindSalesLines(var TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            TempSalesLine := SalesLine;
            TempSalesLine.Insert();
        until SalesLine.Next() = 0;
    end;

    local procedure SetupSalesOrderWithSpecialLines(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"New Page", '', 0);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Begin-Total", '', 0);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Title, '', 0);
        SetupSalesLine(SalesHeader, SalesLine."Quote Variant"::Variant);
        SetupSalesLine(SalesHeader, SalesLine."Quote Variant"::"Calculate only");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"End-Total", '', 0);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Title, '', 0);
        SetupSalesLine(SalesHeader, SalesLine."Quote Variant"::" ");
    end;

    local procedure SetupSalesOrderWithTotals(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibraryCH.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          '', '');
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Begin-Total", '', 0);
        SetupSalesLine(SalesHeader, SalesLine."Quote Variant"::" ");
        SetupSalesLine(SalesHeader, SalesLine."Quote Variant"::" ");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"End-Total", '', 0);
    end;

    local procedure SetupSalesLine(SalesHeader: Record "Sales Header"; QuoteVariant: Option)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", SalesHeader."VAT Bus. Posting Group");
        VATPostingSetup.FindFirst();

        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Quote Variant", QuoteVariant);
        SalesLine.Modify(true);
    end;

    local procedure SetSalesQuoteAutoRecalc(AutoRecalcQuotes: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Automatic recalculate Quotes", AutoRecalcQuotes);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure VerifySalesQuoteReport(SalesHeader: Record "Sales Header"; FilterForVariant: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentCopyText', Format(SalesHeader."Document Type"));
        LibraryReportDataset.SetRange('DocumentNo', SalesHeader."No.");

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if FilterForVariant then
            SalesLine.SetRange("Quote Variant", SalesLine."Quote Variant"::Variant)
        else
            SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::Item);
        SalesLine.FindSet();
        repeat
            LibraryReportDataset.SetRange('Type_Line', Format(SalesLine.Type));
            LibraryReportDataset.SetRange('LineNo_Line', SalesLine."Line No.");
            Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'Special lines should be printed.');
            LibraryReportDataset.AssertCurrentRowValueEquals('ItemNo_Line', SalesLine."No.");
            if SalesLine.Type = SalesLine.Type::"item" then begin
                LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_Line', '0');
                LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount_Line', '0.00');
            end else begin
                LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_Line', '');
                LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount_Line', '');
            end;

            SalesLine.TestField("Subtotal Net", 0);
            SalesLine.TestField("Subtotal Gross", 0);
            SalesLine.TestField(Classification, '');
        until SalesLine.Next() = 0;
    end;

    local procedure VerifySalesOrderReport(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Sales_Header_Document_Type', Format(SalesHeader."Document Type"));
        LibraryReportDataset.SetRange('Sales_Header_No_', SalesHeader."No.");

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::Item);
        SalesLine.FindSet();
        repeat
            LibraryReportDataset.SetRange('Sales_Line__Type', Format(SalesLine.Type));
            Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'Special lines should be printed.');
            LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line__Quantity', 0);
            LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___Line_Amount_', 0);
        until SalesLine.Next() = 0;
    end;

    local procedure VerifySalesOrder(var TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        TempSalesLine.FindSet();
        repeat
            SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", TempSalesLine."Line No.");
            SalesLine.TestField(Type, TempSalesLine.Type);
            SalesLine.TestField("No.", TempSalesLine."No.");
            SalesLine.TestField(Quantity, TempSalesLine.Quantity);
            SalesLine.TestField("Unit Price", TempSalesLine."Unit Price");
        until TempSalesLine.Next() = 0;

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Assert.AreEqual(TempSalesLine.Count, SalesLine.Count, 'No of lines should be the same.');
    end;

    local procedure VerifySalesQuoteAutoRecalculated(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::"End-Total");
        SalesLine.FindSet();
        repeat
            SalesLine.TestField("Subtotal Net");
            SalesLine.TestField("Subtotal Gross");
            SalesLine.TestField(Classification);
        until SalesLine.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesQuoteRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        StandardSalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocTestReqPageHandler(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    begin
        SalesDocumentTest.ShipReceiveOnNextPostReq.SetValue(true);
        SalesDocumentTest.InvOnNextPostReq.SetValue(true);
        SalesDocumentTest.ShowDim.SetValue(true);
        SalesDocumentTest.ShowItemChargeAssignment.SetValue(true);
        SalesDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsModalPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalAmount: Variant;
        TotalQty: Variant;
        TotalCost: Variant;
    begin
        GeneralLedgerSetup.Get();
        LibraryVariableStorage.Dequeue(TotalAmount);
        LibraryVariableStorage.Dequeue(TotalQty);
        LibraryVariableStorage.Dequeue(TotalCost);

        Assert.AreNearlyEqual(TotalAmount, SalesOrderStatistics.LineAmountGeneral.AsDecimal(),
          GeneralLedgerSetup."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(TotalAmount, SalesOrderStatistics."TotalAmount1[1]".AsDecimal(), GeneralLedgerSetup."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(TotalQty, SalesOrderStatistics."TotalSalesLine[1].Quantity".AsDecimal(), GeneralLedgerSetup."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(TotalCost, SalesOrderStatistics."TotalAdjCostLCY[1]".AsDecimal(),
          GeneralLedgerSetup."Amount Rounding Precision", '');
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsModalPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalAmount: Variant;
        TotalQty: Variant;
        TotalCost: Variant;
    begin
        GeneralLedgerSetup.Get();
        LibraryVariableStorage.Dequeue(TotalAmount);
        LibraryVariableStorage.Dequeue(TotalQty);
        LibraryVariableStorage.Dequeue(TotalCost);

        Assert.AreNearlyEqual(TotalAmount, SalesStatistics.Amount.AsDecimal(), GeneralLedgerSetup."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(TotalAmount, SalesStatistics.TotalAmount1.AsDecimal(), GeneralLedgerSetup."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(TotalQty, SalesStatistics."TotalSalesLine.Quantity".AsDecimal(), GeneralLedgerSetup."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(TotalCost, SalesStatistics.TotalAdjCostLCY.AsDecimal(), GeneralLedgerSetup."Amount Rounding Precision", '');
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalAmount: Variant;
        TotalQty: Variant;
        TotalCost: Variant;
    begin
        GeneralLedgerSetup.Get();
        LibraryVariableStorage.Dequeue(TotalAmount);
        LibraryVariableStorage.Dequeue(TotalQty);
        LibraryVariableStorage.Dequeue(TotalCost);

        Assert.AreNearlyEqual(TotalAmount, SalesOrderStatistics.LineAmountGeneral.AsDecimal(),
          GeneralLedgerSetup."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(TotalAmount, SalesOrderStatistics."TotalAmount1[1]".AsDecimal(), GeneralLedgerSetup."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(TotalQty, SalesOrderStatistics."TotalSalesLine[1].Quantity".AsDecimal(), GeneralLedgerSetup."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(TotalCost, SalesOrderStatistics."TotalAdjCostLCY[1]".AsDecimal(),
          GeneralLedgerSetup."Amount Rounding Precision", '');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalAmount: Variant;
        TotalQty: Variant;
        TotalCost: Variant;
    begin
        GeneralLedgerSetup.Get();
        LibraryVariableStorage.Dequeue(TotalAmount);
        LibraryVariableStorage.Dequeue(TotalQty);
        LibraryVariableStorage.Dequeue(TotalCost);

        Assert.AreNearlyEqual(TotalAmount, SalesStatistics.Amount.AsDecimal(), GeneralLedgerSetup."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(TotalAmount, SalesStatistics.TotalAmount1.AsDecimal(), GeneralLedgerSetup."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(TotalQty, SalesStatistics."TotalSalesLine.Quantity".AsDecimal(), GeneralLedgerSetup."Amount Rounding Precision", '');
        Assert.AreNearlyEqual(TotalCost, SalesStatistics.TotalAdjCostLCY.AsDecimal(), GeneralLedgerSetup."Amount Rounding Precision", '');
    end;


    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;  // do not create to-do
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}
