codeunit 103421 Corsica_UpdateSalesStatistics
{
    // Unsupported version tags:
    // ES: Unable to Compile
    // NA: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        PerformTestCase1();
        // TC-1-1 Positive Revaluation with AdjustmentPerformTestCase2();
        // TC-1-2 Positive Revaluation without AdjustmentPerformTestCase3();
        // TC-2-1 Negative RevaluationPerformTestCase4();
        // TC-3-1 Item Charges - InventoriablePerformTestCase5();
        // TC-3-2 Item Charges - Non-InventoriablePerformTestCase7();
        // TC-5-1 Negative Quantity in Sales Document LinesPerformTestCase9();
        // TC-9-1 All Sources of Cost Change apply (complete shipment)PerformTestCase10();
        // TC-9-2 All Sources of Cost Change apply (partial shipment)PerformTestCase11();
        // TC-10-1 Documents deletedPerformTestCase12();
        // TC-11-1 Compress Item Ledger & Value EntriesPerformTestCase13();  // TC-12-1 Handle Undo Functionality;
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;
        CostingTestScriptMgmt: Codeunit _TestscriptManagement;
        CurrTest: Text[80];

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GLSetup: Record "General Ledger Setup";
    begin
        // TC-1-1 Positive Revaluation with Adjustment
        CostingTestScriptMgmt.SetGlobalPreconditions();
        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAddRepCurr('DEM');
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '5_ST_RA', '', 20, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 11, 50, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 10, 10, 0);
        // Post purchase order as received and partially invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010127D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 62.34567);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 5, 62.34567, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 15, 'PCS', 40);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 5, 40, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '5_ST_RA', '', 2, 'PCS', 100.34567);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 100.34567, 0, true);
        // Post sales order as partially shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 1
        VerifyInvoiceStats('TC-1-1-1 Pos. Reval + Adjust -', '103001', 416.42, 416.42, 296, 296, 41.5, 41.5);
        VerifyCustomerStats('TC-1-1-1 Pos. Reval + Adjust -', '10000', 416.42, 416.42, 296, 296, 41.5, 41.5, 1);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Retrieve revaluation journal lines
        CreateRevalJnl(ItemJnlLine, '1_FI_RE', '', '', 20010126D, 'TESTREVAL', "Inventory Value Calc. Per"::Item, false, false, true);
        CreateRevalJnl(ItemJnlLine, '5_ST_RA', '', '', 20010126D, 'TESTREVAL', "Inventory Value Calc. Per"::Item, false, false, true);
        // Set new inventory value
        CostingTestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 150, true, 0);
        CostingTestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 20000, 1200, true, 0);
        // Post revaluation journal lines
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Run Adjust Cost Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 2
        VerifyInvoiceStats('TC-1-1-2 Pos. Reval + Adjust -', '103001', 416.42, 495, 296, 217.42, 41.5, 30.5);
        VerifyCustomerStats('TC-1-1-2 Pos. Reval + Adjust -', '10000', 416.42, 495, 296, 217.42, 41.5, 30.5, 1);
        // Raise workdate
        WorkDate := 20010128D;
        // Post purchase order as invoiced
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010129D;
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales return order lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 62);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 62, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 40);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 40, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 102);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 102, 0, 0);
        // Post sales return order as received and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 3
        VerifyCRMemoStats('TC-1-1-3 Pos. Reval + Adjust -', '104001', 130, 130, 74, 74, 36.3, 36.3);
        VerifyCustomerStats('TC-1-1-3 Pos. Reval + Adjust -', '10000', 286.42, 365, 222, 143.42, 43.7, 28.2, 1);
        // Raise workdate
        WorkDate := 20010130D;
        // Create sales credit memo header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales credit memo lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 50);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 50, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 30);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 30, 0, 0);
        // Post sales credit memo
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 4
        VerifyCRMemoStats('TC-1-1-4 Pos. Reval + Adjust -', '104002', 70, 70, 10, 10, 12.5, 12.5);
        VerifyCustomerStats('TC-1-1-4 Pos. Reval + Adjust -', '10000', 216.42, 295, 212, 133.42, 49.5, 31.1, 1);
        // In General Ledger Setup, set Allow Posting From = 01.02.01
        GLSetup.Find('-');
        GLSetup."Allow Posting From" := 20010201D;
        GLSetup.Modify();
        // Raise workdate
        WorkDate := 20010201D;
        // Run Adjust Cost Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 5
        VerifyCustomerStats('TC-1-1-5 Pos. Reval + Adjust -', '10000', 216.42, 295, 212, 133.42, 49.5, 31.1, 2);
        VerifyInvoiceStats('TC-1-1-5 Pos. Reval + Adjust -', '103001', 416.42, 495, 296, 217.42, 41.5, 30.5);
        VerifyCRMemoStats('TC-1-1-5 Pos. Reval + Adjust -', '104001', 130, 130, 74, 74, 36.3, 36.3);
        VerifyCRMemoStats('TC-1-1-5 Pos. Reval + Adjust -', '104002', 70, 70, 10, 10, 12.5, 12.5);
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
#if not CLEAN25
        SalesLineDiscount: Record "Sales Line Discount";
#else
        PriceListLine: Record "Price List Line";
#endif
        Item: Record Item;
    begin
        // TC-1-2 Positive Revaluation without Adjustment
        CostingTestScriptMgmt.SetGlobalPreconditions();

        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAddRepCurr('DEM');
        // Set up line discount for item 7_ST_OV
#if not CLEAN25
        SalesLineDiscount.Validate(Type, SalesLineDiscount.Type::Item);
        SalesLineDiscount.Validate(Code, '7_ST_OV');
        SalesLineDiscount.Validate("Sales Type", SalesLineDiscount."Sales Type"::"All Customers");
        SalesLineDiscount.Validate("Unit of Measure Code", 'PCS');
        SalesLineDiscount.Validate("Minimum Quantity", 10);
        SalesLineDiscount.Validate("Line Discount %", 10);
        if not SalesLineDiscount.Insert(true) then;
#else
        PriceListLine.Validate("Source Type", "Price Source Type"::"All Customers");
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine.Validate("Asset No.", '7_ST_OV');
        PriceListLine.Validate("Unit of Measure Code", 'PCS');
        PriceListLine.Validate("Minimum Quantity", 10);
        PriceListLine.Validate("Line Discount %", 10);
        PriceListLine.Status := PriceListLine.Status::Active;
        if not PriceListLine.Insert(true) then;
#endif
        // Remove overhead rate and indirect cost % values for item 7_ST_OV
        Item.Get('7_ST_OV');
        Item."Overhead Rate" := 0;
        Item."Indirect Cost %" := 0;
        Item.Modify(true);
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), '', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 42.55555);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 42.55555, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '7_ST_OV', '', 20, 'PCS', 73.45678);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 73.45678, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 82.55555);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 82.55555, 0, false);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 1
        VerifyInvoiceStats('TC-1-2-1 Pos Reval no Adjust -', '103001', 212.78, 212.78, 200, 200, 48.5, 48.5);
        VerifyCustomerStats('TC-1-2-1 Pos Reval no Adjust -', '10000', 212.78, 212.78, 200, 200, 48.5, 48.5, 1);
        // Retrieve revaluation journal lines
        CreateRevalJnl(ItemJnlLine, '7_ST_OV', '', '', 20010126D, 'TESTREVAL', "Inventory Value Calc. Per"::Item, false, false, false);
        // Set new inventory value
        CostingTestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 1486.91, true, 0);
        // Post revaluation journal lines
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Raise workdate
        WorkDate := 20010127D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '7_ST_OV', '', 10, 'PCS', 74.56789);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 74.56789, 10, true);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 2
        VerifyInvoiceStats('TC-1-2-2 Pos Reval no Adjust -', '103002', 723.46, 723.46, -52.35, -52.35, -7.8, -7.8);
        VerifyCustomerStats('TC-1-2-2 Pos Reval no Adjust -', '10000', 936.24, 936.24, 147.65, 147.65, 13.6, 13.6, 1);
        // Raise workdate
        WorkDate := 20010128D;
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales return order lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '7_ST_OV', '', 1, 'PCS', 52.34567);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 52.34567, 0, 0);
        // Post sales return order as received and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 3
        VerifyCRMemoStats('TC-1-2-3 Pos Reval no Adjust -', '104001', 72.35, 72.35, -20, -20, -38.2, -38.2);
        VerifyCustomerStats('TC-1-2-3 Pos Reval no Adjust -', '10000', 863.89, 863.89, 167.65, 167.65, 16.3, 16.3, 1);
        //must be used for the manual test, remove the Brackets from the lines below
        /*
        // In General Ledger Setup, set Allow Posting From = 01.02.01
        WITH GLSetup DO BEGIN
          FIND('-');
          "Allow Posting From" := 010201D;
          Modify();
        END;
        EXIT;
        */
        // Create user "QA", role "SUPER", Allow Posting From = 01.01.01 manually after running the code
        // close database and open it as User QA
        // proceed manual test
        // Raise workdate
        WorkDate := 20010129D;
        // Create sales credit memo header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), '', true, false);
        // Create sales credit memo lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 12.5);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 5, 5, 12.5, 0, 0);
        // Post sales credit memo
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 4
        VerifyCRMemoStats('TC-1-2-4 Pos Reval no Adjust -', '104002', 212.78, 212.78, -150.28, -150.28, -240.4, -240.4);
        VerifyCustomerStats('TC-1-2-4 Pos Reval no Adjust -', '10000', 651.11, 651.11, 317.93, 317.93, 32.8, 32.8, 1);

    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
#if not CLEAN25
        SalesLineDiscount: Record "Sales Line Discount";
#else
        PriceListLine: Record "Price List Line";
#endif
    begin
        // TC-2-1 Negative Revaluation
        CostingTestScriptMgmt.SetGlobalPreconditions();

        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAddRepCurr('DEM');
        // Set up line discount for item 1_FI_RE
#if not CLEAN25
        SalesLineDiscount.Validate(Type, SalesLineDiscount.Type::Item);
        SalesLineDiscount.Validate(Code, '1_FI_RE');
        SalesLineDiscount.Validate("Sales Type", SalesLineDiscount."Sales Type"::"All Customers");
        SalesLineDiscount.Validate("Unit of Measure Code", 'PCS');
        SalesLineDiscount.Validate("Minimum Quantity", 10);
        SalesLineDiscount.Validate("Line Discount %", 10);
        if not SalesLineDiscount.Insert(true) then;
#else
        PriceListLine.Validate("Source Type", "Price Source Type"::"All Customers");
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Item);
        PriceListLine.Validate("Asset No.", '1_FI_RE');
        PriceListLine.Validate("Unit of Measure Code", 'PCS');
        PriceListLine.Validate("Minimum Quantity", 10);
        PriceListLine.Validate("Line Discount %", 10);
        PriceListLine.Status := PriceListLine.Status::Active;
        if not PriceListLine.Insert(true) then;
#endif
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 15, 'PCS', 8);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 15, 10, 8, 10, true);
        // Post sales order as shipped and partially invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 1
        VerifyInvoiceStats('TC-2-1-1 Negat. Reval. -', '103001', 123.33, 123.33, -51.33, -51.33, -71.3, -71.3);
        VerifyCustomerStats('TC-2-1-1 Negat. Reval. -', '10000', 123.33, 123.33, -51.33, -51.33, -71.3, -71.3, 1);
        // Raise workdate
        WorkDate := 20010126D;
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '7_ST_OV', '', 20, 'PCS', 73.55);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 73.55, 0);
        // Post purchase order as partially received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010127D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '7_ST_OV', '', 5, 'PCS', 62.55);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 62.55, 0, true);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Modify purchase order
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 10, 10, 9, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 10, 10, 72.55, 0);
        // Post purchase order as partially received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 2
        VerifyInvoiceStats('TC-2-1-2 Negat. Reval. -', '103001', 123.33, 100, -51.33, -28, -71.3, -38.9);
        VerifyInvoiceStats('TC-2-1-2 Negat. Reval. -', '103002', 377.75, 377.75, -65, -65, -20.8, -20.8);
        VerifyCustomerStats('TC-2-1-2 Negat. Reval. -', '10000', 501.08, 477.75, -116.33, -93, -30.2, -24.2, 1);
        // Raise workdate
        WorkDate := 20010128D;
        // Post the sales order for item 1_FI_RE as shipped and invoiced
        SalesHeader.Find('-');
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 3
        VerifyInvoiceStats('TC-2-1-3 Negat. Reval. -', '103003', 61.67, 45, -25.67, -9, -71.3, -25);
        VerifyCustomerStats('TC-2-1-3 Negat. Reval. -', '10000', 562.75, 522.75, -142, -102, -33.7, -24.2, 1);
        // Retrieve revaluation journal lines
        CreateRevalJnl(ItemJnlLine, '7_ST_OV', '', '', 20010126D, 'TESTREVAL', "Inventory Value Calc. Per"::Item, false, false, true);
        // Set new inventory value
        CostingTestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 705.5, true, 0);
        // Post revaluation journal lines
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 4
        VerifyInvoiceStats('TC-2-1-4 Negat. Reval. -', '103002', 377.75, 352.75, -65, -40, -20.8, -12.8);
        VerifyCustomerStats('TC-2-1-4 Negat. Reval. -', '10000', 562.75, 497.75, -142, -77, -33.7, -18.3, 1);
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales return order lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '7_ST_OV', '', 5, 'PCS', 71.55);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 5, 5, 71.55, 0, 0);
        SalesLine.SetRange(SalesLine."Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", 10000);
        SalesLine.FindFirst();
        SalesLine.Validate("Unit Cost (LCY)", 70.55);
        SalesLine.Modify(true);
        // Post sales return order as received and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 5
        VerifyCRMemoStats('TC-2-1-5 Negat. Reval. -', '104001', 377.75, 377.75, -20, -20, -5.6, -5.6);
        VerifyCustomerStats('TC-2-1-5 Negat. Reval. -', '10000', 185, 120, -122, -57, -193.7, -90.5, 1);
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales return order lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 8);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 5, 0, 8, 0, 0);
        // Post sales return order as received and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 6
        VerifyCustomerStats('TC-2-1-6 Negat. Reval. -', '10000', 185, 120, -122, -57, -193.7, -90.5, 1);
        // Raise workdate
        WorkDate := 20010129D;
        // Create sales credit memo header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales credit memo lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '7_ST_OV', '', 5, 'PCS', 1);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 5, 5, 1, 0, 0);
        SalesLine.SetRange(SalesLine."Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", 10000);
        SalesLine.FindFirst();
        SalesLine.Validate("Unit Cost (LCY)", 70.55);
        SalesLine.Modify(true);
        // Post sales credit memo
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 7
        VerifyCRMemoStats('TC-2-1-7 Negat. Reval. -', '104002', 377.75, 377.75, -372.75, -372.75, -7455, -7455);
        VerifyCustomerStats('TC-2-1-7 Negat. Reval. -', '10000', -192.75, -257.75, 250.75, 315.75, 432.3, 544.4, 1);
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        // TC-3-1 Item Charges - Inventoriable
        CostingTestScriptMgmt.SetGlobalPreconditions();

        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAddRepCurr('DEM');
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 43.55);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 43.55, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::"Charge (Item)", 'UPS', '', 20, '', 16.45);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 16.45, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '7_ST_OV', '', 20, 'PCS', 75.55);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 20, 75.55, 0);
        // Assign charge to item 4_AV_RE
        PurchLine.Reset();
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 20000);
        PurchLine.Find('-');
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, PurchHeader."Document Type", PurchHeader."No.",
        10000, '4_AV_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, 20000, 20000, 20);
        // Post purchase order as received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 88.89);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 1, 88.89, 10, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 100, 10, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 111.11);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 111.11, 10, true);
        // Post sales order as partially shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 1
        VerifyInvoiceStats('TC-3-1-1 Invt. Item Charges -', '103001', 120, 120, 50, 50, 29.4, 29.4);
        VerifyCustomerStats('TC-3-1-1 Invt. Item Charges -', '10000', 120, 120, 50, 50, 29.4, 29.4, 1);
        // Raise workdate
        WorkDate := 20010127D;
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales return order lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 80);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 80, 0, 0);
        SalesLine.SetRange(SalesLine."Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", 10000);
        SalesLine.FindFirst();
        SalesLine.Validate("Unit Cost (LCY)", 65);
        SalesLine.Modify(true);
        // Post sales return order as received and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 2
        VerifyCRMemoStats('TC-3-1-2 Invt. Item Charges -', '104001', 65, 65, 15, 15, 18.8, 18.8);
        VerifyCustomerStats('TC-3-1-2 Invt. Item Charges -', '10000', 55, 55, 35, 35, 38.9, 38.9, 1);
        // Create sales invoice header
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Get shipment lines for item 4_AV_RE
        Clear(SalesShipmentLine);
        SalesShipmentLine.SetRange("Sell-to Customer No.", '10000');
        if SalesShipmentLine.Find('-') then begin
            SalesGetShipment.SetSalesHeader(SalesHeader);
            SalesGetShipment.CreateInvLines(SalesShipmentLine);
        end;
        // Modify sales invoice lines
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 4, 4, 70, 10, true);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 0, 100, 0, true);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 1, 1, 110, 0, true);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Line No.", 30000);
        SalesLine.Find('-');
        SalesLine.Validate(Quantity, 0);
        SalesLine.Modify(true);
        // Post the sales invoice
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 3
        VerifyInvoiceStats('TC-3-1-3 Invt. Item Charges -', '103002', 300, 300, 62, 62, 17.1, 17.1);
        VerifyCustomerStats('TC-3-1-3 Invt. Item Charges -', '10000', 355, 355, 97, 97, 21.5, 21.5, 1);
        // Raise workdate
        WorkDate := 20010128D;
        // Create sales credit memo header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales credit memo lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '7_ST_OV', '', 1, 'PCS', 75.55);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 75.55, 0, 0);
        // Post sales credit memo
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 4
        VerifyCRMemoStats('TC-3-1-4 Invt. Item Charges -', '104002', 75.55, 75.55, 0, 0, 0, 0);
        VerifyCustomerStats('TC-3-1-4 Invt. Item Charges -', '10000', 279.45, 279.45, 97, 97, 25.8, 25.8, 1);
        // Raise workdate
        WorkDate := 20010129D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '7_ST_OV', '', 5, 'PCS', 83.55);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 83.55, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '7_ST_OV', '', 5, 'PCS', 93.55);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 93.55, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '7_ST_OV', '', 5, 'PCS', 103.55);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 103.55, 0, true);
        // Post sales order as partially shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 5
        VerifyInvoiceStats('TC-3-1-5 Invt. Item Charges -', '103003', 453.3, 453.3, 58, 58, 11.3, 11.3);
        VerifyCustomerStats('TC-3-1-5 Invt. Item Charges -', '10000', 732.75, 732.75, 155, 155, 17.5, 17.5, 1);
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'INSURANCE', '', 2, '', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 2, 100, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::"Charge (Item)", 'P-ALLOWANCE', '', 2, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 1, 10, 0);
        // Assign item charges to receipt lines
        PurchLine.SetRange(PurchLine."Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 10000);
        PurchLine.Find('-');
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, '107001', 10000, '4_AV_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, '107001', 30000, '7_ST_OV');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);

        PurchLine.Reset();
        PurchLine.SetRange(PurchLine."Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 20000);
        PurchLine.Find('-');
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, '107001', 30000, '7_ST_OV');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
        // Post purchase order as partially received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 6
        VerifyInvoiceStats('TC-3-1-6 Invt. Item Charges -', '103001', 120, 130, 50, 40, 29.4, 23.5);
        VerifyInvoiceStats('TC-3-1-6 Invt. Item Charges -', '103002', 300, 325, 62, 37, 17.1, 10.2);
        VerifyCustomerStats('TC-3-1-6 Invt. Item Charges -', '10000', 732.75, 767.75, 155, 120, 17.5, 13.5, 1);
        // Raise workdate
        WorkDate := 20010130D;
        // Assign item charge to receipt line
        PurchLine.SetRange(PurchLine."Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 20000);
        PurchLine.Find('-');
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, '107001', 10000, '4_AV_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
        // Post purchase order as partially received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 7
        VerifyInvoiceStats('TC-3-1-7 Invt. Item Charges -', '103001', 120, 131, 50, 39, 29.4, 22.9);
        VerifyInvoiceStats('TC-3-1-7 Invt. Item Charges -', '103002', 300, 327.5, 62, 34.5, 17.1, 9.5);
        VerifyCustomerStats('TC-3-1-7 Invt. Item Charges -', '10000', 732.75, 771.25, 155, 116.5, 17.5, 13.1, 1);
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesShipHeader: Record "Sales Shipment Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        // TC-3-2 Item Charges - Non-Inventoriable
        CostingTestScriptMgmt.SetGlobalPreconditions();

        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAddRepCurr('DEM');
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 15);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 0, 15, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 53.45678);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 5, 53.45678, 0);
        // Post purchase order as received and partially invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 25);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 25, 0, true);
        // Post sales order as shipped
        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 82.34567);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 82.34567, 0, true);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 1
        VerifyInvoiceStats('TC-3-2-1 Non-Inv. Item Char. -', '103001', 261.73, 261.73, 150, 150, 36.4, 36.4);
        VerifyCustomerStats('TC-3-2-1 Non-Inv. Item Char. -', '10000', 261.73, 261.73, 150, 150, 36.4, 36.4, 1);
        // Raise workdate
        WorkDate := 20010127D;
        // Post 1st sales order as invoiced
        SalesHeader.Find('-');
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Modify purchase order line
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 5, 35, 0);
        // Post purchase order as invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 2
        VerifyInvoiceStats('TC-3-2-2 Non-Inv. Item Char. -', '103002', 61.67, 175, 63.33, -50, 50.7, -40);
        VerifyCustomerStats('TC-3-2-2 Non-Inv. Item Char. -', '10000', 323.4, 436.73, 213.33, 100, 39.7, 18.6, 1);
        // Raise workdate
        WorkDate := 20010128D;
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales return order lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 20);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 20, 0, 0);
        SalesLine.SetRange(SalesLine."Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", 10000);
        SalesLine.FindFirst();
        SalesLine.Validate("Unit Cost (LCY)", 35);
        SalesLine.Modify(true);
        // Post sales return order as received and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 3
        VerifyCRMemoStats('TC-3-2-3 Non-Inv. Item Char. -', '104001', 35, 35, -15, -15, -75, -75);
        VerifyCustomerStats('TC-3-2-3 Non-Inv. Item Char. -', '10000', 288.4, 401.73, 228.33, 115, 44.2, 22.3, 1);
        // Raise workdate
        WorkDate := 20010129D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::"Charge (Item)", 'INSURANCE', '', 9, '', 10);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 9, 9, 10, 0, true);
        // Assign item charge to sales shipment lines and sales return receipt line
        SalesShipHeader.Find('-');
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, "Sales Applies-to Document Type"::Shipment, SalesShipHeader."No.", 10000, '1_FI_RE');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 3);
        SalesShipHeader.Find('+');
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, "Sales Applies-to Document Type"::Shipment, SalesShipHeader."No.", 10000, '5_ST_RA');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 3);
        ReturnReceiptHeader.Find('-');
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, "Sales Applies-to Document Type"::"Return Receipt", ReturnReceiptHeader."No.", 10000, '1_FI_RE');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 3);
        // Post sales return order as received and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 4
        VerifyInvoiceStats('TC-3-2-4 Non-Inv. Item Char. -', '103003', 0, 0, 90, 90, 100, 100);
        VerifyCustomerStats('TC-3-2-4 Non-Inv. Item Char. -', '10000', 288.4, 401.73, 318.33, 205, 52.5, 33.8, 1);
        // Raise workdate
        WorkDate := 20010130D;
        // Create sales credit memo header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales credit memo lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 62.34567);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 5, 5, 62.34567, 0, 0);
        // Post sales credit memo
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 5
        VerifyCRMemoStats('TC-3-2-5 Non-Inv. Item Char. -', '104002', 261.73, 261.73, 50, 50, 16, 16);
        VerifyCustomerStats('TC-3-2-5 Non-Inv. Item Char. -', '10000', 26.67, 140, 268.33, 155, 91, 52.5, 1);
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase6()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        ReqWkshLine: Record "Requisition Line";
        CarryOut: Report "Carry Out Action Msg. - Req.";
        GetSalesOrder: Report "Get Sales Orders";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // TC-4-1 Drop Shipment of tracked Items
        CostingTestScriptMgmt.SetGlobalPreconditions();

        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAddRepCurr('DEM');
        // Set Vendor No. for item 3_SP_RE
        Item.Get('3_SP_RE');
        Item.Validate("Vendor No.", '10000');
        Item.Modify(true);
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 10, 0);
        // Post purchase order as received and partially invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '3_SP_RE', '', 1, 'PALLET', 575.76526);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 0, 0, 575.76526, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '3_SP_RE', '', 3, 'PCS', 40.45678);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 40.45678, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '7_ST_OV', '', 10, 'PCS', 80.55);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 3, 80.55, 0, true);

        SalesLine.Reset();
        SalesLine.SetRange(SalesLine."Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", 10000);
        SalesLine.FindFirst();
        SalesLine.Validate("Purchasing Code", 'DROP SHIP');
        SalesLine.Validate("Unit Cost (LCY)", 568.76526);
        SalesLine.Modify(true);
        SalesLine.SetRange("Line No.", 20000);
        SalesLine.FindFirst();
        SalesLine.Validate("Purchasing Code", 'DROP SHIP');
        SalesLine.Validate("Unit Cost (LCY)", 33.45678);
        SalesLine.Modify(true);
        // Assign serial nos. to first sales line
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00001', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00002', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00003', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00004', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00005', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00006', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00007', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00008', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00009', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00010', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00011', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00012', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00013', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00014', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00015', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00016', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, Round(1 / 17, 0.00001), 1, 'SN00017', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        // Assign serial nos. to second sales line
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 20000, 1, Round(1 / 17, 0.00001), 1, 'SN00018', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 20000, 1, Round(1 / 17, 0.00001), 1, 'SN00019', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 20000, 1, Round(1 / 17, 0.00001), 1, 'SN00020', '');
        CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, WorkDate(), 0, "Reservation Status"::Surplus);
        // Release sales order
        CODEUNIT.Run(CODEUNIT::"Release Sales Document", SalesHeader);
        // Create requisition worksheet lines
        ReqWkshLine.DeleteAll();
        ReqWkshLine."Worksheet Template Name" := 'REQ';
        ReqWkshLine."Journal Batch Name" := 'DEFAULT';
        GetSalesOrder.SetReqWkshLine(ReqWkshLine, 0);
        GetSalesOrder.UseRequestPage := false;
        GetSalesOrder.Run();
        // Carry out action message to create purchase order
        CarryOut.SetReqWkshLine(ReqWkshLine);
        CarryOut.SetHideDialog(true);
        CarryOut.InitializeRequest(WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
        CarryOut.UseRequestPage := false;
        CarryOut.Run();
        // Release purchase order
        Clear(PurchHeader);
        PurchHeader.Find('-');
        CODEUNIT.Run(CODEUNIT::"Release Purchase Document", PurchHeader);
        // Post sales order as partially shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 1
        VerifySalesOrderStats('TC-4-1-1 Drop Shpm. -', SalesHeader, 1424.64, 1424.64, 78, 78, 5.2, 5.2);
        VerifyInvoiceStats('TC-4-1-1 Drop Shpm. -', '103001', 260.11, 260.11, 22, 22, 7.8, 7.8);
        VerifyCustomerStats('TC-4-1-1 Drop Shpm. -', '10000', 260.11, 260.11, 22, 22, 7.8, 7.8, 1);
        // Raise workdate
        WorkDate := 20010127D;
        // Post purchase order as partially received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Delete sales line
        SalesLine.SetRange("Line No.", 30000);
        if SalesLine.Find('-') then
            SalesLine.Delete(true);
        // Verify Expected Result No. 2
        VerifyCustomerStats('TC-4-1-2 Drop Shpm. -', '10000', 669.14, 669.14, 28, 28, 4, 4, 1);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 3
        VerifyInvoiceStats('TC-4-1-3 Drop Shpm. -', '103002', 635.68, 635.68, 21, 21, 3.2, 3.2);
        VerifyCustomerStats('TC-4-1-3 Drop Shpm. -', '10000', 895.79, 895.79, 43, 43, 4.6, 4.6, 1);
        // Raise workdate
        WorkDate := 20010128D;
        // Modify purchase order lines
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 1, 1, 575.76526, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 1, 2, 30.45678, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 4
        VerifyInvoiceStats('TC-4-1-4 Drop Shpm. -', '103002', 635.68, 636.68, 21, 20, 3.2, 3);
        VerifyCustomerStats('TC-4-1-4 Drop Shpm. -', '10000', 895.79, 896.79, 43, 42, 4.6, 4.5, 1);
        // Raise workdate
        WorkDate := 20010129D;
        // Create sales header with currency code 'USD'
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        SalesHeader.Find('+');
        SalesHeader.Validate("Currency Code", 'USD');
        SalesHeader.Modify(true);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 100, 0, true);
        SalesLine.Reset();
        SalesLine.SetRange(SalesLine."Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", 10000);
        SalesLine.FindFirst();
        SalesLine.Validate("Unit Cost (LCY)", 60);
        SalesLine.Modify(true);
        // Post sales order as partially shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 5
        VerifyInvoiceStats('TC-4-1-5 Drop Shpm. -', '103003', 600, 600, 48.82, 48.82, 7.5, 7.5);
        VerifyCustomerStats('TC-4-1-5 Drop Shpm. -', '10000', 1495.79, 1496.79, 91.82, 90.82, 5.8, 5.7, 1);
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase7()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // TC-5-1 Negative Quantity in Sales Document Lines
        CostingTestScriptMgmt.SetGlobalPreconditions();

        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAddRepCurr('DEM');
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 15);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 9, 9, 15, 0, true);
        SalesLine.Reset();
        SalesLine.SetRange(SalesLine."Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", 10000);
        SalesLine.FindFirst();
        SalesLine.Validate("Unit Cost (LCY)", 10);
        SalesLine.Modify(true);
        // Post sales order as partially shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Modify sales order
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, true);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 1, 1, 15, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', -4, 'PCS', 2.5);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", -4, -4, 2.5, 0, true);
        SalesLine.Reset();
        SalesLine.SetRange(SalesLine."Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", 20000);
        SalesLine.FindFirst();
        SalesLine.Validate("Unit Cost (LCY)", 10);
        SalesLine.Modify(true);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 1
        VerifyInvoiceStats('TC-5-1-1 Negat. Qty. -', '103002', -30, -30, 35, 35, 700, 700);
        VerifyCustomerStats('TC-5-1-1 Negat. Qty. -', '10000', 60, 60, 80, 80, 57.1, 57.1, 1);
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales credit memo header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales credit memo lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 10);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 10, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', -2, 'PCS', 10);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", -2, -2, 10, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 10);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 10, 0, 0);
        SalesLine.Reset();
        SalesLine.SetRange(SalesLine."Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.Find('-') then
            repeat
                SalesLine.Validate("Unit Cost (LCY)", 10);
                SalesLine.Modify(true);
            until SalesLine.Next() = 0;
        // Post sales credit memo
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 2
        VerifyCRMemoStats('TC-5-1-2 Negat. Qty. -', '104001', 0, 0, 0, 0, 0, 0);
        VerifyCustomerStats('TC-5-1-2 Negat. Qty. -', '10000', 60, 60, 80, 80, 57.1, 57.1, 1);
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase8()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        CombShpts: Report "Combine Shipments";
        DeleteInvoicedSalesOrders: Report "Delete Invoiced Sales Orders";
    begin
        // TC-8-1 Combine Shipments
        CostingTestScriptMgmt.SetGlobalPreconditions();

        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAddRepCurr('DEM');
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 1);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 10, 1, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 20, 'PCS', 2);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 10, 2, 0);
        // Post purchase order as received and partially invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 8, 'PCS', 52.37);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 0, 52.37, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '5_ST_RA', '', 8, 'PCS', 52.36);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 0, 52.36, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '5_ST_RA', '', 8, 'PCS', 52.35);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 0, 52.35, 0, true);
        // Post sales order as shipped
        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 1
        VerifySalesOrderStats('TC-8-1-1 Combine Shipments -', SalesHeader, 1256.31, 1256.31, 0.33, 0.33, 0, 0);
        // Raise workdate
        WorkDate := 20010127D;
        // Modify purchase order lines
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 10, 11, 0);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 10, 1, 0);
        // Post purchase order as invoiced
        PurchHeader.Receive := false;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010128D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 8, 'PCS', 11);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 0, 11, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 8, 'PCS', 21);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 0, 21, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 8, 'PCS', 31);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 0, 31, 0, true);
        // Post sales order as shipped
        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 2
        VerifySalesOrderStats('TC-8-1-2 Combine Shipments -', SalesHeader, 24, 24, 480, 480, 95.2, 95.2);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 3
        VerifySalesOrderStats('TC-8-1-3 Combine Shipments -', SalesHeader, 24, 124, 480, 380, 95.2, 75.4);
        // Raise workdate
        WorkDate := 20010129D;
        // Create sales credit memo header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales credit memo lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 55.34567);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 55.34567, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '5_ST_RA', '', 0, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 0, 0, 100, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 52.34567);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 52.34567, 0, 0);
        // Post sales credit memo
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 4
        VerifyCRMemoStats('TC-8-1-4 Combine Shipments -', '104001', 104.69, 104.7, 3.01, 3, 2.8, 2.8);
        VerifyCustomerStats('TC-8-1-4 Combine Shipments -', '10000', -104.7, -104.7, -3, -3, 2.8, 2.8, 1);
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales return order lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 21);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 0, 21, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 50.34567);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 0, 50.34567, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 2, 'PCS', 41);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 2, 0, 41, 0, 0);
        // Post sales return order as received
        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010130D;
        // Post sales return order as invoiced
        SalesHeader.Ship := false;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 5
        VerifyCRMemoStats('TC-8-1-5 Combine Shipments -', '104002', 55.35, 55.35, 98, 98, 63.9, 63.9);
        VerifyCustomerStats('TC-8-1-5 Combine Shipments -', '10000', -160.05, -160.05, -101, -101, 38.7, 38.7, 1);
        // Raise workdate
        WorkDate := 20010131D;
        // Create sales invoice for combined shipments
        Clear(CombShpts);
        CombShpts.InitializeRequest(WorkDate(), WorkDate(), false, false, false, false);
        CombShpts.SetHideDialog(true);
        CombShpts.UseRequestPage(false);
        CombShpts.RunModal();
        // Post sales invoice
        SalesHeader.Reset();
        SalesHeader.SetRange(SalesHeader."Document Type", SalesHeader."Document Type"::Invoice);
        if SalesHeader.Find('-') then
            CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 6
        VerifyInvoiceStats('TC-8-1-6 Combine Shipments -', '103001', 1280.3, 1280.31, 480.34, 480.33, 27.3, 27.3);
        VerifyCustomerStats('TC-8-1-6 Combine Shipments -', '10000', 1120.26, 1120.26, 379.33, 379.33, 25.3, 25.3, 1);
        // Delete the invoiced sales orders
        DeleteInvoicedSalesOrders.UseRequestPage(false);
        DeleteInvoicedSalesOrders.RunModal();
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 7
        VerifyInvoiceStats('TC-8-1-7 Combine Shipments -', '103001', 1280.3, 1380.32, 480.34, 380.32, 27.3, 21.6);
        VerifyCustomerStats('TC-8-1-7 Combine Shipments -', '10000', 1120.26, 1220.27, 379.33, 279.32, 25.3, 18.6, 1);
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase9()
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // TC-9-1 All Sources of Cost Change apply (complete shipment)
        CostingTestScriptMgmt.SetGlobalPreconditions();

        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAddRepCurr('DEM');
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', '', 5, '', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 2, 100, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 20, 'PCS', 53.45678);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 19, 53.45678, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 19, 100, 0);
        // Assign item charge to purchase order lines
        PurchLine.Reset();
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 10000);
        PurchLine.FindFirst();
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, PurchHeader."Document Type", PurchHeader."No.", 20000, '5_ST_RA');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, PurchHeader."Document Type", PurchHeader."No.", 30000, '6_AV_OV');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
        // Post purchase order as received and partially invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010127D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 8, 'PCS', 52.37);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 8, 52.37, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Resource, 'LINDA', '', 8, 'HOUR', 12.5);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 4, 12.5, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::"Charge (Item)", 'S-FREIGHT', '', 8, '', 52.35);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 8, 52.35, 0, true);
        // Assign item charge to sales line
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, "Sales Applies-to Document Type"::Order, SalesHeader."No.", 10000, '5_ST_RA');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 8);
        // Post sales order as partially shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 1
        VerifyInvoiceStats('TC-9-1-1 All sources (compl) -', '103001', 443.97, 443.97, 443.79, 443.79, 50, 50);
        VerifyCustomerStats('TC-9-1-1 All sources (compl) -', '10000', 443.97, 443.97, 443.79, 443.79, 50, 50, 1);
        // Raise workdate
        WorkDate := 20010128D;
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Retrieve revaluation journal lines
        CreateRevalJnl(ItemJnlLine, '5_ST_RA', '', '', 20010126D, 'TESTREVAL', "Inventory Value Calc. Per"::Item, false, false, true);
        // Set new inventory value
        CostingTestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 1646.91, true, 0);
        // Post revaluation journal lines
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Run Adjust Cost Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 2
        VerifyInvoiceStats('TC-9-1-2 All sources (compl) -', '103001', 443.97, 683.96, 443.79, 203.8, 50, 23);
        VerifyCustomerStats('TC-9-1-2 All sources (compl) -', '10000', 443.97, 683.96, 443.79, 203.8, 50, 23, 1);
        // Raise workdate
        WorkDate := 20010129D;
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales return order lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Resource, 'LINDA', '', 4, 'HOUR', 13.5);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 4, 4, 13.5, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 52.346);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 0, 52.346, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::"Charge (Item)", 'UPS', '', 2, '', 50);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 50, 0, 0);
        // Assign item charge to sales return order line
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, "Sales Applies-to Document Type"::"Return Order", SalesHeader."No.", 20000, '5_ST_RA');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 1);
        // Post sales return order as received and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 3
        VerifyCRMemoStats('TC-9-1-3 All sources (compl) -', '104001', 25.2, 25.2, 78.8, 78.8, 75.8, 75.8);
        VerifyCustomerStats('TC-9-1-3 All sources (compl) -', '10000', 418.77, 658.76, 364.99, 125, 46.6, 15.9, 1);
        // Raise workdate
        WorkDate := 20010130D;
        // Create sales credit memo header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales credit memo lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Resource, 'LINDA', '', 1, 'HOUR', 120);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 120, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Resource, 'MARK', '', 1, 'HOUR', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 100, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '6_AV_OV', '', 1, 'PCS', 99.66);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 99.66, 0, 0);
        // Post sales credit memo
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 4
        VerifyCRMemoStats('TC-9-1-4 All sources (compl) -', '104002', 157.86, 157.86, 161.8, 161.8, 50.6, 50.6);
        VerifyCustomerStats('TC-9-1-4 All sources (compl) -', '10000', 260.91, 500.9, 203.19, -36.8, 43.8, -7.9, 1);
        // Raise workdate
        WorkDate := 20010131D;
        // Modify sales order
        SalesHeader.SetRange(SalesHeader."Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.FindFirst();
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, true);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 4, 17.5, 0, true);
        // Post sales order as invoiced
        SalesHeader.Ship := false;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 5
        VerifyCustomerStats('TC-9-1-5 All sources (compl) -', '10000', 286.11, 526.1, 247.99, 8, 46.4, 1.5, 1);
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase10()
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesShipHeader: Record "Sales Shipment Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        // TC-9-2 All Sources of Cost Change apply (partial shipment)
        CostingTestScriptMgmt.SetGlobalPreconditions();

        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAddRepCurr('DEM');
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 15);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 15, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', '', 2, '', 100);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 2, 100, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '7_ST_OV', '', 5, 'PCS', 75);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 5, 75, 0);
        // Assign item charge to purchase order lines
        PurchLine.Reset();
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 20000);
        PurchLine.FindFirst();
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, PurchHeader."Document Type", PurchHeader."No.", 10000, '1_FI_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, PurchHeader."Document Type", PurchHeader."No.", 30000, '7_ST_OV');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
        // Post purchase order as received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Resource, 'LINDA', '', 2, 'HOUR', 11.3);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 11.3, 0, true);
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 4, 'PCS', 25);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 1, 25, 0, true);
        // Post sales orders as partially shipped and invoiced
        SalesHeader.Reset();
        if SalesHeader.Find('-') then
            repeat
                SalesHeader.Ship := true;
                SalesHeader.Invoice := true;
                CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
            until SalesHeader.Next() = 0;
        // Verify Expected Result No. 1
        VerifyInvoiceStats('TC-9-2-1 All sources (part) -', '103001', 6.3, 6.3, 5, 5, 44.2, 44.2);
        VerifyInvoiceStats('TC-9-2-1 All sources (part) -', '103002', 15, 15, 10, 10, 40, 40);
        VerifyCustomerStats('TC-9-2-1 All sources (part) -', '10000', 21.3, 21.3, 15, 15, 41.3, 41.3, 1);
        // Raise workdate
        WorkDate := 20010127D;
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales return order lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 25);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 25, 0, 0);
        // Post sales return order as received and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 2
        VerifyInvoiceStats('TC-9-2-2 All sources (part) -', '103002', 15, 25, 10, 0, 40, 0);
        VerifyCustomerStats('TC-9-2-2 All sources (part) -', '10000', 6.3, 16.3, 5, -5, 44.2, -44.2, 1);
        // Raise workdate
        WorkDate := 20010128D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::"Charge (Item)", 'UPS', '', 2, '', 10);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 10, 0, true);
        // Assign item charge to sales shipment lines and sales return receipt line
        SalesShipHeader.FindLast();
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, "Sales Applies-to Document Type"::Shipment, SalesShipHeader."No.", 10000, '1_FI_RE');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
        ReturnReceiptHeader.FindFirst();
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, "Sales Applies-to Document Type"::"Return Receipt", ReturnReceiptHeader."No.", 10000, '1_FI_RE');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 3
        VerifyInvoiceStats('TC-9-2-3 All sources (part) -', '103001', 6.3, 6.3, 5, 5, 44.2, 44.2);
        VerifyInvoiceStats('TC-9-2-3 All sources (part) -', '103002', 15, 25, 10, 0, 40, 0);
        VerifyCustomerStats('TC-9-2-3 All sources (part) -', '10000', 6.3, 16.3, 25, 15, 79.9, 47.9, 1);
        // Raise workdate
        WorkDate := 20010129D;
        // Retrieve revaluation journal lines
        CreateRevalJnl(ItemJnlLine, '1_FI_RE', '', '', WorkDate(), 'TESTREVAL', "Inventory Value Calc. Per"::Item, false, false, true);
        CreateRevalJnl(ItemJnlLine, '7_ST_OV', '', '', WorkDate(), 'TESTREVAL', "Inventory Value Calc. Per"::Item, false, false, true);
        // Set new inventory value
        CostingTestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 200, true, 0);
        CostingTestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 20000, 350, true, 0);
        // Post revaluation journal lines
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Run Adjust Cost Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 4
        VerifyInvoiceStats('TC-9-2-4 All sources (part) -', '103001', 6.3, 6.3, 5, 5, 44.2, 44.2);
        VerifyInvoiceStats('TC-9-2-4 All sources (part) -', '103002', 15, 25, 10, 0, 40, 0);
        VerifyCustomerStats('TC-9-2-4 All sources (part) -', '10000', 6.3, 16.3, 25, 15, 79.9, 47.9, 1);
        // Raise workdate
        WorkDate := 20010130D;
        // Modify first sales order
        SalesHeader.Reset();
        SalesHeader.SetRange(SalesHeader."Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.FindFirst();
        ReleaseSalesDocument.PerformManualReopen(SalesHeader);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 1, 1, 0.5, 0, true);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 5
        VerifyCustomerStats('TC-9-2-5 All sources (part) -', '10000', 12.6, 22.6, 19.2, 9.2, 60.4, 28.9, 1);
        // Raise workdate
        WorkDate := 20010131D;
        // Create sales credit memo header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales credit memo lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Resource, 'LINDA', '', 1, 'HOUR', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 100, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '7_ST_OV', '', 2, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 2, 2, 100, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::"Charge (Item)", 'S-FREIGHT', '', 1, '', 11.11);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 11.11, 0, 0);
        // Assign item charge to sales line
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, "Sales Applies-to Document Type"::"Credit Memo", SalesHeader."No.", 20000, '7_ST_OV');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
        // Post sales credit memo
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 6
        VerifyCRMemoStats('TC-9-2-6 All sources (part) -', '104002', 157.4, 157.4, 153.71, 153.71, 49.4, 49.4);
        VerifyCustomerStats('TC-9-2-6 All sources (part) -', '10000', -144.8, -134.8, -134.51, -144.51, 48.2, 51.7, 1);
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase11()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeleteInvoicedSalesOrders: Report "Delete Invoiced Sales Orders";
        DeleteInvdSalesRetOrders: Report "Delete Invd Sales Ret. Orders";
    begin
        PerformTestCase9();
        // Assign item charge in sales return order
        SalesHeader.Reset();
        SalesHeader.SetRange(SalesHeader."Document Type", SalesHeader."Document Type"::"Return Order");
        SalesHeader.FindFirst();
        SalesLine.Reset();
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindLast();

        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 1);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 1
        VerifyCRMemoStats('TC-10-1-1 Delete Docs -', '104003', 82.35, 82.35, 20, 20, 19.5, 19.5);
        VerifyCustomerStats('TC-10-1-1 Delete Docs -', '10000', 203.76, 443.75, 227.99, -12, 52.8, -2.8, 1);
        // Delete the invoiced sales order
        DeleteInvoicedSalesOrders.UseRequestPage(false);
        DeleteInvoicedSalesOrders.RunModal();
        // Delete the invoiced sales return order
        DeleteInvdSalesRetOrders.UseRequestPage(false);
        DeleteInvdSalesRetOrders.RunModal();
        // Verify Expected Result No. 2
        VerifyCRMemoStats('TC-10-1-2 Delete Docs -', '104003', 82.35, 82.35, 20, 20, 19.5, 19.5);
        VerifyInvoiceStats('TC-10-1-2 Delete Docs -', '103001', 443.97, 683.96, 443.79, 203.8, 50, 23);
        VerifyCustomerStats('TC-10-1-2 Delete Docs -', '10000', 203.76, 443.75, 227.99, -12, 52.8, -2.8, 1);
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase12()
    var
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // TC-11-1 Compress Item Ledger & Value Entries
        CostingTestScriptMgmt.SetGlobalPreconditions();

        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAddRepCurr('DEM');
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 4, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 20, 'PCS', 53.45678);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 8, 53.45678, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '7_ST_OV', '', 10, 'PCS', 73.45678);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 4, 73.45678, 0);
        // Post purchase order as received and partially invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', '', 6, '', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 3, 10, 0);
        // Assign item charges to receipt lines
        PurchLine.SetRange(PurchLine."Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("Line No.", 10000);
        PurchLine.FindFirst();
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, '107001', 10000, '1_FI_RE');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, '107001', 20000, '5_ST_RA');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
        CostingTestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, '107001', 30000, '7_ST_OV');
        CostingTestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
        // Post purchase order as received and partially invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales order lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 53.34567);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 5, 53.34567, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Resource, 'LINDA', '', 8, 'HOUR', 12.3);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 4, 12.3, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::"Charge (Item)", 'S-FREIGHT', '', 1, '', 10);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 10, 0, false);
        // Assign item charge to sales order line
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, "Sales Applies-to Document Type"::Order, SalesHeader."No.", 10000, '5_ST_RA');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
        // Post sales order as shipped and partially invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 1
        VerifySalesOrderStats('TC-11-1-1 Compress Entries -', SalesHeader, 573.86, 573.86, 68, 68, 10.6, 10.6);
        VerifyInvoiceStats('TC-11-1-1 Compress Entries -', '103001', 286.93, 286.93, 39, 39, 12, 12);
        VerifyCustomerStats('TC-11-1-1 Compress Entries -', '10000', 286.93, 286.93, 39, 39, 12, 12, 1);
        // Raise workdate
        WorkDate := 20010127D;
        // Create sales credit memo header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales credit memo lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Resource, 'LINDA', '', 1, 'HOUR', 9.3);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 9.3, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '7_ST_OV', '', 1, 'PCS', 95.55);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 95.55, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Resource, 'MARK', '', 1, 'HOUR', 51.9);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 51.9, 0, 0);
        // Post sales credit memo
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 2
        VerifyCRMemoStats('TC-11-1-2 Compress Entries -', '104001', 113.75, 113.75, 43, 43, 27.4, 27.4);
        VerifyCustomerStats('TC-11-1-2 Compress Entries -', '10000', 173.18, 173.18, -4, -4, -2.4, -2.4, 1);
        // Raise workdate
        WorkDate := 20010129D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 26);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 26, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '7_ST_OV', '', 1, 'PCS', 80.55);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 80.55, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 26);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 26, 0, true);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 3
        VerifyInvoiceStats('TC-11-1-3 Compress Entries -', '103002', 117.55, 117.55, 15, 15, 11.3, 11.3);
        VerifyCustomerStats('TC-11-1-3 Compress Entries -', '10000', 290.73, 290.73, 11, 11, 3.6, 3.6, 1);
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 80.34567);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 80.34567, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 10);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 10, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::"Charge (Item)", 'UPS', '', 1, '', 10);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 10, 0, true);
        // Assign item charge to sales order line
        CostingTestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, "Sales Applies-to Document Type"::Order, SalesHeader."No.", 20000, '1_FI_RE');
        CostingTestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010131D;
        // Modify first purchase order
        PurchHeader.Reset();
        PurchHeader.FindFirst();
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        PurchLine.Reset();
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.FindFirst();
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 0, 6, 24, 0);
        // Post purchase order as invoiced
        PurchHeader.Receive := false;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Post first sales order as invoiced
        SalesHeader.Reset();
        SalesHeader.FindFirst();
        SalesHeader.Ship := false;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 4
        VerifyInvoiceStats('TC-11-1-4 Compress Entries -', '103004', 286.93, 286.93, 29, 29, 9.2, 9.2);
        VerifyCustomerStats('TC-11-1-4 Compress Entries -', '10000', 651.01, 651.01, 67, 67, 9.3, 9.3, 1);
        // Raise workdate
        WorkDate := 20010201D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '7_ST_OV', '', 2, 'PCS', 50.55);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 1, 50.55, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '7_ST_OV', '', 1, 'PCS', 50.55);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 50.55, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 3, 'PCS', 3.4);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 3, 3.4, 0, true);
        // Post sales order as shipped and partially invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 5
        VerifyInvoiceStats('TC-11-1-5 Compress Entries -', '103005', 224.39, 224.39, -113.09, -113.09, -101.6, -101.6);
        VerifyCustomerStats('TC-11-1-5 Compress Entries -', '10000', 875.4, 875.4, -46.09, -46.09, -5.6, -5.6, 2);
        // Raise workdate
        WorkDate := 20010202D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 4, 'PCS', 8.4);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 4, 4, 8.4, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '5_ST_RA', '', 9, 'PCS', 58.34567);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 9, 9, 58.34567, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Resource, 'LINDA', '', 8, '', 7.3);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 8, 7.3, 0, true);
        // Post sales order as shipped and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Raise workdate
        WorkDate := 20010203D;
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales return order lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 50.34567);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 50.34567, 0, 0);
        // Post sales return order as received and invoiced
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Verify Expected Result No. 6
        VerifyCRMemoStats('TC-11-1-6 Compress Entries -', '104002', 52.35, 52.35, -2, -2, -4, -4);
        VerifyCustomerStats('TC-11-1-6 Compress Entries -', '10000', 1442.27, 1442.27, -46.2, -46.2, -3.3, -3.3, 2);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Retrieve revaluation journal lines
        CreateRevalJnl(ItemJnlLine, '7_ST_OV', '', '', WorkDate(), 'TESTREVAL', "Inventory Value Calc. Per"::Item, false, false, true);
        // Set new inventory value
        CostingTestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 563.85, true, 0);
        // Post revaluation journal lines
        CostingTestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        // Run Adjust Cost Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 7
        VerifyCustomerStats('TC-11-1-7 Compress Entries -', '10000', 1442.27, 1442.27, -46.2, -46.2, -3.3, -3.3, 2);
        // Close fiscal year 2001
        // Date compress entries for items 1_FI_RE|5_ST_RA
        // Verify Expected Result No. 8
        //VerifyInvoiceStats('TC-11-1-8 Compress Entries -','103001',286.93,0,39,0,12,0);
        //VerifyInvoiceStats('TC-11-1-8 Compress Entries -','103002',117.55,0,15,0,11.3,0);
        //VerifyInvoiceStats('TC-11-1-8 Compress Entries -','103004',286.93,0,29,0,9.2,0);
        //VerifyCustomerStats('TC-11-1-8 Compress Entries -','10000',1442.27,1442.27,-46.2,-46.2,-3.3,-3.3,2);
        // Date compress entries for all items
        // Verify Expected Result No. 9
        //SalesHeader.GET('1004');
        //VerifySalesOrderStats('TC-11-1-9 Compress Entries -',SalesHeader,299.94,0,-138.09,0,-85.3,0);
        //VerifyInvoiceStats('TC-11-1-9 Compress Entries -','103005',224.39,0,-113.09,0,-101.6,0);
        //VerifyCustomerStats('TC-11-1-9 Compress Entries -','10000',1442.27,1442.27,-46.2,-46.2,-3.3,-3.3,2);
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase13()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
        UndoReturnReceiptLine: Codeunit "Undo Return Receipt Line";
        UndoSalesShipmentLine: Codeunit "Undo Sales Shipment Line";
    begin
        // TC-12-1 Handle Undo Functionality
        CostingTestScriptMgmt.SetGlobalPreconditions();

        CostingTestScriptMgmt.SetAutoCostPost(false);
        CostingTestScriptMgmt.SetExpCostPost(false);
        CostingTestScriptMgmt.SetAddRepCurr('DEM');
        // Create purchase header
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'BLUE', '', true);
        // Create purchase lines
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 53.45678);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 53.45678, 0);
        // Post purchase order as received and invoiced
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
        // Raise workdate
        WorkDate := 20010126D;
        // Create sales header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 55.34567);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 55.34567, 0, true);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 12);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 12, 0, true);
        SalesLine.Reset();
        SalesLine.FindFirst();
        SalesLine.Validate("Unit Cost (LCY)", 52.34567);
        SalesLine.Modify(true);
        // Post sales order as partially shipped
        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Modify sales order
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, true);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 1, 0, 55.34567, 0, true);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 1, 0, 12, 0, true);
        SalesLine.Reset();
        SalesLine.FindLast();
        SalesLine.Validate("Unit Cost (LCY)", 11.11);
        SalesLine.Modify(true);
        // Post sales order as partially shipped
        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 1
        VerifySalesOrderStats('TC-12-1-1 Handle Undo -', SalesHeader, 634.56, 632.35, 38.9, 41.11, 5.8, 6.1);
        // Raise workdate
        WorkDate := 20010127D;
        // Undo shipment line for second shipment
        SalesShipmentLine.SetRange("Document No.", '102002');
        SalesShipmentLine.SetRange("Line No.", 20000);
        if SalesShipmentLine.Find('-') then begin
            UndoSalesShipmentLine.SetHideDialog(true);
            UndoSalesShipmentLine.Run(SalesShipmentLine);
        end;
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 2
        VerifySalesOrderStats('TC-12-1-2 Handle Undo -', SalesHeader, 634.56, 633.46, 38.9, 40, 5.8, 5.9);
        // Raise workdate
        WorkDate := 20010128D;
        // Undo shipment line for second shipment
        SalesShipmentLine.SetRange("Document No.", '102001');
        SalesShipmentLine.SetRange("Line No.", 10000);
        if SalesShipmentLine.Find('-') then begin
            UndoSalesShipmentLine.SetHideDialog(true);
            UndoSalesShipmentLine.Run(SalesShipmentLine);
        end;
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 3
        VerifySalesOrderStats('TC-12-1-3 Handle Undo -', SalesHeader, 634.56, 633.45, 38.9, 40.01, 5.8, 5.9);
        // Create sales return order header
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, false);
        // Create sales return order lines
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 2, 'PCS', 12);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 0, 12, 0, 0);
        SalesLine.SetRange(SalesLine."Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", 10000);
        SalesLine.FindFirst();
        SalesLine.Validate("Unit Cost (LCY)", 10);
        SalesLine.Modify(true);
        // Post sales return order as received
        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Modify sales return order
        SalesHeader.SetRange(SalesHeader."Document Type", SalesHeader."Document Type"::"Return Order");
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, true);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.Reset();
        SalesLine.FindLast();
        SalesLine.Validate("Unit Cost (LCY)", 11.11);
        SalesLine.Modify(true);
        // Post sales return order as received
        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 4
        // Verify 1st Return Order
        VerifySalesOrderStats('TC-12-1-4 Handle Undo -', SalesHeader, 22.22, 21.11, 1.78, 2.89, 7.4, 12);
        // Undo return receipt line
        ReturnRcptLine.SetRange("Document No.", '107002');
        ReturnRcptLine.SetRange("Line No.", 10000);
        if ReturnRcptLine.Find('-') then begin
            UndoReturnReceiptLine.SetHideDialog(true);
            UndoReturnReceiptLine.Run(ReturnRcptLine);
        end;
        // Run the Adjust Cost - Item Entries batch job
        CostingTestScriptMgmt.AdjustItem('', '', false);
        // Verify Expected Result No. 5
        // Verify 1st Return Order
        VerifySalesOrderStats('TC-12-1-5 Handle Undo -', SalesHeader, 22.22, 21.11, 1.78, 2.89, 7.4, 12);
    end;

    local procedure CreateRevalJnl(var ItemJnlLine: Record "Item Journal Line"; ItemNo: Code[20]; ItemLocation: Code[10]; ItemVariant: Code[10]; RevalDate: Date; DocNo: Code[20]; CalculatePer: Enum "Inventory Value Calc. Per"; ByLocation: Boolean; ByVariant: Boolean; UpdateStandardCost: Boolean)
    var
        Item: Record Item;
        CalcInvValue: Report "Calculate Inventory Value";
    begin
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        if ItemNo <> '' then
            Item.SetRange("No.", ItemNo);
        if ItemLocation <> '' then
            Item.SetRange("Location Filter", ItemLocation);
        if ItemVariant <> '' then
            Item.SetRange("Variant Filter", ItemVariant);
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(RevalDate, DocNo, true, CalculatePer, ByLocation, ByVariant, UpdateStandardCost, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);
    end;

    local procedure MakeName(TextPar1: Variant; TextPar2: Variant; TextPar3: Variant): Text[250]
    begin
        exit(StrSubstNo('%1 - %2 %3 %4', CurrTest, TextPar1, TextPar2, TextPar3));
    end;

    [Scope('OnPrem')]
    procedure VerifySalesOrderStats(parTestCaseName: Text[30]; parSalesHeader: Record "Sales Header"; parOrgCost: Decimal; parAdjCost: Decimal; parOrgProfit: Decimal; parAdjProfit: Decimal; parOrgProfitPct: Decimal; parAdjProfitPct: Decimal)
    var
        SalesPost: Codeunit "Sales-Post";
        TotalSalesLine: array[3] of Record "Sales Line";
        TotalSalesLineLCY: array[3] of Record "Sales Line";
        VATAmount: array[3] of Decimal;
        VATAmountText: array[3] of Text[30];
        ProfitLCY: array[3] of Decimal;
        ProfitPct: array[3] of Decimal;
        TotalAdjCostLCY: array[3] of Decimal;
        AdjProfitLCY: Decimal;
        AdjProfitPct: Decimal;
    begin
        SalesPost.SumSalesLines(parSalesHeader, 0, TotalSalesLine[1],
          TotalSalesLineLCY[1], VATAmount[1], VATAmountText[1], ProfitLCY[1], ProfitPct[1], TotalAdjCostLCY[1]);

        AdjProfitLCY := TotalSalesLineLCY[1].Amount - TotalAdjCostLCY[1];
        AdjProfitPct := Round(100 * (TotalSalesLineLCY[1].Amount - TotalAdjCostLCY[1]) / TotalSalesLineLCY[1].Amount, 0.1);

        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales ' + Format(parSalesHeader."Document Type") + ' Statistics', '- Original Cost (LCY) ='),
          TotalSalesLineLCY[1]."Unit Cost (LCY)", parOrgCost);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales ' + Format(parSalesHeader."Document Type") + ' Statistics', '- Adjusted Cost (LCY) ='),
          TotalAdjCostLCY[1], parAdjCost);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales ' + Format(parSalesHeader."Document Type") + ' Statistics', '- Original Profit (LCY) ='),
          ProfitLCY[1], parOrgProfit);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales ' + Format(parSalesHeader."Document Type") + ' Statistics', '- Adjusted Profit (LCY) ='),
          AdjProfitLCY, parAdjProfit);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales ' + Format(parSalesHeader."Document Type") + ' Statistics', '- Original Profit % ='),
          ProfitPct[1], parOrgProfitPct);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales ' + Format(parSalesHeader."Document Type") + ' Statistics', '- Adjusted Profit % ='),
          AdjProfitPct, parAdjProfitPct);
    end;

    [Scope('OnPrem')]
    procedure VerifyCustomerStats(parTestCaseName: Text[30]; parCustNo: Code[20]; parOrgCost: Decimal; parAdjCost: Decimal; parOrgProfit: Decimal; parAdjProfit: Decimal; parOrgProfitPct: Decimal; parAdjProfitPct: Decimal; parColumn: Integer)
    var
        CostCalcMgt: Codeunit "Cost Calculation Management";
        DateFilterCalc: Codeunit "DateFilter-Calc";
        CustDateFilter: array[4] of Text[30];
        CustDateName: array[4] of Text[30];
        TotalAmountLCY: Decimal;
        CurrentDate: Date;
        CustSalesLCY: array[4] of Decimal;
        AdjmtCostLCY: array[4] of Decimal;
        CustProfit: array[4] of Decimal;
        ProfitPct: array[4] of Decimal;
        AdjCustProfit: array[4] of Decimal;
        AdjProfitPct: array[4] of Decimal;
        i: Integer;
        Cust: Record Customer;
        ValueEntry: Record "Value Entry";
    begin
        Cust.Get(parCustNo);

        if CurrentDate <> WorkDate() then begin
            CurrentDate := WorkDate();
            DateFilterCalc.CreateAccountingPeriodFilter(CustDateFilter[1], CustDateName[1], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(CustDateFilter[2], CustDateName[2], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(CustDateFilter[3], CustDateName[3], CurrentDate, -1);
        end;

        Cust.SetRange("Date Filter", 0D, CurrentDate);
        Cust.CalcFields(
          Balance, "Balance (LCY)", "Balance Due", "Balance Due (LCY)",
          "Outstanding Orders (LCY)", "Shipped Not Invoiced (LCY)");

        TotalAmountLCY := Cust."Balance (LCY)" + Cust."Outstanding Orders (LCY)" + Cust."Shipped Not Invoiced (LCY)";

        for i := 1 to 4 do begin
            Cust.SetFilter("Date Filter", CustDateFilter[i]);
            Cust.CalcFields(
              "Sales (LCY)", "Profit (LCY)", "Inv. Discounts (LCY)", "Inv. Amounts (LCY)", "Pmt. Discounts (LCY)",
              "Pmt. Disc. Tolerance (LCY)", "Pmt. Tolerance (LCY)",
              "Fin. Charge Memo Amounts (LCY)", "Cr. Memo Amounts (LCY)", "Payments (LCY)",
              "Reminder Amounts (LCY)", "Refunds (LCY)", "Other Amounts (LCY)");
            CustSalesLCY[i] := Cust."Sales (LCY)";

            ValueEntry.SetCurrentKey("Source Type", "Source No.", "Item No.", "Posting Date");

            ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Customer);
            ValueEntry.SetRange("Source No.", Cust."No.");
            ValueEntry.SetFilter("Posting Date", CustDateFilter[i]);
            ValueEntry.SetFilter("Global Dimension 1 Code", Cust."Global Dimension 1 Filter");
            ValueEntry.SetFilter("Global Dimension 2 Code", Cust."Global Dimension 2 Filter");

            ValueEntry.CalcSums("Cost Amount (Non-Invtbl.)");


            CustProfit[i] := Cust."Profit (LCY)" + ValueEntry."Cost Amount (Non-Invtbl.)";
            //CustProfit[i] := "Profit (LCY)" + NonInvtblCostAmt(i);
            AdjmtCostLCY[i] := CostCalcMgt.CalcCustAdjmtCostLCY(Cust);
            AdjCustProfit[i] := CustProfit[i] + AdjmtCostLCY[i];

            if Cust."Sales (LCY)" <> 0 then begin
                ProfitPct[i] := Round(100 * CustProfit[i] / Cust."Sales (LCY)", 0.1);
                AdjProfitPct[i] := Round(100 * AdjCustProfit[i] / Cust."Sales (LCY)", 0.1);
            end else begin
                ProfitPct[i] := 0;
                AdjProfitPct[i] := 0;
            end;

        end;
        Cust.SetRange("Date Filter", 0D, CurrentDate);

        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Customer Statistics', '- Original Cost (LCY) ='),
          CustSalesLCY[parColumn] - CustProfit[parColumn], parOrgCost);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Customer Statistics', '- Adjusted Cost (LCY) ='),
          CustSalesLCY[parColumn] - CustProfit[parColumn] - AdjmtCostLCY[parColumn], parAdjCost);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Customer Statistics', '- Original Profit (LCY) ='),
          CustProfit[parColumn], parOrgProfit);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Customer Statistics', '- Adjusted Profit (LCY) ='),
          AdjCustProfit[parColumn], parAdjProfit);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Customer Statistics', '- Original Profit % ='),
          ProfitPct[parColumn], parOrgProfitPct);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Customer Statistics', '- Adjusted Profit % ='),
          AdjProfitPct[parColumn], parAdjProfitPct);
    end;

    [Scope('OnPrem')]
    procedure VerifyInvoiceStats(parTestCaseName: Text[30]; parInvoiceNo: Code[20]; parOrgCost: Decimal; parAdjCost: Decimal; parOrgProfit: Decimal; parAdjProfit: Decimal; parOrgProfitPct: Decimal; parAdjProfitPct: Decimal)
    var
        SalesInvoice: Record "Sales Invoice Header";
        CurrExchRate: Record "Currency Exchange Rate";
        SalesInvLine: Record "Sales Invoice Line";
        Currency: Record Currency;
        CostCalcMgt: Codeunit "Cost Calculation Management";
        TotalAdjCostLCY: Decimal;
        CustAmount: Decimal;
        CostLCY: Decimal;
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        AdjProfitLCY: Decimal;
        AdjProfitPct: Decimal;
        AmountLCY: Decimal;
    begin
        SalesInvoice.Get(parInvoiceNo);
        ClearAll();

        if SalesInvoice."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(SalesInvoice."Currency Code");

        SalesInvLine.SetRange("Document No.", parInvoiceNo);
        if SalesInvLine.Find('-') then
            repeat
                CustAmount := CustAmount + SalesInvLine.Amount;
                CostLCY := CostLCY + (SalesInvLine.Quantity * SalesInvLine."Unit Cost (LCY)");
                TotalAdjCostLCY := TotalAdjCostLCY + CostCalcMgt.CalcSalesInvLineCostLCY(SalesInvLine);
            until SalesInvLine.Next() = 0;

        if SalesInvoice."Currency Code" = '' then
            AmountLCY := CustAmount
        else
            AmountLCY :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                WorkDate(), SalesInvoice."Currency Code", CustAmount, SalesInvoice."Currency Factor");

        ProfitLCY := AmountLCY - CostLCY;
        if AmountLCY <> 0 then
            ProfitPct := Round(100 * ProfitLCY / AmountLCY, 0.1);

        AdjProfitLCY := AmountLCY - TotalAdjCostLCY;
        if AmountLCY <> 0 then
            AdjProfitPct := Round(100 * AdjProfitLCY / AmountLCY, 0.1);
        CostLCY := Round(CostLCY, 0.01);
        ProfitLCY := Round(ProfitLCY, 0.01);

        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales Invoice Statistics', '- Original Cost (LCY) ='), CostLCY, parOrgCost);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales Invoice Statistics', '- Adjusted Cost (LCY) ='), TotalAdjCostLCY, parAdjCost);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales Invoice Statistics', '- Original Profit (LCY) ='), ProfitLCY, parOrgProfit);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales Invoice Statistics', '- Adjusted Profit (LCY) ='), AdjProfitLCY, parAdjProfit);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales Invoice Statistics', '- Original Profit % ='), ProfitPct, parOrgProfitPct);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales Invoice Statistics', '- Adjusted Profit % ='), AdjProfitPct, parAdjProfitPct);
    end;

    [Scope('OnPrem')]
    procedure VerifyCRMemoStats(parTestCaseName: Text[30]; parCRMemoNo: Code[20]; parOrgCost: Decimal; parAdjCost: Decimal; parOrgProfit: Decimal; parAdjProfit: Decimal; parOrgProfitPct: Decimal; parAdjProfitPct: Decimal)
    var
        CostCalcMgt: Codeunit "Cost Calculation Management";
        SalesCRMemo: Record "Sales Cr.Memo Header";
        CurrExchRate: Record "Currency Exchange Rate";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        Currency: Record Currency;
        TotalAdjCostLCY: Decimal;
        CustAmount: Decimal;
        CostLCY: Decimal;
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        AdjProfitLCY: Decimal;
        AdjProfitPct: Decimal;
        AmountLCY: Decimal;
    begin
        SalesCRMemo.Get(parCRMemoNo);
        ClearAll();

        if SalesCRMemo."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(SalesCRMemo."Currency Code");

        SalesCrMemoLine.SetRange("Document No.", parCRMemoNo);
        if SalesCrMemoLine.Find('-') then
            repeat
                CustAmount := CustAmount + SalesCrMemoLine.Amount;
                CostLCY := CostLCY + (SalesCrMemoLine.Quantity * SalesCrMemoLine."Unit Cost (LCY)");
                TotalAdjCostLCY := TotalAdjCostLCY + CostCalcMgt.CalcSalesCrMemoLineCostLCY(SalesCrMemoLine);
            until SalesCrMemoLine.Next() = 0;

        if SalesCRMemo."Currency Code" = '' then
            AmountLCY := CustAmount
        else
            AmountLCY :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                WorkDate(), SalesCRMemo."Currency Code", CustAmount, SalesCRMemo."Currency Factor");

        ProfitLCY := AmountLCY - CostLCY;
        if AmountLCY <> 0 then
            ProfitPct := Round(100 * ProfitLCY / AmountLCY, 0.1);

        AdjProfitLCY := AmountLCY - TotalAdjCostLCY;
        if AmountLCY <> 0 then
            AdjProfitPct := Round(100 * AdjProfitLCY / AmountLCY, 0.1);
        CostLCY := Round(CostLCY, 0.01);
        ProfitLCY := Round(ProfitLCY, 0.01);

        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales CRMemo Statistics', '- Original Cost (LCY) ='), CostLCY, parOrgCost);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales CRMemo Statistics', '- Adjusted Cost (LCY) ='), TotalAdjCostLCY, parAdjCost);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales CRMemo Statistics', '- Original Profit (LCY) ='), ProfitLCY, parOrgProfit);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales CRMemo Statistics', '- Adjusted Profit (LCY) ='), AdjProfitLCY, parAdjProfit);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales CRMemo Statistics', '- Original Profit % ='), ProfitPct, parOrgProfitPct);
        TestscriptMgt.TestNumberValue(
          MakeName(parTestCaseName, 'Sales CRMemo Statistics', '- Adjusted Profit % ='), AdjProfitPct, parAdjProfitPct);
    end;

    local procedure CreateReservEntryFor(ForType: Option; ForSubtype: Integer; ForID: Code[20]; ForBatchName: Code[10]; ForProdOrderLine: Integer; ForRefNo: Integer; ForQtyPerUOM: Decimal; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservEntry.CreateReservEntryFor(
            ForType, ForSubtype, ForID, ForBatchName, ForProdOrderLine, ForRefNo, ForQtyPerUOM, Quantity, QuantityBase, ForReservEntry);
    end;
}

